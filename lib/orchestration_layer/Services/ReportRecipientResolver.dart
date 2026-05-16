import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/ReportRecipientPrefs.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Resolves the email used for finance + health report delivery.
class ReportRecipientResolver {
  static String? profileEmail(PersonBlock personBlock) {
    final fromProfile = personBlock.information.value.details.email.trim();
    if (fromProfile.isNotEmpty) return fromProfile;
    return Supabase.instance.client.auth.currentUser?.email?.trim();
  }

  static Future<String?> resolve(PersonBlock personBlock) async {
    final override = (await ReportRecipientPrefs.getRecipient())?.trim();
    if (override != null && override.isNotEmpty) return override;
    return profileEmail(personBlock);
  }
}
