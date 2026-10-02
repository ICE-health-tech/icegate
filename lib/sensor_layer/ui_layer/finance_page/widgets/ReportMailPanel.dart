import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailyMailSummarySuggestions.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryEmailFormatter.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryPayloadBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/FinanceDailySummaryBuilder.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/N8nSummaryDispatch.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/ReportRecipientPrefs.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/ReportRecipientResolver.dart';
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
  List<String> _userEmails = [];

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
    final personId = personBlock.currentPersonID.value ?? '';
    final stored = personId.isEmpty
        ? <EmailAddressData>[]
        : await context
            .read<AppDatabase>()
            .personManagementDAO
            .getEmailsForPerson(personId);
    final userEmails = ReportRecipientResolver.userEmailCandidates(
      personBlock,
      stored: stored,
    );
    final defaultEmail = userEmails.isNotEmpty ? userEmails.first : null;
    final saved = (await ReportRecipientPrefs.getRecipient())?.trim();
    if (saved != null &&
        saved.isNotEmpty &&
        !ReportRecipientResolver.isValidEmail(saved)) {
      await ReportRecipientPrefs.setRecipient(null);
    }
    final savedValid = saved != null &&
        saved.isNotEmpty &&
        ReportRecipientResolver.isValidEmail(saved);
    if (!mounted) return;
    setState(() {
      _userEmails = userEmails;
      _profileEmail = defaultEmail;
      _recipientController.text = savedValid ? saved : (defaultEmail ?? '');
      _loadingRecipient = false;
    });
  }

  void _selectUserEmail(String email) {
    setState(() => _recipientController.text = email);
    _saveRecipient();
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
      final mindBlock = context.read<MindBlock>();
      final growthBlock = context.read<GrowthBlock>();
      final projectBlock = context.read<ProjectBlock>();
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

      final suggestions = await DailyMailSummarySuggestions.resolveAsync(
        l10n: l10nNow,
        finance: financeBlock,
        health: healthBlock,
        mind: mindBlock,
        growth: growthBlock,
        localeCode: locale,
      );

      final payload = DailySummaryPayloadBuilder.build(
        finance: financeBlock,
        health: healthBlock,
        mind: mindBlock,
        growth: growthBlock,
        project: projectBlock,
        personId: personId,
        currency: configBlock.currency.value,
        locale: locale,
        recipientEmail: email,
        recipientName: ReportRecipientResolver.displayName(personBlock),
        categoryLabels: categoryLabels,
        suggestions: suggestions.suggestions,
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
    final mindBlock = context.read<MindBlock>();
    final growthBlock = context.read<GrowthBlock>();
    final projectBlock = context.read<ProjectBlock>();

    const financeAccent = EntryColors.financeSilverAccent;
    const iceTextSecondary = Color(0x80ADD8E6);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                financeAccent.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.055),
                Colors.white.withValues(alpha: 0.03),
              ],
              stops: const [0.0, 0.32, 1.0],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000F1E).withValues(alpha: 0.37),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: financeAccent.withValues(alpha: 0.12),
                blurRadius: 48,
                spreadRadius: -8,
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        size: 22,
                        color: financeAccent.withValues(alpha: 0.95),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.reports_mail_section_title,
                            style: const TextStyle(
                              color: Color(0xF2FFFFFF),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n.reports_mail_section_subtitle,
                            style: const TextStyle(
                              color: iceTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
              if (_userEmails.length > 1) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _userEmails.map((email) {
                    final selected =
                        _recipientController.text.trim().toLowerCase() ==
                            email.toLowerCase();
                    return FilterChip(
                      label: Text(
                        email,
                        style: TextStyle(
                          fontSize: 11,
                          color: selected
                              ? EntryColors.deepGlacier
                              : Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      selected: selected,
                      onSelected: (_) => _selectUserEmail(email),
                      selectedColor:
                          EntryColors.financeSilverAccent.withValues(alpha: 0.9),
                      backgroundColor:
                          EntryColors.deepGlacier.withValues(alpha: 0.55),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                      showCheckmark: false,
                    );
                  }).toList(),
                ),
              ] else if (_profileEmail != null && _profileEmail!.isNotEmpty) ...[
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
                final now = DateTime.now();
                double dayIncome = 0;
                double dayExpense = 0;
                for (final t in financeBlock.transactions.value) {
                  if (!FinanceDailySummaryBuilder.sameCalendarDay(
                    t.transactionDate,
                    now,
                  )) {
                    continue;
                  }
                  switch (t.type) {
                    case 'income':
                      dayIncome += t.amount;
                      break;
                    case 'expense':
                    case 'investment':
                      dayExpense += t.amount;
                      break;
                  }
                }
                final dayNet = dayIncome - dayExpense;
                final netWorth = financeBlock.totalBalance.value;
                final savings = financeBlock.totalSavings.value;
                final steps = healthBlock.todaySteps.value;
                final stepGoal = healthBlock.dailyStepGoal.value;
                final sleep = healthBlock.todaySleep.value;
                final water = healthBlock.todayWater.value;
                final heartRate = healthBlock.todayHeartRate.value;
                final exercise = healthBlock.todayExerciseMinutes.value;
                final focus = healthBlock.todayFocusMinutes.value;
                final kcalBurned = healthBlock.todayCaloriesBurned.value;

                final moodLog = mindBlock.latestMoodLog.value;
                final moodToday = moodLog != null &&
                    FinanceDailySummaryBuilder.sameCalendarDay(
                      moodLog.logDate,
                      now,
                    );
                final moodLabel = moodToday
                    ? DailySummaryEmailFormatter.moodLabel(
                        moodLog.moodScore,
                        Localizations.localeOf(context).languageCode,
                      )
                    : l10n.mood_no_data;

                final projectGoals = growthBlock.goals.value
                    .where((g) => g.category == 'project')
                    .toList();
                final tasksActive = projectGoals
                    .where((g) => g.status != 'done')
                    .length;
                final projectsActive = projectBlock.projects.value
                    .where((p) => p.status == 0)
                    .length;

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
                          value: financeBlock.formatCurrency(dayNet),
                          color: EntryColors.financeSilverAccent,
                        ),
                        _PreviewChip(
                          label: l10n.finance_daily_report_income,
                          value: financeBlock.formatCurrency(dayIncome),
                          color: Colors.greenAccent,
                        ),
                        _PreviewChip(
                          label: l10n.finance_daily_report_expense,
                          value: financeBlock.formatCurrency(dayExpense),
                          color: Colors.orangeAccent,
                        ),
                        _PreviewChip(
                          label: l10n.finance_total_net_worth,
                          value: financeBlock.formatCurrency(netWorth),
                          color: EntryColors.primaryIceBlue,
                        ),
                        _PreviewChip(
                          label: l10n.finance_total_savings,
                          value: financeBlock.formatCurrency(savings),
                          color: Colors.tealAccent,
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
                          value: stepGoal > 0 ? '$steps / $stepGoal' : '$steps',
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
                          label: l10n.health_heart_rate,
                          value: heartRate > 0 ? '$heartRate ${l10n.health_bpm}' : '—',
                          color: Colors.redAccent,
                        ),
                        _PreviewChip(
                          label: l10n.health_exercise,
                          value: '$exercise ${l10n.health_minutes}',
                          color: Colors.amberAccent,
                        ),
                        _PreviewChip(
                          label: l10n.health_focus,
                          value: '$focus ${l10n.health_minutes}',
                          color: EntryColors.primaryIceBlue,
                        ),
                        _PreviewChip(
                          label: l10n.health_calories,
                          value: '$kcalBurned',
                          color: Colors.deepOrangeAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.mind_current_mood.toUpperCase(),
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
                          label: l10n.mind_current_mood,
                          value: moodLabel,
                          color: Colors.purpleAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.projects.toUpperCase(),
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
                          label: l10n.home_projects_active,
                          value: '$projectsActive',
                          color: Colors.orangeAccent,
                        ),
                        _PreviewChip(
                          label: l10n.home_tasks_active,
                          value: '$tasksActive',
                          color: EntryColors.projectBlue,
                        ),
                      ],
                    ),
                  ],
                );
              }),
              const SizedBox(height: 16),
              const _MailAiSuggestionsSection(),
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
              Positioned(
                top: 0,
                left: 12,
                right: 12,
                child: IgnorePointer(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(1),
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.white.withValues(alpha: 0.22),
                          Colors.transparent,
                        ],
                      ),
                    ),
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

