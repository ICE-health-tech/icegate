import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';

/// Filters + project labels for achievements tab (stories + unified feed).
abstract final class AchievementFeedUtils {
  AchievementFeedUtils._();

  static DateTime monthKey(DateTime dt) => DateTime(dt.year, dt.month);

  static bool matchesMonth(AchievementData a, DateTime? month) {
    if (month == null) return true;
    final local = a.createdAt.toLocal();
    return local.year == month.year && local.month == month.month;
  }

  static bool matchesProject(AchievementData a, String? projectId) {
    if (projectId == null || projectId.isEmpty) return true;
    final stored = a.projectID?.trim();
    if (stored == null || stored.isEmpty) return false;
    return stored == projectId;
  }

  static List<AchievementData> applyFilters(
    List<AchievementData> all, {
    DateTime? month,
    String? projectId,
  }) {
    return all
        .where(
          (a) => matchesMonth(a, month) && matchesProject(a, projectId),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Photo stories + text feats in one timeline (newest first).
  static List<AchievementData> unifiedFeed(List<AchievementData> filtered) {
    return List<AchievementData>.from(filtered)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Same calendar day in a previous year — "On this day" nostalgia.
  static List<AchievementData> onThisDayMemories(
    List<AchievementData> all, {
    DateTime? reference,
  }) {
    final now = (reference ?? DateTime.now()).toLocal();
    return all
        .where((a) {
          final d = a.createdAt.toLocal();
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

  static List<AchievementMonthGroup> groupByMonth(List<AchievementData> items) {
    final buckets = <DateTime, List<AchievementData>>{};
    for (final a in items) {
      final d = a.createdAt.toLocal();
      final key = DateTime(d.year, d.month);
      buckets.putIfAbsent(key, () => []).add(a);
    }
    final months = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
    return months
        .map((m) => AchievementMonthGroup(month: m, items: buckets[m]!))
        .toList();
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
    AchievementData a,
    List<ProjectProtocol> projects,
  ) {
    final stored = a.projectID?.trim();
    if (stored != null && stored.isNotEmpty) {
      for (final p in projects) {
        if (p.id == stored || p.projectID == stored) return p.name;
      }
    }
    final legacy = a.impactDescHow.trim();
    if (legacy.isNotEmpty && legacy != 'You') return legacy;
    return '';
  }

  static List<DateTime> recentMonths({int count = 12}) {
    final now = DateTime.now();
    return List.generate(count, (i) {
      final d = DateTime(now.year, now.month - i);
      return DateTime(d.year, d.month);
    });
  }

  static List<ProjectProtocol> projectsWithAchievements(
    List<AchievementData> all,
    List<ProjectProtocol> projects,
  ) {
    final ids = <String>{};
    for (final a in all) {
      final id = a.projectID?.trim();
      if (id != null && id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return const [];

    return projects.where((p) {
      return ids.contains(p.id) || ids.contains(p.projectID);
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class AchievementMonthGroup {
  const AchievementMonthGroup({required this.month, required this.items});

  final DateTime month;
  final List<AchievementData> items;
}
