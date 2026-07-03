import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/StorageBlock.dart';
import 'package:ice_gate/utils/app_log.dart';
import 'package:provider/provider.dart';

/// Mirrors project journal logs into Achievements (story grid + text feats).
abstract final class ProjectJournalArchive {
  ProjectJournalArchive._();

  static String moodEmoji(int score) => switch (score) {
    1 => '😫',
    2 => '😔',
    3 => '😐',
    4 => '😊',
    5 => '🤩',
    _ => '😐',
  };

  /// Best-effort: project diary → [achievements] for Thành tựu tab.
  static Future<void> syncFromProjectLog({
    required BuildContext context,
    required String personId,
    required String projectName,
    required int moodScore,
    required String? description,
    required String? imagePath,
    String? projectId,
  }) async {
    if (personId.isEmpty) return;

    final emoji = moodEmoji(moodScore);
    final desc = description?.trim() ?? '';
    final title = desc.isNotEmpty
        ? (desc.length > 120 ? '${desc.substring(0, 117)}…' : desc)
        : '$emoji $projectName';

    final id = IDGen.UUIDV7();
    final hasImage = imagePath != null && imagePath.trim().isNotEmpty;

    try {
      await context.read<AchievementsDAO>().insertAchievement(
        AchievementsTableCompanion(
          id: drift.Value(id),
          personID: drift.Value(personId),
          title: drift.Value(title),
          description:
              desc.isEmpty ? const drift.Value.absent() : drift.Value(desc),
          domain: const drift.Value('project'),
          meaningScore: drift.Value(moodScore.clamp(1, 10)),
          impactScore: drift.Value(moodScore.clamp(1, 10)),
          moodPost: drift.Value(emoji),
          impactDescWho: const drift.Value('You'),
          impactDescHow: drift.Value(projectName),
          projectID: projectId != null && projectId.isNotEmpty
              ? drift.Value(projectId)
              : const drift.Value.absent(),
          localImagePath: hasImage
              ? drift.Value(imagePath.trim())
              : const drift.Value.absent(),
        ),
      );
    } catch (e) {
      appLog('ProjectJournalArchive: achievement insert failed: $e');
      return;
    }

    if (!hasImage || !context.mounted) return;

    try {
      await context.read<StorageBlock>().repushStorySyncUntilMatched(
        achievementId: id,
        personId: personId,
        title: title,
        storyDatetime: DateTime.now(),
        imageS3Path: imagePath.trim(),
        isUploading: false,
      );
    } catch (e) {
      appLog('ProjectJournalArchive: story sync failed: $e');
    }
  }
}
