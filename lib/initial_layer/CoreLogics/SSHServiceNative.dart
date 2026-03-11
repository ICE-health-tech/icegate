import 'dart:async';
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:xterm/xterm.dart';

class SSHServiceNative {
  SSHClient? _client;
  SSHSession? _shell;
  final Terminal terminal = Terminal();
  
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool get isConnected => _client != null;

  SSHServiceNative() {
    // Listen to terminal output and send it to SSH stdin
    terminal.onOutput = (data) {
      _shell?.stdin.add(utf8.encode(data));
    };
  }

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      terminal.write('Connecting to $host:$port...\r\n');
      
      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      _shell = await _client!.shell();
      _connectionStateController.add(true);
      
      terminal.write('Connected.\r\n');

      _shell!.stdout.listen((data) {
        terminal.write(utf8.decode(data));
      });

      _shell!.stderr.listen((data) {
        terminal.write('\x1b[31m${utf8.decode(data)}\x1b[0m');
      });

      unawaited(_shell!.done.then((_) {
        terminal.write('\r\nConnection closed.\r\n');
        _client = null;
        _shell = null;
        _connectionStateController.add(false);
      }));

    } catch (e) {
      terminal.write('\x1b[31mConnection failed: $e\x1b[0m\r\n');
      _connectionStateController.add(false);
      rethrow;
    }
  }

  void write(String data) {
    _shell?.stdin.add(utf8.encode(data));
  }

  void resize(int width, int height) {
    _shell?.resizeTerminal(width, height);
  }

  void disconnect() {
    _client?.close();
    _client = null;
    _shell = null;
    _connectionStateController.add(false);
  }
}
