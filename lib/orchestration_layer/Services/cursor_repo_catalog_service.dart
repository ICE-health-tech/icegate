import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// A GitHub repo the user can target from Cursor Hub (cloud mode).
class CursorRepoEntry {
  const CursorRepoEntry({
    required this.name,
    required this.httpsUrl,
    this.localPath,
    this.isPrivate = false,
  });

  final String name;
  final String httpsUrl;
  final String? localPath;
  final bool isPrivate;

  @override
  bool operator ==(Object other) =>
      other is CursorRepoEntry && httpsUrl == other.httpsUrl;

  @override
  int get hashCode => httpsUrl.hashCode;
}

/// Discovers GitHub repos from local clones and the public GitHub API.
class CursorRepoCatalogService {
  CursorRepoCatalogService._();
  static final CursorRepoCatalogService instance = CursorRepoCatalogService._();

  static const _githubUser = 'DuyLongArt';
  static const _localRoots = [
    '/Users/duylong/Code/Flutter',
    '/Users/duylong/Code/PersonalProject',
    '/Users/duylong/Code/App',
    '/Users/duylong/Code/Backend',
    '/Users/duylong/Code/AI',
  ];

  List<CursorRepoEntry>? _cache;

  /// Normalizes `git@github.com:org/repo.git` → `https://github.com/org/repo`.
  static String? normalizeGitHubHttpsUrl(String? remote) {
    if (remote == null || remote.trim().isEmpty) return null;
    var r = remote.trim();
    if (r.startsWith('git@github.com:')) {
      r = 'https://github.com/${r.substring('git@github.com:'.length)}';
    }
    if (!r.startsWith('https://github.com/')) return null;
    if (r.endsWith('.git')) r = r.substring(0, r.length - 4);
    return r;
  }

  Future<List<CursorRepoEntry>> loadRepos({bool forceRefresh = false}) async {
    if (!forceRefresh && _cache != null) return _cache!;

    final merged = <String, CursorRepoEntry>{};

    for (final entry in await _loadLocalRepos()) {
      merged[entry.httpsUrl] = entry;
    }
    for (final entry in await _loadGitHubApiRepos()) {
      merged.putIfAbsent(entry.httpsUrl, () => entry);
    }

    final list = merged.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _cache = list;
    return list;
  }

  Future<List<CursorRepoEntry>> _loadLocalRepos() async {
    if (!Platform.isMacOS && !Platform.isLinux) return [];

    final results = <CursorRepoEntry>[];
    for (final root in _localRoots) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;

      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final gitDir = Directory('${entity.path}/.git');
        if (!await gitDir.exists()) continue;

        try {
          final remote = await Process.run(
            'git',
            ['-C', entity.path, 'remote', 'get-url', 'origin'],
          );
          if (remote.exitCode != 0) continue;
          final url = normalizeGitHubHttpsUrl(
            (remote.stdout as String).trim(),
          );
          if (url == null) continue;

          final name = url.split('/').last;
          results.add(
            CursorRepoEntry(
              name: name,
              httpsUrl: url,
              localPath: entity.path,
            ),
          );
        } catch (_) {}
      }
    }
    return results;
  }

  Future<List<CursorRepoEntry>> _loadGitHubApiRepos() async {
    try {
      final uri = Uri.parse(
        'https://api.github.com/users/$_githubUser/repos'
        '?per_page=100&sort=updated&type=all',
      );
      final response = await http.get(
        uri,
        headers: {'Accept': 'application/vnd.github+json'},
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) return [];

      final list = jsonDecode(response.body);
      if (list is! List) return [];

      return list
          .whereType<Map<String, dynamic>>()
          .map((json) {
            final name = json['name'] as String? ?? '';
            final htmlUrl = json['html_url'] as String?;
            if (htmlUrl == null || name.isEmpty) return null;
            return CursorRepoEntry(
              name: name,
              httpsUrl: htmlUrl,
              isPrivate: json['private'] == true,
            );
          })
          .whereType<CursorRepoEntry>()
          .toList();
    } catch (_) {
      return [];
    }
  }
}
