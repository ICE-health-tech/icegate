import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class SSHNoteSelectorSheet extends StatelessWidget {
  final Function(ProjectNoteData) onNoteSelected;

  const SSHNoteSelectorSheet({super.key, required this.onNoteSelected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final personBlock = context.read<PersonBlock>();
    final noteDao = context.read<ProjectNoteDAO>();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(Icons.description_rounded, color: colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  l10n.project_notes_label,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: StreamBuilder<List<ProjectNoteData>>(
                stream: noteDao.watchAllNotes(
                  personBlock.information.value.profiles.id ?? "",
                ),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(l10n.system_error(snapshot.error.toString())));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final notes = snapshot.data!;
                  if (notes.isEmpty) {
                    return _buildEmptyState(context, colorScheme, l10n);
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return _NoteTile(
                        note: note,
                        onTap: () {
                          Navigator.pop(context);
                          onNoteSelected(note);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.note_alt_outlined, size: 48, color: colorScheme.onSurface.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            l10n.project_no_notes_list,
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
          ),
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final ProjectNoteData note;
  final VoidCallback onTap;

  const _NoteTile({required this.note, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final updatedAt = note.updatedAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    note.title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  DateFormat.MMMd().format(updatedAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withOpacity(0.4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _getPreviewText(note.content),
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText(String content) {
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        return decoded
            .where((op) => op is Map && op.containsKey('insert'))
            .map((op) => op['insert'])
            .join('')
            .trim();
      }
    } catch (_) {}
    return content.replaceAll(RegExp(r'[#*`>_-]'), '').trim();
  }
}
