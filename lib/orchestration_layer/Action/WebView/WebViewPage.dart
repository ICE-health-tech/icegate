import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'WebViewWidget.dart';

class WebViewPage extends StatefulWidget {
  final String url;
  final String title;

  const WebViewPage({super.key, required this.url, this.title = 'External Widget'});

  @override
  State<WebViewPage> createState() => _WebViewPageState();
}

class _WebViewPageState extends State<WebViewPage> {
  late String _currentTitle;

  @override
  void initState() {
    super.initState();
    _currentTitle = widget.title;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _currentTitle,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.url,
              style: TextStyle(
                fontSize: 10,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.normal,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'copy':
                  await Clipboard.setData(ClipboardData(text: widget.url));
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('URL copied to clipboard')),
                    );
                  }
                  break;
                case 'browser':
                  if (await canLaunchUrl(Uri.parse(widget.url))) {
                    await launchUrl(
                      Uri.parse(widget.url),
                      mode: LaunchMode.externalApplication,
                    );
                  }
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'copy', child: Text('Copy Link')),
              const PopupMenuItem(
                value: 'browser',
                child: Text('Open in Browser'),
              ),
            ],
          ),
        ],
      ),
      body: EmbeddedWebViewWidget(url: widget.url, showControls: true),
    );
  }
}
