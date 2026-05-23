import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists HTTP basic-auth credentials and per-host "remember sign-in" for WebViews.
class WebViewCredentialStore {
  WebViewCredentialStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String hostKey(String host) =>
      host.toLowerCase().replaceAll(RegExp(r'[^a-z0-9.-]'), '_');

  String _userKey(String host) => 'webview_http_user_${hostKey(host)}';
  String _passKey(String host) => 'webview_http_pass_${hostKey(host)}';
  String _rememberKey(String host) => 'webview_remember_${hostKey(host)}';

  Future<bool> isRememberEnabled(String host) async {
    final v = await _storage.read(key: _rememberKey(host));
    // Default: remember sign-in unless user opted out.
    if (v == null) return true;
    return v == 'true';
  }

  Future<void> setRememberEnabled(String host, bool enabled) async {
    await _storage.write(
      key: _rememberKey(host),
      value: enabled ? 'true' : 'false',
    );
  }

  Future<({String user, String password})?> readHttpAuth(String host) async {
    if (!await isRememberEnabled(host)) return null;
    final user = await _storage.read(key: _userKey(host));
    final pass = await _storage.read(key: _passKey(host));
    if (user == null || user.isEmpty || pass == null) return null;
    return (user: user, password: pass);
  }

  Future<void> saveHttpAuth({
    required String host,
    required String user,
    required String password,
  }) async {
    await _storage.write(key: _userKey(host), value: user);
    await _storage.write(key: _passKey(host), value: password);
    await setRememberEnabled(host, true);
  }

  Future<void> clearHost(String host) async {
    await _storage.delete(key: _userKey(host));
    await _storage.delete(key: _passKey(host));
    await _storage.delete(key: _rememberKey(host));
  }
}
