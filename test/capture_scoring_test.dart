import 'package:flutter_test/flutter_test.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Screenshot/ScreenshotMemoryProtocol.dart';
import 'package:ice_gate/orchestration_layer/Services/AutoCaptureJob.dart';

/// Scoring and extraction-parsing tests. Pure logic, no platform channels.
void main() {
  group('Capture scoring', () {
    AutoCaptureJob job = AutoCaptureJob.instance;

    setUp(() {
      // Fresh session state per test.
      job.stop();
    });

    test('low signal activity does not reach the threshold', () {
      final score = job.score(const BehaviourSignal(route: '/settings'));
      expect(score.score, lessThan(0.6));
    });

    test('high-value route with dwell clears the threshold', () {
      final score = job.score(
        const BehaviourSignal(route: '/health', dwellSeconds: 60),
      );
      // 0.4 dwell + 0.3 high-value
      expect(score.score, closeTo(0.7, 0.001));
      expect(score.reasons, contains('high_value_route'));
      expect(score.reasons, contains('dwell:60s'));
    });

    test('dwell weight saturates rather than growing without bound', () {
      final short = job.score(
        const BehaviourSignal(route: '/unknown', dwellSeconds: 10),
      );
      final long = job.score(
        const BehaviourSignal(route: '/unknown', dwellSeconds: 600),
      );
      expect(long.score, lessThanOrEqualTo(0.4));
      expect(long.score, greaterThan(short.score));
    });

    test('data entry contributes even on a low-value route', () {
      final score = job.score(
        const BehaviourSignal(
          route: '/health/food-input',
          hasDataEntry: true,
        ),
      );
      expect(score.reasons, contains('data_entry'));
    });

    test('records why a capture happened', () {
      final score = job.score(
        const BehaviourSignal(
          route: '/finance',
          dwellSeconds: 45,
          hasDataEntry: true,
        ),
      );
      expect(score.reasons, isNotEmpty);
      expect(score.reasons.every((r) => r.isNotEmpty), isTrue);
    });
  });

  group('ScreenshotMemoryProtocol parsing', () {
    test('parses the standard envelope', () {
      final memory = ScreenshotMemoryProtocol.fromJsonString('''
      {"output": {"title": "HR trend", "summary": "s", "memory": "m",
       "tags": ["health"], "memory_weight": 0.8}}
      ''');
      expect(memory.title, 'HR trend');
      expect(memory.memory, 'm');
      expect(memory.tags, ['health']);
      expect(memory.memoryWeight, 0.8);
    });

    test('parses a bare object without the envelope', () {
      final memory = ScreenshotMemoryProtocol.fromJsonString(
        '{"title": "t", "memory": "m"}',
      );
      expect(memory.title, 't');
      expect(memory.memoryWeight, 1.0);
    });

    test('accepts tags as a comma-separated string', () {
      final memory = ScreenshotMemoryProtocol.fromJsonString(
        '{"output": {"tags": "health, finance"}}',
      );
      expect(memory.tags, ['health', 'finance']);
    });

    test('clamps an out-of-range weight so ordering cannot be poisoned', () {
      expect(
        ScreenshotMemoryProtocol.fromJsonString(
          '{"output": {"memory_weight": 99}}',
        ).memoryWeight,
        1.0,
      );
      expect(
        ScreenshotMemoryProtocol.fromJsonString(
          '{"output": {"memory_weight": -5}}',
        ).memoryWeight,
        0.0,
      );
    });

    test('malformed input yields an empty memory, not a throw', () {
      final memory = ScreenshotMemoryProtocol.fromJsonString('not json {{{');
      expect(memory.memory, '');
      expect(memory.tags, isEmpty);
    });

    test('falls back to content when memory is absent', () {
      final memory = ScreenshotMemoryProtocol.fromJsonString(
        '{"output": {"content": "from content"}}',
      );
      expect(memory.memory, 'from content');
    });
  });

  group('Scoring config', () {
    test('falls back to defaults when no config exists', () {
      expect(
        CaptureScoringConfig.fromConfig(null).threshold,
        CaptureScoringConfig.defaults.threshold,
      );
    });

    test('parses a comma-separated override list', () {
      final config = ConfigData(
        id: 'c1',
        personID: 'p1',
        configKey: 'auto_capture_threshold',
        configValue: 'threshold=0.9, dwell=0.5',
        updatedAt: DateTime(2026),
      );
      final parsed = CaptureScoringConfig.fromConfig(config);
      expect(parsed.threshold, 0.9);
      expect(parsed.dwellWeight, 0.5);
    });

    test('ignores unparseable override values', () {
      final config = ConfigData(
        id: 'c1',
        personID: 'p1',
        configKey: 'auto_capture_threshold',
        configValue: 'threshold=not-a-number',
        updatedAt: DateTime(2026),
      );
      expect(
        CaptureScoringConfig.fromConfig(config).threshold,
        CaptureScoringConfig.defaults.threshold,
      );
    });
  });
}
