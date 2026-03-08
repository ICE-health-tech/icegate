import 'package:local_auth/local_auth.dart';
import 'package:logging/logging.dart';

class BiometricAuthService {
  final LocalAuthentication _auth = LocalAuthentication();
  final Logger _logger = Logger('BiometricAuthService');

  Future<bool> isDeviceSupported() async {
    return await _auth.isDeviceSupported();
  }

  Future<bool> canAuthenticate() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
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
    bool stickyAuth = true,
    bool biometricOnly = false,
  }) async {
    try {
      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          stickyAuth: stickyAuth,
          biometricOnly: biometricOnly,
        ),
      );
      return didAuthenticate;
    } catch (e) {
      _logger.severe('Error during biometric authentication: $e');
      return false;
    }
  }
}
