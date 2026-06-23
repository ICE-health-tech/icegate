import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/GrowthBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:ice_gate/sensor_layer/ui_layer/projects_page/CreateProjectDialog.dart';
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// SDLC entry dashboard — pick a project before opening the phase board.
class ProjectsSdlcHubPage extends StatefulWidget {
  const ProjectsSdlcHubPage({super.key});

  @override
  State<ProjectsSdlcHubPage> createState() => _ProjectsSdlcHubPageState();
}

class _ProjectsSdlcHubPageState extends State<ProjectsSdlcHubPage> {
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_sync(showSnackBar: false));
    });
  }

  Future<void> _sync({bool showSnackBar = true}) async {
    if (_syncing) return;
    setState(() => _syncing = true);
    final l10n = AppLocalizations.of(context)!;
    try {
      await Future.wait([
        context.read<ProjectBlock>().syncFromCloud(),
        context.read<GrowthBlock>().sync(),
      ]);
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.project_sync_success),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (showSnackBar && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.project_sync_failed(e.toString())),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.project_sdlc_board_title),
        actions: [
          if (_syncing)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              tooltip: l10n.integrations_sync_now,
              icon: const Icon(Icons.sync_rounded),
              onPressed: () => unawaited(_sync()),
            ),
        ],
      ),
      body: Watch((context) {
        final active = context
            .read<ProjectBlock>()
            .projects
            .value
            .where((p) => p.status == 0)
            .rootsOnly
            .toList();

        if (active.isEmpty) {
          return RefreshIndicator(
            onRefresh: () => _sync(showSnackBar: false),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                Icon(
                  Icons.view_kanban_outlined,
                  size: 48,
                  color: colorScheme.primary.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    l10n.project_sdlc_no_project,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => const CreateProjectDialog(),
                      );
                    },
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l10n.create_project_title),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => _sync(showSnackBar: false),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              Text(
                l10n.project_sdlc_pick_project,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 12),
              ...active.map((project) => _ProjectPickTile(project: project)),
            ],
          ),
        );
      }),
    );
  }
}

class _ProjectPickTile extends StatelessWidget {
  const _ProjectPickTile({required this.project});

  final ProjectProtocol project;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final accent = HealthMetricColors.pillarAccentAt(3);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => context.push('/projects/${project.id}/sdlc'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.view_kanban_outlined,
                    color: accent,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
