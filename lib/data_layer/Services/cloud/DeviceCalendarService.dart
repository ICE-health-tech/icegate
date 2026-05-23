import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

/// Normalized event from the device calendar (Apple Calendar on iOS, system calendars on Android).
class DeviceCalendarEventItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarName;

  const DeviceCalendarEventItem({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.calendarName,
  });

  DateTime get dayLocal => DateTime(start.year, start.month, start.day);

  bool occursOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (allDay) {
      final startDay = DateTime(start.year, start.month, start.day);
      final endLocal = end;
      if (endLocal == null) return startDay == dayStart;
      final endDay = DateTime(endLocal.year, endLocal.month, endLocal.day);
      return !dayStart.isBefore(startDay) && !dayStart.isAfter(endDay);
    }

    final eventEnd = end ?? start.add(const Duration(hours: 1));
    return start.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }

  Iterable<DateTime> daysSpanned() sync* {
    final startDay = DateTime(start.year, start.month, start.day);
    if (!allDay || end == null) {
      yield startDay;
      return;
    }
    final endLocal = end!;
    final endDay = DateTime(endLocal.year, endLocal.month, endLocal.day);
    var cursor = startDay;
    while (!cursor.isAfter(endDay)) {
      yield DateTime(cursor.year, cursor.month, cursor.day);
      cursor = cursor.add(const Duration(days: 1));
    }
  }
}

class DeviceCalendarService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  bool _accessGranted = false;
  String? lastAccessError;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool get hasAccess => _accessGranted;

  Future<bool> requestAccess() async {
    lastAccessError = null;
    if (!isSupported) {
      lastAccessError = 'unsupported';
      return false;
    }
    try {
      final has = await _plugin.hasPermissions();
      if (has.isSuccess && has.data == true) {
        _accessGranted = true;
        return true;
      }
      final granted = await _plugin.requestPermissions();
      _accessGranted = granted.isSuccess && granted.data == true;
      if (!_accessGranted) lastAccessError = 'denied';
      return _accessGranted;
    } catch (e, stack) {
      lastAccessError = e.toString();
      debugPrint('Device calendar permission error: $e\n$stack');
      return false;
    }
  }

  Future<bool> restoreAccess() async {
    if (!isSupported) return false;
    try {
      final has = await _plugin.hasPermissions();
      _accessGranted = has.isSuccess && has.data == true;
      return _accessGranted;
    } catch (e, stack) {
      debugPrint('Device calendar restore error: $e\n$stack');
      _accessGranted = false;
      return false;
    }
  }

  void disconnect() {
    _accessGranted = false;
  }

  Future<List<DeviceCalendarEventItem>> fetchEvents({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (!_accessGranted) {
      final ok = await restoreAccess();
      if (!ok) return [];
    }

    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return [];
    }

    final start = tz.TZDateTime.from(
      DateTime(rangeStart.year, rangeStart.month, rangeStart.day),
      tz.local,
    );
    final end = tz.TZDateTime.from(
      DateTime(rangeEnd.year, rangeEnd.month, rangeEnd.day, 23, 59, 59),
      tz.local,
    );
    final params = RetrieveEventsParams(startDate: start, endDate: end);

    final seen = <String>{};
    final items = <DeviceCalendarEventItem>[];

    for (final calendar in calendarsResult.data!) {
      final calendarId = calendar.id;
      if (calendarId == null) continue;
      final eventsResult = await _plugin.retrieveEvents(calendarId, params);
      if (!eventsResult.isSuccess || eventsResult.data == null) continue;

      for (final event in eventsResult.data!) {
        final parsed = _parseEvent(event, calendar.name);
        if (parsed == null) continue;
        final key = '${calendar.id}|${parsed.id}';
        if (seen.add(key)) items.add(parsed);
      }
    }

    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  DeviceCalendarEventItem? _parseEvent(Event event, String? calendarName) {
    final startTz = event.start;
    if (startTz == null) return null;

    final start = startTz.toLocal();
    final endTz = event.end;
    final end = endTz?.toLocal();

    return DeviceCalendarEventItem(
      id: event.eventId ?? '${start.millisecondsSinceEpoch}',
      title: (event.title ?? '').trim().isEmpty ? '—' : event.title!.trim(),
      start: start,
      end: end,
      allDay: event.allDay ?? false,
      calendarName: calendarName,
    );
  }
}
