import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class FocusHistoryPage extends StatelessWidget {
  const FocusHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final focusBlock = context.watch<FocusBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            "Focus History",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<List<FocusSessionData>>(
          stream: context.read<FocusSessionsDAO>().watchSessionsByPerson(
            focusBlock.currentPersonId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = snapshot.data!.reversed.toList();

            if (sessions.isEmpty) {
              return _EmptyState(colorScheme: colorScheme);
            }

            final groupedSessions = _groupSessionsByDate(sessions);
            final totalMinutes = sessions.fold<int>(
              0,
              (sum, s) => sum + (s.durationSeconds ~/ 60),
            );

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: _OverallStats(
                    totalSessions: sessions.length,
                    totalMinutes: totalMinutes,
                    colorScheme: colorScheme,
                  ),
                ),
                ...groupedSessions.entries.map((entry) {
                  return SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: _DateHeader(
                          date: entry.key,
                          sessions: entry.value,
                          colorScheme: colorScheme,
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((
                            context,
                            index,
                          ) {
                            final session = entry.value[index];
                            return _HistoryItem(
                              session: session,
                              focusBlock: focusBlock,
                            );
                          }, childCount: entry.value.length),
                        ),
                      ),
                    ],
                  );
                }),
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            );
          },
        ),
      ),
    );
  }

  Map<DateTime, List<FocusSessionData>> _groupSessionsByDate(
    List<FocusSessionData> sessions,
  ) {
    final grouped = <DateTime, List<FocusSessionData>>{};
    for (final session in sessions) {
      final date = DateTime(
        session.startTime.year,
        session.startTime.month,
        session.startTime.day,
      );
      grouped.putIfAbsent(date, () => []).add(session);
    }
    return grouped;
  }
}

class _OverallStats extends StatelessWidget {
  final int totalSessions;
  final int totalMinutes;
  final ColorScheme colorScheme;

  const _OverallStats({
    required this.totalSessions,
    required this.totalMinutes,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatTile(
            label: "Sessions",
            value: totalSessions.toString(),
            icon: Icons.bolt_rounded,
            onPrimary: colorScheme.onPrimary,
          ),
          Container(
            width: 1,
            height: 40,
            color: colorScheme.onPrimary.withOpacity(0.2),
          ),
          _StatTile(
            label: "Total Time",
            value: "${totalMinutes ~/ 60}h ${totalMinutes % 60}m",
            icon: Icons.timer_rounded,
            onPrimary: colorScheme.onPrimary,
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color onPrimary;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: onPrimary.withOpacity(0.8), size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: onPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: onPrimary.withOpacity(0.7), fontSize: 11),
        ),
      ],
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;
  final List<FocusSessionData> sessions;
  final ColorScheme colorScheme;

  const _DateHeader({
    required this.date,
    required this.sessions,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String dateStr;
    if (date == today) {
      dateStr = "Today";
    } else if (date == yesterday) {
      dateStr = "Yesterday";
    } else {
      dateStr = DateFormat('MMMM d, yyyy').format(date);
    }

    final dailyMinutes = sessions.fold<int>(
      0,
      (sum, s) => sum + (s.durationSeconds ~/ 60),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dateStr.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              color: colorScheme.primary,
            ),
          ),
          Text(
            "${dailyMinutes}m focused",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final FocusSessionData session;
  final FocusBlock focusBlock;

  const _HistoryItem({required this.session, required this.focusBlock});

  @override
  Widget build(BuildContext context) {
    final mins = session.durationSeconds ~/ 60;
    final colorScheme = Theme.of(context).colorScheme;
    final modeColor = session.sessionType == 'Focus'
        ? Colors.orangeAccent
        : Colors.teal;

    return Dismissible(
      key: Key(session.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => focusBlock.deleteSession(session.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: modeColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                session.sessionType == 'Focus'
                    ? Icons.bolt_rounded
                    : Icons.coffee_rounded,
                color: modeColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "${mins}m ${session.sessionType} Session",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (session.notes != null && session.notes!.isNotEmpty) ...[
                    Text(
                      session.notes!,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('HH:mm').format(session.startTime),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                if (session.status == 'interrupted')
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "Interrupted",
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ColorScheme colorScheme;
  const _EmptyState({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_rounded,
              size: 80,
              color: colorScheme.primary.withOpacity(0.2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "No Focus History Yet",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              "Your focus sessions will be listed here once you complete them. Start your first session to build your streak!",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text("Start Focusing"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
