import 'dart:async';
import 'package:flutter/foundation.dart';

/// Abstract interface for any hardware sensor bridge.
/// Implementations handle the protocol-specific details (BLE, MQTT, etc.)
abstract class SensorBridge {
  final String deviceId;
  final String name;

  SensorBridge({required this.deviceId, required this.name});

  Stream<Map<String, dynamic>> get dataStream;
  Future<bool> connect();
  Future<void> disconnect();
  bool get isConnected;
}

/// Implementation for ESP32 over MQTT
class MqttSensorBridge extends SensorBridge {
  final String brokerAddress;
  final String topic;
  
  MqttSensorBridge({
    required super.deviceId,
    required super.name,
    required this.brokerAddress,
    required this.topic,
  });

  final _streamController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get dataStream => _streamController.stream;

  @override
  bool isConnected = false;

  @override
  Future<bool> connect() async {
    debugPrint("MQTT: Connecting to $brokerAddress...");
    // 1. Initialize MQTT Client (e.g., using mqtt_client package)
    // 2. Setup callbacks for messages
    // 3. Subscribe to 'topic'
    
    // Simulation:
    isConnected = true;
    _startSimulation();
    return true;
  }

  void _startSimulation() {
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!isConnected) {
        timer.cancel();
        return;
      }
      _streamController.add({
        'steps': 10,
        'heart_rate': 72 + (timer.tick % 5),
        'timestamp': DateTime.now().toIso8601String(),
      });
    });
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
    await _streamController.close();
  }
}

/// Implementation for STM32 over BLE (Bluetooth Low Energy)
class BleSensorBridge extends SensorBridge {
  final String serviceUuid;
  final String characteristicUuid;

  BleSensorBridge({
    required super.deviceId,
    required super.name,
    required this.serviceUuid,
    required this.characteristicUuid,
  });

  @override
  Stream<Map<String, dynamic>> get dataStream => const Stream.empty(); // Implementation would use flutter_blue_plus

  @override
  bool isConnected = false;

  @override
  Future<bool> connect() async {
    debugPrint("BLE: Connecting to $serviceUuid...");
    // 1. Scan for deviceId
    // 2. Discover services
    // 3. Enable notifications on characteristicUuid
    isConnected = true;
    return true;
  }

  @override
  Future<void> disconnect() async {
    isConnected = false;
  }
}
