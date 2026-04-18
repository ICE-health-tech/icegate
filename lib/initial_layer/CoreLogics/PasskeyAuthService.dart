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
  /// [optionsJson] Full publicKey JSON from server
  Future<String?> registerRequest({
    required String userId,
    required String username,
    required String challenge, // Still kept for backward compatibility if needed
    String? optionsJson, // Full publicKey JSON from server
  }) async {
    try {
      if (!await isSupported()) {
        throw Exception('Passkeys are not supported on this device.');
      }

      // Increase delay to 1250ms to ensure the UI/Window/Scene is fully ready and Key status is gained
      await Future.delayed(const Duration(milliseconds: 1250));

      // 1. Construct the creation options.
      final String finalOptionsJson;
      
      if (optionsJson != null && optionsJson.isNotEmpty) {
        _logger.info('Using provided registration options from Hub');
        finalOptionsJson = optionsJson;
      } else {
        _logger.info('Constructing manual registration options');
        final registrationOptions = {
          "challenge": challenge,
          "rp": {
            "name": "ICE Gate",
            "id": "passkey.duylong.art", // MUST match Associated Domains
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
        finalOptionsJson = jsonEncode(registrationOptions);
      }

      _logger.info('Starting passkey registration with options: $finalOptionsJson');
      
      // 2. Invoke the platform passkey creation with a retry loop
      int attempts = 0;
      const int maxAttempts = 2;
      String? result;

      while (attempts < maxAttempts) {
        try {
          attempts++;
          result = await _flutterPasskey.createCredential(finalOptionsJson);
          break; // Success!
        } catch (e) {
          // Retry if the native system is struggling with the view controller/window focus
          if (e.toString().contains('Root view controller') && attempts < maxAttempts) {
             _logger.warning('UI Error: Native window not ready for Registration. Retrying in 800ms... (Attempt $attempts)');
             await Future.delayed(const Duration(milliseconds: 800));
          } else {
            rethrow; // Terminal failure
          }
        }
      }

      _logger.info('Passkey registration result: $result');
      return result;
    } catch (e) {
      if (e.toString().contains('1004')) {
        _logger.severe('Passkey Error 1004: Identity verification failed. Ensure apple-app-site-association is correctly hosted on passkey.duylong.art and entitlements match.');
      }
      _logger.severe('Error registering passkey: $e');
      rethrow;
    }
  }

  /// Sign in with an existing passkey.
  ///
  /// [challenge] The challenge string from the Relying Party (your backend).
  /// [optionsJson] Full publicKey JSON from server
  Future<String?> loginRequest({
    required String challenge, // Base64 encoded challenge from server
    String? optionsJson, // Full publicKey assertion options from Hub
  }) async {
    try {
      if (!await isSupported()) {
        throw Exception('Passkeys are not supported on this device.');
      }
 
      // Increase delay to 1250ms to ensure the UI/Window/Scene is fully ready and Key status is gained
      await Future.delayed(const Duration(milliseconds: 1250));
 
      // Standard WebAuthn PublicKeyCredentialRequestOptions
      final String finalOptionsJson;
      
      if (optionsJson != null && optionsJson.isNotEmpty) {
        _logger.info('Using provided login options from Hub');
        finalOptionsJson = optionsJson;
      } else {
        _logger.info('Constructing manual login options');
        final authOptions = {
          "challenge": challenge,
          "rpId": "passkey.duylong.art", // MUST match registration and Associated Domains
          "timeout": 60000,
          "userVerification": "required",
        };
        finalOptionsJson = jsonEncode(authOptions);
      }
 
      _logger.info('Starting passkey login with options: $finalOptionsJson');
 
      // 2. Invoke the platform passkey authentication with a retry loop
      // to handle any transient "Root view controller not found" window issues on iPad.
      int attempts = 0;
      const int maxAttempts = 2;
      String? result;
 
      while (attempts < maxAttempts) {
        try {
          attempts++;
          result = await _flutterPasskey.getCredential(finalOptionsJson);
          break; // Success!
        } catch (e) {
          if (e.toString().contains('Root view controller') && attempts < maxAttempts) {
             _logger.warning('UI Error: Native window not ready. Retrying in 500ms... (Attempt $attempts)');
             await Future.delayed(const Duration(milliseconds: 500));
          } else {
            rethrow; // Final failure or unrelated error
          }
        }
      }
 
      _logger.info('Passkey login result: $result');
      return result; // This is the assertion to be sent back to the backend for verification
    } catch (e) {
      _logger.severe('Error logging in with passkey: $e');
      rethrow;
    }
  }
}
