import 'package:flutter/material.dart';

class SSHShortcutKeyRow extends StatelessWidget {
  final Function(String) onKeyPressed;

  const SSHShortcutKeyRow({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<String> keys = ['ESC', 'TAB', 'CTRL', 'ALT', '/', '-', '|', '^'];

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return InkWell(
            onTap: () => onKeyPressed(keys[index]),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.onSurface.withOpacity(0.05)),
              ),
              child: Text(
                keys[index],
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Courier',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
