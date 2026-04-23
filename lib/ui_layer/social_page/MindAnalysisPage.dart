import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'dart:convert';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/ui_layer/canvas_page/GoalConfigurationWidget.dart';

class MindAnalysisPage extends StatelessWidget {
  const MindAnalysisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final scoreBlock = context.watch<ScoreBlock>();
    final noteDAO = context.watch<ProjectNoteDAO>();
    final personBlock = context.read<PersonBlock>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      body: Watch((context) {
        final personId = personBlock.currentPersonID.value;
        if (personId == null || personId.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        return Stack(
          children: [
            // 1. Deep Base Background
            Container(color: isDark ? const Color(0xFF0A0A0E) : const Color(0xFFF0F2F5)),

            // 2. Tactical Grid Background
            Positioned.fill(
              child: Opacity(
                opacity: isDark ? 0.3 : 0.1,
                child: CustomPaint(
                  painter: TacticalGridPainter(
                    color: colorScheme.primary,
                    isDark: isDark,
                  ),
                ),
              ),
            ),

            // 3. Ambient Glows
            Positioned(
              top: -100,
              right: -100,
              child: _buildAmbientGlow(colorScheme.primary, 300),
            ),
            Positioned(
              bottom: -50,
              left: -50,
              child: _buildAmbientGlow(colorScheme.secondary, 250),
            ),

            // 4. Main Content
            SafeArea(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(Icons.arrow_back_ios_rounded, color: colorScheme.onSurface, size: 22),
                      onPressed: () => WidgetNavigatorAction.smartPop(context),
                    ),
                    expandedHeight: 120,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      centerTitle: false,
                      title: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('COGNITIVE LAYER'.toUpperCase(),
                              style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          )),
                          Text('STRATEGY JOURNAL',
                              style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          )),
                        ],
                      ),
                    ),
                  ),
                  StreamBuilder<List<ProjectNoteData>>(
                    stream: noteDAO.watchAllNotes(personId),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                      }

                      final notes = snapshot.data!;
                      final strategyNotesCount = notes.length;
                      final breakdown = scoreBlock.socialBreakdown.value;
                      final mentalPoints = breakdown['Mental'] ?? 0.0;
                      final strategyPoints = breakdown['Strategy'] ?? 0.0;
                      final questPoints = breakdown['Quests'] ?? 0.0;
                      final totalPoints = mentalPoints + strategyPoints + questPoints;

                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          child: Column(
                            children: [
                              _buildGlassCard(
                                context,
                                title: 'SYSTEM TELEMETRY',
                                icon: Icons.hub_rounded,
                                child: GridView.count(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 16,
                                  crossAxisSpacing: 16,
                                  childAspectRatio: 1.6,
                                  children: [
                                    _buildTacticalMetric(context, 'STABILITY INDEX', 'OPTIMAL', Icons.psychology_rounded, colorScheme.primary),
                                    _buildTacticalMetric(context, 'STRATEGY DEPTH', '$strategyNotesCount ENTRIES', Icons.auto_awesome_mosaic_rounded, const Color(0xFF00B2FF)),
                                    _buildTacticalMetric(context, 'NEURAL LOAD', '${(questPoints % 100).toInt()}%', Icons.self_improvement_rounded, const Color(0xFFFF2D55)),
                                    _buildTacticalMetric(context, 'COGNITIVE GAIN', '+${mentalPoints.toInt()} XP', Icons.lightbulb_rounded, const Color(0xFFFFD600)),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildGlassCard(
                                context,
                                title: 'COGNITIVE BALANCE',
                                icon: Icons.pie_chart_rounded,
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        SizedBox(
                                          width: 100,
                                          height: 100,
                                          child: SimplePieChart(
                                            data: {'Core': mentalPoints, 'Strategy': strategyPoints, 'Quests': questPoints},
                                            colors: [colorScheme.primary, const Color(0xFF00B2FF), const Color(0xFFFFD600)],
                                            size: 100,
                                          ),
                                        ),
                                        const SizedBox(width: 24),
                                        Expanded(
                                          child: Column(
                                            children: [
                                              _buildLegendRow(context, colorScheme.primary, 'Core Mental', mentalPoints, totalPoints),
                                              const SizedBox(height: 8),
                                              _buildLegendRow(context, const Color(0xFF00B2FF), 'Strategy', strategyPoints, totalPoints),
                                              const SizedBox(height: 8),
                                              _buildLegendRow(context, const Color(0xFFFFD600), 'Quests', questPoints, totalPoints),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 32),
                                    _buildStabilityGauge(context, 'Processing Fidelity', 0.92),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              _buildMindJournalCard(context),
                              const SizedBox(height: 20),
                              _buildMoodTelemetry(context, personId),
                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildMoodTelemetry(BuildContext context, String personId) {
    final mindBlock = context.read<MindBlock>();
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<List<MindLogData>>(
      stream: mindBlock.watchMindLogsByDay(personId, DateTime.now()),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        if (logs.isEmpty) return const SizedBox.shrink();

        final recentLog = logs.first;
        final moodValue = recentLog.moodScore.toDouble();
        
        return _buildGlassCard(
          context,
          title: 'COGNITIVE VITALITY',
          icon: Icons.monitor_heart_rounded,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getMoodEmoji(recentLog.moodScore),
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CURRENT COGNITIVE POLARITY',
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          _getMoodLabel(recentLog.moodScore).toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildStabilityGauge(context, 'Stability Deviation', moodValue / 5.0),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: (jsonDecode(recentLog.activities) as List)
                        .map((a) => Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                a.toString().toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ))
                        .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMoodEmoji(int score) {
    switch (score) {
      case 1: return '😫';
      case 2: return '😔';
      case 3: return '😐';
      case 4: return '😊';
      case 5: return '🔥';
      default: return '😐';
    }
  }

  String _getMoodLabel(int score) {
    switch (score) {
      case 1: return 'Critically Low';
      case 2: return 'Below Nominal';
      case 3: return 'Stable';
      case 4: return 'Optimal';
      case 5: return 'Peak Performance';
      default: return 'Neutral';
    }
  }

  Widget _buildStabilityGauge(BuildContext context, String label, double value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.4),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                color: colorScheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                fontFamily: 'Monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(colorScheme.primary),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildAmbientGlow(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: size / 2,
            spreadRadius: size / 4,
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard(BuildContext context, {required String title, required IconData icon, required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: colorScheme.onSurface.withOpacity(0.5), size: 14),
                  const SizedBox(width: 8),
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              child,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTacticalMetric(BuildContext context, String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: color.withOpacity(0.7),
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(BuildContext context, Color color, String label, double points, double total) {
    final percent = total > 0 ? (points / total * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Text(
          '$percent%',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            fontFamily: 'Monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildMindJournalCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: colorScheme.primary.withOpacity(0.2),
              width: 1.5,
            ),
          ),
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
                            Icon(Icons.history_edu_rounded, color: colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'MIND JOURNAL',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ],
                        ),
                        Icon(Icons.arrow_forward_ios_rounded, color: colorScheme.primary.withOpacity(0.5), size: 14),
                      ],
                    ),
                    const SizedBox(height: 16),
                    StreamBuilder<List<ProjectNoteData>>(
                      stream: context.read<ProjectNoteDAO>().watchRecentNotes(personId, 1),
                      builder: (context, snapshot) {
                        final note = snapshot.hasData && snapshot.data!.isNotEmpty ? snapshot.data!.first : null;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note?.title ?? 'START YOUR MIND JOURNAL',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              note != null ? _getPreviewText(note.content) : 'Record mental strategies and emotional milestones.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                fontSize: 13,
                                height: 1.4,
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
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .where((op) => op is Map && op.containsKey('insert'))
            .map((op) => op['insert'])
            .join('')
            .trim();
      }
    } catch (_) {}
    return content.trim();
  }
}

