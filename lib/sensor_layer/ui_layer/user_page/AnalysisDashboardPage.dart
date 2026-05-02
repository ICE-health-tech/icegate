import 'package:flutter/material.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/AnalysisCharts.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';

class AnalysisDashboardPage extends StatefulWidget {
  final String? personId;
  const AnalysisDashboardPage({super.key, this.personId});

  static Widget icon(BuildContext context, {double size = 56.0}) {
    return MainButton(
      type: "profile",
      icon: Icons.insert_chart_outlined_rounded,
      destination: "/profile",
      size: size,
      mainFunction: () {
        // context.push("/profile");
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
    );
  }

  @override
  State<AnalysisDashboardPage> createState() => _AnalysisDashboardPageState();
}

class _AnalysisDashboardPageState extends State<AnalysisDashboardPage> {
  ScoreBlock? _viewedScoreBlock;
  bool _isOther = false;

  @override
  void initState() {
    super.initState();
    _checkAndInitOther();
  }

  @override
  void didUpdateWidget(AnalysisDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.personId != oldWidget.personId) {
      _checkAndInitOther();
    }
  }

  @override
  void dispose() {
    _viewedScoreBlock?.dispose();
    super.dispose();
  }

  void _checkAndInitOther() {
    final personBlock = context.read<PersonBlock>();
    final currentId = personBlock.information.value.profiles.id;

    if (widget.personId != null && widget.personId != currentId) {
      _isOther = true;
      personBlock.fetchPersonById(widget.personId!);

      // Initialize a temporary ScoreBlock for the viewed user
      _viewedScoreBlock?.dispose();
      _viewedScoreBlock = ScoreBlock();

      final db = context.read<AppDatabase>();

      _viewedScoreBlock!.init(
        db.scoreDAO,
        db.financeDAO,
        db.healthMealDAO,
        db.metricsDAO,
        db.projectNoteDAO,
        widget.personId!,
      );
    } else {
      _isOther = false;
      _viewedScoreBlock?.dispose();
      _viewedScoreBlock = null;
      personBlock.viewedInformation.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final personBlock = context.watch<PersonBlock>();
    final mainScoreBlock = context.watch<ScoreBlock>();

    // Use the viewed score block if it exists, otherwise use the global one
    final activeScoreBlock = _viewedScoreBlock ?? mainScoreBlock;

    // Use the viewed information if it exists, otherwise use the global one
    final activeInfo = _isOther
        ? personBlock.viewedInformation.watch(context) ??
              personBlock.information.value
        : personBlock.information.watch(context);

    // If we're waiting for 'other' data to load (and it's not the guest fallback)
    if (_isOther && personBlock.viewedInformation.value == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      key: ValueKey(widget.personId),
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => WidgetNavigatorAction.smartPop(context),
        ),
        title: _isOther
            ? Text(
                AppLocalizations.of(
                  context,
                )!.analysis_user_title(activeInfo.profiles.firstName),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              )
            : null,
        actions: [
          // IconButton(
          //   icon: const Icon(Icons.settings_rounded, color: Colors.white70),
          //   onPressed: () => context.push("/personal-info"),
          //   style: IconButton.styleFrom(
          //     backgroundColor: Colors.white.withOpacity(0.05),
          //   ),
          // ),
          // const SizedBox(width: 12),
          // Padding(
          //   padding: const EdgeInsets.only(right: 16.0),
          //   child: Icon(Icons.auto_graph_rounded, color: colorScheme.primary),
          // ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- GUEST BANNER (Only for self) ---
            if (!_isOther &&
                context.watch<AuthBlock>().username.value == 'Guest')
              _buildGuestBanner(colorScheme, context),

            // --- TITLE ---
            Text(
              _isOther
                  ? AppLocalizations.of(context)!.performance
                  : AppLocalizations.of(context)!.overview,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),

            // --- MINI PROFILE (For others) ---
            if (_isOther) ...[
              _buildMiniProfile(activeInfo, colorScheme),
              const SizedBox(height: 24),
            ],

            // --- SECTOR GRID ---
            _buildSectorGrid(context, activeScoreBlock),
            const SizedBox(height: 32),

            // --- BALANCE CHART ---
            _buildBalanceSection(context, activeScoreBlock),
            const SizedBox(height: 32),

            // --- USAGE HISTORY ---
            Watch((signalsContext) {
              final history =
                  activeScoreBlock.usageHistory.watch(signalsContext);
              if (history.isEmpty) return const SizedBox.shrink();
              return _buildUsageHistory(context, history);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniProfile(UserInformation info, ColorScheme colorScheme) {
    return Row(
      children: [
        LocalFirstImage(
          ownerId: info.profiles.id,
          localPath: info.profiles.avatarLocalPath,
          remoteUrl: info.profiles.profileImageUrl,
          width: 40,
          height: 40,
          borderRadius: BorderRadius.circular(20),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "${info.profiles.firstName} ${info.profiles.lastName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              info.details.occupation,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGuestBanner(ColorScheme colorScheme, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.primary.withOpacity(0.1),
              colorScheme.tertiary.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.cloud_off_rounded, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.guest_mode,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.sync_desc,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: () => context.push('/login'),
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(AppLocalizations.of(context)!.sync),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSectorGrid(BuildContext context, ScoreBlock scoreBlock) {
    final score = scoreBlock.score;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.85, // Adjusted for breakdown text
      children: [
        _buildSectorCard(
          context,
          title: AppLocalizations.of(context)!.scoring_health.toUpperCase(),
          value: score.healthGlobalScore.toInt().toString(),
          icon: Icons.favorite_rounded,
          color: Colors.green,
          onTap: () => context.push('/health/dashboard'),
        ),
        _buildSectorCard(
          context,
          title: AppLocalizations.of(context)!.scoring_finance.toUpperCase(),
          value: score.financialGlobalScore.toInt().toString(),
          icon: Icons.account_balance_wallet_rounded,
          color: Colors.blue,
          onTap: () => context.push('/finance/dashboard'),
        ),
        _buildSectorCard(
          context,
          title: AppLocalizations.of(context)!.scoring_social.toUpperCase(),
          value: score.socialGlobalScore.toInt().toString(),
          icon: Icons.psychology_rounded,
          color: Colors.purple,
          onTap: () => context.push('/social/dashboard'),
        ),
        _buildSectorCard(
          context,
          title: AppLocalizations.of(context)!.scoring_career.toUpperCase(),
          value: score.careerGlobalScore.toInt().toString(),
          icon: Icons.rocket_launch_rounded,
          color: Colors.orange,
          onTap: () => context.push('/projects/dashboard'),
        ),
      ],
    );
  }

  Widget _buildSectorCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;


    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceSection(BuildContext context, ScoreBlock scoreBlock) {
    final score = scoreBlock.score;
    final distributionData = {
      'Health': score.healthGlobalScore,
      'Finance': score.financialGlobalScore,
      'Social': score.socialGlobalScore,
      'Projects': score.careerGlobalScore,
    };

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colorScheme.outline.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.score_balance,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              SimplePieChart(
                data: distributionData,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.purple,
                  Colors.orange,
                ],
                size: 120,
              ),
              const SizedBox(width: 32),
              Expanded(
                child: Column(
                  children: distributionData.entries.map((e) {
                    final percent =
                        (e.value /
                                distributionData.values.fold(
                                  0.1,
                                  (sum, val) => sum + val,
                                ) *
                                100)
                            .toInt();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: _getColorForSector(e.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _getLocalizedSectorTitle(context, e.key),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "$percent%",
                            style: TextStyle(
                              fontSize: 13,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForSector(String sector) {
    switch (sector) {
      case 'Health':
        return Colors.green;
      case 'Finance':
        return Colors.blue;
      case 'Social':
        return Colors.purple;
      case 'Projects':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _getLocalizedSectorTitle(BuildContext context, String sector) {
    final l10n = AppLocalizations.of(context)!;
    switch (sector) {
      case 'Health':
        return l10n.scoring_health;
      case 'Finance':
        return l10n.scoring_finance;
      case 'Social':
        return l10n.scoring_social;
      case 'Projects':
        return l10n.scoring_career;
      default:
        return sector;
    }
  }

  String _formatScreenTime(double minutes) {
    if (minutes <= 0) return "0m";
    final h = (minutes / 60).floor();
    final m = (minutes % 60).round();
    if (h > 0) {
      return "${h}h ${m}m";
    }
    return "${m}m";
  }

  Widget _buildUsageHistory(
      BuildContext context, List<AppUsageHistoryData> history) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Group by date
    final grouped = <DateTime, List<AppUsageHistoryData>>{};
    for (var item in history) {
      final date = DateTime(item.date.year, item.date.month, item.date.day);
      grouped.putIfAbsent(date, () => []).add(item);
    }

    final sortedDates = grouped.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.breakdown_screentime.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 16),
        ...sortedDates.map((date) {
          final items = grouped[date]!;
          final isToday = DateTime.now().year == date.year &&
              DateTime.now().month == date.month &&
              DateTime.now().day == date.day;

          final dateLabel = isToday
              ? l10n.date_today
              : "${date.day}/${date.month}/${date.year}";

          return Padding(
            padding: const EdgeInsets.only(bottom: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _formatScreenTime(items.fold(
                          0.0, (sum, item) => sum + item.durationMinutes)),
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: items.map((item) {
                      return ListTile(
                        dense: true,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _getColorForSector(item.sector)
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getSectorIcon(item.sector),
                            size: 16,
                            color: _getColorForSector(item.sector),
                          ),
                        ),
                        title: Text(
                          (item.pagePath == null || item.pagePath == '/')
                              ? l10n.home_welcome.toUpperCase()
                              : item.pagePath!.split('/').last.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          item.pagePath ?? item.sector,
                          style: const TextStyle(fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          _formatScreenTime(item.durationMinutes),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  IconData _getSectorIcon(String sector) {
    switch (sector.toLowerCase()) {
      case 'health':
        return Icons.favorite_rounded;
      case 'finance':
        return Icons.account_balance_wallet_rounded;
      case 'social':
        return Icons.psychology_rounded;
      case 'projects':
        return Icons.work_rounded;
      default:
        return Icons.apps_rounded;
    }
  }
}
