import 'package:shared_preferences/shared_preferences.dart';

/// Optional override for report email delivery (n8n).
class ReportRecipientPrefs {
  static const _kRecipient = 'report_recipient_email';

  static Future<String?> getRecipient() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kRecipient);
  }

  static Future<void> setRecipient(String? value) async {
    final p = await SharedPreferences.getInstance();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      await p.remove(_kRecipient);
    } else {
      await p.setString(_kRecipient, trimmed);
    }
  }
}
