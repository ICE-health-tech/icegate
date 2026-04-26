import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/orchestration_layer/Services/SSHService.dart';
import 'package:ice_gate/sensor_layer/ui_layer/widget_page/PluginList/TalkSSH/SSHStorageService.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class ProjectNoteItem extends StatelessWidget {
  final ProjectNoteData note;
  final ProjectProtocol project;

  const ProjectNoteItem({super.key, required this.note, required this.project});

  Future<void> _sendToAI(BuildContext context) async {
    if (project.sshHostId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No SSH host linked to this project')),
        );
      }
      return;
    }

    final sshService = SSHService();
    final storage = SSHStorageService();

    final hosts = await storage.loadHosts();
    final host = hosts.where((h) => h.id == project.sshHostId).firstOrNull;

    if (host == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('SSH host not found')));
      }
      return;
    }

    try {
      await sshService.connect(
        host: host.host,
        port: host.port,
        username: host.user,
        password: host.password ?? '',
        useTmux: true,
      );

      final remotePath = project.remotePath ?? '';
      final aiMode = project.aiModel ?? 'gemini';
      final content = note.content;

      if (remotePath.isNotEmpty) {
        sshService.write('cd $remotePath\r');
        await Future.delayed(const Duration(milliseconds: 500));
      }

      String command;
      if (aiMode == 'opencode') {
        command = 'opencode "$content"\r';
      } else {
        command = 'gemini "$content"\r';
      }

      sshService.write(command);

      if (context.mounted) {
        context.push(
          '/widgets/ssh',
          extra: {
            'hostId': project.sshHostId,
            'remotePath': project.remotePath,
          },
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Material(
              color:
                  (isDark
                          ? colorScheme.surfaceContainerHighest
                          : colorScheme.surface)
                      .withValues(alpha: 0.5),
              child: InkWell(
                onTap: () {
                  context.push('/projects/editor', extra: note);
                },
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.description_rounded,
                          color: Color(0xFFB2EBF2), // Icy Blue
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              note.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              AppLocalizations.of(
                                context,
                              )!.project_last_edited_msg(
                                DateFormat(
                                  'MMM d, yyyy',
                                ).format(note.updatedAt),
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (project.sshHostId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getAiColor(
                              project.aiModel,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _getAiColor(
                                project.aiModel,
                              ).withValues(alpha: 0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            (project.aiModel ?? 'gemini').toUpperCase(),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              color: _getAiColor(project.aiModel),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: colorScheme.onSurface.withValues(alpha: 0.3),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _sendToAI(context),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.psychology_rounded,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getAiColor(String? mode) {
    switch (mode?.toLowerCase()) {
      case 'gemini':
        return Colors.blue;
      case 'opencode':
        return Colors.purple;
      case 'openclaw':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}
