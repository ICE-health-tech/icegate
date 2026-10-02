import 'package:shared_preferences/shared_preferences.dart';

/// Morning notification + briefing preferences (local only).
class MorningLoopPrefs {
  static const _kReminderEnabled = 'morning_loop_reminder_enabled';
  static const _kReminderHour = 'morning_loop_reminder_hour';
  static const _kReminderMinute = 'morning_loop_reminder_minute';
  static const _kBriefingEnabled = 'morning_loop_briefing_enabled';

  /// Daily push to open Ice Gate first thing.
  static Future<bool> getReminderEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kReminderEnabled) ?? false;
  }

  static Future<void> setReminderEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kReminderEnabled, value);
  }

  static Future<int> getHour() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kReminderHour) ?? 7;
  }

  static Future<int> getMinute() async {
    final p = await SharedPreferences.getInstance();
    return p.getInt(_kReminderMinute) ?? 0;
  }

  static Future<void> setTime(int hour, int minute) async {
    final p = await SharedPreferences.getInstance();
    await p.setInt(_kReminderHour, hour);
    await p.setInt(_kReminderMinute, minute);
  }

  /// Full-screen morning sheet on first Home visit (5:00–11:59).
  static Future<bool> getBriefingEnabled() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_kBriefingEnabled) ?? true;
  }

  static Future<void> setBriefingEnabled(bool value) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kBriefingEnabled, value);
  }

  static const _kBriefingLastShown = 'morning_briefing_last_shown';
  static const _kHomeQuoteText = 'morning_home_quote_text';
  static const _kHomeQuoteDate = 'morning_home_quote_date';

  static Future<bool> shouldShowBriefingToday() async {
    if (!await getBriefingEnabled()) return false;
    final hour = DateTime.now().hour;
    if (hour < 5 || hour >= 12) return false;
    final p = await SharedPreferences.getInstance();
    final today = _dateKey(DateTime.now());
    return p.getString(_kBriefingLastShown) != today;
  }

  static Future<void> markBriefingShownToday() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kBriefingLastShown, _dateKey(DateTime.now()));
  }

  /// Home quote strip after morning briefing (same calendar day).
  static Future<void> saveMorningHomeQuote(String text) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_kHomeQuoteText, text);
    await p.setString(_kHomeQuoteDate, _dateKey(DateTime.now()));
  }

  static Future<String?> loadMorningHomeQuoteIfToday() async {
    final p = await SharedPreferences.getInstance();
    if (p.getString(_kHomeQuoteDate) != _dateKey(DateTime.now())) {
      return null;
    }
    return p.getString(_kHomeQuoteText);
  }

  static Future<void> clearMorningHomeQuote() async {
    final p = await SharedPreferences.getInstance();
    await p.remove(_kHomeQuoteText);
    await p.remove(_kHomeQuoteDate);
  }

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static int _dailyRotationIndex() =>
      DateTime.now().day + DateTime.now().month * 31;

  static Future<bool> _isVietnamese() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('app_locale') ?? 'vi') == 'vi';
  }

  /// Notification copy (no BuildContext at schedule time).
  static Future<({String title, String body})> notificationCopy() async {
    final vi = await _isVietnamese();
    final i = _dailyRotationIndex();
    if (vi) {
      const messages = [
        (
          title: 'Chào buổi sáng',
          body:
              'Uống nước, hít thở sâu — mở Ice Gate để bắt đầu ngày nhẹ nhàng.',
        ),
        (
          title: 'Chăm mình từ sáng',
          body:
              'Ghi tâm trạng và xem chỉ số sức khỏe trong 2 phút trên Ice Gate.',
        ),
        (
          title: 'Tinh thần tỉnh táo',
          body:
              'Một buổi sáng ổn định giúp bạn dùng app hiệu quả hơn. Mở Ice Gate nhé.',
        ),
        (
          title: 'Khởi đầu tốt lành',
          body:
              'Bước chân, giấc ngủ, nước uống — hôm nay bạn muốn chăm điều gì trước?',
        ),
        (
          title: 'Sáng nay, yêu bản thân',
          body:
              'Vòng 4 trụ cột ngắn: sức khỏe, tâm trí, dự án, tài chính — từng bước nhỏ.',
        ),
        (
          title: 'Buổi sáng an lành',
          body:
              'Không cần hoàn hảo — chỉ cần bắt đầu. Ice Gate cùng bạn từng bước.',
        ),
        (
          title: 'Năng lượng mới',
          body:
              'Dành 3 phút sáng nay — Ice Gate nhắc bạn chăm cơ thể và tinh thần.',
        ),
      ];
      return messages[i % messages.length];
    }
    const messages = [
      (
        title: 'Good morning',
        body:
            'Drink water, breathe deep — open Ice Gate and ease into your day.',
      ),
      (
        title: 'Care for yourself',
        body:
            'Log your mood and check health metrics in 2 minutes on Ice Gate.',
      ),
      (
        title: 'Clear mind, clear day',
        body:
            'A calm morning helps you use the app well. Open Ice Gate when ready.',
      ),
      (
        title: 'Start gently',
        body:
            'Steps, sleep, hydration — which pillar will you nurture first today?',
      ),
      (
        title: 'Small steps count',
        body:
            'A short 4-pillar loop: health, mind, projects, finance — one at a time.',
      ),
      (
        title: 'No perfection needed',
        body: 'Just begin — Ice Gate walks with you through each small win.',
      ),
      (
        title: 'Fresh energy',
        body:
            'Take 3 minutes this morning — Ice Gate nudges body and mind care.',
      ),
    ];
    return messages[i % messages.length];
  }

  /// Wellness tip shown on the morning briefing sheet (rotates daily).
  static Future<String> briefingWellnessTip() async {
    final vi = await _isVietnamese();
    final i = _dailyRotationIndex();
    if (vi) {
      const tips = [
        '💧 Uống một cố nước ấm trước khi chạm vào điện thoại.',
        '🌬️ Hít thở 4–4–4: hít 4 giây, giữ 4, thở 4 — tinh thần sẽ nhẹ hơn.',
        '📝 Ghi một dòng nhật ký: hôm nay bạn cảm thấy thế nào?',
        '🚶 Dành 5 phút đi bộ — cơ thể tỉnh, não bộ sáng hơn.',
        '😴 Ngủ đủ giúp app đọc chỉ số sức khỏe chính xác — đừng bỏ qua giấc ngủ.',
        '🧘 Một phút im lặng trước khi mở app — bạn sẽ tập trung tốt hơn.',
        '🎯 Chọn một việc nhỏ hôm nay — Ice Gate giúp bạn không quên.',
      ];
      return tips[i % tips.length];
    }
    const tips = [
      '💧 Drink warm water before touching your phone.',
      '🌬️ Try 4-4-4 breathing: inhale, hold, exhale — 4 seconds each.',
      '📝 One journal line: how do you feel starting today?',
      '🚶 Five minutes of walking wakes body and mind.',
      '😴 Good sleep keeps health metrics accurate — rest matters.',
      '🧘 One quiet minute before opening the app improves focus.',
      '🎯 Pick one small win today — Ice Gate helps you remember.',
    ];
    return tips[i % tips.length];
  }
}
