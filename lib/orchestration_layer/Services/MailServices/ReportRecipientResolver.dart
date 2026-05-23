import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/ReportRecipientPrefs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the email used for finance + health report delivery.
class ReportRecipientResolver {
  static String? _authEmail() =>
      Supabase.instance.client.auth.currentUser?.email?.trim();

  /// Rejects website URLs and other non-email strings (e.g. `duylong.dev`).
  static bool isValidEmail(String value) {
    final s = value.trim();
    if (s.length < 5 || s.contains(' ')) return false;
    if (s.startsWith('http://') || s.startsWith('https://')) return false;
    if (!s.contains('@')) return false;
    final parts = s.split('@');
    if (parts.length != 2 || parts[0].isEmpty || parts[1].isEmpty) {
      return false;
    }
    return parts[1].contains('.');
  }

  /// Default recipient for UI hints: logged-in account email, then valid profile email.
  static String? profileEmail(PersonBlock personBlock) {
    final auth = _authEmail();
    if (auth != null && auth.isNotEmpty && isValidEmail(auth)) return auth;

    final fromProfile = personBlock.information.value.details.email.trim();
    if (fromProfile.isNotEmpty && isValidEmail(fromProfile)) return fromProfile;

    return auth?.isNotEmpty == true ? auth : null;
  }

  /// Display name for email greeting (first + last from profile).
  static String? displayName(PersonBlock personBlock) {
    final profile = personBlock.information.value.profiles;
    final parts = [
      profile.firstName.trim(),
      profile.lastName.trim(),
    ].where((s) => s.isNotEmpty);
    if (parts.isEmpty) return null;
    return parts.join(' ');
  }

  static Future<String?> resolve(PersonBlock personBlock) async {
    final override = (await ReportRecipientPrefs.getRecipient())?.trim();
    if (override != null &&
        override.isNotEmpty &&
        isValidEmail(override)) {
      return override;
    }

    final auth = _authEmail();
    if (auth != null && auth.isNotEmpty && isValidEmail(auth)) return auth;

    final fromProfile = personBlock.information.value.details.email.trim();
    if (fromProfile.isNotEmpty && isValidEmail(fromProfile)) {
      return fromProfile;
    }

    return null;
  }
}
