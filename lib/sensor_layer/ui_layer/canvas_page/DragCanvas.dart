import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:go_router/go_router.dart';

import 'DotGridPainter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/home_page/DailyLoopCard.dart';
import 'package:ice_gate/sensor_layer/ui_layer/reusable_widget/HubEntryCard.dart';

class DragCanvas extends StatelessWidget {
  static const double _maxHubWidth = 560;
  static const double _headerClearance = 64;

  final Color baseColor;
  final bool isDark;

  const DragCanvas({super.key, required this.baseColor, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      children: [
        const SizedBox(height: _headerClearance),
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            decoration: BoxDecoration(
              color: baseColor.withValues(alpha: isDark ? 0.12 : 0.35),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
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
                        opacity: isDark ? 0.09 : 0.06,
                        spacing: 25,
                      ),
                    ),
                  ),
                  Watch((context) {
                    final l10n = AppLocalizations.of(context)!;
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxHubWidth,
                        ),
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 108),
                          physics: const BouncingScrollPhysics(),
                          children: [
                           
                            const SizedBox(height: 16),
                            HubEntryCard(
                              title: l10n.canvas_notification_center,
                              subtitle: l10n.canvas_notification_desc,
                              icon: Icons.notifications_active_rounded,
                              accent: HealthMetricColors.pillarBlue,
                              onTap: () => context.push('/notifications'),
                            ),
                            const SizedBox(height: 14),
                            HubEntryCard(
                              title: l10n.canvas_goal_center,
                              subtitle: l10n.canvas_goal_desc,
                              icon: Icons.flag_rounded,
                              accent: HealthMetricColors.pillarYellow,
                              onTap: () => context.push('/canvas/goals'),
                            ),
                            const SizedBox(height: 14),
                            HubEntryCard(
                              title: l10n.integration_hub_title,
                              subtitle: l10n.integration_hub_subtitle,
                              icon: Icons.hub_rounded,
                              accent: HealthMetricColors.pillarViolet,
                              onTap: () => context.push('/integrations'),
                            ),
                            const SizedBox(height: 14),
                            HubEntryCard(
                              title: l10n.plugin_ssh,
                              subtitle: l10n.plugin_ssh_desc,
                              icon: Icons.terminal_rounded,
                              accent: HealthMetricColors.pillarGreen,
                              onTap: () => context.push('/widget/ssh_manager'),
                            ),
                            const SizedBox(height: 14),
                            HubEntryCard(
                              title: l10n.reports_hub_title,
                              subtitle: l10n.reports_hub_subtitle,
                              icon: Icons.mark_email_unread_rounded,
                              accent: EntryColors.financeSilverAccent,
                              onTap: () =>
                                  context.push('/finance/reports/daily'),
                            ),
                          ],
                        ),
                      ),
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

}
