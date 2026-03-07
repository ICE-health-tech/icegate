import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';

/// Protocol for managing finance metrics data
abstract class FinanceMetricsProtocol {
  /// Get the current finance metrics
  FinanceMetrics? getFinanceMetrics();

  /// Update finance metrics
  Future<bool> updateFinanceMetrics(FinanceMetrics metrics);

  /// Update specific metric value
  Future<bool> updateMetric(String metricId, dynamic value);

  /// Get metric by ID
  dynamic getMetric(String metricId);

  /// Validate finance metrics
  Map<String, String?> validateFinanceMetrics(FinanceMetrics metrics);
}

/// Default implementation of FinanceMetricsProtocol
class FinanceMetricsService implements FinanceMetricsProtocol {
  FinanceMetrics? _currentMetrics;

  FinanceMetricsService({FinanceMetrics? initialMetrics})
    : _currentMetrics = initialMetrics;

  @override
  FinanceMetrics? getFinanceMetrics() {
    return _currentMetrics;
  }

  @override
  Future<bool> updateFinanceMetrics(FinanceMetrics metrics) async {
    // Validate before updating
    final errors = validateFinanceMetrics(metrics);
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
      FinanceMetrics updatedMetrics;

      switch (metricId) {
        case 'balance':
          if (value is! double) return false;
          updatedMetrics = _currentMetrics!.copyWith(balance: value);
          break;
        case 'monthlyIncome':
          if (value is! double) return false;
          updatedMetrics = _currentMetrics!.copyWith(monthlyIncome: value);
          break;
        case 'monthlyExpenses':
          if (value is! double) return false;
          updatedMetrics = _currentMetrics!.copyWith(monthlyExpenses: value);
          break;
        case 'savingsRate':
          if (value is! double) return false;
          updatedMetrics = _currentMetrics!.copyWith(savingsRate: value);
          break;
        default:
          return false;
      }

      return await updateFinanceMetrics(updatedMetrics);
    } catch (e) {
      return false;
    }
  }

  @override
  dynamic getMetric(String metricId) {
    if (_currentMetrics == null) return null;

    switch (metricId) {
      case 'balance':
        return _currentMetrics!.balance;
      case 'monthlyIncome':
        return _currentMetrics!.monthlyIncome;
      case 'monthlyExpenses':
        return _currentMetrics!.monthlyExpenses;
      case 'savingsRate':
        return _currentMetrics!.savingsRate;
      case 'monthlySavings':
        return _currentMetrics!.monthlySavings;
      default:
        return null;
    }
  }

  @override
  Map<String, String?> validateFinanceMetrics(FinanceMetrics metrics) {
    final errors = <String, String?>{};

    // Validate balance (can be negative for debt, but warn if too low)
    if (metrics.balance < -1000000) {
      errors['balance'] = 'Balance seems unrealistically low';
    }

    // Validate monthly income (should be non-negative)
    if (metrics.monthlyIncome < 0) {
      errors['monthlyIncome'] = 'Monthly income cannot be negative';
    }

    // Validate monthly expenses (should be non-negative)
    if (metrics.monthlyExpenses < 0) {
      errors['monthlyExpenses'] = 'Monthly expenses cannot be negative';
    }

    // Validate savings rate (should be between 0 and 1)
    if (metrics.savingsRate < 0 || metrics.savingsRate > 1) {
      errors['savingsRate'] = 'Savings rate must be between 0 and 1';
    }

    return errors;
  }
}
