import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/PlanProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Project/ProjectBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/PlanBlockPrefs.dart';
import 'package:provider/provider.dart';

/// Lists projects that have a saved flowchart / plan diagram.
class ProjectDiagramsGalleryPage extends StatefulWidget {
  const ProjectDiagramsGalleryPage({super.key});

  @override
  State<ProjectDiagramsGalleryPage> createState() =>
      _ProjectDiagramsGalleryPageState();
}

class _ProjectDiagramsGalleryPageState extends State<ProjectDiagramsGalleryPage> {
  Future<List<_DiagramEntry>>? _loadFuture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final personId = context.read<PersonBlock>().currentPersonID.value ?? '';
    final projects = context.read<ProjectBlock>().projects.value;
    setState(() {
      _loadFuture = _loadEntries(personId, projects);
    });
  }

  static Future<List<_DiagramEntry>> _loadEntries(
    String personId,
    List<ProjectProtocol> projects,
  ) async {
    if (personId.isEmpty) return const [];
    final ids = await PlanBlockPrefs.listProjectIdsWithDiagrams(personId);
    final entries = <_DiagramEntry>[];
    for (final id in ids) {
      final board = await PlanBlockPrefs.load(personId, projectId: id);
      if (board == null) continue;
      ProjectProtocol? project;
      for (final p in projects) {
        if (p.id == id || p.projectID == id) {
          project = p;
          break;
        }
      }
      entries.add(
        _DiagramEntry(
          projectId: id,
          projectName: project?.name ?? board.rootLabel,
          board: board,
        ),
      );
    }
    entries.sort((a, b) => a.projectName.compareTo(b.projectName));
    return entries;
  }

  Future<void> _pickProjectAndDraw() async {
    final projects = context.read<ProjectBlock>().projects.value.rootsOnly;
    if (!mounted) return;
    if (projects.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.projects_diagrams_no_projects)),
      );
      return;
    }

    final picked = await showModalBottomSheet<ProjectProtocol>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Text(
                AppLocalizations.of(ctx)!.projects_diagrams_pick_project,
                style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ...projects.map(
              (p) => ListTile(
                leading: const Icon(Icons.account_tree_outlined),
                title: Text(p.name),
                onTap: () => Navigator.pop(ctx, p),
              ),
            ),
          ],
        ),
      ),
    );

    if (picked == null || !mounted) return;
    await context.push('/projects/plan?projectId=${picked.id}');
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(l10n.projects_diagrams_title),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickProjectAndDraw,
        icon: const Icon(Icons.draw_outlined),
        label: Text(l10n.projects_diagrams_new),
      ),
      body: FutureBuilder<List<_DiagramEntry>>(
        future: _loadFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final entries = snapshot.data!;
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_tree_outlined,
                      size: 56,
                      color: cs.onSurface.withValues(alpha: 0.2),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.projects_diagrams_empty,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final entry = entries[index];
              final stepCount = entry.board.columns
                  .where((c) => !c.hidden)
                  .fold<int>(0, (n, c) => n + c.steps.length);
              return Card(
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.primary.withValues(alpha: 0.12),
                    child: Icon(Icons.hub_outlined, color: cs.primary),
                  ),
                  title: Text(
                    entry.projectName,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    '${entry.board.rootLabel} · $stepCount ${l10n.projects_diagrams_steps}',
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    await context.push(
                      '/projects/plan?projectId=${entry.projectId}',
                    );
                    _reload();
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _DiagramEntry {
  const _DiagramEntry({
    required this.projectId,
    required this.projectName,
    required this.board,
  });

  final String projectId;
  final String projectName;
  final PlanBoard board;
}
