import 'dart:convert';
import 'package:flutter_passkey/flutter_passkey.dart';
import 'package:logging/logging.dart';

class PasskeyAuthService {
  final FlutterPasskey _flutterPasskey = FlutterPasskey();
  final Logger _logger = Logger('PasskeyAuthService');

  PasskeyAuthService();

  Future<bool> isSupported() async {
    return await _flutterPasskey.isSupported();
  }

  /// Register a new passkey.
  ///
  /// [userId] The unique user ID from your backend.
  /// [username] The username (usually email) to display in the system prompt.
  /// [challenge] The challenge string from the Relying Party (your backend).
  Future<String?> registerRequest({
    required String userId,
    required String username,
    required String challenge, // Base64 encoded challenge from server
  }) async {
    try {
      if (!await isSupported()) {
        throw Exception('Passkeys are not supported on this device.');
      }

      // Increase delay to 1000ms to ensure the UI/Window is ready
      await Future.delayed(const Duration(milliseconds: 1000));

      // 1. Construct the creation options.
      // Ideally, the backend should generate the full options JSON.
      // But for this example/simplification, we might construct parts of it here
      // or assume `challenge` is just the random bytes string.
      // However, `flutter_passkey` expects the platform-specific JSON parameters.

      // Let's assume for a moment we are constructing a minimal valid registration request
      // compliant with WebAuthn.

      // Standard WebAuthn PublicKeyCredentialCreationOptions structure
      // Note: flutter_passkey passes this JSON essentially directly to the platform.
      final registrationOptions = {
        "challenge": challenge,
        "rp": {
          "name": "ICE Gate",
          "id": "auth.duylong.art", // MUST match Associated Domains
        },
        "user": {
          "id": base64Encode(utf8.encode(userId)),
          "name": username,
          "displayName": username,
        },
        "pubKeyCredParams": [
          {"type": "public-key", "alg": -7}, // ES256
          {"type": "public-key", "alg": -257}, // RS256
        ],
        "timeout": 60000,
        "attestation": "none",
        "authenticatorSelection": {
          "authenticatorAttachment": "platform",
          "requireResidentKey": true,
          "userVerification": "required",
        },
      };

      final String optionsJson = jsonEncode(registrationOptions);

      _logger.info('Starting passkey registration with options: $optionsJson');

      // 2. Invoke the platform passkey creation
      final String result = await _flutterPasskey.createCredential(optionsJson);

      _logger.info('Passkey registration result: $result');
      return result; // This is the credential to be sent back to the backend for verification
    } catch (e) {
      _logger.severe('Error registering passkey: $e');
      rethrow;
    }
  }

  /// Sign in with an existing passkey.
  ///
  /// [challenge] The challenge string from the Relying Party (your backend).
  Future<String?> loginRequest({
    required String challenge, // Base64 encoded challenge from server
  }) async {
    try {
      if (!await isSupported()) {
        throw Exception('Passkeys are not supported on this device.');
      }

      // Increase delay to 1000ms to ensure the UI/Window is ready
      await Future.delayed(const Duration(milliseconds: 1000));

      // Standard WebAuthn PublicKeyCredentialRequestOptions
      final authOptions = {
        "challenge": challenge,
        "rpId": "wthislkepfufkbgiqegs.supabase.co", // Updated to Supabase project domain
        "timeout": 60000,
        "userVerification": "required",
        // "allowCredentials": [], // Empty list allows discovering all credentials for this RP
      };

      final String optionsJson = jsonEncode(authOptions);

      _logger.info('Starting passkey login with options: $optionsJson');

      // 2. Invoke the platform passkey authentication
      final String result = await _flutterPasskey.getCredential(optionsJson);

      _logger.info('Passkey login result: $result');
      return result; // This is the assertion to be sent back to the backend for verification
    } catch (e) {
      _logger.severe('Error logging in with passkey: $e');
      rethrow;
    }
  }
}
