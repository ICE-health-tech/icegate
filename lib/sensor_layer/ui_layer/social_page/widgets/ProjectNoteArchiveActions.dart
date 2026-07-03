import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveViewer.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

abstract final class ProjectNoteArchiveActions {
  static Future<void> addPhotoMemory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image == null || !context.mounted) return;

    final personId = context.read<PersonBlock>().currentPersonID.value;
    if (personId == null || personId.isEmpty) return;

    if (!context.mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Expanded(child: Text(l10n.health_smart_scale_syncing)),
            ],
          ),
        ),
      ),
    );

    String savedPath;
    try {
      savedPath = await context.read<ObjectDatabaseBlock>().saveAnyLocalImage(
        image,
        subFolder: 'user_markdown_documentation',
        personId: personId,
        awaitCloudSync: true,
      );
    } catch (_) {
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.achievement_story_save_failed)),
        );
      }
      return;
    }

    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      HapticFeedback.mediumImpact();
      context.push(
        '/projects/editor',
        extra: {'category': ProjectNoteArchiveUtils.archiveCategory, 'initialImage': savedPath},
      );
    }
  }

  static void openViewer(
    BuildContext context,
    List<ProjectNoteData> photos,
    int index, {
    List<ProjectProtocol> projects = const [],
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => ProjectNoteArchiveViewer(
          notes: photos,
          initialIndex: index,
          projects: projects,
        ),
      ),
    );
  }

  static void openNote(BuildContext context, ProjectNoteData note) {
    context.push('/projects/editor', extra: note);
  }

  static Future<void> showActionSheet(
    BuildContext context,
    ProjectNoteData note,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.project_notes_label),
              onTap: () {
                Navigator.pop(ctx);
                openNote(context, note);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: cs.error),
              title: Text(
                l10n.common_delete,
                style: TextStyle(color: cs.error),
              ),
              onTap: () async {
                Navigator.pop(ctx);
                await context.read<ProjectNoteDAO>().deleteNote(note.id);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
