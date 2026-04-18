import 'package:flutter/material.dart';

class MoodSelector extends StatelessWidget {
  final int selectedMood;
  final Function(int) onMoodSelected;

  const MoodSelector({
    super.key,
    required this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMoodItem(context, 1, "Awful", Icons.sentiment_very_dissatisfied_rounded, const Color(0xFF8000FF)),
        _buildMoodItem(context, 2, "Bad", Icons.sentiment_dissatisfied_rounded, const Color(0xFF2C3E50)),
        _buildMoodItem(context, 3, "Meh", Icons.sentiment_neutral_rounded, const Color(0xFFE0E0E0)),
        _buildMoodItem(context, 4, "Good", Icons.sentiment_satisfied_alt_rounded, const Color(0xFF00FF88)),
        _buildMoodItem(context, 5, "Rad", Icons.sentiment_very_satisfied_rounded, const Color(0xFF00FFFF)),
      ],
    );
  }

  Widget _buildMoodItem(BuildContext context, int score, String label, IconData icon, Color color) {
    final isSelected = selectedMood == score;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => onMoodSelected(score),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: EdgeInsets.all(isSelected ? 16 : 12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        color.withValues(alpha: 0.8),
                        color.withValues(alpha: 0.4),
                      ],
                    )
                  : null,
              color: isSelected ? null : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      )
                    ]
                  : [],
              border: Border.all(
                color: isSelected ? color : colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Icon(
              icon,
              size: isSelected ? 32 : 28,
              color: isSelected ? Colors.white : colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
