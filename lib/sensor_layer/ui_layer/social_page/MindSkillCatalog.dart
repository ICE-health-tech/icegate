/// Canonical mind / project skill names (matches [MindSkillsView] tiles).
abstract final class MindSkillCatalog {
  /// Per-person master list in `skills.skill_category`.
  static String personLibraryCategory() => 'person:library';

  /// Legacy category from early Skill Boost XP rows.
  static bool isPersonLibrary(String? category) =>
      category == personLibraryCategory() || category == 'mind:boost';

  static const List<String> defaults = <String>[
    'Meta Mental',
    'Adaptation',
    'Health',
    'Presentation',
    'Focus',
    'Logic',
    'Design',
    'Syntax',
    'Growth',
    'Spirit',
  ];

  static bool namesMatch(String a, String b) =>
      a.trim().toLowerCase() == b.trim().toLowerCase();

  static const int maxNameLength = 24;

  /// Standard display name: trim, single spaces, Title Case, max [maxNameLength].
  static String? normalizeName(String raw) {
    var s = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (s.isEmpty) return null;
    if (s.length > maxNameLength) return null;
    s = s
        .split(' ')
        .map((w) {
          if (w.isEmpty) return w;
          if (w.length == 1) return w.toUpperCase();
          return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
        })
        .join(' ');
    for (final d in defaults) {
      if (namesMatch(d, s)) return d;
    }
    return s;
  }

  /// One tile per skill name (case-insensitive), first occurrence wins.
  static List<String> dedupeNames(Iterable<String> names) {
    final out = <String>[];
    for (final raw in names) {
      final name = raw.trim();
      if (name.isEmpty) continue;
      if (out.any((s) => namesMatch(s, name))) continue;
      out.add(name);
    }
    return out;
  }
}
