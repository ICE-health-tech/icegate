import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/link_layer/ui_route/InternalRoute.dart';
import 'package:ice_gate/orchestration_layer/Services/DailyFinanceReportPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/DailyMailSummaryPrefs.dart';
import 'package:signals/signals.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  // 1. Create the plugin instance
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Stable ID so [syncAllNotifications] can cancel+restore alongside DB-driven reminders.
  static const int dailyFinanceReportNotificationId = 920001;

  /// Payload consumed by [router] for deep-link taps (see [initialize] callbacks).
  static const String dailyFinanceReportPayload =
      'route:/finance/reports/daily';

  static const int dailyMailSummaryNotificationId = 920002;

  static const String dailyMailSummaryPayload = 'action:send_daily_mail_summary';

  /// Invoked when the user opens the app from the daily mail reminder.
  Future<void> Function()? onDailyMailSummaryTriggered;

  /// Whether notifications are currently enabled
  final notificationsEnabled = signal<bool>(true);

  /// Number of custom notifications currently enabled and scheduled
  final numberOfEnabledNotifications = signal<int>(0);

  AppDatabase? _database;
  StreamSubscription<int>? _enabledNotificationsSubscription;

  Future<void> init([AppDatabase? database]) async {
    if (kIsWeb) {
      debugPrint("🌐 Notifications not supported on web. Skipping init.");
      return;
    }
    _database = database;
    // Initialize Timezones
    try {
      tz.initializeTimeZones();
      String? timeZoneString;

      try {
        final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
        timeZoneString = localTimezone.toString();
      } catch (e) {
        debugPrint("Could not get local timezone: $e");
      }

      if (timeZoneString != null) {
        // Clean up complex strings from some platforms (e.g., "TimezoneInfo(ID: Asia/Ho_Chi_Minh, ...)")
        if (timeZoneString.contains('(')) {
          final match = RegExp(
            r'\((?:ID:\s*)?([^,\s\)]+)',
          ).firstMatch(timeZoneString);
          if (match != null) {
            timeZoneString = match.group(1);
          }
        }

        try {
          tz.setLocalLocation(tz.getLocation(timeZoneString!));
          debugPrint("✅ Timezone set to $timeZoneString");
        } catch (e) {
          debugPrint(
            "⚠️ Invalid timezone '$timeZoneString': $e. Falling back.",
          );
          _setFallbackTimezone();
        }
      } else {
        _setFallbackTimezone();
      }
    } catch (e) {
      debugPrint("❌ Critical error in timezone initialization: $e");
      try {
        tz.setLocalLocation(tz.UTC);
      } catch (_) {}
    }

    // 2. Android Initialization Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS Initialization Settings
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
          macOS: initializationSettingsIOS,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    await _handleColdStartNotificationNavigation();

    // 4. Request Permissions for macOS/iOS
    await requestPermissions();

    debugPrint("🚀 LocalNotificationService Initialized Successfully");
  }

  void _onNotificationResponse(NotificationResponse details) {
    debugPrint(
      "🔔 Notification Tapped: ${details.id} | Payload: ${details.payload}",
    );
    if (details.payload == dailyMailSummaryPayload) {
      onDailyMailSummaryTriggered?.call();
      return;
    }
    _navigateFromNotificationPayload(details.payload);
  }

  void _navigateFromNotificationPayload(String? payload) {
    if (payload == null || !payload.startsWith('route:')) return;
    final path = payload.substring('route:'.length);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(path);
    });
  }

  Future<void> _handleColdStartNotificationNavigation() async {
    if (kIsWeb) return;
    try {
      final details = await _notificationsPlugin.getNotificationAppLaunchDetails();
      final payload = details?.notificationResponse?.payload;
      if (details?.didNotificationLaunchApp ?? false) {
        _navigateFromNotificationPayload(payload);
      }
    } catch (e) {
      debugPrint('Cold-start notification routing skipped: $e');
    }
  }

  /// Schedules the repeating daily finance reminder if prefs allow and global toggle is on.
  /// Call after [syncAllNotifications] (which uses [cancelAll]) so this reminder is restored.
  Future<void> scheduleDailyFinanceReportFromPrefs() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id: dailyFinanceReportNotificationId);

    final prefsEnabled = await DailyFinanceReportPrefs.getEnabled();
    if (!prefsEnabled || !notificationsEnabled.value) return;

    final hour = await DailyFinanceReportPrefs.getHour();
    final minute = await DailyFinanceReportPrefs.getMinute();
    final scheduledClock =
        DateTime(1970, 1, 1, hour, minute); // date ignored by [_nextInstanceOfTime]
    final scheduledDate = _nextInstanceOfTime(scheduledClock);

    const android = AndroidNotificationDetails(
      'finance_report_channel',
      'Finance reports',
      channelDescription: 'Daily finance summary reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: dailyFinanceReportNotificationId,
      title: 'Daily finance summary',
      body: 'Tap to open today\'s report',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: dailyFinanceReportPayload,
    );
    debugPrint('📅 Daily finance report notification scheduled at $hour:$minute');
  }

  /// Local reminder for automatic daily email report (send runs when app is open).
  Future<void> scheduleDailyMailSummaryFromPrefs() async {
    if (kIsWeb) return;
    await _notificationsPlugin.cancel(id: dailyMailSummaryNotificationId);

    final prefsEnabled = await DailyMailSummaryPrefs.getEnabled();
    if (!prefsEnabled || !notificationsEnabled.value) return;

    final hour = await DailyMailSummaryPrefs.getHour();
    final minute = await DailyMailSummaryPrefs.getMinute();
    final scheduledClock = DateTime(1970, 1, 1, hour, minute);
    final scheduledDate = _nextInstanceOfTime(scheduledClock);

    const android = AndroidNotificationDetails(
      'mail_report_channel',
      'Email reports',
      channelDescription: 'Daily email report reminders',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const details = NotificationDetails(
      android: android,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.zonedSchedule(
      id: dailyMailSummaryNotificationId,
      title: 'Daily email report',
      body: 'Open Ice Gate to send today\'s summary',
      scheduledDate: scheduledDate,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: dailyMailSummaryPayload,
    );
    debugPrint('📅 Daily mail summary reminder scheduled at $hour:$minute');
  }

  /// Request permissions for macOS and iOS
  Future<void> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      debugPrint(
        "🍎 Requesting Notification Permissions for Apple platform...",
      );
      final bool? granted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            MacOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      // Also check iOS specifically if needed (though macOS uses the same often)
      final bool? iosGranted = await _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);

      debugPrint("🍎 Permission Status - macOS: $granted | iOS: $iosGranted");
    }
  }

  /// Toggle notifications on or off
  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    if (enabled) {
      debugPrint('🔔 Notifications manual toggle: ENABLED');
      await scheduleDailyFinanceReportFromPrefs();
      await scheduleDailyMailSummaryFromPrefs();
    } else {
      await cancelAllNotifications();
      debugPrint('🔕 Notifications manual toggle: DISABLED (All cancelled)');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    debugPrint("🧹 Cancelling all pending notifications...");
    await _notificationsPlugin.cancelAll();
  }

  /// Start watching enabled notifications count for badge display
  void startWatchingEnabledNotifications(String personId) {
    if (_database == null || personId.isEmpty) return;
    
    _enabledNotificationsSubscription?.cancel();
    _enabledNotificationsSubscription = _database!.customNotificationDAO
        .watchEnabledNotificationsCount(personId)
        .listen((count) {
      numberOfEnabledNotifications.value = count;
    });
  }

  void dispose() {
    _enabledNotificationsSubscription?.cancel();
  }

  Future<void> cancelNotification(int id) async {
    debugPrint("🧹 Cancelling notification ID: $id");
    await _notificationsPlugin.cancel(id: id);
  }

  /// Sync all custom notifications from DB for a specific person
  Future<void> syncAllNotifications(String personId) async {
    if (personId.isEmpty) return;

    // First, clear all existing schedules to prevent "ghost" notifications from deleted records
    debugPrint("🧹 Clearing all scheduled notifications before sync...");
    await _notificationsPlugin.cancelAll();

    // If global toggle is off, stop here after clearing
    if (!notificationsEnabled.value) {
      debugPrint("🔕 Notifications are disabled globally. Sync aborted.");
      return;
    }

    // Custom notifications from database
    if (_database != null) {
      try {
        final customNotifications = await _database!.customNotificationDAO
            .getAllEnabledNotifications(personId);
        for (final notification in customNotifications) {
          try {
            await scheduleCustomNotification(notification);
          } catch (e) {
            print(
              "Warning: Failed to schedule notification ${notification.id}: $e",
            );
          }
        }
      } catch (e) {
        print("Warning: Failed to sync notifications: $e");
      }
    }

    await scheduleDailyFinanceReportFromPrefs();
    await scheduleDailyMailSummaryFromPrefs();
  }

  Future<void> scheduleCustomNotification(CustomNotificationData data) async {
    if (!notificationsEnabled.value || !data.isEnabled) return;

    final now = tz.TZDateTime.now(tz.local);
    final scheduledDate = tz.TZDateTime.from(data.scheduledTime, tz.local);
    DateTimeComponents? matchComponents;

    switch (data.repeatFrequency ?? 'none') {
      case 'daily':
        matchComponents = DateTimeComponents.time;
        break;
      case 'weekly':
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      default:
        matchComponents = null;
    }

    // Guard: If it's a one-time notification and it's in the past, skip it.
    if (matchComponents == null && scheduledDate.isBefore(now)) {
      print('Skipping past one-time notification: ${data.title}');
      return;
    }

    final details = _customNotificationDetails(data.category, data.priority);

    // For weekly, we might need multiple schedules if multiple days are selected
    if (data.repeatFrequency == 'weekly' &&
        data.repeatDays != null &&
        data.repeatDays!.isNotEmpty) {
      final selectedDays = data.repeatDays!
          .split(',')
          .map((e) => int.parse(e.trim()))
          .toList();

      debugPrint(
        "📅 Scheduling WEEKLY notification '${data.title}' for days: $selectedDays",
      );

      for (final day in selectedDays) {
        final dayInt = day.toInt();
        // Unique ID per day: Combine hashCode with day index
        final dayId = (data.notificationID.hashCode % 100000) * 10 + dayInt;

        await _notificationsPlugin.zonedSchedule(
          id: dayId,
          title: data.title,
          body: data.content,
          scheduledDate: _nextInstanceOfDay(data.scheduledTime, day),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
      debugPrint("✅ Weekly instances scheduled for '${data.title}'");
    } else {
      final intId = data.notificationID.hashCode % 1000000;
      debugPrint(
        "📅 Scheduling notification '${data.title}' (ID: $intId) at ${matchComponents != null ? 'repeating time' : scheduledDate}",
      );

      await _notificationsPlugin.zonedSchedule(
        id: intId,
        title: data.title,
        body: data.content,
        scheduledDate: matchComponents != null
            ? _nextInstanceOfTime(data.scheduledTime)
            : scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
      debugPrint("✅ Notification Scheduled: '${data.title}'");
    }
  }

  NotificationDetails _customNotificationDetails(
    String category,
    String priority,
  ) {
    final Importance importance = switch (priority) {
      'Urgent' => Importance.max,
      'High' => Importance.high,
      'Normal' => Importance.defaultImportance,
      'Low' => Importance.min,
      _ => Importance.defaultImportance,
    };

    final Priority p = switch (priority) {
      'Urgent' => Priority.max,
      'High' => Priority.high,
      'Normal' => Priority.defaultPriority,
      'Low' => Priority.min,
      _ => Priority.defaultPriority,
    };

    // Use category for channel ID/Name
    final String channelId =
        "${category.toLowerCase().replaceAll(' ', '_')}_channel";

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        category,
        channelDescription: '$category notifications',
        importance: importance,
        priority: p,
      ),
      iOS: DarwinNotificationDetails(
        interruptionLevel: switch (priority) {
          'Urgent' => InterruptionLevel.critical,
          'High' => InterruptionLevel.active,
          'Normal' => InterruptionLevel.active,
          'Low' => InterruptionLevel.passive,
          _ => InterruptionLevel.active,
        },
      ),
      macOS: const DarwinNotificationDetails(),
    );
  }

  tz.TZDateTime _nextInstanceOfTime(DateTime time) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    // If scheduled date is now OR in the past, move to the next day
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  tz.TZDateTime _nextInstanceOfDay(DateTime time, int dayOfWeek) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(time);
    // Convert Monday=1, Sunday=7 (Dart/TZDateTime)
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  // 4. Show a simple notification (respects enabled toggle, unless forced for Focus)
  // Updated to handle channel selection based on ID or content
  Future<void> showNotification(int id, String title, String body) async {
    // Determine channel based on ID or content
    // ID 888 is strictly for Focus Timer
    if (id == 888) {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'focus_channel',
            'Focus Session',
            channelDescription: 'Active focus session timer',
            importance: Importance.max,
            priority: Priority.high,
            ongoing: true,
            autoCancel: false,
            silent: true, // Don't make sound on updates
          );
      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: false,
          presentList: true, // Show in Notification Center
          interruptionLevel: InterruptionLevel.active,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBanner: true,
          presentSound: false,
        ),
      );
      await _notificationsPlugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: platformChannelSpecifics,
      );
      return;
    }

    if (!notificationsEnabled.value) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'main_channel', // Channel ID
          'Main Channel', // Channel Name
          channelDescription: 'General notifications',
          importance: Importance.max,
          priority: Priority.high,
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }

  void _setFallbackTimezone() {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
      }
    }
  }
}
