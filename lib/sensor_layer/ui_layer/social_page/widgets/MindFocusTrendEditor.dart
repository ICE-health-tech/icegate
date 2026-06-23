import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/MindFocusTrendPrefs.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ActivitySelector.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

class MindFocusTrendEditor extends StatefulWidget {
  final MindFocusTrend? existing;
  final void Function(MindFocusTrend trend) onSave;
  final VoidCallback? onDelete;

  const MindFocusTrendEditor({
    super.key,
    this.existing,
    required this.onSave,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    MindFocusTrend? existing,
    required void Function(MindFocusTrend trend) onSave,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => MindFocusTrendEditor(
        existing: existing,
        onSave: onSave,
        onDelete: onDelete,
      ),
    );
  }

  /// Clearance for [MainShell] Dynamic Island (SafeArea + 54px slot + gap).
  static double _mainShellTopClearance(BuildContext context, {double gap = 8}) {
    const islandSlotHeight = 54.0;
    return MediaQuery.paddingOf(context).top + islandSlotHeight + gap;
  }

  @override
  State<MindFocusTrendEditor> createState() => _MindFocusTrendEditorState();
}

class _MindFocusTrendEditorState extends State<MindFocusTrendEditor> {
  late final TextEditingController _nameController;
  late List<String> _selectedTokens;
  late int _weeklyGoal;
  late int _iconCodePoint;
  late int _colorArgb;
  String? _linkedProjectId;

  static const _noProject = '__none__';

  static const _iconChoices = [
    Icons.fitness_center_rounded,
    Icons.school_rounded,
    Icons.trending_up_rounded,
    Icons.psychology_rounded,
    Icons.payments_rounded,
    Icons.self_improvement_rounded,
    Icons.menu_book_rounded,
    Icons.track_changes_rounded,
  ];

  static const _colorChoices = [
    0xFF66BB6A,
    0xFF42A5F5,
    0xFFFFB74D,
    0xFFAB47BC,
    0xFFEF5350,
    0xFF26C6DA,
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameController = TextEditingController(text: e?.name ?? '');
    _selectedTokens = List<String>.from(e?.activityTokens ?? []);
    _weeklyGoal = e?.weeklyGoal ?? 3;
    _iconCodePoint =
        e?.iconCodePoint ?? Icons.track_changes_rounded.codePoint;
    _colorArgb = e?.colorArgb ?? _colorChoices[1];
    _linkedProjectId = e?.linkedProjectId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _toggleToken(String token) {
    setState(() {
      if (_selectedTokens.contains(token)) {
        _selectedTokens.remove(token);
      } else {
        _selectedTokens.add(token);
      }
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mind_focus_name_required)),
      );
      return;
    }
    if (_selectedTokens.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mind_focus_activities_required)),
      );
      return;
    }
    widget.onSave(
      MindFocusTrend(
        id: widget.existing?.id ?? IDGen.UUIDV7(),
        name: name,
        iconCodePoint: _iconCodePoint,
        activityTokens: List<String>.from(_selectedTokens),
        weeklyGoal: _weeklyGoal.clamp(1, 14),
        colorArgb: _colorArgb,
        linkedProjectId: _linkedProjectId,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final topClearance = MindFocusTrendEditor._mainShellTopClearance(context);
    final screenH = MediaQuery.sizeOf(context).height;
    final sheetHeight = (screenH - topClearance - 24).clamp(320.0, screenH * 0.88);

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        margin: EdgeInsets.fromLTRB(12, topClearance, 12, 12),
        height: sheetHeight,
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
        ),
        child: Column(
          children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.existing == null
                            ? l10n.mind_focus_add
                            : l10n.mind_focus_edit,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (widget.onDelete != null)
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onDelete!();
                        },
                        icon: Icon(Icons.delete_outline, color: cs.error),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: l10n.mind_focus_name_hint,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Watch((context) {
                        final projects = context
                            .watch<ProjectBlock>()
                            .projects
                            .value
                            .where((p) => p.status == 0)
                            .rootsOnly
                            .toList();
                        if (projects.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return DropdownButtonFormField<String>(
                          value: projects.any(
                            (p) =>
                                ProjectBlock.linkId(p) == _linkedProjectId ||
                                p.id == _linkedProjectId,
                          )
                              ? _linkedProjectId
                              : _noProject,
                          decoration: InputDecoration(
                            labelText: l10n.mind_focus_linked_project,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: _noProject,
                              child: Text(l10n.mind_focus_linked_project_none),
                            ),
                            for (final p in projects)
                              DropdownMenuItem(
                                value: ProjectBlock.linkId(p),
                                child: Text(p.name),
                              ),
                          ],
                          onChanged: (v) => setState(
                            () => _linkedProjectId =
                                v == null || v == _noProject ? null : v,
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Text(
                        l10n.mind_focus_icon_label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _iconChoices.map((icon) {
                          final selected = icon.codePoint == _iconCodePoint;
                          return ChoiceChip(
                            selected: selected,
                            label: Icon(icon, size: 20),
                            onSelected: (_) => setState(
                              () => _iconCodePoint = icon.codePoint,
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.mind_focus_color_label,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        children: _colorChoices.map((argb) {
                          final selected = argb == _colorArgb;
                          return GestureDetector(
                            onTap: () => setState(() => _colorArgb = argb),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(argb),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: selected
                                      ? cs.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              l10n.mind_focus_weekly_goal,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          IconButton(
                            onPressed: _weeklyGoal > 1
                                ? () => setState(() => _weeklyGoal--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Text(
                            '$_weeklyGoal',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          IconButton(
                            onPressed: _weeklyGoal < 14
                                ? () => setState(() => _weeklyGoal++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mind_focus_activities_label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...ActivitySelector.categories.entries.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: cat.value.map((act) {
                              final token = act['name'] as String;
                              final icon = act['icon'] as IconData;
                              final selected = _selectedTokens.contains(token);
                              return FilterChip(
                                selected: selected,
                                avatar: Icon(icon, size: 16),
                                label: Text(
                                  MindActivityTokens.presetLabel(l10n, token),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                onSelected: (_) => _toggleToken(token),
                              );
                            }).toList(),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _submit,
                    child: Text(l10n.mind_focus_save),
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }
}
