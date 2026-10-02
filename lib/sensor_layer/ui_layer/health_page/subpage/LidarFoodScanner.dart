import 'package:flutter/material.dart';

/// NOTE:
/// This feature previously used ARKit/LiDAR via `arkit_plugin`.
/// App Review flagged TrueDepth API usage for food scanning, so 3D scanning is
/// disabled for App Store compliance.
class LidarFoodScanner extends StatelessWidget {
  const LidarFoodScanner({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Food Scanner')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline_rounded, color: cs.primary, size: 36),
                const SizedBox(height: 12),
                Text(
                  '3D scanning is disabled to comply with App Store requirements.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Use manual entry or photo-based calorie estimation instead.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: cs.onSurface.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

