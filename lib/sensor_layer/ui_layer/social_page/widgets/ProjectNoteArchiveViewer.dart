import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveActions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/ProjectNoteArchiveWarm.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/project_note_archive_utils.dart';
import 'package:intl/intl.dart';

/// Full-screen photo memory viewer for [project_notes].
class ProjectNoteArchiveViewer extends StatefulWidget {
  const ProjectNoteArchiveViewer({
    super.key,
    required this.notes,
    this.initialIndex = 0,
    this.projects = const [],
  });

  final List<ProjectNoteData> notes;
  final int initialIndex;
  final List<ProjectProtocol> projects;

  @override
  State<ProjectNoteArchiveViewer> createState() =>
      _ProjectNoteArchiveViewerState();
}

class _ProjectNoteArchiveViewerState extends State<ProjectNoteArchiveViewer> {
  late PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.notes.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0 || next >= widget.notes.length) {
      Navigator.maybePop(context);
      return;
    }
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.notes.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final note = widget.notes[i];
              final ring = ProjectNoteArchiveUtils.ringColorForCategory(
                note.category,
              );
              final projectLabel = ProjectNoteArchiveUtils.projectLabel(
                note,
                widget.projects,
              );
              final routeProjectId = ProjectNoteArchiveUtils.routeProjectId(
                note.projectID,
                widget.projects,
              );
              final body = ProjectNoteArchiveUtils.plainBody(note);
              final years = ProjectNoteArchiveUtils.yearsAgo(note.createdAt);
              final yearsLabel = years > 0
                  ? l10n.achievement_years_ago(years)
                  : null;

              return Stack(
                fit: StackFit.expand,
                children: [
                  ProjectNoteArchiveImage(
                    note: note,
                    fit: BoxFit.contain,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0, 0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: padding.bottom + 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (yearsLabel != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              yearsLabel,
                              style: TextStyle(
                                color: ProjectNoteArchiveWarm.accent
                                    .withValues(alpha: 0.95),
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ring.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ring.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            (note.category).toUpperCase(),
                            style: TextStyle(
                              color: ring,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          note.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if (body.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            body,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          DateFormat.yMMMd().format(note.createdAt.toLocal()),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        if (projectLabel.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            projectLabel,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            if (routeProjectId != null)
                              FilledButton.tonalIcon(
                                style: FilledButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.14),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.push('/projects/$routeProjectId');
                                },
                                icon: const Icon(
                                  Icons.folder_open_outlined,
                                  size: 18,
                                ),
                                label: Text(l10n.achievement_open_project),
                              ),
                            const SizedBox(width: 8),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor:
                                    Colors.white.withValues(alpha: 0.14),
                              ),
                              onPressed: () {
                                Navigator.pop(context);
                                ProjectNoteArchiveActions.openNote(
                                  context,
                                  note,
                                );
                              },
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              label: Text(l10n.project_notes_label),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
                child: IconButton.filled(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _go(-1),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _go(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
