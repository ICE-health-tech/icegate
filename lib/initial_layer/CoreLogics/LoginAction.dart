import 'package:ice_gate/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:logging/logging.dart';

class LoginAction {
  final CustomAuthService _authService;
  final PasskeyAuthService _passkeyService = PasskeyAuthService();
  final Logger _logger = Logger('LoginAction');

  LoginAction({required String baseUrl})
    : _authService = CustomAuthService(baseUrl: baseUrl);

  /// Login with email and password
  Future<Map<String, dynamic>> loginWithUserName(
    String userName,
    String password,
  ) async {
    try {
      return await _authService.login(userName, password);
    } catch (e) {
      _logger.severe('Login failed: $e');
      throw Exception(e.toString());
    }
  }

  /// Login with passkey
  Future<Map<String, dynamic>> loginWithPasskey({String? email}) async {
    final targetEmail = email ?? "duylong.art@gmail.com";
    try {
      // 1. Get challenge from backend
      final challenge = await _authService.getPasskeyChallenge(email: targetEmail);

      // 2. Trigger platform passkey UI
      final credential = await _passkeyService.loginRequest(
        challenge: challenge,
      );

      if (credential == null) {
        throw Exception('Passkey login cancelled or failed');
      }

      // 3. Verify credential with backend
      return await _authService.verifyPasskeyLogin(
        credential: credential,
        email: targetEmail,
      );
    } catch (e) {
      _logger.severe('Passkey login failed: $e');
      throw Exception(e.toString());
    }
  }

  /// Logout
  Future<void> logout(String token) async {
    // Implement token clearing in CustomAuthService if needed
    await _authService.logout(token);
    // _passkeyService.logout();
  }

  /// Check if user is logged in
  bool get isLoggedIn => false; // Implement proper state check

  /// Get current user ID
  String? get currentUserId => null;
}
