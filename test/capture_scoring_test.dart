import 'package:flutter_test/flutter_test.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Screenshot/ScreenshotMemoryProtocol.dart';
import 'package:ice_gate/orchestration_layer/Services/AutoCaptureJob.dart';

/// Scoring and extraction-parsing tests. Pure logic, no platform channels.
///
/// Session state matters here: `score()` awards a first-visit bonus only for
/// routes absent from the job's session-seen set, and that set is populated by
/// `onRouteChanged()` — not by `score()` itself. A test that neither declares a
/// route as visited nor accounts for the bonus is off by firstVisitWeight
/// (0.1 by default). Both cases are covered explicitly below.
void main() {
  group('Capture scoring', () {
    final job = AutoCaptureJob.instance;

    /// stop() is async and clears the session-seen sets, so it must be awaited
    /// before scoring or a prior test's routes leak into the next one.
    Future<void> freshSession() => job.stop();

    setUp(freshSession);

    test('low signal activity does not reach the threshold', () async {
      await freshSession();
      // Unseen, low-value, no dwell: only the first-visit bonus applies.
      final score = job.score(const BehaviourSignal(route: '/settings'));
      expect(score.score, lessThan(0.6));
    });

    test('high-value route with dwell clears the threshold', () async {
      await freshSession();
      final score = job.score(
        const BehaviourSignal(route: '/health', dwellSeconds: 60),
      );
      // 0.4 dwell (60s saturates) + 0.3 high-value + 0.1 first visit.
      expect(score.score, closeTo(0.8, 0.001));
      expect(score.reasons, contains('high_value_route'));
      expect(score.reasons, contains('dwell:60s'));
      expect(score.reasons, contains('first_visit'));
    });

    test('first-visit bonus is not awarded to a route already seen', () async {
      await freshSession();
      // Declare the route visited, as MainShell would on a real navigation.
      job.onRouteChanged('/health');
      job.onRouteChanged('/health');

      final score = job.score(
        const BehaviourSignal(route: '/health', dwellSeconds: 60),
      );
      // 0.4 dwell + 0.3 high-value, no first-visit bonus.
      expect(score.score, closeTo(0.7, 0.001));
      expect(score.reasons, isNot(contains('first_visit')));
    });

    test('dwell weight saturates rather than growing without bound', () async {
      await freshSession();
      // Mark seen so the first-visit bonus does not vary between the two
      // scores below.
      job.onRouteChanged('/unknown');

      final short = job.score(
        const BehaviourSignal(route: '/unknown', dwellSeconds: 10),
      );
      final long = job.score(
        const BehaviourSignal(route: '/unknown', dwellSeconds: 600),
      );

      // 10s is 1/6 of the saturation window; 600s clamps to full weight.
      expect(short.score, closeTo(0.4 * (10 / 60), 0.001));
      expect(long.score, closeTo(0.4, 0.001));
      expect(long.score, greaterThan(short.score));
    });

    test('data entry contributes even on a low-value route', () async {
      await freshSession();
      final score = job.score(
        const BehaviourSignal(
          route: '/health/food-input',
          hasDataEntry: true,
        ),
      );
      expect(score.reasons, contains('data_entry'));
    });

    test('repeat visits only count past the third visit', () async {
      await freshSession();
      for (var i = 0; i < 3; i++) {
        job.onRouteChanged('/finance');
      }
      final underThreshold = job.score(
        const BehaviourSignal(route: '/finance'),
      );
      expect(underThreshold.reasons, isNot(contains('repeat_visit:3')));

      job.onRouteChanged('/finance');
      final overThreshold = job.score(
        const BehaviourSignal(route: '/finance'),
      );
      expect(overThreshold.reasons, contains('repeat_visit:4'));
    });

    test('zero dwell records no dwell reason', () async {
      await freshSession();
      final score = job.score(const BehaviourSignal(route: '/health'));
      expect(score.reasons, isNot(contains('dwell:0s')));
    });

    test('records why a capture happened', () async {
      await freshSession();
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