class _MailAiSuggestionsSection extends StatelessWidget {
  const _MailAiSuggestionsSection();

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final finance = context.read<FinanceBlock>();
      final health = context.read<HealthBlock>();
      final mind = context.read<MindBlock>();
      final growth = context.read<GrowthBlock>();
      final l10n = AppLocalizations.of(context)!;
      final localeCode = Localizations.localeOf(context).languageCode;
      final refreshKey = Object.hash(
        finance.transactions.value.length,
        health.todaySteps.value,
        health.todayWater.value,
        health.todaySleep.value,
        health.todayFocusMinutes.value,
        mind.latestMoodLog.value?.id,
        growth.goals.value.length,
        localeCode,
      );

      return _MailAiSuggestionsLoader(
        key: ValueKey(refreshKey),
        finance: finance,
        health: health,
        mind: mind,
        growth: growth,
        l10n: l10n,
        localeCode: localeCode,
      );
    });
  }
}

class _MailAiSuggestionsLoader extends StatefulWidget {
  const _MailAiSuggestionsLoader({
    super.key,
    required this.finance,
    required this.health,
    required this.mind,
    required this.growth,
    required this.l10n,
    required this.localeCode,
  });

  final FinanceBlock finance;
  final HealthBlock health;
  final MindBlock mind;
  final GrowthBlock growth;
  final AppLocalizations l10n;
  final String localeCode;

