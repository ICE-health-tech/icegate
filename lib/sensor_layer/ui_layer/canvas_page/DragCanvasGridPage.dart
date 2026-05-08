import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/AddPluginForm.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'DragCanvas.dart';

// --- MAIN SCREEN WRAPPER ---

void buildAddCell(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: AddPluginForm(
        data: FormData(
          title: AppLocalizations.of(context)!.canvas_add_custom_widget,
          description: AppLocalizations.of(context)!.canvas_add_widget_desc,
        ),
      ),
    ),
  );
}

class DragCanvasGrid extends StatefulWidget {
  const DragCanvasGrid({super.key});

  // Global signal for tab state
  static final activeCanvasTab = signal<String>('none');

  static void toggleStore() {
    print("Toggle store");
    if (activeCanvasTab.value == 'store') {
      activeCanvasTab.value = 'none';
    } else {
      activeCanvasTab.value = 'store';
    }
  }

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "grid",
      destination: "/canvas",
      size: size,
      iconWidget: Center(
        child: Transform.rotate(
          angle: 45 * math.pi / 180,
          child: Icon(
            Icons.grid_view,
            color: Colors.white,
            size: size! * 0.6, // Ensure the icon respects the passed size
          ),
        ),
      ),
      mainFunction: () {
        toggleStore();
        HapticFeedback.heavyImpact();
      },
      onLongPress: () {
        context.go("/");
        HapticFeedback.heavyImpact();
      },
    );
  }

  @override
  State<DragCanvasGrid> createState() => _DragCanvasGridState();
}

class _DragCanvasGridState extends State<DragCanvasGrid> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surface;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: baseColor,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        bottom: false,
        child: DragCanvas(baseColor: baseColor, isDark: isDark),
      ),
    );
  }
}
