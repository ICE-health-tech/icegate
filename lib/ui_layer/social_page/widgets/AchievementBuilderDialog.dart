import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

class AchievementBuilderDialog extends StatefulWidget {
  final BuildContext parentContext;

  const AchievementBuilderDialog({super.key, required this.parentContext});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => AchievementBuilderDialog(parentContext: context),
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
  final _impactHowController = TextEditingController();
  final _moodPreController = TextEditingController();
  final _moodPostController = TextEditingController();

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

  bool get _isValid {
    if (_titleController.text.trim().isEmpty) return false;
    if (_impactScore == 0) return false; // Mandatory Impact Score
    if (_impactWhoController.text.trim().isEmpty) return false;
    if (_impactHowController.text.trim().isEmpty) return false;
    return true;
  }

  Future<void> _saveAchievement() async {
    if (!_isValid) return;

    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.currentPersonID.value;

    final entry = AchievementsTableCompanion(
      id: drift.Value(IDGen.UUIDV7()),
      personID: drift.Value(personId),
      title: drift.Value(_titleController.text.trim()),
      description: drift.Value(_descriptionController.text.trim()),
      domain: drift.Value(_selectedDomain),
      meaningScore: drift.Value(_meaningScore),
      impactScore: drift.Value(_impactScore),
      impactDescWho: drift.Value(_impactWhoController.text.trim()),
      impactDescHow: drift.Value(_impactHowController.text.trim()),
      moodPre: drift.Value(_moodPreController.text.trim().isEmpty ? null : _moodPreController.text.trim()),
      moodPost: drift.Value(_moodPostController.text.trim().isEmpty ? null : _moodPostController.text.trim()),
    );

    await context.read<AchievementsDAO>().insertAchievement(entry);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _impactWhoController.dispose();
    _impactHowController.dispose();
    _moodPreController.dispose();
    _moodPostController.dispose();
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
        "Log Achievement",
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
                labelText: "What did you accomplish? *",
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
            
            // PSYCHOLOGICAL IMPACT SECTION
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
                border: Border.all(color: Theme.of(context).colorScheme.secondary),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Theme.of(context).colorScheme.secondary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Psychological Impact",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _moodPreController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: "How did you feel BEFORE this? (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _moodPostController,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: "How do you feel AFTER achieving this? (Optional)",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            
            // MANDATORY PHILOSOPHY SECTION
            Container(
              margin: const EdgeInsets.symmetric(vertical: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
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
                    "Your philosophy dictates that your actions must have a good impact on others. This is mandatory.",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text("Impact Score (1-10) *", style: TextStyle(fontWeight: FontWeight.bold)),
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
                      labelText: "Who did this help? *",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _impactHowController,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    decoration: const InputDecoration(
                      labelText: "How did it make a positive impact? *",
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
          onPressed: _isValid ? _saveAchievement : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text("Log Win"),
        ),
      ],
    );
  }
}
