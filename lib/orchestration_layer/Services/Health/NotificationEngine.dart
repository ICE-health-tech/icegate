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
    int? activeProjects,
    int? activeTasks,
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
      final steps =
          motivation.pillars.where((p) => p.id == 'steps').firstOrNull;
      if (steps != null && steps.progress < 0.5) {
        final copy = MotivationEngine.nudgeCopy(
          pillarId: 'steps',
          vietnamese: vi,
          value: steps.value,
          goal: steps.goal,
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
      final water =
          motivation.pillars.where((p) => p.id == 'water').firstOrNull;
      if (water != null && water.progress < 0.4) {
        final copy = MotivationEngine.nudgeCopy(
          pillarId: 'water',
          vietnamese: vi,
          value: water.value,
          goal: water.goal,
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
        body: _eveningRecapBody(
          motivation: motivation,
          activeProjects: activeProjects,
          activeTasks: activeTasks,
          vietnamese: vi,
          fallback: copy.body,
        ),
        hour: 20,
        minute: 0,
        payload: eveningRecapPayload,
      );
    }
  }

  /// STORY: First list the pillars still short of goal with their real
  /// numbers. Then append open projects/tasks. So the 20:00 recap shows the
  /// whole day, not one generic sentence.
  static String _eveningRecapBody({
    required DailyMotivationResult motivation,
    required int? activeProjects,
    required int? activeTasks,
    required bool vietnamese,
    required String fallback,
  }) {
    final lines = <String>[];

    final unfinished = motivation.pillars
        .where((p) => p.progress < 1 && p.goal > 0)
        .toList()
      ..sort((a, b) => a.progress.compareTo(b.progress));
    if (unfinished.isNotEmpty) {
      lines.add(
        unfinished
            .take(3)
            .map(
              (p) => MotivationEngine.formatPillarStat(
                pillarId: p.id,
                value: p.value,
                goal: p.goal,
                vietnamese: vietnamese,
              ),
            )
            .join(' · '),
      );
    }

    final projects = activeProjects ?? 0;
    final tasks = activeTasks ?? 0;
    if (projects > 0 || tasks > 0) {
      lines.add(
        vietnamese
            ? '$projects dự án · $tasks task đang mở'
            : '$projects projects · $tasks tasks open',
      );
    }

    return lines.isEmpty ? fallback : lines.join('\n');
  }

  static Future<bool> _isVietnamese() async {
    final p = await SharedPreferences.getInstance();
    return (p.getString('app_locale') ?? 'vi') == 'vi';
  }
}
