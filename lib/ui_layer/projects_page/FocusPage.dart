import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:file_picker/file_picker.dart';

import 'package:flutter/material.dart';
import 'package:ice_shield/ui_layer/UIConstants.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_shield/initial_layer/Notification/NotificationInit.dart';

class TimerThemeInfo {
  final String name;
  final Color color;
  final IconData icon;
  final String soundAsset; // e.g. 'sounds/ocean.mp3'

  const TimerThemeInfo(
    this.name,
    this.color,
    this.icon, {
    this.soundAsset = 'sounds/white_noise.mp3',
  });
}

final timerThemes = [
  TimerThemeInfo(
    'Default',
    Colors.blue,
    Icons.water_drop_rounded,
    soundAsset: 'sounds/rain.mp3',
  ),
  // Nature
  TimerThemeInfo(
    'Emerald Haven',
    const Color(0xFF2E8B57),
    Icons.landscape_rounded,
    soundAsset: 'sounds/forest_stream.mp3',
  ),
  TimerThemeInfo(
    'Emerald Forest',
    const Color(0xFF006350),
    Icons.forest_rounded,
    soundAsset: 'sounds/birds.mp3',
  ),
  TimerThemeInfo(
    'Sakura Zen',
    const Color(0xFFFFB7C5),
    Icons.local_florist_rounded,
    soundAsset: 'sounds/zen_garden.mp3',
  ),
  // Elements
  TimerThemeInfo(
    'Deep Sea',
    const Color(0xFF00008B),
    Icons.scuba_diving_rounded,
    soundAsset: 'sounds/ocean_waves.mp3',
  ),
  TimerThemeInfo(
    'Frosty Morning',
    const Color(0xFFE0FFFF),
    Icons.ac_unit_rounded,
    soundAsset: 'sounds/snow_wind.mp3',
  ),
  TimerThemeInfo(
    'Sunset',
    Colors.orange,
    Icons.wb_twilight_rounded,
    soundAsset: 'sounds/crickets.mp3',
  ),
  // Vibe
  TimerThemeInfo(
    'Cyberpunk 2077',
    const Color(0xFFFCEE0A),
    Icons.bolt_rounded,
    soundAsset: 'sounds/cyber_ambience.mp3',
  ),
  TimerThemeInfo(
    'Nordic Night',
    const Color(0xFF191970),
    Icons.nights_stay_rounded,
    soundAsset: 'sounds/campfire.mp3',
  ),
  TimerThemeInfo(
    'Royal Velvet',
    const Color(0xFF800080),
    Icons.diamond_rounded,
    soundAsset: 'sounds/lofi.mp3',
  ),
  TimerThemeInfo(
    'Midnight Gold',
    const Color(0xFFFFD700),
    Icons.star_rounded,
    soundAsset: 'sounds/space_drone.mp3',
  ),
  // Colors
  TimerThemeInfo(
    'Light Purple',
    const Color(0xFFE6E6FA),
    Icons.bubble_chart_rounded,
    soundAsset: 'sounds/bubbles.mp3',
  ),
  TimerThemeInfo(
    'Purple Seed',
    const Color(0xFF8A2BE2),
    Icons.grain_rounded,
    soundAsset: 'sounds/white_noise.mp3',
  ),
  TimerThemeInfo(
    'Nebula',
    Colors.purpleAccent,
    Icons.auto_awesome_rounded,
    soundAsset: 'sounds/nebula_hum.mp3',
  ),
  TimerThemeInfo(
    'Cherry',
    Colors.redAccent,
    Icons.local_fire_department_rounded,
    soundAsset: 'sounds/fire_crackle.mp3',
  ),
  TimerThemeInfo(
    'Volcano',
    const Color(0xFFFF4500),
    Icons.volcano_rounded,
    soundAsset: 'sounds/lava_flow.mp3',
  ),
  TimerThemeInfo(
    'Ocean Deep',
    const Color(0xFF008080),
    Icons.waves_rounded,
    soundAsset: 'sounds/deep_ocean.mp3',
  ),
  TimerThemeInfo(
    'Cyberpunk Pink',
    const Color(0xFFFF00FF),
    Icons.flash_on_rounded,
    soundAsset: 'sounds/synthwave.mp3',
  ),
  TimerThemeInfo(
    'Enchanted Forest',
    const Color(0xFF32CD32),
    Icons.nature_people_rounded,
    soundAsset: 'sounds/magic_forest.mp3',
  ),
];

class FocusPage extends StatefulWidget {
  const FocusPage({super.key});

  @override
  State<FocusPage> createState() => _FocusPageState();
}

class _FocusPageState extends State<FocusPage> {
  StreamSubscription? _audioSubscription;
  bool _hasSetupListeners = false;

  @override
  void initState() {
    super.initState();
    // Sync logic has been moved to FocusBlock and FocusAudioHandler
    // to prevent infinite loops and state fighting.
  }

  @override
  void dispose() {
    _audioSubscription?.cancel();
    _summaryEffectDispose?.call();
    super.dispose();
  }

