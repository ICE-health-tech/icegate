import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class AchievementBuilderDialog extends StatefulWidget {
  final BuildContext parentContext;
  final AchievementData? initialData;

  const AchievementBuilderDialog({super.key, required this.parentContext, this.initialData});

  static Future<void> show(BuildContext context, {AchievementData? initialData}) {
    return showDialog(
      context: context,
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
      // Edit mode
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
      // Create mode
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
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          if (isMandatory) ...[
            const SizedBox(width: 4),
            Text(
              '*',
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            )
          ]
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      title: Text(
        widget.initialData != null ? "Edit Achievement" : "Log Achievement",
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w900,
          letterSpacing: 1,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              onChanged: (_) => setState(() {}),
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: "What did you accomplish? (optional)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              decoration: const InputDecoration(
                labelText: "Description (Optional)",
                border: OutlineInputBorder(),
              ),
            ),
            _buildSectionTitle("Domain Tag", isMandatory: true),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _domains.map((d) {
                final isSelected = _selectedDomain == d;
                return ChoiceChip(
                  label: Text(d),
                  selected: isSelected,
                  onSelected: (val) {
                    if (val) setState(() => _selectedDomain = d);
                  },
                );
              }).toList(),
            ),
            _buildSectionTitle("Internal Meaningfulness (1-10)", isMandatory: true),
            Slider(
              value: _meaningScore.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              label: _meaningScore.toString(),
              onChanged: (val) => setState(() => _meaningScore = val.toInt()),
            ),
            
            
            // MANDATORY PHILOSOPHY SECTION
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Philosophy Check: Impact on Others",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Reflect on how your actions affected others (optional details below).",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Impact Score (1-10)", style: TextStyle(fontWeight: FontWeight.bold)),
                  Slider(
                    value: _impactScore.toDouble(),
                    min: 0,
                    max: 10,
                    divisions: 10,
                    label: _impactScore == 0 ? "Not Rated" : _impactScore.toString(),
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (val) => setState(() => _impactScore = val.toInt()),
                  ),
                  TextField(
                    controller: _impactWhoController,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: "Who did this help? (optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            "Cancel",
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
        ElevatedButton(
          onPressed: _saveAchievement,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: Text(widget.initialData != null ? "Save Changes" : "Log Win"),
        ),
      ],
    );
  }
}
