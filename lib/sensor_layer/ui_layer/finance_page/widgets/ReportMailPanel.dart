import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/DailySummaryPayloadBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/N8nSummaryDispatch.dart';
import 'package:ice_gate/orchestration_layer/Services/ReportRecipientPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/ReportRecipientResolver.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DailyMailSummaryAutoSection.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// n8n email report: recipient, preview, auto schedule, and manual send.
class ReportMailPanel extends StatefulWidget {
  const ReportMailPanel({super.key});

  @override
  State<ReportMailPanel> createState() => _ReportMailPanelState();
}

class _ReportMailPanelState extends State<ReportMailPanel> {
  final _recipientController = TextEditingController();
  bool _loadingRecipient = true;
  bool _sending = false;
  String? _profileEmail;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRecipient());
  }

  @override
  void dispose() {
    _recipientController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipient() async {
    final personBlock = context.read<PersonBlock>();
    final profileEmail = ReportRecipientResolver.profileEmail(personBlock);
    final saved = await ReportRecipientPrefs.getRecipient();
    if (!mounted) return;
    setState(() {
      _profileEmail = profileEmail;
      _recipientController.text = (saved?.trim().isNotEmpty == true)
          ? saved!.trim()
          : (profileEmail ?? '');
      _loadingRecipient = false;
    });
  }

  Future<void> _saveRecipient() async {
    await ReportRecipientPrefs.setRecipient(_recipientController.text);
  }

  Future<String?> _effectiveRecipient() async {
    if (!mounted) return null;
    final personBlock = context.read<PersonBlock>();
    await _saveRecipient();
    if (!mounted) return null;
    return ReportRecipientResolver.resolve(personBlock);
  }

  Future<void> _sendSummary() async {
    if (_sending) return;

    final l10n = AppLocalizations.of(context)!;
    final email = await _effectiveRecipient();
    if (!mounted) return;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.canvas_finance_n8n_no_email)),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a24),
        title: Text(l10n.canvas_finance_n8n_confirm_title),
        content: Text(l10n.canvas_finance_n8n_confirm_message(email)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.canvas_finance_n8n_confirm_send),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    try {
      final personBlock = context.read<PersonBlock>();
      final financeBlock = context.read<FinanceBlock>();
      final healthBlock = context.read<HealthBlock>();
      final configBlock = context.read<ConfigBlock>();
      final personId = personBlock.currentPersonID.value ?? '';
      final locale = Localizations.localeOf(context).languageCode;
      final l10nNow = AppLocalizations.of(context)!;

      final categoryLabels = <String, String>{};
      for (final t in financeBlock.transactions.value) {
        categoryLabels.putIfAbsent(
          t.category,
          () => FinancePage.getCategoryName(l10nNow, t.category),
        );
      }

      final payload = DailySummaryPayloadBuilder.build(
        finance: financeBlock,
        health: healthBlock,
        personId: personId,
        currency: configBlock.currency.value,
        locale: locale,
        recipientEmail: email,
        categoryLabels: categoryLabels,
      );

      await N8nSummaryDispatch.send(payload);
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.canvas_finance_n8n_send_success)),
      );
    } on N8nSummaryDispatchException catch (e) {
      if (!mounted) return;
      final message = e.message.contains('not configured')
          ? l10n.canvas_finance_n8n_not_configured
          : l10n.canvas_finance_n8n_send_failed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.canvas_finance_n8n_send_failed)),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final financeBlock = context.read<FinanceBlock>();
    final healthBlock = context.read<HealthBlock>();

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: EntryColors.financeSilverAccent.withValues(alpha: 0.22),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.reports_mail_section_title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.reports_mail_section_subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.canvas_mail_summary_recipient.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              if (_loadingRecipient)
                const SizedBox(
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else
                TextField(
                  controller: _recipientController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: l10n.reports_recipient_hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                    filled: true,
                    fillColor: EntryColors.deepGlacier.withValues(alpha: 0.45),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: EntryColors.financeSilverAccent.withValues(alpha: 0.55),
                      ),
                    ),
                    suffixIcon: IconButton(
                      tooltip: l10n.reports_recipient_save,
                      onPressed: () async {
                        await _saveRecipient();
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.reports_recipient_saved)),
                        );
                      },
                      icon: Icon(
                        Icons.check_rounded,
                        color: EntryColors.financeSilverAccent.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  onSubmitted: (_) => _saveRecipient(),
                ),
              if (_profileEmail != null && _profileEmail!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  l10n.reports_recipient_profile_fallback(_profileEmail!),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Watch((context) {
                final income = financeBlock.monthlyIncome.value;
                final spending = financeBlock.monthlySpending.value;
                final netWorth = financeBlock.totalBalance.value;
                final dailyNet = financeBlock.dailyDelta.value;
                final steps = healthBlock.todaySteps.value;
                final sleep = healthBlock.todaySleep.value;
                final water = healthBlock.todayWater.value;
                final kcal = healthBlock.todayCaloriesBurned.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.canvas_mail_summary_finance.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PreviewChip(
                          label: l10n.finance_daily_report_net,
                          value: financeBlock.formatCurrency(dailyNet),
                          color: EntryColors.financeSilverAccent,
                        ),
                        _PreviewChip(
                          label: l10n.finance_total_net_worth,
                          value: financeBlock.formatCurrency(netWorth),
                          color: EntryColors.primaryIceBlue,
                        ),
                        _PreviewChip(
                          label: l10n.finance_daily_report_income,
                          value: financeBlock.formatCurrency(income),
                          color: Colors.greenAccent,
                        ),
                        _PreviewChip(
                          label: l10n.finance_daily_report_expense,
                          value: financeBlock.formatCurrency(spending),
                          color: Colors.orangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.canvas_mail_summary_health.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _PreviewChip(
                          label: l10n.health_steps,
                          value: '$steps',
                          color: EntryColors.healthGreen,
                        ),
                        _PreviewChip(
                          label: l10n.health_sleep,
                          value: sleep.toStringAsFixed(1),
                          color: EntryColors.projectBlue,
                        ),
                        _PreviewChip(
                          label: l10n.health_water,
                          value: '$water ml',
                          color: EntryColors.iceCyan,
                        ),
                        _PreviewChip(
                          label: l10n.health_calories,
                          value: '$kcal',
                          color: Colors.deepOrangeAccent,
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 18),
              const DailyMailSummaryAutoSection(),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _sending ? null : _sendSummary,
                  style: FilledButton.styleFrom(
                    backgroundColor: EntryColors.financeSilverAccent,
                    foregroundColor: EntryColors.deepGlacier,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: EntryColors.deepGlacier,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                  label: Text(
                    l10n.canvas_mail_summary_send,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PreviewChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _PreviewChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.85),
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
