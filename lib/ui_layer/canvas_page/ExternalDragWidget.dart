import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:http/http.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart' show ReadContext;
import 'package:signals_flutter/signals_flutter.dart';
// Required for context.read

import '../../data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import '../../initial_layer/FireAPI/UrlNavigate.dart';
import '../../data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';
import '../../orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import '../widget_page/PluginList/IOTTracker/CompactOSMMapWidget.dart';
import '../../orchestration_layer/Action/WebView/WebViewWidget.dart';
// import '../../data_layer/Protocol/Widget/InternalWidgetDragProtocol.dart';
// import '../../data_layer/Protocol/Widget/WidgetManagerBlock.dart';
// Ensure you import your DAO file here, e.g.:
// import '../../../database/ExternalWidgetsDAO.dart';

import '../UIConstants.dart';

class ExternalDragWidget extends StatefulWidget {
  final int index;
  final WidgetManagerBlock store;

  const ExternalDragWidget({super.key, required this.index, required this.store});

  @override
  State<ExternalDragWidget> createState() => _ExternalDragWidgetState();
}

class _ExternalDragWidgetState extends State<ExternalDragWidget> {
  bool isHovering = false;
  late ExternalWidgetsDAO _widgetDAO;

  @override
  Widget build(BuildContext context) {
    // 1. Added the DAO access here as requested
    _widgetDAO = context.read<ExternalWidgetsDAO>();

    // OBSERVER: Rebuilds specific cell if its specific data changes
    return Watch((context) {
      // Get current data from store
      final InternalWidgetDragProtocol cellData =
          widget.store.widgets[widget.index];
      final bool isEmpty = cellData.name == 'Empty';

      // Decide what we accept
      return DragTarget(
        onWillAcceptWithDetails: (details) {
          setState(() => isHovering = true);
          return true;
        },
        onLeave: (_) => setState(() => isHovering = false),
        onAcceptWithDetails: (details) {
          setState(() => isHovering = false);

          final incomingData = details.data;

          if (incomingData is int) {
            // Case A: Dragging from another Grid Cell (Int Index)
            // print("Test");
            widget.store.handleInteraction(incomingData, widget.index);

            // TODO: You can use 'dao' here to update the position in DB
          } else if (incomingData is InternalWidgetDragProtocol) {
            // print("Widget from outside");

            // Add to MobX Store
            widget.store.addWidget(widget.index, incomingData);

            final externalWidgetProtocol = ExternalWidgetProtocol(
              name: incomingData.name,
              protocol: incomingData.protocol,
              host: incomingData.host,
              url: incomingData.url,
            );
            // TODO: You can use 'dao' here to persist the new item
            _widgetDAO.insertNewWidget(
              externalWidgetProtocol: externalWidgetProtocol,
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          final Color borderColor = isHovering
              ? Colors.yellowAccent
              : Colors.white10;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isEmpty
                  ? Colors.white.withOpacity(0.05)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: borderColor,
                width: UIConstants.getBorderWidth(
                  context,
                  1000,
                ), // External widgets are large by default
              ),
            ),
            child: isEmpty
                ? const Center(child: Icon(Icons.add, color: Colors.white24))
                : Draggable<int>(
                    // We pass the INDEX, not the object, to track where it came from
                    data: widget.index,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.05,
                        child: _BuildCard(item: cellData, isDragging: true),
                      ),
                    ),
                    childWhenDragging: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Stack(
                      children: [
                        _BuildCard(item: cellData),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: InkWell(
                            // Action: Remove
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Colors.black26,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: IconButton(
                                onPressed: () {
                                  // Remove from Store
                                  HapticFeedback.heavyImpact();
                                  widget.store.removeByIndex(widget.index);

                                  // TODO: You can use 'dao' here to delete from DB
                                  // dao.deleteWidget(cellData.widgetID);
                                },
                                icon: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
          );
        },
      );
    });
  }
}

// --- CARD RENDERER ---
// --- CARD RENDERER ---
class _BuildCard extends StatelessWidget {
  final InternalWidgetDragProtocol item;
  final bool isDragging;

  const _BuildCard({required this.item, this.isDragging = false});

  DecorationImage? _buildUrlImage(String url) {
    if (url.isEmpty) return null;

    // 1. Check if the URL is already a direct image file
    bool isDirectImage =
        url.toLowerCase().endsWith('.png') ||
        url.toLowerCase().endsWith('.jpg') ||
        url.toLowerCase().endsWith('.jpeg') ||
        url.toLowerCase().endsWith('.gif');

    String imageUrl;

    if (isDirectImage) {
      imageUrl = url;
    } else {
      // 2. If it's a website URL, fetch the Favicon via Google's Service
      // Skip for widget protocols
      if (url.startsWith('widget://')) {
        return null;
      }

      Uri uri = Uri.tryParse(url) ?? Uri();
      String domain = uri.host.isNotEmpty ? uri.host : url;
      imageUrl = 'https://www.google.com/s2/favicons?sz=64&domain=$domain';
    }

    return DecorationImage(
      image: NetworkImage(imageUrl),
      fit: isDirectImage ? BoxFit.cover : BoxFit.scaleDown,
      onError: (exception, stackTrace) {
        debugPrint('Could not load image: $exception');
      },
    );
  }

  // Helper to parse Hex String to Color
  Color _getColor(String hexString) {
    try {
      return Color(int.parse(hexString));
    } catch (e) {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is a map widget
    final isMapWidget = item.url == 'widget://map';

    if (isMapWidget) {
      return _buildMapWidget();
    }

    // Check if this is a webview widget
    if (item.url.startsWith('widget://webview')) {
      return _buildWebViewWidget();
    }

    final color = _getColor(item.color);

    return Card(
      elevation: isDragging ? 12 : 4,
      shadowColor: color.withOpacity(0.6),
      color: Colors.transparent, // Transparent to show gradient
      margin: EdgeInsets.zero, // Remove default margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
          ),
          image: item.url.isNotEmpty ? _buildUrlImage(item.url) : null,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              print("Navigating to: ${item.url}");
              urlNavigate(item.url);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Text Overlay with Glass effect
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item.score > 0)
                          Text(
                            "${item.score}",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMapWidget() {
    return Card(
      elevation: isDragging ? 12 : 4,
      shadowColor: Colors.blue.withOpacity(0.6),
      color: Colors.transparent,
      margin: EdgeInsets.zero, // Remove default margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.withOpacity(0.9),
              Colors.blue.withOpacity(0.7),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: const CompactOSMMapWidget(showControls: true),
        ),
      ),
    );
  }

  Widget _buildWebViewWidget() {
    // Parse the target URL from the query parameter
    final uri = Uri.parse(item.url);
    final targetUrl = uri.queryParameters['target'] ?? 'https://google.com';

    return Card(
      elevation: isDragging ? 12 : 4,
      shadowColor: Colors.black.withOpacity(0.3),
      color: Colors.white,
      margin: EdgeInsets.zero, // Remove default margin
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: EmbeddedWebViewWidget(url: targetUrl, showControls: true),
      ),
    );
  }
}
