import 'dart:async';
import 'package:signals_flutter/signals_flutter.dart';
import 'SSHServiceStub.dart' if (dart.library.io) 'SSHServiceNative.dart';

class SSHService {
  static final SSHService _instance = SSHService._internal();
  factory SSHService() => _instance;
  SSHService._internal();

  final SSHServiceNative _impl = SSHServiceNative();

  final aiMode = signal<String>('standard');
  final aiPromptPrefix = signal<String>('');
  final useTmuxSignal = signal<bool>(false);
  final hostSignal = signal<String>('localhost');
  final portSignal = signal<int>(22);
  final userSignal = signal<String>('');
  final passSignal = signal<String>('');
  final remotePathSignal = signal<String>('');
  final isConfigMode = signal<bool>(false);
  String? currentHostId;

  dynamic get terminal => _impl.terminal;

  bool get isConnected => _impl.isConnected;
  
  String? get currentHost => _impl.currentHost;
  DateTime? get connectedAt => _impl.connectedAt;
  
  Stream<bool> get connectionState => _impl.connectionState;
  Stream<Map<String, dynamic>> get statsStream => _impl.statsStream;
  
  int get bytesIn => _impl.bytesIn;
  int get bytesOut => _impl.bytesOut;
  double get latencyMs => _impl.latencyMs;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useTmux = false,
    String? autoStartCommand,
  }) async {
    return _impl.connect(
      host: host,
      port: port,
      username: username,
      password: password,
      useTmux: useTmux,
      autoStartCommand: autoStartCommand,
    );
  }

  void write(String data) => _impl.write(data);
  
  void resize(int width, int height) => _impl.resize(width, height);
  
  Future<String?> execute(String command) => _impl.execute(command);
  
  Future<List<String>> listTmuxSessions() => _impl.listTmuxSessions();
  
  void killTmuxSession(String sessionName) => _impl.killTmuxSession(sessionName);
  
  void disconnect() => _impl.disconnect();
}
