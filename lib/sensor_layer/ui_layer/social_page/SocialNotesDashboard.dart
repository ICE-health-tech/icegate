import 'dart:convert';

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
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/MindBlock.dart';
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
                        child: StreamBuilder<List<MindLogData>>(
                          stream: context.read<MindBlock>().watchMindLogsRange(
                            personId,
                            7,
                          ),
                          builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                              AppLocalizations.of(context)!.mood_trends_title.toUpperCase(),
                              style: textTheme.labelSmall?.copyWith(
                                letterSpacing: 1.4,
                                fontWeight: FontWeight.w900,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 12),
                            MoodTrendsChart(logs: snapshot.data!),
                            const SizedBox(height: 16),
                            _buildRecentLogsPreview(
                              context,
                              snapshot.data!,
                              personId,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.social_notes_title.toUpperCase(),
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
                    var crossCount = 2;
                    var aspect = 0.82;
                    var gap = 14.0;
                    var hPad = 16.0;
                    final bottomPad = _bottomClearance(context);
                    if (cw >= 1200) {
                      crossCount = 5;
                      aspect = 0.88;
                      gap = 14;
                      hPad = 32;
                    } else if (cw >= 900) {
                      crossCount = 4;
                      aspect = 0.86;
                      gap = 14;
                      hPad = 28;
                    } else if (cw >= 640) {
                      crossCount = 3;
                      aspect = 0.84;
                      gap = 14;
                      hPad = 20;
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(hPad, 8, hPad, bottomPad),
                      sliver: SliverGrid(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossCount,
                          crossAxisSpacing: gap,
                          mainAxisSpacing: gap,
                          childAspectRatio: aspect,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _SocialNoteCard(
                            note: sortedNotes[index],
                            accent: HealthMetricColors.pillarAccentAt(index),
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
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (image != null && context.mounted) {
      final personBlock = context.read<PersonBlock>();
      final objectBlock = context.read<ObjectDatabaseBlock>();
      final personId = personBlock.currentPersonID.value;

      final savedPath = await objectBlock.saveAnyLocalImage(
        image,
        subFolder: 'user_markdown_documentation',
        personId: personId,
      );

      if (context.mounted) {
        context.push(
          '/projects/editor',
          extra: {'category': 'social', 'initialImage': savedPath},
        );
      }
    }
  }
}

class _SocialNoteCard extends StatelessWidget {
  final ProjectNoteData note;
  final Color accent;

  const _SocialNoteCard({
    required this.note,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final imageUrl = _getPreviewImage(note.content);
    final previewText = _getPreviewText(note.content);

    return Hero(
      tag: 'note_${note.id}',
      child: Container(
        decoration: HealthMetricColors.shellPanel(
          colorScheme,
          isDark: isDark,
          radius: 20,
          accent: HealthMetricColors.pillarViolet,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: isDark
                ? HealthMetricColors.shellIslandFill
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.82),
            child: InkWell(
              onTap: () => context.push('/projects/editor', extra: note),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AspectRatio(
                    aspectRatio: 1.45,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (imageUrl != null)
                          LocalFirstImage(
                            ownerId: note.personID ?? "",
                            localPath: imageUrl,
                            remoteUrl: _s3RemoteUrl(imageUrl, note.personID),
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
                                  accent.withValues(alpha: 0.38),
                                  accent.withValues(alpha: 0.14),
                                  colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.65),
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.auto_awesome_rounded,
                              color: accent.withValues(alpha: 0.55),
                              size: 32,
                            ),
                          ),
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.45),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Text(
                            DateFormat('MMM d').format(note.updatedAt),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (note.mood != null && note.mood!.isNotEmpty)
                          Positioned(
                            bottom: 10,
                            right: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.92,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                note.mood!.toUpperCase(),
                                style: TextStyle(
                                  color: colorScheme.onPrimary,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.2,
                              height: 1.2,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Expanded(
                            child: Text(
                              previewText,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.78,
                                ),
                                height: 1.35,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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

    String plainText = content;

    // 1. Handle JSON (Quill Delta)
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];
            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        plainText = buffer.toString();
      }
    } catch (_) {}

    // 2. STICKY FIX: Robust Markdown Strip
    // Strip images: ![alt](url)
    plainText = plainText.replaceAll(RegExp(r'!\[.*?\]\((.*?)\)'), '');
    // Strip links: [text](url) -> text
    plainText = plainText.replaceAllMapped(
      RegExp(r'\[(.*?)\]\(.*?\文明\)'),
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
    if (content.isEmpty) return null;

    String textToSearch = content;

    // 1. Handle JSON (Quill Delta)
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op.containsKey('insert')) {
            final insert = op['insert'];

            // Check for direct image map
            if (insert is Map && insert.containsKey('image')) {
              return insert['image'] as String;
            }

            if (insert is String) {
              buffer.write(insert);
            }
          }
        }
        textToSearch = buffer.toString();
      }
    } catch (_) {}

    // 2. Robust Markdown extraction
    // Also support standard markdown image
    final regExp = RegExp(r'!\[.*?\]\((.*?)\)');
    final match = regExp.firstMatch(textToSearch);
    if (match != null && match.groupCount >= 1) {
      return match.group(1);
    }

    return null;
  }

  static String _s3RemoteUrl(String? localPath, String? personId) {
    if (localPath == null || localPath.isEmpty) return '';
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
