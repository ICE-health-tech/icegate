/// Normalizes values for PostgREST upserts. Timestamptz columns expect ISO-8601;
/// Drift [Map]/JSON sometimes carries epoch **milliseconds** as [int] or digit [String].
library;

bool _isTimestamptzColumnKey(String key) {
  const explicit = <String>{
    'created_at',
    'updated_at',
    'deleted_at',
    'synced_at',
    'timestamp',
    'start_time',
    'end_time',
    'eaten_at',
  };
  if (explicit.contains(key)) return true;
  return key.endsWith('_at');
}

bool _isEpochMilliseconds(num n) {
  // ~ Sep 2001 .. year 2600 in ms
  return n >= 1e12 && n < 2e13;
}

/// Encodes a cell for Supabase upsert. Keeps [oxygen_saturation_logs.timestamp] as ms when needed.
dynamic encodeForSupabaseUpsert({
  required String table,
  required String key,
  required dynamic value,
}) {
  if (value == null) return null;

  if (table == 'oxygen_saturation_logs' && key == 'timestamp') {
    if (value is String && value.contains('T') && value.endsWith('Z')) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed.millisecondsSinceEpoch;
    }
    if (value is DateTime) return value.millisecondsSinceEpoch;
    if (value is int || value is num) return value;
    return value;
  }

  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }

  if (_isTimestamptzColumnKey(key)) {
    if (value is int && _isEpochMilliseconds(value)) {
      return DateTime.fromMillisecondsSinceEpoch(value, isUtc: true)
          .toUtc()
          .toIso8601String();
    }
    if (value is num && _isEpochMilliseconds(value.toDouble())) {
      return DateTime.fromMillisecondsSinceEpoch(
        value.round(),
        isUtc: true,
      ).toUtc().toIso8601String();
    }
    if (value is String) {
      final s = value.trim();
      if (RegExp(r'^\d{13,}$').hasMatch(s)) {
        final ms = int.parse(s);
        if (_isEpochMilliseconds(ms)) {
          return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true)
              .toUtc()
              .toIso8601String();
        }
      }
    }
  }

  return value;
}
