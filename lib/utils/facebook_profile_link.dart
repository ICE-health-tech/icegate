/// Parse / normalize Facebook profile URLs (no Graph API — link + manual avatar only).
abstract final class FacebookProfileLink {
  FacebookProfileLink._();

  static final _hostPattern = RegExp(
    r'(?:https?://)?(?:www\.|m\.|mbasic\.)?facebook\.com',
    caseSensitive: false,
  );

  /// Returns a canonical `https://www.facebook.com/...` URL, or null if invalid.
  static String? normalize(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    var input = trimmed;
    if (!_hostPattern.hasMatch(input) && !input.contains('fb.com')) {
      final handle = input.replaceAll(RegExp(r'^@'), '');
      if (handle.isEmpty || handle.contains(' ')) return null;
      input = 'https://www.facebook.com/$handle';
    }

    Uri? uri;
    try {
      uri = Uri.parse(input);
    } catch (_) {
      return null;
    }

    final host = uri.host.toLowerCase();
    if (host != 'facebook.com' &&
        host != 'www.facebook.com' &&
        host != 'm.facebook.com' &&
        host != 'mbasic.facebook.com' &&
        host != 'fb.com' &&
        host != 'www.fb.com') {
      return null;
    }

    if (uri.pathSegments.isEmpty && uri.queryParameters['id'] == null) {
      return null;
    }

    if (uri.path.toLowerCase().contains('profile.php')) {
      final id = uri.queryParameters['id'];
      if (id == null || id.isEmpty) return null;
      return 'https://www.facebook.com/profile.php?id=$id';
    }

    final segments =
        uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final head = segments.first.toLowerCase();

    // Share links copied from the Facebook app (e.g. /share/1RSZDgpkJR).
    if (head == 'share' && segments.length >= 2) {
      final path = segments.map((s) => Uri.encodeComponent(s)).join('/');
      return 'https://www.facebook.com/$path';
    }

    const reserved = {
      'people',
      'pages',
      'groups',
      'events',
      'watch',
      'marketplace',
      'gaming',
      'photo.php',
      'story.php',
      'sharer',
      'login',
      'dialog',
    };
    if (reserved.contains(head)) return null;

    if (head == 'profile.php') {
      final id = uri.queryParameters['id'];
      if (id == null || id.isEmpty) return null;
      return 'https://www.facebook.com/profile.php?id=$id';
    }

    return 'https://www.facebook.com/${segments.first}';
  }

  /// True when [normalize] accepts the input.
  static bool isValid(String raw) => normalize(raw) != null;

  /// Best-effort display name from URL path (not from Facebook API).
  static String? suggestedName(String? normalizedUrl) {
    if (normalizedUrl == null) return null;
    final uri = Uri.parse(normalizedUrl);
    if (uri.path.toLowerCase().contains('profile.php')) {
      final id = uri.queryParameters['id'];
      return id != null ? 'Facebook $id' : null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (segments.first.toLowerCase() == 'share') return null;
    final slug = segments.first;
    final cleaned = slug.replaceAll(RegExp(r'[._-]+'), ' ').trim();
    if (cleaned.isEmpty) return null;
    return cleaned
        .split(' ')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final chars = parts.take(2).map((p) => p[0].toUpperCase());
    final joined = chars.join();
    return joined.isEmpty ? '?' : joined;
  }
}
