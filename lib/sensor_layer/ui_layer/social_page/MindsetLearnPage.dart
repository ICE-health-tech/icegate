import 'dart:convert';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindLogInsights.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Logs mindset principles / lessons into [mind_logs] (`mindset_learn` token).
class MindsetLearnPage extends StatelessWidget {
  const MindsetLearnPage({super.key});

  static bool isMindsetLog(MindLogData log) =>
      MindLogInsights.isMindsetLog(log);

  static String? topicFromLog(MindLogData log) {
    try {
      final raw = jsonDecode(log.activities);
      if (raw is! List) return null;
      for (final e in raw) {
        final s = e.toString();
        if (s.startsWith('mindset_topic:')) {
          final t = s.substring('mindset_topic:'.length).trim();
          if (t.isNotEmpty) return t;
        }
      }
    } catch (_) {}
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return SwipeablePage(
      onSwipe: () => context.pop(),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: cs.surface,
        appBar: AppBar(
          title: Text(l10n.mindset_learn_title),
          backgroundColor: cs.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const MindsetLearnView(),
      ),
    );
  }
}

/// Mindset log form + history; embed in [SocialPage] tab or full [MindsetLearnPage].
class MindsetLearnView extends StatefulWidget {
  const MindsetLearnView({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<MindsetLearnView> createState() => _MindsetLearnViewState();
}

class _MindsetLearnViewState extends State<MindsetLearnView> {
  final _topicCtrl = TextEditingController();
  final _lessonCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _topicCtrl.dispose();
    _lessonCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(String personId) async {
    final l10n = AppLocalizations.of(context)!;
    final topic = _topicCtrl.text.trim();
    final lesson = _lessonCtrl.text.trim();
    if (topic.isEmpty || lesson.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mindset_learn_validation)),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await context.read<MindBlock>().addMindLog(
        moodScore: 0,
        activities: [
          'mindset_learn',
          'mindset_topic:$topic',
        ],
        note: lesson,
        personId: personId,
        tenantId: null,
      );
      if (!mounted) return;
      _topicCtrl.clear();
      _lessonCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mindset_learn_saved)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double _bottomPadding(BuildContext context) {
    if (!widget.embedded) return 120;
    final width = MediaQuery.sizeOf(context).width;
    final wideMac =
        defaultTargetPlatform == TargetPlatform.macOS && width >= 560;
    return wideMac ? 72 : 104;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = HealthMetricColors.pillarViolet;

    return Watch((context) {
      final personId =
          context.read<PersonBlock>().currentPersonID.value ?? '';
      if (personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(20, 8, 20, _bottomPadding(context)),
        children: [
          if (widget.embedded) ...[
            Text(
              l10n.mindset_learn_title,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Text(
                l10n.mindset_learn_subtitle,
                style: TextStyle(
                  color: cs.onSurfaceVariant,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              _panel(
                cs,
                isDark,
                accent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _topicCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.mindset_learn_topic,
                        hintText: l10n.mindset_learn_topic_hint,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _lessonCtrl,
                      minLines: 3,
                      maxLines: 8,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: l10n.mindset_learn_lesson,
                        alignLabelWithHint: true,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _save(personId),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.psychology_alt_outlined),
                      label: Text(l10n.mindset_learn_save),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                l10n.mindset_learn_history,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 10),
              StreamBuilder<List<MindLogData>>(
                stream: context.read<MindBlock>().watchAllMindLogs(personId),
                builder: (context, snap) {
                  final logs = (snap.data ?? const [])
                      .where(MindsetLearnPage.isMindsetLog)
                      .toList()
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (logs.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.mindset_learn_empty,
                        style: TextStyle(
                          color: cs.onSurface.withValues(alpha: 0.5),
                          height: 1.35,
                        ),
                      ),
                    );
                  }

                  final dateFmt = DateFormat.yMMMd(
                    Localizations.localeOf(context).toString(),
                  );
                  return Column(
                    children: logs.map((log) {
                      final topic = MindsetLearnPage.topicFromLog(log) ??
                          l10n.mindset_learn_topic;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _panel(
                          cs,
                          isDark,
                          accent,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      topic,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    dateFmt.format(log.createdAt.toLocal()),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: cs.onSurface
                                          .withValues(alpha: 0.45),
                                    ),
                                  ),
                                ],
                              ),
                              if (log.note != null &&
                                  log.note!.trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  log.note!.trim(),
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          );
    });
  }

  Widget _panel(
    ColorScheme cs,
    bool isDark,
    Color accent, {
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: HealthMetricColors.shellPanel(
        cs,
        isDark: isDark,
        radius: 18,
        accent: accent,
      ),
      child: child,
    );
  }
}
