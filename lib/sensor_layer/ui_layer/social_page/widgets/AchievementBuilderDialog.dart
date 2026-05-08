import 'dart:math' as math;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class AchievementBuilderDialog extends StatefulWidget {
  final BuildContext parentContext;
  final AchievementData? initialData;

  const AchievementBuilderDialog({super.key, required this.parentContext, this.initialData});

  static Future<void> show(BuildContext context, {AchievementData? initialData}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AchievementBuilderDialog(parentContext: context, initialData: initialData),
    );
  }

  @override
  State<AchievementBuilderDialog> createState() =>
      _AchievementBuilderDialogState();
}

class _AchievementBuilderDialogState extends State<AchievementBuilderDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _impactWhoController = TextEditingController();

  String _selectedDomain = 'project';
  int _meaningScore = 5;
  int _impactScore = 0;

  final List<String> _domains = [
    'health',
    'finance',
    'good social impact',
    'relationship',
    'project',
    'knowledge'
  ];

  static const double _radius = 20;

  OutlineInputBorder _fieldBorder(ColorScheme cs) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.45)),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final a = widget.initialData!;
      _titleController.text = a.title;
      _descriptionController.text = a.description ?? "";
      _selectedDomain = a.domain;
      _meaningScore = a.meaningScore ?? 5;
      _impactScore = a.impactScore;
      _impactWhoController.text = a.impactDescWho;
    }
  }

  /// `title` column requires min length 1 — use a dash placeholder when left blank for fast saves.
  static const _emptyTitlePlaceholder = '—';

  String get _resolvedTitle {
    final t = _titleController.text.trim();
    return t.isEmpty ? _emptyTitlePlaceholder : t;
  }

  Future<void> _saveAchievement() async {
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.currentPersonID.value;
    final dao = context.read<AchievementsDAO>();

    if (widget.initialData != null) {
      final updated = widget.initialData!.copyWith(
        title: _resolvedTitle,
        description: drift.Value(_descriptionController.text.trim()),
        domain: _selectedDomain,
        meaningScore: drift.Value(_meaningScore),
        impactScore: _impactScore,
        impactDescWho: _impactWhoController.text.trim(),
        impactDescHow: widget.initialData!.impactDescHow,
      );
      await dao.updateAchievement(updated);
    } else {
      final entry = AchievementsTableCompanion(
        id: drift.Value(IDGen.UUIDV7()),
        personID: drift.Value(personId),
        title: drift.Value(_resolvedTitle),
        description: drift.Value(_descriptionController.text.trim()),
        domain: drift.Value(_selectedDomain),
        meaningScore: drift.Value(_meaningScore),
        impactScore: drift.Value(_impactScore),
        impactDescWho: drift.Value(_impactWhoController.text.trim()),
        impactDescHow: drift.Value(''),
      );
      await dao.insertAchievement(entry);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _impactWhoController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title, {bool isMandatory = false}) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
                height: 1.25,
              ),
            ),
          ),
          if (isMandatory)
            Text(
              '*',
              style: TextStyle(
                color: cs.error,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(ColorScheme cs, String label, {int maxLines = 1}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surface.withValues(alpha: 0.55),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: _fieldBorder(cs),
      enabledBorder: _fieldBorder(cs),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary, width: 1.5),
      ),
      labelStyle: TextStyle(color: cs.onSurfaceVariant, fontSize: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);
    final maxH = mq.size.height * 0.88;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: Material(
        color: cs.surfaceContainerHigh,
        elevation: 16,
        shadowColor: Colors.black.withValues(alpha: 0.55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_radius),
          side: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 440,
            maxHeight: maxH,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initialData != null ? "Edit Achievement" : "Log Achievement",
                        style: TextStyle(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 19,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(Icons.close_rounded, color: cs.onSurfaceVariant),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: MaterialLocalizations.of(context).cancelButtonLabel,
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: cs.outline.withValues(alpha: 0.28)),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _titleController,
                        onChanged: (_) => setState(() {}),
                        style: TextStyle(color: cs.onSurface, fontSize: 16),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _fieldDecoration(cs, "What did you accomplish? (optional)"),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 3,
                        style: TextStyle(color: cs.onSurface, fontSize: 15),
                        textCapitalization: TextCapitalization.sentences,
                        decoration: _fieldDecoration(cs, "Description (Optional)", maxLines: 3),
                      ),
                      _buildSectionTitle("Domain Tag", isMandatory: true),
                      LayoutBuilder(
                        builder: (context, bc) {
                          const spacing = 8.0;
                          const runSpacing = 8.0;
                          final maxW = bc.maxWidth;
                          return Wrap(
                            spacing: spacing,
                            runSpacing: runSpacing,
                            children: _domains.map((d) {
                              final isSelected = _selectedDomain == d;
                              return ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: math.min(104, (maxW - spacing) / 2),
                                ),
                                child: FilterChip(
                                  showCheckmark: true,
                                  checkmarkColor: cs.onPrimary,
                                  selectedColor: cs.primary,
                                  backgroundColor: cs.surface.withValues(alpha: 0.5),
                                  side: BorderSide(
                                    color: isSelected
                                        ? cs.primary
                                        : cs.outline.withValues(alpha: 0.55),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                  label: Text(
                                    d,
                                    style: TextStyle(
                                      color: isSelected ? cs.onPrimary : cs.onSurface,
                                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                      fontSize: 12.5,
                                      height: 1.2,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  selected: isSelected,
                                  onSelected: (val) {
                                    if (val) setState(() => _selectedDomain = d);
                                  },
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                      _buildSectionTitle("Internal Meaningfulness (1-10)", isMandatory: true),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.primaryContainer.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$_meaningScore',
                              style: TextStyle(
                                color: cs.onPrimaryContainer,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Slider(
                              value: _meaningScore.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _meaningScore.toString(),
                              onChanged: (val) => setState(() => _meaningScore = val.toInt()),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: cs.primaryContainer.withValues(alpha: 0.28),
                          border: Border.all(color: cs.primary.withValues(alpha: 0.55)),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.08),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.public_rounded, color: cs.primary, size: 22),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    "Philosophy Check: Impact on Others",
                                    style: TextStyle(
                                      color: cs.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      height: 1.25,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Reflect on how your actions affected others (optional details below).",
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              "Impact Score (1-10)",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurface,
                                fontSize: 14,
                              ),
                            ),
                            Row(
                              children: [
                                SizedBox(
                                  width: 52,
                                  child: Text(
                                    _impactScore == 0 ? "—" : '$_impactScore',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Slider(
                                    value: _impactScore.toDouble(),
                                    min: 0,
                                    max: 10,
                                    divisions: 10,
                                    label: _impactScore == 0 ? "Not rated" : _impactScore.toString(),
                                    onChanged: (val) => setState(() => _impactScore = val.toInt()),
                                  ),
                                ),
                              ],
                            ),
                            TextField(
                              controller: _impactWhoController,
                              onChanged: (_) => setState(() {}),
                              style: TextStyle(color: cs.onSurface, fontSize: 15),
                              decoration: _fieldDecoration(cs, "Who did this help? (optional)"),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: mq.padding.bottom > 0 ? 8 : 16),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                minimum: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _saveAchievement,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 2,
                          shadowColor: Colors.black.withValues(alpha: 0.35),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          widget.initialData != null ? "Save Changes" : "Log Win",
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: cs.onSurfaceVariant,
                        ),
                        child: const Text("Cancel", style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
