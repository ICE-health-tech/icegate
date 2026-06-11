import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/CalendarProtocol.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Normalized event from the device calendar (Apple Calendar on iOS, system calendars on Android).
class DeviceCalendarEventItem {
  final String id;
  final String calendarId;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarName;
  final String? description;

  const DeviceCalendarEventItem({
    required this.id,
    required this.calendarId,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.calendarName,
    this.description,
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
  static bool _timezonesReady = false;

  static Future<void> _ensureTimezonesReady() async {
    if (_timezonesReady) return;
    try {
      tz_data.initializeTimeZones();
      String? timeZoneString;
      try {
        final dynamic localTimezone = await FlutterTimezone.getLocalTimezone();
        timeZoneString = localTimezone.toString();
      } catch (e) {
        debugPrint('Device calendar timezone lookup failed: $e');
      }
      if (timeZoneString != null && timeZoneString.contains('(')) {
        final match = RegExp(
          r'\((?:ID:\s*)?([^,\s\)]+)',
        ).firstMatch(timeZoneString);
        if (match != null) {
          timeZoneString = match.group(1);
        }
      }
      if (timeZoneString != null) {
        try {
          tz.setLocalLocation(tz.getLocation(timeZoneString));
        } catch (_) {
          tz.setLocalLocation(tz.UTC);
        }
      } else {
        tz.setLocalLocation(tz.UTC);
      }
      _timezonesReady = true;
    } catch (e, stack) {
      debugPrint('Device calendar timezone init error: $e\n$stack');
      try {
        tz.setLocalLocation(tz.UTC);
        _timezonesReady = true;
      } catch (_) {}
    }
  }

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

  Future<bool> _ensureAccess() async {
    if (_accessGranted) return true;
    return restoreAccess();
  }

  Future<List<CalendarProtocol>> fetchCalendars({
    bool writableOnly = false,
  }) async {
    if (!isSupported) return [];
    if (!await _ensureAccess()) {
      final ok = await requestAccess();
      if (!ok) return [];
    }

    final calendarsResult = await _plugin.retrieveCalendars();
    if (!calendarsResult.isSuccess || calendarsResult.data == null) {
      return [];
    }

    final items = calendarsResult.data!
        .where((c) => c.id != null && c.id!.isNotEmpty)
        .map(_calendarFromPlugin)
        .where((c) => c.id.isNotEmpty)
        .toList();

    if (writableOnly) {
      return items.where((c) => c.isWritable).toList();
    }
    return items;
  }

  /// Default writable calendar, or null if none available.
  Future<CalendarProtocol?> defaultWritableCalendar() async {
    final writable = await fetchCalendars(writableOnly: true);
    if (writable.isEmpty) return null;
    return writable.firstWhere(
      (c) => c.isDefault,
      orElse: () => writable.first,
    );
  }

  Future<List<DeviceCalendarEventItem>> fetchEvents({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    await _ensureTimezonesReady();
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
        final parsed = _parseEvent(event, calendarId, calendar.name);
        if (parsed == null) continue;
        final key = '${calendar.id}|${parsed.id}';
        if (seen.add(key)) items.add(parsed);
      }
    }

    items.sort((a, b) => a.start.compareTo(b.start));
    return items;
  }

  /// Creates an event in [calendar], or the default writable calendar when omitted.
  ///
  /// Returns the new event id on success, or null on failure (see
  /// [lastAccessError] for the reason). Requests calendar access if needed.
  Future<String?> createEvent({
    required String title,
    required DateTime start,
    required DateTime end,
    CalendarProtocol? calendar,
    String? description,
    bool allDay = false,
  }) async {
    lastAccessError = null;
    if (!isSupported) {
      lastAccessError = 'unsupported';
      return null;
    }
    await _ensureTimezonesReady();
    if (!await _ensureAccess()) {
      final ok = await requestAccess();
      if (!ok) return null;
    }

    try {
      final target = calendar ?? await defaultWritableCalendar();
      if (target == null) {
        lastAccessError = 'no_writable_calendar';
        return null;
      }
      if (!target.isWritable) {
        lastAccessError = 'calendar_read_only';
        return null;
      }

      final event = Event(
        target.id,
        title: title,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        description: description,
        allDay: allDay,
      );

      final result = await _plugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess && result.data != null) {
        return result.data;
      }
      lastAccessError = result?.errors.isNotEmpty == true
          ? result!.errors.map((e) => e.errorMessage).join(', ')
          : 'create_failed';
      return null;
    } catch (e, stack) {
      lastAccessError = e.toString();
      debugPrint('Device calendar create error: $e\n$stack');
      return null;
    }
  }

  /// Updates an existing event on the device calendar.
  Future<bool> updateEvent({
    required String calendarId,
    required String eventId,
    required String title,
    required DateTime start,
    required DateTime end,
    String? description,
    bool allDay = false,
  }) async {
    lastAccessError = null;
    if (!isSupported) {
      lastAccessError = 'unsupported';
      return false;
    }
    await _ensureTimezonesReady();
    if (!await _ensureAccess()) return false;

    try {
      final event = Event(
        calendarId,
        eventId: eventId,
        title: title,
        start: tz.TZDateTime.from(start, tz.local),
        end: tz.TZDateTime.from(end, tz.local),
        description: description,
        allDay: allDay,
      );
      final result = await _plugin.createOrUpdateEvent(event);
      if (result != null && result.isSuccess) return true;
      lastAccessError = result?.errors.isNotEmpty == true
          ? result!.errors.map((e) => e.errorMessage).join(', ')
          : 'update_failed';
      return false;
    } catch (e, stack) {
      lastAccessError = e.toString();
      debugPrint('Device calendar update error: $e\n$stack');
      return false;
    }
  }

  /// Deletes an event from the device calendar.
  Future<bool> deleteEvent({
    required String calendarId,
    required String eventId,
  }) async {
    lastAccessError = null;
    if (!isSupported) {
      lastAccessError = 'unsupported';
      return false;
    }
    if (!await _ensureAccess()) return false;

    try {
      final result = await _plugin.deleteEvent(calendarId, eventId);
      if (result.isSuccess && result.data == true) return true;
      lastAccessError = result.errors.isNotEmpty
          ? result.errors.map((e) => e.errorMessage).join(', ')
          : 'delete_failed';
      return false;
    } catch (e, stack) {
      lastAccessError = e.toString();
      debugPrint('Device calendar delete error: $e\n$stack');
      return false;
    }
  }

  CalendarProtocol _calendarFromPlugin(Calendar calendar) {
    return CalendarProtocol(
      id: calendar.id ?? '',
      name: (calendar.name ?? '').trim().isEmpty
          ? 'Calendar'
          : calendar.name!.trim(),
      isReadOnly: calendar.isReadOnly ?? false,
      isDefault: calendar.isDefault ?? false,
      color: calendar.color,
      accountName: calendar.accountName,
    );
  }

  DeviceCalendarEventItem? _parseEvent(
    Event event,
    String calendarId,
    String? calendarName,
  ) {
    final startTz = event.start;
    if (startTz == null) return null;

    final start = startTz.toLocal();
    final endTz = event.end;
    final end = endTz?.toLocal();
    final eventId = event.eventId ?? '${start.millisecondsSinceEpoch}';

    return DeviceCalendarEventItem(
      id: eventId,
      calendarId: event.calendarId ?? calendarId,
      title: (event.title ?? '').trim().isEmpty ? '—' : event.title!.trim(),
      start: start,
      end: end,
      allDay: event.allDay ?? false,
      calendarName: calendarName,
      description: event.description?.trim(),
    );
  }
}
