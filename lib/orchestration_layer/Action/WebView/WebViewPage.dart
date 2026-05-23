import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'WebViewWidget.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({
    super.key,
    required this.url,
    this.title = 'External Widget',
  });

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  final EmbeddedWebViewHandle _webHandle = EmbeddedWebViewHandle();
  late final WebViewDisplayOptions _displayOptions;
  bool _canGoBack = false;
  bool _canGoForward = false;

  @override
  void initState() {
    super.initState();
    _displayOptions = WebViewDisplayOptions.forUrl(widget.url);
    _webHandle.onHistoryChanged = _refreshNavigationState;
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
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        actions: [
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
                  await Clipboard.setData(ClipboardData(text: widget.url));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied')),
                    );
                  }
                  break;
                case 'browser':
                  await _openInBrowser();
                  break;
              }
            },
            itemBuilder: (context) => [
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
          url: widget.url,
          handle: _webHandle,
          showControls: true,
          displayOptions: _displayOptions.copyWith(showFloatingRefresh: false),
        ),
      ),
    );
  }
}
