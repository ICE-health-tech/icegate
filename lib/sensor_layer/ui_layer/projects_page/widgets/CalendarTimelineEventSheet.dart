import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:intl/intl.dart';

/// Bottom sheet when the user taps a timeline event block.
Future<void> showCalendarTimelineEventSheet(
  BuildContext context, {
  required String title,
  required DateTime start,
  DateTime? end,
  String? subtitle,
  required bool canEdit,
  required bool canDelete,
  VoidCallback? onEdit,
  Future<void> Function()? onDelete,
}) {
  final l10n = AppLocalizations.of(context)!;
  final locale = Localizations.localeOf(context).toString();
  final timeFmt = DateFormat.jm(locale);
  final range = end != null
      ? '${timeFmt.format(start)} – ${timeFmt.format(end)}'
      : timeFmt.format(start);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                range,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(ctx).colorScheme.onSurface.withValues(
                        alpha: 0.6,
                      ),
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurface.withValues(
                          alpha: 0.45,
                        ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              if (canEdit && onEdit != null)
                FilledButton.tonalIcon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onEdit();
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: Text(l10n.projects_calendar_edit_event),
                ),
              if (canDelete && onDelete != null) ...[
                if (canEdit && onEdit != null) const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                      context: ctx,
                      builder: (dialogCtx) => AlertDialog(
                        title: Text(l10n.projects_calendar_delete_event),
                        content: Text(
                          l10n.projects_calendar_timeline_remove_confirm(title),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogCtx, false),
                            child: Text(l10n.cancel),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.pop(dialogCtx, true),
                            child: Text(l10n.delete),
                          ),
                        ],
                      ),
                    );
                    if (ok != true || !ctx.mounted) return;
                    Navigator.pop(ctx);
                    await onDelete();
                  },
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: Text(l10n.projects_calendar_delete_event),
                ),
              ],
            ],
          ),
        ),
      );
    },
  );
}