  void _setupSummaryEffect(FocusBlock focusBlock) {
    if (_summaryEffectDispose != null) return;
    _summaryEffectDispose = effect(() {
      if (focusBlock.showSummary.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showSessionSummary(context, focusBlock);
          }
        });
      }
    });
  }

  void Function()? _summaryEffectDispose;

  String formatTime(int totalSeconds) {
    int minutes = totalSeconds ~/ 60;
    int seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _showSessionSummary(BuildContext context, FocusBlock focusBlock) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _SessionResultDialog(focusBlock: focusBlock),
    );
  }

  // Effect to listen for changes
  void _setupNotificationListener(BuildContext context, FocusBlock focusBlock) {
    if (_hasSetupListeners) return;
    _hasSetupListeners = true;

    final notificationService = context.read<LocalNotificationService>();

    effect(() {
      final isRunning = focusBlock.isRunning.value;
      if (isRunning) {
        // notificationService.showNotification(99, "Focus Mode On", "Time to concentrate!");
        // We might not want to spam notifications on every resume, maybe just start.
      }
    });

    effect(() {
      final remaining = focusBlock.remainingTime.value;
      if (remaining == 0) {
        notificationService.showNotification(
          100,
          "Session Complete",
          "Great job! Take a break.",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final focusBlock = context.watch<FocusBlock>();
    final projectBlock = context.watch<ProjectBlock>();
    final growthBlock = context.watch<GrowthBlock>();

    _setupNotificationListener(context, focusBlock);
    _setupSummaryEffect(focusBlock);

    final focusMin = focusBlock.focusDuration.watch(context);
    final shortMin = focusBlock.shortBreakDuration.watch(context);
    final longMin = focusBlock.longBreakDuration.watch(context);

    final timeStr = formatTime(focusBlock.remainingTime.watch(context));
    final isRunning = focusBlock.isRunning.watch(context);
    final sessionType = focusBlock.currentSessionType.watch(context);
    final totalStudyTime = focusBlock.totalStudyTimeToday.watch(context);
    final sessionsCount = focusBlock.sessionsCompletedToday.watch(context);
    final themeName = focusBlock.timerTheme.watch(context);
    final isExerciseMode = focusBlock.isExerciseMode.watch(context);
    final exerciseType = focusBlock.exerciseType.watch(context);

    // Sync logic has been moved to FocusBlock and FocusAudioHandler
    // to prevent infinite loops and state fighting.

    // Get current theme
    final themeStyle = timerThemes.firstWhere(
      (t) => t.name == themeName,
      orElse: () => timerThemes.first,
    );

    // Dynamic Colors based on mode
    final modeColor = isExerciseMode
        ? Colors.orange
        : (sessionType == 'Focus' ? themeStyle.color : Colors.teal);
    final modeBg = isExerciseMode
        ? Colors.orange.withOpacity(0.1)
        : (sessionType == 'Focus'
              ? themeStyle.color.withOpacity(0.1)
              : Colors.teal.withOpacity(0.1));

    int totalDuration = focusMin * 60;
    if (sessionType == 'Short Break') totalDuration = shortMin * 60;
    if (sessionType == 'Long Break') totalDuration = longMin * 60;

    double progress = totalDuration > 0
        ? (totalDuration - focusBlock.remainingTime.value) / totalDuration
        : 1.0;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // 1. Dynamic Background
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colorScheme.surface, modeBg, colorScheme.surface],
              ),
            ),
          ),

          Positioned(
            top: -50,
            left: -50,
            child: _BlurCircle(color: modeColor.withOpacity(0.15), size: 350),
          ),
          Positioned(
            bottom: 100,
            right: -100,
            child: _BlurCircle(color: modeColor.withOpacity(0.1), size: 350),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        // Custom Back Button with Glassy feel
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 20,
                            ),
                            color: Theme.of(context).colorScheme.onSurface,
                            tooltip: "Back",
                          ),
                        ),

                        // Centered Title (Removed - integrated into DI elsewhere or hidden)
                        const Spacer(),

                        // Balance Space (matches back button size approx)
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Center(
                    child: _SessionTypeToggle(focusBlock: focusBlock),
                  ),
                ),
                // Minimal Selection Status (Text only)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: _ActiveSessionContext(
                      focusBlock: focusBlock,
                      projectBlock: projectBlock,
                      growthBlock: growthBlock,
                    ),
                  ),
                ),

                // Timer Main Component
                // const SizedBox(height: 40),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Spacer(),
                        _TimerCircle(
                          progress: progress,
                          timeStr: timeStr,
                          modeColor: modeColor,
                          sessionType: sessionType,
                          isRunning: isRunning,
                          focusBlock: focusBlock,
                          totalDuration: totalDuration,
                          themeName: themeName,
                          isExerciseMode: isExerciseMode,
                          exerciseType: exerciseType,
                        ),
                        const Spacer(),

                        // Detailed Controls Consolidated into Circle
                        const SizedBox(height: 30),

                        // Stats & History Preview
                        _StatsGrid(
                          sessionsCount: sessionsCount,
                          totalStudyTime: totalStudyTime,
                          modeColor: modeColor,
                        ),

                        const SizedBox(height: 24),

                        _RecentHistoryHeader(),
                        const SizedBox(
                          height: 24,
                        ), // Add bottom padding for balance
                      ],
                    ),
                  ),
                ),

                // History List
                StreamBuilder<List<FocusSessionData>>(
                  stream: context
                      .read<FocusSessionsDAO>()
                      .watchSessionsByPerson(focusBlock.currentPersonId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const SliverToBoxAdapter(child: SizedBox.shrink());
                    }
                    final sessions = snapshot.data!.reversed.take(5).toList();
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _HistoryItem(
                            session: sessions[index],
                            modeColor: modeColor,
                          ),
                          childCount: sessions.length,
                        ),
                      ),
                    );
                  },
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color.withOpacity(0.4),
            color.withOpacity(0.1),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class _TimerControls extends StatelessWidget {
  final FocusBlock focusBlock;
  final bool isRunning;
  final int totalDuration;
  final Color modeColor;

  const _TimerControls({
    required this.focusBlock,
    required this.isRunning,
    required this.totalDuration,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton.filled(
          onPressed: () => focusBlock.resetTimer(),
          icon: const Icon(Icons.refresh_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 24),
        IconButton.filled(
          onPressed: () => _showYoutubeDialog(context),
          icon: const Icon(Icons.music_video_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.all(12),
          ),
        ),
        const SizedBox(width: 24),
        IconButton.filled(
          onPressed: () => _showSettings(context),
          icon: const Icon(Icons.settings_suggest_rounded, size: 20),
          style: IconButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
            padding: const EdgeInsets.all(12),
          ),
        ),
      ],
    );
  }

  void _showYoutubeDialog(BuildContext context) {
    final controller = TextEditingController(text: focusBlock.youtubeUrl.value);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("YouTube Music"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Paste a YouTube link to play audio during your session.",
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "https://youtube.com/watch?v=...",
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              focusBlock.clearYoutube();
              Navigator.pop(context);
            },
            child: const Text("Clear"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                focusBlock.playYoutube(controller.text);
              }
              Navigator.pop(context);
            },
            child: const Text("Play"),
          ),
        ],
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TimerSettingsSheet(focusBlock: focusBlock),
    );
  }
}

class _SessionTypeToggle extends StatelessWidget {
  final FocusBlock focusBlock;
  const _SessionTypeToggle({required this.focusBlock});

  @override
  Widget build(BuildContext context) {
    final type = focusBlock.currentSessionType.watch(context);
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'Focus',
          icon: Icon(Icons.bolt, size: 16),
          label: Text('Focus'),
        ),
        ButtonSegment(
          value: 'Short Break',
          icon: Icon(Icons.coffee, size: 16),
          label: Text('Break'),
        ),
      ],
      selected: {type == 'Long Break' ? 'Short Break' : type},
      onSelectionChanged: (val) => focusBlock.setSessionType(val.first),
      showSelectedIcon: false,
      style: const ButtonStyle(
        visualDensity: VisualDensity.compact,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}

class _ActiveSessionContext extends StatelessWidget {
  final FocusBlock focusBlock;
  final ProjectBlock projectBlock;
  final GrowthBlock growthBlock;

