import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/MindGratitudePanel.dart';
import 'package:provider/provider.dart';

/// Shown under journal activities when [act_gratitude] is selected.
class GratitudeLogPicker extends StatelessWidget {
  const GratitudeLogPicker({
    super.key,
    required this.personId,
    required this.selectedEntryId,
    required this.onSelected,
  });

  final String personId;
  final String? selectedEntryId;
  final ValueChanged<String?> onSelected;

  static const _accent = MindGratitudePanel.flagColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<List<GratitudeEntryData>>(
      stream: context.read<AppDatabase>().gratitudeDAO.watchForPerson(personId),
      builder: (context, snap) {
        final entries = snap.data ?? const [];

        return AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accent.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_rounded, color: _accent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.gratitude_pick_title,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        await MindGratitudePanel.showAddDialog(context);
                      },
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(l10n.gratitude_add_title),
                    ),
                  ],
                ),
                if (!snap.hasData)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                else if (entries.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Text(
                      l10n.gratitude_empty_subtitle,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final e in entries)
                        FilterChip(
                          selected: selectedEntryId == e.id,
                          showCheckmark: true,
                          avatar: Icon(
                            e.kind == 'thing'
                                ? Icons.category_outlined
                                : Icons.person_outline_rounded,
                            size: 16,
                            color: selectedEntryId == e.id
                                ? colorScheme.onPrimaryContainer
                                : _accent,
                          ),
                          label: Text(e.name),
                          selectedColor: _accent.withValues(alpha: 0.35),
                          onSelected: (on) {
                            onSelected(on ? e.id : null);
                          },
                        ),
                    ],
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
