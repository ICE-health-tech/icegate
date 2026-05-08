import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_music/ice_music.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';

class MindSkillsPage extends StatelessWidget {
  const MindSkillsPage({super.key});

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
      body: const MindSkillsView(showBackground: true, popOnSave: true),
    );
  }
}

class MindSkillsView extends StatefulWidget {
  final bool showBackground;
  final bool popOnSave;

  const MindSkillsView({
    super.key,
    required this.showBackground,
    required this.popOnSave,
  });

  @override
  State<MindSkillsView> createState() => _MindSkillsViewState();
}

class _MindSkillsViewState extends State<MindSkillsView>
    with TickerProviderStateMixin {
  final AudioPlayer _sfxPlayer = AudioPlayer();
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
  late final AnimationController _selectFxController;
  int _selectFxSeed = 1;
  late final AnimationController _tripleRingController;
  List<Color> _tripleRingColors = const [];
  late final AnimationController _ringIntroController;
  String? _lastRingAddedSkill;

  static const _defaultSkills = <String>[
    'Meta Mental',
    'Adaptation',
    'Health',
    'Presentation',
    'Focus',
    'Logic',
    'Design',
    'Syntax',
    'Growth',
    'Spirit',
  ];
  final List<String> _customSkills = [];
  String? _loadedForPersonId;
  String? _loadedIconsForPersonId;
  String? _loadedHiddenDefaultsForPersonId;
  final Set<String> _hiddenDefaultSkillsLower = <String>{};
  final Map<String, int> _iconOverrideCodePoint = <String, int>{};
  final Map<String, int> _popTick = <String, int>{};
  Timer? _surgeTimer;
  Color _orbitColor = const Color(0xFFBFD0FF);

  final _noteController = TextEditingController();
  final Set<String> _selected = <String>{};
  double _minutes = 25;

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
  void dispose() {
    _sfxPlayer.dispose();
    _spinController.dispose();
    _levelUpController.dispose();
    _sessionPulseController.dispose();
    _selectFxController.dispose();
    _tripleRingController.dispose();
    _ringIntroController.dispose();
    _surgeTimer?.cancel();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _playSessionMusicIfAny() async {
    if (_sessionTracks.isEmpty) return;
    final pick = math.Random().nextInt(_sessionTracks.length);
    _currentSessionTrack = _sessionTracks[pick];
    try {
      await IceMusic.instance.playLoopAsset(_currentSessionTrack!, volume: 0.25);
    } catch (_) {
      // If the asset is missing, just ignore (UI/animations still work).
    }
  }

  Future<void> _stopSessionMusic() async {
    try {
      await IceMusic.instance.stop();
    } catch (_) {}
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

  Future<void> _setSessionActive(bool active) async {
    if (_sessionActive == active) return;
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

  Color _skillColorFor(String skill) {
    switch (skill.toLowerCase()) {
      case 'focus':
        return const Color(0xFF41E3D0);
      case 'logic':
        return const Color(0xFF8C7BFF);
      case 'design':
        return const Color(0xFFFF7FD1);
      case 'syntax':
        return const Color(0xFF56C0FF);
      case 'growth':
        return const Color(0xFF9BE15D);
      case 'health':
        return const Color(0xFF5AF2B0);
      case 'presentation':
        return const Color(0xFFFFD66B);
      case 'adaptation':
        return const Color(0xFF53E1FF);
      case 'meta mental':
        return const Color(0xFFB794F4);
      case 'spirit':
        return const Color(0xFFFF9A6B);
      default:
        // Fallback: derive from hash
        final h = _hashSeed(skill) % 360;
        return HSLColor.fromAHSL(1.0, h.toDouble(), 0.72, 0.55).toColor();
    }
  }

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
      final icons = <IconData>[
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
      ];

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
      final ok = await showDialog<bool>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Delete skill?'),
            content: Text('Remove “$skill” from your skills?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: const Text('Delete'),
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
      return;
    }

    if (action == 'edit') {
      final controller = TextEditingController(text: skill);
      if (!context.mounted) return;
      final next = await showDialog<String>(
        context: context,
        useRootNavigator: true,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Edit skill'),
            content: TextField(
              controller: controller,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(hintText: 'Skill name'),
              onSubmitted: (_) =>
                  Navigator.of(dialogContext).pop(controller.text),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );

      final normalized = (next ?? '').trim();
      if (normalized.isEmpty) return;
      final lower = normalized.toLowerCase();
      final alreadyExists = _allSkills().any((s) => s.toLowerCase() == lower);
      if (alreadyExists && lower != skill.toLowerCase()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('That skill already exists.'),
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
          // Rename a default skill by hiding the default and creating a custom replacement.
          if (!_customSkills.any((s) => s.toLowerCase() == newKey)) {
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

  IconData _defaultIconForSkill(String label) {
    return switch (label.toLowerCase()) {
      'focus' => Icons.center_focus_strong_rounded,
      'logic' => Icons.functions_rounded,
      'design' => Icons.brush_rounded,
      'syntax' => Icons.code_rounded,
      'growth' => Icons.trending_up_rounded,
      'health' => Icons.favorite_rounded,
      'presentation' => Icons.record_voice_over_rounded,
      'adaptation' => Icons.autorenew_rounded,
      'meta mental' => Icons.psychology_alt_rounded,
      'spirit' => Icons.auto_awesome_rounded,
      _ => Icons.auto_awesome_mosaic_rounded,
    };
  }

  IconData _iconForSkill(String label) {
    final cp = _iconOverrideCodePoint[label.toLowerCase()];
    if (cp != null) {
      return IconData(cp, fontFamily: 'MaterialIcons');
    }
    return _defaultIconForSkill(label);
  }

  Future<void> _persistCustomSkills(String personId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('mind_custom_skills_$personId', _customSkills);
  }

  List<String> _allSkills() => [
        ..._defaultSkills.where(
          (s) => !_hiddenDefaultSkillsLower.contains(s.toLowerCase()),
        ),
        ..._customSkills,
      ];

  Future<void> _promptAddSkill(BuildContext context, String personId) async {
    final controller = TextEditingController();
    final cs = Theme.of(context).colorScheme;

    final result = await showDialog<String>(
      context: context,
      useRootNavigator: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: cs.surface.withValues(alpha: 0.95),
          title: const Text('Add a skill'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              hintText: 'e.g. Writing, Memory, Negotiation',
            ),
            onSubmitted: (_) => Navigator.of(dialogContext).pop(controller.text),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    final name = (result ?? '').trim();
    if (name.isEmpty) return;

    // Normalize: collapse spaces, cap length
    final normalized = name.replaceAll(RegExp(r'\s+'), ' ');
    if (normalized.length > 24) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Skill name too long (max 24 chars).'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final exists = _allSkills()
        .any((s) => s.toLowerCase() == normalized.toLowerCase());
    if (exists) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('That skill already exists.'),
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
  }

  int _computeBoostedMood(int baseMood, double minutes, int selectedCount) {
    final extra = (minutes >= 45 || selectedCount >= 3) ? 2 : 1;
    return (baseMood + extra).clamp(1, 5);
  }

  Future<void> _openSessionSheet({
    required BuildContext context,
    required MindBlock mindBlock,
    required String personId,
    required String? tenantId,
    required int baseMood,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final colorScheme = Theme.of(sheetContext).colorScheme;
        final boosted =
            _computeBoostedMood(baseMood, _minutes, _selected.length);

        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.38),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                colorScheme.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: colorScheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'START SESSION'.toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                '${_selected.length} skills • ${_minutes.round()} min',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color:
                                  colorScheme.primary.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Text(
                            'MOOD → $boosted',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'DURATION'.toUpperCase(),
                      style: TextStyle(
                        color:
                            colorScheme.onSurface.withValues(alpha: 0.55),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    Slider(
                      value: _minutes,
                      min: 5,
                      max: 120,
                      divisions: 23,
                      label: '${_minutes.round()} min',
                      onChanged: (v) => setState(() => _minutes = v),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _noteController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'What did you learn?',
                        filled: true,
                        fillColor:
                            colorScheme.onSurface.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color:
                                colorScheme.onSurface.withValues(alpha: 0.10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _selected.isEmpty
                            ? null
                            : () async {
                                final boostedMood = _computeBoostedMood(
                                  baseMood,
                                  _minutes,
                                  _selected.length,
                                );
                                final activities = <String>[
                                  ..._selected.map((s) => 'skill:$s'),
                                  'learn:${_minutes.round()}m',
                                ];
                                await mindBlock.addMindLog(
                                  moodScore: boostedMood,
                                  activities: activities,
                                  note: _noteController.text.trim(),
                                  personId: personId,
                                  tenantId: tenantId,
                                );
                                if (!mounted) return;
                                _levelUpController.forward(from: 0);
                                Navigator.of(sheetContext).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Skill session logged.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                if (widget.popOnSave && context.canPop()) {
                                  context.pop();
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colorScheme.primary,
                          foregroundColor: colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'LOG SESSION',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Watch((context) {
      final personBlock = context.read<PersonBlock>();
      final mindBlock = context.read<MindBlock>();

      final personId = personBlock.currentPersonID.value;
      final tenantId = personBlock.currentTenantID.value;
      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }
      _ensureCustomSkillsLoaded(personId);
      _ensureHiddenDefaultsLoaded(personId);
      _ensureSkillIconsLoaded(personId);

      final baseMood = mindBlock.latestMoodLog.value?.moodScore ?? 3;

      final skills = _allSkills();
      final ringProgress = ((_minutes / 90) + (_selected.length / 10))
          .clamp(0.08, 1.0)
          .toDouble();

      final content = SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            children: [
              Center(
                child: Text(
                  'ASCEND',
                  style: TextStyle(
                    color: colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text(
                  'SKILL'.toUpperCase(),
                  style: TextStyle(
                    color: colorScheme.primary.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Make the ring bigger and keep skills row lower.
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
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
                      final spin =
                          (_spinController.value * math.pi * 2) * spinMultiplier;

                      final levelUpBurst =
                          Curves.easeOutCubic.transform(_levelUpController.value);
                      final sessionPulse = _sessionActive
                          ? (0.18 + (0.38 * _sessionPulseController.value))
                          : 0.0;
                      final burst = (levelUpBurst + sessionPulse).clamp(0.0, 1.0);
                      final tripleT = Curves.easeOutCubic.transform(
                        _tripleRingController.value,
                      );
                      final introT = Curves.easeOutCubic.transform(
                        _ringIntroController.value,
                      );

                      return RepaintBoundary(
                        child: SizedBox(
                          width: 320,
                          height: 320,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size.square(320),
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
                                    size: const Size.square(320),
                                    painter: _SkillSelectFxPainter(
                                      t: _selectFxController.value,
                                      seed: _selectFxSeed,
                                    ),
                                  ),
                                ),
                              if (burst > 0.001)
                                Opacity(
                                  opacity: (1 - burst).clamp(0.0, 1.0),
                                  child: Transform.scale(
                                    scale: 1.0 + (burst * 0.12),
                                    child: Container(
                                      width: 260,
                                      height: 260,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFBFD0FF)
                                                .withValues(alpha: 0.28),
                                            blurRadius: 38,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                              // Center icon
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      await _setSessionActive(!_sessionActive);
                                      _triggerTripleRingIfReady();
                                    },
                                    onLongPress: () => _openSessionSheet(
                                      context: context,
                                      mindBlock: mindBlock,
                                      personId: personId,
                                      tenantId: tenantId,
                                      baseMood: baseMood,
                                    ),
                                    borderRadius: BorderRadius.circular(48),
                                    child: Container(
                                      width: 70,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF41E3D0)
                                                .withValues(alpha: 0.22),
                                            blurRadius: 26,
                                            spreadRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Image.asset(
                                        'assets/images/iceflowerlogo.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                height: 98,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  itemCount: skills.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, idx) {
                    if (idx == skills.length) {
                    return SizedBox(
                        width: 86,
                        child: _SkillTile(
                          label: 'New',
                          selected: false,
                          onTap: () => _promptAddSkill(context, personId),
                          iconOverride: Icons.add_rounded,
                        ),
                      );
                    }

                    final s = skills[idx];
                    final selected = _selected.contains(s);
                    return SizedBox(
                      width: 86,
                      child: _SkillTile(
                        label: s,
                        selected: selected,
                        popTick: _popTick[s] ?? 0,
                        onTap: () {
                          setState(() {
                            if (selected) {
                              _selected.remove(s);
                            } else {
                              _selected.add(s);
                              _bumpTilePop(s);
                              _orbitColor = _skillColorFor(s);
                              _triggerOrbitRingsIntro(s);
                            }
                          });
                          if (!selected) {
                            _triggerRingSurge();
                            _triggerSelectFx(s);
                            HapticFeedback.lightImpact();
                            _playSfxSafe('sounds/select.wav', volume: 0.8);
                          }
                        },
                      onLongPress: () => _editSkillMenu(
                          context,
                          personId: personId,
                          skill: s,
                        ),
                      iconOverride: _iconForSkill(s),
                        showDeleteHint: _customSkills.contains(s),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );

      if (!widget.showBackground) return content;

      return Stack(
        children: [
          Container(
            color: isDark ? const Color(0xFF0A0A0E) : const Color(0xFFF0F2F5),
          ),
          content,
        ],
      );
    });
  }
}

class _SkillTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final IconData? iconOverride;
  final bool showDeleteHint;
  final int popTick;

  const _SkillTile({
    required this.label,
    required this.selected,
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
        ? const Color(0xFFBFD0FF).withValues(alpha: 0.55)
        : cs.onSurface.withValues(alpha: 0.10);
    final bg = selected
        ? const Color(0xFFBFD0FF).withValues(alpha: 0.12)
        : cs.surface.withValues(alpha: 0.12);

    final icon = iconOverride ??
        switch (label.toLowerCase()) {
      'focus' => Icons.center_focus_strong_rounded,
      'logic' => Icons.functions_rounded,
      'design' => Icons.brush_rounded,
      'syntax' => Icons.code_rounded,
      'growth' => Icons.trending_up_rounded,
      'health' => Icons.favorite_rounded,
      'presentation' => Icons.record_voice_over_rounded,
      'adaptation' => Icons.autorenew_rounded,
      'meta mental' => Icons.psychology_alt_rounded,
      'spirit' => Icons.auto_awesome_rounded,
      _ => Icons.auto_awesome_mosaic_rounded,
    };

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
                        color: const Color(0xFFBFD0FF).withValues(alpha: 0.18),
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
                      ? const Color(0xFFBFD0FF)
                      : cs.onSurface.withValues(alpha: 0.65),
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

