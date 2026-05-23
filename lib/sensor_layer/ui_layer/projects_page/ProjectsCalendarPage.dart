import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';
import 'package:ice_gate/data_layer/Services/cloud/google_api_error.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/TaskItem.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/CalendarReminderDialog.dart';
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

  late DateTime _focusedMonth;
  late DateTime _selectedDay;

  List<GoogleCalendarEventItem> _googleEvents = [];
  List<DeviceCalendarEventItem> _deviceEvents = [];
  bool _googleLoading = false;
  bool _deviceLoading = false;
  bool _googleConnected = false;
  bool _deviceConnected = false;
  bool _syncingTasks = false;

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  bool _isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= _desktopBreakpoint;

  void _openAddReminder(String personId) {
    showCalendarReminderDialog(
      context,
      initialDay: _selectedDay,
      personId: personId,
    );
  }

  Future<void> _syncTasks() async {
    if (_syncingTasks) return;
    setState(() => _syncingTasks = true);
    try {
      await context.read<GrowthBlock>().sync();
    } finally {
      if (mounted) setState(() => _syncingTasks = false);
    }
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _focusedMonth = DateTime(today.year, today.month);
    _selectedDay = _dateOnly(today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreGoogleSession();
      _restoreDeviceCalendar();
    });
  }

  Future<void> _restoreGoogleSession() async {
    final service = context.read<GoogleCalendarService>();
    var ok = service.isSignedIn;
    if (!ok) ok = await service.restoreSession();
    if (!mounted) return;
    setState(() => _googleConnected = ok);
    if (ok) await _syncGoogleEvents();
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
  }

  Future<void> _restoreDeviceCalendar() async {
    if (!DeviceCalendarService.isSupported) return;
    final service = context.read<DeviceCalendarService>();
    final ok = await service.restoreAccess();
    if (!mounted) return;
    setState(() => _deviceConnected = ok);
    if (ok) await _syncDeviceEvents();
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
  }

  Future<void> _syncDeviceEvents() async {
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _deviceLoading = false);
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

  Future<void> _syncGoogleEvents() async {
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

  void _showCalendarIntegrationsSheet() {
    final l10n = AppLocalizations.of(context)!;
    final showDevice = DeviceCalendarService.isSupported;
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                l10n.projects_calendar_integrations,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            if (!_googleConnected)
              ListTile(
                leading: const Icon(Icons.event_rounded, color: Color(0xFF4285F4)),
                title: Text(l10n.projects_calendar_connect_google),
                subtitle: Text(l10n.projects_calendar_connect_hint),
                onTap: () {
                  Navigator.pop(ctx);
                  _connectGoogle();
                },
              )
            else ...[
              ListTile(
                leading: const Icon(Icons.sync_rounded, color: Color(0xFF4285F4)),
                title: Text(l10n.projects_calendar_sync_google),
                onTap: () {
                  Navigator.pop(ctx);
                  _syncGoogleEvents();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off_rounded),
                title: Text(l10n.projects_calendar_disconnect_google),
                onTap: () {
                  Navigator.pop(ctx);
                  _disconnectGoogle();
                },
              ),
            ],
            if (showDevice) ...[
              const Divider(height: 1),
              if (!_deviceConnected)
                ListTile(
                  leading: Icon(
                    _isIos ? Icons.apple_rounded : Icons.smartphone_rounded,
                  ),
                  title: Text(
                    _isIos
                        ? l10n.projects_calendar_connect_apple
                        : l10n.projects_calendar_connect_device,
                  ),
                  subtitle: Text(l10n.projects_calendar_device_hint),
                  onTap: () {
                    Navigator.pop(ctx);
                    _connectDeviceCalendar();
                  },
                )
              else ...[
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: Text(l10n.projects_calendar_sync_device),
                  onTap: () {
                    Navigator.pop(ctx);
                    _syncDeviceEvents();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.link_off_rounded),
                  title: Text(
                    _isIos
                        ? l10n.projects_calendar_disconnect_apple
                        : l10n.projects_calendar_disconnect_device,
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _disconnectDeviceCalendar();
                  },
                ),
              ],
            ],
            ListTile(
              leading: const Icon(Icons.hub_rounded),
              title: Text(l10n.integration_hub_open),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/integrations?focus=calendar');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final growthBlock = context.watch<GrowthBlock>();
    final projectBlock = context.watch<ProjectBlock>();
    final personId = context.watch<PersonBlock>().currentPersonID.value ?? '';
    final notificationDao = context.read<CustomNotificationDAO>();
    final isDesktop = _isDesktop(context);

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
            if (isDesktop && personId.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: FilledButton.tonalIcon(
                  onPressed: () => _openAddReminder(personId),
                  icon: const Icon(Icons.notifications_active_outlined, size: 20),
                  label: Text(l10n.projects_calendar_add_reminder),
                ),
              ),
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
                tooltip: l10n.projects_calendar_integrations,
                icon: Icon(
                  (_googleConnected || _deviceConnected)
                      ? Icons.event_available_rounded
                      : Icons.calendar_month_outlined,
                  color: (_googleConnected || _deviceConnected)
                      ? colorScheme.primary
                      : null,
                ),
                onPressed: _showCalendarIntegrationsSheet,
              ),
          ],
        ),
        body: StreamBuilder<List<CustomNotificationData>>(
          stream: personId.isEmpty
              ? Stream.value(const [])
              : notificationDao.watchAllNotifications(personId),
          builder: (context, notificationSnap) {
            final notifications = notificationSnap.data ?? const [];

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
              final markedDays = {
                ...taskMarkedDays,
                ...projectCreatedDays,
                ...googleEventDays,
                ...deviceEventDays,
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
                  .toList()
                ..sort((a, b) => a.start.compareTo(b.start));

              final deviceOnDay = _deviceEvents
                  .where((e) => e.occursOnDay(_selectedDay))
                  .toList()
                ..sort((a, b) => a.start.compareTo(b.start));

              final remindersOnDay = notifications
                  .where(
                    (n) =>
                        n.isEnabled &&
                        _sameDay(n.scheduledTime.toLocal(), _selectedDay),
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
                    icon: Icons.event_rounded,
                    iconColor: const Color(0xFF4285F4),
                    start: e.start,
                  ),
                for (final e in deviceOnDay)
                  _MergedCalendarEvent(
                    title: e.title,
                    subtitle: _deviceEventSubtitle(l10n, e, createdTimeFormat),
                    icon: _isIos ? Icons.apple_rounded : Icons.event_note_rounded,
                    iconColor: colorScheme.secondary,
                    start: e.start,
                  ),
              ]..sort((a, b) => a.start.compareTo(b.start));

              final hasExternalCalendars = mergedCalendarEvents.isNotEmpty;
              final hasReminders = remindersOnDay.isNotEmpty;
              final hasTasks = selectedTasks.isNotEmpty;
              final hasProjectsHere = projectsCreatedHere.isNotEmpty;
              final monthExternalCount =
                  _googleEvents.length + _deviceEvents.length;
              final hasAnything = hasExternalCalendars ||
                  hasReminders ||
                  hasTasks ||
                  hasProjectsHere;

              final selectedLabel = _selectedDay == _dateOnly(DateTime.now())
                  ? l10n.date_today
                  : DateFormat.yMMMd().format(_selectedDay);

              final integrationsBanner = _buildIntegrationsBanner(
                context,
                l10n,
                colorScheme,
              );

              final calendar = AppSessionCalendar(
                markedDays: markedDays,
                focusedMonth: _focusedMonth,
                selectedDay: _selectedDay,
                onMonthChanged: (month) {
                  setState(
                    () => _focusedMonth = DateTime(month.year, month.month),
                  );
                  _syncGoogleEvents();
                  _syncDeviceEvents();
                },
                onDaySelected: (day) {
                  setState(() {
                    _selectedDay = _dateOnly(day);
                    _focusedMonth = DateTime(day.year, day.month);
                  });
                },
              );

              final agendaChildren = <Widget>[
                Text(
                    selectedLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!hasAnything)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
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
                    )
                  else ...[
                    if (hasExternalCalendars) ...[
                      _sectionHeader(
                        context,
                        l10n.projects_calendar_all_calendars_events,
                        Icons.calendar_month_rounded,
                      ),
                      const SizedBox(height: 8),
                      ...mergedCalendarEvents.map(
                        (event) => _simpleEventTile(
                          context,
                          title: event.title,
                          subtitle: event.subtitle,
                          icon: event.icon,
                          iconColor: event.iconColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    if (hasReminders) ...[
                      _sectionHeader(
                        context,
                        l10n.projects_calendar_reminders,
                        Icons.notifications_active_outlined,
                      ),
                      const SizedBox(height: 8),
                      ...remindersOnDay.map((reminder) {
                        return _simpleEventTile(
                          context,
                          title: reminder.title,
                          subtitle: createdTimeFormat.format(
                            reminder.scheduledTime.toLocal(),
                          ),
                          icon: Icons.alarm_rounded,
                          iconColor: colorScheme.tertiary,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
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
                            integrationsBanner,
                            const SizedBox(height: 16),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(width: 400, child: calendar),
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
                            integrationsBanner,
                            const SizedBox(height: 16),
                            calendar,
                            const SizedBox(height: 24),
                            ...agendaChildren,
                          ],
                        );

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
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
        ),
      ),
    );
  }

  Widget _buildIntegrationsBanner(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme colorScheme,
  ) {
    final showGoogle = !_googleConnected;
    final showDevice =
        DeviceCalendarService.isSupported && !_deviceConnected;
    if (!showGoogle && !showDevice) return const SizedBox.shrink();

    final loading = _googleLoading || _deviceLoading;
    final hint = showGoogle && showDevice
        ? '${l10n.projects_calendar_connect_hint}\n${l10n.projects_calendar_device_hint}'
        : showGoogle
        ? l10n.projects_calendar_connect_hint
        : l10n.projects_calendar_device_hint;

    return Material(
      color: colorScheme.primaryContainer.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: loading ? null : _showCalendarIntegrationsSheet,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: colorScheme.primary),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.projects_calendar_integrations,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hint,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (loading)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                FilledButton(
                  onPressed: _showCalendarIntegrationsSheet,
                  child: Text(l10n.projects_calendar_integrations),
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

  Widget _simpleEventTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 22, color: iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MergedCalendarEvent {
  const _MergedCalendarEvent({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.start,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final DateTime start;
}
