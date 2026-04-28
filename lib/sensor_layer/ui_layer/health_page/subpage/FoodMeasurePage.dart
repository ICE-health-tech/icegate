import 'package:arkit_plugin/arkit_plugin.dart';
import 'package:flutter/material.dart';
import 'package:vector_math/vector_math_64.dart' as vector;
import 'dart:math' as math;

class FoodMeasurePage extends StatefulWidget {
  const FoodMeasurePage({super.key});

  @override
  State<FoodMeasurePage> createState() => _FoodMeasurePageState();
}

class _FoodMeasurePageState extends State<FoodMeasurePage> {
  late ARKitController arkitController;
  vector.Vector3? lastPosition;
  double? distance;

  @override
  void dispose() {
    arkitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measure Food Size'),
        actions: [
          if (distance != null)
            IconButton(
              icon: const Icon(Icons.check_circle_rounded),
              onPressed: () {
                Navigator.of(context).pop(distance);
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          ARKitSceneView(
            onARKitViewCreated: onARKitViewCreated,
            enableTapRecognizer: true,
          ),
          if (distance != null)
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Size: ${(distance! * 100).toStringAsFixed(1)} cm',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void onARKitViewCreated(ARKitController controller) {
    arkitController = controller;
    arkitController.onARTap = (List<ARKitTestResult> results) {
      if (results.isNotEmpty) {
        final tap = results.first;
        final position = vector.Vector3(
          tap.worldTransform.getColumn(3).x,
          tap.worldTransform.getColumn(3).y,
          tap.worldTransform.getColumn(3).z,
        );
        _addPoint(position);
      }
    };
  }

  void _addPoint(vector.Vector3 position) {
    final node = ARKitNode(
      geometry: ARKitSphere(radius: 0.005),
      position: position,
    );
    arkitController.add(node);

    if (lastPosition != null) {
      final line = ARKitLine(
        fromVector: lastPosition!,
        toVector: position,
      );
      final lineNode = ARKitNode(geometry: line);
      arkitController.add(lineNode);

      setState(() {
        distance = _calculateDistance(lastPosition!, position);
      });
    }

    lastPosition = position;
  }

  double _calculateDistance(vector.Vector3 p1, vector.Vector3 p2) {
    return math.sqrt(math.pow(p1.x - p2.x, 2) + math.pow(p1.y - p2.y, 2) + math.pow(p1.z - p2.z, 2));
  }
}
