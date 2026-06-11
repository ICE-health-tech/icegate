/// Identifies an existing event opened in the create/edit dialog.
class CalendarEventEditTarget {
  const CalendarEventEditTarget.device({
    required this.calendarId,
    required this.eventId,
  }) : loggedEventId = null;

  const CalendarEventEditTarget.logged({required this.loggedEventId})
      : calendarId = null,
        eventId = null;

  final String? calendarId;
  final String? eventId;
  final String? loggedEventId;

  bool get isDevice => calendarId != null && eventId != null;
  bool get isLogged => loggedEventId != null;
}

/// Result of saving a calendar event from the in-app create dialog.
class CalendarEventSaveResult {
  const CalendarEventSaveResult({
    required this.day,
    required this.start,
    required this.end,
    required this.title,
    this.description,
    this.savedToDeviceCalendar = false,
    this.wasEdit = false,
  });

  final DateTime day;
  final DateTime start;
  final DateTime end;
  final String title;
  final String? description;
  final bool savedToDeviceCalendar;
  final bool wasEdit;
}
