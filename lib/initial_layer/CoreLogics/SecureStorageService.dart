import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final Logger _logger = Logger('SecureStorageService');

  static const String _keyUsername = 'auth_username';
  static const String _keyPassword = 'auth_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';

  Future<void> saveCredentials(String username, String password) async {
    try {
      await _storage.write(key: _keyUsername, value: username);
      await _storage.write(key: _keyPassword, value: password);
    } catch (e) {
      _logger.severe('Error saving credentials to secure storage: $e');
    }
  }

  Future<Map<String, String?>> getCredentials() async {
    try {
      final username = await _storage.read(key: _keyUsername);
      final password = await _storage.read(key: _keyPassword);
      return {'username': username, 'password': password};
    } catch (e) {
      _logger.severe('Error reading credentials from secure storage: $e');
      return {'username': null, 'password': null};
    }
  }

  Future<void> clearCredentials() async {
    try {
      await _storage.delete(key: _keyUsername);
      await _storage.delete(key: _keyPassword);
    } catch (e) {
      _logger.severe('Error clearing credentials from secure storage: $e');
    }
  }

  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(
        key: _keyBiometricEnabled,
        value: enabled.toString(),
      );
    } catch (e) {
      _logger.severe('Error setting biometric enabled state: $e');
    }
  }

  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: _keyBiometricEnabled);
      return value == 'true';
    } catch (e) {
      _logger.severe('Error reading biometric enabled state: $e');
      return false;
    }
  }
}
