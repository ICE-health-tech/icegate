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
}
