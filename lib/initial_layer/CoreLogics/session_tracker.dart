import 'package:shared_preferences/shared_preferences.dart';

class SessionTracker {
  static const String _keyLastOpen = 'last_open_time';
  static bool _hasCheckedThisSession = false;

  static Future<bool> shouldShowIntro() async {
    if (_hasCheckedThisSession) return false;
    _hasCheckedThisSession = true;

    final prefs = await SharedPreferences.getInstance();
    final lastOpenMs = prefs.getInt(_keyLastOpen);
    final now = DateTime.now().millisecondsSinceEpoch;

    // Update last open time for next time
    await prefs.setInt(_keyLastOpen, now);

    if (lastOpenMs == null) {
      // First time ever opening the app, or after clear data
      return true;
    }

    final diff = now - lastOpenMs;
    const twoHoursInMs = 2 * 60 * 60 * 1000;

    return diff >= twoHoursInMs;
  }

  // For testing purposes or manual reset if needed
  static Future<void> resetLastOpen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLastOpen);
    _hasCheckedThisSession = false;
  }
}
