import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
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

  static void _addEmail(Set<String> seen, List<String> out, String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !isValidEmail(value)) return;
    final key = value.toLowerCase();
    if (seen.add(key)) out.add(value);
  }

  /// All deliverable emails for this user (auth → profile → saved addresses).
  static List<String> userEmailCandidates(
    PersonBlock personBlock, {
    List<EmailAddressData> stored = const [],
  }) {
    final seen = <String>{};
    final out = <String>[];
    _addEmail(seen, out, _authEmail());
    _addEmail(seen, out, personBlock.information.value.details.email);
    final sortedStored = List<EmailAddressData>.from(stored)
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.emailAddress.compareTo(b.emailAddress);
      });
    for (final row in sortedStored) {
      _addEmail(seen, out, row.emailAddress);
    }
    return out;
  }

  /// Default recipient for UI hints: first [userEmailCandidates] entry.
  static String? profileEmail(
    PersonBlock personBlock, {
    List<EmailAddressData> stored = const [],
  }) {
    final candidates = userEmailCandidates(personBlock, stored: stored);
    if (candidates.isNotEmpty) return candidates.first;
    return null;
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
