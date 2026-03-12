import 'dart:async';
import 'SSHServiceStub.dart' if (dart.library.io) 'SSHServiceNative.dart';

class SSHService {
  static final SSHService _instance = SSHService._internal();
  factory SSHService() => _instance;
  SSHService._internal();

  final SSHServiceNative _impl = SSHServiceNative();

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
  }) async {
    return _impl.connect(host: host, port: port, username: username, password: password);
  }

  void write(String data) => _impl.write(data);
  
  void resize(int width, int height) => _impl.resize(width, height);
  
  void disconnect() => _impl.disconnect();
}
