import 'dart:async';

import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/CalendarEventSaveResult.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleApiError.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/TaskItem.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/CalendarDayTimeline.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/CalendarReminderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/CreateCalendarEventDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/user_page/widgets/AppSessionCalendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class ProjectsCalendarPage extends StatefulWidget {
  const ProjectsCalendarPage({super.key});

  @override
  State<ProjectsCalendarPage> createState() => _ProjectsCalendarPageState();
}

class _ProjectsCalendarPageState extends State<ProjectsCalendarPage> {
  static const double _desktopBreakpoint = 900;
  static const double _contentMaxWidth = 1140;

  /// Survives route pop/push so reopening Lịch does not refetch the same month.
  static String? _sessionMonthKey;
  static DateTime? _sessionFocusedMonth;
  static DateTime? _sessionSelectedDay;
  static List<GoogleCalendarEventItem> _sessionGoogleEvents = [];
  static List<DeviceCalendarEventItem> _sessionDeviceEvents = [];
  static bool _sessionGoogleConnected = false;
  static bool _sessionDeviceConnected = false;
  static bool _sessionEventsLoaded = false;
  static final Set<String> _sessionHiddenTimelineKeys = {};

  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  List<GoogleCalendarEventItem> _googleEvents = [];
  List<DeviceCalendarEventItem> _deviceEvents = [];
  bool _googleLoading = false;
  bool _deviceLoading = false;
  bool _googleConnected = false;
  bool _deviceConnected = false;
  bool _syncingTasks = false;
  bool _timelineDragging = false;

  final _pageScrollController = ScrollController();

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  ({DateTime start, DateTime end}) _loggedEventsQueryRange(
    DateTime focusedMonth,
  ) {
    final monthStart = DateTime(focusedMonth.year, focusedMonth.month, 1);
    final monthEnd = DateTime(
      focusedMonth.year,
      focusedMonth.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
    return (
      start: monthStart.subtract(const Duration(days: 1)),
      end: monthEnd.add(const Duration(days: 1)),
    );
  }

  Future<void> _syncLoggedEventsForFocusedMonth() async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;
    final range = _loggedEventsQueryRange(_focusedMonth);
    await context.read<AppDatabase>().eventsDAO.syncEventsFromCloud(
      personId,
      rangeStart: range.start,
      rangeEnd: range.end,
    );
  }

  bool _isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

  String _googleTimelineKey(GoogleCalendarEventItem e) => 'g|${e.id}';

  String _deviceTimelineKey(DeviceCalendarEventItem e) => 'd|${e.id}';

  String _reminderTimelineKey(CustomNotificationData n) => 'r|${n.id}';

  void _hideTimelineEntry(String key) {
    setState(() => _sessionHiddenTimelineKeys.add(key));
  }

  void _showTimelineEventSheet(_MergedCalendarEvent event) {
    showCalendarTimelineEventDetailSheet(
      context,
      title: event.title,
      start: event.start,
      end: event.end,
      allDay: event.allDay,
      accentColor: event.iconColor,
      sourceLabel: calendarTimelineSourceLabel(
        event.subtitle,
        event.start,
        Localizations.localeOf(context).toString(),
      ),
      description: event.description,
      canEdit: event.canEdit,
      canDelete: event.canDelete,
      onEdit: event.onEdit,
      onDelete: event.onDelete,
    );
  }

  String _storedLoggedDescription(CalendarEventSaveResult saved) {
    final endTag = '[icegate-end:${saved.end.toUtc().toIso8601String()}]';
    final description = saved.description?.trim();
    if (description == null || description.isEmpty) return endTag;
    return '$description\n$endTag';
  }

  Future<void> _mirrorLoggedAfterDeviceSave(
    DeviceCalendarEventItem before,
    CalendarEventSaveResult saved,
  ) async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;
    final eventsDao = context.read<AppDatabase>().eventsDAO;

