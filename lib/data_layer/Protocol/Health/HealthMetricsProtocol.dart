import 'package:flutter/widgets.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';
import 'package:ice_gate/data_layer/Protocol/Health/HealthMetricProtocol.dart';

/// Protocol for aggregated person health profile (steps, sleep, HR, etc.).
abstract class HealthMetricsProtocol {
  HealthMetrics? getHealthMetrics();

  Future<bool> updateHealthMetrics(HealthMetrics metrics);

  Future<bool> updateMetric(String metricId, dynamic value);

  dynamic getMetric(String metricId);

  Map<String, String?> validateHealthMetrics(HealthMetrics metrics);
}

/// Protocol for loading health dashboard display tiles.
abstract class HealthDisplayMetricsProtocol {
  List<HealthMetricProtocol> getDefaultMetrics(BuildContext context);

  Future<Map<String, HealthMetricProtocol>> getMetricsByDay(
    String personId,
    DateTime day,
    BuildContext context,
  );
}
