// import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_neumorphic_plus/flutter_neumorphic.dart';

// --- DÒNG IMPORT TỪ DỰ ÁN CỦA BẠN ---
// import 'package:ice_gate/data_layer/DomainData/Home/InternalWidget.dart';

import 'package:go_router/go_router.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return NeumorphicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Neumorphic(
            style: NeumorphicStyle(
              depth: -8,
              intensity: 0.9,
              boxShape: NeumorphicBoxShape.roundRect(BorderRadius.circular(16)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                NeumorphicIcon(
                  Icons.error_outline,
                  size: 64,
                  style: const NeumorphicStyle(color: Colors.redAccent),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Page not found',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The page you are looking for does not exist.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    NeumorphicButton(
                      onPressed: () => context.go('/'),
                      style: NeumorphicStyle(depth: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: const Text('Home'),
                    ),
                    const SizedBox(width: 12),
                    NeumorphicButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      style: NeumorphicStyle(depth: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: const Text('Back'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
