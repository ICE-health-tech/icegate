import 'package:flutter/material.dart';

class HabitCircularItem extends StatelessWidget {
  final IconData? icon;
  final String? label;
  final String title;
  final String? timeSuffix;
  final bool showPlayButton;
  final VoidCallback onTap;

  const HabitCircularItem({
    super.key,
    this.icon,
    this.label,
    required this.title,
    this.timeSuffix,
    this.showPlayButton = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              // Circular Border
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF4A6115), // Dark green border
                    width: 6,
                  ),
                ),
                child: Center(
                  child: icon != null
                      ? Icon(icon, color: Colors.white, size: 60)
                      : Text(
                          label ?? "",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              // Play Button Wrapper
              if (showPlayButton)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.black,
                      size: 35,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (timeSuffix != null)
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.white70,
                  size: 14,
                ),
              if (timeSuffix != null) const SizedBox(width: 4),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              if (timeSuffix != null) const SizedBox(width: 4),
              if (timeSuffix != null)
                Text(
                  timeSuffix!,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
