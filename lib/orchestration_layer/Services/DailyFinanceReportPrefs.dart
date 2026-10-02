import 'package:shared_preferences/shared_preferences.dart';

/// Local-only prefs for the daily finance summary notification (no server).
class DailyFinanceReportPrefs {
  static const _kEnabled = 'daily_finance_report_enabled';
  static const _kHour = 'daily_finance_report_hour';
  static const _kMinute = 'daily_finance_report_minute';

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
    return p.getInt(_kHour) ?? 8;
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
}
