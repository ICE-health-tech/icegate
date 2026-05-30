import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class AuthErrorHelper {
  static String getLocalizedError(BuildContext context, String key) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) return key;

    if (key.startsWith('err_unexpected|')) {
      final details = key.substring('err_unexpected|'.length);
      return l10n.err_unexpected(details.isEmpty ? 'System Error' : details);
    }
    switch (key) {
      case "err_invalid_credentials":
        return l10n.err_invalid_credentials;
      case "err_email_not_confirmed":
        return l10n.err_email_not_confirmed;
      case "err_user_not_found":
        return l10n.err_user_not_found;
      case "err_network_fail":
        return l10n.err_network_fail;
      case "err_passkey_canceled":
        return l10n.err_passkey_canceled;
      case "err_passkey_failed":
        return l10n.err_passkey_failed;
      case "err_biometric_unsupported":
        return l10n.err_biometric_unsupported;
      case "err_biometric_disabled":
        return l10n.err_biometric_disabled;
      case "err_too_many_attempts":
        return l10n.err_too_many_attempts;
      case "err_unexpected":
        return l10n.err_unexpected("System Error");
      default:
        return key; // Fallback to raw string if not a known key
    }
  }
}
