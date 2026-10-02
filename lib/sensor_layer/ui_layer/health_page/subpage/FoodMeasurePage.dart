import 'package:flutter/material.dart';

class FoodMeasurePage extends StatefulWidget {
  const FoodMeasurePage({super.key});

  @override
  State<FoodMeasurePage> createState() => _FoodMeasurePageState();
}

class _FoodMeasurePageState extends State<FoodMeasurePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure Food Size'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline_rounded, size: 34),
                const SizedBox(height: 12),
                Text(
                  '3D measurement has been disabled to comply with App Store requirements.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'You can still log food calories using photo-based estimation or manual entry.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7)),
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
