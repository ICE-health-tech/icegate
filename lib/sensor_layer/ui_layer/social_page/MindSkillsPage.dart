import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/SkillCertificatePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindSkillCatalog.dart';
import 'package:ice_gate/link_layer/skills/skill_practice_streak.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/SkillSessionCelebration.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class MindSkillsPage extends StatelessWidget {
  final String? projectId;
  final String? altProjectId;
  final String? projectTitle;
  final String? startSkill;
  final List<String>? startSkills;
  final bool autoStartSession;

  const MindSkillsPage({
    super.key,
    this.projectId,
    this.altProjectId,
    this.projectTitle,
    this.startSkill,
    this.startSkills,
    this.autoStartSession = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'SKILL BOOST',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: MindSkillsView(
        showBackground: true,
        popOnSave: true,
        projectId: projectId,
        altProjectId: altProjectId,
        projectTitle: projectTitle,
        initialSkillName: startSkill,
        initialSkillNames: startSkills,
        autoStartSession: autoStartSession,
      ),
    );
  }
}

class MindSkillsView extends StatefulWidget {
  final bool showBackground;
  final bool popOnSave;
  final VoidCallback? onSessionLogged;
  final String? projectId;
  final String? altProjectId;
  final String? projectTitle;
  final String? initialSkillName;
  final List<String>? initialSkillNames;
  final bool autoStartSession;

  const MindSkillsView({
    super.key,
    required this.showBackground,
    required this.popOnSave,
    this.onSessionLogged,
    this.projectId,
    this.altProjectId,
    this.projectTitle,
    this.initialSkillName,
    this.initialSkillNames,
    this.autoStartSession = false,
  });

  @override
  State<MindSkillsView> createState() => _MindSkillsViewState();
}

