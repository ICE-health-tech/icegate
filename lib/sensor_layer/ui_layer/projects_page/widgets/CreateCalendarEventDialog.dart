import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/CalendarEventSaveResult.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/CalendarProtocol.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Creates a calendar event (device calendar when supported + ICE Gate log).
///
/// Returns [CalendarEventSaveResult] when saved, or `null` when cancelled.
Future<CalendarEventSaveResult?> showCreateCalendarEventDialog(
  BuildContext context, {
  required DateTime initialDay,
  TimeOfDay? initialStart,
  TimeOfDay? initialEnd,
  CalendarEventEditTarget? editTarget,
  String? initialTitle,
  String? initialDescription,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 600;
  return showDialog<CalendarEventSaveResult>(
    context: context,
    useRootNavigator: true,
    builder: (ctx) => _CreateCalendarEventDialog(
      initialDay: initialDay,
      initialStart: initialStart,
      initialEnd: initialEnd,
      editTarget: editTarget,
      initialTitle: initialTitle,
      initialDescription: initialDescription,
      wide: wide,
    ),
  );
}

class _CreateCalendarEventDialog extends StatefulWidget {
  const _CreateCalendarEventDialog({
    required this.initialDay,
    this.initialStart,
    this.initialEnd,
    this.editTarget,
    this.initialTitle,
    this.initialDescription,
    required this.wide,
  });

  final DateTime initialDay;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  final CalendarEventEditTarget? editTarget;
  final String? initialTitle;
  final String? initialDescription;
  final bool wide;

  bool get isEdit => editTarget != null;

  @override
  State<_CreateCalendarEventDialog> createState() =>
      _CreateCalendarEventDialogState();
}

class _CreateCalendarEventDialogState extends State<_CreateCalendarEventDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late DateTime _selectedDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;

  List<CalendarProtocol> _calendars = [];
  CalendarProtocol? _selectedCalendar;
  bool _loadingCalendars = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(
      widget.initialDay.year,
      widget.initialDay.month,
      widget.initialDay.day,
    );
    final start = widget.initialStart ?? TimeOfDay.now();
    _startTime = start;
    _endTime = widget.initialEnd ??
        TimeOfDay(
          hour: (start.hour + 1) % 24,
          minute: start.minute,
        );
    if (widget.initialTitle != null) {
      _titleController.text = widget.initialTitle!;
    }
    if (widget.initialDescription != null) {
      _descriptionController.text = widget.initialDescription!;
    }
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    final service = context.read<DeviceCalendarService>();
    final list = await service.fetchCalendars(writableOnly: true);
    if (!mounted) return;
    setState(() {
      _calendars = list;
      if (list.isNotEmpty) {
        _selectedCalendar = list.firstWhere(
          (c) => c.isDefault,
          orElse: () => list.first,
        );
      }
      _loadingCalendars = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.projects_calendar_event_title_required)),
      );
      return;
    }

    final start = _combine(_selectedDate, _startTime);
    var end = _combine(_selectedDate, _endTime);
    if (!end.isAfter(start)) {
      end = start.add(const Duration(hours: 1));
    }

    setState(() => _saving = true);
    final description = _descriptionController.text.trim();
    final edit = widget.editTarget;
    var savedToDevice = false;
    DeviceCalendarService? service;

    if (edit?.isLogged == true) {
      final db = context.read<AppDatabase>();
      final endTag = '[icegate-end:${end.toUtc().toIso8601String()}]';
      final storedDescription = description.isEmpty
          ? endTag
          : '$description\n$endTag';
      await db.eventsDAO.updateLoggedEvent(
        id: edit!.loggedEventId!,
        name: title,
        occurredAt: start,
        description: storedDescription,
      );
    } else if (edit?.isDevice == true && DeviceCalendarService.isSupported) {
      service = context.read<DeviceCalendarService>();
      savedToDevice = await service.updateEvent(
        calendarId: edit!.calendarId!,
        eventId: edit.eventId!,
        title: title,
        start: start,
        end: end,
        description: description.isEmpty ? null : description,
      );
    } else if (DeviceCalendarService.isSupported) {
      service = context.read<DeviceCalendarService>();
      final deviceEventId = await service.createEvent(
        calendar: _selectedCalendar,
        title: title,
        start: start,
        end: end,
        description: description.isEmpty ? null : description,
      );
      savedToDevice = deviceEventId != null;
    }

    if (!mounted) return;
    setState(() => _saving = false);

    final deviceFailed = edit?.isDevice == true
        ? !savedToDevice
        : edit == null &&
            DeviceCalendarService.isSupported &&
            !savedToDevice &&
            service != null;

    if (deviceFailed && service != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.projects_calendar_event_failed}${service.lastAccessError != null ? ': ${service.lastAccessError}' : ''}',
          ),
        ),
      );
      if (edit?.isDevice == true) return;
    }

    Navigator.pop(
      context,
      CalendarEventSaveResult(
        day: DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
        ),
        start: start,
        end: end,
        title: title,
        description: description.isEmpty ? null : description,
        savedToDeviceCalendar: savedToDevice,
        wasEdit: widget.isEdit,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();

    return AlertDialog(
      insetPadding: widget.wide
          ? const EdgeInsets.symmetric(horizontal: 80, vertical: 48)
          : null,
      title: Text(
        widget.isEdit
            ? l10n.projects_calendar_edit_event
            : l10n.projects_calendar_add_event,
      ),
      content: SizedBox(
        width: widget.wide ? 440 : null,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.projects_calendar_event_title,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                autofocus: true,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.finance_label_description_optional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              if (_loadingCalendars)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: LinearProgressIndicator(),
                )
              else if (_calendars.isNotEmpty && !widget.isEdit)
                DropdownButtonFormField<CalendarProtocol>(
                  value: _selectedCalendar,
                  decoration: InputDecoration(
                    labelText: l10n.projects_calendar_select_calendar,
                    border: const OutlineInputBorder(),
                  ),
                  items: _calendars
                      .map(
                        (c) => DropdownMenuItem(
                          value: c,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (c) => setState(() => _selectedCalendar = c),
                ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.notification_date_label),
                subtitle: Text(DateFormat.yMMMd(locale).format(_selectedDate)),
                trailing: const Icon(Icons.calendar_today_rounded),
                onTap: _pickDate,
              ),
              if (widget.wide)
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.projects_calendar_event_start),
                        subtitle: Text(_startTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () => _pickTime(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.projects_calendar_event_end),
                        subtitle: Text(_endTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () => _pickTime(false),
                      ),
                    ),
                  ],
                )
              else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.projects_calendar_event_start),
                  subtitle: Text(_startTime.format(context)),
                  trailing: const Icon(Icons.access_time_rounded),
                  onTap: () => _pickTime(true),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.projects_calendar_event_end),
                  subtitle: Text(_endTime.format(context)),
                  trailing: const Icon(Icons.access_time_rounded),
                  onTap: () => _pickTime(false),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(
                  widget.isEdit ? l10n.projects_calendar_save : l10n.add,
                ),
        ),
      ],
    );
  }
}
