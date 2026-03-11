import 'dart:async';

class SSHServiceNative {
  final dynamic terminal = null;
  
  final _connectionStateController = StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionStateController.stream;

  bool get isConnected => false;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    throw Exception('SSH is not supported on this platform');
  }

  void write(String data) {}
  
  void resize(int width, int height) {}
  
  void disconnect() {}
}
