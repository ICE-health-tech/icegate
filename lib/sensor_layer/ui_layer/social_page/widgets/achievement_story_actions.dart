import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryViewer.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
        subFolder: 'achievement_stories',
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

    if (!context.mounted) return;
    final title = await promptStoryTitle(context);
    if (!context.mounted) return;

    final dao = context.read<AchievementsDAO>();
    await dao.insertAchievement(
      AchievementsTableCompanion(
        id: drift.Value(IDGen.UUIDV7()),
        personID: drift.Value(personId),
        title: drift.Value(
          title != null && title.trim().isNotEmpty
              ? title.trim()
              : DateFormat.yMMMd().format(DateTime.now()),
        ),
        description: const drift.Value.absent(),
        domain: const drift.Value('project'),
        meaningScore: const drift.Value(6),
        impactScore: const drift.Value(5),
        impactDescWho: const drift.Value('You'),
        impactDescHow: const drift.Value(''),
        localImagePath: drift.Value(savedPath),
      ),
    );

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
