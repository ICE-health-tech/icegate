import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/StorageBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryViewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Add / title / open flows shared by story UI widgets.
abstract final class AchievementStoryActions {
  static Future<void> addStory(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) return;

    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;

    final objectBlock = context.read<ObjectDatabaseBlock>();
    String savedPath;
    try {
      savedPath = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'memories',
        personId: personId,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.achievement_story_save_failed)),
        );
      }
      return;
    }

    // Best-effort sync to S3 `<userId>/memories/` for this achievement image.
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final absolute = File(p.join(appDir.path, savedPath));
      if (await absolute.exists()) {
        await context.read<StorageBlock>().uploadFile(
              absolute,
              fileName: p.basename(savedPath),
              subFolder: '$personId/memories',
            );
      }
    } catch (_) {
      // Silent: local-first still works; download-on-demand will handle later.
    }

    if (!context.mounted) return;
    final title = await promptStoryTitle(context);
    if (!context.mounted) return;

    final id = IDGen.UUIDV7();
    final storyTitle = title != null && title.trim().isNotEmpty
        ? title.trim()
        : DateFormat.yMMMd().format(DateTime.now());

    final dao = context.read<AchievementsDAO>();
    await dao.insertAchievement(
      AchievementsTableCompanion(
        id: drift.Value(id),
        personID: drift.Value(personId),
        title: drift.Value(storyTitle),
        description: const drift.Value.absent(),
        domain: const drift.Value('project'),
        meaningScore: const drift.Value(6),
        impactScore: const drift.Value(5),
        impactDescWho: const drift.Value('You'),
        impactDescHow: const drift.Value(''),
        localImagePath: drift.Value(savedPath),
      ),
    );

    // If Supabase row is null / stale, keep repushing until it matches S3 key.
    try {
      await context.read<StorageBlock>().repushStorySyncUntilMatched(
            achievementId: id,
            personId: personId,
            title: storyTitle,
            storyDatetime: DateTime.now(),
            imageS3Path: savedPath,
            isUploading: false,
          );
    } catch (_) {}

    if (context.mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.achievement_story_added)),
      );
    }
  }

  static Future<String?> promptStoryTitle(BuildContext context) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _StoryTitleSheet(),
    );
  }

  static void openViewer(
    BuildContext context,
    List<AchievementData> stories,
    int index,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => AchievementStoryViewer(
          stories: stories,
          initialIndex: index,
        ),
      ),
    );
  }

  static Future<void> showStoryActionSheet(
    BuildContext context,
    AchievementData story,
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
              leading: const Icon(Icons.image_outlined),
              title: const Text('Update image'),
              onTap: () async {
                Navigator.pop(ctx);
                await updateStoryImage(context, story);
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
                await deleteStory(context, story);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Future<void> updateStoryImage(
    BuildContext context,
    AchievementData story,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !context.mounted) return;

    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    if (personId.isEmpty) return;

    final oldRel = story.localImagePath;

    // Save new image locally under `memories/`.
    final objectBlock = context.read<ObjectDatabaseBlock>();
    String newRel;
    try {
      newRel = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'memories',
        personId: personId,
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.achievement_story_save_failed)),
        );
      }
      return;
    }

    // Update DB row.
    final updated = story.copyWith(
      localImagePath: drift.Value(newRel),
      updatedAt: DateTime.now(),
    );
    await context.read<AchievementsDAO>().updateAchievement(updated);

    // Best-effort: upload new image to S3 `<userId>/memories/`.
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final absolute = File(p.join(appDir.path, newRel));
      if (await absolute.exists()) {
        await context.read<StorageBlock>().uploadFile(
              absolute,
              fileName: p.basename(newRel),
              subFolder: '$personId/memories',
            );
      }
    } catch (_) {}

    // If Supabase row is null / stale, keep repushing until it matches S3 key.
    try {
      await context.read<StorageBlock>().repushStorySyncUntilMatched(
            achievementId: story.id,
            personId: personId,
            title: story.title,
            storyDatetime: story.createdAt,
            imageS3Path: newRel,
            isUploading: false,
          );
    } catch (_) {}

    // Best-effort: delete old local + old S3 object (if path changed).
    if (oldRel != null && oldRel.trim().isNotEmpty && oldRel != newRel) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final f = File(p.join(appDir.path, oldRel));
        if (await f.exists()) await f.delete();
      } catch (_) {}
      try {
        await context.read<StorageBlock>().deleteObject(oldRel);
      } catch (_) {}
    }

    if (context.mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.common_done)),
      );
    }
  }

  static Future<void> deleteStory(
    BuildContext context,
    AchievementData story,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.common_delete),
        content: Text(l10n.social_delete_feat_body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.common_cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    // 1) Delete DB row (will sync delete to Supabase).
    await context.read<AchievementsDAO>().deleteAchievement(story.id);

    // 2) Delete local file best-effort.
    final rel = story.localImagePath;
    if (rel != null && rel.trim().isNotEmpty) {
      try {
        final appDir = await getApplicationDocumentsDirectory();
        final file = File(p.join(appDir.path, rel));
        if (await file.exists()) await file.delete();
      } catch (_) {}

      // 3) Delete S3 object best-effort (key == rel, e.g. `<userId>/memories/<file>`).
      try {
        await context.read<StorageBlock>().deleteObject(rel);
      } catch (_) {}
    }

    if (context.mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.common_done)),
      );
    }
  }
}

class _StoryTitleSheet extends StatefulWidget {
  const _StoryTitleSheet();

  @override
  State<_StoryTitleSheet> createState() => _StoryTitleSheetState();
}

class _StoryTitleSheetState extends State<_StoryTitleSheet> {
  String _title = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.achievement_story_title_dialog,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              autofocus: true,
              maxLength: 80,
              textInputAction: TextInputAction.done,
              onChanged: (v) => _title = v,
              decoration: InputDecoration(
                hintText: l10n.achievement_story_title_hint,
                filled: true,
                fillColor: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (v) => Navigator.pop(context, v),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context, ''),
                  child: Text(l10n.cancel),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => Navigator.pop(context, _title),
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: Text(l10n.mind_save_btn),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
