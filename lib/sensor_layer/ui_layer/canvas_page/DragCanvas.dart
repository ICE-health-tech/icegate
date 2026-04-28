import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/WidgetManagerBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

import 'DotGridPainter.dart';
import 'InternalDragIconWidget.dart';
import 'StoreWidget.dart';
import 'DragCanvasGridPage.dart'; // For activeCanvasTab

class DragCanvas extends StatefulWidget {
  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  State<DragCanvas> createState() => _DragCanvasState();
}

class _DragCanvasState extends State<DragCanvas> {
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
        const SizedBox(height: 70), // Header space

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: widget.baseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(35),
              border: Border.all(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
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
                          title: l10n.plugin_ssh,
                          subtitle: l10n.plugin_ssh_desc,
                          icon: Icons.track_changes_rounded,
                          color: Colors.green,
                          onTap: () => context.push('/widget/ssh_manager'),
                        ),

                        const SizedBox(height: 32),
                        _buildSectionTitle(context, "INTERACTIVE CANVAS"),
                        const SizedBox(height: 12),
                        
                        // --- 15 CELL GRID ---
                        _buildWidgetGrid(context),

                        const SizedBox(height: 32),
                        _buildSectionTitle(context, "FINANCE SETTINGS"),
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

  Widget _buildWidgetGrid(BuildContext context) {
    final store = context.read<WidgetManagerBlock>();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate card size based on 3 columns
        final double spacing = 12.0;
        final double width = (constraints.maxWidth - (spacing * 2)) / 3;
        final double height = width; // Square cards

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: 1.0,
          ),
          itemCount: 15,
          itemBuilder: (context, index) {
            return InternalDragIconWidget(
              index: index,
              store: store,
              widthCard: width,
              heightCard: height,
              name: "Slot $index", // Name is handled inside InternalDragIconWidget watching the store
            );
          },
        );
      },
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
        border: Border.all(color: color.withValues(alpha: 0.3), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
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
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
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
                          color: color.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
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
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
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
                    color: color.withValues(alpha: 0.1),
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
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                trailing ??
                    Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