  const _ActiveSessionContext({
    required this.focusBlock,
    required this.projectBlock,
    required this.growthBlock,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = focusBlock.isRunning.watch(context);
    final selectedProjId = focusBlock.selectedProjectId.watch(context);
    final selectedTaskId = focusBlock.selectedTaskId.watch(context);

    final projects = projectBlock.projects.watch(context);
    final selectedProject = projects
        .where((p) => p.projectID == selectedProjId)
        .firstOrNull;

    final tasks = growthBlock.goals
        .watch(context)
        .where((g) => g.projectID == selectedProjId && g.status != 'done')
        .toList();

    final selectedTask = tasks
        .where((t) => t.goalID == selectedTaskId)
        .firstOrNull;

    if (selectedProject == null) {
      return GestureDetector(
        onTap: () => _showProjectPicker(context, projects),
        child: Center(
          child: AnimatedScale(
            scale: isRunning ? 0.8 : 1.1,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "TAP TO SELECT PROJECT",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: isRunning ? 0.85 : 1.15,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: isRunning
                ? null
                : () => _showProjectPicker(context, projects),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedProject.color != null
                        ? Color(int.parse(selectedProject.color!))
                        : Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  selectedProject.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: isRunning ? 10 : 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (!isRunning) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.5),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: isRunning
                ? null
                : () => _showTaskPicker(context, tasks, selectedTaskId),
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedTask?.title ?? "SELECT TASK",
                  style: TextStyle(
                    fontSize: isRunning ? 12 : 16,
                    fontWeight: isRunning ? FontWeight.w500 : FontWeight.w700,
                    color: selectedTask != null
                        ? Theme.of(context).colorScheme.onSurface.withOpacity(
                            isRunning ? 0.5 : 0.8,
                          )
                        : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isRunning && selectedTask != null) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.3),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectPicker(BuildContext context, List<dynamic> projects) {
    final selectedProjId = focusBlock.selectedProjectId.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Choose Project",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final p = projects[index];
                  return ListTile(
                    leading: Icon(
                      Icons.folder,
                      color: p.color != null
                          ? Color(int.parse(p.color!))
                          : Colors.grey,
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: selectedProjId == p.projectID
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      focusBlock.setProject(p.projectID);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskPicker(
    BuildContext context,
    List<dynamic> tasks,
    String? selectedTaskId,
  ) {
    final selectedProjId = focusBlock.selectedProjectId.value;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Ongoing Task",
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 16),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text("No active tasks for this project"),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final t = tasks[index];
                    return ListTile(
                      leading: const Icon(Icons.task_alt_rounded),
                      title: Text(
                        t.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: t.description != null
                          ? Text(
                              t.description!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: selectedTaskId == t.goalID
                          ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).colorScheme.primary,
                            )
                          : null,
                      onTap: () {
                        focusBlock.setTask(t.goalID);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            const Divider(),
            ListTile(
              leading: Icon(
                Icons.add_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                "Create New Task",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                _showCreateTaskDialog(
                  context,
                  focusBlock,
                  growthBlock,
                  selectedProjId,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTaskDialog(
    BuildContext context,
    FocusBlock focusBlock,
    GrowthBlock growthBlock,
    String? projectId,
  ) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("New Task"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: "Task Title",
                hintText: "What are you focusing on?",
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await growthBlock.createNewTask(
                  titleController.text,
                  descController.text,
                  projectID: projectId,
                );
                Navigator.pop(context);
              }
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }
}

class _TimerCircle extends StatelessWidget {
  final double progress;
  final String timeStr;
  final Color modeColor;
  final String sessionType;
  final bool isRunning;
  final FocusBlock focusBlock;
  final int totalDuration;
  final String themeName;
  final bool isExerciseMode;
  final String exerciseType;

  const _TimerCircle({
    required this.progress,
    required this.timeStr,
    required this.modeColor,
    required this.sessionType,
    required this.isRunning,
    required this.focusBlock,
    required this.totalDuration,
    required this.themeName,
    required this.isExerciseMode,
    required this.exerciseType,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trackSize = UIConstants.getTimerTrackSize(context);
    final containerSize = UIConstants.getTimerContainerSize(context);
    final rippleSize = UIConstants.getTimerRippleSize(context);

    // Calculate offsets to center the ripple
    // The stack alignment is center, so Positioned relative to the stack center needs careful handling
    // Actually, if we use Stack(alignment: Alignment.center), we can just use a centered Container with the ripple size
    // inside a Center widget or just let alignment handle it if the stack is big enough.
    // Better: Use a Container with width/height = rippleSize and ensure it's centered.

    return GestureDetector(
      onTap: () {
        if (isRunning) {
          focusBlock.pauseTimer();
        } else {
          focusBlock.startTimer();
        }
      },
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none, // Allow glow/ripple to expand beyond
        children: [
          // Pulsing Effect (Behind everything)
          if (isRunning)
            SizedBox(
              width: rippleSize,
              height: rippleSize,
              child: _RippleEffect(color: modeColor),
            ),

          // 1. Multi-layered Volumetric Glow
          Container(
            width: containerSize,
            height: containerSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: modeColor.withValues(alpha: 0.7),
                width: 30, // Could also be responsive if needed
              ),
              boxShadow: [
                BoxShadow(
                  color: modeColor.withOpacity(0.08),
                  blurRadius: 100,
                  spreadRadius: 20,
                ),
                BoxShadow(
                  color: modeColor.withOpacity(0.04),
                  blurRadius: 150,
                  spreadRadius: 40,
                ),
              ],
            ),
          ),

          // 2. Base Track (Minimalist)
          CustomPaint(
            size: Size(trackSize, trackSize),
            painter: _GloriousTimerPainter(
              progress: 1.0,
              color: modeColor.withOpacity(0.05),
              strokeWidth: 4,
              isTrack: true,
              themeName: themeName,
            ),
          ),

          // 3. Animated Progress Ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: progress),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutQuint,
            builder: (context, value, _) => CustomPaint(
              // Progress ring is slightly larger than track usually, or same.
              // Let's keep the correlation: trackSize + padding
              size: Size(trackSize + 20, trackSize + 20),
              painter: _GloriousTimerPainter(
                progress: value,
                color: modeColor.withValues(
                  alpha: 0.8,
                  green: 10,
                  blue: 10,
                  red: 10,
                ),
                strokeWidth: 5,
                themeName: themeName,
              ),
            ),
          ),

          // 4. Subtle Inner Atmosphere
          Container(
            width: trackSize * 0.8, // Responsive inner size
            height: trackSize * 0.8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [modeColor.withOpacity(0.03), Colors.transparent],
              ),
            ),
          ),

          // Theme Specific Decorator
          _ThemeVibeDecorator(
            themeName: themeName,
            isRunning: isRunning,
            color: modeColor,
          ),

          // Content Layer
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 60,
                  fontWeight: FontWeight.w900, // Even bolder
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _getContrastColor(modeColor, colorScheme.surface),
                  letterSpacing: -2,
                  shadows: [
                    Shadow(color: modeColor.withOpacity(0.2), blurRadius: 20),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isExerciseMode
                        ? Icons.bolt_rounded
                        : (isRunning ? Icons.bolt_rounded : Icons.spa_rounded),
                    size: 14,
                    color: _getContrastColor(
                      modeColor,
                      colorScheme.surface,
                    ).withOpacity(0.8),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isExerciseMode
                        ? "ACTIVE EXERCISE: ${exerciseType.toUpperCase()}"
                        : (isRunning ? "FLOW STATE ACTIVE" : "BREATHING"),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      color: _getContrastColor(
                        modeColor,
                        colorScheme.surface,
                      ).withOpacity(0.9),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              if (focusBlock.currentTrackTitle.watch(context) != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.music_note_rounded,
                        size: 14,
                        color: modeColor,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          focusBlock.currentTrackTitle.value!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: modeColor,
                            letterSpacing: 1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              _TimerControls(
                focusBlock: focusBlock,
                isRunning: isRunning,
                totalDuration: totalDuration,
                modeColor: modeColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GloriousTimerPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;
  final bool isTrack;
  final String themeName;

  _GloriousTimerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.themeName,
    this.isTrack = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    if (isTrack) {
      canvas.drawCircle(center, radius, paint);
      return;
    }

    // Progress Arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    // Theme-specific glow
    if (progress > 0) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.3)
        ..strokeWidth = strokeWidth + 4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    }

    // Draw the main arc
    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // --- Premium Iridescent Layer ---
    if (progress > 0 && !isTrack) {
      final iridescentPaint = Paint()
        ..shader = SweepGradient(
          colors: [
            color.withOpacity(0.1),
            Colors.white.withOpacity(0.4),
            color.withOpacity(0.1),
          ],
          stops: const [0.0, 0.5, 1.0],
          transform: GradientRotation(startAngle + sweepAngle - 0.2),
        ).createShader(rect)
        ..strokeWidth = strokeWidth * 0.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweepAngle, false, iridescentPaint);
    }

    // --- Theme Specific Details ---
    if (progress > 0) {
      if (themeName == 'Sakura Zen') {
        _paintSakuraDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Frosty Morning' || themeName == 'Snowflake') {
        _paintFrostyDetails(
          canvas,
          center,
          radius,
          startAngle,
          sweepAngle,
          isDense: themeName == 'Snowflake',
        );
      } else if (themeName == 'Ice') {
        _paintIceDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Indigo') {
        _paintIndigoDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Volcano') {
        _paintVolcanoDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Ocean Deep') {
        _paintOceanDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Cyberpunk Pink') {
        _paintCyberDetails(canvas, center, radius, startAngle, sweepAngle);
      } else if (themeName == 'Enchanted Forest') {
        _paintForestDetails(canvas, center, radius, startAngle, sweepAngle);
      }
    }

    // Energy Head (Bright tip)
    if (progress > 0 && progress < 1.0) {
      final headAngle = startAngle + sweepAngle;
      final headPos = Offset(
        center.dx + radius * math.cos(headAngle),
        center.dy + radius * math.sin(headAngle),
      );

      final headPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(headPos, strokeWidth / 1.5, headPaint);

      final outerHeadPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(headPos, strokeWidth * 2, outerHeadPaint);

      // Particle Trail
      _paintParticles(canvas, center, radius, headAngle, color);
    }
  }

  void _paintSakuraDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    // Fewer full flowers than single petals for clarity
    final flowerCount = (sweepAngle * radius / 40).floor();
    final random = math.Random(42);
    const flowerRadius = 8.0;

    for (int i = 0; i <= flowerCount; i++) {
      final angle = startAngle + (sweepAngle * (i / flowerCount));
      final drift = (random.nextDouble() - 0.5) * 12;
      final pos = Offset(
        center.dx + (radius + drift) * math.cos(angle),
        center.dy + (radius + drift) * math.sin(angle),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      // Rotate flowers slightly for organic variety
      canvas.rotate(angle + i * random.nextDouble() * 2);
      final scale = 0.8 + random.nextDouble() * 0.4;
      canvas.scale(scale);

      final flowerPaint = Paint()
        ..color = const Color(0xFFFFB7C5).withOpacity(0.9)
        ..style = PaintingStyle.fill;

      // Draw 5 Petals (Based on user snippet logic)
      for (int j = 0; j < 5; j++) {
        double petalAngle = (j * 72) * math.pi / 180;
        _drawDetailedPetal(
          canvas,
          Offset.zero,
          flowerRadius,
          petalAngle,
          flowerPaint,
        );
      }

      // Draw Flower Center (Stamen)
      final stamenPaint = Paint()
        ..color = Colors.yellow.shade100
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);
      canvas.drawCircle(Offset.zero, 1.5, stamenPaint);

      canvas.restore();
    }
  }

  void _drawDetailedPetal(
    Canvas canvas,
    Offset center,
    double radius,
    double angle,
    Paint paint,
  ) {
    final path = Path();
    final double cosA = math.cos(angle);
    final double sinA = math.sin(angle);

    path.moveTo(center.dx, center.dy);

    // Left curve
    path.quadraticBezierTo(
      center.dx + radius * 1.2 * math.cos(angle - 0.4),
      center.dy + radius * 1.2 * math.sin(angle - 0.4),
      center.dx + radius * cosA,
      center.dy + radius * sinA,
    );

    // The Notch
    path.lineTo(
      center.dx + radius * 0.85 * math.cos(angle),
      center.dy + radius * 0.85 * math.sin(angle),
    );

    // Right curve
    path.lineTo(center.dx + radius * cosA, center.dy + radius * sinA);
    path.quadraticBezierTo(
      center.dx + radius * 1.2 * math.cos(angle + 0.4),
      center.dy + radius * 1.2 * math.sin(angle + 0.4),
      center.dx,
      center.dy,
    );

    path.close();
    canvas.drawPath(path, paint);

    // Subtle edge highlight
    final strokePaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    canvas.drawPath(path, strokePaint);
  }

  void _paintFrostyDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle, {
    bool isDense = false,
  }) {
    final crystalCount = (sweepAngle * radius / (isDense ? 25 : 40)).floor();
    final crystalPaint = Paint()
      ..color = Colors.white.withValues(alpha: isDense ? 0.9 : 0.8)
      ..strokeWidth = isDense ? 0.8 : 1.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i <= crystalCount; i++) {
      final angle = startAngle + (sweepAngle * (i / crystalCount));
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      // Intricate Crystalline Snowflake design
      const arms = 6;
      const armLength = 5.0;
      for (int j = 0; j < arms; j++) {
        canvas.rotate(2 * math.pi / arms);

        // Main branch
        canvas.drawLine(Offset.zero, const Offset(armLength, 0), crystalPaint);

        // Small side spurs (The "V" shape logic from reference image)
        canvas.save();
        canvas.translate(armLength * 0.6, 0);
        canvas.rotate(math.pi / 4);
        canvas.drawLine(Offset.zero, const Offset(2.5, 0), crystalPaint);
        canvas.rotate(-math.pi / 2);
        canvas.drawLine(Offset.zero, const Offset(2.5, 0), crystalPaint);
        canvas.restore();
      }

      canvas.restore();
    }
  }

  void _paintIceDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final shardCount = (sweepAngle * radius / 50).floor();
    final shardPaint = Paint()
      ..color = const Color(0xFFE0F7FA).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i <= shardCount; i++) {
      final angle = startAngle + (sweepAngle * (i / shardCount));
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle);

      // Sharp Ice Shard
      final shardPath = Path();
      shardPath.moveTo(-2, 0);
      shardPath.lineTo(8, -2);
      shardPath.lineTo(12, 0);
      shardPath.lineTo(8, 2);
      shardPath.close();

      canvas.drawPath(shardPath, shardPaint);
      canvas.restore();
    }
  }

  void _paintIndigoDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final pulseCount = (sweepAngle * radius / 60).floor();
    final pulsePaint = Paint()
      ..color = const Color(0xFF3F51B5).withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i <= pulseCount; i++) {
      final angle = startAngle + (sweepAngle * (i / pulseCount));
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      // Deep Indigo dots for stability
      canvas.drawCircle(pos, 2, pulsePaint);
      canvas.drawCircle(
        pos,
        5,
        pulsePaint..color = pulsePaint.color.withOpacity(0.2),
      );
    }
  }

  void _paintVolcanoDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final sparkCount = (sweepAngle * radius / 20).floor();
    final random = math.Random(7);
    final sparkPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < sparkCount; i++) {
      final angle = startAngle + (sweepAngle * (i / sparkCount));
      final drift = random.nextDouble() * 15;
      final pos = Offset(
        center.dx + (radius + drift) * math.cos(angle),
        center.dy + (radius + drift) * math.sin(angle),
      );

      sparkPaint.color = Colors.orangeAccent.withOpacity(0.8 - (drift / 20));
      canvas.drawCircle(pos, 1.5 + random.nextDouble() * 2, sparkPaint);
    }
  }

  void _paintOceanDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final bubbleCount = (sweepAngle * radius / 30).floor();
    final random = math.Random(13);
    final bubblePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < bubbleCount; i++) {
      final angle = startAngle + (sweepAngle * (i / bubbleCount));
      final drift = -(random.nextDouble() * 10);
      final pos = Offset(
        center.dx + (radius + drift) * math.cos(angle),
        center.dy + (radius + drift) * math.sin(angle),
      );

      bubblePaint.color = Colors.white.withOpacity(
        0.4 + random.nextDouble() * 0.4,
      );
      canvas.drawCircle(pos, 2 + random.nextDouble() * 3, bubblePaint);
    }
  }

  void _paintCyberDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final pulseCount = (sweepAngle * radius / 40).floor();
    final random = math.Random(21);
    final linePaint = Paint()
      ..color = const Color(0xFF00FFFF).withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < pulseCount; i++) {
      final angle = startAngle + (sweepAngle * (i / pulseCount));
      final pos = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(angle + math.pi / 2);

      // Glitchy line
      canvas.drawLine(
        Offset(-5, (random.nextDouble() - 0.5) * 8),
        Offset(5, (random.nextDouble() - 0.5) * 8),
        linePaint,
      );
      canvas.restore();
    }
  }

  void _paintForestDetails(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double sweepAngle,
  ) {
    final sporeCount = (sweepAngle * radius / 35).floor();
    final random = math.Random(33);
    final sporePaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < sporeCount; i++) {
      final angle = startAngle + (sweepAngle * (i / sporeCount));
      final drift = (random.nextDouble() - 0.5) * 20;
      final pos = Offset(
        center.dx + (radius + drift) * math.cos(angle),
        center.dy + (radius + drift) * math.sin(angle),
      );

      sporePaint.color = Colors.lightGreenAccent.withOpacity(0.6);
      sporePaint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(pos, 1.5, sporePaint);
    }
  }

  void _paintParticles(
    Canvas canvas,
    Offset center,
    double radius,
    double headAngle,
    Color color,
  ) {
    final random = math.Random(42); // Deterministic "random"
    for (int i = 0; i < 8; i++) {
      final angleOffset = -(random.nextDouble() * 0.2);
      final distOffset = (random.nextDouble() - 0.5) * 10;
      final partAngle = headAngle + angleOffset;
      final partPos = Offset(
        center.dx + (radius + distOffset) * math.cos(partAngle),
        center.dy + (radius + distOffset) * math.sin(partAngle),
      );

      final partPaint = Paint()
        ..color = color.withOpacity(1.0 - (i / 8))
        ..style = PaintingStyle.fill
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          random.nextDouble() * 3,
        );

      canvas.drawCircle(partPos, 1.5 * (1.0 - (i / 8)), partPaint);
    }
  }

  @override
  bool shouldRepaint(_GloriousTimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.themeName != themeName;
  }
}

