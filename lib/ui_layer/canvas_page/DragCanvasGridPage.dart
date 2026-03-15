import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';
import 'package:ice_gate/ui_layer/widget_page/AddPluginForm.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'StoreWidget.dart'; // The Bottom Bar
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';

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
      // Note: Some MainButton implementations use 'icon' as a fallback.
      // If it looks weird, try setting icon to Icons.circle (invisible) or null.
      // icon: Icons.grid_view,
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
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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

class DragCanvas extends StatefulWidget {
  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  State<DragCanvas> createState() => _DragCanvasState();
}

class _DragCanvasState extends State<DragCanvas> {
  bool isClick = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WidgetManagerBlock>().loadFromDatabase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 70), // Match 70px Header Area

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: widget.baseColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(35),
              child: Stack(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(color: Colors.transparent),
                  ),
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DotGridPainter(
                        color: widget.isDark ? Colors.white : Colors.black,
                        opacity: 0.1,
                        spacing: 25,
                      ),
                    ),
                  ),
                  Watch((context) {
                    final l10n = AppLocalizations.of(context)!;
                    return ListView(
                      padding: const EdgeInsets.all(24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildEntryCard(
                          context: context,
                          title: l10n.canvas_notification_center,
                          subtitle: l10n.canvas_notification_desc,
                          icon: Icons.notifications_active_rounded,
                          color: Colors.blueAccent,
                          onTap: () => context.push('/notifications'),
                        ),
                        const SizedBox(height: 20),
                        _buildEntryCard(
                          context: context,
                          title: l10n.canvas_goal_center,
                          subtitle: l10n.canvas_goal_desc,
                          icon: Icons.track_changes_rounded,
                          color: Colors.orangeAccent,
                          onTap: () => context.push('/canvas/goals'),
                        ),
                        const SizedBox(height: 20),
                        _buildEntryCard(
                          context: context,
                          title: l10n.plugin_ssh_gemini,
                          subtitle: l10n.plugin_ssh_desc,
                          icon: Icons.track_changes_rounded,
                          color: Colors.green,
                          onTap: () => context.push('/widget/ssh_manager'),
                        ),

                        const SizedBox(height: 32),
                        _buildSettingsTitle(context, "FINANCE SETTINGS"),
                        const SizedBox(height: 12),
                        Watch((context) {
                          final configBlock = context.read<ConfigBlock>();
                          final currency = configBlock.currency.watch(context);
                          return _buildSettingTile(
                            context: context,
                            title: "Currency Unit",
                            subtitle: "Current: $currency",
                            icon: Icons.monetization_on_rounded,
                            color: Colors.green,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currency,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Switch.adaptive(
                                  value: currency == 'VND',
                                  onChanged: (_) =>
                                      configBlock.toggleCurrency(),
                                  activeColor: Colors.greenAccent,
                                ),
                              ],
                            ),
                            onTap: () => configBlock.toggleCurrency(),
                          );
                        }),

                        const SizedBox(height: 32),
                        _buildSettingsTitle(context, "MODALITY PREFERENCES"),
                        const SizedBox(height: 12),
                        _buildModalityGroup(context),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Watch((context) {
          final activeTab = DragCanvasGrid.activeCanvasTab.value;
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: animation.drive(
                  Tween(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).chain(CurveTween(curve: Curves.easeOutCubic)),
                ),
                child: child,
              );
            },
            child: activeTab == 'store'
                ? const StoreWidget()
                : const SizedBox.shrink(),
          );
        }),
      ],
    );
  }

  Widget _buildEntryCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(0.3), width: 1),
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: color.withOpacity(0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withOpacity(0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.blueGrey.shade300,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.2),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModalityGroup(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1),
      ),
      child: Column(
        children: [
          _buildModalityItem(
            context: context,
            title: "Health Modality",
            subtitle: "Custom goals and tracking",
            icon: Icons.favorite_rounded,
            color: Colors.redAccent,
            onTap: () {},
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 70),
          _buildModalityItem(
            context: context,
            title: "Social Modality",
            subtitle: "Privacy and connections",
            icon: Icons.people_rounded,
            color: Colors.blueAccent,
            onTap: () {},
          ),
          Divider(color: Colors.white.withOpacity(0.05), height: 1, indent: 70),
          _buildModalityItem(
            context: context,
            title: "Projects Modality",
            subtitle: "Default folders and AI flow",
            icon: Icons.code_rounded,
            color: Colors.deepOrange,
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildModalityItem({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.white.withOpacity(0.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  final double opacity;

  DotGridPainter({required this.color, this.spacing = 20, this.opacity = 0.1});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(opacity)
      ..strokeWidth = 2;

    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DotGridPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.opacity != opacity;
  }
}
