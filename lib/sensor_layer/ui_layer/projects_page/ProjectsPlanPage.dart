import 'package:flutter/material.dart';
import 'package:ice_gate/utils/L10nExtensions.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/ProjectsPlanCanvas.dart';

/// Full-screen schedule planner (opened from Projects quick action).
class ProjectsPlanPage extends StatelessWidget {
  const ProjectsPlanPage({super.key});

  static const double _headerClearance = 64;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: _headerClearance),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                context.l10n.projects_plan_section_title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: const ProjectsPlanCanvas(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
