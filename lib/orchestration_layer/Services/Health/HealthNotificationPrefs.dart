import 'package:shared_preferences/shared_preferences.dart';

/// Preferences for health nudges scheduled by [NotificationEngine].
class HealthNotificationPrefs {
  static const _kStepNudge = 'health_notif_step_nudge_enabled';
  static const _kWaterNudge = 'health_notif_water_nudge_enabled';
  static const _kEveningRecap = 'health_notif_evening_recap_enabled';

  const HealthNotificationPrefs({
    required this.stepNudgeEnabled,
    required this.waterNudgeEnabled,
    required this.eveningRecapEnabled,
  });

  final bool stepNudgeEnabled;
  final bool waterNudgeEnabled;
  final bool eveningRecapEnabled;

  static Future<HealthNotificationPrefs> load() async {
    final p = await SharedPreferences.getInstance();
    return HealthNotificationPrefs(
      stepNudgeEnabled: p.getBool(_kStepNudge) ?? true,
      waterNudgeEnabled: p.getBool(_kWaterNudge) ?? true,
      eveningRecapEnabled: p.getBool(_kEveningRecap) ?? false,
    );
  }

  Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kStepNudge, stepNudgeEnabled);
    await p.setBool(_kWaterNudge, waterNudgeEnabled);
    await p.setBool(_kEveningRecap, eveningRecapEnabled);
  }
}
