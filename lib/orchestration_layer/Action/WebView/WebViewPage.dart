import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/Services/HomelabHostPolicy.dart';
import 'package:url_launcher/url_launcher.dart';
import 'WebViewWidget.dart';

/// LAN vs remote (or other) endpoint selectable in [WebViewPage].
class WebViewUrlOption {
  const WebViewUrlOption({required this.label, required this.url});

  final String label;
  final String url;
}

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;
  final List<WebViewUrlOption> urlOptions;

  const WebViewPage({
    super.key,
    required this.url,
    this.title = 'External Widget',
    this.urlOptions = const [],
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final EmbeddedWebViewHandle _webHandle = EmbeddedWebViewHandle();
  late WebViewDisplayOptions _displayOptions;
  late String _activeUrl;
  bool _canGoBack = false;
  bool _canGoForward = false;

  bool get _canSwitchUrl => widget.urlOptions.length > 1;

  @override
  void initState() {
    super.initState();
    _activeUrl = widget.url;
    _displayOptions = WebViewDisplayOptions.forUrl(_activeUrl);
    _webHandle.onHistoryChanged = _refreshNavigationState;
  }

  void _switchUrl(String url) {
    if (url == _activeUrl) return;
    setState(() {
      _activeUrl = url;
      _displayOptions = WebViewDisplayOptions.forUrl(url);
      _canGoBack = false;
      _canGoForward = false;
    });
  }

  Future<void> _showUrlPicker() async {
    if (!_canSwitchUrl) return;
    final picked = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in widget.urlOptions)
                ListTile(
                  leading: Icon(
                    _activeUrl == option.url
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    color: _activeUrl == option.url ? cs.primary : cs.outline,
                  ),
                  title: Text(option.label),
                  subtitle: Text(
                    option.url,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () => Navigator.pop(ctx, option.url),
                ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
    if (picked != null && picked != _activeUrl && mounted) {
      HapticFeedback.selectionClick();
      _switchUrl(picked);
    }
  }

  Future<void> _refreshNavigationState() async {
    final back = await _webHandle.canGoBack?.call() ?? false;
    final forward = await _webHandle.canGoForward?.call() ?? false;
    if (!mounted) return;
    setState(() {
      _canGoBack = back;
      _canGoForward = forward;
    });
  }

  Future<void> _openInBrowser() async {
    final live = await _webHandle.currentUrl?.call();
    final raw = (live != null && live.isNotEmpty) ? live : _activeUrl;
    final uri = Uri.tryParse(raw);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _copyLink() async {
    final live = await _webHandle.currentUrl?.call();
    final raw = (live != null && live.isNotEmpty) ? live : _activeUrl;
    await Clipboard.setData(ClipboardData(text: raw));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL copied')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final pageUri = Uri.tryParse(_activeUrl);
    final showTrustCert = pageUri != null &&
        pageUri.scheme == 'https' &&
        HomelabHostPolicy.isPrivateLan(pageUri.host);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            if (_activeUrl.isNotEmpty)
              InkWell(
                onTap: _canSwitchUrl ? _showUrlPicker : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          _activeUrl,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _canSwitchUrl
                                ? colorScheme.primary
                                : colorScheme.onSurfaceVariant,
                            decoration: _canSwitchUrl
                                ? TextDecoration.underline
                                : null,
                            decorationColor: colorScheme.primary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      ),
                      if (_canSwitchUrl) ...[
                        const SizedBox(width: 2),
                        Icon(
                          Icons.unfold_more_rounded,
                          size: 14,
                          color: colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (_canSwitchUrl)
            IconButton(
              tooltip: l10n.webview_choose_url,
              icon: const Icon(Icons.alt_route_rounded),
              onPressed: () {
                HapticFeedback.selectionClick();
                _showUrlPicker();
              },
            ),
          if (showTrustCert)
            IconButton(
              tooltip: l10n.webview_ssl_trust_continue,
              icon: const Icon(Icons.lock_open_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                _webHandle.trustHomelabCertificate?.call();
              },
            ),
          IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _canGoBack
                ? () {
                    HapticFeedback.selectionClick();
                    _webHandle.goBack?.call();
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Forward',
            icon: const Icon(Icons.arrow_forward_rounded),
            onPressed: _canGoForward
                ? () {
                    HapticFeedback.selectionClick();
                    _webHandle.goForward?.call();
                  }
                : null,
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _webHandle.reload?.call();
            },
          ),
          IconButton(
            tooltip: 'Open in browser',
            icon: const Icon(Icons.open_in_new_rounded),
            onPressed: _openInBrowser,
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'signout':
                  await _webHandle.signOut?.call();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Web sign-in cleared for this site'),
                      ),
                    );
                  }
                  break;
                case 'copy':
                  await _copyLink();
                  break;
                case 'browser':
                  await _openInBrowser();
                  break;
                case 'switch_url':
                  await _showUrlPicker();
                  break;
              }
            },
            itemBuilder: (context) => [
              if (_canSwitchUrl)
                PopupMenuItem(
                  value: 'switch_url',
                  child: Text(l10n.webview_choose_url),
                ),
              const PopupMenuItem(
                value: 'signout',
                child: Text('Sign out & clear saved login'),
              ),
              const PopupMenuItem(value: 'copy', child: Text('Copy link')),
              const PopupMenuItem(
                value: 'browser',
                child: Text('Open in Safari'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: EmbeddedWebViewWidget(
          key: ValueKey(_activeUrl),
          url: _activeUrl,
          handle: _webHandle,
          showControls: true,
          displayOptions: _displayOptions.copyWith(showFloatingRefresh: false),
        ),
      ),
    );
  }
}
