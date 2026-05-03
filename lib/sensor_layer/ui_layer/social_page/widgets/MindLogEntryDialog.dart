import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_activity_tokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MoodSelector.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ActivitySelector.dart';
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

  Future<void> _onAddCustomOption(
    String categoryKey,
    String personId,
    String? tenantId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    String? result;
    try {
      result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(l10n.mind_activity_custom_dialog_title),
          content: TextField(
            controller: controller,
            maxLength: 80,
            autofocus: true,
            decoration: InputDecoration(
              hintText: l10n.mind_activity_custom_hint,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                final label = controller.text.trim();
                if (label.isEmpty) return;
                if (label.contains('|')) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(l10n.mind_activity_custom_invalid_char)),
                  );
                  return;
                }
                Navigator.pop(ctx, label);
              },
              child: Text(l10n.mind_activity_custom_add),
            ),
          ],
        ),
      );
    } finally {
      controller.dispose();
    }

    if (result == null || result.isEmpty || !mounted) return;

    final id = IDGen.UUIDV7();
    final db = context.read<AppDatabase>();
    try {
      await db.journalActivityOptionsDAO.insertOption(
        id: id,
        personId: personId,
        tenantId: tenantId,
        categoryKey: categoryKey,
        label: result,
      );
      if (!mounted) return;
      _onActivityToggled(MindActivityTokens.refToken(id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save activity: $e')),
        );
      }
    }
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

    if (personId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.auth_error_session_not_found),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = context.read<AppDatabase>();
      await context.read<MindBlock>().addMindLog(
        moodScore: _selectedMood,
        activities: _selectedActivities,
        note: _noteController.text.trim(),
        personId: personId,
        tenantId: tenantId,
      );
      if (!mounted) return;

      // Double insert into project_notes for Journal visibility
      final l10n = AppLocalizations.of(context)!;
      final optionLabels = await db.journalActivityOptionsDAO.labelMapForPerson(
        personId,
      );
      if (!mounted) return;
      final activitiesStr = _selectedActivities.isNotEmpty
          ? _selectedActivities
                .map(
                  (t) => MindActivityTokens.displayLabel(l10n, t, optionLabels),
                )
                .join(', ')
          : l10n.mind_logged_mood;
      final emoji = _getMoodEmoji(_selectedMood);
      
      await context.read<ProjectNoteDAO>().insertNote(
        title: "$emoji $activitiesStr",
        content: _noteController.text.trim().isEmpty 
            ? AppLocalizations.of(context)!.mind_feeling_format(emoji)
            : _noteController.text.trim(),
        personID: personId,
        tenantID: tenantId,
        category: 'social',
        mood: emoji,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.mind_save_success)),
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

  String _getMoodEmoji(int score) {
    switch (score) {
      case 1: return "😫";
      case 2: return "😔";
      case 3: return "😐";
      case 4: return "😊";
      case 5: return "🤩";
      default: return "😐";
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
    final personBlock = context.read<PersonBlock>();
    final profile = personBlock.information.value.profiles;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final personId = profile.id ?? currentUser?.id;
    final Object? rawTenant = (profile.tenantId != null &&
            profile.tenantId!.isNotEmpty)
        ? profile.tenantId
        : (currentUser?.appMetadata['tenant_id'] ??
            currentUser?.userMetadata?['tenant_id']);
    final String? tenantId =
        rawTenant is String ? rawTenant : rawTenant?.toString();

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
                  AppLocalizations.of(context)!.mind_question,
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
                  AppLocalizations.of(context)!.mind_activities_question,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                if (personId != null && personId.isNotEmpty)
                  StreamBuilder<List<JournalActivityOptionData>>(
                    stream: context
                        .read<AppDatabase>()
                        .journalActivityOptionsDAO
                        .watchForPerson(personId),
                    builder: (context, snap) {
                      return ActivitySelector(
                        selectedActivities: _selectedActivities,
                        onActivityToggled: _onActivityToggled,
                        customOptions: snap.data ?? const [],
                        onAddCustomOption: (cat) => _onAddCustomOption(
                          cat,
                          personId,
                          tenantId,
                        ),
                      );
                    },
                  )
                else
                  ActivitySelector(
                    selectedActivities: _selectedActivities,
                    onActivityToggled: _onActivityToggled,
                    customOptions: const [],
                    onAddCustomOption: (_) {},
                  ),
                const SizedBox(height: 24),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  style: TextStyle(color: colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.mind_note_hint,
                    hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
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
                        : Text(
                            AppLocalizations.of(context)!.mind_save_btn,
                            style: const TextStyle(
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