    final day = _dateOnly(before.start);
    final logged = await eventsDao.listEventsForPersonInRange(
      personId,
      day,
      DateTime(day.year, day.month, day.day, 23, 59, 59, 999),
    );
    if (!mounted) return;
    for (final event in logged) {
      if (!_deviceEventMatchesLogged(before, event)) continue;
      await eventsDao.updateLoggedEvent(
        id: event.id,
        name: saved.title,
        occurredAt: saved.start,
        description: _storedLoggedDescription(saved),
      );
      break;
    }
  }

  Future<void> _mirrorDeviceAfterLoggedSave(
    EventData before,
    CalendarEventSaveResult saved,
  ) async {
    if (!DeviceCalendarService.isSupported || !_deviceConnected) return;

    DeviceCalendarEventItem? match;
    for (final device in _deviceEvents) {
      if (_deviceEventMatchesLogged(device, before)) {
        match = device;
        break;
      }
    }
    if (match == null) return;

    final service = context.read<DeviceCalendarService>();
    final ok = await service.updateEvent(
      calendarId: match.calendarId,
      eventId: match.id,
      title: saved.title,
      start: saved.start,
      end: saved.end,
      description: saved.description,
    );
    if (!mounted) return;
    if (ok) {
      await _syncDeviceEvents(showSnackBar: false);
    }
  }

  Future<void> _editDeviceEvent(DeviceCalendarEventItem event) async {
    final end = event.end ?? event.start.add(const Duration(hours: 1));
    final saved = await showCreateCalendarEventDialog(
      context,
      initialDay: _dateOnly(event.start),
      initialStart: TimeOfDay.fromDateTime(event.start),
      initialEnd: TimeOfDay.fromDateTime(end),
      initialTitle: event.title,
      initialDescription: event.description,
      editTarget: CalendarEventEditTarget.device(
        calendarId: event.calendarId,
        eventId: event.id,
      ),
    );
    if (saved == null || !mounted) return;
    await _mirrorLoggedAfterDeviceSave(event, saved);
    await _syncDeviceEvents(showSnackBar: false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.projects_calendar_event_saved),
      ),
    );
  }

  Future<void> _deleteDeviceEvent(DeviceCalendarEventItem event) async {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<DeviceCalendarService>();
    final ok = await service.deleteEvent(
      calendarId: event.calendarId,
      eventId: event.id,
    );
    if (!mounted) return;
    if (ok) {
      _hideTimelineEntry(_deviceTimelineKey(event));
      await _syncDeviceEvents(showSnackBar: false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projects_calendar_event_deleted)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.projects_calendar_event_failed}${service.lastAccessError != null ? ': ${service.lastAccessError}' : ''}',
          ),
        ),
      );
    }
  }

  String _loggedDescriptionForEdit(EventData event) {
    final raw = event.description?.trim() ?? '';
    if (raw.isEmpty) return '';
    final lines = raw.split('\n');
    final kept = lines
        .where((line) => !line.trim().startsWith('[icegate-end:'))
        .join('\n')
        .trim();
    return kept;
  }

  Future<void> _editLoggedEvent(EventData event) async {
    final local = event.occurredAt.toLocal();
    final end = _loggedEventEnd(event);
    final saved = await showCreateCalendarEventDialog(
      context,
      initialDay: _dateOnly(local),
      initialStart: TimeOfDay.fromDateTime(local),
      initialEnd: TimeOfDay.fromDateTime(end),
      initialTitle: event.name,
      initialDescription: _loggedDescriptionForEdit(event),
      editTarget: CalendarEventEditTarget.logged(loggedEventId: event.id),
    );
    if (saved == null || !mounted) return;
    await _mirrorDeviceAfterLoggedSave(event, saved);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.projects_calendar_event_saved),
      ),
    );
  }

  Future<void> _deleteLoggedEvent(EventData event) async {
    final l10n = AppLocalizations.of(context)!;
    await context.read<AppDatabase>().eventsDAO.deleteLoggedEvent(event.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.projects_calendar_event_deleted)),
    );
  }

  Future<void> _editReminder(CustomNotificationData reminder) async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;
    await showCalendarReminderDialog(
      context,
      initialDay: reminder.scheduledTime.toLocal(),
      personId: personId,
      existing: reminder,
    );
  }

  void _feedbackEventMoved(DateTime newStart) {
    if (!mounted) return;
    HapticFeedback.lightImpact();
    final locale = Localizations.localeOf(context).toString();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.projects_calendar_event_moved(
            DateFormat.jm(locale).format(newStart),
          ),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _moveDeviceEvent(
    DeviceCalendarEventItem event,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    if (event.allDay) return;
    final service = context.read<DeviceCalendarService>();
    final ok = await service.updateEvent(
      calendarId: event.calendarId,
      eventId: event.id,
      title: event.title,
      start: newStart,
      end: newEnd,
      description: event.description,
    );
    if (!mounted) return;
    if (ok) {
      await _syncDeviceEvents(showSnackBar: false);
      _feedbackEventMoved(newStart);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.projects_calendar_event_failed}${service.lastAccessError != null ? ': ${service.lastAccessError}' : ''}',
          ),
        ),
      );
    }
  }

  Future<void> _moveLoggedEvent(
    EventData event,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final userDesc = _loggedDescriptionForEdit(event);
    final endTag = '[icegate-end:${newEnd.toUtc().toIso8601String()}]';
    final storedDescription =
        userDesc.isEmpty ? endTag : '$userDesc\n$endTag';
    await context.read<AppDatabase>().eventsDAO.updateLoggedEvent(
          id: event.id,
          name: event.name,
          occurredAt: newStart,
          description: storedDescription,
        );
    if (!mounted) return;
    _feedbackEventMoved(newStart);
  }

  Future<void> _moveReminder(
    CustomNotificationData reminder,
    DateTime newStart,
    DateTime newEnd,
  ) async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;
    final numericId =
        '${newStart.hour.toString().padLeft(2, '0')}${newStart.minute.toString().padLeft(2, '0')}';
    final dao = context.read<CustomNotificationDAO>();
    await dao.updateNotification(
      reminder.copyWith(
        notificationID: Value(numericId),
        scheduledTime: newStart,
      ),
    );
    if (!mounted) return;
    await context.read<LocalNotificationService>().syncAllNotifications(
          personId,
        );
    if (!mounted) return;
    _feedbackEventMoved(newStart);
  }

  Future<void> _deleteReminder(CustomNotificationData reminder) async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    final dao = context.read<CustomNotificationDAO>();
    await dao.deleteNotification(reminder.id);
    if (!mounted) return;
    await context.read<LocalNotificationService>().syncAllNotifications(
          personId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.of(context)!.projects_calendar_event_deleted,
        ),
      ),
    );
  }

  void _openAddReminder(String personId) {
    showCalendarReminderDialog(
      context,
      initialDay: _selectedDay,
      personId: personId,
    );
  }

  Future<void> _logLocalCalendarEvent(
    CalendarEventSaveResult result,
    String personId,
  ) async {
    if (personId.isEmpty) return;
    final db = context.read<AppDatabase>();
    final endTag = '[icegate-end:${result.end.toUtc().toIso8601String()}]';
    final description = result.description?.trim();
    final storedDescription = description == null || description.isEmpty
        ? endTag
        : '$description\n$endTag';

    await db.eventsDAO.insertEvent(
      EventsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: personId,
        name: result.title,
        description: Value(storedDescription),
        occurredAt: Value(result.start.toUtc()),
      ),
    );
  }

  bool _deviceEventMatchesLogged(
    DeviceCalendarEventItem device,
    EventData logged,
  ) {
    if (logged.name.trim() != device.title.trim()) return false;
    final local = logged.occurredAt.toLocal();
    return local.year == device.start.year &&
        local.month == device.start.month &&
        local.day == device.start.day &&
        local.hour == device.start.hour &&
        local.minute == device.start.minute;
  }

  bool _deviceEventDuplicatesLogged(
    DeviceCalendarEventItem device,
    List<EventData> loggedOnDay,
  ) {
    for (final logged in loggedOnDay) {
      if (_deviceEventMatchesLogged(device, logged)) return true;
    }
    return false;
  }

  DateTime _loggedEventEnd(EventData event) {
    final description = event.description;
    if (description != null) {
      final match = RegExp(r'\[icegate-end:([^\]]+)\]').firstMatch(description);
      if (match != null) {
        return DateTime.parse(match.group(1)!).toLocal();
      }
    }
    return event.occurredAt.toLocal().add(const Duration(hours: 1));
  }

  Future<void> _openAddEvent(
    DateTime day, {
    TimeOfDay? initialStart,
    TimeOfDay? initialEnd,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;

    if (DeviceCalendarService.isSupported && !_deviceConnected) {
      final service = context.read<DeviceCalendarService>();
      final ok = await service.requestAccess();
      if (!mounted) return;
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.projects_calendar_device_denied)),
        );
      } else {
        setState(() => _deviceConnected = true);
      }
    }

    final saved = await showCreateCalendarEventDialog(
      context,
      initialDay: day,
      initialStart: initialStart,
      initialEnd: initialEnd,
    );
    if (saved == null || !mounted) return;

    await _logLocalCalendarEvent(saved, personId);
    if (!mounted) return;

    final eventDay = _dateOnly(saved.day);
    setState(() {
      _selectedDay = eventDay;
      _focusedMonth = DateTime(eventDay.year, eventDay.month);
    });
    _invalidateSessionCache();

    if (DeviceCalendarService.isSupported && _deviceConnected) {
      // EventKit can lag briefly before new events appear in retrieveEvents.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await _syncDeviceEvents(showSnackBar: false);
      if (!mounted) return;

      var deviceVisible =
          _deviceEvents.any((e) => e.occursOnDay(eventDay));
      if (!deviceVisible) {
        await Future<void>.delayed(const Duration(milliseconds: 600));
        await _syncDeviceEvents(showSnackBar: false);
        if (!mounted) return;
        deviceVisible = _deviceEvents.any((e) => e.occursOnDay(eventDay));
      }

      if (!saved.savedToDeviceCalendar && !deviceVisible) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${l10n.projects_calendar_event_saved} '
              '${l10n.projects_calendar_device_hint}',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.projects_calendar_event_saved)),
    );
  }

  void _handleDaySelected(DateTime day) {
    final d = _dateOnly(day);
    setState(() {
      _selectedDay = d;
      _focusedMonth = DateTime(day.year, day.month);
    });
  }

  Future<void> _syncTasks() async {
    if (_syncingTasks) return;
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    setState(() => _syncingTasks = true);
    try {
      final loggedRange = _loggedEventsQueryRange(_focusedMonth);
      await Future.wait([
        context.read<GrowthBlock>().sync(),
        if (personId.isNotEmpty)
          context.read<AppDatabase>().eventsDAO.syncEventsFromCloud(
            personId,
            rangeStart: loggedRange.start,
            rangeEnd: loggedRange.end,
          ),
        if (_googleConnected) _syncGoogleEvents(showSnackBar: false),
        if (_deviceConnected) _syncDeviceEvents(showSnackBar: false),
      ]);
    } finally {
      if (mounted) setState(() => _syncingTasks = false);
    }
  }

  String _monthKey(DateTime month) => '${month.year}-${month.month}';

  void _invalidateSessionCache() {
    _sessionEventsLoaded = false;
    _sessionMonthKey = null;
  }

  void _persistSessionCache() {
    _sessionMonthKey = _monthKey(_focusedMonth);
    _sessionFocusedMonth = _focusedMonth;
    _sessionSelectedDay = _selectedDay;
    _sessionGoogleEvents = List<GoogleCalendarEventItem>.from(_googleEvents);
    _sessionDeviceEvents = List<DeviceCalendarEventItem>.from(_deviceEvents);
    _sessionGoogleConnected = _googleConnected;
    _sessionDeviceConnected = _deviceConnected;
    _sessionEventsLoaded = true;
  }

  bool _canReuseSessionCache({
    required bool googleConnected,
    required bool deviceConnected,
  }) {
    if (!_sessionEventsLoaded || _sessionMonthKey != _monthKey(_focusedMonth)) {
      return false;
    }
    return _sessionGoogleConnected == googleConnected &&
        _sessionDeviceConnected == deviceConnected;
  }

  void _applySessionCache() {
    _googleEvents = List<GoogleCalendarEventItem>.from(_sessionGoogleEvents);
    _deviceEvents = List<DeviceCalendarEventItem>.from(_sessionDeviceEvents);
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    if (_sessionFocusedMonth != null && _sessionSelectedDay != null) {
      _focusedMonth = _sessionFocusedMonth!;
      _selectedDay = _sessionSelectedDay!;
    } else {
      _focusedMonth = DateTime(today.year, today.month);
      _selectedDay = _dateOnly(today);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapCalendar());
  }

  @override
  void dispose() {
    _sessionFocusedMonth = _focusedMonth;
    _sessionSelectedDay = _selectedDay;
    _pageScrollController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCalendar() async {
    final googleService = context.read<GoogleCalendarService>();
    final deviceService = DeviceCalendarService.isSupported
        ? context.read<DeviceCalendarService>()
        : null;
    var googleOk = googleService.isSignedIn;
    if (!googleOk) googleOk = await googleService.restoreSession();

    var deviceOk = false;
    if (deviceService != null) {
      deviceOk = await deviceService.restoreAccess();
    }

    if (!mounted) return;

    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';

    final reuseCache = _canReuseSessionCache(
      googleConnected: googleOk,
      deviceConnected: deviceOk,
    );
    setState(() {
      _googleConnected = googleOk;
      _deviceConnected = deviceOk;
      if (reuseCache) {
        _applySessionCache();
      }
    });

    if (reuseCache) {
      if (personId.isNotEmpty) {
        unawaited(_syncLoggedEventsForFocusedMonth());
      }
      return;
    }

    if (personId.isNotEmpty) {
      await _syncLoggedEventsForFocusedMonth();
    }

    if (googleOk) {
      await _syncGoogleEvents(showSnackBar: false);
    }
    if (deviceOk) {
      await _syncDeviceEvents(showSnackBar: false);
    }
    if (mounted && (_googleConnected || _deviceConnected)) {
      _persistSessionCache();
    }
  }

  Future<void> _connectGoogle() async {
    final l10n = AppLocalizations.of(context)!;
    final service = context.read<GoogleCalendarService>();
    setState(() => _googleLoading = true);
    final ok = await service.signIn(interactive: true);
    if (!mounted) return;
    setState(() {
      _googleLoading = false;
      _googleConnected = ok;
    });
    if (ok) {
      await _syncGoogleEvents();
      if (mounted && _googleConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.projects_calendar_google_connected)),
        );
      }
    } else if (mounted) {
      _showGoogleCalendarError(l10n, service);
    }
  }

  void _showGoogleCalendarError(
    AppLocalizations l10n,
    GoogleCalendarService service, [
    Object? thrown,
  ]) {
    final code = GoogleApiError.classify(thrown ?? service.lastSignInError);
    final message = switch (code) {
      GoogleApiError.cancelled => l10n.projects_calendar_sign_in_cancelled,
      GoogleApiError.scopeDenied => l10n.projects_calendar_scope_denied,
      GoogleApiError.insufficientScopes =>
        l10n.projects_calendar_insufficient_scopes,
      GoogleApiError.apiNotEnabled => l10n.projects_calendar_api_not_enabled(
          GoogleSignInHub.darwinProjectNumber,
        ),
      _ => l10n.projects_calendar_sign_in_failed,
    };
    final url = code == GoogleApiError.apiNotEnabled
        ? GoogleApiError.calendarApiConsoleUrl(
            thrown ?? service.lastSignInError,
            fallbackProjectId: GoogleSignInHub.darwinProjectNumber,
          )
        : null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(url == null ? message : '$message\n$url'),
        duration: const Duration(seconds: 8),
      ),
    );
  }

  Future<void> _disconnectGoogle() async {
    await context.read<GoogleCalendarService>().signOut();
    if (!mounted) return;
    setState(() {
      _googleConnected = false;
      _googleEvents = [];
    });
    _invalidateSessionCache();
  }

  Future<void> _connectDeviceCalendar() async {
    if (!DeviceCalendarService.isSupported) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _deviceLoading = true);
    final service = context.read<DeviceCalendarService>();
    final ok = await service.requestAccess();
    if (!mounted) return;
    setState(() {
      _deviceConnected = ok;
      _deviceLoading = false;
    });
    if (ok) {
      await _syncDeviceEvents();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isIos
                ? l10n.projects_calendar_apple_connected
                : l10n.projects_calendar_device_connected,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projects_calendar_device_denied)),
      );
    }
  }

  void _disconnectDeviceCalendar() {
    context.read<DeviceCalendarService>().disconnect();
    setState(() {
      _deviceConnected = false;
      _deviceEvents = [];
    });
    _invalidateSessionCache();
  }

  Future<void> _syncDeviceEvents({bool showSnackBar = true}) async {
    if (!_deviceConnected || !DeviceCalendarService.isSupported) return;
    setState(() => _deviceLoading = true);
    final service = context.read<DeviceCalendarService>();
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    try {
      final events = await service.fetchEvents(
        rangeStart: monthStart,
        rangeEnd: monthEnd,
      );
      if (mounted) {
        setState(() {
          _deviceEvents = events;
          _deviceLoading = false;
        });
        _persistSessionCache();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deviceLoading = false);
        if (showSnackBar) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.projects_calendar_sign_in_failed}: $e',
              ),
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Future<void> _syncGoogleEvents({bool showSnackBar = true}) async {
    if (!_googleConnected) return;
    setState(() => _googleLoading = true);
    final service = context.read<GoogleCalendarService>();
    final monthStart = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final monthEnd =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    try {
      final events = await service.fetchEvents(
        rangeStart: monthStart,
        rangeEnd: monthEnd,
      );
      if (mounted) {
        setState(() {
          _googleEvents = events;
          _googleLoading = false;
        });
        _persistSessionCache();
        if (showSnackBar) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                events.isEmpty
                    ? l10n.projects_calendar_sync_empty_month
                    : l10n.projects_calendar_synced_count(events.length),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _googleLoading = false;
          _googleConnected = false;
        });
        _showGoogleCalendarError(
          AppLocalizations.of(context)!,
          service,
          e,
        );
      }
    }
  }

  bool _isCalendarTask(GoalProtocol goal) {
    return goal.category == 'project' ||
        goal.projectID != null ||
        (goal.status != 'done' && goal.category == 'personal');
  }

  bool _sameDay(DateTime? a, DateTime b) {
    if (a == null) return false;
    return _dateOnly(a) == _dateOnly(b);
  }

  Set<DateTime> _reminderDays(List<CustomNotificationData> notifications) {
    return notifications
        .where((n) => n.isEnabled)
        .map((n) => _dateOnly(n.scheduledTime.toLocal()))
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final projectBlock = context.watch<ProjectBlock>();
    final personId = context.watch<PersonBlock>().currentPersonID.value ?? '';
    final notificationDao = context.read<CustomNotificationDAO>();
    final eventsDao = context.read<AppDatabase>().eventsDAO;
    final isDesktop = _isDesktop(context);
    final canAddEvent = personId.isNotEmpty;

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            l10n.projects_tile_calendar,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
          actions: [
            if (_syncingTasks)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: l10n.integrations_sync_now,
                icon: const Icon(Icons.sync_rounded),
                onPressed: personId.isEmpty ? null : _syncTasks,
              ),
            if (isDesktop && canAddEvent) ...[
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.tonalIcon(
                  onPressed: () => _openAddEvent(_selectedDay),
                  icon: const Icon(Icons.event_rounded, size: 20),
                  label: Text(l10n.projects_calendar_add_event),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.tonalIcon(
                  onPressed: () => _openAddReminder(personId),
                  icon: const Icon(Icons.notifications_active_outlined, size: 20),
                  label: Text(l10n.projects_calendar_add_reminder),
                ),
              ),
            ],
            if (_googleLoading)
              const Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                tooltip: l10n.integration_hub_open,
                icon: Icon(
                  (_googleConnected || _deviceConnected)
                      ? Icons.event_available_rounded
                      : Icons.hub_outlined,
                  color: (_googleConnected || _deviceConnected)
                      ? colorScheme.primary
                      : null,
                ),
                onPressed: () =>
                    context.push('/integrations?focus=calendar'),
              ),
          ],
        ),
        body: StreamBuilder<List<CustomNotificationData>>(
          stream: personId.isEmpty
              ? Stream.value(const [])
              : notificationDao.watchAllNotifications(personId),
          builder: (context, notificationSnap) {
            final notifications = notificationSnap.data ?? const [];

            return StreamBuilder<List<EventData>>(
              stream: personId.isEmpty
                  ? Stream.value(const [])
                  : eventsDao.watchEventsInRange(
                      personId,
                      _loggedEventsQueryRange(_focusedMonth).start,
                      _loggedEventsQueryRange(_focusedMonth).end,
                    ),
              builder: (context, eventsSnap) {
                final loggedEvents = eventsSnap.data ?? const [];

                return Watch((context) {
              final tasks =
                  growthBlock.goals.value.where(_isCalendarTask).toList();
              final projects = projectBlock.projects.value;

              final taskMarkedDays = tasks
                  .where((task) => task.targetDate != null)
                  .map((task) => _dateOnly(task.targetDate!))
                  .toSet();
              final projectCreatedDays = projects
                  .map((p) => _dateOnly(p.createdAt.toLocal()))
                  .toSet();
              final googleEventDays = {
                for (final e in _googleEvents) ...e.daysSpanned(),
              };
              final deviceEventDays = {
                for (final e in _deviceEvents) ...e.daysSpanned(),
              };
              final reminderDays = _reminderDays(notifications);
              final loggedEventDays = loggedEvents
                  .map((e) => _dateOnly(e.occurredAt.toLocal()))
                  .toSet();
              final markedDays = {
                ...taskMarkedDays,
                ...projectCreatedDays,
                ...googleEventDays,
                ...deviceEventDays,
                ...loggedEventDays,
                ...reminderDays,
              };

              final selectedTasks = tasks
                  .where((task) => _sameDay(task.targetDate, _selectedDay))
                  .toList()
                ..sort((a, b) => a.title.compareTo(b.title));

              final projectsCreatedHere = projects
                  .where((p) => _sameDay(p.createdAt.toLocal(), _selectedDay))
                  .toList()
                ..sort(
                  (a, b) =>
                      a.createdAt.toLocal().compareTo(b.createdAt.toLocal()),
                );

              final googleOnDay = _googleEvents
                  .where((e) => e.occursOnDay(_selectedDay))
                  .where(
                    (e) =>
                        !_sessionHiddenTimelineKeys.contains(
                          _googleTimelineKey(e),
                        ),
                  )
                  .toList()
                ..sort((a, b) => a.start.compareTo(b.start));

              final loggedOnDay = loggedEvents
                  .where((e) => _sameDay(e.occurredAt.toLocal(), _selectedDay))
                  .toList()
                ..sort(
                  (a, b) =>
                      a.occurredAt.toLocal().compareTo(b.occurredAt.toLocal()),
                );

              final deviceOnDay = _deviceEvents
                  .where((e) => e.occursOnDay(_selectedDay))
                  .where((e) => !_deviceEventDuplicatesLogged(e, loggedOnDay))
                  .where(
                    (e) =>
                        !_sessionHiddenTimelineKeys.contains(
                          _deviceTimelineKey(e),
                        ),
                  )
                  .toList()
                ..sort((a, b) => a.start.compareTo(b.start));

              final remindersOnDay = notifications
                  .where(
                    (n) =>
                        n.isEnabled &&
                        _sameDay(n.scheduledTime.toLocal(), _selectedDay) &&
                        !_sessionHiddenTimelineKeys.contains(
                          _reminderTimelineKey(n),
                        ),
                  )
                  .toList()
                ..sort(
                  (a, b) => a.scheduledTime.compareTo(b.scheduledTime),
                );

              final createdTimeFormat = DateFormat.jm(
                Localizations.localeOf(context).toString(),
              );

              final mergedCalendarEvents = <_MergedCalendarEvent>[
                for (final e in googleOnDay)
                  _MergedCalendarEvent(
                    title: e.title,
                    subtitle: _googleEventSubtitle(l10n, e, createdTimeFormat),
                    description: e.description,
                    icon: Icons.event_rounded,
                    iconColor: const Color(0xFF4285F4),
                    start: e.start,
                    end: e.end,
                    allDay: e.allDay,
                    canEdit: false,
                    canDelete: true,
                    onDelete: () async =>
                        _hideTimelineEntry(_googleTimelineKey(e)),
                  ),
                for (final e in deviceOnDay)
                  _MergedCalendarEvent(
                    title: e.title,
                    subtitle: _deviceEventSubtitle(l10n, e, createdTimeFormat),
                    description: e.description,
                    icon: _isIos ? Icons.apple_rounded : Icons.event_note_rounded,
                    iconColor: colorScheme.secondary,
                    start: e.start,
                    end: e.end,
                    allDay: e.allDay,
                    canEdit: true,
                    canDelete: true,
                    onEdit: () => _editDeviceEvent(e),
                    onDelete: () => _deleteDeviceEvent(e),
                    onMove: e.allDay
                        ? null
                        : (s, end) => _moveDeviceEvent(e, s, end),
                  ),
                for (final e in loggedOnDay)
                  _MergedCalendarEvent(
                    title: e.name,
                    subtitle: createdTimeFormat.format(e.occurredAt.toLocal()),
                    description: _loggedDescriptionForEdit(e),
                    icon: Icons.event_available_rounded,
                    iconColor: colorScheme.primary,
                    start: e.occurredAt.toLocal(),
                    end: _loggedEventEnd(e),
                    allDay: false,
                    canEdit: true,
                    canDelete: true,
                    onEdit: () => _editLoggedEvent(e),
                    onDelete: () => _deleteLoggedEvent(e),
                    onMove: (s, end) => _moveLoggedEvent(e, s, end),
                  ),
              ]..sort((a, b) => a.start.compareTo(b.start));

              final reminderTimelineEvents = [
                for (final r in remindersOnDay)
                  _MergedCalendarEvent(
                    title: r.title,
                    subtitle: createdTimeFormat.format(
                      r.scheduledTime.toLocal(),
                    ),
                    icon: Icons.notifications_active_outlined,
                    iconColor: colorScheme.tertiary,
                    start: r.scheduledTime.toLocal(),
                    end: r.scheduledTime.toLocal().add(
                          const Duration(minutes: 30),
                        ),
                    canEdit: true,
                    canDelete: true,
                    onEdit: () => _editReminder(r),
                    onDelete: () => _deleteReminder(r),
                    onMove: (s, end) => _moveReminder(r, s, end),
                  ),
              ];

              final timelineEntries = <CalendarTimelineEntry>[
                for (final e in mergedCalendarEvents)
                  CalendarTimelineEntry(
                    title: e.title,
                    start: e.start,
                    end: e.end,
                    allDay: e.allDay,
                    color: e.iconColor,
                    subtitle: e.subtitle,
                    onTap: (e.canEdit || e.canDelete)
                        ? () => _showTimelineEventSheet(e)
                        : null,
                    canMove: e.onMove != null,
                    onMoved: e.onMove,
                  ),
                for (final e in reminderTimelineEvents)
                  CalendarTimelineEntry(
                    title: e.title,
                    start: e.start,
                    end: e.end,
                    color: e.iconColor,
                    subtitle: e.subtitle,
                    onTap: () => _showTimelineEventSheet(e),
                    canMove: e.onMove != null,
                    onMoved: e.onMove,
                  ),
              ];

              final hasTasks = selectedTasks.isNotEmpty;
              final hasProjectsHere = projectsCreatedHere.isNotEmpty;
              final monthExternalCount =
                  _googleEvents.length + _deviceEvents.length;

              final selectedLabel = _selectedDay == _dateOnly(DateTime.now())
                  ? l10n.date_today
                  : DateFormat.yMMMd().format(_selectedDay);
              final isTodaySelected =
                  _selectedDay == _dateOnly(DateTime.now());

              final calendar = AppSessionCalendar(
                markedDays: markedDays,
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                onMonthChanged: (month) {
                  setState(
                    () => _focusedMonth = DateTime(month.year, month.month),
                  );
                  _invalidateSessionCache();
                  _syncGoogleEvents(showSnackBar: false);
                  _syncDeviceEvents(showSnackBar: false);
                  unawaited(_syncLoggedEventsForFocusedMonth());
                },
                onDaySelected: _handleDaySelected,
                onDayLongPress: canAddEvent
                    ? (day) => _openAddEvent(_dateOnly(day))
                    : null,
                onDaySecondaryTap: canAddEvent
                    ? (day) => _openAddEvent(_dateOnly(day))
                    : null,
              );

              final agendaChildren = <Widget>[
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        selectedLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (!isTodaySelected)
                      TextButton(
                        onPressed: () => _handleDaySelected(DateTime.now()),
                        child: Text(l10n.date_today),
                      ),
                    if (canAddEvent)
                      FilledButton.tonalIcon(
                        onPressed: () => _openAddEvent(_selectedDay),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(l10n.projects_calendar_add_event),
                      ),
                  ],
                ),
                if (!_googleConnected ||
                    (DeviceCalendarService.isSupported && !_deviceConnected))
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: _buildIntegrationHubEntry(
                      context,
                      l10n,
                      colorScheme,
                    ),
                  ),
                _sectionHeader(
                  context,
                  l10n.projects_calendar_day_timeline,
                  Icons.schedule_rounded,
                ),
                const SizedBox(height: 8),
                if (canAddEvent)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      l10n.projects_calendar_timeline_tap_slot,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurface.withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                CalendarDayTimeline(
                  entries: timelineEntries,
                  selectedDay: _selectedDay,
                  scrollController: _pageScrollController,
                  onDragActiveChanged: (active) =>
                      setState(() => _timelineDragging = active),
                  onHourTap: canAddEvent
                      ? (hour) => _openAddEvent(
                            _selectedDay,
                            initialStart: TimeOfDay(hour: hour, minute: 0),
                            initialEnd: hour >= 23
                                ? const TimeOfDay(hour: 23, minute: 59)
                                : TimeOfDay(hour: hour + 1, minute: 0),
                          )
                      : null,
                ),
                const SizedBox(height: 16),
                if (timelineEntries.isEmpty &&
                    !hasTasks &&
                    !hasProjectsHere)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      _dayEmptyMessage(
                        l10n,
                        monthExternalCount: monthExternalCount,
                        googleConnected: _googleConnected,
                        deviceConnected: _deviceConnected,
                      ),
                      style: TextStyle(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                        height: 1.35,
                      ),
                    ),
                  ),
                if (hasProjectsHere) ...[
                  _sectionHeader(
                    context,
                    l10n.projects_calendar_projects_created,
                    Icons.create_new_folder_outlined,
                  ),
                  const SizedBox(height: 8),
                  ...projectsCreatedHere.map((project) {
                        final createdLocal = project.createdAt.toLocal();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                            color: colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () =>
                                  context.push('/projects/${project.id}'),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.create_new_folder_outlined,
                                      size: 22,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            project.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            createdTimeFormat
                                                .format(createdLocal),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: colorScheme.onSurface
                                                  .withValues(alpha: 0.55),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: colorScheme.onSurface
                                          .withValues(alpha: 0.35),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                  if (hasTasks) const SizedBox(height: 20),
                ],
                if (hasTasks) ...[
                      _sectionHeader(
                        context,
                        l10n.tasks,
                        Icons.task_alt_rounded,
                      ),
                      const SizedBox(height: 8),
                      ...selectedTasks.map((task) {
                        String? projectName;
                        if (task.projectID != null) {
                          for (final project in projects) {
                            if (project.projectID == task.projectID) {
                              projectName = project.name;
                              break;
                            }
                          }
                        }

                        return TaskItem(
                          task: task,
                          projectName: projectName,
                          onComplete: () => growthBlock.completeGoal(task.id),
                          onDeleteRequested: () => confirmDeleteTask(
                            context,
                            growthBlock,
                            task,
                          ),
                        );
                      }),
                ],
              ];

              return LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= _desktopBreakpoint;
                  final pad = wide ? 32.0 : 20.0;
                  final bottom = wide ? 24.0 : 88.0;

                  final body = wide
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 380,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      calendar,
                                      if (canAddEvent) ...[
                                        const SizedBox(height: 12),
                                        Text(
                                          l10n.projects_calendar_hold_day_add_hint,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: colorScheme.onSurface
                                                .withValues(alpha: 0.45),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 28),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: agendaChildren,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            calendar,
                            if (canAddEvent) ...[
                              const SizedBox(height: 8),
                              Text(
                                l10n.projects_calendar_hold_day_add_hint,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ...agendaChildren,
                          ],
                        );

                  return SingleChildScrollView(
                    controller: _pageScrollController,
                    physics: _timelineDragging
                        ? const NeverScrollableScrollPhysics()
                        : const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(pad, 8, pad, bottom),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _contentMaxWidth,
                        ),
                        child: body,
                      ),
                    ),
                  );
                },
              );
                });
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildIntegrationHubEntry(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push('/integrations?focus=calendar'),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(Icons.hub_rounded, color: colorScheme.primary, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.integration_hub_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.integration_hub_subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String label,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: colorScheme.onSurface.withValues(alpha: 0.85),
          ),
        ),
      ],
    );
  }

  String _dayEmptyMessage(
    AppLocalizations l10n, {
    required int monthExternalCount,
    required bool googleConnected,
    required bool deviceConnected,
  }) {
    if (!googleConnected && !deviceConnected) {
      return l10n.projects_calendar_day_empty_not_connected;
    }
    if (monthExternalCount > 0) {
      return l10n.projects_calendar_day_empty_other_days(monthExternalCount);
    }
    return l10n.projects_calendar_day_empty;
  }

  String _googleEventSubtitle(
    AppLocalizations l10n,
    GoogleCalendarEventItem event,
    DateFormat timeFormat,
  ) {
    final time = event.allDay
        ? l10n.projects_calendar_all_day
        : timeFormat.format(event.start);
    final name = event.calendarName?.trim();
    if (name == null || name.isEmpty) return time;
    return '$name · $time';
  }

  String _deviceEventSubtitle(
    AppLocalizations l10n,
    DeviceCalendarEventItem event,
    DateFormat timeFormat,
  ) {
    final time = event.allDay
        ? l10n.projects_calendar_all_day
        : timeFormat.format(event.start);
    final name = event.calendarName?.trim();
    if (name == null || name.isEmpty) return time;
    return '$name · $time';
  }
}

class _MergedCalendarEvent {
  const _MergedCalendarEvent({
    required this.title,
    required this.subtitle,
    this.description,
    required this.icon,
    required this.iconColor,
    required this.start,
    this.end,
    this.allDay = false,
    this.canEdit = false,
    this.canDelete = false,
    this.onEdit,
    this.onDelete,
    this.onMove,
  });

  final String title;
  final String subtitle;
  final String? description;
  final IconData icon;
  final Color iconColor;
  final DateTime start;
  final DateTime? end;
  final bool allDay;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onEdit;
  final Future<void> Function()? onDelete;
  final Future<void> Function(DateTime newStart, DateTime newEnd)? onMove;
}
