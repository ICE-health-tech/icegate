import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// One day of aggregated health metrics from [get_health_steps_trend] RPC.
class HealthTrendPoint {
  final DateTime date;
  final int steps;
  final int caloriesBurned;

  const HealthTrendPoint({
    required this.date,
    required this.steps,
    required this.caloriesBurned,
  });
}

/// Full daily row from [get_health_metrics] / [get_health_metrics_for_day].
class HealthMetricRemoteRow {
  final String id;
  final String? personId;
  final DateTime date;
  final String? category;
  final int steps;
  final int? heartRate;
  final double? sleepHours;
  final int? waterGlasses;
  final int? exerciseMinutes;
  final int? focusMinutes;
  final double? weightKg;
  final int? caloriesConsumed;
  final int? caloriesBurned;
  final double? oxygenSaturation;
  final double? questPoints;
  final String? source;
  final DateTime? updatedAt;

  const HealthMetricRemoteRow({
    required this.id,
    required this.date,
    this.personId,
    this.category,
    this.steps = 0,
    this.heartRate,
    this.sleepHours,
    this.waterGlasses,
    this.exerciseMinutes,
    this.focusMinutes,
    this.weightKg,
    this.caloriesConsumed,
    this.caloriesBurned,
    this.oxygenSaturation,
    this.questPoints,
    this.source,
    this.updatedAt,
  });

  factory HealthMetricRemoteRow.fromMap(Map<String, dynamic> m) {
    final d = m['metric_date'] ?? m['metricdate'] ?? m['date'];
    final date = d == null
        ? DateTime.now()
        : (DateTime.tryParse(d.toString()) ?? DateTime.now());
    final updated = m['updated_at'] ?? m['updatedat'];
    return HealthMetricRemoteRow(
      id: (m['id'] ?? '').toString(),
      personId: m['person_id']?.toString() ?? m['personid']?.toString(),
      date: DateTime(date.year, date.month, date.day),
      category: m['category']?.toString(),
      steps: (m['steps'] as num?)?.round() ?? 0,
      heartRate: (m['heart_rate'] as num?)?.round() ??
          (m['heartrate'] as num?)?.round(),
      sleepHours: (m['sleep_hours'] as num?)?.toDouble() ??
          (m['sleephours'] as num?)?.toDouble(),
      waterGlasses: (m['water_glasses'] as num?)?.round() ??
          (m['waterglasses'] as num?)?.round(),
      exerciseMinutes: (m['exercise_minutes'] as num?)?.round() ??
          (m['exerciseminutes'] as num?)?.round(),
      focusMinutes: (m['focus_minutes'] as num?)?.round() ??
          (m['focusminutes'] as num?)?.round(),
      weightKg: (m['weight_kg'] as num?)?.toDouble() ??
          (m['weightkg'] as num?)?.toDouble(),
      caloriesConsumed: (m['calories_consumed'] as num?)?.round() ??
          (m['caloriesconsumed'] as num?)?.round(),
      caloriesBurned: (m['calories_burned'] as num?)?.round() ??
          (m['caloriesburned'] as num?)?.round(),
      oxygenSaturation: (m['oxygen_saturation'] as num?)?.toDouble() ??
          (m['oxygensaturation'] as num?)?.toDouble(),
      questPoints: (m['quest_points'] as num?)?.toDouble() ??
          (m['questpoints'] as num?)?.toDouble(),
      source: m['source']?.toString(),
      updatedAt: updated == null ? null : DateTime.tryParse(updated.toString()),
    );
  }
}

/// Fetches pre-aggregated insight series from Supabase (report engine in SQL).
class HealthInsightsRemoteService {
  HealthInsightsRemoteService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  /// Returns empty list if not signed in, on error, or when RPC returns nothing.
  Future<List<HealthTrendPoint>> fetchStepsTrend({int days = 14}) async {
    final session = _client.auth.currentSession;
    if (session == null) {
      return [];
    }

    try {
      final response = await _client.rpc(
        'get_health_steps_trend',
        params: {'p_days': days},
      );

      if (response == null) return [];

      final list = response is List
          ? response
          : (response as List<dynamic>?) ?? <dynamic>[];

      final out = <HealthTrendPoint>[];
      for (final row in list) {
        if (row is! Map) continue;
        final m = Map<String, dynamic>.from(row);
        final d = m['metric_date'] ?? m['metricdate'];
        if (d == null) continue;
        final date = DateTime.tryParse(d.toString());
        if (date == null) continue;
        final steps = (m['steps'] as num?)?.round() ?? 0;
        final cal = (m['calories_burned'] as num?)?.round() ??
            (m['caloriesburned'] as num?)?.round() ??
            0;
        out.add(
          HealthTrendPoint(
            date: DateTime(date.year, date.month, date.day),
            steps: steps,
            caloriesBurned: cal,
          ),
        );
      }
      return out;
    } catch (e, st) {
      debugPrint('HealthInsightsRemoteService.fetchStepsTrend: $e\n$st');
      return [];
    }
  }

  /// Full daily metrics for the current user over [days].
  Future<List<HealthMetricRemoteRow>> fetchMetrics({
    int days = 14,
    String? category,
  }) async {
    if (_client.auth.currentSession == null) return [];
    try {
      final response = await _client.rpc(
        'get_health_metrics',
        params: {
          'p_days': days,
          'p_category': category,
        },
      );
      return _parseMetricRows(response);
    } catch (e, st) {
      debugPrint('HealthInsightsRemoteService.fetchMetrics: $e\n$st');
      return [];
    }
  }

  /// Metrics for a single calendar [day] (local date, UTC noon-safe).
  Future<List<HealthMetricRemoteRow>> fetchMetricsForDay({
    DateTime? day,
    String? category,
  }) async {
    if (_client.auth.currentSession == null) return [];
    final d = day ?? DateTime.now();
    final dayStr =
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    try {
      final response = await _client.rpc(
        'get_health_metrics_for_day',
        params: {
          'p_day': dayStr,
          'p_category': category,
        },
      );
      return _parseMetricRows(response);
    } catch (e, st) {
      debugPrint('HealthInsightsRemoteService.fetchMetricsForDay: $e\n$st');
      return [];
    }
  }

  List<HealthMetricRemoteRow> _parseMetricRows(dynamic response) {
    if (response == null) return [];
    final list = response is List
        ? response
        : (response as List<dynamic>?) ?? <dynamic>[];
    final out = <HealthMetricRemoteRow>[];
    for (final row in list) {
      if (row is! Map) continue;
      out.add(HealthMetricRemoteRow.fromMap(Map<String, dynamic>.from(row)));
    }
    return out;
  }
}
