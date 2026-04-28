import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

enum IntegrationProvider {
  appleHealth,
  googleFit,
  fitbit,
  garmin,
  oura,
  esp32,
  stm32,
  customMqtt,
}

enum IntegrationType {
  native,
  wearable,
  iot,
  manual,
}

enum IntegrationStatus {
  connected,
  disconnected,
  pairing,
  error,
}

class HealthIntegration {
  final String id;
  final String personId;
  final String name;
  final IntegrationProvider provider;
  final IntegrationType type;
  final IntegrationStatus status;
  final Map<String, dynamic> config;
  final DateTime? lastSync;

  HealthIntegration({
    required this.id,
    required this.personId,
    required this.name,
    required this.provider,
    required this.type,
    required this.status,
    this.config = const {},
    this.lastSync,
  });

  HealthIntegration copyWith({
    String? name,
    IntegrationStatus? status,
    Map<String, dynamic>? config,
    DateTime? lastSync,
  }) {
    return HealthIntegration(
      id: id,
      personId: personId,
      name: name ?? this.name,
      provider: provider,
      type: type,
      status: status ?? this.status,
      config: config ?? this.config,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

class HealthIntegrationBlock {
  final HealthBlock _healthBlock;
  final String personId;

  // Reactive State
  final integrations = signal<List<HealthIntegration>>([]);
  final isScanning = signal<bool>(false);
  final activeDataStreamCount = signal<int>(0);

  HealthIntegrationBlock({
    required this.personId,
    required HealthBlock healthBlock,
  }) : _healthBlock = healthBlock {
    _loadStoredIntegrations();
  }

  void _loadStoredIntegrations() {
    // In a real app, this would load from Supabase or Local DB
    // For the prototype, we'll seed with the Apple Health integration
    integrations.value = [
      HealthIntegration(
        id: IDGen.generateDeterministicUuid(personId, "apple_health_v1"),
        personId: personId,
        name: "Apple Health",
        provider: IntegrationProvider.appleHealth,
        type: IntegrationType.native,
        status: IntegrationStatus.connected,
        lastSync: DateTime.now(),
      ),
    ];
  }

  // --- DEVICE MANAGEMENT ---

  Future<void> connectNativeProvider(IntegrationProvider provider) async {
    // Logic for HealthKit/GoogleFit permissions
    debugPrint("Backend: Requesting permissions for ${provider.name}...");
    await Future.delayed(const Duration(seconds: 2)); // Mocking native delay
    
    final newIntegration = HealthIntegration(
      id: IDGen.generateDeterministicUuid(personId, "${provider.name}_v1"),
      personId: personId,
      name: provider == IntegrationProvider.googleFit ? "Google Fit" : "Native Sync",
      provider: provider,
      type: IntegrationType.native,
      status: IntegrationStatus.connected,
      lastSync: DateTime.now(),
    );

    _addOrUpdateIntegration(newIntegration);
  }

  Future<void> connectIoTDevice({
    required String name,
    required IntegrationProvider provider,
    required Map<String, dynamic> config,
  }) async {
    debugPrint("Backend: Connecting to $name via ${config['protocol']}...");
    
    final id = IDGen.generateUuid();
    final integration = HealthIntegration(
      id: id,
      personId: personId,
      name: name,
      provider: provider,
      type: IntegrationType.iot,
      status: IntegrationStatus.pairing,
      config: config,
    );

    _addOrUpdateIntegration(integration);

    // Mock successful pairing
    await Future.delayed(const Duration(seconds: 3));
    
    _addOrUpdateIntegration(integration.copyWith(
      status: IntegrationStatus.connected,
      lastSync: DateTime.now(),
    ));

    // Simulate starting a data ingestion pipeline
    _startDataIngestion(id);
  }

  void _addOrUpdateIntegration(HealthIntegration integration) {
    final list = List<HealthIntegration>.from(integrations.value);
    final index = list.indexWhere((item) => item.id == integration.id);
    
    if (index != -1) {
      list[index] = integration;
    } else {
      list.add(integration);
    }
    
    integrations.value = list;
  }

  // --- DATA INGESTION PIPELINE ---

  void _startDataIngestion(String integrationId) {
    activeDataStreamCount.value++;
    
    // In a real app, this would setup MQTT subscribers or BLE listeners
    debugPrint("Backend: Data ingestion pipeline started for $integrationId");
    
    // Simulate incoming data points every few seconds
    if (kDebugMode) {
      // Logic would be handled by hardware bridges
    }
  }

  /// Entry point for external sensors to push data into the system
  void pushSensorData({
    required String integrationId,
    required Map<String, dynamic> data,
  }) {
    final integration = integrations.value.firstWhere((i) => i.id == integrationId);
    if (integration.status != IntegrationStatus.connected) return;

    debugPrint("Backend: Received sensor data from ${integration.name}: $data");

    // Route data to HealthBlock based on type
    if (data.containsKey('steps')) {
      _healthBlock.updateSteps(data['steps'] as int);
    }
    if (data.containsKey('heart_rate')) {
      _healthBlock.updateHeartRate(data['heart_rate'] as int);
    }
    if (data.containsKey('weight')) {
      _healthBlock.updateWeight(data['weight'] as double);
    }

    _updateLastSync(integrationId);
  }

  void _updateLastSync(String id) {
    final list = List<HealthIntegration>.from(integrations.value);
    final index = list.indexWhere((item) => item.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(lastSync: DateTime.now());
      integrations.value = list;
    }
  }

  void disconnect(String id) {
    final list = List<HealthIntegration>.from(integrations.value);
    list.removeWhere((item) => item.id == id);
    integrations.value = list;
    activeDataStreamCount.value = (activeDataStreamCount.value - 1).clamp(0, 99);
    debugPrint("Backend: Disconnected integration $id");
  }
}
