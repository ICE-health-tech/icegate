import 'dart:convert';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/MoodSelector.dart';
import 'package:ice_gate/ui_layer/social_page/widgets/ActivitySelector.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  bool _isSaving = false;

  Future<void> _saveLog() async {
    final personBlock = context.read<PersonBlock>();
    final profile = personBlock.information.value.profiles;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final personId = profile.id ?? currentUser?.id;
    
    // Robust tenantId capture from multiple potential sources
    final tenantId = (profile.tenantId != null && profile.tenantId!.isNotEmpty)
        ? profile.tenantId
        : (currentUser?.appMetadata['tenant_id'] ?? currentUser?.userMetadata?['tenant_id']);

    print("DEBUG: Resolved personId: $personId, tenantId: $tenantId");

    if (personId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: User session not found. Please log in again."),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entry = MindLogsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        tenantID: const drift.Value('00000000-0000-0000-0000-000000000001'),
        personID: drift.Value(personId),
        moodScore: _selectedMood,
        activities: jsonEncode(_selectedActivities),
        note: _noteController.text.trim().isEmpty
            ? const drift.Value.absent()
            : drift.Value(_noteController.text.trim()),
        logDate: drift.Value(DateTime.now()),
        createdAt: drift.Value(DateTime.now()),
      );
      print("entry oke: " + entry.toString());
      await context.read<MindLogsDAO>().insertLog(entry);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Mind log saved! Reflection updated.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to save log: $e")));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
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

    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          height: constraints.maxHeight * 0.85,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomInset),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                    fillColor: colorScheme.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _saveLog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorScheme.primary,
                      foregroundColor: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            "Save Entry",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }
}
