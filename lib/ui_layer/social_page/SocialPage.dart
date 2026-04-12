import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

import 'package:ice_gate/ui_layer/social_page/SocialNotesDashboard.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/AchievementBuilderDialog.dart';

import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/AchievementTimeline.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/DomainAnalysisChart.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/SocialBlock.dart';

import 'package:signals_flutter/signals_flutter.dart';
import 'package:live_activities/live_activities.dart';
import 'package:flutter/foundation.dart';

import 'package:ice_gate/ui_layer/social_page/SocialAnalysisPage.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  static Widget icon(BuildContext context, {double? size}) {
    return Watch((context) {
      final socialBlock = context.read<SocialBlock>();
      final index = socialBlock.activeTab.value;
      IconData iconData;
      VoidCallback action;
      print("social index: $index");
      // 3 tabs: 0=Journal, 1=Achievements, 2=Analysis
      switch (index) {
        case 0: // Journal
          iconData = Icons.edit_note_rounded;
          action = () => context.push('/projects/editor', extra: {
                'category': 'social',
              });
          break;
        case 1: // Achievements
          iconData = Icons.spa_rounded;
          action = () => AchievementBuilderDialog.show(context);
          break;
        case 2: // Analysis
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
      length: 3, // Journal, Achievements, Analysis
      vsync: this,
      // Clamp to valid range in case signal was saved from old 4-tab layout
      initialIndex: _socialBlock.activeTab.peek().clamp(0, 2),
    );

    // Sync signal -> tab
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      final newIndex = _tabController.index;
      if (_socialBlock.activeTab.peek() != newIndex) {
        print("🔄 [TAB -> SIGNAL] Syncing index: $newIndex");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            untracked(() {
              _socialBlock.activeTab.value = newIndex;
            });
          }
        });
      }
    });

    // Sync tab -> signal (for external updates like Dynamic Island)
    _disposeEffect = effect(() {
      final rawIndex = _socialBlock.activeTab.value;
      // Clamp to valid range to prevent out-of-bounds animation
      final index = rawIndex.clamp(0, 2);
      print("🔄 [SIGNAL -> TAB] Checking sync for index: $index");

      // Update Live Activity / Dynamic Island
      if (mounted) {
        _updateLiveActivity(context, index);
      }

      if (_tabController.index != index) {
        print("🔄 [SIGNAL -> TAB] Animating TabController to: $index");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _tabController.index != index) {
            _tabController.animateTo(index);
          }
        });
      }
    });

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      _setupLiveActivity();
    }
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
      _activityId = await _liveActivities.createActivity(
        'group.duylong.art.iceshield',
        {
          'title': l10n.social_dashboard,
          'songName': _getTabName(context, _tabController.index),
          'artist': "ICE GATE",
          'cover': "social_cover",
          'progress': 0.0,
        },
      );
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
        print("✅ [SOCIAL] Dynamic Island Updated to: ${_getTabName(context, index)}");
      } catch (e) {
        debugPrint("Social Live Activity Update Error: $e");
      }
    }
  }

  // Returns the tab name for the Dynamic Island display
  String _getTabName(BuildContext context, int index) {
    final l10n = AppLocalizations.of(context)!;
    switch (index) {
      case 0:
        return l10n.journal;
      case 1:
        return l10n.achievements;
      case 2:
        return "ANALYSIS"; // Placeholder for L10n
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
    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          toolbarHeight: 80, // We use a custom header (CanvasDynamicIsland)
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            // const SizedBox(height: 16),
            // TabBar is now removed, navigation is handled by Dynamic Island
            Expanded(
              child: Watch((context) {
                // Accessing activeTab.value ensures this widget rebuilds when the signal changes
                final _ = _socialBlock.activeTab.value;
                return TabBarView(
                  controller: _tabController,
                  children: [
                    const SocialNotesDashboard(),
                    _buildAchievementsDashboard(context),
                    const SocialAnalysisPage(),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
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
              color: colorScheme.primary.withOpacity(0.05),
              shape: BoxShape.circle,
              border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
            ),
            child: Icon(
              icon,
              size: 48,
              color: colorScheme.primary.withOpacity(0.5),
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
      final personBlock = context.read<PersonBlock>();
      final currentPersonId = personBlock.currentPersonID.value ?? "";

      return StreamBuilder<List<AchievementData>>(
        stream: achievementsDAO.watchAchievementsByPerson(currentPersonId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final achievements = snapshot.data!;

          if (achievements.isEmpty) {
            return _buildEmptyState(
              context,
              "No achievements logged yet. Log a win to start reflection.",
              Icons.emoji_events_outlined,
            );
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: DomainAnalysisChart(achievements: achievements),
              ),
              const SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),
              SliverToBoxAdapter(
                child: AchievementTimeline(achievements: achievements),
              ),
            ],
          );
        },
      );
    });
  }
}
