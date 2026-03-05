import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/ContentBlock.dart';

class NotificationManagerPage extends StatefulWidget {
  const NotificationManagerPage({super.key});

  @override
  State<NotificationManagerPage> createState() =>
      _NotificationManagerPageState();
}

class _NotificationManagerPageState extends State<NotificationManagerPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notificationService = context.watch<LocalNotificationService>();
    final isEnabled = notificationService.notificationsEnabled.watch(context);

    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Premium Glassmorphic Background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: Theme.of(context).brightness == Brightness.light
                      ? [
                          const Color(0xFFF1F5F9),
                          colorScheme.surface,
                          const Color(0xFFE2E8F0),
                        ]
                      : [
                          const Color(0xFF0F172A),
                          colorScheme.surface,
                          const Color(0xFF1E293B),
                        ],
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(color: Colors.black.withOpacity(0.2)),
              ),
            ),
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        _buildPremiumHeader(context),
                        const SizedBox(height: 24),
                        _buildTabBar(context),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildActiveHunterTab(context, isEnabled),
                        _buildRemindersTab(context, isEnabled),
                        _buildWisdomBoardTab(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "NOTIFICATION CENTER",
              style: TextStyle(
                color: Colors.blueAccent.withOpacity(0.8),
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "HUNTER HUB",
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 22, // Reduced from 28 to prevent overflow
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => GoRouter.of(context).push('/notification-inbox'),
              icon: const Icon(
                Icons.history,
                color: Colors.blueAccent,
                size: 26,
              ),
              style: IconButton.styleFrom(
                backgroundColor: Colors.blueAccent.withOpacity(0.1),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.blueAccent.withOpacity(0.2)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurface,
                size: 28,
              ),
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.onSurface.withOpacity(0.05),
                padding: const EdgeInsets.all(12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.onSurface.withOpacity(0.1)),
      ),
      child: TabBar(
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: const LinearGradient(
            colors: [Colors.blueAccent, Color.fromARGB(255, 58, 129, 187)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blueAccent.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: colorScheme.onSurface.withOpacity(0.5),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: "Active Hunter"),
          Tab(text: "Reminders"),
          Tab(text: "Wisdom Board"),
        ],
      ),
    );
  }

  Widget _buildActiveHunterTab(BuildContext context, bool isEnabled) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        _buildAIAdvisorCard(context),
        const SizedBox(height: 24),
        _buildSystemQuestsSection(context),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildAIAdvisorCard(BuildContext context) {
    final contentBlock = context.watch<ContentBlock>();
    final analyses = contentBlock.analyses.watch(context);

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

    final displayText =
        latest?.summary ??
        latest?.detailedAnalysis ??
        "No analysis available yet. The System will generate insights based on your recent metrics.";
    final subtitle = latest != null
        ? "Advice based on recent metrics"
        : "Awaiting data synchronization";
    final hasLiveData = latest != null;

    return _buildGlassCard(
      borderColor: Colors.blueAccent.withOpacity(0.3),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blueAccent.withOpacity(0.1), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.psychology_outlined,
                  color: Colors.blueAccent,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  "SYSTEM ANALYSIS",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.sensors_rounded,
                  color: hasLiveData
                      ? Colors.greenAccent
                      : Colors.greenAccent.withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "\"$displayText\"",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 15,
                fontFamily: 'Courier', // Typewriter feel
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemQuestsSection(BuildContext context) {
    final dao = context.watch<QuestDAO>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.currentPersonID.watch(context) ?? "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "DAILY QUEST: ",
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<QuestData>>(
          stream: dao.watchActiveQuests(personId),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) {
              return const SizedBox.shrink();
            }
            final quests = snapshot.data!;
            if (quests.isEmpty) return const SizedBox.shrink();

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
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quest.title ?? "Unnamed Quest",
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        quest.description ?? "Active System Quest",
                        style: TextStyle(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      progress,
                      style: const TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _handleCompleteQuest(context, quest),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.greenAccent.withOpacity(0.5),
                          ),
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.greenAccent,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percent,
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.1),
                valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                minHeight: 4,
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

    // Award EXP to Social Score
    try {
      final personBlock = context.read<PersonBlock>();
      final pID = personBlock.currentPersonID.value;
      final reward = quest.rewardExp ?? 0;
      if (pID != null && reward > 0) {
        await context.read<ScoreDAO>().incrementSocialScore(
          pID,
          reward.toDouble(),
        );
      }
    } catch (e) {
      debugPrint('Error awarding social EXP: $e');
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "[SYSTEM] Quest '${quest.title ?? "Unnamed"}' Completed! +${quest.rewardExp ?? 0} EXP",
          ),
          backgroundColor: Colors.blueAccent.withOpacity(0.8),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Widget _buildRemindersTab(BuildContext context, bool isEnabled) {
    final customNotificationDao = context.watch<CustomNotificationDAO>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Personal Reminders",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddNotificationDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text("Add New"),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
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
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 64),
                        child: Column(
                          children: [
                            Icon(
                              Icons.notifications_none_rounded,
                              size: 48,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "No active reminders.\nAdd one to keep track of your schedule.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: snapshot.data!.map((notif) {
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
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 64),
              child: Column(
                children: [
                  Icon(
                    Icons.notifications_off_rounded,
                    size: 48,
                    color: Colors.white.withOpacity(0.1),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Notifications are disabled.\nEnable them in settings to see your reminders.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWisdomBoardTab(BuildContext context) {
    final dao = context.watch<QuoteDAO>();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Wisdom Board",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () => _showAddQuoteDialog(context),
              icon: const Icon(Icons.add_rounded, size: 20),
              label: const Text("Add Quote"),
              style: TextButton.styleFrom(foregroundColor: Colors.blueAccent),
            ),
          ],
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<QuoteData>>(
          stream: dao.watchAllQuotes(),
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Column(
                    children: [
                      Icon(
                        Icons.auto_stories_rounded,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Your board is empty.\nSave some wisdom to stay focused.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
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
  }

  Widget _buildQuoteTile(BuildContext context, QuoteData quote) {
    final dao = context.read<QuoteDAO>();
    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.format_quote_rounded,
                  color: Colors.blueAccent,
                  size: 24,
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
                    ).colorScheme.onSurface.withOpacity(0.5),
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
                    color: Colors.redAccent.withOpacity(0.6),
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
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            "Add New Wisdom",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: contentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: _premiumInputDecoration(
                  "Content",
                  Icons.format_quote_rounded,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: authorController,
                style: const TextStyle(color: Colors.white),
                decoration: _premiumInputDecoration(
                  "Author",
                  Icons.person_outline,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
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
              child: const Text("Save Wisdom"),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGlassCard({required Widget child, Color? borderColor}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.08),
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color:
                    borderColor ??
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
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

    final category = notification.category ?? 'General';
    final priority = notification.priority ?? 'Normal';

    final categoryIcons = {
      'General': Icons.notifications_none_rounded,
      'Health': Icons.favorite_rounded,
      'Finance': Icons.account_balance_wallet_rounded,
      'Social': Icons.people_rounded,
      'Projects': Icons.rocket_launch_rounded,
    };

    return _buildGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    categoryIcons[category] ?? Icons.notifications_none_rounded,
                    color: Colors.blueAccent,
                    size: 20,
                  ),
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
                          ).colorScheme.onSurface.withOpacity(0.6),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.blueAccent,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            formattedTime,
                            style: const TextStyle(
                              color: Colors.blueAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getPriorityColor(priority).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        priority,
                        style: TextStyle(
                          color: _getPriorityColor(priority),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.edit_rounded,
                        color: Colors.blueAccent.withOpacity(0.6),
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
                        color: Colors.redAccent.withOpacity(0.6),
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
                side: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              title: Text(
                existing == null ? "New Reminder" : "Edit Reminder",
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
                        "Title",
                        Icons.title_rounded,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _premiumInputDecoration(
                        "Content",
                        Icons.subject_rounded,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Category Picker
                    const Text(
                      "Category",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.entries.map((e) {
                        final isSelected = selectedCategory == e.key;
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
                                  ? Colors.blueAccent.withOpacity(0.2)
                                  : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.blueAccent
                                    : Colors.white.withOpacity(0.1),
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
                                  e.key,
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
                                      ? color.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : Colors.white.withOpacity(0.1),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  p,
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
                              return DropdownMenuItem(
                                value: f,
                                child: Text(
                                  f.toUpperCase(),
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
                              "Repeat",
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
                                "Time",
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
                            "Date",
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
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (titleController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Please enter a title")),
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
                  child: Text(existing == null ? "Save Reminder" : "Update"),
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
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
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
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? Colors.blueAccent
                    : Colors.white.withOpacity(0.1),
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
