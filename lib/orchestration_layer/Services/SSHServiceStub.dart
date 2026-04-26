import 'dart:async';

class SSHServiceNative {
  final dynamic terminal = null;
  bool get isConnected => false;
  String? get currentHost => null;
  DateTime? get connectedAt => null;
  Stream<bool> get connectionState => Stream.value(false);
  Stream<Map<String, dynamic>> get statsStream => Stream.empty();
  int get bytesIn => 0;
  int get bytesOut => 0;
  double get latencyMs => 0;

  Future<void> connect({
    required String host,
    required int port,
    required String username,
    required String password,
    bool useTmux = false,
    String? autoStartCommand,
  }) async {}

  void write(String data) {}
  void resize(int width, int height) {}
  Future<String?> execute(String command) async => null;
  Future<List<String>> listTmuxSessions() async => [];
  void killTmuxSession(String sessionName) {}
  void disconnect() {}
}
