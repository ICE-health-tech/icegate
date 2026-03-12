import 'package:flutter/material.dart';

class SSHShortcutKeyRow extends StatelessWidget {
  final Function(String) onKeyPressed;

  const SSHShortcutKeyRow({super.key, required this.onKeyPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final List<Map<String, dynamic>> keys = [
      {'label': 'ESC', 'value': 'ESC', 'color': Colors.orangeAccent},
      {'label': 'TAB', 'value': 'TAB', 'color': colorScheme.primary},
      {'label': 'S-TAB', 'value': 'S-TAB', 'color': colorScheme.primary},
      {'label': 'CTRL', 'value': 'CTRL', 'color': Colors.blueAccent},
      {'label': 'ALT', 'value': 'ALT', 'color': Colors.purpleAccent},
      {'label': '↑', 'value': '\x1b[A'},
      {'label': '↓', 'value': '\x1b[B'},
      {'label': '←', 'value': '\x1b[D'},
      {'label': '→', 'value': '\x1b[C'},
      {'label': 'HOME', 'value': '\x1b[H'},
      {'label': 'END', 'value': '\x1b[F'},
      {'label': 'PGUP', 'value': '\x1b[5~'},
      {'label': 'PGDN', 'value': '\x1b[6~'},
      {'label': '/', 'value': '/'},
      {'label': '-', 'value': '-'},
      {'label': '|', 'value': '|'},
      {'label': '^', 'value': '^'},
      {'label': 'C-c', 'value': '\x03', 'color': Colors.redAccent},
      {'label': 'C-d', 'value': '\x04', 'color': Colors.redAccent},
      {'label': 'C-z', 'value': '\x1a', 'color': Colors.redAccent},
      {'label': 'C-l', 'value': '\x0c', 'color': Colors.greenAccent},
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: keys.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final key = keys[index];
          final color = key['color'] as Color? ?? colorScheme.primary;
          final isSpecial = key.containsKey('color');
          
          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onKeyPressed(key['value']),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSpecial ? color.withOpacity(0.1) : Colors.black.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSpecial ? color.withOpacity(0.5) : colorScheme.onSurface.withOpacity(0.05),
                    width: isSpecial ? 1.5 : 1,
                  ),
                  boxShadow: [
                    if (isSpecial) BoxShadow(
                      color: color.withOpacity(0.2),
                      blurRadius: 4,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  key['label'],
                  style: TextStyle(
                    color: isSpecial ? color : colorScheme.onSurface.withOpacity(0.6),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'Courier',
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
