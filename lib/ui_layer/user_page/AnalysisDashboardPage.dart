import 'package:flutter/material.dart';
import 'package:ice_gate/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/AnalysisCharts.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
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
      final healthBlock = context.read<HealthBlock>();

      _viewedScoreBlock!.init(
        db.scoreDAO,
        db.personManagementDAO,
        db.financeDAO,
        healthBlock,
        db.healthMealDAO,
        db.metricsDAO,
        db.projectNoteDAO,
        widget.personId!,
        tenantID: personBlock.viewedInformation.value?.profiles.tenantId,
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

  Widget _buildHeroSection(
    BuildContext context,
    int level,
    String rank,
    double progress,
    double totalXP,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.primary.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LEVEL $level",
                    style: TextStyle(
                      color: colorScheme.onPrimary.withOpacity(0.7),
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    rank,
                    style: TextStyle(
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.onPrimary.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colorScheme.onPrimary,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: colorScheme.onPrimary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(
                  context,
                )!.percent_to_level((progress * 100).toInt(), level + 1),
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                AppLocalizations.of(context)!.total_xp(totalXP.toInt()),
                style: TextStyle(
                  color: colorScheme.onPrimary.withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
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
        Watch(
          (signalsContext) => _buildSectorCard(
            context,
            title: AppLocalizations.of(context)!.scoring_health.toUpperCase(),
            value: score.healthGlobalScore.toInt().toString(),
            icon: Icons.favorite_rounded,
            color: Colors.green,
            breakdown: scoreBlock.healthBreakdown.watch(signalsContext),
            onTap: () => context.push('/health/dashboard'),
          ),
        ),
        Watch(
          (signalsContext) => _buildSectorCard(
            context,
            title: AppLocalizations.of(context)!.scoring_finance.toUpperCase(),
            value: score.financialGlobalScore.toInt().toString(),
            icon: Icons.account_balance_wallet_rounded,
            color: Colors.blue,
            breakdown: scoreBlock.financeBreakdown.watch(signalsContext),
            onTap: () => context.push('/finance/dashboard'),
          ),
        ),
        Watch(
          (signalsContext) => _buildSectorCard(
            context,
            title: AppLocalizations.of(context)!.scoring_social.toUpperCase(),
            value: score.socialGlobalScore.toInt().toString(),
            icon: Icons.psychology_rounded,
            color: Colors.purple,
            breakdown: scoreBlock.socialBreakdown.watch(signalsContext),
            onTap: () => context.push('/social/dashboard'),
          ),
        ),
        Watch(
          (signalsContext) => _buildSectorCard(
            context,
            title: AppLocalizations.of(context)!.scoring_career.toUpperCase(),
            value: score.careerGlobalScore.toInt().toString(),
            icon: Icons.rocket_launch_rounded,
            color: Colors.orange,
            breakdown: scoreBlock.projectsBreakdown.watch(signalsContext),
            onTap: () => context.push('/projects/dashboard'),
          ),
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
    required Map<String, double> breakdown,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Fallback for non-zero scores with empty breakdowns (e.g. at startup)
    final displayBreakdown = Map<String, double>.from(breakdown);
    if (displayBreakdown.isEmpty && (double.tryParse(value) ?? 0) > 0) {
      displayBreakdown['Base'] = double.tryParse(value) ?? 0;
    }

    IconData getBreakdownIcon(String key) {
      switch (key.toLowerCase()) {
        case 'steps':
          return Icons.directions_walk_rounded;
        case 'diet':
          return Icons.restaurant_rounded;
        case 'exercise':
          return Icons.fitness_center_rounded;
        case 'focus':
          return Icons.timer_rounded;
        case 'water':
          return Icons.water_drop_rounded;
        case 'sleep':
          return Icons.bedtime_rounded;
        case 'contacts':
          return Icons.person_rounded;
        case 'affection':
          return Icons.favorite_rounded;
        case 'quests':
          return Icons.auto_awesome_rounded;
        case 'accounts':
          return Icons.savings_rounded;
        case 'assets':
          return Icons.inventory_2_rounded;
        case 'tasks':
          return Icons.task_alt_rounded;
        case 'projects':
          return Icons.rocket_rounded;
        case 'system':
          return Icons.history_rounded;
        default:
          return Icons.adjust_rounded;
      }
    }

    String getLocalizedBreakdownTitle(String key) {
      final l10n = AppLocalizations.of(context)!;
      switch (key.toLowerCase()) {
        case 'steps':
          return l10n.breakdown_steps;
        case 'diet':
          return l10n.breakdown_diet;
        case 'exercise':
          return l10n.breakdown_exercise;
        case 'focus':
          return l10n.breakdown_focus;
        case 'water':
          return l10n.breakdown_water;
        case 'sleep':
          return l10n.breakdown_sleep;
        case 'contacts':
          return l10n.breakdown_contacts;
        case 'affection':
          return l10n.breakdown_affection;
        case 'quests':
          return l10n.breakdown_quests;
        case 'accounts':
          return l10n.breakdown_accounts;
        case 'assets':
          return l10n.breakdown_assets;
        case 'tasks':
          return l10n.breakdown_tasks;
        case 'projects':
          return l10n.breakdown_projects;
        case 'system':
          return l10n.breakdown_system;
        default:
          return key.toUpperCase();
      }
    }

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
            const Divider(height: 16, thickness: 0.5),
            ...displayBreakdown.entries
                .where((e) => e.value != 0)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3.0),
                    child: Row(
                      children: [
                        Icon(
                          getBreakdownIcon(e.key),
                          size: 10,
                          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            getLocalizedBreakdownTitle(e.key),
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.4,
                              color: colorScheme.onSurfaceVariant.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          e.value > 0
                              ? "+${e.value.toInt()}"
                              : e.value.toInt().toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: e.value > 0 ? color : Colors.red,
                          ),
                        ),
                      ],
                    ),
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
}