class _MindSkillsViewState extends State<MindSkillsView>
    with TickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _sessionMusicPlayer = AudioPlayer();
  StreamSubscription<void>? _musicCompleteSub;
  Timer? _sessionFallbackTimer;
  final List<String> _sessionTracks = const [
    // Put your extracted tracks into `assets/sounds/` and keep names simple.
    // Example filenames:
    // - assets/sounds/session_1.m4a
    // - assets/sounds/session_2.m4a
    'sounds/session_1.m4a',
    'sounds/session_2.m4a',
  ];
  String? _currentSessionTrack;

  late final AnimationController _spinController;
  late final AnimationController _levelUpController;
  late final AnimationController _sessionPulseController;
  bool _sessionActive = false;
  DateTime? _sessionStartedAt;
  bool _isLoggingSession = false;
  late final AnimationController _selectFxController;
  int _selectFxSeed = 1;
  late final AnimationController _tripleRingController;
  List<Color> _tripleRingColors = const [];
  late final AnimationController _ringIntroController;
  String? _lastRingAddedSkill;

  /// Const palette for custom skill icons (release builds cannot use IconData(cp)).
  static const _skillIconPalette = <IconData>[
    Icons.auto_awesome_rounded,
    Icons.psychology_alt_rounded,
    Icons.bolt_rounded,
    Icons.ac_unit_rounded,
    Icons.water_drop_rounded,
    Icons.local_fire_department_rounded,
    Icons.air_rounded,
    Icons.eco_rounded,
    Icons.favorite_rounded,
    Icons.record_voice_over_rounded,
    Icons.center_focus_strong_rounded,
    Icons.functions_rounded,
    Icons.brush_rounded,
    Icons.code_rounded,
    Icons.trending_up_rounded,
    Icons.autorenew_rounded,
    Icons.auto_awesome_mosaic_rounded,
  ];
  final List<String> _customSkills = [];
  String? _loadedForPersonId;
  String? _loadedIconsForPersonId;
  String? _loadedHiddenDefaultsForPersonId;
  bool _projectSkillsPreselected = false;
  bool _routeSkillSelectionApplied = false;
  final Set<String> _hiddenDefaultSkillsLower = <String>{};
  final Map<String, int> _iconOverrideCodePoint = <String, int>{};
  final Map<String, int> _popTick = <String, int>{};
  Timer? _surgeTimer;
  Color _orbitColor = const Color(0xFFBFD0FF);

  final Set<String> _selected = <String>{};
  static const int _fallbackSessionMinutes = 25;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _sessionPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _selectFxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _tripleRingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ringIntroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..value = 1.0;

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _applyRouteSkillSelection();
    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId != null && personId.isNotEmpty) {
      context.read<GrowthBlock>().ensurePersonSkillLibrary();
    }
  }

  void _applyRouteSkillSelection() {
    if (_routeSkillSelectionApplied) return;
    _routeSkillSelectionApplied = true;

    final routeNames = <String>[
      ...?widget.initialSkillNames,
      if (widget.initialSkillName != null &&
          widget.initialSkillName!.trim().isNotEmpty)
        widget.initialSkillName!.trim(),
    ];
    if (routeNames.isNotEmpty) {
      final all = _allSkills();
      final matched = <String>[];
      for (final name in routeNames) {
        final hit = all.where((s) => MindSkillCatalog.namesMatch(s, name));
        if (hit.isNotEmpty) matched.add(hit.first);
      }
      if (matched.isEmpty) return;

      setState(() {
        _selected
          ..clear()
          ..addAll(matched);
        _orbitColor = _skillColorFor(matched.last);
      });

      if (widget.autoStartSession) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted || _sessionActive) return;
          await _setSessionActive(true);
        });
      }
      return;
    }

    _preselectProjectSkillsOnce();
  }

  void _preselectProjectSkillsOnce() {
    if (_projectSkillsPreselected || widget.projectId == null) return;
    _projectSkillsPreselected = true;
    final growthBlock = context.read<GrowthBlock>();
    final linked = growthBlock.skillsForProject(
      widget.projectId!,
      altProjectId: widget.altProjectId,
    );
    if (linked.isEmpty) return;
    setState(() {
      for (final skill in linked) {
        final name = skill.skillName;
        if (_allSkills().any((s) => MindSkillCatalog.namesMatch(s, name))) {
          _selected.add(
            _allSkills().firstWhere((s) => MindSkillCatalog.namesMatch(s, name)),
          );
        }
      }
    });
  }

  Future<int> _grantSkillXpForSession(
    List<String> sessionSkills,
    int minutes,
  ) async {
    if (sessionSkills.isEmpty || minutes <= 0) return 0;
    final growthBlock = context.read<GrowthBlock>();
    final projectId = widget.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      return growthBlock.grantSessionXpToProjectSkills(
        projectId: projectId,
        skillNames: sessionSkills,
        minutes: minutes,
        altProjectId: widget.altProjectId,
      );
    }
    return growthBlock.grantSessionXpToMindSkills(
      skillNames: sessionSkills,
      minutes: minutes,
    );
  }

  Future<int> _logSkillSession({
    required MindBlock mindBlock,
    required String personId,
    required String? tenantId,
    required int baseMood,
    required int minutes,
    String? note,
  }) async {
    if (_selected.isEmpty || minutes <= 0) return 0;

    final skills = _selected.toList();
    final boostedMood = _computeBoostedMood(
      baseMood,
      minutes.toDouble(),
      skills.length,
    );
    final activities = <String>[
      ...skills.map((s) => 'skill:$s'),
      'learn:${minutes}m',
    ];
    final projectId = widget.projectId;
    if (projectId != null && projectId.isNotEmpty) {
      activities.add('project:$projectId');
    }
    final trimmedNote = note?.trim();

    await mindBlock.addMindLog(
      moodScore: boostedMood,
      activities: activities,
      note: trimmedNote != null && trimmedNote.isNotEmpty ? trimmedNote : null,
      personId: personId,
      tenantId: tenantId,
    );

    return _grantSkillXpForSession(skills, minutes);
  }

  Future<void> _finishTimedSession({
    required MindBlock mindBlock,
    required String personId,
    required String? tenantId,
    required int baseMood,
    bool forceLog = false,
  }) async {
    final started = _sessionStartedAt;
    _sessionStartedAt = null;
    if (started == null || _isLoggingSession) return;

    final elapsed = DateTime.now().difference(started);
    if (!forceLog && elapsed.inSeconds < 5) return;

    final minutes = (elapsed.inSeconds / 60).ceil().clamp(1, 180);
    _isLoggingSession = true;
    try {
      final growth = context.read<GrowthBlock>();
      final beforeLevels = <String, int>{};
      for (final name in _selected) {
        final row = _skillDataForName(name, growth);
        if (row != null) beforeLevels[name] = row.levelIndex;
      }

      final totalXp = await _logSkillSession(
        mindBlock: mindBlock,
        personId: personId,
        tenantId: tenantId,
        baseMood: baseMood,
        minutes: minutes,
      );
      if (!mounted) return;
      _levelUpController.forward(from: 0);
      await growth.syncSkills();
      if (!mounted) return;

      final leveledUp = <String>[];
      for (final name in _selected) {
        final row = _skillDataForName(name, growth);
        if (row == null) continue;
        final prev = beforeLevels[name] ?? row.levelIndex;
        if (row.levelIndex > prev) leveledUp.add(row.skillName);
      }

      final db = context.read<AppDatabase>();
      final logRows = await (db.select(db.mindLogsTable)
            ..where((t) => t.personID.equals(personId)))
          .get();
      final dayIndex = SkillPracticeStreak.buildDayIndex(logRows);
      var bestStreak = 0;
      for (final name in _selected) {
        final s = SkillPracticeStreak.streakForProtocol(dayIndex, name);
        if (s > bestStreak) bestStreak = s;
      }

      showSkillSessionCelebration(
        context,
        minutes: minutes,
        totalXp: totalXp,
        leveledUpSkills: leveledUp,
        bestStreak: bestStreak,
        practicedSkills: _selected.toList(),
      );
      widget.onSessionLogged?.call();
    } finally {
      _isLoggingSession = false;
    }
  }

  @override
  void dispose() {
    _cancelSessionEndListeners();
    _sessionMusicPlayer.dispose();
    _sfxPlayer.dispose();
    _spinController.dispose();
    _levelUpController.dispose();
    _sessionPulseController.dispose();
    _selectFxController.dispose();
    _tripleRingController.dispose();
    _ringIntroController.dispose();
    _surgeTimer?.cancel();
    super.dispose();
  }

  void _cancelSessionEndListeners() {
    _musicCompleteSub?.cancel();
    _musicCompleteSub = null;
    _sessionFallbackTimer?.cancel();
    _sessionFallbackTimer = null;
  }

  Future<void> _playSessionMusicIfAny() async {
    _cancelSessionEndListeners();
    if (_sessionTracks.isEmpty) {
      _startSessionFallbackTimer();
      return;
    }
    final pick = math.Random().nextInt(_sessionTracks.length);
    _currentSessionTrack = _sessionTracks[pick];
    try {
      await _sessionMusicPlayer.setReleaseMode(ReleaseMode.stop);
      _musicCompleteSub = _sessionMusicPlayer.onPlayerComplete.listen((_) {
        if (!mounted || !_sessionActive) return;
        unawaited(_setSessionActive(false, forceLog: true));
      });
      await _sessionMusicPlayer.setVolume(0.25);
      await _sessionMusicPlayer.play(AssetSource(_currentSessionTrack!));
      final duration = await _sessionMusicPlayer.getDuration();
      if (duration != null && duration > Duration.zero) {
        _sessionFallbackTimer = Timer(duration + const Duration(seconds: 1), () {
          if (!mounted || !_sessionActive) return;
          unawaited(_setSessionActive(false, forceLog: true));
        });
      }
    } catch (_) {
      _startSessionFallbackTimer();
    }
  }

  void _startSessionFallbackTimer() {
    _sessionFallbackTimer?.cancel();
    _sessionFallbackTimer = Timer(
      const Duration(minutes: _fallbackSessionMinutes),
      () {
        if (!mounted || !_sessionActive) return;
        unawaited(_setSessionActive(false, forceLog: true));
      },
    );
  }

  Future<void> _stopSessionMusic() async {
    _cancelSessionEndListeners();
    try {
      await _sessionMusicPlayer.stop();
    } catch (_) {}
    _currentSessionTrack = null;
  }

  Future<void> _playSfxSafe(String asset, {double volume = 1.0}) async {
    try {
      await _sfxPlayer.play(AssetSource(asset), volume: volume);
    } catch (_) {
      // Missing/empty asset should never crash the UI.
    }
  }

  void _triggerTripleRingIfReady() {
    if (_selected.length != 3) return;
    final colors = _selected.take(3).map(_skillColorFor).toList(growable: false);
    setState(() {
      _tripleRingColors = colors;
    });
    _tripleRingController.forward(from: 0);
  }

  void _triggerOrbitRingsIntro(String skill) {
    _lastRingAddedSkill = skill;
    _ringIntroController.forward(from: 0);
  }

  Future<void> _setSessionActive(bool active, {bool forceLog = false}) async {
    if (_sessionActive == active) return;

    if (active && _selected.isEmpty) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mind_skills_session_pick_skills),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final personBlock = context.read<PersonBlock>();
    final mindBlock = context.read<MindBlock>();
    final personId = personBlock.currentPersonID.value;
    final tenantId = personBlock.currentTenantID.value;
    final baseMood = mindBlock.latestMoodLog.value?.moodScore ?? 3;

    if (active) {
      _sessionStartedAt = DateTime.now();
    }

    setState(() => _sessionActive = active);

    // Make the ring feel “powered up” while a session is active.
    _spinController
      ..duration = active
          ? const Duration(milliseconds: 900)
          : const Duration(seconds: 6)
      ..repeat();

    if (active) {
      _sessionPulseController.repeat(reverse: true);
      _levelUpController.forward(from: 0);
      await _playSessionMusicIfAny();
    } else {
      _sessionPulseController.stop();
      await _stopSessionMusic();
      if (personId != null && personId.isNotEmpty) {
        await _finishTimedSession(
          mindBlock: mindBlock,
          personId: personId,
          tenantId: tenantId,
          baseMood: baseMood,
          forceLog: forceLog,
        );
      }
    }
  }

  void _bumpTilePop(String skill) {
    _popTick[skill] = (_popTick[skill] ?? 0) + 1;
  }

  void _triggerRingSurge() {
    _surgeTimer?.cancel();
    // Short “anime surge” on selection: speed up + burst glow.
    _spinController
      ..duration = const Duration(milliseconds: 750)
      ..repeat();
    _levelUpController.forward(from: 0);
    _surgeTimer = Timer(const Duration(milliseconds: 520), () {
      if (!mounted) return;
      // If user is in a started session, keep the faster cadence from session mode.
      _spinController
        ..duration = _sessionActive
            ? const Duration(milliseconds: 900)
            : const Duration(seconds: 6)
        ..repeat();
    });
  }

  int _hashSeed(String s) {
    // Deterministic-ish small hash for effect variance.
    var h = 2166136261;
    for (final code in s.codeUnits) {
      h ^= code;
      h = (h * 16777619) & 0x7fffffff;
    }
    return h == 0 ? 1 : h;
  }

  void _triggerSelectFx(String skill) {
    _selectFxSeed = _hashSeed('$skill:${DateTime.now().millisecondsSinceEpoch}');
    _selectFxController.forward(from: 0);
  }

  Color _skillColorFor(String skill) => SkillCertificatePage.colorForSkill(skill);

  // Element “type” for each skill (ice / water / thunder / fire / wind / nature).
  // This drives ring effect style so it feels consistent (not random).
  int _skillElementFor(String skill) {
    switch (skill.toLowerCase()) {
      case 'focus':
        return 0; // ice
      case 'syntax':
        return 0; // ice
      case 'health':
        return 1; // water
      case 'adaptation':
        return 4; // wind
      case 'logic':
        return 2; // thunder
      case 'meta mental':
        return 2; // thunder
      case 'presentation':
        return 3; // fire
      case 'spirit':
        return 3; // fire
      case 'design':
        return 5; // nature
      case 'growth':
        return 5; // nature
      default:
        // Custom skills: assign “element” from deterministic hash (stable).
        return _hashSeed(skill) % 6;
    }
  }

  Future<void> _ensureCustomSkillsLoaded(String personId) async {
    if (_loadedForPersonId == personId) return;
    _loadedForPersonId = personId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('mind_custom_skills_$personId') ?? const [];
    if (!mounted) return;
    setState(() {
      _customSkills
        ..clear()
        ..addAll(raw.where((s) => s.trim().isNotEmpty));
    });
  }

  Future<void> _ensureHiddenDefaultsLoaded(String personId) async {
    if (_loadedHiddenDefaultsForPersonId == personId) return;
    _loadedHiddenDefaultsForPersonId = personId;
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getStringList('mind_hidden_default_skills_$personId') ?? const [];
    if (!mounted) return;
    setState(() {
      _hiddenDefaultSkillsLower
        ..clear()
        ..addAll(raw.map((s) => s.toLowerCase().trim()).where((s) => s.isNotEmpty));
    });
  }

  Future<void> _persistHiddenDefaults(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'mind_hidden_default_skills_$personId',
      _hiddenDefaultSkillsLower.toList(growable: false),
    );
  }

  Future<void> _ensureSkillIconsLoaded(String personId) async {
    if (_loadedIconsForPersonId == personId) return;
    _loadedIconsForPersonId = personId;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList('mind_skill_icons_$personId') ?? const [];
    final next = <String, int>{};
    for (final entry in raw) {
      final parts = entry.split('|');
      if (parts.length != 2) continue;
      final name = parts[0].trim();
      final cp = int.tryParse(parts[1]);
      if (name.isEmpty || cp == null) continue;
      next[name.toLowerCase()] = cp;
    }
    if (!mounted) return;
    setState(() {
      _iconOverrideCodePoint
        ..clear()
        ..addAll(next);
    });
  }

  Future<void> _editSkillMenu(
    BuildContext context, {
    required String personId,
    required String skill,
  }) async {
    final isCustom = _customSkills.contains(skill);
    final action = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final cs = Theme.of(sheetContext).colorScheme;
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: cs.onSurface.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                Text(
                  skill,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: cs.onSurface.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.palette_rounded),
                  title: const Text('Change icon'),
                  onTap: () => Navigator.of(sheetContext).pop('icon'),
                ),
                ListTile(
                  dense: true,
                  leading: const Icon(Icons.edit_rounded),
                  title: const Text('Edit name'),
                  onTap: () => Navigator.of(sheetContext).pop('edit'),
                ),
                if (isCustom)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.delete_rounded, color: cs.error),
                    title: Text('Delete', style: TextStyle(color: cs.error)),
                    onTap: () => Navigator.of(sheetContext).pop('delete'),
                  ),
              ],
            ),
          ),
        );
      },
    );

    if (action == 'icon') {
      const icons = _skillIconPalette;

      if (!context.mounted) return;
      final picked = await showModalBottomSheet<IconData>(
        context: context,
        useRootNavigator: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          final cs = Theme.of(sheetContext).colorScheme;
          return SafeArea(
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final ic in icons)
                    InkWell(
                      onTap: () => Navigator.of(sheetContext).pop(ic),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.onSurface.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Icon(ic, color: cs.onSurface.withValues(alpha: 0.85)),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );

      if (picked == null) return;
      setState(() {
        _iconOverrideCodePoint[skill.toLowerCase()] = picked.codePoint;
      });
      await _persistSkillIcons(personId);
      return;
    }

    if (action == 'delete') {
      if (!isCustom) return;
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context)!;
      final ok = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.mind_skill_delete_title),
            content: Text(l10n.mind_skill_delete_body(skill)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(l10n.delete),
              ),
            ],
          );
        },
      );
      if (ok != true) return;

      setState(() {
        _customSkills.remove(skill);
        _selected.remove(skill);
        _iconOverrideCodePoint.remove(skill.toLowerCase());
      });
      await _persistCustomSkills(personId);
      await _persistSkillIcons(personId);
      if (mounted) {
        await context
            .read<GrowthBlock>()
            .deletePersonLibrarySkillByName(skill);
      }
      return;
    }

    if (action == 'edit') {
      final l10n = AppLocalizations.of(context)!;
      final controller = TextEditingController(text: skill);
      if (!context.mounted) return;
      final next = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(l10n.mind_skill_edit_title),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: l10n.mind_skills_add_skill,
              ),
              onSubmitted: (_) =>
                  Navigator.of(dialogContext).pop(controller.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: Text(l10n.edit),
              ),
            ],
          );
        },
      );

      final normalized = MindSkillCatalog.normalizeName(next ?? '');
      if (normalized == null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mind_skill_name_invalid),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      if (_allSkills().any(
            (s) =>
                MindSkillCatalog.namesMatch(s, normalized) &&
                !MindSkillCatalog.namesMatch(s, skill),
          )) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mind_skill_name_duplicate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final growth = context.read<GrowthBlock>();
      final renamed = await growth.renamePersonLibrarySkill(skill, normalized);
      if (!renamed) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.mind_skill_name_duplicate),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      setState(() {
        final oldKey = skill.toLowerCase();
        final newKey = normalized.toLowerCase();

        if (isCustom) {
          final idx = _customSkills.indexOf(skill);
          if (idx >= 0) _customSkills[idx] = normalized;
        } else {
          if (!_customSkills.any((s) => MindSkillCatalog.namesMatch(s, normalized))) {
            _customSkills.add(normalized);
          }
          _hiddenDefaultSkillsLower.add(oldKey);
        }

        if (_selected.remove(skill)) _selected.add(normalized);
        final cp = _iconOverrideCodePoint.remove(oldKey);
        if (cp != null) _iconOverrideCodePoint[newKey] = cp;
      });
      await _persistCustomSkills(personId);
      await _persistHiddenDefaults(personId);
      await _persistSkillIcons(personId);
      return;
    }
  }

  Future<void> _persistSkillIcons(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        _iconOverrideCodePoint.entries.map((e) => '${e.key}|${e.value}').toList();
    await prefs.setStringList('mind_skill_icons_$personId', raw);
  }

  IconData _defaultIconForSkill(String label) =>
      SkillCertificatePage.iconForSkill(label);

  IconData _iconForSkill(String label) {
    final cp = _iconOverrideCodePoint[label.toLowerCase()];
    if (cp != null) {
      for (final icon in _skillIconPalette) {
        if (icon.codePoint == cp) return icon;
      }
    }
    return _defaultIconForSkill(label);
  }

  Future<void> _persistCustomSkills(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mind_custom_skills_$personId', _customSkills);
  }

  List<String> _allSkills() {
    return context.read<GrowthBlock>().mindVisibleSkillNames(
      customSkills: _customSkills,
      hiddenDefaultSkillsLower: _hiddenDefaultSkillsLower,
    );
  }

  Future<void> _promptAddSkill(BuildContext context, String personId) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cs.surface.withValues(alpha: 0.95),
          title: Text(l10n.mind_skill_add_title),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'Writing, Memory, Negotiation',
            ),
            onSubmitted: (_) => Navigator.of(dialogContext).pop(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(l10n.add),
            ),
          ],
        );
      },
    );

    final normalized = MindSkillCatalog.normalizeName(result ?? '');
    if (normalized == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mind_skill_name_invalid),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_allSkills().any((s) => MindSkillCatalog.namesMatch(s, normalized))) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.mind_skill_name_duplicate),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _customSkills.add(normalized);
      _selected.add(normalized);
    });
    await _persistCustomSkills(personId);
    if (mounted) {
      await context.read<GrowthBlock>().ensurePersonLibrarySkill(normalized);
    }
  }

  int _computeBoostedMood(int baseMood, double minutes, int selectedCount) {
    final extra = (minutes >= 45 || selectedCount >= 3) ? 2 : 1;
    return (baseMood + extra).clamp(1, 5);
  }

  SkillProtocol? _skillDataForName(String name, GrowthBlock growth) {
    for (final s in growth.personLibrarySkills()) {
      if (MindSkillCatalog.namesMatch(s.skillName, name)) return s;
    }
    return null;
  }

  Future<void> _openSkillCertificate(
    BuildContext context, {
    required String skillName,
    required int accentIndex,
    required bool selected,
  }) async {
    final uri = Uri(
      path: '/social/skills/certificate',
      queryParameters: {
        'skill': skillName,
        'accent': '$accentIndex',
        if (selected) 'selected': '1',
      },
    );
    final wantSelect = await context.push<bool>(uri.toString());
    if (!mounted) return;
    if (wantSelect == true && !_selected.contains(skillName)) {
      _toggleSkillSelection(skillName);
    } else if (wantSelect == false && _selected.contains(skillName)) {
      _toggleSkillSelection(skillName);
    }
  }

  void _toggleSkillSelection(String skill) {
    final selected = _selected.contains(skill);
    setState(() {
      if (selected) {
        _selected.remove(skill);
      } else {
        _selected.add(skill);
        _bumpTilePop(skill);
        _orbitColor = _skillColorFor(skill);
        _triggerOrbitRingsIntro(skill);
      }
    });
    if (!selected) {
      _triggerRingSurge();
      _triggerSelectFx(skill);
      HapticFeedback.lightImpact();
      _playSfxSafe('sounds/select.wav', volume: 0.8);
    }
  }

  String _proficiencyLabel(String raw) {
    if (raw.isEmpty) return 'Beginner';
    return raw[0].toUpperCase() + raw.substring(1);
  }

  Widget _buildOrbitRing(double size, double ringProgress) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _spinController,
        _levelUpController,
        _sessionPulseController,
        _selectFxController,
        _tripleRingController,
        _ringIntroController,
      ]),
      builder: (context, child) {
        final spinMultiplier = _sessionActive ? 2.2 : 1.0;
        final spin = (_spinController.value * math.pi * 2) * spinMultiplier;
        final levelUpBurst =
            Curves.easeOutCubic.transform(_levelUpController.value);
        final sessionPulse = _sessionActive
            ? (0.18 + (0.38 * _sessionPulseController.value))
            : 0.0;
        final burst = (levelUpBurst + sessionPulse).clamp(0.0, 1.0);
        final tripleT = Curves.easeOutCubic.transform(_tripleRingController.value);
        final introT = Curves.easeOutCubic.transform(_ringIntroController.value);

        return RepaintBoundary(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size.square(size),
                  painter: _SkillOrbitPainter(
                    progress: ringProgress,
                    rotation: spin,
                    burst: burst,
                    color: _orbitColor,
                    tripleT: tripleT,
                    tripleColors: _tripleRingColors,
                    selectedSkills: _selected.toList(growable: false),
                    skillColorFor: _skillColorFor,
                    skillElementFor: _skillElementFor,
                    introT: introT,
                    lastAddedSkill: _lastRingAddedSkill,
                  ),
                ),
                if (_selectFxController.value > 0.001)
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size.square(size),
                      painter: _SkillSelectFxPainter(
                        t: _selectFxController.value,
                        seed: _selectFxSeed,
                      ),
                    ),
                  ),
                InkWell(
                  onTap: () async {
                    await _setSessionActive(!_sessionActive, forceLog: false);
                    _triggerTripleRingIfReady();
                  },
                  borderRadius: BorderRadius.circular(48),
                  child: Container(
                    width: size * 0.50,
                    height: size * 0.50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF41E3D0).withValues(alpha: 0.22),
                          blurRadius: 26,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/images/skill_compass_icon.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillStatusList({
    required BuildContext context,
    required String personId,
    required List<String> skillNames,
    required AppLocalizations l10n,
    required ColorScheme colorScheme,
  }) {
    final growth = context.read<GrowthBlock>();
    final mindBlock = context.read<MindBlock>();

    return StreamBuilder<List<MindLogData>>(
      stream: mindBlock.watchMindLogs(personId),
      builder: (context, logSnapshot) {
        final streakIndex =
            SkillPracticeStreak.buildDayIndex(logSnapshot.data ?? []);

        return ListView.separated(
          padding: const EdgeInsets.only(bottom: 8),
          itemCount: skillNames.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            if (index == skillNames.length) {
              return OutlinedButton.icon(
                onPressed: () => _promptAddSkill(context, personId),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.mind_skills_add_skill),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              );
            }

            final name = skillNames[index];
            final data = _skillDataForName(name, growth);
            final selected = _selected.contains(name);
            final streak = SkillPracticeStreak.streakFor(streakIndex, name);
            final accent = _skillColorFor(name);
            final icon = _iconForSkill(name);
            final inSession = _sessionActive && selected;

            return _MindSkillStatusRow(
              name: name,
              skill: data,
              icon: icon,
              accent: accent,
              selected: selected,
              inSession: inSession,
              streak: streak,
              l10n: l10n,
              proficiencyLabel: _proficiencyLabel(
                data?.proficiencyLevel ?? 'beginner',
              ),
              onOpenCertificate: () => _openSkillCertificate(
                context,
                skillName: name,
                accentIndex: index,
                selected: selected,
              ),
              onToggleSession: () => _toggleSkillSelection(name),
              onLongPress: () => _editSkillMenu(
                context,
                personId: personId,
                skill: name,
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Watch((context) {
      final l10n = AppLocalizations.of(context)!;
      final personId =
          context.read<PersonBlock>().currentPersonID.value;
      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      _ensureCustomSkillsLoaded(personId);
      _ensureHiddenDefaultsLoaded(personId);
      _ensureSkillIconsLoaded(personId);

      final skills = _allSkills();
      final ringProgress = _sessionActive
          ? 0.72
          : ((_fallbackSessionMinutes / 90) + (_selected.length / 10))
              .clamp(0.08, 1.0)
              .toDouble();

      final focusTitle = _selected.isEmpty
          ? 'PICK SKILL'
          : (_selected.length == 1
              ? _selected.first.toUpperCase()
              : '${_selected.length} SKILLS');
      final focusSubtitle = _sessionActive
          ? l10n.mind_skills_session_listening
              : _selected.isEmpty
              ? (widget.projectId != null
                  ? l10n.mind_skills_tap_list_project
                  : l10n.mind_skills_tap_list)
              : l10n.mind_skills_session_tap_start;

      final content = SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            children: [
              if (widget.projectId != null) ...[
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: HealthMetricColors.glassChip,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: HealthMetricColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.folder_special_rounded,
                        size: 16,
                        color: colorScheme.primary.withValues(alpha: 0.85),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.projectTitle != null &&
                                  widget.projectTitle!.isNotEmpty
                              ? 'Project · ${widget.projectTitle}'
                              : 'Project skills linked',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface.withValues(alpha: 0.75),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Center(
                child: Text(
                  focusTitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  focusSubtitle,
                  style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: widget.showBackground ? 220 : 168,
                child: Center(child: _buildOrbitRing(
                  widget.showBackground ? 220 : 168,
                  ringProgress,
                )),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.mind_skills_my_list,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: colorScheme.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _buildSkillStatusList(
                  context: context,
                  personId: personId,
                  skillNames: skills,
                  l10n: l10n,
                  colorScheme: colorScheme,
                ),
              ),
          ],
        ),
      ),
    );

      if (!widget.showBackground) return content;

      return Stack(
        children: [
          Container(color: colorScheme.surface),
          content,
        ],
      );
    });
  }
}

class _MindSkillStatusRow extends StatelessWidget {
  const _MindSkillStatusRow({
    required this.name,
    required this.skill,
    required this.icon,
    required this.accent,
    required this.selected,
    required this.inSession,
    required this.streak,
    required this.l10n,
    required this.proficiencyLabel,
    required this.onOpenCertificate,
    required this.onToggleSession,
    required this.onLongPress,
  });

  final String name;
  final SkillProtocol? skill;
  final IconData icon;
  final Color accent;
  final bool selected;
  final bool inSession;
  final int streak;
  final AppLocalizations l10n;
  final String proficiencyLabel;
  final VoidCallback onOpenCertificate;
  final VoidCallback onToggleSession;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final level = skill?.levelIndex ?? 1;
    final xp = skill?.practicePoints ?? 0;
    final xpRemaining = skill?.xpToNextLevel ?? 100;
    final progress = skill?.levelProgress ?? 0.0;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpenCertificate,
        onDoubleTap: onOpenCertificate,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          decoration: BoxDecoration(
            color: selected
                ? accent.withValues(alpha: 0.14)
                : cs.onSurface.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? accent.withValues(alpha: 0.45)
                  : cs.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 40,
                height: 40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 3,
                      backgroundColor: cs.onSurface.withValues(alpha: 0.08),
                      color: accent,
                    ),
                    Icon(icon, size: 18, color: accent),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        if (inSession)
                          _statusChip(
                            l10n.mind_skills_status_in_session,
                            Colors.orange.shade700,
                            Colors.orange.shade50,
                          )
                        else if (selected)
                          _statusChip(
                            l10n.mind_skills_status_selected,
                            cs.primary,
                            cs.primary.withValues(alpha: 0.12),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.mind_skills_level_short(level)} · $proficiencyLabel',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 3,
                        backgroundColor: cs.onSurface.withValues(alpha: 0.06),
                        color: accent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.local_fire_department_rounded,
                          size: 13,
                          color: streak > 0
                              ? Colors.orange.shade600
                              : cs.onSurface.withValues(alpha: 0.25),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          streak > 0
                              ? l10n.project_skill_streak_days(streak)
                              : l10n.project_skill_streak_none,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: streak > 0
                                ? Colors.orange.shade700
                                : cs.onSurface.withValues(alpha: 0.38),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.project_skill_xp_hint(xp, xpRemaining),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: l10n.mind_skill_certificate_select_session,
                onPressed: onToggleSession,
                icon: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? accent : cs.onSurface.withValues(alpha: 0.35),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusChip(String label, Color fg, Color bg) {
    return Container(
      margin: const EdgeInsets.only(left: 6),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: fg,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _SkillTile extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? iconOverride;
  final bool showDeleteHint;
  final int popTick;

  const _SkillTile({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.iconOverride,
    this.showDeleteHint = false,
    this.popTick = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final border = selected
        ? accent.withValues(alpha: 0.55)
        : accent.withValues(alpha: 0.22);
    final bg = selected
        ? accent.withValues(alpha: 0.16)
        : accent.withValues(alpha: 0.08);

    final icon = iconOverride ?? SkillCertificatePage.iconForSkill(label);

    return TweenAnimationBuilder<double>(
      // Using popTick as the key ensures a new pop animation per selection.
      key: ValueKey('skill_pop_${label}_$popTick'),
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 210),
      curve: Curves.easeOutBack,
      builder: (context, t, child) {
        // 0.96 → 1.06 → 1.0 feel
        final scale = 0.96 + (0.10 * t) - (0.06 * (t * t));
        return Transform.scale(scale: scale, child: child);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.22),
                        blurRadius: 18,
                        spreadRadius: 1,
                      ),
                    ]
                  : const [],
            ),
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? accent
                      : accent.withValues(alpha: 0.72),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected
                        ? cs.onSurface
                        : cs.onSurface.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
                if (showDeleteHint) ...[
                  const SizedBox(height: 4),
                  Text(
                    'HOLD',
                    style: TextStyle(
                      color: cs.onSurface.withValues(alpha: 0.35),
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.6,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillOrbitPainter extends CustomPainter {
  final double progress;
  final double rotation;
  final double burst;
  final Color color;
  final double tripleT;
  final List<Color> tripleColors;
  final List<String> selectedSkills;
  final Color Function(String) skillColorFor;
  final int Function(String) skillElementFor;
  final double introT;
  final String? lastAddedSkill;

  _SkillOrbitPainter({
    required this.progress,
    required this.rotation,
    required this.burst,
    required this.color,
    required this.tripleT,
    required this.tripleColors,
    required this.selectedSkills,
    required this.skillColorFor,
    required this.skillElementFor,
    required this.introT,
    required this.lastAddedSkill,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;

    final burstT = burst.clamp(0.0, 1.0);
    final tri = tripleT.clamp(0.0, 1.0);

    // Outer orbit rings (like the reference image)
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = Colors.white.withValues(alpha: 0.18);

    final outerR = r - 6;
    final midR = r - 46;
    final innerR = r - 86;
    final coreR = r - 126;

    Color ringColor(int idx, Color fallback) {
      if (tripleColors.length != 3) return fallback;
      return tripleColors[idx];
    }

    // 4 concentric rings
    final outerC = tri > 0.001
        ? ringColor(0, Colors.white).withValues(alpha: 0.22 + 0.35 * (1 - tri))
        : Colors.white.withValues(alpha: 0.18);
    final midC = tri > 0.001
        ? ringColor(1, const Color(0xFF41E3D0))
            .withValues(alpha: 0.26 + 0.40 * (1 - tri))
        : const Color(0xFF41E3D0).withValues(alpha: 0.22);
    final innerC = tri > 0.001
        ? ringColor(2, Colors.white).withValues(alpha: 0.22 + 0.35 * (1 - tri))
        : Colors.white.withValues(alpha: 0.18);

    final glowRing = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..color = Colors.white.withValues(alpha: 0.0)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);

    // Outer ring
    ringPaint.color = outerC;
    canvas.drawCircle(center, outerR, ringPaint);
    if (tri > 0.001 && tripleColors.length == 3) {
      glowRing.color = ringColor(0, outerC).withValues(alpha: 0.22 * (1 - tri));
      canvas.drawCircle(center, outerR, glowRing);
    }

    // Mid ring
    ringPaint.color = midC;
    canvas.drawCircle(center, midR, ringPaint);
    if (tri > 0.001 && tripleColors.length == 3) {
      glowRing.color = ringColor(1, midC).withValues(alpha: 0.24 * (1 - tri));
      canvas.drawCircle(center, midR, glowRing);
    }

    // Inner ring
    ringPaint.color = innerC;
    canvas.drawCircle(center, innerR, ringPaint);
    if (tri > 0.001 && tripleColors.length == 3) {
      glowRing.color = ringColor(2, innerC).withValues(alpha: 0.22 * (1 - tri));
      canvas.drawCircle(center, innerR, glowRing);
    }

    // Core ring (neutral)
    canvas.drawCircle(
      center,
      coreR,
      ringPaint..color = Colors.white.withValues(alpha: 0.14),
    );

    // Rotating progress arc on the inner ring
    final arcRect = Rect.fromCircle(center: center, radius: innerR);
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6 + (burstT * 5)
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2 + rotation,
        endAngle: (math.pi * 2) - (math.pi / 2) + rotation,
        colors: [
          color.withValues(alpha: 0.10),
          color.withValues(alpha: 0.92),
          color.withValues(alpha: 0.10),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(arcRect);

    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 + (burstT * 14)
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.18 + (0.22 * burstT))
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        20 + (14 * burstT),
      );

    final sweep = (progress.clamp(0.0, 1.0)) * 4.6;
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, glowPaint);
    canvas.drawArc(arcRect, -math.pi / 2, sweep, false, arcPaint);

    // Cut-out segments on the core ring (two gaps like the reference)
    final segRect = Rect.fromCircle(center: center, radius: coreR);
    final segPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.22);
    canvas.drawArc(segRect, -math.pi / 2 + 0.35, 2.15, false, segPaint);
    canvas.drawArc(segRect, math.pi / 2 + 0.55, 2.15, false, segPaint);

    // --- Option A: stacked orbit rings for each selected skill ---
    // Render inside the outer ring but outside the core ring.
    if (selectedSkills.isNotEmpty) {
      final sorted = List<String>.from(selectedSkills)
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      final maxR = outerR - 14;
      final minR = coreR + 18;
      final span = (maxR - minR).clamp(0.0, double.infinity);
      final step = span / math.max(1, sorted.length);

      for (var i = 0; i < sorted.length; i++) {
        final skill = sorted[i];
        final ringR = maxR - (i + 0.5) * step;

        final isIntro = lastAddedSkill != null &&
            skill.toLowerCase() == lastAddedSkill!.toLowerCase();
        final appear = isIntro ? introT : 1.0;
        final alpha = (0.10 + (0.26 * appear)).clamp(0.0, 1.0);

        final c = skillColorFor(skill);
        // Use the element type to choose the ring effect style.
        // Same skill => same “element” => same ring style.
        final mode = skillElementFor(skill) % 5; // 0..4 ring style families
        final baseStroke = (1.4 + (0.8 * appear));

        // Subtle glow (varies per-mode)
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (2.6 + (1.6 * appear)) + (mode == 2 ? 0.8 : 0.0)
          ..color = c.withValues(alpha: (0.10 + (mode == 4 ? 0.04 : 0.0)) * appear)
          ..maskFilter = MaskFilter.blur(
            BlurStyle.normal,
            (10 + (6 * appear)) + (mode == 4 ? 4 : 0),
          );
        canvas.drawCircle(center, ringR, glow);

        // Ring body: each ring gets a different lightweight “effect mode”.
        switch (mode) {
          case 0: // solid ring
            canvas.drawCircle(
              center,
              ringR,
              Paint()
                ..style = PaintingStyle.stroke
                ..strokeWidth = baseStroke
                ..color = c.withValues(alpha: alpha),
            );
            break;
          case 1: // dotted ring
            final dots = 18 + (i % 7);
            final dotPaint = Paint()
              ..style = PaintingStyle.fill
              ..color = c.withValues(alpha: (0.12 + (0.20 * appear)).clamp(0.0, 1.0));
            final dotR = (0.9 + (0.6 * appear));
            final a0 = rotation * (0.40 + (i * 0.03));
            for (var d = 0; d < dots; d++) {
              final a = a0 + (d / dots) * (math.pi * 2);
              final p = Offset(center.dx + math.cos(a) * ringR, center.dy + math.sin(a) * ringR);
              canvas.drawCircle(p, dotR, dotPaint);
            }
            break;
          case 2: // double ring
            final p1 = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = baseStroke + 0.6
              ..color = c.withValues(alpha: alpha);
            final p2 = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = baseStroke
              ..color = c.withValues(alpha: (alpha * 0.55).clamp(0.0, 1.0));
            canvas.drawCircle(center, ringR, p1);
            canvas.drawCircle(center, ringR - 2.2, p2);
            break;
          case 3: // segmented arcs ring
            final rect = Rect.fromCircle(center: center, radius: ringR);
            final segPaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 3.2 + (1.2 * appear)
              ..strokeCap = StrokeCap.round
              ..color = c.withValues(alpha: (0.16 + (0.22 * appear)).clamp(0.0, 1.0));
            final segRot = rotation * (0.35 + (i * 0.04)) + (i * 0.7);
            for (var k = 0; k < 6; k++) {
              final start = (-math.pi / 2) + segRot + (k * (math.pi * 2 / 6));
              canvas.drawArc(rect, start, 0.55, false, segPaint);
            }
            break;
          default: // 4: spark ticks
            final tickPaint = Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.6 + (0.8 * appear)
              ..strokeCap = StrokeCap.round
              ..color = c.withValues(alpha: (0.14 + (0.22 * appear)).clamp(0.0, 1.0));
            final ticks = 10 + (i % 5);
            final a0 = rotation * (0.55 + (i * 0.05)) + (i * 0.3);
            for (var t0 = 0; t0 < ticks; t0++) {
              final a = a0 + (t0 / ticks) * (math.pi * 2);
              final inP = Offset(
                center.dx + math.cos(a) * (ringR - 2.0),
                center.dy + math.sin(a) * (ringR - 2.0),
              );
              final outP = Offset(
                center.dx + math.cos(a) * (ringR + 3.5 + (2.0 * appear)),
                center.dy + math.sin(a) * (ringR + 3.5 + (2.0 * appear)),
              );
              canvas.drawLine(inP, outP, tickPaint);
            }
        }

        // Rotating highlight arc (per-ring speed/phase)
        final rect = Rect.fromCircle(center: center, radius: ringR);
        final phase = (i * 0.9) + (rotation * (0.28 + i * 0.06)) + (mode * 0.25);
        final arcSweep = (0.55 + (0.38 * (1 - (i / sorted.length))) + (mode == 1 ? 0.18 : 0.0))
            .clamp(0.35, 1.2);
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = (mode == 4 ? 3.6 : 3.0) + (0.8 * appear)
          ..strokeCap = StrokeCap.round
          ..shader = SweepGradient(
            startAngle: -math.pi / 2 + phase,
            endAngle: (math.pi * 2) - (math.pi / 2) + phase,
            colors: [
              c.withValues(alpha: 0.0),
              c.withValues(alpha: (0.75 + (mode == 4 ? 0.15 : 0.0)) * appear),
              c.withValues(alpha: 0.0),
            ],
            stops: const [0.0, 0.10, 1.0],
          ).createShader(rect);
        canvas.drawArc(
          rect,
          -math.pi / 2 + phase,
          arcSweep,
          false,
          arcPaint,
        );
      }
    }

    // (Labels removed)
  }

  @override
  bool shouldRepaint(covariant _SkillOrbitPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.rotation != rotation ||
        oldDelegate.burst != burst ||
        oldDelegate.color != color ||
        oldDelegate.tripleT != tripleT ||
        oldDelegate.introT != introT ||
        oldDelegate.lastAddedSkill != lastAddedSkill ||
        oldDelegate.selectedSkills.length != selectedSkills.length;
  }
}

// (Removed unused _GlassCard/_MoodPill after redesign)

class _SkillSelectFxPainter extends CustomPainter {
  final double t; // 0..1
  final int seed;

  _SkillSelectFxPainter({required this.t, required this.seed});

  double _rand01(int n) {
    // Simple LCG-ish deterministic random
    var x = (seed + (n * 1103515245)) & 0x7fffffff;
    x = (x ^ (x >> 16)) & 0x7fffffff;
    return (x % 10000) / 9999.0;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final p = Curves.easeOutCubic.transform(t.clamp(0.0, 1.0));
    final fade = (1.0 - p).clamp(0.0, 1.0);

    // --- Multi-ring “skill-up” circles (varies per skill) ---
    // Base hue shift per seed to give each skill a slightly different tint.
    final hueShift = (_rand01(999) - 0.5) * 0.22; // ~[-0.11..0.11]
    Color tint(Color c, double shift) {
      final hsl = HSLColor.fromColor(c);
      final next = hsl.withHue((hsl.hue + (shift * 360)) % 360);
      return next.toColor();
    }

    final baseColor = tint(const Color(0xFFBFD0FF), hueShift);

    // Ring 1: primary shockwave
    final waveR = (size.shortestSide * 0.18) + (size.shortestSide * 0.30 * p);
    final wavePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + (2 * (1 - p))
      ..color = baseColor.withValues(alpha: 0.38 * fade)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, waveR, wavePaint);

    // Ring 2: segmented arc ring (anime HUD feel)
    final segR = (size.shortestSide * 0.26) + (size.shortestSide * 0.22 * p);
    final segRect = Rect.fromCircle(center: center, radius: segR);
    final segRot = (p * 5.2) + (_rand01(321) * 2.0);
    final segPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2 + segRot,
        endAngle: (math.pi * 2) - (math.pi / 2) + segRot,
        colors: [
          baseColor.withValues(alpha: 0.0),
          baseColor.withValues(alpha: 0.65 * fade),
          baseColor.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.12, 1.0],
      ).createShader(segRect);
    // draw 3 short arcs, gaps between
    for (var k = 0; k < 3; k++) {
      final start = (-math.pi / 2) + (k * 2.1) + (segRot * 0.25);
      canvas.drawArc(segRect, start, 0.78, false, segPaint);
    }

    // Ring 3: thin fast ring (inner tech ring)
    final thinR = (size.shortestSide * 0.16) + (size.shortestSide * 0.20 * p);
    final thinRect = Rect.fromCircle(center: center, radius: thinR);
    final thinRot = (-p * 10.0) + (_rand01(777) * 4.0);
    final thinPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = baseColor.withValues(alpha: 0.42 * fade);
    // dotted effect via multiple micro arcs
    const dots = 14;
    for (var d = 0; d < dots; d++) {
      final a = (-math.pi / 2) +
          (d / dots) * (math.pi * 2) +
          thinRot * 0.22;
      canvas.drawArc(thinRect, a, 0.09, false, thinPaint);
    }

    // Sparks / petals
    final count = 12;
    for (var i = 0; i < count; i++) {
      final a = (_rand01(i) * math.pi * 2) + (p * 0.8);
      final dist = (size.shortestSide * 0.08) +
          (size.shortestSide * (0.30 + 0.12 * _rand01(i + 33)) * p);
      final pos = center + Offset(math.cos(a), math.sin(a)) * dist;

      final len = size.shortestSide * (0.028 + 0.02 * _rand01(i + 7));
      final wid = size.shortestSide * (0.010 + 0.01 * _rand01(i + 19));
      final rot = a + (math.pi / 2) + (0.6 * (0.5 - _rand01(i + 55)));

      final fill = Paint()
        ..color = tint(const Color(0xFFEAF9FF), hueShift * 0.65)
            .withValues(alpha: 0.58 * fade)
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = tint(const Color(0xFF8FD3FF), hueShift * 0.85)
            .withValues(alpha: 0.65 * fade)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;

      final path = Path()
        ..moveTo(0, -len)
        ..lineTo(wid, 0)
        ..lineTo(0, len)
        ..lineTo(-wid, 0)
        ..close();

      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(rot);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
      canvas.restore();
    }

    // Tiny lens flash
    final flashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.18 * fade),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(
          center: center,
          radius: size.shortestSide * (0.45 + 0.15 * p),
        ),
      );
    canvas.drawCircle(
      center,
      size.shortestSide * (0.45 + 0.15 * p),
      flashPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SkillSelectFxPainter oldDelegate) {
    return oldDelegate.t != t || oldDelegate.seed != seed;
  }
}

