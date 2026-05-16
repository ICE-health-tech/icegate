import 'package:shared_preferences/shared_preferences.dart';

/// Local prefs for automatic daily email report (n8n) scheduling.
class DailyMailSummaryPrefs {
  static const _kEnabled = 'daily_mail_summary_enabled';
  static const _kHour = 'daily_mail_summary_hour';
  static const _kMinute = 'daily_mail_summary_minute';
  static const _kLastSentDate = 'daily_mail_summary_last_sent_date';

  static Future<bool> getEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kEnabled) ?? false;
  }

  static Future<void> setEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kEnabled, value);
  }

  static Future<int> getHour() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kHour) ?? 20;
  }

  static Future<int> getMinute() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kMinute) ?? 0;
  }

  static Future<void> setTime(int hour, int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kHour, hour);
    await p.setInt(_kMinute, minute);
  }

  static Future<String?> getLastSentDate() async {
    final p = await SharedPreferences.getInstance();
    return p.getString(_kLastSentDate);
  }

  static Future<void> setLastSentDate(String ymd) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kLastSentDate, ymd);
  }

  static String todayKey(DateTime now) {
    final local = now.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
  }
}
