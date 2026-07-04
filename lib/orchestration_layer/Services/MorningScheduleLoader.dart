import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';

/// One row in the morning briefing "today" schedule.
class MorningScheduleItem {
  const MorningScheduleItem({
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
  });

  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
}

/// Today's calendar snapshot for the morning briefing sheet.
class MorningScheduleSnapshot {
  const MorningScheduleSnapshot({
    required this.items,
    required this.hasCalendarSource,
  });

  final List<MorningScheduleItem> items;
  final bool hasCalendarSource;

  bool get isEmpty => items.isEmpty;
}

/// Loads today's events from app log, Google, and device calendars (best effort).
abstract final class MorningScheduleLoader {
  /// [forDay] defaults to today; morning notification passes its fire day.
  static Future<MorningScheduleSnapshot> loadToday({
    required AppDatabase db,
    required String personId,
    required GoogleCalendarService google,
    required DeviceCalendarService device,
    DateTime? forDay,
  }) async {
    final base = forDay ?? DateTime.now();
    final day = DateTime(base.year, base.month, base.day);
    final dayEnd = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

    final items = <MorningScheduleItem>[];
    var hasSource = false;

    if (personId.isNotEmpty) {
      final logged = await db.eventsDAO.listEventsForPersonInRange(
        personId,
        day,
        dayEnd,
      );
      if (logged.isNotEmpty) hasSource = true;
      for (final event in logged) {
        final title = event.name.trim();
        if (title.isEmpty) continue;
        items.add(
          MorningScheduleItem(
            title: title,
            start: event.occurredAt,
          ),
        );
      }
    }

    if (google.isSignedIn || await google.signIn(interactive: false)) {
      hasSource = true;
      final googleEvents = await google.fetchEvents(
        rangeStart: day,
        rangeEnd: dayEnd,
      );
      for (final event in googleEvents) {
        if (!event.occursOnDay(day)) continue;
        final title = event.title.trim();
        if (title.isEmpty) continue;
        items.add(
          MorningScheduleItem(
            title: title,
            start: event.start,
            end: event.end,
            allDay: event.allDay,
          ),
        );
      }
    }

    if (device.hasAccess) {
      hasSource = true;
      final deviceEvents = await device.fetchEvents(
        rangeStart: day,
        rangeEnd: dayEnd,
      );
      for (final event in deviceEvents) {
        if (!event.occursOnDay(day)) continue;
        final title = event.title.trim();
        if (title.isEmpty) continue;
        items.add(
          MorningScheduleItem(
            title: title,
            start: event.start,
            end: event.end,
            allDay: event.allDay,
          ),
        );
      }
    }

    items.sort((a, b) {
      if (a.allDay != b.allDay) return a.allDay ? -1 : 1;
      return a.start.compareTo(b.start);
    });

    return MorningScheduleSnapshot(
      items: items,
      hasCalendarSource: hasSource,
    );
  }
}
