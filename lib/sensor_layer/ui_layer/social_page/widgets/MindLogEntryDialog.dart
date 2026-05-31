import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MoodSelector.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ActivitySelector.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:ice_gate/utils/journal_media.dart';
import 'package:ice_gate/utils/sync_device.dart';

class MindLogEntryDialog extends StatefulWidget {
  const MindLogEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
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
  String? _attachedImagePath;
  bool _isPickingImage = false;

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

  String? _resolveTenantId(
    PersonBlock personBlock,
    User? currentUser,
  ) {
    final profile = personBlock.information.value.profiles;
    final Object? raw = (profile.tenantId != null &&
            profile.tenantId!.isNotEmpty)
        ? profile.tenantId
        : (currentUser?.appMetadata['tenant_id'] ??
            currentUser?.userMetadata?['tenant_id']);
    if (raw == null) return null;
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }

  bool _isSaving = false;

  String _journalContent(String emoji) {
    final note = _noteController.text.trim();
    final body = note.isEmpty
        ? AppLocalizations.of(context)!.mind_feeling_format(emoji)
        : note;
    if (_attachedImagePath == null || _attachedImagePath!.isEmpty) {
      return body;
    }
    return '![Image]($_attachedImagePath)\n\n$body';
  }

  Future<void> _pickAndAttachImage(String personId) async {
    if (_isPickingImage || _isSaving) return;

    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;

    setState(() => _isPickingImage = true);
    try {
      final savedPath = await context.read<ObjectDatabaseBlock>().saveAnyLocalImage(
        image,
        subFolder: 'user_markdown_documentation',
        personId: personId,
        awaitCloudSync: true,
      );
      if (!mounted) return;
      setState(() => _attachedImagePath = savedPath);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.achievement_story_save_failed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _saveLog() async {
    if (_isSaving) return;

    final personBlock = context.read<PersonBlock>();
    final profile = personBlock.information.value.profiles;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final personId = profile.id ?? currentUser?.id;
    final tenantId = _resolveTenantId(personBlock, currentUser);

    if (personId == null || personId.isEmpty) {
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

      // Mirror to project_notes for Journal cards (best-effort; mood log is source of truth).
      try {
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
        final localPath = _attachedImagePath;
        final remotePath = JournalMedia.canonicalRemotePath(
          localPath,
          personId: personId,
        );

        await context.read<ProjectNoteDAO>().insertNote(
          title: "$emoji $activitiesStr",
          content: _journalContent(emoji),
          personID: personId,
          tenantID: tenantId,
          category: 'social',
          mood: emoji,
          localPath: localPath,
          remotePath: remotePath,
          device: localPath != null ? SyncDevice.current() : null,
        );
      } catch (e) {
        appLog('MindLogEntryDialog: journal mirror failed: $e');
      }

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
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.85;
    final personBlock = context.read<PersonBlock>();
    final profile = personBlock.information.value.profiles;
    final currentUser = Supabase.instance.client.auth.currentUser;
    final personId = profile.id ?? currentUser?.id;
    final tenantId = _resolveTenantId(personBlock, currentUser);

    return Container(
      height: sheetHeight,
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
                const SizedBox(height: 12),
                if (_isPickingImage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(
                      borderRadius: BorderRadius.circular(4),
                      color: colorScheme.primary,
                    ),
                  ),
                if (_attachedImagePath != null) ...[
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: LocalFirstImage(
                          localPath: _attachedImagePath!,
                          remoteUrl: _remoteImageUrl(_attachedImagePath!, personId),
                          subFolder: 'user_markdown_documentation',
                          ownerId: personId,
                          height: 140,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          borderRadius: BorderRadius.circular(14),
                          placeholder: Container(
                            height: 140,
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.image_outlined,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Material(
                          color: Colors.black54,
                          shape: const CircleBorder(),
                          child: IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            onPressed: _isSaving
                                ? null
                                : () => setState(() => _attachedImagePath = null),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],
                if (personId != null && personId.isNotEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: (_isSaving || _isPickingImage)
                          ? null
                          : () => _pickAndAttachImage(personId),
                      icon: Icon(
                        Icons.add_photo_alternate_outlined,
                        color: colorScheme.secondary,
                      ),
                      label: Text(
                        AppLocalizations.of(context)!.stat_images,
                        style: TextStyle(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveLog,
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
  }

  static String _remoteImageUrl(String localPath, String? personId) {
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }
    final normalized = localPath.replaceAll('\\', '/');
    final key = normalized.contains('/')
        ? normalized
        : (personId != null && personId.isNotEmpty
            ? '$personId/user_markdown_documentation/${p.basename(normalized)}'
            : normalized);
    return MinioService().publicUrlForKey(key);
  }
}
