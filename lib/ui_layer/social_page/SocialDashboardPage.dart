import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'dart:convert';

class SocialDashboardPage extends StatelessWidget {
  const SocialDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final scoreBlock = context.watch<ScoreBlock>();
    final personDAO = context.watch<PersonManagementDAO>();

    return SwipeablePage(
      direction: SwipeablePageDirection.leftToRight,
      onSwipe: () => WidgetNavigatorAction.smartPop(context),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 70,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_rounded,
              color: colorScheme.onSurface,
              size: 22,
            ),
            onPressed: () => WidgetNavigatorAction.smartPop(context),
          ),
          title: Text(
            'Social Analysis',
            style: textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () => context.push('/social/contacts'),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.people_alt_rounded,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
        body: StreamBuilder<List<SocialContact>>(
          stream: personDAO.getAllContacts(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final contacts = snapshot.data!;
            final totalAffection = contacts.fold<int>(
              0,
              (sum, p) => sum + p.affection,
            );
            final avgAffection = contacts.isEmpty
                ? 0.0
                : totalAffection / contacts.length;

            final breakdown = scoreBlock.socialBreakdown.value;
            final contactPoints = breakdown['Contacts'] ?? 0.0;
            final affectionPoints = breakdown['Affection'] ?? 0.0;
            final questPoints = breakdown['Quests'] ?? 0.0;
            final totalPoints = contactPoints + affectionPoints + questPoints;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPerformanceCard(
                    context,
                    colorScheme,
                    textTheme,
                    networkSize: contacts.length,
                    avgAffection: avgAffection,
                    outreach: contacts.length > 5 ? "Active" : "Stable",
                    influence: totalPoints > 100 ? "High" : "Developing",
                  ),
                  const SizedBox(height: 24),
                  _buildSocialBalanceCard(
                    context,
                    colorScheme,
                    textTheme,
                    contactPoints: contactPoints,
                    affectionPoints: affectionPoints,
                    questPoints: questPoints,
                    totalPoints: totalPoints,
                  ),
                  const SizedBox(height: 24),
                  _buildInsightsCard(
                    context,
                    colorScheme,
                    textTheme,
                    networkSize: contacts.length,
                    avgAffection: avgAffection,
                  ),
                  const SizedBox(height: 24),
                  _buildSocialJournalCard(context, colorScheme, textTheme),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPerformanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required int networkSize,
    required double avgAffection,
    required String outreach,
    required String influence,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'NETWORK PERFORMANCE',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              Icon(Icons.hub_rounded, color: colorScheme.primary, size: 16),
            ],
          ),
          const SizedBox(height: 24),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.6,
            children: [
              _buildAnalysisGridItem(
                context,
                'Network Size',
                '$networkSize units',
                Icons.groups_rounded,
                Colors.purple,
              ),
              _buildAnalysisGridItem(
                context,
                'Avg Affection',
                avgAffection.toStringAsFixed(1),
                Icons.favorite_rounded,
                Colors.pink,
              ),
              _buildAnalysisGridItem(
                context,
                'Outreach',
                outreach,
                Icons.send_rounded,
                Colors.blue,
              ),
              _buildAnalysisGridItem(
                context,
                'Influence',
                influence,
                Icons.auto_awesome_rounded,
                Colors.amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialBalanceCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required double contactPoints,
    required double affectionPoints,
    required double questPoints,
    required double totalPoints,
  }) {
    final contactWeight = totalPoints > 0
        ? (contactPoints / totalPoints * 100).round()
        : 0;
    final affectionWeight = totalPoints > 0
        ? (affectionPoints / totalPoints * 100).round()
        : 0;
    final questWeight = (100 - contactWeight - affectionWeight).clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SOCIAL BALANCE',
            style: textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SimplePieChart(
                data: {
                  'Contacts': contactWeight.toDouble(),
                  'Affection': affectionWeight.toDouble(),
                  'Quests': questWeight.toDouble(),
                },
                colors: [Colors.purple, Colors.pink, Colors.amber],
                size: 80,
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Point Distribution',
                      style: textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      Colors.purple,
                      'Contacts',
                      '$contactWeight%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      Colors.pink,
                      'Affection',
                      '$affectionWeight%',
                      textTheme,
                    ),
                    const SizedBox(height: 4),
                    _buildLegendRow(
                      Colors.amber,
                      'Quests',
                      '$questWeight%',
                      textTheme,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(
    Color color,
    String label,
    String value,
    TextTheme textTheme,
  ) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        Text(
          value,
          style: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }

  Widget _buildInsightsCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme, {
    required int networkSize,
    required double avgAffection,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(32.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: colorScheme.outlineVariant.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_rounded, color: Colors.amber, size: 18),
              const SizedBox(width: 8),
              Text(
                'SYSTEM INSIGHTS',
                style: textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInsightItem(
            Icons.trending_up_rounded,
            Colors.purple,
            'Expand Network',
            networkSize < 10
                ? 'Your social reach is limited. Interacting with more people increases your base social score.'
                : 'Keep maintaining your broad network to stabilize your influence.',
            colorScheme,
            textTheme,
          ),
          const SizedBox(height: 12),
          _buildInsightItem(
            Icons.favorite_rounded,
            Colors.pink,
            'Deepen Bonds',
            avgAffection < 50
                ? 'Low average affection detected. Spend more time with key contacts to earn affection bonuses.'
                : 'Your relationships are strong! High affection significantly boosts social multipliers.',
            colorScheme,
            textTheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSocialJournalCard(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withOpacity(0.1),
            colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(32.0),
        border: Border.all(
          color: colorScheme.primary.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/social/journal'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history_edu_rounded,
                            color: colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'SOCIAL JOURNAL',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: colorScheme.primary.withOpacity(0.5),
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ProjectNoteData>>(
                    stream: context.read<ProjectNoteDAO>().watchRecentNotes(
                      personId,
                      1,
                    ),
                    builder: (context, snapshot) {
                      final hasNotes =
                          snapshot.hasData && snapshot.data!.isNotEmpty;
                      final latestNote = hasNotes ? snapshot.data!.first : null;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            latestNote?.title ?? 'Start Your Social Diary',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            latestNote != null
                                ? _getPreviewText(latestNote.content)
                                : 'Record memories, social strategies, and relationship milestones.',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            buffer.write(op['insert']);
          }
        }
        return buffer.toString().trim();
      }
    } catch (_) {}
    return content.trim();
  }

  Widget _buildInsightItem(
    IconData icon,
    Color color,
    String title,
    String description,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisGridItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: textTheme.labelSmall?.copyWith(
                    color: color.withOpacity(0.7),
                    fontWeight: FontWeight.w900,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
