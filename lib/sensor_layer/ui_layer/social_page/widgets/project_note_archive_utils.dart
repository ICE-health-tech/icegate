import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/utils/journal_media.dart';

/// Filters + grouping for the memory archive (`project_notes` table).
abstract final class ProjectNoteArchiveUtils {
  ProjectNoteArchiveUtils._();

  /// Life-archive notes created from Projects hub → Social → Thành tựu.
  static const String archiveCategory = 'note';

  static String? imagePath(ProjectNoteData note) {
    final local = note.localPath?.trim();
    if (local != null && local.isNotEmpty) return local;
    return JournalMedia.extractFirstImagePath(note.content);
  }

  static String? imageRemotePath(ProjectNoteData note) {
    final remote = note.remotePath?.trim();
    if (remote != null && remote.isNotEmpty) return remote;
    return JournalMedia.canonicalRemotePath(
      imagePath(note),
      personId: note.personID,
    );
  }

  static String imageSubFolder(String? path) {
    final normalized = path?.replaceAll('\\', '/') ?? '';
    if (normalized.contains('/memories/')) return 'memories';
    return 'user_markdown_documentation';
  }

  static bool hasPhoto(ProjectNoteData note) {
    final path = imagePath(note);
    return path != null && path.isNotEmpty;
  }

  static String plainBody(ProjectNoteData note) {
    return JournalMedia.extractPlainBody(note.content);
  }

  static String moodDisplay(ProjectNoteData note) {
    final mood = note.mood?.trim();
    if (mood != null && mood.isNotEmpty) return mood;
    return '📖';
  }

  static Color ringColorForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'note':
        return const Color(0xFFE8C07A);
      case 'social':
        return Colors.cyanAccent;
      case 'project_log':
        return Colors.greenAccent;
      case 'projects':
        return Colors.lightBlueAccent;
      default:
        return Colors.amberAccent;
    }
  }

  static bool matchesMonth(ProjectNoteData note, DateTime? month) {
    if (month == null) return true;
    final local = note.createdAt.toLocal();
    return local.year == month.year && local.month == month.month;
  }

  static bool matchesProject(ProjectNoteData note, String? projectId) {
    if (projectId == null || projectId.isEmpty) return true;
    final stored = note.projectID?.trim();
    if (stored == null || stored.isEmpty) return false;
    return stored == projectId;
  }

  static List<ProjectNoteData> applyFilters(
    List<ProjectNoteData> all, {
    DateTime? month,
    String? projectId,
  }) {
    return all
        .where(
          (n) => matchesMonth(n, month) && matchesProject(n, projectId),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<ProjectNoteData> photoMemories(List<ProjectNoteData> all) {
    return all.where(hasPhoto).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<ProjectNoteData> timeline(List<ProjectNoteData> filtered) {
    return List<ProjectNoteData>.from(filtered)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static List<ProjectNoteData> onThisDayMemories(
    List<ProjectNoteData> all, {
    DateTime? reference,
  }) {
    final now = (reference ?? DateTime.now()).toLocal();
    return all
        .where((n) {
          final d = n.createdAt.toLocal();
          return d.month == now.month &&
              d.day == now.day &&
              d.year < now.year;
        })
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  static int yearsAgo(DateTime date, {DateTime? reference}) {
    final now = (reference ?? DateTime.now()).toLocal();
    return now.year - date.toLocal().year;
  }

  static List<ProjectNoteMonthGroup> groupByMonth(List<ProjectNoteData> items) {
    final buckets = <DateTime, List<ProjectNoteData>>{};
    for (final note in items) {
      final d = note.createdAt.toLocal();
      final key = DateTime(d.year, d.month);
      buckets.putIfAbsent(key, () => []).add(note);
    }
    final months = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return months
        .map((m) => ProjectNoteMonthGroup(month: m, items: buckets[m]!))
        .toList();
  }

  static List<DateTime> recentMonths({int count = 12}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i);
      return DateTime(d.year, d.month);
    });
  }

  static String? routeProjectId(
    String? storedId,
    List<ProjectProtocol> projects,
  ) {
    if (storedId == null || storedId.trim().isEmpty) return null;
    for (final p in projects) {
      if (p.id == storedId || p.projectID == storedId) return p.id;
    }
    return storedId;
  }

  static String projectLabel(
    ProjectNoteData note,
    List<ProjectProtocol> projects,
  ) {
    final stored = note.projectID?.trim();
    if (stored != null && stored.isNotEmpty) {
      for (final p in projects) {
        if (p.id == stored || p.projectID == stored) return p.name;
      }
    }
    return '';
  }

  static List<ProjectProtocol> projectsWithNotes(
    List<ProjectNoteData> all,
    List<ProjectProtocol> projects,
  ) {
    final ids = <String>{};
    for (final n in all) {
      final id = n.projectID?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return const [];

    return projects.where((p) {
      return ids.contains(p.id) || ids.contains(p.projectID);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class ProjectNoteMonthGroup {
  const ProjectNoteMonthGroup({required this.month, required this.items});

  final DateTime month;
  final List<ProjectNoteData> items;
}
