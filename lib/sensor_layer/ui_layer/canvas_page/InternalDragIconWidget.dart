// / --- DRAG TARGET (GRID CELL) ---
import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';

import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';
// import 'package:ice_gate/data_layer/Protocol/Widget/InternalWidgetDragProtocol.dart';
// import 'package:ice_gate/data_layer/Protocol/Widget/WidgetManagerBlock.dart';
// import '../BigWidget/Canvas/StoreWidget.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'StoreWidget.dart';
// import 'package:ice_gate/data_layer/Protocol/Widget/InternalWidgetDragProtocol.dart';
// import 'package:ice_gate/data_layer/Protocol/Widget/WidgetManagerBlock.dart';

import '../UIConstants.dart';
import 'package:ice_gate/utils/app_log.dart';

class InternalDragIconWidget extends StatefulWidget {
  final int index;
  final WidgetManagerBlock store;

  const InternalDragIconWidget({
    super.key,
    required this.index,
    required this.store,
    required this.widthCard,
    required this.heightCard,
    required this.name,
  });

  final double widthCard;
  final double heightCard;
  final String name;

  @override
  State<InternalDragIconWidget> createState() => _InternalDragIconWidgetState();
}

class _InternalDragIconWidgetState extends State<InternalDragIconWidget> {
  bool isHovering = false;

  @override
  Widget build(BuildContext context) {
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
            widget.store.handleInteraction(incomingData, widget.index);
            appLog("Widget from inside");
          } else if (incomingData is InternalWidgetDragProtocol) {
            appLog("Widget from outside");
            widget.store.addWidget(widget.index, incomingData);
          }
        },
        builder: (context, candidateData, rejectedData) {
          final Color borderColor = isHovering
              ? Colors.cyanAccent
              : Colors.white.withValues(alpha: 25 / 255);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: isEmpty ? Colors.white.withValues(alpha: 10 / 255) : Colors.transparent,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: borderColor,
                width: UIConstants.getBorderWidth(
                  context,
                  widget.widthCard,
                  widget.heightCard,
                ),
              ),
              boxShadow: isHovering
                  ? [
                      BoxShadow(
                        color: Colors.cyanAccent.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ]
                  : [],
            ),
            child: isEmpty
                ? Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: isHovering ? Colors.cyanAccent : Colors.white24,
                      size: 28,
                    ),
                  )
                : LongPressDraggable<int>(
                    delay: const Duration(milliseconds: 300),
                    hapticFeedbackOnStart: true,
                    data: widget.index,
                    feedback: Material(
                      color: Colors.transparent,
                      child: Transform.scale(
                        scale: 1.15,
                        child: BuildCard(
                          item: cellData,
                          isDragging: true,
                          cardWidth: widget.widthCard,
                          cardHeight: widget.heightCard,
                          name: cellData.name,
                        ),
                      ),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: BuildCard(
                        item: cellData,
                        cardWidth: widget.widthCard,
                        cardHeight: widget.heightCard,
                        name: cellData.name,
                      ),
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        BuildCard(
                          item: cellData,
                          cardWidth: widget.widthCard,
                          cardHeight: widget.heightCard,
                          name: cellData.name,
                        ),
                        Positioned(
                          top: -8,
                          left: -8,
                          child: InkWell(
                            onTap: () =>
                                _showRenameDialog(context, cellData.name),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.edit_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: InkWell(
                            onTap: () =>
                                widget.store.removeByIndex(widget.index),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.error,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Colors.white,
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

  void _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Widget'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'New Name',
              hintText: 'Enter widget name',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  widget.store.renameWidget(widget.index, controller.text);
                  Navigator.pop(context);
                }
              },
              child: const Text('Rename'),
            ),
          ],
        );
      },
    );
  }
}
