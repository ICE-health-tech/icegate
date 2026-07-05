import 'package:ice_gate/orchestration_layer/Services/HomelabHostPolicy.dart';

/// How saved credentials are applied when opening a dev-tool WebView.
enum DevQuickTabLoginType {
  /// Classic admin UI (OPNsense, pfSense) — username + password inputs.
  htmlForm('html_form'),

  /// SPA email login (Supabase, Northflank) — email + password.
  emailPassword('email_password'),

  /// HTTP Basic Auth challenge only — no JS injection.
  httpBasic('http_basic'),

  /// API key field (Northflank, generic APIs).
  apiKey('api_key'),

  /// Bearer token only (Kubernetes Dashboard, JWT login).
  bearerToken('bearer_token'),

  /// GitHub / Google SSO — open in Safari/Chrome, no WebView autofill.
  externalBrowser('external_browser'),

  /// GitHub / Google SSO — manual login in WebView.
  oauth('oauth'),

  /// Do not autofill.
  none('none');

  const DevQuickTabLoginType(this.storageKey);

  final String storageKey;

  static DevQuickTabLoginType fromStorage(String? raw) {
    if (raw == null || raw.isEmpty) return DevQuickTabLoginType.htmlForm;
    for (final type in DevQuickTabLoginType.values) {
      if (type.storageKey == raw) return type;
    }
    return DevQuickTabLoginType.htmlForm;
  }

  /// Default when user has not picked a type yet.
  static DevQuickTabLoginType inferForHost(String host) {
    final h = host.trim().toLowerCase();
    if (h.isEmpty) return DevQuickTabLoginType.none;
    if (h.contains('k8s') || h.contains('kubernetes')) {
      return DevQuickTabLoginType.bearerToken;
    }
    if (HomelabHostPolicy.isPrivateLan(host)) {
      return DevQuickTabLoginType.htmlForm;
    }
    if (h.contains('github') ||
        h.contains('google') ||
        h.contains('accounts.google')) {
      return DevQuickTabLoginType.externalBrowser;
    }
    if (h.contains('supabase') ||
        h.contains('northflank') ||
        h.contains('n8n')) {
      return DevQuickTabLoginType.emailPassword;
    }
    return DevQuickTabLoginType.emailPassword;
  }

  /// URL-aware inference (dashboard paths on bare IPs).
  static DevQuickTabLoginType inferForUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return DevQuickTabLoginType.none;
    final blob = '${uri.host} ${uri.path} ${uri.fragment}'.toLowerCase();
    if (blob.contains('k8s') || blob.contains('kubernetes')) {
      return DevQuickTabLoginType.bearerToken;
    }
    return inferForHost(uri.host);
  }

  bool get usesTokenField => this == apiKey || this == bearerToken;

  bool get opensExternally => this == externalBrowser;

  bool get usesJsAutofill =>
      this == htmlForm ||
      this == emailPassword ||
      this == apiKey ||
      this == bearerToken;
}
