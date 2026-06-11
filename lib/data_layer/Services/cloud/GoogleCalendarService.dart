import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/calendar/v3.dart' as cal;
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleApiError.dart';

/// A normalized event from Google Calendar for in-app display.
class GoogleCalendarEventItem {
  final String id;
  final String title;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final String? calendarId;
  final String? calendarName;

  const GoogleCalendarEventItem({
    required this.id,
    required this.title,
    required this.start,
    this.end,
    this.allDay = false,
    this.calendarId,
    this.calendarName,
  });

  DateTime get dayLocal => DateTime(start.year, start.month, start.day);

  /// Each local day this event should appear on (handles multi-day all-day).
  Iterable<DateTime> daysSpanned() sync* {
    final startDay = DateTime(start.year, start.month, start.day);
    if (!allDay) {
      yield startDay;
      return;
    }
    final endDay = end;
    final lastInclusive = endDay != null
        ? DateTime(endDay.year, endDay.month, endDay.day)
            .subtract(const Duration(days: 1))
        : startDay;
    var cursor = startDay;
    while (!cursor.isAfter(lastInclusive)) {
      yield DateTime(cursor.year, cursor.month, cursor.day);
      cursor = cursor.add(const Duration(days: 1));
    }
  }

  bool occursOnDay(DateTime day) {
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    if (allDay) {
      for (final d in daysSpanned()) {
        if (d == dayStart) return true;
      }
      return false;
    }

    final eventEnd = end ?? start.add(const Duration(hours: 1));
    return start.isBefore(dayEnd) && eventEnd.isAfter(dayStart);
  }
}

class GoogleCalendarService {
  GoogleSignInAccount? _account;
  cal.CalendarApi? _calendarApi;
  String? lastSignInError;

  bool get isSignedIn => _account != null && _calendarApi != null;

  Future<bool> signIn({bool interactive = true}) async {
    lastSignInError = null;
    try {
      var account = await GoogleSignInHub.silentAccount();
      if (account == null && interactive) {
        account = await GoogleSignInHub.interactiveSignIn();
      }
      if (account == null) {
        lastSignInError = 'cancelled';
        return false;
      }

      final scopesOk = await GoogleSignInHub.ensureScopes(
        [cal.CalendarApi.calendarReadonlyScope],
      );
      if (!scopesOk) {
        lastSignInError = 'scope_denied';
        return false;
      }

      _account = account;
      _calendarApi = cal.CalendarApi(GoogleAuthorizedClient(account));
      if (!await verifyApiAccess()) return false;
      return true;
    } catch (e, stack) {
      lastSignInError = GoogleApiError.classify(e);
      debugPrint('Google Calendar sign-in error: $e\n$stack');
      return false;
    }
  }

  Future<bool> restoreSession() => signIn(interactive: false);

  /// Lightweight probe — catches disabled Calendar API in GCP (403).
  Future<bool> verifyApiAccess() async {
    final api = _calendarApi;
    if (api == null) return false;
    try {
      await api.calendarList.list(maxResults: 1);
      return true;
    } catch (e, stack) {
      lastSignInError = GoogleApiError.classify(e);
      debugPrint('Google Calendar API probe failed: $e\n$stack');
      return false;
    }
  }

  Future<void> signOut() async {
    await GoogleSignInHub.signIn.signOut();
    _account = null;
    _calendarApi = null;
  }

  /// Fetches single-instance events from every readable Google calendar.
  Future<List<GoogleCalendarEventItem>> fetchEvents({
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) async {
    if (_calendarApi == null) {
      final ok = await signIn(interactive: false);
      if (!ok) return [];
    }
    final api = _calendarApi!;

    final timeMin = DateTime(
      rangeStart.year,
      rangeStart.month,
      rangeStart.day,
    ).toUtc();
    final timeMax = DateTime(
      rangeEnd.year,
      rangeEnd.month,
      rangeEnd.day,
      23,
      59,
      59,
    ).toUtc();

    try {
      final listResponse = await api.calendarList.list();
      final calendars = listResponse.items ?? <cal.CalendarListEntry>[];

      final items = <GoogleCalendarEventItem>[];
      final seen = <String>{};

      for (final entry in calendars) {
        final calendarId = entry.id;
        if (calendarId == null || entry.hidden == true) continue;
        final role = entry.accessRole;
        if (role == 'freeBusyReader') continue;

        try {
          final calendarName =
              entry.summary?.trim().isNotEmpty == true
                  ? entry.summary!.trim()
                  : calendarId;

          String? pageToken;
          do {
            final response = await api.events.list(
              calendarId,
              timeMin: timeMin,
              timeMax: timeMax,
              singleEvents: true,
              orderBy: 'startTime',
              maxResults: 250,
              pageToken: pageToken,
            );

            for (final event in response.items ?? <cal.Event>[]) {
              final parsed = _parseEvent(
                event,
                calendarId: calendarId,
                calendarName: calendarName,
              );
              if (parsed == null) continue;
              final key = '$calendarId|${parsed.id}';
              if (seen.add(key)) items.add(parsed);
            }
            pageToken = response.nextPageToken;
          } while (pageToken != null);
        } catch (e, stack) {
          debugPrint(
            'Google Calendar: skip "$calendarId" (${entry.summary}): $e\n$stack',
          );
        }
      }

      items.sort((a, b) => a.start.compareTo(b.start));
      return items;
    } catch (e, stack) {
      lastSignInError = GoogleApiError.classify(e);
      debugPrint('Google Calendar fetch error: $e\n$stack');
      rethrow;
    }
  }

  GoogleCalendarEventItem? _parseEvent(
    cal.Event event, {
    String? calendarId,
    String? calendarName,
  }) {
    final start = event.start;
    if (start == null) return null;

    DateTime startLocal;
    DateTime? endLocal;
    var allDay = false;

    if (start.date != null) {
      allDay = true;
      final d = start.date!;
      startLocal = DateTime(d.year, d.month, d.day);
      if (event.end?.date != null) {
        final e = event.end!.date!;
        endLocal = DateTime(e.year, e.month, e.day);
      }
    } else if (start.dateTime != null) {
      startLocal = start.dateTime!.toLocal();
      if (event.end?.dateTime != null) {
        endLocal = event.end!.dateTime!.toLocal();
      }
    } else {
      return null;
    }

    return GoogleCalendarEventItem(
      id: event.id ?? '${startLocal.millisecondsSinceEpoch}',
      title: (event.summary?.trim().isNotEmpty ?? false)
          ? event.summary!.trim()
          : '(No title)',
      start: startLocal,
      end: endLocal,
      allDay: allDay,
      calendarId: calendarId,
      calendarName: calendarName,
    );
  }
}
