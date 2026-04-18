import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/MoodSelector.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/ActivitySelector.dart';
import 'package:provider/provider.dart';

class MindLogEntryDialog extends StatefulWidget {
  const MindLogEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const MindLogEntryDialog(),
    );
  }

  @override
  State<MindLogEntryDialog> createState() => _MindLogEntryDialogState();
}

class _MindLogEntryDialogState extends State<MindLogEntryDialog> {
  int _selectedMood = 3; // Meh
  final List<String> _selectedActivities = [];
  final _noteController = TextEditingController();

  void _onActivityToggled(String name) {
    setState(() {
      if (_selectedActivities.contains(name)) {
        _selectedActivities.remove(name);
      } else {
        _selectedActivities.add(name);
      }
    });
  }

  Future<void> _saveLog() async {
    final personBlock = context.read<PersonBlock>();
    final personId = personBlock.currentPersonID.value;
    if (personId == null) return;

    final entry = MindLogsTableCompanion.insert(
      id: IDGen.UUIDV7(),
      personID: drift.Value(personId),
      moodScore: _selectedMood,
      activities: jsonEncode(_selectedActivities),
      note: drift.Value(_noteController.text.trim().isEmpty ? null : _noteController.text.trim()),
      logDate: drift.Value(DateTime.now()),
      createdAt: drift.Value(DateTime.now()),
    );

    await context.read<MindLogsDAO>().insertLog(entry);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Mind log saved! Reflection updated.")),
      );
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "How are you feeling?",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          MoodSelector(
            selectedMood: _selectedMood,
            onMoodSelected: (score) => setState(() => _selectedMood = score),
          ),
          const SizedBox(height: 32),
          Text(
            "What have you been up to?",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  ActivitySelector(
                    selectedActivities: _selectedActivities,
                    onActivityToggled: _onActivityToggled,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: "Add a note (optional)",
                      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: colorScheme.surfaceVariant.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                "Save Entry",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
