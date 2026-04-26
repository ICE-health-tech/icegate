import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/widgets.dart';
import 'package:xterm/xterm.dart';
import 'SSHService.dart';

class SSHServiceNative with WidgetsBindingObserver {
  SSHClient? _client;
  SSHSession? _shell;
  final Terminal terminal = Terminal();
  
  String? currentHost;
  int? currentPort;
  String? currentUsername;
  String? currentPassword;
  DateTime? connectedAt;
  bool useTmux = false;
  String? autoStartCommand;
  
  // Stats
  int _bytesIn = 0;
  int _bytesOut = 0;
  int get bytesIn => _bytesIn;
  int get bytesOut => _bytesOut;
  
  double _latencyMs = 0;
  double get latencyMs => _latencyMs;
  
  bool _isManuallyDisconnected = false;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 20; // Increased for better background recovery

  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  bool get isConnected => _client != null;

  SSHServiceNative() {
    WidgetsBinding.instance.addObserver(this);
    terminal.onOutput = (data) {
      if (isConnected) {
        final encoded = utf8.encode(data);
        _bytesOut += encoded.length;
        _shell?.stdin.add(encoded);
        _emitStats();
      }
    };
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App moved to background - ensure heartbeat is robust
      _startHeartbeat(isBackground: true);
    } else if (state == AppLifecycleState.resumed) {
      // App returned to foreground
      _startHeartbeat(isBackground: false);
      if (!isConnected && !_isManuallyDisconnected && currentHost != null) {
        _handleReconnect();
      }
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cleanupSession();
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
    bool useTmux = false,
    String? autoStartCommand,
  }) async {
    _isManuallyDisconnected = false;
    currentHost = host;
    currentPort = port;
    currentUsername = username;
    currentPassword = password;
    this.useTmux = useTmux;
    SSHService().useTmuxSignal.value = useTmux;
    this.autoStartCommand = autoStartCommand;
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
      
      final socket = await SSHSocket.connect(currentHost!, currentPort!, timeout: const Duration(seconds: 15));
      _client = SSHClient(
        socket,
        username: currentUsername!,
        onPasswordRequest: () => currentPassword!,
        keepAliveInterval: const Duration(seconds: 30),
      );

      _shell = await _client!.shell();
      
      if (useTmux) {
        terminal.write('\x1b[38;5;208m>>> INITIALIZING PERSISTENT TMUX SESSION...\x1b[0m\r\n');
        // Attach to existing session 'ice_gate' or create a new one
        _shell?.stdin.add(utf8.encode('tmux attach -t ice_gate || tmux new-session -s ice_gate\n'));
      }

      connectedAt = DateTime.now();
      _reconnectAttempts = 0;
      _connectionStateController.add(true);
      
      _startHeartbeat();
      _startStatsTimer();
      
      terminal.write('\x1b[38;5;46m>>> UPLINK ESTABLISHED. ENCRYPTION ACTIVE.\x1b[0m\r\n\r\n');

      if (autoStartCommand != null) {
        // Wait slightly for the shell to be ready
        Future.delayed(const Duration(milliseconds: 500), () {
          if (isConnected) {
            _shell?.stdin.add(utf8.encode('$autoStartCommand\n'));
          }
        });
      }

      
      _shell!.stdout.listen((data) {
        _bytesIn += data.length;
        try {
          // Use chunked conversion or simple decode with allowMalformed if needed, 
          // but better to decode with a stateful decoder if possible.
          // For simplicity and robustness in a terminal context:
          terminal.write(utf8.decode(data, allowMalformed: true));
        } catch (e) {
          debugPrint('SSH STDOUT Decode Error: $e');
        }
        _emitStats();
      }, onError: (e) => _handleError('STDOUT', e));

      _shell!.stderr.listen((data) {
        _bytesIn += data.length;
        try {
          terminal.write('\x1b[38;5;196m[ERR] ${utf8.decode(data, allowMalformed: true)}\x1b[0m');
        } catch (e) {
          debugPrint('SSH STDERR Decode Error: $e');
        }
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

  void _startHeartbeat({bool isBackground = false}) {
    _heartbeatTimer?.cancel();
    final interval = isBackground ? const Duration(seconds: 20) : const Duration(seconds: 15);
    _heartbeatTimer = Timer.periodic(interval, (timer) async {
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
      
      final backoff = pow(2, min(_reconnectAttempts, 6)).toInt(); // Cap backoff at 64s
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
    SSHService().useTmuxSignal.value = false;
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

  Future<String?> execute(String command) async {
    if (!isConnected || _client == null) return null;
    try {
      final session = await _client!.execute(command);
      return await utf8.decodeStream(session.stdout);
    } catch (e) {
      debugPrint('SSH Execute Error: $e');
      return null;
    }
  }

  Future<List<String>> listTmuxSessions() async {
    final output = await execute('tmux list-sessions -F "#S"');
    if (output == null || output.trim().isEmpty) return [];
    return output.trim().split('\n');
  }

  void killTmuxSession(String sessionName) {
    if (isConnected) {
      terminal.write('\r\n\x1b[38;5;196m>>> TERMINATING TMUX SESSION: $sessionName...\x1b[0m\r\n');
      _shell?.stdin.add(utf8.encode('tmux kill-session -t $sessionName\n'));
    }
  }

  void disconnect() {
    _isManuallyDisconnected = true;
    _cleanupSession();
    _client?.close();
    _clearConnection();
  }
}