  @override
  State<_MailAiSuggestionsLoader> createState() =>
      _MailAiSuggestionsLoaderState();
}

class _MailAiSuggestionsLoaderState extends State<_MailAiSuggestionsLoader> {
  late Future<DailyMailSummarySuggestionsResult> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<DailyMailSummarySuggestionsResult> _load() {
    return DailyMailSummarySuggestions.resolveAsync(
      l10n: widget.l10n,
      finance: widget.finance,
      health: widget.health,
      mind: widget.mind,
      growth: widget.growth,
      localeCode: widget.localeCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return FutureBuilder<DailyMailSummarySuggestionsResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _MailSuggestionsPanel.loading(
            title: l10n.mail_suggestion_title,
            subtitle: l10n.mail_suggestion_ai_loading,
          );
        }

        final result = snapshot.data;
        final suggestions = result?.suggestions ?? const <String>[];
        if (suggestions.isEmpty) return const SizedBox.shrink();

        return _MailSuggestionsPanel(
          title: l10n.mail_suggestion_title,
          suggestions: suggestions,
          poweredByAi: result?.source == DailyMailSummarySuggestionSource.ai,
          fallbackNote: result?.source == DailyMailSummarySuggestionSource.rules
              ? l10n.mail_suggestion_ai_fallback
              : null,
        );
      },
    );
  }
}

class _MailSuggestionsPanel extends StatelessWidget {
  const _MailSuggestionsPanel({
    required this.title,
    required this.suggestions,
    this.poweredByAi = false,
    this.fallbackNote,
    this.loading = false,
    this.subtitle,
  });

  factory _MailSuggestionsPanel.loading({
    required String title,
    String? subtitle,
  }) {
    return _MailSuggestionsPanel(
      title: title,
      suggestions: const [],
      loading: true,
      subtitle: subtitle,
    );
  }

  final String title;
  final List<String> suggestions;
  final bool poweredByAi;
  final String? fallbackNote;
  final bool loading;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    const accent = EntryColors.financeSilverAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                poweredByAi ? Icons.auto_awesome_rounded : Icons.lightbulb_outline_rounded,
                color: accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (poweredByAi)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: accent,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
          if (loading) ...[
            const SizedBox(height: 12),
            const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            ...suggestions.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: accent.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (fallbackNote != null) ...[
              const SizedBox(height: 6),
              Text(
                fallbackNote!,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.38),
                  fontSize: 10,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ],
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
