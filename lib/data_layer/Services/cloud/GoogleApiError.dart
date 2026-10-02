/// Classifies Google REST / Sign-In failures for user-facing messages.
class GoogleApiError {
  GoogleApiError._();

  static const apiNotEnabled = 'api_not_enabled';
  static const insufficientScopes = 'insufficient_scopes';
  static const forbidden = 'forbidden';
  static const cancelled = 'cancelled';
  static const scopeDenied = 'scope_denied';
  static const unknown = 'unknown';

  static String classify(Object? error) {
    if (error == null) return unknown;
    if (error is String) {
      switch (error) {
        case apiNotEnabled:
        case insufficientScopes:
        case forbidden:
        case cancelled:
        case scopeDenied:
          return error;
      }
    }
    final s = error.toString().toLowerCase();
    if (s.contains('has not been used in project') ||
        s.contains('it is disabled') ||
        s.contains('accessnotconfigured')) {
      return apiNotEnabled;
    }
    if (s.contains('insufficient authentication scopes')) {
      return insufficientScopes;
    }
    if (s.contains('status: 403')) return forbidden;
    if (error == cancelled || s.contains('cancelled')) return cancelled;
    if (error == scopeDenied) return scopeDenied;
    return unknown;
  }

  /// Console link from API error text, or [fallbackProjectId].
  static String? calendarApiConsoleUrl(Object? error, {String? fallbackProjectId}) {
    final match = RegExp(r'project[=\s](\d+)', caseSensitive: false)
        .firstMatch(error?.toString() ?? '');
    final projectId = match?.group(1) ?? fallbackProjectId;
    if (projectId == null || projectId.isEmpty) return null;
    return 'https://console.developers.google.com/apis/api/calendar-json.googleapis.com/overview?project=$projectId';
  }
}
