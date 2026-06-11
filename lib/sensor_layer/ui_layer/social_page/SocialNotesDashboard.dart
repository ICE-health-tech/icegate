import 'dart:async';

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/common/LocalFirstImage.dart';
import 'package:ice_gate/link_layer/storage_services/MinioService.dart';
import 'package:path/path.dart' as p;
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ObjectDatabaseBlock.dart';
import 'package:ice_gate/utils/journal_media.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/StorageBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_log_insights.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MoodTrendsChart.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/MindActivityTokens.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindMoodPalette.dart';
import 'package:signals_flutter/signals_flutter.dart';

class SocialNotesDashboard extends StatefulWidget {
  const SocialNotesDashboard({super.key});

  @override
  State<SocialNotesDashboard> createState() => _SocialNotesDashboardState();
}

class _SocialNotesDashboardState extends State<SocialNotesDashboard> {
  bool _journalSyncStarted = false;

  void _maybeSyncJournalImages(String personId) {
    if (_journalSyncStarted || personId.isEmpty) return;
    _journalSyncStarted = true;
    unawaited(
      context.read<StorageBlock>().syncJournalNotes(
        personId: personId,
        notesDao: context.read<ProjectNoteDAO>(),
        category: 'social',
      ),
    );
  }

  /// Space for [MainShell] bottom FAB / home button strip.
  double _bottomClearance(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wideMac = defaultTargetPlatform == TargetPlatform.macOS && width >= 560;
    return wideMac ? 72 : 104;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    return Watch((context) {
      final personBlock = context.read<PersonBlock>();
      final personId = personBlock.currentPersonID.value;

      if (personId == null || personId.isEmpty) {
        return const Center(child: CircularProgressIndicator());
      }

      _maybeSyncJournalImages(personId);

      return Container(
        color: Colors.transparent,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildQuickEntryBar(context, colorScheme, textTheme, isDark),
                  const SizedBox(height: 8),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.sizeOf(context).width >= 900
                          ? 32
                          : 16,
                      vertical: 12,
                    ),
                    child: Align(
                      alignment: Alignment.center,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 920),
                        child: _buildJournalMoodTrendsPanel(
                          context,
                          personId,
                          colorScheme,
                          textTheme,
                          isDark,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            StreamBuilder<List<ProjectNoteData>>(
              stream: context.read<ProjectNoteDAO>().watchNotesByCategory(
                personId,
                'social',
              ),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text('Error: ${snapshot.error}')),
                  );
                }

                if (!snapshot.hasData) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notes = snapshot.data!;

                if (notes.isEmpty) {
                  return SliverFillRemaining(
                    child: _buildEmptyState(context, colorScheme, textTheme),
                  );
                }

                // Sort by updatedAt descending
                final sortedNotes = List<ProjectNoteData>.from(notes)
                  ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                return SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final cw = constraints.crossAxisExtent;
                    var gap = 14.0;
                    var hPad = 16.0;
                    var maxTileWidth = 320.0;
                    var tileHeight = 320.0;
                    final bottomPad = _bottomClearance(context);
                    final useList = cw < 720;

                    if (cw >= 1200) {
                      maxTileWidth = 300;
                      tileHeight = 328;
                      hPad = 32;
                    } else if (cw >= 900) {
                      maxTileWidth = 300;
                      tileHeight = 324;
                      hPad = 28;
                    } else if (cw >= 640) {
                      maxTileWidth = 280;
                      tileHeight = 316;
                      hPad = 20;
                    }

                    if (useList) {
                      return SliverPadding(
                        padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => Padding(
                              padding: EdgeInsets.only(
                                bottom: index < sortedNotes.length - 1
                                    ? gap
                                    : 0,
                              ),
                              child: _SocialNoteCard(
                                note: sortedNotes[index],
                                layout: _NoteCardLayout.list,
                              ),
                            ),
                            childCount: sortedNotes.length,
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: maxTileWidth,
                          mainAxisExtent: tileHeight,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _SocialNoteCard(
                            note: sortedNotes[index],
                            layout: _NoteCardLayout.grid,
                          ),
                          childCount: sortedNotes.length,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      );
    });
  }

