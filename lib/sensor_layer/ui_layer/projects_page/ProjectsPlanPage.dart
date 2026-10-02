import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Canvas/PlanBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/widgets/ProjectsPlanCanvas.dart';
import 'package:provider/provider.dart';

/// Full-screen flowchart canvas — global quick board or per-project when [projectId] is set.
class ProjectsPlanPage extends StatefulWidget {
  const ProjectsPlanPage({super.key, this.projectId});

  final String? projectId;

  @override
  State<ProjectsPlanPage> createState() => _ProjectsPlanPageState();
}

class _ProjectsPlanPageState extends State<ProjectsPlanPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _activatePlan());
  }

  @override
  void didUpdateWidget(ProjectsPlanPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _activatePlan();
    }
  }

  Future<void> _activatePlan() async {
    if (!mounted) return;
    final planBlock = context.read<PlanBlock>();
    await planBlock.activateForProject(widget.projectId);
    if (!mounted) return;
    final projectId = widget.projectId?.trim();
    if (projectId != null && projectId.isNotEmpty) {
      final projects = context.read<ProjectBlock>().projects.value;
      for (final p in projects) {
        if (p.id == projectId || p.projectID == projectId) {
          if (planBlock.rootLabel.value == 'My schedule') {
            planBlock.setRootLabel(p.name);
          }
          break;
        }
      }
    }
  }

  String _title(AppLocalizations l10n) {
    final projectId = widget.projectId?.trim();
    if (projectId == null || projectId.isEmpty) {
      return l10n.projects_tile_canvas;
    }
    final projects = context.read<ProjectBlock>().projects.value;
    for (final p in projects) {
      if (p.id == projectId || p.projectID == projectId) return p.name;
    }
    return l10n.projects_tile_canvas;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final canvasBg = isDark
        ? cs.surfaceContainerLow.withValues(alpha: 0.92)
        : const Color(0xFFF3F4F6);

    return Scaffold(
      backgroundColor: canvasBg,
      appBar: AppBar(
        backgroundColor: canvasBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(_title(l10n)),
        actions: [
          IconButton(
            tooltip: l10n.projects_diagrams_title,
            icon: const Icon(Icons.folder_special_outlined),
            onPressed: () => context.push('/projects/diagrams'),
          ),
        ],
      ),
      body: const ProjectsPlanCanvas(),
    );
  }
}
