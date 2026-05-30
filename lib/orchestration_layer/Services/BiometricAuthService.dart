import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final Logger _logger = Logger('BiometricAuthService');

  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  Future<bool> canAuthenticate() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck || supported;
    } catch (e) {
      _logger.warning('canAuthenticate check failed: $e');
      return false;
    }
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (e) {
      _logger.severe('Error getting available biometrics: $e');
      return <BiometricType>[];
    }
  }

  Future<bool> authenticate({
    required String reason,
    bool stickyAuth = false,
    bool biometricOnly = true,
  }) async {
    try {
      if (!await canAuthenticate()) {
        _logger.warning('Biometric auth unavailable on this device');
        return false;
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
          useErrorDialogs: true,
          sensitiveTransaction: true,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('cancel') ||
          msg.contains('dismiss') ||
          msg.contains('userfallback')) {
        _logger.info('Biometric auth canceled by user');
        return false;
      }
      _logger.severe('Error during biometric authentication: $e');
      return false;
    }
  }
}
