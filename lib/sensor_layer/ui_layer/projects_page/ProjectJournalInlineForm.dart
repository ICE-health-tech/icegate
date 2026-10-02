import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/ProjectJournalArchive.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:ice_gate/utils/journal_media.dart';
import 'package:ice_gate/utils/sync_device.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Inline mood + description form on the project journal panel.
class ProjectJournalInlineForm extends StatefulWidget {
  const ProjectJournalInlineForm({
    super.key,
    required this.project,
  });

  final ProjectProtocol project;

  @override
  State<ProjectJournalInlineForm> createState() =>
      _ProjectJournalInlineFormState();
}

class _ProjectJournalInlineFormState extends State<ProjectJournalInlineForm> {
  int _mood = 4;
  final _descController = TextEditingController();
  String? _imagePath;
  bool _isSaving = false;
  bool _isPickingImage = false;

  static const _activities = ['act_deep_work'];

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  String _moodEmoji(int score) => switch (score) {
    1 => '😫',
    2 => '😔',
    3 => '😐',
    4 => '😊',
    5 => '🤩',
    _ => '😐',
  };

  String _moodLabel(AppLocalizations l10n, int score) => switch (score) {
    1 => l10n.mood_awful,
    2 => l10n.mood_bad,
    3 => l10n.mood_meh,
    4 => l10n.mood_good,
    5 => l10n.mood_rad,
    _ => l10n.mood_meh,
  };

  InputDecoration _fieldDecoration(
    ColorScheme cs,
    String label, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.45),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.35)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.25)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: cs.primary.withValues(alpha: 0.65)),
      ),
    );
  }

  Future<void> _pickImage(String personId) async {
    if (_isPickingImage || _isSaving) return;
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !mounted) return;
    setState(() => _isPickingImage = true);
    try {
      final path = await context.read<ObjectDatabaseBlock>().saveAnyLocalImage(
        image,
        subFolder: 'user_markdown_documentation',
        personId: personId,
        awaitCloudSync: true,
      );
      if (mounted) setState(() => _imagePath = path);
    } finally {
      if (mounted) setState(() => _isPickingImage = false);
    }
  }

  Future<void> _save() async {
    if (_isSaving) return;
    final l10n = AppLocalizations.of(context)!;
    final personBlock = context.read<PersonBlock>();
    final profile = personBlock.information.value.profiles;
    final user = Supabase.instance.client.auth.currentUser;
    final personId = profile.id ?? user?.id;
    if (personId == null || personId.isEmpty) return;

    final tenantRaw = profile.tenantId ?? user?.appMetadata['tenant_id'];
    final tenantId = tenantRaw?.toString().trim();

    setState(() => _isSaving = true);
    try {
      final note = _descController.text.trim();
      final activities = [
        ..._activities,
        'project:${widget.project.projectID}',
      ];
      await context.read<MindBlock>().addMindLog(
        moodScore: _mood,
        activities: activities,
        note: note.isEmpty ? null : note,
        personId: personId,
        tenantId: tenantId?.isNotEmpty == true ? tenantId : null,
      );
      if (!mounted) return;

      final emoji = _moodEmoji(_mood);
      final body = note.isEmpty
          ? l10n.mind_feeling_format(emoji)
          : note;
      final content = _imagePath != null
          ? '![Image]($_imagePath)\n\n$body'
          : body;

      await context.read<ProjectNoteDAO>().insertNote(
        title: '$emoji ${widget.project.name}',
        content: content,
        personID: personId,
        tenantID: tenantId?.isNotEmpty == true ? tenantId : null,
        projectID: widget.project.projectID,
        category: 'project_log',
        mood: emoji,
        localPath: _imagePath,
        remotePath: JournalMedia.canonicalRemotePath(
          _imagePath,
          personId: personId,
        ),
        device: _imagePath != null ? SyncDevice.current() : null,
      );

      await ProjectJournalArchive.syncFromProjectLog(
        context: context,
        personId: personId,
        projectName: widget.project.name,
        projectId: ProjectBlock.linkId(widget.project),
        moodScore: _mood,
        description: note.isEmpty ? null : note,
        imagePath: _imagePath,
      );

      if (!mounted) return;
      _descController.clear();
      setState(() {
        _imagePath = null;
        _mood = 4;
      });
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.mind_save_success)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save log: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<int>(
          initialValue: _mood,
          decoration: _fieldDecoration(cs, l10n.project_journal_mood_label),
          items: List.generate(5, (i) {
            final score = i + 1;
            final color = mindMoodAccent(score);
            return DropdownMenuItem(
              value: score,
              child: Row(
                children: [
                  Text(_moodEmoji(score), style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Text(
                    _moodLabel(l10n, score),
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ],
              ),
            );
          }),
          onChanged: _isSaving
              ? null
              : (v) {
                  if (v != null) setState(() => _mood = v);
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descController,
          maxLines: 3,
          minLines: 2,
          enabled: !_isSaving,
          textCapitalization: TextCapitalization.sentences,
          decoration: _fieldDecoration(cs, l10n.project_journal_desc_label),
        ),
        if (_imagePath != null) ...[
          const SizedBox(height: 10),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LocalFirstImage(
                  localPath: _imagePath!,
                  remoteUrl: JournalMedia.canonicalRemotePath(
                        _imagePath,
                        personId: personId,
                      ) ??
                      _imagePath!,
                  subFolder: 'user_markdown_documentation',
                  ownerId: personId,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: IconButton.filledTonal(
                  visualDensity: VisualDensity.compact,
                  onPressed: _isSaving ? null : () => setState(() => _imagePath = null),
                  icon: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            IconButton.filledTonal(
              onPressed: _isSaving || _isPickingImage || personId.isEmpty
                  ? null
                  : () => _pickImage(personId),
              icon: _isPickingImage
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: cs.primary,
                      ),
                    )
                  : const Icon(Icons.add_photo_alternate_outlined),
              tooltip: l10n.stat_images,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(l10n.project_journal_save),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
