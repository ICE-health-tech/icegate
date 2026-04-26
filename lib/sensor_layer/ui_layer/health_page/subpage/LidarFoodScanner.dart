import 'package:flutter/material.dart';
import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:async';

class LidarFoodScanner extends StatefulWidget {
  const LidarFoodScanner({super.key});

  @override
  State<LidarFoodScanner> createState() => _LidarFoodScannerState();
}

class _LidarFoodScannerState extends State<LidarFoodScanner> {
  late ARKitController arkitController;
  final List<vector.Vector3> _points = [];
  double _calculatedVolumeCm3 = 0;
  bool _isScanning = false;
  Timer? _scanTimer;

  @override
  void dispose() {
    _scanTimer?.cancel();
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Food 3D Scanner'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_points.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: _resetPoints,
            ),
        ],
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            configuration: ARKitConfiguration.worldTracking,
            enableTapRecognizer: true,
          ),
          
          // Scanning HUD
          Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                border: Border.all(
                  color: _isScanning ? Colors.red.withOpacity(0.5) : Colors.white24,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  if (_isScanning)
                    const Center(
                      child: Icon(Icons.view_in_ar_rounded, color: Colors.red, size: 40),
                    ),
                  Center(
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Measurement & Results
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_points.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorScheme.primary, width: 1),
                      boxShadow: [BoxShadow(color: colorScheme.primary.withOpacity(0.3), blurRadius: 15)],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Estimated Volume'.toUpperCase(),
                          style: TextStyle(color: colorScheme.primary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_calculatedVolumeCm3.toStringAsFixed(1)} cm³',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${_points.length} scan points',
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Scan Toggle Button
                    GestureDetector(
                      onTap: _toggleScan,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _isScanning ? Colors.red : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: (_isScanning ? Colors.red : Colors.white).withOpacity(0.4),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isScanning ? Icons.stop_rounded : Icons.sensors_rounded,
                          color: _isScanning ? Colors.white : Colors.black,
                          size: 40,
                        ),
                      ),
                    ),
                    
                    if (_points.length > 5)
                      FloatingActionButton.large(
                        onPressed: _finishAndReturn,
                        backgroundColor: colorScheme.primary,
                        child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isScanning ? 'Scan the entire food portion' : 'Tap to start 3D Food Scan',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 4)]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController arkitController) {
    this.arkitController = arkitController;
  }

  void _toggleScan() {
    setState(() {
      _isScanning = !_isScanning;
    });

    if (_isScanning) {
      _scanTimer = Timer.periodic(const Duration(milliseconds: 150), (timer) {
        _captureCurrentPoint();
      });
    } else {
      _scanTimer?.cancel();
    }
  }

  Future<void> _captureCurrentPoint() async {
    // Check if controller is initialized to avoid LateInitializationError
    if (!mounted || !context.mounted) return;
    
    try {
      final results = await arkitController.performHitTest(x: 0.5, y: 0.5);
      if (results.isNotEmpty) {
        final transform = results.first.worldTransform;
        final position = vector.Vector3(
          transform.getColumn(3).x,
          transform.getColumn(3).y,
          transform.getColumn(3).z,
        );

        // Density check
        bool tooClose = false;
        int checkLimit = _points.length > 50 ? 50 : _points.length;
        for (int i = _points.length - checkLimit; i < _points.length; i++) {
          if (i >= 0 && _points[i].distanceTo(position) < 0.015) { // 1.5cm
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          _addPoint(position);
        }
      }
    } catch (e) {
      // It's normal to fail if controller isn't ready yet or scene is lost
      debugPrint('Capture attempt: $e');
    }
  }

  void _addPoint(vector.Vector3 position) {
    setState(() {
      _points.add(position);
      _calculateVolume();
    });

    final node = ARKitNode(
      geometry: ARKitSphere(
        radius: 0.004, // 4mm
        materials: [
          ARKitMaterial(
            diffuse: ARKitMaterialProperty.color(Colors.cyanAccent),
            lightingModelName: ARKitLightingModel.constant,
          ),
        ],
      ),
      position: position,
    );
    arkitController.add(node);
  }

  void _calculateVolume() {
    if (_points.length < 3) return;

    // Use a simple bounding box volume for the scanned points
    double minX = _points[0].x, maxX = _points[0].x;
    double minY = _points[0].y, maxY = _points[0].y;
    double minZ = _points[0].z, maxZ = _points[0].z;

    for (var p in _points) {
      if (p.x < minX) minX = p.x;
      if (p.x > maxX) maxX = p.x;
      if (p.y < minY) minY = p.y;
      if (p.y > maxY) maxY = p.y;
      if (p.z < minZ) minZ = p.z;
      if (p.z > maxZ) maxZ = p.z;
    }

    double l = (maxX - minX) * 100;
    double w = (maxY - minY) * 100;
    double h = (maxZ - minZ) * 100;

    // Food isn't a perfect cube, usually 70% of bounding box
    setState(() {
      _calculatedVolumeCm3 = l * w * h * 0.7;
    });
  }

  void _resetPoints() {
    setState(() {
      _points.clear();
      _calculatedVolumeCm3 = 0;
      _isScanning = false;
    });
    _scanTimer?.cancel();
    // Quick reload
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LidarFoodScanner()));
  }

  Future<void> _finishAndReturn() async {
    _scanTimer?.cancel();
    setState(() => _isScanning = false);

    if (_points.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    try {
      // Capture a snapshot of the AR scene with the points
      final imageProvider = await arkitController.snapshot();
      
      // Calculate dimensions
      double minX = _points[0].x, maxX = _points[0].x;
      for (var p in _points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
      }
      double lengthCm = (maxX - minX) * 100;

      if (mounted) {
        Navigator.of(context).pop({
          'volume': _calculatedVolumeCm3,
          'image': imageProvider, // Return the snapshot
          'dimensions': {
            'length': lengthCm,
            'points': _points.length,
          }
        });
      }
    } catch (e) {
      debugPrint('Snapshot error: $e');
      if (mounted) {
        Navigator.of(context).pop({
          'volume': _calculatedVolumeCm3,
          'dimensions': {'length': 0, 'points': _points.length}
        });
      }
    }
  }
}
