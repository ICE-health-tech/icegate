import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/WhiteboardPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/entry/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/ProjectsWhiteboardCanvas.dart';
import 'package:provider/provider.dart';

/// Personal scratch whiteboard — opens directly from Projects hub (no project pick).
class ProjectsWhiteboardPage extends StatefulWidget {
  const ProjectsWhiteboardPage({super.key});

  @override
  State<ProjectsWhiteboardPage> createState() => _ProjectsWhiteboardPageState();
}

class _ProjectsWhiteboardPageState extends State<ProjectsWhiteboardPage> {
  static const _penColors = [
    Color(0xFF111827),
    EntryColors.projectBlue,
    Color(0xFFDC2626),
    Color(0xFF16A34A),
    Color(0xFF9333EA),
  ];

  List<WhiteboardStroke> _strokes = const [];
  Color _penColor = _penColors.first;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadBoard());
  }

  Future<void> _loadBoard() async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    final doc = await WhiteboardPrefs.load(personId);
    if (!mounted) return;
    setState(() {
      _strokes = List<WhiteboardStroke>.from(doc.strokes);
      _loaded = true;
    });
  }

  Future<void> _persist(List<WhiteboardStroke> strokes) async {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    await WhiteboardPrefs.save(
      personId,
      WhiteboardDocument(strokes: strokes),
    );
  }

  void _onStrokesChanged(List<WhiteboardStroke> strokes) {
    setState(() => _strokes = strokes);
    _persist(strokes);
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    final next = List<WhiteboardStroke>.from(_strokes)..removeLast();
    _onStrokesChanged(next);
  }

  Future<void> _clearAll(AppLocalizations l10n) async {
    if (_strokes.isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.projects_whiteboard_clear_title),
        content: Text(l10n.projects_whiteboard_clear_message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.projects_whiteboard_clear_confirm),
          ),
        ],
      ),
    );
    if (ok == true && mounted) _onStrokesChanged(const []);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final boardColor = isDark
        ? cs.surfaceContainerLow.withValues(alpha: 0.92)
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: boardColor,
      appBar: AppBar(
        backgroundColor: boardColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(l10n.projects_tile_whiteboard),
        actions: [
          IconButton(
            tooltip: l10n.undo,
            icon: const Icon(Icons.undo_rounded),
            onPressed: _strokes.isEmpty ? null : _undo,
          ),
          IconButton(
            tooltip: l10n.projects_whiteboard_clear_title,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: _strokes.isEmpty ? null : () => _clearAll(l10n),
          ),
        ],
      ),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                    child: ProjectsWhiteboardCanvas(
                      strokes: _strokes,
                      penColor: _penColor,
                      penWidth: 3,
                      boardColor: boardColor,
                      isDark: isDark,
                      onStrokesChanged: _onStrokesChanged,
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final color in _penColors)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: _ColorDot(
                              color: color,
                              selected: _penColor == color,
                              onTap: () => setState(() => _penColor = color),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: selected ? 32 : 26,
        height: selected ? 32 : 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
      ),
    );
  }
}
