import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Home/QuoteBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Quests/QuestBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/Health/MotivationEngine.dart';
import 'package:ice_gate/orchestration_layer/Services/MailServices/DailySummaryEmailFormatter.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningBriefingService.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningLoopPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// First Home visit each morning — yesterday recap + motivation for today.
abstract final class MorningBriefingSheet {
  /// Auto on first Home visit (5:00–11:59) when briefing prefs allow.
  static Future<void> maybeShow(BuildContext context) async {
    if (!await MorningLoopPrefs.shouldShowBriefingToday()) return;
    if (!context.mounted) return;
    await _present(context, markShownOnDismiss: true);
  }

  /// On demand — e.g. Dynamic Island sun button on Home.
  static Future<void> showSummary(BuildContext context) async {
    await _present(context, markShownOnDismiss: false);
  }

  static Future<void> _present(
    BuildContext context, {
    required bool markShownOnDismiss,
  }) async {
    if (!context.mounted) return;

    final auth = context.read<PersonBlock>();
    if (auth.information.value.profiles.username == 'Guest') return;

    final personId =
        Supabase.instance.client.auth.currentUser?.id ??
        auth.currentPersonID.value ??
        '';
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).languageCode;
    final finance = context.read<FinanceBlock>();

    final categoryLabels = <String, String>{};
    for (final t in finance.transactions.value) {
      categoryLabels.putIfAbsent(
        t.category,
        () => FinancePage.getCategoryName(l10n, t.category),
      );
    }

    final snapshot = await MorningBriefingService(context.read<AppDatabase>())
        .load(
          personId: personId,
          health: context.read<HealthBlock>(),
          finance: finance,
          mind: context.read<MindBlock>(),
          growth: context.read<GrowthBlock>(),
          project: context.read<ProjectBlock>(),
          currency: context.read<ConfigBlock>().currency.value,
          locale: locale,
          l10n: l10n,
          categoryLabels: categoryLabels,
        );
    if (!context.mounted) return;

    final motivationText = MotivationEngine.resolveMorningMotivation(
      l10n,
      snapshot.motivation,
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _MorningBriefingBody(snapshot: snapshot),
    );

    if (markShownOnDismiss) {
      await MorningLoopPrefs.markBriefingShownToday();
    }

    if (context.mounted) {
      await context.read<QuoteBlock>().setMorningMotivation(motivationText);
    }
  }
}

class _MorningBriefingBody extends StatelessWidget {
  const _MorningBriefingBody({required this.snapshot});

  final MorningBriefingSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final person = context.watch<PersonBlock>();
    final name = person.information.value.profiles.firstName.trim();
    final greeting = name.isEmpty
        ? l10n.morning_briefing_title
        : l10n.morning_briefing_title_name(name);
    final maxHeight = MediaQuery.sizeOf(context).height * 0.82;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 24),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.94),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border.all(
                color: HealthMetricColors.pillarYellow.withValues(alpha: 0.35),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: cs.onSurface.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Icon(
                    Icons.wb_sunny_rounded,
                    size: 32,
                    color: HealthMetricColors.pillarYellow,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    greeting,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    snapshot.headerLine,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: _buildSummaryBody(context, cs, snapshot.sections),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMotivationCard(context, l10n, cs, snapshot),
                  const SizedBox(height: 12),
                  Watch((context) {
                    final quests = context.read<QuestBlock>().quests.value;
                    final dailies =
                        quests.where((q) => q.type == 'daily').toList();
                    final done =
                        dailies.where((q) => q.isCompleted == true).length;
                    final total = dailies.length;

                    return Text(
                      total > 0
                          ? l10n.morning_briefing_progress(done, total)
                          : l10n.daily_loop_subtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: HealthMetricColors.pillarGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    );
                  }),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: HealthMetricColors.pillarGreen,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      l10n.morning_briefing_start,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/social');
                    },
                    child: Text(l10n.morning_briefing_log_mood),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildSummaryBody(
    BuildContext context,
    ColorScheme cs,
    List<DailySummarySection> sections,
  ) {
    final bodySections = sections.length <= 1 ? sections : sections.sublist(1);

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < bodySections.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _buildEmailSection(cs, bodySections[i]),
          ],
        ],
      ),
    );
  }

  static Widget _buildEmailSection(ColorScheme cs, DailySummarySection section) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title.toUpperCase(),
          style: TextStyle(
            color: cs.onSurface.withValues(alpha: 0.5),
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.1,
          ),
        ),
        if (section.lines.isNotEmpty) ...[
          const SizedBox(height: 8),
          for (final line in section.lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                line,
                style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.88),
                  fontSize: 12.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ],
    );
  }

  static Widget _buildMotivationCard(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    MorningBriefingSnapshot snapshot,
  ) {
    final text = MotivationEngine.resolveMorningMotivation(
      l10n,
      snapshot.motivation,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            HealthMetricColors.pillarYellow.withValues(alpha: 0.14),
            HealthMetricColors.pillarYellow.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: HealthMetricColors.pillarYellow.withValues(alpha: 0.28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.auto_awesome_rounded,
            color: HealthMetricColors.pillarYellow,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.morning_briefing_motivation_title,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: TextStyle(
                    color: cs.onSurface.withValues(alpha: 0.9),
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
