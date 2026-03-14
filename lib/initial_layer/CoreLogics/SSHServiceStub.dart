import 'dart:async';

class SSHServiceNative {
  final dynamic terminal = null;
  
  String? currentHost;
  DateTime? connectedAt;
  
  int get bytesIn => 0;
  int get bytesOut => 0;
  double get latencyMs => 0.0;
  
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  final _statsController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get statsStream => _statsController.stream;

  bool get isConnected => false;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useTmux = false,
    String? autoStartCommand,
  }) async {
    throw Exception('SSH is not supported on this platform');
  }

  void write(String data) {}
  
  void resize(int width, int height) {}
  
  void disconnect() {}
}
