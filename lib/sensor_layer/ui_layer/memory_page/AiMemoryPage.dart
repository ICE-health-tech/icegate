import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Memory/AiMemoryBlock.dart';
import 'package:ice_gate/orchestration_layer/Services/AutoCaptureJob.dart';
import 'package:signals_flutter/signals_flutter.dart';

/// Review surface for screen memory: pending captures, draft memories
/// awaiting a decision, and the settings that gate automatic capture.
///
/// Nothing here is confirmed implicitly — every memory starts as a draft and
/// only a tap makes it eligible for prompt injection.
class AiMemoryPage extends StatelessWidget {
  final AiMemoryBlock block;

  const AiMemoryPage({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(t.aiMemoryTitle)),
      body: Watch((_) {
        final memories = block.memories.value;
        final drafts = memories.where((m) => m.status == 'draft').toList();
        final confirmed = memories
            .where((m) => m.status == 'confirmed')
            .toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildAutoCaptureCard(context, t),
            const SizedBox(height: 16),
            Text(
              t.aiMemoryDraftsTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (drafts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(t.aiMemoryNoDrafts),
              )
            else
              ...drafts.map((m) => _MemoryCard(block: block, memory: m)),
            const SizedBox(height: 24),
            Text(
              t.aiMemoryConfirmedTitle,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (confirmed.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(t.aiMemoryNoConfirmed),
              )
            else
              ...confirmed.map((m) => _MemoryCard(block: block, memory: m)),
          ],
        );
      }),
    );
  }

  Widget _buildAutoCaptureCard(BuildContext context, AppLocalizations t) {
    final enabled = block.isAutoCaptureEnabled.value;
    final capturesLeft = block.dailyCap.value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: enabled,
              onChanged: (v) => block.setAutoCaptureEnabled(v),
              title: Text(t.aiMemoryAutoCaptureTitle),
              subtitle: Text(
                t.aiMemoryAutoCaptureSubtitle(capturesLeft),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Divider(),
            Text(
              t.aiMemoryDisclosure,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${t.aiMemoryDailyCap}: ${block.dailyCap.value}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      block.setDailyCap(block.dailyCap.value - 1),
                  child: const Text('−'),
                ),
                TextButton(
                  onPressed: () =>
                      block.setDailyCap(block.dailyCap.value + 1),
                  child: const Text('+'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                TextButton.icon(
                  onPressed: block.isSyncing.value
                      ? null
                      : () => block.syncNow(),
                  icon: const Icon(Icons.sync),
                  label: Text(t.aiMemorySyncNow),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _confirmDeleteAll(context, t),
                  icon: const Icon(Icons.delete_outline),
                  label: Text(t.aiMemoryDeleteAll),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAll(
    BuildContext context,
    AppLocalizations t,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.aiMemoryDeleteAll),
        content: Text(t.aiMemoryDeleteAllConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t.new_label),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t.aiMemoryDeleteAll),
          ),
        ],
      ),
    );
    if (ok == true) {
      await block.deleteAllCaptures();
    }
  }
}

class _MemoryCard extends StatelessWidget {
  final AiMemoryBlock block;
  final AiMemoryData memory;

  const _MemoryCard({required this.block, required this.memory});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final isDraft = memory.status == 'draft';
    List<String> tags = const [];
    try {
      final decoded = jsonDecode(memory.tags ?? '[]');
      if (decoded is List) tags = decoded.map((e) => e.toString()).toList();
    } catch (_) {
      tags = const [];
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              memory.title.isEmpty ? t.aiMemoryTitle : memory.title,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(memory.content),
            if (tags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: tags
                    .map(
                      (tag) => Chip(
                        label: Text(tag),
                        visualDensity: VisualDensity.compact,
                      ),
                    )
                    .toList(),
              ),
            ],
            if (isDraft) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => block.discardMemory(memory.id),
                    child: Text(t.aiMemoryDiscard),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => block.confirmMemory(memory.id),
                    child: Text(t.aiMemoryConfirm),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
