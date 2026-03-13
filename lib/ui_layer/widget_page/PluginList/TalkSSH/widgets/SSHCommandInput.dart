import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class SSHCommandInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback? onNoteImportPressed;

  const SSHCommandInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.onNoteImportPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        border: Border(top: BorderSide(color: colorScheme.primary.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(
                  color: colorScheme.onSurface, 
                  fontSize: 14, 
                  fontFamily: 'Courier',
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                decoration: InputDecoration(
                  prefixIcon: onNoteImportPressed != null 
                    ? IconButton(
                        icon: Icon(
                          Icons.note_add_rounded,
                          color: colorScheme.primary.withOpacity(0.8),
                          size: 20,
                        ),
                        onPressed: onNoteImportPressed,
                        tooltip: 'Import Plan',
                      )
                    : Icon(
                        Icons.terminal_rounded,
                        color: colorScheme.primary.withOpacity(0.6),
                        size: 18,
                      ),
                  hintText: l10n.ssh_type_command.toUpperCase(),
                  hintStyle: TextStyle(
                    color: colorScheme.onSurface.withOpacity(0.2), 
                    fontSize: 11,
                    fontFamily: 'Courier',
                    letterSpacing: 2,
                    fontWeight: FontWeight.w900,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onSubmitted: (_) => onSend(),
                cursorColor: colorScheme.primary,
                cursorWidth: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          _buildSendButton(colorScheme),
        ],
      ),
    );
  }

  Widget _buildSendButton(ColorScheme colorScheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSend,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.primary.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(Icons.send_rounded, color: colorScheme.primary, size: 22),
        ),
      ),
    );
  }
}