class _RippleEffect extends StatefulWidget {
  final Color color;
  const _RippleEffect({required this.color});

  @override
  State<_RippleEffect> createState() => _RippleEffectState();
}

class _RippleEffectState extends State<_RippleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2), // Faster for more energy
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(600, 600),
          painter: _RipplePainter(
            animationValue: _controller.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _RipplePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _RipplePainter({required this.animationValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxRadius = size.width / 2;
    // Base radius of the timer circle is 150 (width 350 / 2) -> actually depends on screen size now but let's keep it relative or use fixed since the ripple container is what matters
    // Ideally we should pass the base radius, but for now let's stick to the visual effect requested.
    // The previous code had const baseRadius = 150.0;
    const baseRadius = 150.0;

    // INCREASED WAVE COUNT to 5
    for (int i = 0; i < 5; i++) {
      // Stagger the waves (1.0 / 5 = 0.2)
      final progress = (animationValue + (i * 0.2)) % 1.0;

      // Only draw if outside the base circle
      final currentRadius = baseRadius + (maxRadius - baseRadius) * progress;

      // Fade out as it expands
      double opacity = (1.0 - progress).clamp(0.0, 1.0);
      opacity = math
          .pow(opacity, 1.5) // Less aggressive fade for more visibility
          .toDouble();

      final paint = Paint()
        ..color = color
            .withOpacity(opacity * 0.3) // Higher opacity
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0; // Thicker stroke

      // Draw the ring
      canvas.drawCircle(center, currentRadius, paint);

      // Optional: Add a second filled circle with very low opacity for "glow" feel
      final glowPaint = Paint()
        ..color = color.withOpacity(opacity * 0.1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, currentRadius, glowPaint);
    }
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return animationValue != oldDelegate.animationValue ||
        color != oldDelegate.color;
  }
}

class _ThemeVibeDecorator extends StatelessWidget {
  final String themeName;
  final bool isRunning;
  final Color color;

  const _ThemeVibeDecorator({
    required this.themeName,
    required this.isRunning,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRunning) return const SizedBox.shrink();

    return ClipOval(
      child: SizedBox(width: 420, height: 420, child: _buildEffect()),
    );
  }

  Widget _buildEffect() {
    switch (themeName) {
      case 'Frosty Morning':
      case 'Snowflake':
        return const _SnowEffect();
      case 'Ice':
        return const _SnowEffect(); // Ice uses snow particles for now
      case 'Indigo':
        return const _AuroraEffect(); // Indigo uses cosmic/aurora feel
      case 'Emerald Forest':
      case 'Emerald Haven':
        return _ForestEffect(color: color);
      case 'Cherry':
        return const _FireEffect();
      case 'Nordic Night':
        return const _AuroraEffect();
      case 'Deep Sea':
        return const _BubbleEffect(color: Colors.blueAccent);
      case 'Light Purple':
        return const _BubbleEffect(color: Colors.purpleAccent);
      case 'Sakura Zen':
        return const _SakuraEffect();
      case 'Cyberpunk 2077':
        return const _GlitchEffect();
      case 'Nebula':
      case 'Midnight Gold':
        return const _StarfieldEffect();
      case 'Royal Velvet':
        return const _SparkleEffect();
      default:
        return const SizedBox.shrink();
    }
  }
}

class _SnowEffect extends StatefulWidget {
  const _SnowEffect();

  @override
  State<_SnowEffect> createState() => _SnowEffectState();
}

class _SnowEffectState extends State<_SnowEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _snowflakes = List.generate(20, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _SnowPainter(_snowflakes, _controller.value),
        );
      },
    );
  }
}

