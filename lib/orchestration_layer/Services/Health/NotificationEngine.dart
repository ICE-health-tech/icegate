import 'package:flutter/foundation.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/HealthNotificationPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/MotivationEngine.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Schedules contextual health nudges from [MotivationEngine] output.
class NotificationEngine {
  NotificationEngine(this._notifications);

  final LocalNotificationService _notifications;

  static const int stepNudgeId = 920010;
  static const int waterNudgeId = 920011;
  static const int eveningRecapId = 920012;

  static const String stepNudgePayload = 'route:/health/steps';
  static const String waterNudgePayload = 'route:/health/water';
  static const String eveningRecapPayload = 'route:/health';

  DateTime? _lastSyncAt;

  Future<void> syncHealthNudges({
    required DailyMotivationResult motivation,
    bool force = false,
  }) async {
    if (kIsWeb) return;

    final now = DateTime.now();
    if (!force &&
        _lastSyncAt != null &&
        now.difference(_lastSyncAt!) < const Duration(minutes: 5)) {
      return;
    }
    _lastSyncAt = now;

    await _notifications.cancelNotification(stepNudgeId);
    await _notifications.cancelNotification(waterNudgeId);
    await _notifications.cancelNotification(eveningRecapId);

    if (!_notifications.notificationsEnabled.value) return;

    final prefs = await HealthNotificationPrefs.load();
    final vi = await _isVietnamese();

    if (motivation.tier == DailyMotivationTier.allDone) return;

    final weakest = MotivationEngine.weakestPillar(motivation);

    if (prefs.stepNudgeEnabled && now.hour < 20) {
      final steps = motivation.pillars
          .where((p) => p.id == 'steps')
          .map((p) => p.progress)
          .firstOrNull;
      if (steps != null && steps < 0.5) {
        final copy = MotivationEngine.nudgeCopy(
          pillarId: 'steps',
          vietnamese: vi,
        );
        await _notifications.scheduleDailyHealthNudge(
          id: stepNudgeId,
          channelId: 'health_step_nudge',
          channelName: 'Step reminders',
          title: copy.title,
          body: copy.body,
          hour: 14,
          minute: 30,
          payload: stepNudgePayload,
        );
      }
    }

    if (prefs.waterNudgeEnabled && now.hour < 18) {
      final water = motivation.pillars
          .where((p) => p.id == 'water')
          .map((p) => p.progress)
          .firstOrNull;
      if (water != null && water < 0.4) {
        final copy = MotivationEngine.nudgeCopy(
          pillarId: 'water',
          vietnamese: vi,
        );
        await _notifications.scheduleDailyHealthNudge(
          id: waterNudgeId,
          channelId: 'health_water_nudge',
          channelName: 'Hydration reminders',
          title: copy.title,
          body: copy.body,
          hour: 11,
          minute: 0,
          payload: waterNudgePayload,
        );
      }
    }

    if (prefs.eveningRecapEnabled && motivation.tier != DailyMotivationTier.empty) {
      final pillarId = weakest?.id ?? 'steps';
      final copy = MotivationEngine.nudgeCopy(
        pillarId: pillarId,
        vietnamese: vi,
      );
      await _notifications.scheduleDailyHealthNudge(
        id: eveningRecapId,
        channelId: 'health_evening_recap',
        channelName: 'Evening health recap',
        title: copy.title,
        body: copy.body,
        hour: 20,
        minute: 0,
        payload: eveningRecapPayload,
      );
    }
  }

  static Future<bool> _isVietnamese() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('app_locale') ?? 'vi') == 'vi';
  }
}
