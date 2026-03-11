import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class SSHCommandInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const SSHCommandInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                style: TextStyle(color: colorScheme.onSurface, fontSize: 15, fontFamily: 'Courier'),
                decoration: InputDecoration(
                  icon: Text(
                    '\$',
                    style: TextStyle(
                      color: colorScheme.primary.withOpacity(0.7),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  hintText: l10n.ssh_type_command,
                  hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.3), fontSize: 15),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onSend,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.send, color: colorScheme.onPrimary, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
