import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';

/// Protocol for managing social metrics data
abstract class SocialMetricsProtocol {
  /// Get the current social metrics
  SocialMetrics? getSocialMetrics();

  /// Update social metrics
  Future<bool> updateSocialMetrics(SocialMetrics metrics);

  /// Update specific metric value
  Future<bool> updateMetric(String metricId, dynamic value);

  /// Get metric by ID
  dynamic getMetric(String metricId);

  /// Validate social metrics
  Map<String, String?> validateSocialMetrics(SocialMetrics metrics);
}

/// Default implementation of SocialMetricsProtocol
class SocialMetricsService implements SocialMetricsProtocol {
  SocialMetrics? _currentMetrics;

  SocialMetricsService({SocialMetrics? initialMetrics})
    : _currentMetrics = initialMetrics;

  @override
  SocialMetrics? getSocialMetrics() {
    return _currentMetrics;
  }

  @override
  Future<bool> updateSocialMetrics(SocialMetrics metrics) async {
    // Validate before updating
    final errors = validateSocialMetrics(metrics);
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
      SocialMetrics updatedMetrics;

      switch (metricId) {
        case 'friendsCount':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(friendsCount: value);
          break;
        case 'unreadMessages':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(unreadMessages: value);
          break;
        case 'upcomingEvents':
          if (value is! int) return false;
          updatedMetrics = _currentMetrics!.copyWith(upcomingEvents: value);
          break;
        default:
          return false;
      }

      return await updateSocialMetrics(updatedMetrics);
    } catch (e) {
      return false;
    }
  }

  @override
  dynamic getMetric(String metricId) {
    if (_currentMetrics == null) return null;

    switch (metricId) {
      case 'friendsCount':
        return _currentMetrics!.friendsCount;
      case 'unreadMessages':
        return _currentMetrics!.unreadMessages;
      case 'upcomingEvents':
        return _currentMetrics!.upcomingEvents;
      default:
        return null;
    }
  }

  @override
  Map<String, String?> validateSocialMetrics(SocialMetrics metrics) {
    final errors = <String, String?>{};

    // Validate friends count (should be non-negative)
    if (metrics.friendsCount < 0) {
      errors['friendsCount'] = 'Friends count cannot be negative';
    }

    // Validate unread messages (should be non-negative)
    if (metrics.unreadMessages < 0) {
      errors['unreadMessages'] = 'Unread messages cannot be negative';
    }

    // Validate upcoming events (should be non-negative)
    if (metrics.upcomingEvents < 0) {
      errors['upcomingEvents'] = 'Upcoming events cannot be negative';
    }

    return errors;
  }
}
