import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Services/NotificationInit.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ContentBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlockerBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MorningLoopPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/NotificationMaskChip.dart';
import 'package:ice_gate/sensor_layer/ui_layer/canvas_page/DotGridPainter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';

class NotificationManagerPage extends StatefulWidget {
  const NotificationManagerPage({super.key});

  @override
  State<NotificationManagerPage> createState() =>
      _NotificationManagerPageState();
}

class _NotificationManagerPageState extends State<NotificationManagerPage> {
  static const double _hubMaxWidth = 560;
  static const double _headerClearance = 56;

  bool _morningPrefsLoading = true;
  bool _morningReminderEnabled = true;
  bool _morningBriefingEnabled = true;
  bool _quotesSyncStarted = false;
  TimeOfDay _morningReminderTime = const TimeOfDay(hour: 7, minute: 0);

  Color _hubAccent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  @override
  void initState() {
    super.initState();
    _loadMorningPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncQuotesFromCloud());
  }

  void _syncQuotesFromCloud() {
    if (_quotesSyncStarted || !mounted) return;
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;
    _quotesSyncStarted = true;
    unawaited(context.read<QuoteDAO>().syncFromCloud(personId));
  }

  Future<void> _loadMorningPrefs() async {
    final reminder = await MorningLoopPrefs.getReminderEnabled();
    final briefing = await MorningLoopPrefs.getBriefingEnabled();
    final hour = await MorningLoopPrefs.getHour();
    final minute = await MorningLoopPrefs.getMinute();
    if (!mounted) return;
    setState(() {
      _morningReminderEnabled = reminder;
      _morningBriefingEnabled = briefing;
      _morningReminderTime = TimeOfDay(hour: hour, minute: minute);
      _morningPrefsLoading = false;
    });
  }

  Future<void> _persistMorningPrefs() async {
    await MorningLoopPrefs.setReminderEnabled(_morningReminderEnabled);
    await MorningLoopPrefs.setBriefingEnabled(_morningBriefingEnabled);
    await MorningLoopPrefs.setTime(
      _morningReminderTime.hour,
      _morningReminderTime.minute,
    );
    if (!mounted) return;
    try {
      await context
          .read<LocalNotificationService>()
          .scheduleMorningLoopFromPrefs();
    } catch (e) {
      debugPrint('NotificationManagerPage: morning schedule failed — $e');
    }
  }

  Future<void> _pickMorningReminderTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _morningReminderTime,
    );
    if (picked == null) return;
    setState(() => _morningReminderTime = picked);
    await _persistMorningPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<LocalNotificationService>();
    final isEnabled = notificationService.notificationsEnabled.watch(context);

    final colorScheme = Theme.of(context).colorScheme;

    final tabs = [
      {
        'title': AppLocalizations.of(context)!.notification_tab_active,
        'view': _buildActiveHunterTab(context, isEnabled),
      },
      {
        'title': AppLocalizations.of(context)!.notification_tab_reminders,
        'view': _buildRemindersTab(context, isEnabled),
      },
      {
        'title': AppLocalizations.of(context)!.notification_tab_wisdom,
        'view': _buildWisdomBoardTab(context),
      },
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panelColor = isDark
        ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.72)
        : colorScheme.surfaceContainerHigh.withValues(alpha: 0.95);

    return DefaultTabController(
      length: tabs.length,
      animationDuration: const Duration(milliseconds: 320),
      child: Scaffold(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.98),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: _headerClearance),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildPremiumHeader(context),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildTabBar(context, tabs),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  decoration: BoxDecoration(
                    color: panelColor,
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: DotGridPainter(
                              color: colorScheme.onSurface,
                              opacity: isDark ? 0.06 : 0.04,
                              spacing: 25,
                            ),
                          ),
                        ),
                        TabBarView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          clipBehavior: Clip.hardEdge,
                          children:
                              tabs.map((t) => t['view'] as Widget).toList(),
                        ),
                      ],
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

  Widget _buildPremiumHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final accent = _hubAccent(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.notification_manager_title.toUpperCase(),
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                l10n.notification_hunter_hub,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
        _headerIconButton(
          context,
          icon: Icons.history_rounded,
          onPressed: () {
            HapticFeedback.lightImpact();
            context.push('/notification-inbox');
          },
        ),
        const SizedBox(width: 10),
        _headerIconButton(
          context,
          icon: Icons.close_rounded,
          onPressed: () => Navigator.maybePop(context),
        ),
      ],
    );
  }

  Widget _headerIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final accent = _hubAccent(context);
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
            border: Border.all(color: accent.withValues(alpha: 0.4), width: 1.2),
          ),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: cs.onSurface, size: 22),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, List<Map<String, dynamic>> tabs) {
    final cs = Theme.of(context).colorScheme;
    final accent = _hubAccent(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: accent.withValues(alpha: 0.14),
          border: Border.all(color: accent.withValues(alpha: 0.55), width: 1.3),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: cs.onSurface,
        unselectedLabelColor: cs.onSurfaceVariant,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 11.5,
          letterSpacing: 0.4,
        ),
        dividerColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        tabs: tabs.map((t) => Tab(text: t['title'] as String)).toList(),
      ),
    );
  }

  Widget _buildActiveHunterTab(BuildContext context, bool isEnabled) {
    return _hubScroll(
      context,
      children: [
        _buildAIAdvisorCard(context),
        const SizedBox(height: 14),
        _buildSystemQuestsSection(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _hubScroll(BuildContext context, {required List<Widget> children}) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _hubMaxWidth),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 108),
          physics: const BouncingScrollPhysics(),
          children: children,
        ),
      ),
    );
  }

  Widget _buildAIAdvisorCard(BuildContext context) {
    final contentBlock = context.watch<ContentBlock>();
    final analyses = contentBlock.analyses.watch(context);
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accent = _hubAccent(context);

    // Pick the latest featured analysis, or just the latest one
    final featured = analyses.where((a) => a.isFeatured == true).toList()
      ..sort(
        (a, b) => (b.publishedAt ?? DateTime(0)).compareTo(
          a.publishedAt ?? DateTime(0),
        ),
      );
    final latest = featured.isNotEmpty
        ? featured.first
        : (analyses.isNotEmpty ? analyses.first : null);

    final hasLiveData = latest != null;
    final displayText =
        latest?.summary ?? latest?.detailedAnalysis;
    final subtitle = hasLiveData
        ? l10n.notification_ai_advice
        : l10n.notification_ai_waiting;

    return _buildSurfaceCard(
      context,
      accent: accent,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _accentIcon(context, Icons.psychology_outlined, accent: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.notification_ai_analysis,
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                Icon(
                  Icons.sensors_rounded,
                  color: hasLiveData
                      ? HealthMetricColors.pillarGreen
                      : cs.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (!hasLiveData)
              _hubInlineEmpty(
                context,
                icon: Icons.insights_outlined,
                title: l10n.notification_ai_no_data,
                subtitle: subtitle,
              )
            else ...[
              Text(
                displayText!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _hubSectionLabel(BuildContext context, String label) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      label,
      style: TextStyle(
        color: cs.onSurfaceVariant,
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _hubInlineEmpty(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Column(
        children: [
          Icon(icon, size: 36, color: cs.onSurfaceVariant.withValues(alpha: 0.7)),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
        ],
      ),
    );
  }

  Widget _hubEmptyCard(
    BuildContext context, {
    required IconData icon,
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final cs = Theme.of(context).colorScheme;
    return _buildSurfaceCard(
      context,
      accent: cs.outline,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        child: Column(
          children: [
            Icon(icon, size: 40, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accentIcon(
    BuildContext context,
    IconData icon, {
    Color? accent,
  }) {
    final tone = accent ?? _hubAccent(context);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: tone.withValues(alpha: 0.12),
        border: Border.all(color: tone.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Icon(icon, color: tone, size: 22),
    );
  }

  Widget _buildSystemQuestsSection(BuildContext context) {
    final dao = context.watch<QuestDAO>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.currentPersonID.watch(context) ?? "";
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _hubSectionLabel(
          context,
          l10n.notification_daily_quest.toUpperCase(),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<QuestData>>(
          stream: dao.watchActiveQuests(personId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            final quests = snapshot.data ?? [];
            if (quests.isEmpty) {
              return _hubEmptyCard(
                context,
                icon: Icons.flag_outlined,
                message: l10n.notification_no_active_quests,
              );
            }

            return Column(
              children: quests.map((quest) {
                final targetV = quest.targetValue ?? 0.0;
                final currentV = quest.currentValue ?? 0.0;
                final percent = targetV > 0
                    ? (currentV / targetV).clamp(0.0, 1.0)
                    : 0.0;
                final progressStr = "${currentV.toInt()} / ${targetV.toInt()}";

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSoloLevelingQuestTile(
                    context,
                    quest: quest,
                    progress: progressStr,
                    percent: percent,
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSoloLevelingQuestTile(
    BuildContext context, {
    required QuestData quest,
    required String progress,
    required double percent,
  }) {
    final cs = Theme.of(context).colorScheme;

    return _buildSurfaceCard(
      context,
      accent: HealthMetricColors.pillarYellow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _accentIcon(
                  context,
                  Icons.flag_rounded,
                  accent: HealthMetricColors.pillarYellow,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title ??
                            AppLocalizations.of(context)!.project_note_untitled,
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        quest.description ??
                            AppLocalizations.of(context)!.notification_tab_active,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.92),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    Text(
                      progress,
                      style: TextStyle(
                        color: HealthMetricColors.pillarYellow,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _handleCompleteQuest(context, quest),
                        borderRadius: BorderRadius.circular(20),
                        child: Ink(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: HealthMetricColors.pillarGreen
                                  .withValues(alpha: 0.55),
                            ),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.check_rounded,
                              color: HealthMetricColors.pillarGreen,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: cs.outlineVariant.withValues(alpha: 0.25),
                valueColor: AlwaysStoppedAnimation(
                  HealthMetricColors.pillarYellow.withValues(alpha: 0.95),
                ),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCompleteQuest(
    BuildContext context,
    QuestData quest,
  ) async {
    final dao = context.read<QuestDAO>();
    final targetV = quest.targetValue ?? 0.0;
    await dao.updateQuestProgress(quest.id, targetV > 0 ? targetV : 1.0);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.notification_quest_completed_snack(
              quest.title ?? AppLocalizations.of(context)!.project_note_untitled,
              0, // Passing 0 for exp as we're removing it from the message
            ),
          ),
          backgroundColor: Colors.blueAccent.withValues(alpha: 0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildRemindersTab(BuildContext context, bool isEnabled) {
    final customNotificationDao = context.watch<CustomNotificationDAO>();
    final cs = Theme.of(context).colorScheme;
    final accent = _hubAccent(context);
    final l10n = AppLocalizations.of(context)!;

    return _hubScroll(
      context,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.notification_personal_reminders,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () => _showAddNotificationDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text(l10n.notification_add_new),
              style: TextButton.styleFrom(foregroundColor: accent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isEnabled)
          Builder(
            builder: (context) {
              final personBlock = context.watch<PersonBlock>();
              final personId = personBlock.currentPersonID.watch(context) ?? "";
              return StreamBuilder<List<CustomNotificationData>>(
                stream: customNotificationDao.watchAllNotifications(personId),
                builder: (context, snapshot) {
                  final notifications = snapshot.data ?? [];
                  if (notifications.isEmpty) {
                    return _hubEmptyCard(
                      context,
                      icon: Icons.notifications_none_rounded,
                      message: l10n.notification_no_reminders,
                      actionLabel: l10n.notification_add_new,
                      onAction: () => _showAddNotificationDialog(context),
                    );
                  }
                  return Column(
                    children: notifications.map((notif) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildCustomNotificationTile(context, notif),
                      );
                    }).toList(),
                  );
                },
              );
            },
          )
        else
          _hubEmptyCard(
            context,
            icon: Icons.notifications_off_rounded,
            message: l10n.notification_disabled_desc,
          ),
        const SizedBox(height: 32),
        _buildSystemPreferencesSection(context),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildSystemPreferencesSection(BuildContext context) {
    // ignore: unused_local_variable
    final blocker = context.watch<SocialBlockerBlock>();
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.notification_system_preferences,
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        if (_morningPrefsLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          )
        else ...[
          _buildPreferenceTile(
            context,
            title: l10n.morning_loop_reminder_title,
            subtitle: l10n.morning_loop_reminder_subtitle,
            icon: Icons.wb_sunny_outlined,
            color: HealthMetricColors.pillarYellow,
            trailing: Switch.adaptive(
              value: _morningReminderEnabled,
              activeColor: HealthMetricColors.pillarYellow,
              onChanged: (value) async {
                setState(() => _morningReminderEnabled = value);
                await _persistMorningPrefs();
              },
            ),
            footer: _morningReminderEnabled
                ? Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: NotificationMaskChip.schedule(
                        label: DateFormat.jm().format(
                          DateTime(
                            0,
                            1,
                            1,
                            _morningReminderTime.hour,
                            _morningReminderTime.minute,
                          ),
                        ),
                        onTap: _pickMorningReminderTime,
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 12),
          _buildPreferenceTile(
            context,
            title: l10n.morning_briefing_toggle,
            subtitle: l10n.notification_morning_briefing_subtitle,
            icon: Icons.waving_hand_outlined,
            color: HealthMetricColors.pillarViolet,
            trailing: Switch.adaptive(
              value: _morningBriefingEnabled,
              activeColor: HealthMetricColors.pillarViolet,
              onChanged: (value) async {
                setState(() => _morningBriefingEnabled = value);
                await _persistMorningPrefs();
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
        _buildPreferenceTile(
          context,
          title: l10n.notification_pomodoro_reminder_title,
          subtitle: l10n.notification_pomodoro_reminder_subtitle,
          icon: Icons.notifications_active_rounded,
          color: Colors.greenAccent,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.notification_status_on,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildPreferenceTile(
          context,
          title: l10n.notification_live_activities_title,
          subtitle: l10n.notification_live_activities_subtitle,
          icon: Icons.timer_rounded,
          color: Colors.blueAccent,
          trailing: Switch.adaptive(
            value: true, // Sync with Block later
            activeColor: Colors.blueAccent,
            onChanged: (val) {},
          ),
        ),
      ],
    );
  }

  Widget _buildPreferenceTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? trailing,
    Widget? footer,
  }) {
    return _buildSurfaceCard(
      context,
      accent: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.12),
                border: Border.all(color: color.withValues(alpha: 0.35), width: 1.2),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  if (footer != null) footer,
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing ?? const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildWisdomBoardTab(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accent = _hubAccent(context);
    final l10n = AppLocalizations.of(context)!;

    return Watch((context) {
      final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
      final dao = context.read<QuoteDAO>();

      return _hubScroll(
        context,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.notification_wisdom_board,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton.icon(
                onPressed: () => _showAddQuoteDialog(context),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: Text(l10n.notification_add_quote),
                style: TextButton.styleFrom(foregroundColor: accent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<QuoteData>>(
            stream: personId.isEmpty
                ? const Stream.empty()
                : dao.watchQuotesByPerson(personId),
            builder: (context, snapshot) {
              if (personId.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _hubEmptyCard(
                  context,
                  icon: Icons.auto_stories_rounded,
                  message: l10n.notification_quote_empty,
                  actionLabel: l10n.notification_add_quote,
                  onAction: () => _showAddQuoteDialog(context),
                );
              }

              return Column(
                children: snapshot.data!.map((quote) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildQuoteTile(context, quote),
                  );
                }).toList(),
              );
            },
          ),
        ],
      );
    });
  }

  Widget _buildQuoteTile(BuildContext context, QuoteData quote) {
    final dao = context.read<QuoteDAO>();
    return _buildSurfaceCard(
      context,
      accent: HealthMetricColors.pillarViolet,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _accentIcon(
                  context,
                  Icons.format_quote_rounded,
                  accent: HealthMetricColors.pillarViolet,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    quote.content,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
            if (quote.author != null && quote.author!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  "- ${quote.author}",
                  style: TextStyle(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  onPressed: () => dao.deleteQuote(quote.id),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.redAccent.withValues(alpha: 0.6),
                    size: 20,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddQuoteDialog(BuildContext context) {
    final contentController = TextEditingController();
    final authorController = TextEditingController();
    final personBlock = context.read<PersonBlock>();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF161B33),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
          ),
          title: Text(
            AppLocalizations.of(context)!.notification_add_wisdom_title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _premiumInputDecoration(
                  AppLocalizations.of(context)!.notification_wisdom_content,
                  Icons.format_quote_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorController,
                style: const TextStyle(color: Colors.white),
                decoration: _premiumInputDecoration(
                  AppLocalizations.of(context)!.notification_wisdom_author,
                  Icons.person_outline,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                AppLocalizations.of(context)!.cancel,
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (contentController.text.isEmpty) return;
                final dao = context.read<QuoteDAO>();
                dao
                    .insertQuote(
                      QuotesTableCompanion.insert(
                        id: IDGen.UUIDV7(),
                        content: contentController.text,
                        author: Value(authorController.text),
                        personID: Value(personBlock.currentPersonID.value),
                      ),
                    )
                    .then((_) => Navigator.pop(context));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.notification_save_reminder),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSurfaceCard(
    BuildContext context, {
    required Widget child,
    Color? accent,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tone = accent ?? _hubAccent(context);
    const radius = 22.0;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(
          alpha: Theme.of(context).brightness == Brightness.dark ? 0.55 : 0.85,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: tone.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      child: child,
    );
  }

  Widget _buildCustomNotificationTile(
    BuildContext context,
    CustomNotificationData notification,
  ) {
    final dao = context.read<CustomNotificationDAO>();
    final service = context.read<LocalNotificationService>();
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.currentPersonID.value ?? "";
    final formattedTime = DateFormat(
      'MMM dd, HH:mm',
    ).format(notification.scheduledTime);

    final categoryIcons = {
      'General': Icons.notifications_none_rounded,
      'Health': Icons.favorite_rounded,
      'Finance': Icons.account_balance_wallet_rounded,
      'Social': Icons.people_rounded,
      'Projects': Icons.rocket_launch_rounded,
    };

    return _buildSurfaceCard(
      context,
      accent: _hubAccent(context),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _accentIcon(
                  context,
                  categoryIcons[notification.category] ??
                      Icons.notifications_none_rounded,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        notification.title,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        notification.content,
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: notification.isEnabled,
                  onChanged: (val) async {
                    final updated = notification.copyWith(isEnabled: val);
                    await dao.updateNotification(updated);
                    await service.syncAllNotifications(personId);
                  },
                  activeThumbColor: Colors.blueAccent,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    NotificationMaskChip.schedule(label: formattedTime),
                    const SizedBox(width: 8),
                    NotificationMaskChip.tag(
                      label: _localizedPriorityShort(
                        context,
                        notification.priority,
                      ),
                      tagAccent: _getPriorityColor(notification.priority),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blueAccent.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () => _showAddNotificationDialog(
                        context,
                        existing: notification,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.redAccent.withValues(alpha: 0.6),
                        size: 20,
                      ),
                      onPressed: () async {
                        await dao.deleteNotification(notification.id);
                        await service.syncAllNotifications(personId);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotificationDialog(
    BuildContext context, {
    CustomNotificationData? existing,
  }) {
    final titleController = TextEditingController(text: existing?.title);
    final contentController = TextEditingController(text: existing?.content);
    DateTime selectedDate =
        existing?.scheduledTime ??
        DateTime.now().add(const Duration(minutes: 5));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);
    String repeatFrequency = existing?.repeatFrequency ?? 'once';
    List<int> repeatDays =
        existing?.repeatDays
            ?.split(',')
            .where((s) => s.isNotEmpty)
            .map((s) => int.parse(s))
            .toList() ??
        [];
    String selectedCategory = existing?.category ?? 'General';
    String selectedPriority = existing?.priority ?? 'Normal';

    final categories = {
      'General': Icons.notifications_none_rounded,
      'Daily': Icons.calendar_today_rounded,
      'Health': Icons.favorite_rounded,
      'Finance': Icons.account_balance_wallet_rounded,
      'Social': Icons.people_rounded,
      'Projects': Icons.rocket_launch_rounded,
    };

    final priorities = ['Low', 'Normal', 'High', 'Urgent'];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF161B33),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
                side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              title: Text(
                existing == null
                    ? AppLocalizations.of(context)!.notification_reminder_new
                    : AppLocalizations.of(context)!.notification_reminder_edit,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -0.5,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _premiumInputDecoration(
                        AppLocalizations.of(context)!.project_title_label,
                        Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _premiumInputDecoration(
                        AppLocalizations.of(context)!.notification_wisdom_content,
                        Icons.subject_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Picker
                    Text(
                      AppLocalizations.of(context)!.notification_wisdom_author,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.entries.map((e) {
                        final isSelected = selectedCategory == e.key;
                        final localizedCategory = {
                          'General': AppLocalizations.of(context)!.notification_category_general,
                          'Daily': AppLocalizations.of(context)!.notification_category_daily,
                          'Health': AppLocalizations.of(context)!.notification_category_health,
                          'Finance': AppLocalizations.of(context)!.notification_category_finance,
                          'Social': AppLocalizations.of(context)!.notification_category_social,
                          'Projects': AppLocalizations.of(context)!.notification_category_projects,
                        }[e.key] ?? e.key;
                        
                        return InkWell(
                          onTap: () =>
                              setDialogState(() => selectedCategory = e.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Colors.blueAccent.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  e.value,
                                  size: 16,
                                  color: isSelected
                                      ? Colors.blueAccent
                                      : Colors.white70,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  localizedCategory,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.blueAccent
                                        : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Priority Picker
                    const Text(
                      "Priority",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: priorities.map((p) {
                        final isSelected = selectedPriority == p;
                        final color = _getPriorityColor(p);
                        final localizedPriority = {
                          'Low': AppLocalizations.of(context)!.notification_priority_low,
                          'Normal': AppLocalizations.of(context)!.notification_priority_normal,
                          'High': AppLocalizations.of(context)!.notification_priority_high,
                          'Urgent': AppLocalizations.of(context)!.notification_priority_urgent,
                        }[p] ?? p;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: InkWell(
                              onTap: () =>
                                  setDialogState(() => selectedPriority = p),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? color.withValues(alpha: 0.2)
                                      : Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  localizedPriority,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? color : Colors.white70,
                                    fontSize: 10,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Time and Repeat
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            dropdownColor: const Color(0xFF161B33),
                            initialValue: repeatFrequency,
                            items: ['once', 'daily', 'weekly'].map((f) {
                              final localizedFreq = {
                                'once': AppLocalizations.of(context)!.notification_freq_once,
                                'daily': AppLocalizations.of(context)!.notification_freq_daily,
                                'weekly': AppLocalizations.of(context)!.notification_freq_weekly,
                              }[f] ?? f;
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  localizedFreq.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setDialogState(() => repeatFrequency = val!),
                            decoration: _premiumInputDecoration(
                              AppLocalizations.of(context)!.notification_repeat_label,
                              Icons.repeat_rounded,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final time = await showTimePicker(
                                context: context,
                                initialTime: selectedTime,
                              );
                              if (time != null) {
                                setDialogState(() => selectedTime = time);
                              }
                            },
                            child: InputDecorator(
                              decoration: _premiumInputDecoration(
                                AppLocalizations.of(context)!.notification_time_label,
                                Icons.access_time_rounded,
                              ),
                              child: Text(
                                selectedTime.format(context),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (repeatFrequency == 'once') ...[
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() => selectedDate = date);
                          }
                        },
                        child: InputDecorator(
                          decoration: _premiumInputDecoration(
                            AppLocalizations.of(context)!.notification_date_label,
                            Icons.calendar_today_rounded,
                          ),
                          child: Text(
                            DateFormat('MMM dd, yyyy').format(selectedDate),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                    if (repeatFrequency == 'weekly') ...[
                      const SizedBox(height: 16),
                      _buildDayPicker(
                        repeatDays,
                        (days) => setDialogState(() => repeatDays = days),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    AppLocalizations.of(context)!.cancel,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppLocalizations.of(context)!.notification_enter_title_snack)),
                      );
                      return;
                    }
                    final dao = context.read<CustomNotificationDAO>();
                    final service = context.read<LocalNotificationService>();
                    final personBlock = context.read<PersonBlock>();
                    final personId = personBlock.currentPersonID.value;

                    final scheduled = DateTime(
                      selectedDate.year,
                      selectedDate.month,
                      selectedDate.day,
                      selectedTime.hour,
                      selectedTime.minute,
                    );

                    // Generate numeric ID from time: HHmm
                    final hourStr = selectedTime.hour.toString().padLeft(
                      2,
                      '0',
                    );
                    final minStr = selectedTime.minute.toString().padLeft(
                      2,
                      '0',
                    );
                    final numericIdStr = "$hourStr$minStr";

                    if (existing == null) {
                      dao
                          .insertNotification(
                            CustomNotificationsTableCompanion.insert(
                              id: IDGen.UUIDV7(),
                              title: titleController.text,
                              content: contentController.text,
                              notificationID: Value(numericIdStr),
                              scheduledTime: scheduled,
                              repeatFrequency: Value(repeatFrequency),
                              repeatDays: Value(
                                repeatDays.isEmpty
                                    ? null
                                    : repeatDays.join(','),
                              ),
                              category: Value(selectedCategory),
                              priority: Value(selectedPriority),
                              personID: Value(personId),
                              isEnabled: const Value(true),
                              createdAt: Value(DateTime.now()),
                            ),
                          )
                          .then((id) async {
                            try {
                              await service.syncAllNotifications(
                                personId ?? "",
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              debugPrint("Error syncing notifications: $e");
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error syncing: $e")),
                                );
                              }
                            }
                          })
                          .catchError((e) {
                            debugPrint("Error inserting notification: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error saving: $e")),
                              );
                            }
                          });
                    } else {
                      dao
                          .patchNotification(
                            existing.id,
                            CustomNotificationsTableCompanion(
                              title: Value(titleController.text),
                              content: Value(contentController.text),
                              notificationID: Value(numericIdStr),
                              scheduledTime: Value(scheduled),
                              repeatFrequency: Value(repeatFrequency),
                              repeatDays: Value(
                                repeatDays.isEmpty
                                    ? null
                                    : repeatDays.join(','),
                              ),
                              category: Value(selectedCategory),
                              priority: Value(selectedPriority),
                              personID: Value(personId),
                            ),
                          )
                          .then((_) async {
                            try {
                              await service.syncAllNotifications(
                                personId ?? "",
                              );
                              if (context.mounted) Navigator.pop(context);
                            } catch (e) {
                              debugPrint("Error syncing notifications: $e");
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error syncing: $e")),
                                );
                              }
                            }
                          })
                          .catchError((e) {
                            debugPrint("Error patching notification: $e");
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Error updating: $e")),
                              );
                            }
                          });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(existing == null 
                    ? AppLocalizations.of(context)!.notification_save_reminder 
                    : AppLocalizations.of(context)!.notification_update_reminder),
                ),
              ],
            );
          },
        );
      },
    );
  }

  InputDecoration _premiumInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white54, fontSize: 13),
      prefixIcon: Icon(icon, color: Colors.blueAccent, size: 20),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent),
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.redAccent;
      case 'High':
        return Colors.orangeAccent;
      case 'Normal':
        return Colors.blueAccent;
      case 'Low':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  String _localizedPriorityShort(BuildContext context, String priority) {
    final l10n = AppLocalizations.of(context)!;
    return {
          'Low': l10n.notification_priority_low,
          'Normal': l10n.notification_priority_normal,
          'High': l10n.notification_priority_high,
          'Urgent': l10n.notification_priority_urgent,
        }[priority] ??
        priority;
  }

  Widget _buildDayPicker(
    List<int> selectedDays,
    Function(List<int>) onChanged,
  ) {
    final days = ["M", "T", "W", "T", "F", "S", "S"];
    return Wrap(
      spacing: 6,
      children: List.generate(7, (index) {
        final dayNum = index + 1;
        final isSelected = selectedDays.contains(dayNum);
        return InkWell(
          onTap: () {
            final newDays = List<int>.from(selectedDays);
            if (isSelected) {
              newDays.remove(dayNum);
            } else {
              newDays.add(dayNum);
            }
            onChanged(newDays);
          },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.blueAccent
                  : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.blueAccent
                    : Colors.white.withValues(alpha: 0.1),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }
}