  Widget _buildQuickEntryBar(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 32 : 16,
        vertical: isDesktop ? 12 : 16,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isDesktop ? 720 : double.infinity,
          ),
          child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _createNewNote(context),
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isDesktop ? 16 : 20,
                  vertical: isDesktop ? 10 : 12,
                ),
                decoration: HealthMetricColors.shellPanel(
                  colorScheme,
                  isDark: isDark,
                  radius: 30,
                  accent: HealthMetricColors.pillarViolet,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.sentiment_satisfied_alt_rounded,
                      size: isDesktop ? 18 : 20,
                      color: colorScheme.onSurface,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.mind_quick_entry_hint,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.78),
                        fontWeight: FontWeight.w600,
                        fontSize: isDesktop ? 14 : null,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filledTonal(
            onPressed: () => _pickAndCreateImageNote(context),
            icon: Icon(
              Icons.add_photo_alternate_rounded,
              size: isDesktop ? 20 : 22,
            ),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.secondaryContainer.withValues(
                alpha: 0.4,
              ),
              foregroundColor: colorScheme.secondary,
            ),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.auto_stories_rounded,
                size: 80,
                color: colorScheme.primary.withValues(alpha: 0.15),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.social_empty_state_title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)!.social_empty_state_subtitle,
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: () => _createNewNote(context),
              icon: const Icon(Icons.add_rounded),
              label: Text(AppLocalizations.of(context)!.btn_new_reflection),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentLogsPreview(
    BuildContext context,
    List<MindLogData> logs,
    String personId,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;

    // Sort by when the entry was saved (createdAt); logDate is only the day bucket.
    final sortedLogs = List<MindLogData>.from(logs)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return StreamBuilder<List<JournalActivityOptionData>>(
      stream: context
          .read<AppDatabase>()
          .journalActivityOptionsDAO
          .watchForPerson(personId),
      builder: (context, optSnap) {
        final optMap = <String, String>{
          for (final o in optSnap.data ?? []) o.id: o.label,
        };
        final l10n = AppLocalizations.of(context)!;

        return SizedBox(
          height: 112,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: sortedLogs.length.clamp(0, 10),
            itemBuilder: (context, index) {
              final log = sortedLogs[index];

              final mood = mindMoodAccent(log.moodScore);
              return Container(
                width: 168,
                margin: EdgeInsets.only(right: index == sortedLogs.length - 1 ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: HealthMetricColors.shellPanel(
                  colorScheme,
                  isDark: isDark,
                  radius: 16,
                  accent: HealthMetricColors.pillarViolet,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        _buildMoodIcon(context, log.moodScore),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            DateFormat('MMM d, HH:mm')
                                .format(log.createdAt.toLocal()),
                            style: textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      MindActivityTokens.formatActivitiesJson(
                        l10n,
                        log.activities,
                        optMap,
                      ),
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.82),
                        fontSize: 11,
                        height: 1.25,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMoodIcon(BuildContext context, int score) {
    final Color color = mindMoodAccent(score);
    final IconData icon;

    switch (score) {
      case 1:
        icon = Icons.sentiment_very_dissatisfied_rounded;
        break;
      case 2:
        icon = Icons.sentiment_dissatisfied_rounded;
        break;
      case 3:
        icon = Icons.sentiment_neutral_rounded;
        break;
      case 4:
        icon = Icons.sentiment_satisfied_alt_rounded;
        break;
      case 5:
        icon = Icons.sentiment_very_satisfied_rounded;
        break;
      default:
        icon = Icons.sentiment_neutral_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 16,
        color: color,
      ),
    );
  }

  void _createNewNote(BuildContext context) {
    context.push('/projects/editor', extra: {'category': 'social'});
  }

  Future<void> _pickAndCreateImageNote(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image == null || !context.mounted) return;

    final personBlock = context.read<PersonBlock>();
    final objectBlock = context.read<ObjectDatabaseBlock>();
    final personId = personBlock.currentPersonID.value;

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
      savedPath = await objectBlock.saveAnyLocalImage(
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
      context.push(
        '/projects/editor',
        extra: {'category': 'social', 'initialImage': savedPath},
      );
    }
  }

  static const _moodChartDays = 14;

  Widget _buildJournalMoodTrendsPanel(
    BuildContext context,
    String personId,
    ColorScheme colorScheme,
    TextTheme textTheme,
    bool isDark,
  ) {
    final mindBlock = context.read<MindBlock>();
    final notesDao = context.read<ProjectNoteDAO>();

    return StreamBuilder<List<ProjectNoteData>>(
      stream: notesDao.watchNotesByCategory(personId, 'social'),
      builder: (context, notesSnap) {
        return StreamBuilder<List<MindLogData>>(
          stream: mindBlock.watchMindLogsRange(personId, _moodChartDays),
          builder: (context, logsSnap) {
            final merged = MindLogInsights.mergeNotesWithMindLogs(
              mindLogs: logsSnap.data ?? const [],
              journalNotes: notesSnap.data ?? const [],
              days: _moodChartDays,
            );

            if (merged.isEmpty) {
              return const SizedBox.shrink();
            }

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
              decoration: HealthMetricColors.shellPanel(
                colorScheme,
                isDark: isDark,
                radius: 22,
                accent: HealthMetricColors.pillarViolet,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!
                        .mood_trends_title
                        .toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  MoodTrendsChart(logs: merged, groupByDay: true),
                  const SizedBox(height: 16),
                  _buildRecentLogsPreview(context, merged, personId),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)!
                        .social_notes_title
                        .toUpperCase(),
                    style: textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _NoteCardLayout { grid, list }

int _noteMoodScore(String? mood) {
  return switch (mood?.toLowerCase()) {
    'awful' => 1,
    'bad' => 2,
    'meh' => 3,
    'good' => 4,
    'awesome' => 5,
    _ => 3,
  };
}

IconData _noteMoodIcon(String? mood) {
  return switch (mood?.toLowerCase()) {
    'awesome' => Icons.sentiment_very_satisfied_rounded,
    'good' => Icons.sentiment_satisfied_alt_rounded,
    'meh' => Icons.sentiment_neutral_rounded,
    'bad' => Icons.sentiment_dissatisfied_rounded,
    'awful' => Icons.sentiment_very_dissatisfied_rounded,
    _ => Icons.sentiment_neutral_rounded,
  };
}

class _SocialNoteCard extends StatelessWidget {
  final ProjectNoteData note;
  final _NoteCardLayout layout;

  const _SocialNoteCard({
    required this.note,
    this.layout = _NoteCardLayout.grid,
  });

  Color get _moodColor => mindMoodAccent(_noteMoodScore(note.mood));

  @override
  Widget build(BuildContext context) {
    return layout == _NoteCardLayout.list
        ? _buildListCard(context)
        : _buildGridCard(context);
  }

  Widget _moodBubble({double size = 46}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(_moodColor, Colors.white, 0.15) ?? _moodColor,
            _moodColor.withValues(alpha: 0.65),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _moodColor.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(
        _noteMoodIcon(note.mood),
        size: size * 0.48,
        color: Colors.white,
      ),
    );
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = note.localPath ??
        _getPreviewImage(note.content) ??
        note.remotePath;
    final remoteKey = note.remotePath ??
        JournalMedia.canonicalRemotePath(imageUrl, personId: note.personID);
    final previewText = _getPreviewText(note.content);

    return Hero(
      tag: 'note_${note.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/projects/editor', extra: note),
          borderRadius: BorderRadius.circular(22),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: isDark
                  ? colorScheme.surface.withValues(alpha: 0.55)
                  : colorScheme.surface,
              border: Border.all(
                color: _moodColor.withValues(alpha: 0.22),
              ),
              boxShadow: [
                BoxShadow(
                  color: _moodColor.withValues(alpha: 0.1),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _moodBubble(size: 50),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              note.title,
                              style: textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('MMM d').format(note.updatedAt),
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      if (previewText.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          previewText,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.72),
                            height: 1.4,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (imageUrl != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: SizedBox(
                            height: 88,
                            width: double.infinity,
                            child: LocalFirstImage(
                              ownerId: note.personID ?? '',
                              localPath: note.localPath ?? imageUrl,
                              remoteUrl: _s3RemoteUrl(remoteKey, note.personID),
                              subFolder: 'user_markdown_documentation',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = note.localPath ??
        _getPreviewImage(note.content) ??
        note.remotePath;
    final remoteKey = note.remotePath ??
        JournalMedia.canonicalRemotePath(imageUrl, personId: note.personID);
    final previewText = _getPreviewText(note.content);

    return Hero(
      tag: 'note_${note.id}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _moodColor.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: _moodColor.withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: isDark
                ? colorScheme.surface.withValues(alpha: 0.62)
                : colorScheme.surface,
            child: InkWell(
              onTap: () => context.push('/projects/editor', extra: note),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 2.2,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          LocalFirstImage(
                            ownerId: note.personID ?? "",
                            localPath: note.localPath ?? imageUrl,
                            remoteUrl: _s3RemoteUrl(remoteKey, note.personID),
                            subFolder: "user_markdown_documentation",
                            fit: BoxFit.cover,
                          )
                        else
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  _moodColor.withValues(alpha: 0.38),
                                  _moodColor.withValues(alpha: 0.12),
                                  colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: _moodBubble(size: 36),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              DateFormat('MMM d').format(note.updatedAt),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.15,
                              height: 1.25,
                              fontSize: 14,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (previewText.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Expanded(
                              child: Text(
                                previewText,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.72,
                                  ),
                                  height: 1.45,
                                  fontSize: 12.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    if (content.isEmpty) return "";

    var plainText = JournalMedia.extractPlainBody(content);
    // Strip images: ![alt](url)
    plainText = plainText.replaceAll(RegExp(r'!\[.*?\]\((.*?)\)'), '');
    // Strip links: [text](url) -> text
    plainText = plainText.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\)'),
      (match) => match.group(1) ?? '',
    );
    // Strip bold/italic: **bold**, __bold__, *italic*, _italic_
    plainText = plainText.replaceAll(RegExp(r'(\*\*|__|\*|_|~~)'), '');
    // Strip headers: # Header
    plainText = plainText.replaceAll(RegExp(r'^#+\s+', multiLine: true), '');
    // Strip horizontal rules
    plainText = plainText.replaceAll(
      RegExp(r'^\s*([-*_])\s*\1\s*\1\s*$', multiLine: true),
      '',
    );
    // Strip multiple newlines
    plainText = plainText.replaceAll(RegExp(r'\n+'), ' ');

    return plainText.trim();
  }

  String? _getPreviewImage(String content) {
    return JournalMedia.extractFirstImagePath(content);
  }

  static Widget _deviceBadge(String device) {
    final icon = switch (device) {
      'ios' => Icons.phone_iphone_rounded,
      'mac' => Icons.laptop_mac_rounded,
      'android' => Icons.phone_android_rounded,
      _ => Icons.devices_rounded,
    };
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, size: 12, color: Colors.white70),
    );
  }

  static String _s3RemoteUrl(String? remoteKey, String? personId) {
    if (remoteKey == null || remoteKey.isEmpty) return '';
    if (remoteKey.startsWith('http://') || remoteKey.startsWith('https://')) {
      return remoteKey;
    }
    final normalized = remoteKey.replaceAll('\\', '/');
    final key = normalized.contains('/')
        ? normalized
        : (personId != null && personId.isNotEmpty
            ? '$personId/user_markdown_documentation/${p.basename(normalized)}'
            : normalized);
    return MinioService().publicUrlForKey(key);
  }
}
