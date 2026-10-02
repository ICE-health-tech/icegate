import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/DevTools/DevQuickTabLoginType.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/HomelabHostPolicy.dart';
import 'package:ice_gate/orchestration_layer/Services/WebViewCredentialStore.dart';
import 'package:ice_gate/orchestration_layer/Services/WebViewLoginAutofillScript.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:webview_flutter/webview_flutter.dart' as wv;
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Optional chrome trimming and layout for [EmbeddedWebViewWidget].
class WebViewDisplayOptions {
  const WebViewDisplayOptions({
    this.showFloatingRefresh = true,
    this.trimGoogleCalendarChrome = false,
    this.contentPadding,
  });

  final bool showFloatingRefresh;
  final bool trimGoogleCalendarChrome;
  final EdgeInsets? contentPadding;

  static WebViewDisplayOptions forUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase() ?? '';
    final isGoogleCalendar = host.contains('calendar.google');
    return WebViewDisplayOptions(
      showFloatingRefresh: !isGoogleCalendar,
      trimGoogleCalendarChrome: isGoogleCalendar,
      contentPadding: isGoogleCalendar
          ? const EdgeInsets.only(bottom: 8)
          : null,
    );
  }

  WebViewDisplayOptions copyWith({
    bool? showFloatingRefresh,
    bool? trimGoogleCalendarChrome,
    EdgeInsets? contentPadding,
  }) {
    return WebViewDisplayOptions(
      showFloatingRefresh: showFloatingRefresh ?? this.showFloatingRefresh,
      trimGoogleCalendarChrome:
          trimGoogleCalendarChrome ?? this.trimGoogleCalendarChrome,
      contentPadding: contentPadding ?? this.contentPadding,
    );
  }
}

class EmbeddedWebViewWidget extends StatefulWidget {
  final String url;
  final bool showControls;
  final WebViewDisplayOptions displayOptions;

  /// Optional handle for parent widgets (e.g. app bar refresh).
  final EmbeddedWebViewHandle? handle;

  EmbeddedWebViewWidget({
    super.key,
    required this.url,
    this.showControls = true,
    this.handle,
    WebViewDisplayOptions? displayOptions,
  }) : displayOptions =
            displayOptions ?? WebViewDisplayOptions.forUrl(url);

  @override
  State<EmbeddedWebViewWidget> createState() => _EmbeddedWebViewWidgetState();
}

class EmbeddedWebViewHandle {
  Future<void> Function()? reload;
  Future<void> Function()? signOut;
  Future<bool> Function()? canGoBack;
  Future<bool> Function()? canGoForward;
  Future<void> Function()? goBack;
  Future<void> Function()? goForward;
  Future<String?> Function()? currentUrl;
  /// Like Chrome "Advanced → Proceed" for self-signed homelab HTTPS certs.
  Future<void> Function()? trustHomelabCertificate;
  VoidCallback? onHistoryChanged;
}

class _EmbeddedWebViewWidgetState extends State<EmbeddedWebViewWidget> {
  wv.WebViewController? _controller;
  final WebViewCredentialStore _credentialStore = WebViewCredentialStore();
  bool _isLoading = true;
  double _progress = 0.0;
  String? _errorMessage;
  int _loadGeneration = 0;

  static const _calendarChromeScript = '''
(function() {
  try {
    var style = document.createElement('style');
    style.textContent = [
      'footer, [role="contentinfo"] { display: none !important; }',
      '.AzWLWb.vcursor-pointer { display: none !important; }',
      'body { margin: 0 !important; overflow-x: hidden !important; }'
    ].join('\\n');
    document.head.appendChild(style);
  } catch (e) {}
})();
''';

  Uri get _pageUri => Uri.parse(widget.url);

  bool get _isHomelabHttps =>
      _pageUri.scheme == 'https' &&
      HomelabHostPolicy.isPrivateLan(_pageUri.host);

  @override
  void initState() {
    super.initState();
    unawaited(_setupController());
  }

