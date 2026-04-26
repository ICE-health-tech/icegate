import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';

class LidarFoodScanner extends StatefulWidget {
  const LidarFoodScanner({super.key});

  @override
  State<LidarFoodScanner> createState() => _LidarFoodScannerState();
}

class _LidarFoodScannerState extends State<LidarFoodScanner> {
  late ARKitController arkitController;
  bool _scanning = false;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('LiDAR Food Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            configuration: ARKitConfiguration.worldTracking,
            enableTapRecognizer: true,
          ),
          // Overlay UI
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Move device to scan food volume',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FloatingActionButton(
                    onPressed: _takeSnapshot,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.camera_alt, size: 28),
                  ),
                ],
              ),
            ),
          ),
          if (_scanning)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
    // We could add plane detection visualization here
    // For now, we will add a reference node to show the scene is working
    // automatic plane detection is enabled by default in worldTracking
  }

  Future<void> _takeSnapshot() async {
    setState(() {
      _scanning = true;
    });

    try {
      // Taking a snapshot of the AR view (simulating a scan)
      await arkitController.snapshot();

      if (!mounted) return;

      setState(() {
        _scanning = false;
      });

      // Return the image or handle the "scan" result
      // For now, we just go back with a success indicator
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food scanned successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error scanning: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
