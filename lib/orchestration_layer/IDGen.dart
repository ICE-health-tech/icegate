import 'dart:math';
import 'package:uuid/uuid.dart';

class IDGen {
  static const _uuid = Uuid();

  static String generateUuid() => _uuid.v4();
  // Static random instance to avoid creating a new one every call
  static final Random _rng = Random.secure();

  // Static set to track IDs globally across the app
  static final Set<int> _usedIds = {};

  // 8-digit range
  static const int _min = 10000000;
  static const int _max = 99999999;

  /// Static method to generate a unique 8-digit integer
  static int generate() {
    // Safety valve: prevent infinite loops if we somehow run out of numbers
    if (_usedIds.length >= (_max - _min)) {
      throw Exception('ID Capacity Reached');
    }

    int id;
    do {
      // Generate 10,000,000 to 99,999,999
      id = _min + _rng.nextInt(_max - _min);
    } while (_usedIds.contains(id)); // Check against static history

    _usedIds.add(id);
    return id;
  }

  /// Optional: Check if an ID exists
  static bool exists(int id) => _usedIds.contains(id);

  /// Optional: Clear history
  static void reset() => _usedIds.clear();
}
