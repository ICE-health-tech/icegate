import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

class SecureStorageService {
  final _storage = const FlutterSecureStorage();
  final Logger _logger = Logger('SecureStorageService');

  static const String _keyUsername = 'auth_username';
  static const String _keyPassword = 'auth_password';
  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyDisplayName = 'auth_display_name';
  static const String _keyAvatarUrl = 'auth_avatar_url';

  Future<void> saveCredentials(String username, String password, {String? displayName, String? avatarUrl}) async {
    try {
      await _storage.write(key: _keyUsername, value: username);
      await _storage.write(key: _keyPassword, value: password);
      if (displayName != null) {
        await _storage.write(key: _keyDisplayName, value: displayName);
      }
      if (avatarUrl != null) {
        await _storage.write(key: _keyAvatarUrl, value: avatarUrl);
      }
    } catch (e) {
      _logger.severe('Error saving credentials to secure storage: $e');
    }
  }

  Future<Map<String, String?>> getRememberedUser() async {
    try {
      final username = await _storage.read(key: _keyUsername);
      final displayName = await _storage.read(key: _keyDisplayName);
      final avatarUrl = await _storage.read(key: _keyAvatarUrl);
      return {
        'username': username,
        'displayName': displayName,
        'avatarUrl': avatarUrl,
      };
    } catch (e) {
      _logger.severe('Error reading remembered user: $e');
      return {'username': null, 'displayName': null, 'avatarUrl': null};
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
      await _storage.delete(key: _keyDisplayName);
      await _storage.delete(key: _keyAvatarUrl);
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