class _ForestEffect extends StatefulWidget {
  final Color color;
  const _ForestEffect({required this.color});

  @override
  State<_ForestEffect> createState() => _ForestEffectState();
}

class _ForestEffectState extends State<_ForestEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _leaves = List.generate(15, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _ForestPainter(_leaves, _controller.value, widget.color),
        );
      },
    );
  }
}

class _FireEffect extends StatefulWidget {
  const _FireEffect();

  @override
  State<_FireEffect> createState() => _FireEffectState();
}

class _FireEffectState extends State<_FireEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _embers = List.generate(25, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _FirePainter(_embers, _controller.value));
      },
    );
  }
}

class _Particle {
  double x = 0;
  double y = 0;
  double size = 0;
  double speed = 0;
  double angle = 0;

  _Particle() {
    _reset();
  }

  void _reset() {
    x = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000;
    y = (DateTime.now().microsecondsSinceEpoch % 1234) / 1234;
    size = 2 + (DateTime.now().microsecondsSinceEpoch % 5);
    speed = 0.5 + (DateTime.now().microsecondsSinceEpoch % 10) / 10;
    angle = (DateTime.now().microsecondsSinceEpoch % 360) * 3.14 / 180;
  }
}

class _SnowPainter extends CustomPainter {
  final List<_Particle> snowflakes;
  final double animationValue;

