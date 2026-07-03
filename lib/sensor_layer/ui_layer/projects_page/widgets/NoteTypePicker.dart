import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

/// Glass L2 picker — shared by Projects hub, folder details, notes list.
Future<String?> showNoteTypePicker(
  BuildContext context, {
  bool includeDocx = true,
}) {
  final l10n = AppLocalizations.of(context)!;
  final options = <_NoteTypeOption>[
    _NoteTypeOption(
      ext: '.md',
      label: l10n.note_type_markdown,
      icon: Icons.integration_instructions_outlined,
    ),
    _NoteTypeOption(
      ext: '.txt',
      label: l10n.note_type_plain_text,
      icon: Icons.notes_rounded,
    ),
    if (includeDocx)
      _NoteTypeOption(
        ext: '.docx',
        label: l10n.note_type_word,
        icon: Icons.description_outlined,
      ),
  ];

  return showDialog<String>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (dialogContext) {
      final cs = Theme.of(dialogContext).colorScheme;
      return Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            width: 280,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.35),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.note_type_picker_title,
                  style: Theme.of(dialogContext).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                for (final option in options)
                  _NoteTypeTile(
                    option: option,
                    onTap: () => Navigator.pop(dialogContext, option.ext),
                  ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _NoteTypeOption {
  const _NoteTypeOption({
    required this.ext,
    required this.label,
    required this.icon,
  });

  final String ext;
  final String label;
  final IconData icon;
}

class _NoteTypeTile extends StatelessWidget {
  const _NoteTypeTile({required this.option, required this.onTap});

  final _NoteTypeOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Icon(option.icon, size: 20, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                option.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
