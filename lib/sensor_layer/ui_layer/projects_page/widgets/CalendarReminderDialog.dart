import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

/// Creates a one-shot reminder shown on [ProjectsCalendarPage] and in notifications.
Future<void> showCalendarReminderDialog(
  BuildContext context, {
  required DateTime initialDay,
  required String personId,
  CustomNotificationData? existing,
}) {
  final wide = MediaQuery.sizeOf(context).width >= 600;
  return showDialog(
    context: context,
    builder: (ctx) => _CalendarReminderDialog(
      initialDay: initialDay,
      personId: personId,
      existing: existing,
      wide: wide,
    ),
  );
}

class _CalendarReminderDialog extends StatefulWidget {
  const _CalendarReminderDialog({
    required this.initialDay,
    required this.personId,
    this.existing,
    required this.wide,
  });

  final DateTime initialDay;
  final String personId;
  final CustomNotificationData? existing;
  final bool wide;

  bool get isEdit => existing != null;

  @override
  State<_CalendarReminderDialog> createState() => _CalendarReminderDialogState();
}

class _CalendarReminderDialogState extends State<_CalendarReminderDialog> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  late DateTime _selectedDate;
  TimeOfDay _selectedTime = TimeOfDay.now();

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      final local = existing.scheduledTime.toLocal();
      _selectedDate = DateTime(local.year, local.month, local.day);
      _selectedTime = TimeOfDay.fromDateTime(local);
      _titleController.text = existing.title;
      _contentController.text = existing.content;
    } else {
      _selectedDate = DateTime(
        widget.initialDay.year,
        widget.initialDay.month,
        widget.initialDay.day,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
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
            ? l10n.projects_calendar_edit_reminder
            : l10n.projects_calendar_add_reminder,
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
                  labelText: l10n.projects_calendar_reminder_title,
                  border: const OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _contentController,
                decoration: InputDecoration(
                  labelText: l10n.finance_label_description_optional,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              if (widget.wide)
                Row(
                  children: [
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notification_date_label),
                        subtitle: Text(
                          DateFormat.yMMMd(locale).format(_selectedDate),
                        ),
                        trailing: const Icon(Icons.calendar_today_rounded),
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365 * 3)),
                          );
                          if (picked != null) {
                            setState(() => _selectedDate = picked);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.notification_time_label),
                        subtitle: Text(_selectedTime.format(context)),
                        trailing: const Icon(Icons.access_time_rounded),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: _selectedTime,
                          );
                          if (picked != null) {
                            setState(() => _selectedTime = picked);
                          }
                        },
                      ),
                    ),
                  ],
                )
              else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notification_date_label),
                  subtitle: Text(DateFormat.yMMMd(locale).format(_selectedDate)),
                  trailing: const Icon(Icons.calendar_today_rounded),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notification_time_label),
                  subtitle: Text(_selectedTime.format(context)),
                  trailing: const Icon(Icons.access_time_rounded),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: _selectedTime,
                    );
                    if (picked != null) {
                      setState(() => _selectedTime = picked);
                    }
                  },
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(widget.isEdit ? l10n.projects_calendar_save : l10n.add),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.notification_enter_title_snack),
        ),
      );
      return;
    }

    final scheduled = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final numericId =
        '${_selectedTime.hour.toString().padLeft(2, '0')}${_selectedTime.minute.toString().padLeft(2, '0')}';

    final dao = context.read<CustomNotificationDAO>();
    final notificationService = context.read<LocalNotificationService>();
    final existing = widget.existing;

    if (existing != null) {
      await dao.updateNotification(
        existing.copyWith(
          title: title,
          content: _contentController.text.trim(),
          notificationID: Value(numericId),
          scheduledTime: scheduled,
        ),
      );
    } else {
      final id = IDGen.UUIDV7();
      await dao.insertNotification(
        CustomNotificationsTableCompanion.insert(
          id: id,
          title: title,
          content: _contentController.text.trim(),
          notificationID: Value(numericId),
          scheduledTime: scheduled,
          repeatFrequency: const Value('none'),
          category: const Value('Projects'),
          priority: const Value('Normal'),
          personID: Value(widget.personId),
          isEnabled: const Value(true),
          createdAt: Value(DateTime.now()),
        ),
      );
    }

    if (!mounted) return;
    await notificationService.syncAllNotifications(widget.personId);

    if (!context.mounted) return;
    Navigator.pop(context);
  }
}
