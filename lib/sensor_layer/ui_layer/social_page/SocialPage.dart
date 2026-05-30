import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindFocusTrendsTab.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindFocusTrendEditor.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindLogEntryDialog.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryRail.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/achievement_story_utils.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementTimeline.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/DomainAnalysisChart.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/SwipeablePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:live_activities/live_activities.dart';
import 'package:flutter/foundation.dart';

import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindFocusTheme.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SocialAnalysisPage.dart';
import 'package:ice_gate/utils/app_log.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return Watch((context) {
      final socialBlock = context.read<SocialBlock>();
      final index = socialBlock.activeTab.value;
      IconData iconData;
      VoidCallback action;
      appLog("social index: $index");
      // 4 tabs: 0=Journal, 1=Focus, 2=Achievements, 3=Analysis
      switch (index) {
        case 0: // Journal
          iconData = Icons.sentiment_satisfied_rounded;
          action = () => MindLogEntryDialog.show(context);
          break;
        case 1: // Focus trends
          iconData = Icons.center_focus_strong_rounded;
          action = () async {
            final personId =
                context.read<PersonBlock>().currentPersonID.value ?? '';
            if (personId.isEmpty) return;
            await MindFocusTrendEditor.show(
              context,
              onSave: (trend) async {
                final list = await MindFocusTrendPrefs.load(personId);
                list.add(trend);
                await MindFocusTrendPrefs.save(personId, list);
                context.read<SocialBlock>().notifyFocusTrendsChanged();
              },
            );
          };
          break;
        case 2: // Achievements
          iconData = Icons.emoji_events_outlined;
          action = () => AchievementBuilderDialog.show(context);
          break;
        case 3: // Analysis
          iconData = Icons.bar_chart_rounded;
          action = () {
            // Placeholder for analysis action or navigation
          };
          break;
        default:
          iconData = Icons.psychology_outlined;
          action = () => context.go("/");
      }

      return MainButton(
        type: "social",
        destination: "/social",
        mainFunction: action,
        onSwipeUp: () {
          WidgetNavigatorAction.smartPop(context);
        },
        onSwipeRight: () {
          WidgetNavigatorAction.smartPop(context);
        },
        onLongPress: () {
          context.go("/social/dashboard");
        },
        onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
        size: size,
        icon: iconData,
        subButtons: [],
      );
    });
  }

  // The old showAddFeatDialog was removed and replaced by AchievementBuilderDialog

  static InputDecoration buildInputDecoration(
    BuildContext context,
    String label,
  ) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        fontSize: 14,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
      ),
      filled: true,
      fillColor: Theme.of(context).colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _liveActivities = LiveActivities();
  String? _activityId;
  void Function()? _disposeEffect;
  late SocialBlock _socialBlock;

  @override
  void initState() {
    super.initState();
    _socialBlock = context.read<SocialBlock>();
    _tabController = TabController(
      length: 4, // Journal, Focus, Achievements, Analysis
      vsync: this,
      initialIndex: _socialBlock.activeTab.peek().clamp(0, 3),
    );

    // Sync signal -> tab
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_socialBlock.activeTab.peek() != newIndex) {
        // Use microtask to break out of synchronous feedback loop (effect -> animateTo -> listener -> signal update)
        Future.microtask(() {
          if (!mounted) return;
          untracked(() {
            _socialBlock.activeTab.value = newIndex;
          });
        });
      }
    });

    // Sync tab -> signal (for external updates like Dynamic Island)
    _disposeEffect = effect(() {
      final rawIndex = _socialBlock.activeTab.value;
      // Clamp to valid range to prevent out-of-bounds animation
      final index = rawIndex.clamp(0, 3);

      // Update Live Activity / Dynamic Island
      if (mounted) {
        _updateLiveActivity(context, index);
      }

      if (_tabController.index != index) {
        if (mounted && _tabController.index != index) {
          _tabController.animateTo(index);
        }
      }
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _setupLiveActivity();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreActiveFocus());
  }

  Future<void> _restoreActiveFocus() async {
    if (!mounted) return;
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;
    await _socialBlock.restoreActiveFocus(personId);
  }

  Future<void> _setupLiveActivity() async {
    try {
      await _liveActivities.init(appGroupId: 'group.duylong.art.iceshield');
      await _createLiveActivity();
    } catch (e) {
      debugPrint("Social Live Activity Setup Error: $e");
    }
  }

  Future<void> _createLiveActivity() async {
    try {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      _activityId = await _liveActivities
          .createActivity('group.duylong.art.iceshield', {
            'title': l10n.social_dashboard,
            'songName': _getTabName(context, _tabController.index),
            'artist': "ICE GATE",
            'cover': "social_cover",
            'progress': 0.0,
          });
    } catch (e) {
      debugPrint("Social Live Activity Creation Error: $e");
    }
  }

  void _updateLiveActivity(BuildContext context, int index) {
    if (_activityId != null) {
      try {
        final l10n = AppLocalizations.of(context)!;
        _liveActivities.updateActivity(_activityId!, {
          'title': l10n.social_dashboard,
          'songName': _getTabName(context, index),
          'artist': "ICE GATE",
          'cover': "social_cover",
          'progress': 0.0,
        });
        appLog(
          "✅ [SOCIAL] Dynamic Island Updated to: ${_getTabName(context, index)}",
        );
      } catch (e) {
        debugPrint("Social Live Activity Update Error: $e");
      }
    }
  }

  // Returns the tab name for the Dynamic Island display
  String _getTabName(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    final focus = _socialBlock.activeFocusTrend.peek();
    if (focus != null) return focus.name;
    switch (index) {
      case 0:
        return l10n.journal;
      case 1:
        return l10n.mind_focus_title.toUpperCase();
      case 2:
        return l10n.achievements;
      case 3:
        return AppLocalizations.of(context)!.analysis.toUpperCase();
      default:
        return l10n.social;
    }
  }

  @override
  void dispose() {
    if (_activityId != null) {
      _liveActivities.endActivity(_activityId!);
    }
    _disposeEffect?.call();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final focus = _socialBlock.activeFocusTrend.value;
      final baseTheme = Theme.of(context);
      final pageTheme = mindFocusThemed(baseTheme, focus);

      final colorScheme = pageTheme.colorScheme;

      return Theme(
        data: pageTheme,
        child: SwipeablePage(
          onSwipe: () => Navigator.maybePop(context),
          direction: SwipeablePageDirection.leftToRight,
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              toolbarHeight: 80,
              backgroundColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
            ),
            body: Column(
              children: [
                Expanded(
                  child: Watch((context) {
                    final _ = _socialBlock.activeTab.value;

                    return Stack(
                      children: [
                        TabBarView(
                          controller: _tabController,
                          children: [
                            const SocialNotesDashboard(),
                            const MindFocusTrendsTab(),
                            _buildAchievementsDashboard(context),
                            const SocialAnalysisPage(),
                          ],
                        ),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildEmptyState(BuildContext context, String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(
                color: colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsDashboard(BuildContext context) {
    return Watch((context) {
      final achievementsDAO = context.read<AchievementsDAO>();
      final mindBlock = context.read<MindBlock>();
      final personBlock = context.read<PersonBlock>();
      final currentPersonId = personBlock.currentPersonID.value ?? "";

      return StreamBuilder<List<AchievementData>>(
        stream: achievementsDAO.watchAchievementsByPerson(currentPersonId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final achievements = snapshot.data!;
          final feats = achievementLoggedFeats(achievements);
          final l10n = AppLocalizations.of(context)!;

          return StreamBuilder<List<MindLogData>>(
            stream: mindBlock.watchMindLogsRange(currentPersonId, 60),
            builder: (context, logSnap) {
              final mindLogs = logSnap.data ?? [];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: AchievementStoryRail.recordColumnFlex,
                    child: CustomScrollView(
                      physics: const BouncingScrollPhysics(),
                      slivers: [
                        const SliverToBoxAdapter(child: SizedBox(height: 4)),
                        if (feats.isEmpty && achievements.isEmpty && mindLogs.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _buildEmptyState(
                              context,
                              l10n.social_no_achievements_msg,
                              Icons.emoji_events_outlined,
                            ),
                          )
                        else ...[
                          if (feats.isNotEmpty ||
                              countSkillSessionsInRange(mindLogs) > 0) ...[
                            SliverToBoxAdapter(
                              child: DomainAnalysisChart(
                                achievements: feats,
                                mindLogs: mindLogs,
                              ),
                            ),
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 10, 12, 2),
                            child: Text(
                              l10n.achievement_feats_section.toUpperCase(),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                letterSpacing: 1.1,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: AchievementTimeline(achievements: feats),
                        ),
                      ] else
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 24, 12, 8),
                            child: Text(
                              l10n.social_no_achievements_msg,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      const SliverToBoxAdapter(child: SizedBox(height: 96)),
                    ],
                  ],
                ),
              ),
              Expanded(
                flex: AchievementStoryRail.imageColumnFlex,
                child: AchievementStoryRail(achievements: achievements),
              ),
            ],
          );
            },
          );
        },
      );
    });
  }
}
