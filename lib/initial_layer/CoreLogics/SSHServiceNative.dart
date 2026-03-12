import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

class SSHServiceNative {
  SSHClient? _client;
  SSHSession? _shell;
  final Terminal terminal = Terminal();
  
  String? currentHost;
  int? currentPort;
  String? currentUsername;
  String? currentPassword;
  DateTime? connectedAt;
  
  // Stats
  int _bytesIn = 0;
  int _bytesOut = 0;
  int get bytesIn => _bytesIn;
  int get bytesOut => _bytesOut;
  
  double _latencyMs = 0;
  double get latencyMs => _latencyMs;
  
  bool _isManuallyDisconnected = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 10;

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  bool get isConnected => _client != null;

  SSHServiceNative() {
    terminal.onOutput = (data) {
      if (isConnected) {
        final encoded = utf8.encode(data);
        _bytesOut += encoded.length;
        _shell?.stdin.add(encoded);
        _emitStats();
      }
    };
  }

  void _emitStats() {
    _statsController.add({
      'bytesIn': _bytesIn,
      'bytesOut': _bytesOut,
      'latencyMs': _latencyMs,
      'uptime': connectedAt != null ? DateTime.now().difference(connectedAt!) : Duration.zero,
    });
  }

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    _isManuallyDisconnected = false;
    currentHost = host;
    currentPort = port;
    currentUsername = username;
    currentPassword = password;
    _bytesIn = 0;
    _bytesOut = 0;
    _reconnectAttempts = 0;
    
    await _performConnect();
  }

  Timer? _heartbeatTimer;
  Timer? _statsTimer;

  Future<void> _performConnect() async {
    if (currentHost == null) return;
    
    try {
      terminal.write('\r\n\x1b[38;5;39m>>> ESTABLISHING UPLINK TO $currentHost:$currentPort...\x1b[0m\r\n');
      
      final socket = await SSHSocket.connect(currentHost!, currentPort!, timeout: const Duration(seconds: 10));
      _client = SSHClient(
        socket,
        username: currentUsername!,
        onPasswordRequest: () => currentPassword!,
      );

      _shell = await _client!.shell();
      connectedAt = DateTime.now();
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      
      _startHeartbeat();
      _startStatsTimer();
      
      terminal.write('\x1b[38;5;46m>>> UPLINK ESTABLISHED. ENCRYPTION ACTIVE.\x1b[0m\r\n\r\n');

      _shell!.stdout.listen((data) {
        _bytesIn += data.length;
        terminal.write(utf8.decode(data));
        _emitStats();
      }, onError: (e) => _handleError('STDOUT', e));

      _shell!.stderr.listen((data) {
        _bytesIn += data.length;
        terminal.write('\x1b[38;5;196m[ERR] ${utf8.decode(data)}\x1b[0m');
        _emitStats();
      }, onError: (e) => _handleError('STDERR', e));

      unawaited(_shell!.done.then((_) {
        _cleanupSession();
        if (!_isManuallyDisconnected) {
          terminal.write('\r\n\x1b[38;5;214m>>> UPLINK INTERRUPTED. INITIATING AUTO-RECOVERY...\x1b[0m\r\n');
          _handleReconnect();
        } else {
          terminal.write('\r\n\x1b[38;5;240m>>> UPLINK TERMINATED BY OPERATOR.\x1b[0m\r\n');
          _clearConnection();
        }
      }));

    } catch (e) {
      _cleanupSession();
      terminal.write('\x1b[38;5;196m>>> CONNECTION FAILED: $e\x1b[0m\r\n');
      if (!_isManuallyDisconnected) {
        _handleReconnect();
      } else {
        _clearConnection();
        rethrow;
      }
    }
  }

  void _handleError(String source, dynamic error) {
    terminal.write('\x1b[38;5;196m>>> $source ERROR: $error\x1b[0m\r\n');
  }

  void _cleanupSession() {
    _stopHeartbeat();
    _stopStatsTimer();
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (isConnected && _client != null) {
        try {
          final stopwatch = Stopwatch()..start();
          // Use a simple SSH ping/keep-alive if available or send a null byte
          _shell?.stdin.add(Uint8List.fromList([0]));
          _latencyMs = stopwatch.elapsedMicroseconds / 1000.0;
          _emitStats();
        } catch (e) {
          _stopHeartbeat();
        }
      } else {
        _stopHeartbeat();
      }
    });
  }

  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  void _startStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (isConnected) {
        _emitStats();
      }
    });
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  void _handleReconnect() {
    if (_reconnectAttempts < maxReconnectAttempts) {
      _reconnectAttempts++;
      
      final backoff = pow(2, _reconnectAttempts).toInt();
      final jitter = Random().nextInt(1000);
      final delay = Duration(milliseconds: backoff * 1000 + jitter);
      
      terminal.write('\x1b[38;5;214m>>> RECOVERY ATTEMPT $_reconnectAttempts/ $maxReconnectAttempts IN ${delay.inSeconds}s...\x1b[0m\r\n');
      
      _client = null;
      _shell = null;
      _connectionStateController.add(false);

      Timer(delay, () {
        if (!_isManuallyDisconnected) {
          _performConnect();
        }
      });
    } else {
      terminal.write('\x1b[38;5;196m>>> CRITICAL: MAXIMUM RECOVERY ATTEMPTS EXCEEDED. UPLINK OFFLINE.\x1b[0m\r\n');
      _clearConnection();
    }
  }

  void _clearConnection() {
    _cleanupSession();
    _client = null;
    _shell = null;
    currentHost = null;
    connectedAt = null;
    _reconnectAttempts = 0;
    _connectionStateController.add(false);
    _emitStats();
  }

  void write(String data) {
    if (isConnected) {
      final encoded = utf8.encode(data);
      _bytesOut += encoded.length;
      _shell?.stdin.add(encoded);
      _emitStats();
    }
  }

  void resize(int width, int height) {
    _shell?.resizeTerminal(width, height);
  }

  void disconnect() {
    _isManuallyDisconnected = true;
    _cleanupSession();
    _client?.close();
    _clearConnection();
  }
}
