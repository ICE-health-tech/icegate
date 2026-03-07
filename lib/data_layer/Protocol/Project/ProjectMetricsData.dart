import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';

/// Protocol for managing project metrics data
abstract class ProjectMetricsProtocol {
  /// Get the current project metrics
  ProjectMetrics? getProjectMetrics();

  /// Update project metrics
  Future<bool> updateProjectMetrics(ProjectMetrics metrics);

  /// Update specific metric value
  Future<bool> updateMetric(String metricId, dynamic value);

  /// Get metric by ID
  dynamic getMetric(String metricId);

  /// Validate project metrics
  Map<String, String?> validateProjectMetrics(ProjectMetrics metrics);
}

/// Default implementation of ProjectMetricsProtocol
class ProjectMetricsService implements ProjectMetricsProtocol {
  ProjectMetrics? _currentMetrics;

  ProjectMetricsService({ProjectMetrics? initialMetrics})
    : _currentMetrics = initialMetrics;

  @override
  ProjectMetrics? getProjectMetrics() {
    return _currentMetrics;
  }

  @override
  Future<bool> updateProjectMetrics(ProjectMetrics metrics) async {
    // Validate before updating
    final errors = validateProjectMetrics(metrics);
    if (errors.values.any((error) => error != null)) {
      return false;
    }

    // Simulate async operation
    await Future.delayed(const Duration(milliseconds: 300));
    _currentMetrics = metrics;
    return true;
  }

  @override
  Future<bool> updateMetric(String metricId, dynamic value) async {
    if (_currentMetrics == null) return false;

    try {
      ProjectMetrics updatedMetrics;

      switch (metricId) {
        case 'activeProjects':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(activeProjects: value);
          break;
        case 'completedProjects':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(completedProjects: value);
          break;
        case 'tasksToday':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(tasksToday: value);
          break;
        default:
          return false;
      }

      return await updateProjectMetrics(updatedMetrics);
    } catch (e) {
      return false;
    }
  }

  @override
  dynamic getMetric(String metricId) {
    if (_currentMetrics == null) return null;

    switch (metricId) {
      case 'activeProjects':
        return _currentMetrics!.activeProjects;
      case 'completedProjects':
        return _currentMetrics!.completedProjects;
      case 'tasksToday':
        return _currentMetrics!.tasksToday;
      case 'totalProjects':
        return _currentMetrics!.totalProjects;
      default:
        return null;
    }
  }

  @override
  Map<String, String?> validateProjectMetrics(ProjectMetrics metrics) {
    final errors = <String, String?>{};

    // Validate active projects (should be non-negative)
    if (metrics.activeProjects < 0) {
      errors['activeProjects'] = 'Active projects cannot be negative';
    }

    // Validate completed projects (should be non-negative)
    if (metrics.completedProjects < 0) {
      errors['completedProjects'] = 'Completed projects cannot be negative';
    }

    // Validate tasks today (should be non-negative)
    if (metrics.tasksToday < 0) {
      errors['tasksToday'] = 'Tasks today cannot be negative';
    }

    return errors;
  }
}
