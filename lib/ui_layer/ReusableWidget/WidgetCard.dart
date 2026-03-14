import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/widget_page/ConfirmDialog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widget_page/PluginList/IOTTracker/OSMMapPlugin.dart';
import '../../orchestration_layer/Action/WebView/LiveMapPlugin.dart';

import 'package:go_router/go_router.dart';

// ------------------------------------------
// MOCK CLASSES & METHODS (Required for runnability)
// ------------------------------------------

// ... (existing code)

// Mock function for navigation
void _navigateExternalUrl(BuildContext context, String url) async {
  // Check for special widget protocol
  if (url.startsWith('widget://')) {
    if (url == 'widget://map') {
      OSMMapPlugin.navigateToMap(context);
      return;
    }
    if (url.startsWith('widget://webview')) {
      debugPrint("WebView widget detected: $url - Drag this to canvas to use");
      LiveMapPlugin.navigateToWebView(context, url);
      return;
    }
    debugPrint("Widget protocol detected: $url - Drag this to canvas to use");
    return;
  }

  // Handle SSH protocol
  if (url.startsWith('ssh://')) {
    context.push('/ssh');
    return;
  }

  // Future<void> _launchUrl() async {
  // 1. Check if the URL can be launched on the device
  if (!await launchUrl(Uri.parse(url))) {
    // 2. Throw an exception or display an error if launching fails
    throw Exception('Could not launch $url');
    // }
  }
  debugPrint("Navigating to URL: $url");
}

// Mock function for showing the delete dialog
void _showDeleteConfirmDialog(
  BuildContext context,
  ExternalWidgetsDAO dao,
  ExternalWidgetData widgetData,
) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ConfirmDialog(
        dao: dao,
        name: "Confirm",
        widgetID: widgetData.widgetID ?? '',
      ); // Return your dialog widget here
    },
  );
  debugPrint("Showing delete confirmation for: ${widgetData.name}");
  // In a real app, this would show a dialog using showDialog
}

// Helper to build a fallback icon
Widget _buildFallbackIcon(BuildContext context, String name) {
  return Icon(
    Icons.widgets,
    size: 48,
    color: Theme.of(context).colorScheme.primary,
  );
}

// Mock replacement for NeumorphicButton (since we don't have the dependency)
class MockStyledButton extends StatelessWidget {
  final VoidCallback onPressed;
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Widget child;

  const MockStyledButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.margin = const EdgeInsets.all(0),
    this.padding = const EdgeInsets.all(0),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

// ------------------------------------------
// FIXED WIDGET COMPONENT
// ------------------------------------------

class WidgetCard extends StatelessWidget {
  // Required data is passed into the constructor
  final ExternalWidgetsDAO dao;
  final ExternalWidgetData widgetData;
  final String fullUrl;

  const WidgetCard({
    super.key,
    required BuildContext context,
    required this.dao,
    required this.widgetData,
    required this.fullUrl,
  });

  @override
  Widget build(context) {
    final bool hasImage =
        widgetData.imageUrl != null && widgetData.imageUrl!.isNotEmpty;

    // The entire card content, now a StatelessWidget build method
    return Stack(
      children: [
        // This is the main button/card body
        MockStyledButton(
          onPressed: () => _navigateExternalUrl(context, fullUrl),
          margin: const EdgeInsets.all(8), // Added margin for spacing
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image or Fallback Icon
              Expanded(
                child: hasImage
                    ? Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8.0),
                          child: Image.network(
                            widgetData.imageUrl!,
                            fit:
                                BoxFit.contain, // Changed to contain for safety
                            loadingBuilder: (context, child, progress) {
                              return progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    );
                            },
                            errorBuilder: (context, error, stack) {
                              return _buildFallbackIcon(
                                context,
                                widgetData.name ?? 'Widget',
                              );
                            },
                          ),
                        ),
                      )
                    : _buildFallbackIcon(context, widgetData.name ?? 'Widget'),
              ),
              const SizedBox(height: 8),
              // Name Text
              Text(
                widgetData.name ?? 'Untitled',
                style: Theme.of(context).textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        // --- DELETE BUTTON: Positioned in the top right corner ---
        Positioned(
          top: 0,
          right: 0,
          child: IconButton(
            // Using a standard IconButton for simplicity
            onPressed: () {
              // Call the confirmation dialog
              _showDeleteConfirmDialog(context, dao, widgetData);
            },
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade400,
              shape: const CircleBorder(),
              minimumSize: const Size(32, 32),
              padding: EdgeInsets.zero,
            ),
            icon: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }
}