  _SnowPainter(this.snowflakes, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    for (var flake in snowflakes) {
      final yProgress = (animationValue * flake.speed + flake.y) % 1.0;
      final xOffset = (animationValue * 0.2 + flake.x) % 1.0;

      canvas.drawCircle(
        Offset(xOffset * size.width, yProgress * size.height),
        flake.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _ForestPainter extends CustomPainter {
  final List<_Particle> leaves;
  final double animationValue;
  final Color color;

  _ForestPainter(this.leaves, this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withOpacity(0.3);
    for (var leaf in leaves) {
      final yProgress = (animationValue * 0.1 * leaf.speed + leaf.y) % 1.0;
      final xOffset = (animationValue * 0.05 + leaf.x) % 1.0;

      canvas.drawCircle(
        Offset(xOffset * size.width, yProgress * size.height),
        leaf.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _FirePainter extends CustomPainter {
  final List<_Particle> embers;
  final double animationValue;

  _FirePainter(this.embers, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var ember in embers) {
      final yProgress = 1.0 - ((animationValue * ember.speed + ember.y) % 1.0);
      final xOffset = (ember.x + 0.1 * (animationValue - 0.5)) % 1.0;

      final paint = Paint()
        ..color = Colors.orangeAccent.withOpacity((1.0 - yProgress) * 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(xOffset * size.width, yProgress * size.height),
        ember.size / 2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _AuroraEffect extends StatefulWidget {
  const _AuroraEffect();

  @override
  State<_AuroraEffect> createState() => _AuroraEffectState();
}

class _AuroraEffectState extends State<_AuroraEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(painter: _AuroraPainter(_controller.value));
      },
    );
  }
}

class _AuroraPainter extends CustomPainter {
  final double animationValue;
  _AuroraPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    for (int i = 0; i < 3; i++) {
      final progress = (animationValue + i * 0.33) % 1.0;
      final xOffset = size.width * (0.2 + 0.6 * progress);

      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          Colors.transparent,
          const Color(0xFF00FFCC).withOpacity(0.3 * (1 - progress)),
          const Color(0xFF6600FF).withOpacity(0.1 * (1 - progress)),
          Colors.transparent,
        ],
      );

      paint.shader = gradient.createShader(
        Rect.fromLTWH(xOffset - 50, 0, 100, size.height),
      );

      final path = Path();
      path.moveTo(xOffset - 100, size.height);
      path.quadraticBezierTo(
        xOffset + 50 * (progress - 0.5),
        size.height / 2,
        xOffset + 100,
        0,
      );
      path.lineTo(xOffset + 150, 0);
      path.quadraticBezierTo(
        xOffset + 100 * progress,
        size.height / 2,
        xOffset - 50,
        size.height,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SakuraEffect extends StatefulWidget {
  const _SakuraEffect();

  @override
  State<_SakuraEffect> createState() => _SakuraEffectState();
}

class _SakuraEffectState extends State<_SakuraEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _petals = List.generate(12, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _SakuraPainter(_petals, _controller.value)),
    );
  }
}

class _SakuraPainter extends CustomPainter {
  final List<_Particle> petals;
  final double animationValue;
  _SakuraPainter(this.petals, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFB7C5).withOpacity(0.6);
    for (var petal in petals) {
      final yProgress = (animationValue * 0.4 * petal.speed + petal.y) % 1.0;
      final xOffset =
          (petal.x + 0.1 * math.sin(animationValue * 6.28 + petal.angle)) % 1.0;

      canvas.save();
      canvas.translate(xOffset * size.width, yProgress * size.height);
      canvas.rotate(animationValue * 3.14 + petal.angle);
      final petalPath = Path();
      petalPath.addOval(Rect.fromLTWH(0, 0, petal.size, petal.size * 1.5));
      canvas.drawPath(petalPath, paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _GlitchEffect extends StatefulWidget {
  const _GlitchEffect();
  @override
  State<_GlitchEffect> createState() => _GlitchEffectState();
}

class _GlitchEffectState extends State<_GlitchEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _GlitchPainter(_controller.value)),
    );
  }
}

class _GlitchPainter extends CustomPainter {
  final double animationValue;
  _GlitchPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final rand = animationValue;
    if (rand > 0.8) {
      final paint = Paint()..color = const Color(0xFFFCEE0A).withOpacity(0.2);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * rand, size.width, 2.0),
        paint,
      );

      final paint2 = Paint()..color = Colors.cyanAccent.withOpacity(0.1);
      canvas.drawRect(
        Rect.fromLTWH(0, size.height * (1 - rand), size.width, 10.0),
        paint2,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _StarfieldEffect extends StatefulWidget {
  const _StarfieldEffect();
  @override
  State<_StarfieldEffect> createState() => _StarfieldEffectState();
}

class _StarfieldEffectState extends State<_StarfieldEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _stars = List.generate(40, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _StarfieldPainter(_stars, _controller.value)),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  final List<_Particle> stars;
  final double animationValue;
  _StarfieldPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      final opacity =
          (math.sin(animationValue * 6.28 * star.speed * 5 + star.angle) +
              1.0) /
          2.0;
      paint.color = Colors.white.withOpacity(opacity * 0.8);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size / 4,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _SparkleEffect extends StatefulWidget {
  const _SparkleEffect();
  @override
  State<_SparkleEffect> createState() => _SparkleEffectState();
}

class _SparkleEffectState extends State<_SparkleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _sparkles = List.generate(15, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) =>
          CustomPaint(painter: _SparklePainter(_sparkles, _controller.value)),
    );
  }
}

class _SparklePainter extends CustomPainter {
  final List<_Particle> sparkles;
  final double animationValue;
  _SparklePainter(this.sparkles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFD700);
    for (var sparkle in sparkles) {
      final progress = (animationValue * sparkle.speed + sparkle.y) % 1.0;
      final opacity = math.sin(progress * 3.14);
      paint.color = const Color(0xFFFFD700).withOpacity(opacity * 0.6);

      final center = Offset(sparkle.x * size.width, sparkle.y * size.height);
      final s = sparkle.size * opacity;

      canvas.drawRect(
        Rect.fromCenter(center: center, width: s, height: s / 4),
        paint,
      );
      canvas.drawRect(
        Rect.fromCenter(center: center, width: s / 4, height: s),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _BubbleEffect extends StatefulWidget {
  final Color color;
  const _BubbleEffect({required this.color});

  @override
  State<_BubbleEffect> createState() => _BubbleEffectState();
}

class _BubbleEffectState extends State<_BubbleEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _bubbles = List.generate(15, (i) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _BubblePainter(_bubbles, _controller.value, widget.color),
        );
      },
    );
  }
}

class _BubblePainter extends CustomPainter {
  final List<_Particle> bubbles;
  final double animationValue;
  final Color color;

