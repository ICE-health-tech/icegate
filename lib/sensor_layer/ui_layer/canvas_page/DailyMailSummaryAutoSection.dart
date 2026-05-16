import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/DailyMailSummaryPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/NotificationMaskChip.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Toggle + time for automatic daily email report (n8n) when the app is open.
class DailyMailSummaryAutoSection extends StatefulWidget {
  const DailyMailSummaryAutoSection({super.key});

  @override
  State<DailyMailSummaryAutoSection> createState() =>
      _DailyMailSummaryAutoSectionState();
}

class _DailyMailSummaryAutoSectionState extends State<DailyMailSummaryAutoSection> {
  bool _loading = true;
  bool _enabled = false;
  TimeOfDay _time = const TimeOfDay(hour: 20, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final en = await DailyMailSummaryPrefs.getEnabled();
    final h = await DailyMailSummaryPrefs.getHour();
    final m = await DailyMailSummaryPrefs.getMinute();
    if (!mounted) return;
    setState(() {
      _enabled = en;
      _time = TimeOfDay(hour: h, minute: m);
      _loading = false;
    });
  }

  Future<void> _persistAndSchedule() async {
    await DailyMailSummaryPrefs.setEnabled(_enabled);
    await DailyMailSummaryPrefs.setTime(_time.hour, _time.minute);
    if (!mounted) return;
    await context.read<LocalNotificationService>().scheduleDailyMailSummaryFromPrefs();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: EntryColors.financeSilverAccent,
              surface: const Color(0xFF1a1a24),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
      await _persistAndSchedule();
    }
  }

  Future<void> _onAutoSendChanged(bool value) async {
    final notifications = context.read<LocalNotificationService>();
    if (value && !notifications.notificationsEnabled.value) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.finance_daily_report_notifications_off,
          ),
        ),
      );
      return;
    }
    setState(() => _enabled = value);
    await _persistAndSchedule();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final timeStr = DateFormat.jm().format(
      DateTime(0, 1, 1, _time.hour, _time.minute),
    );

    if (_loading) {
      return const SizedBox(
        height: 56,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: EntryColors.glassBorder.withValues(alpha: 0.12),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SwitchListTile.adaptive(
            value: _enabled,
            activeTrackColor: EntryColors.financeSilverAccent.withValues(alpha: 0.35),
            activeThumbColor: EntryColors.deepGlacier,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
            title: Text(
              l10n.canvas_mail_summary_auto_title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              l10n.canvas_mail_summary_auto_subtitle,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
            onChanged: _onAutoSendChanged,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: NotificationMaskChip.schedule(
              label: timeStr,
              onTap: _enabled ? _pickTime : null,
            ),
          ),
        ],
      ),
    );
  }
}
