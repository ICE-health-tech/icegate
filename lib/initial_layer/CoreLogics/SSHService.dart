import 'dart:async';
import 'SSHServiceStub.dart' if (dart.library.io) 'SSHServiceNative.dart';

class SSHService {
  final SSHServiceNative _impl = SSHServiceNative();

  dynamic get terminal => _impl.terminal;

  bool get isConnected => _impl.isConnected;
  
  Stream<bool> get connectionState => _impl.connectionState;

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