  /// WKWebView must have navigation delegate (incl. SSL handler) attached
  /// before [loadRequest] — otherwise TLS fails silently (blank page).
  Future<void> _setupController() async {
    late final wv.PlatformWebViewControllerCreationParams params;
    if (wv.WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else {
      params = const wv.PlatformWebViewControllerCreationParams();
    }

    final wv.WebViewController controller =
        wv.WebViewController.fromPlatformCreationParams(params);

    await controller.setJavaScriptMode(wv.JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      wv.NavigationDelegate(
        onProgress: (int progress) {
          if (mounted) {
            setState(() {
              _progress = progress / 100.0;
            });
          }
        },
        onPageStarted: (String url) {
          if (kDebugMode) debugPrint('WebView: pageStarted $url');
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
          _notifyHistoryChanged();
        },
        onPageFinished: (String url) async {
          if (kDebugMode) debugPrint('WebView: pageFinished $url');
          if (mounted) {
            setState(() {
              _isLoading = false;
              _progress = 0.0;
            });
          }
          if (widget.displayOptions.trimGoogleCalendarChrome) {
            try {
              await controller.runJavaScript(_calendarChromeScript);
            } catch (_) {}
          }
          await _tryAutofillSavedLogin(controller, url);
          _notifyHistoryChanged();
        },
        onUrlChange: (change) {
          if (kDebugMode && change.url != null) {
            debugPrint('WebView: urlChange ${change.url}');
          }
          _notifyHistoryChanged();
        },
        onWebResourceError: (wv.WebResourceError error) {
          if (kDebugMode) {
            debugPrint(
              'WebView: resourceError code=${error.errorCode} '
              'mainFrame=${error.isForMainFrame} ${error.description}',
            );
          }
          if (error.isForMainFrame != true) return;
          if (mounted) {
            setState(() {
              _errorMessage = 'Failed to load: ${error.description}';
              _isLoading = false;
            });
          }
        },
        onSslAuthError: _handleSslAuthError,
        onHttpAuthRequest: _handleHttpAuthRequest,
      ),
    );

    if (defaultTargetPlatform != TargetPlatform.macOS) {
      await controller.setBackgroundColor(EntryLandscapePalette.midnightNavy);
    }

    _controller = controller;
    _wireHandle(controller);

    if (!mounted) return;
    setState(() {});

    await _configureAndroidCookies();
    _notifyHistoryChanged();
    await _beginInitialLoad();
  }

  void _wireHandle(wv.WebViewController controller) {
    widget.handle?.reload = () => _startLoad();
    widget.handle?.signOut = _signOutWebSession;
    widget.handle?.currentUrl = () => controller.currentUrl();
    widget.handle?.canGoBack = () => controller.canGoBack();
    widget.handle?.canGoForward = () => controller.canGoForward();
    widget.handle?.goBack = () async {
      if (await controller.canGoBack()) {
        await controller.goBack();
        _notifyHistoryChanged();
      }
    };
    widget.handle?.goForward = () async {
      if (await controller.canGoForward()) {
        await controller.goForward();
        _notifyHistoryChanged();
      }
    };
    widget.handle?.trustHomelabCertificate = _trustHomelabAndReload;
  }

  /// Homelab HTTPS: load immediately; SSL challenge handled in [onSslAuthError].
  Future<void> _beginInitialLoad() async {
    if (widget.url.trim().isEmpty) {
      _setConnectionError('No URL to load');
      return;
    }
    if (!mounted) return;
    await _startLoad();
  }

  Future<void> _startLoad() async {
    final controller = _controller;
    if (controller == null) return;
    _loadGeneration++;
    final generation = _loadGeneration;
    if (kDebugMode) {
      debugPrint('WebView: loadRequest $_pageUri');
    }
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    await controller.loadRequest(_pageUri);
    if (_isHomelabHttps) {
      unawaited(_watchHomelabBlankPage(generation));
    }
  }

  /// WKWebView can fail TLS without calling [onSslAuthError] — detect blank/stuck.
  Future<void> _watchHomelabBlankPage(int generation) async {
    await Future<void>.delayed(const Duration(seconds: 3));
    if (!mounted || generation != _loadGeneration || _errorMessage != null) {
      return;
    }
    final controller = _controller;
    if (controller == null) return;
    final current = await controller.currentUrl();
    final blank = current == null ||
        current.isEmpty ||
        current == 'about:blank' ||
        current.startsWith('about:');
    final stuck = _isLoading && _progress == 0;
    if (!blank && !stuck) return;

    if (kDebugMode) {
      debugPrint(
        'WebView: homelab blank watchdog current=$current loading=$_isLoading',
      );
    }

    // Auto-trust homelab TLS and retry (same as Chrome "Proceed unsafe").
    await _markHomelabSslTrusted(_pageUri.host);
    await _startLoad();
  }

  Future<void> _markHomelabSslTrusted(String host) async {
    await _credentialStore.setHomelabSslTrusted(host, true);
  }

  void _notifyHistoryChanged() {
    widget.handle?.onHistoryChanged?.call();
  }

  Future<void> _configureAndroidCookies() async {
    final controller = _controller;
    if (controller == null || controller.platform is! AndroidWebViewController) {
      return;
    }
    try {
      final androidController = controller.platform as AndroidWebViewController;
      final platformManager = wv.WebViewCookieManager().platform;
      if (platformManager is AndroidWebViewCookieManager) {
        await platformManager.setAcceptThirdPartyCookies(androidController, true);
      }
    } catch (_) {}
  }

  Future<void> _tryAutofillSavedLogin(
    wv.WebViewController controller,
    String url,
  ) async {
    try {
      final host = Uri.tryParse(url)?.host ?? _pageUri.host;
      if (host.isEmpty) return;
      final creds = await _credentialStore.readHostCredentials(host);
      var type = creds.loginType;
      if (type == DevQuickTabLoginType.htmlForm) {
        final inferred = DevQuickTabLoginType.inferForUrl(url);
        if (inferred.usesTokenField) type = inferred;
      }
      if (creds.passkey.isNotEmpty) {
        type = type == DevQuickTabLoginType.apiKey
            ? DevQuickTabLoginType.apiKey
            : DevQuickTabLoginType.bearerToken;
      }
      if (!type.usesJsAutofill) return;
      if (!_hasAutofillData(type, creds)) return;

      // STORY: JS-rendered UIs (Proxmox ExtJS, SPAs) build the login form
      // after onPageFinished — one shot misses it on slow devices. So we
      // retry; scripts skip fields that are already filled or user-typed.
      await _runAutofillScript(controller, type, creds);
      for (final ms in [600, 1500, 3000, 5000]) {
        await Future<void>.delayed(Duration(milliseconds: ms));
        if (!mounted) return;
        await _runAutofillScript(controller, type, creds);
      }
    } catch (_) {}
  }

  bool _hasAutofillData(
    DevQuickTabLoginType type,
    WebViewHostCredentials creds,
  ) {
    switch (type) {
      case DevQuickTabLoginType.apiKey:
      case DevQuickTabLoginType.bearerToken:
        return creds.passkey.isNotEmpty;
      case DevQuickTabLoginType.htmlForm:
      case DevQuickTabLoginType.emailPassword:
        return creds.username.isNotEmpty && creds.password.isNotEmpty;
      default:
        return false;
    }
  }

  Future<void> _runAutofillScript(
    wv.WebViewController controller,
    DevQuickTabLoginType type,
    WebViewHostCredentials creds,
  ) async {
    await controller.runJavaScript(
      WebViewLoginAutofill.buildScript(
        type: type,
        username: creds.username,
        password: creds.password,
        passkey: creds.passkey,
      ),
    );
  }

  String _sslErrorHost(wv.SslAuthError error) {
    if (error.platform is WebKitSslAuthError) {
      return (error.platform as WebKitSslAuthError).host;
    }
    return _pageUri.host;
  }

  void _setConnectionError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _handleSslAuthError(wv.SslAuthError error) async {
    final host = _sslErrorHost(error);
    if (kDebugMode) {
      debugPrint('WebView: onSslAuthError host=$host');
    }
    if (!HomelabHostPolicy.isPrivateLan(host)) {
      await error.cancel();
      _setConnectionError(
        'Failed to load: certificate not trusted for $host',
      );
      return;
    }

    await _markHomelabSslTrusted(host);
    if (kDebugMode) debugPrint('WebView: SSL auto-proceed homelab $host');
    await error.proceed();
    if (mounted) setState(() => _errorMessage = null);
  }

  bool _isSslProtocolError(String message) {
    final lower = message.toLowerCase();
    return lower.contains('err_ssl_protocol') ||
        lower.contains('ssl_protocol') ||
        lower.contains('invalid response');
  }

  Future<void> _retryAsHttp() async {
    if (_pageUri.scheme != 'https') return;
    final httpUri = _pageUri.replace(scheme: 'http');
    if (!mounted) return;
    setState(() => _errorMessage = null);
    final controller = _controller;
    if (controller == null) return;
    await controller.loadRequest(httpUri);
  }

  Future<void> _trustHomelabAndReload() async {
    final host = _pageUri.host;
    if (!HomelabHostPolicy.isPrivateLan(host)) return;
    await _markHomelabSslTrusted(host);
    if (!mounted) return;
    setState(() => _errorMessage = null);
    await _startLoad();
  }

  Future<void> _handleHttpAuthRequest(wv.HttpAuthRequest request) async {
    final saved = await _credentialStore.readHttpAuth(request.host);
    if (saved != null) {
      request.onProceed(
        wv.WebViewCredential(user: saved.user, password: saved.password),
      );
      return;
    }

    if (!mounted) {
      request.onCancel();
      return;
    }

    final result = await showDialog<({String user, String pass, bool remember})>(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => _HttpAuthDialog(host: request.host, realm: request.realm),
    );

    if (!mounted) {
      request.onCancel();
      return;
    }

    if (result == null) {
      request.onCancel();
      return;
    }

    if (result.remember) {
      await _credentialStore.saveHttpAuth(
        host: request.host,
        user: result.user,
        password: result.pass,
      );
    }

    request.onProceed(
      wv.WebViewCredential(user: result.user, password: result.pass),
    );
  }

  Future<void> _signOutWebSession() async {
    final controller = _controller;
    if (controller == null) return;
    final host = _pageUri.host;
    await _credentialStore.clearHost(host);
    try {
      await wv.WebViewCookieManager().clearCookies();
    } catch (_) {}
    await controller.loadRequest(_pageUri);
  }

  @override
  void dispose() {
    widget.handle?.reload = null;
    widget.handle?.signOut = null;
    widget.handle?.currentUrl = null;
    widget.handle?.canGoBack = null;
    widget.handle?.canGoForward = null;
    widget.handle?.goBack = null;
    widget.handle?.goForward = null;
    widget.handle?.trustHomelabCertificate = null;
    widget.handle?.onHistoryChanged = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final padding = widget.displayOptions.contentPadding ?? EdgeInsets.zero;
    final controller = _controller;

    if (controller == null) {
      return ColoredBox(
        color: colorScheme.surface,
        child: Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );
    }

    return ColoredBox(
      color: colorScheme.surface,
      child: Stack(
        children: [
          Padding(
            padding: padding,
            child: wv.WebViewWidget(controller: controller),
          ),
          if (_progress > 0 && _progress < 1.0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _progress,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                minHeight: 3,
              ),
            ),
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: colorScheme.error,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          l10n.webview_connection_error,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage!,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_errorMessage != null &&
                            _pageUri.scheme == 'https' &&
                            _isSslProtocolError(_errorMessage!)) ...[
                          const SizedBox(height: 12),
                          Text(
                            HomelabHostPolicy.isTailscaleWireIp(_pageUri.host)
                                ? l10n.webview_ssl_protocol_tailscale_hint
                                : l10n.webview_ssl_protocol_hint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                          if (!HomelabHostPolicy.isTailscaleWireIp(
                            _pageUri.host,
                          )) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _retryAsHttp,
                              icon: const Icon(Icons.http_rounded),
                              label: Text(l10n.webview_try_http),
                            ),
                          ],
                        ],
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: _startLoad,
                          icon: const Icon(Icons.refresh),
                          label: Text(l10n.webview_retry),
                        ),
                        if (_errorMessage != null && _isHomelabHttps) ...[
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _trustHomelabAndReload,
                            icon: const Icon(Icons.lock_open_rounded),
                            label: Text(l10n.webview_ssl_trust_continue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          if (_isLoading && _errorMessage == null && _progress == 0)
            Center(
              child: CircularProgressIndicator(color: colorScheme.primary),
            ),
          if (widget.showControls &&
              widget.displayOptions.showFloatingRefresh &&
              _errorMessage == null)
            Positioned(
              bottom: 16,
              right: 16,
              child: FloatingActionButton.small(
                heroTag: 'webview_refresh_${widget.url.hashCode}',
                onPressed: _startLoad,
                child: const Icon(Icons.refresh_rounded),
              ),
            ),
        ],
      ),
    );
  }
}

class _HttpAuthDialog extends StatefulWidget {
  const _HttpAuthDialog({required this.host, this.realm});

  final String host;
  final String? realm;

  @override
  State<_HttpAuthDialog> createState() => _HttpAuthDialogState();
}

class _HttpAuthDialogState extends State<_HttpAuthDialog> {
  final _userController = TextEditingController();
  final _passController = TextEditingController();
  bool _remember = true;

  @override
  void dispose() {
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Sign in — ${widget.host}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.realm != null && widget.realm!.isNotEmpty)
              Text(
                widget.realm!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _userController,
              decoration: const InputDecoration(labelText: 'Username'),
              textInputAction: TextInputAction.next,
              autofocus: true,
            ),
            TextField(
              controller: _passController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
              onSubmitted: (_) => _submit(),
            ),
            CheckboxListTile(
              value: _remember,
              onChanged: (v) => setState(() => _remember = v ?? true),
              contentPadding: EdgeInsets.zero,
              title: const Text('Remember on this device'),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  void _submit() {
    Navigator.of(context).pop((
      user: _userController.text,
      pass: _passController.text,
      remember: _remember,
    ));
  }
}
