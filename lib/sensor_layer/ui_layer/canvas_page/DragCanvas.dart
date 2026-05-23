import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

import 'DotGridPainter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';

class DragCanvas extends StatelessWidget {
  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 70), // Header space

        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: 0.15),
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
                        color: isDark ? Colors.white : Colors.black,
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
                        _buildEntryCard(
                          context: context,
                          title: l10n.reports_hub_title,
                          subtitle: l10n.reports_hub_subtitle,
                          icon: Icons.mark_email_unread_rounded,
                          color: EntryColors.financeSilverAccent,
                          onTap: () => context.push('/finance/reports/daily'),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
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

}
