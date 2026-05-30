import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningLoopPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/NotificationMaskChip.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Toggle + time for the morning “open Ice Gate first” notification.
class MorningLoopReminderRow extends StatefulWidget {
  const MorningLoopReminderRow({super.key, this.showHeader = true});

  /// When false, title/subtitle are omitted (sheet provides them).
  final bool showHeader;

  @override
  State<MorningLoopReminderRow> createState() => _MorningLoopReminderRowState();
}

class _MorningLoopReminderRowState extends State<MorningLoopReminderRow> {
  bool _loading = true;
  bool _enabled = true;
  bool _briefing = true;
  TimeOfDay _time = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final en = await MorningLoopPrefs.getReminderEnabled();
    final br = await MorningLoopPrefs.getBriefingEnabled();
    final h = await MorningLoopPrefs.getHour();
    final m = await MorningLoopPrefs.getMinute();
    if (!mounted) return;
    setState(() {
      _enabled = en;
      _briefing = br;
      _time = TimeOfDay(hour: h, minute: m);
      _loading = false;
    });
  }

  Future<void> _persistAndSchedule() async {
    await MorningLoopPrefs.setReminderEnabled(_enabled);
    await MorningLoopPrefs.setBriefingEnabled(_briefing);
    await MorningLoopPrefs.setTime(_time.hour, _time.minute);
    if (!mounted) return;
    try {
      await context
          .read<LocalNotificationService>()
          .scheduleMorningLoopFromPrefs();
    } catch (e) {
      debugPrint('MorningLoopReminderRow: schedule failed — $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.finance_daily_report_notifications_off,
          ),
        ),
      );
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null) {
      setState(() => _time = picked);
      await _persistAndSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _loading) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final timeStr = DateFormat.jm().format(
      DateTime(0, 1, 1, _time.hour, _time.minute),
    );

    final reminderToggle = widget.showHeader
        ? SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            value: _enabled,
            activeThumbColor: HealthMetricColors.pillarYellow,
            title: Text(
              l10n.morning_loop_reminder_title,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            subtitle: Text(
              l10n.morning_loop_reminder_subtitle,
              style: TextStyle(
                color: cs.onSurface.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
            onChanged: (v) async {
              setState(() => _enabled = v);
              await _persistAndSchedule();
            },
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Switch.adaptive(
                  value: _enabled,
                  activeColor: HealthMetricColors.pillarYellow,
                  onChanged: (v) async {
                    setState(() => _enabled = v);
                    await _persistAndSchedule();
                  },
                ),
                const SizedBox(width: 12),
                if (_enabled)
                  NotificationMaskChip.schedule(
                    label: timeStr,
                    onTap: _pickTime,
                  )
                else
                  Text(
                    l10n.notification_status_off,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        reminderToggle,
        if (_enabled && widget.showHeader)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: NotificationMaskChip.schedule(
                label: timeStr,
                onTap: _pickTime,
              ),
            ),
          ),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: _briefing,
          title: Text(
            l10n.morning_briefing_toggle,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
          onChanged: (v) async {
            setState(() => _briefing = v);
            await _persistAndSchedule();
          },
        ),
      ],
    );
  }
}
