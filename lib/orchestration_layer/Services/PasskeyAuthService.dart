import 'dart:async';
import 'dart:convert';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_passkey/flutter_passkey.dart';
import 'package:logging/logging.dart';

class PasskeyAuthService {
  final FlutterPasskey _flutterPasskey = FlutterPasskey();
  final Logger _logger = Logger('PasskeyAuthService');

  PasskeyAuthService();

  /// Wait until Flutter has presented a window (ASAuthorization needs a VC).
  Future<void> _waitForPresentableWindow() async {
    final completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    final binding = SchedulerBinding.instance;
    if (binding.schedulerPhase == SchedulerPhase.idle) {
      await binding.endOfFrame;
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

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

      await _waitForPresentableWindow();

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
      const int maxAttempts = 3;
      String? result;

      while (attempts < maxAttempts) {
        try {
          attempts++;
          if (attempts > 1) await _waitForPresentableWindow();
          result = await _flutterPasskey.createCredential(finalOptionsJson);
          break; // Success!
        } catch (e) {
          final msg = e.toString();
          final retryable = attempts < maxAttempts &&
              (msg.contains('Root view controller') ||
                  msg.contains('not in window hierarchy') ||
                  msg.contains('presentation'));
          if (retryable) {
            _logger.warning(
              'Passkey registration UI not ready (attempt $attempts): $e',
            );
            await Future.delayed(Duration(milliseconds: 500 * attempts));
          } else {
            rethrow;
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
 
      await _waitForPresentableWindow();

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
      const int maxAttempts = 3;
      String? result;

      while (attempts < maxAttempts) {
        try {
          attempts++;
          if (attempts > 1) await _waitForPresentableWindow();
          result = await _flutterPasskey.getCredential(finalOptionsJson);
          break;
        } catch (e) {
          final msg = e.toString();
          final retryable = attempts < maxAttempts &&
              (msg.contains('Root view controller') ||
                  msg.contains('not in window hierarchy') ||
                  msg.contains('presentation') ||
                  msg.contains('1001'));
          if (retryable) {
            _logger.warning(
              'Passkey login UI not ready (attempt $attempts): $e',
            );
            await Future.delayed(Duration(milliseconds: 500 * attempts));
          } else {
            rethrow;
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
