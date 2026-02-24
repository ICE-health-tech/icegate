import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:signals/signals.dart';

import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class LocalNotificationService {
  // 1. Create the plugin instance
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  /// Whether notifications are currently enabled
  final notificationsEnabled = signal<bool>(true);

  AppDatabase? _database;

  Future<void> init([AppDatabase? database]) async {
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
      onDidReceiveNotificationResponse: (details) {
        // Handle tap logic here
      },
    );

    // Schedule daily briefing and custom notifications
    try {
      await syncAllNotifications();
    } catch (e) {
      print("Warning: Failed to sync notifications on startup: $e");
    }
  }

  /// Toggle notifications on or off
  Future<void> setNotificationsEnabled(bool enabled) async {
    notificationsEnabled.value = enabled;
    if (enabled) {
      await syncAllNotifications();
      print('🔔 Notifications enabled');
    } else {
      await cancelAllNotifications();
      print('🔕 Notifications disabled');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notificationsPlugin.cancel(id: id);
  }

  /// Sync all notifications (daily + custom from DB)
  Future<void> syncAllNotifications() async {
    if (!notificationsEnabled.value) return;

    // Daily notification
    await scheduleDailyNotification();

    // Retention notifications (Engagement)
    await scheduleRetentionNotifications();

    // Custom notifications from database
    if (_database != null) {
      final customNotifications = await _database!.customNotificationDAO
          .getAllEnabledNotifications();
      for (final notification in customNotifications) {
        await scheduleCustomNotification(notification);
      }
    }
  }

  Future<void> scheduleRetentionNotifications() async {
    if (!notificationsEnabled.value) return;

    // 1. Daily Engagement Reminder (9 PM)
    await _notificationsPlugin.zonedSchedule(
      id: 999,
      title: 'Daily Review 🌙',
      body:
          'Time to review your progress! Check how you did in Health and Projects today.',
      scheduledDate: _nextInstanceOfTime(
        DateTime(2024, 1, 1, 21, 0), // 9:00 PM
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'retention_channel',
          'Engagement Reminders',
          channelDescription: 'Notifications to keep you on track',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    // 2. Weekend Summary Reminder (Sunday 10 AM)
    await _notificationsPlugin.zonedSchedule(
      id: 1000,
      title: 'Weekly Summary 📈',
      body:
          "How was your week? Let's check your analysis and plan for the next one!",
      scheduledDate: _nextInstanceOfDay(
        DateTime(2024, 1, 1, 10, 0), // 10:00 AM
        DateTime.sunday,
      ),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'retention_channel',
          'Engagement Reminders',
          channelDescription: 'Notifications to keep you on track',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          interruptionLevel: InterruptionLevel.active,
        ),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleDailyNotification() async {
    if (!notificationsEnabled.value) return;

    final quote = await _getRandomQuote();

    await _notificationsPlugin.zonedSchedule(
      id: 888,
      title: 'Good Morning! ☀️',
      body: quote,
      scheduledDate: _nextInstanceOfSevenAM(),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_channel',
          'Daily Reminder',
          channelDescription: 'Daily 7 AM briefing',
          importance: Importance.max,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
        macOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

    // For weekly, we might need multiple schedules if multiple days are selected
    if (data.repeatFrequency == 'weekly' &&
        data.repeatDays != null &&
        data.repeatDays!.isNotEmpty) {
      final selectedDays = data.repeatDays!
          .split(',')
          .map((e) => int.parse(e))
          .toList();
      for (final day in selectedDays) {
        // We need a unique ID for each day of the weekly repeat
        // Using notificationID + day offset to keep it unique but related
        final dayId =
            data.notificationID.hashCode * 100 + day; // Using 100 to avoid overlap
        await _notificationsPlugin.zonedSchedule(
          id: dayId,
          title: data.title,
          body: data.content,
          scheduledDate: _nextInstanceOfDay(data.scheduledTime, day),
          notificationDetails: _customNotificationDetails(),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    } else {
      await _notificationsPlugin.zonedSchedule(
        id: data.notificationID.hashCode,
        title: data.title,
        body: data.content,
        scheduledDate: matchComponents != null
            ? _nextInstanceOfTime(data.scheduledTime)
            : scheduledDate,
        notificationDetails: _customNotificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: matchComponents,
      );
    }
  }

  Future<String> _getRandomQuote() async {
    if (_database != null) {
      final quotes = await _database!.quoteDAO.getAllQuotes();
      final activeQuotes = quotes.where((q) => q.isActive).toList();
      if (activeQuotes.isNotEmpty) {
        final quote = activeQuotes[DateTime.now().day % activeQuotes.length];
        return "${quote.content} ${quote.author != null ? '- ${quote.author}' : ''}";
      }
    }

    // Default Fallback Quotes
    final defaultQuotes = [
      "The only way to do great work is to love what you do.",
      "Innovation distinguishes between a leader and a follower.",
      "Stay hungry, stay foolish.",
      "Your time is limited, don't waste it living someone else's life.",
      "Design is not just what it looks like and feels like. Design is how it works.",
    ];
    return defaultQuotes[DateTime.now().day % defaultQuotes.length];
  }

  NotificationDetails _customNotificationDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'custom_channel',
        'Custom Notifications',
        channelDescription: 'User scheduled notifications',
        importance: Importance.max,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
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

  tz.TZDateTime _nextInstanceOfSevenAM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      7,
    );
    // If scheduled date is now OR in the past, move to the next day
    if (!scheduledDate.isAfter(now)) {
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