  _BubblePainter(this.bubbles, this.animationValue, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final yProgress =
          1.0 - ((animationValue * bubble.speed + bubble.y) % 1.0);
      final xOffset = (bubble.x + 0.05 * (animationValue - 0.5)) % 1.0;

      final paint = Paint()
        ..color = color.withOpacity((1.0 - yProgress) * 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      final fillPaint = Paint()
        ..color = color.withOpacity((1.0 - yProgress) * 0.1)
        ..style = PaintingStyle.fill;

      final center = Offset(xOffset * size.width, yProgress * size.height);
      canvas.drawCircle(center, bubble.size, fillPaint);
      canvas.drawCircle(center, bubble.size, paint);

      // Highlight on bubble
      canvas.drawCircle(
        center - Offset(bubble.size * 0.3, bubble.size * 0.3),
        bubble.size * 0.2,
        Paint()..color = Colors.white.withOpacity((1.0 - yProgress) * 0.4),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _TimerSettingsSheet extends StatelessWidget {
  final FocusBlock focusBlock;
  const _TimerSettingsSheet({required this.focusBlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final focusMin = focusBlock.focusDuration.watch(context);
    final shortMin = focusBlock.shortBreakDuration.watch(context);
    final longMin = focusBlock.longBreakDuration.watch(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      padding: EdgeInsets.only(top: 90, left: 20, right: 20),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const SizedBox(width: 50,),
              Row(
                children: [
                  const Icon(Icons.settings_suggest_rounded, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    "Timer Settings",
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _DurationSlider(
                label: "Focus Duration",
                value: focusMin,
                max: 60,
                min: 1,
                color: theme.colorScheme.primary,
                onChanged: (val) {
                  HapticFeedback.mediumImpact();
                  focusBlock.setDurations(focus: val.toInt());
                },
              ),
              const SizedBox(height: 16),
              _DurationSlider(
                label: "Short Break",
                value: shortMin,
                max: 30,
                min: 1,
                color: Colors.teal,
                onChanged: (val) {
                  HapticFeedback.mediumImpact();
                  focusBlock.setDurations(short: val.toInt());
                },
              ),
              const SizedBox(height: 16),
              _DurationSlider(
                label: "Long Break",
                value: longMin,
                max: 45,
                min: 5,
                color: Colors.blue,
                onChanged: (val) {
                  HapticFeedback.heavyImpact();
                  focusBlock.setDurations(long: val.toInt());
                },
              ),
              const SizedBox(height: 24),
              Text(
                "Ambience",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _SoundSelector(focusBlock: focusBlock),
              const SizedBox(height: 24),
              Text(
                "Timer Style",
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: timerThemes.map((t) {
                  final isSelected =
                      focusBlock.timerTheme.watch(context) == t.name;
                  return InkWell(
                    onTap: () => focusBlock.setTimerTheme(t.name),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? t.color.withOpacity(0.15)
                            : theme.colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? t.color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            t.icon,
                            color: isSelected
                                ? t.color
                                : theme.colorScheme.onSurfaceVariant,
                            size: 28,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? t.color
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final int value;
  final double min;
  final double max;
  final Color color;
  final ValueChanged<double> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(
              "$value min",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: color.withOpacity(0.5),
            inactiveTrackColor: color.withOpacity(0.1),
            thumbColor: color,
            overlayColor: color.withOpacity(0.2),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min,
            max: max,
            divisions: (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  final int sessionsCount;
  final int totalStudyTime;
  final Color modeColor;

  const _StatsGrid({
    required this.sessionsCount,
    required this.totalStudyTime,
    required this.modeColor,
  });

  @override
  Widget build(BuildContext context) {
    final hrs = totalStudyTime ~/ 3600;
    final mins = (totalStudyTime % 3600) ~/ 60;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatBox(
                label: "Sessions",
                value: "$sessionsCount",
                icon: Icons.bolt_rounded,
                color: modeColor,
              ),
            ),
            const VerticalDivider(width: 32, indent: 10, endIndent: 10),
            Expanded(
              child: _StatBox(
                label: "Focus Time",
                value: hrs > 0 ? "${hrs}h ${mins}m" : "${mins}m",
                icon: Icons.schedule_rounded,
                color: modeColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _RecentHistoryHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            "Recent Activity",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          TextButton(
            onPressed: () => context.push('/focus-history'),
            child: const Text("View All", style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _HistoryItem extends StatelessWidget {
  final FocusSessionData session;
  final Color modeColor;
  const _HistoryItem({required this.session, required this.modeColor});

  @override
  Widget build(BuildContext context) {
    final mins = session.durationSeconds ~/ 60;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: modeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.history_rounded, color: modeColor, size: 18),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${mins}m Focus Session",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(session.startTime),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (session.notes != null && session.notes!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    session.notes!,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withOpacity(0.8),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Text(
            DateFormat('HH:mm').format(session.startTime),
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: modeColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingCircle extends StatefulWidget {
  final Color color;
  const _BreathingCircle({required this.color});

  @override
  State<_BreathingCircle> createState() => _BreathingCircleState();
}

class _BreathingCircleState extends State<_BreathingCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _animation,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withOpacity(0.05),
        ),
      ),
    );
  }
}

class _SoundSelector extends StatefulWidget {
  final FocusBlock focusBlock;
  const _SoundSelector({required this.focusBlock});

  @override
  State<_SoundSelector> createState() => _SoundSelectorState();
}

class _SoundSelectorState extends State<_SoundSelector> {
  bool _isPicking = false;

  @override
  Widget build(BuildContext context) {
    final customPath = widget.focusBlock.customSoundPath.watch(context);
    final isLocal = widget.focusBlock.isCustomSoundLocal.watch(context);

    return Column(
      children: [
        // 1. Theme Default Option
        _SoundOption(
          label: "Theme Default",
          isSelected: customPath == null,
          icon: Icons.auto_awesome,
          onTap: () => widget.focusBlock.clearCustomSound(),
        ),
        const SizedBox(height: 8),

        // 2. Local File Option
        _SoundOption(
          label: _isPicking
              ? "Picking file..."
              : (isLocal && customPath != null
                    ? "Local: ${customPath.split('/').last}"
                    : "Pick from Device..."),
          isSelected: isLocal,
          icon: _isPicking
              ? Icons.hourglass_empty_rounded
              : Icons.audio_file_rounded,
          onTap: _isPicking ? () {} : () => _pickFile(context),
        ),
        const SizedBox(height: 8),

        // 3. Built-in Preset Options (Horizontal Scroll)
        SizedBox(
          height: 100,
          child: ListView(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            children: [
              _presetOption(
                context,
                "Rain",
                "sounds/rain.mp3",
                Icons.water_drop,
              ),
              _presetOption(
                context,
                "Forest",
                "sounds/forest_stream.mp3",
                Icons.forest,
              ),
              _presetOption(context, "Lofi", "sounds/lofi.mp3", Icons.headset),
              _presetOption(
                context,
                "White Noise",
                "sounds/white_noise.mp3",
                Icons.grain,
              ),
              _presetOption(
                context,
                "Waves",
                "sounds/ocean_waves.mp3",
                Icons.waves,
              ),
              _presetOption(
                context,
                "Fire",
                "sounds/fire_crackle.mp3",
                Icons.local_fire_department,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _presetOption(
    BuildContext context,
    String label,
    String path,
    IconData icon,
  ) {
    final customPath = widget.focusBlock.customSoundPath.watch(context);
    final isSelected = customPath == path;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: () => widget.focusBlock.setCustomSound(path),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 80,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? theme.colorScheme.primaryContainer
                : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    if (_isPicking) return;

    setState(() {
      _isPicking = true;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac', 'flac'],
      );
      if (result != null && result.files.single.path != null) {
        widget.focusBlock.setCustomSound(
          result.files.single.path!,
          isLocal: true,
        );
      }
    } catch (e) {
      if (e is! UnimplementedError) {
        debugPrint("File picker error: $e");
      }
      // Handle error or permission denial
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPicking = false;
        });
      }
    }
  }
}

class _SoundOption extends StatelessWidget {
  final String label;
  final bool isSelected;
  final IconData icon;
  final VoidCallback onTap;

  const _SoundOption({
    required this.label,
    required this.isSelected,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: theme.colorScheme.primary)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

Color _getContrastColor(Color baseColor, Color backgroundColor) {
  // Basic luminance check to ensure text is readable
  // If the base color is too close to light background, return a darker version or onSurface
  final double bgLuminance = backgroundColor.computeLuminance();
  final double colorLuminance = baseColor.computeLuminance();

  // If background is light (high luminance) and color is also light
  if (bgLuminance > 0.6 && colorLuminance > 0.6) {
    // Return a darker version or a fallback dark color
    return HSLColor.fromColor(baseColor)
        .withLightness(
          (HSLColor.fromColor(baseColor).lightness - 0.4).clamp(0.0, 1.0),
        )
        .toColor();
  }

  // If background is dark and color is dark
  if (bgLuminance < 0.4 && colorLuminance < 0.3) {
    return Colors.white70;
  }

  return baseColor;
}

class _SessionResultDialog extends StatefulWidget {
  final FocusBlock focusBlock;
  const _SessionResultDialog({required this.focusBlock});

  @override
  State<_SessionResultDialog> createState() => _SessionResultDialogState();
}

class _SessionResultDialogState extends State<_SessionResultDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _markTaskCompleted = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final sessionType = widget.focusBlock.currentSessionType.value;
    final isFocus = sessionType == 'Focus';
    final hasActiveTask = widget.focusBlock.selectedTaskId.value != null;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isFocus
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.teal.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFocus ? Icons.emoji_events_rounded : Icons.coffee_rounded,
                color: isFocus ? Colors.orange : Colors.teal,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              isFocus ? "Session Complete!" : "Break Finished",
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFocus
                  ? "Outstanding effort! You've stayed in the zone."
                  : "Hope you enjoyed your break. Ready for another round?",
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "What did you accomplish?",
                labelText: "Session Notes",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                filled: true,
                fillColor: colorScheme.surfaceContainerLow,
              ),
            ),
            if (isFocus && hasActiveTask) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    "Mark task as fully completed",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  value: _markTaskCompleted,
                  activeColor: Colors.orange,
                  onChanged: (val) {
                    setState(() {
                      _markTaskCompleted = val ?? false;
                    });
                  },
                ),
              ),
            ],
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  widget.focusBlock.finishAndSaveSession(
                    _notesController.text,
                    markTaskDone: _markTaskCompleted,
                  );
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  backgroundColor: isFocus ? Colors.orange : Colors.teal,
                ),
                child: const Text(
                  "Log Result",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                widget.focusBlock.finishAndSaveSession(
                  "",
                  markTaskDone: _markTaskCompleted,
                );
                Navigator.pop(context);
              },
              child: Text(
                "Skip Notes",
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
