/// Readiness to complete a scheduled calendar block from local context (no cloud).
enum CalendarEnvironmentLevel { ready, caution, notReady }

class CalendarEnvironmentFactor {
  const CalendarEnvironmentFactor({
    required this.id,
    required this.impact,
  });

  final String id;
  final int impact;
}

class CalendarEnvironmentAssessment {
  const CalendarEnvironmentAssessment({
    required this.score,
    required this.level,
    required this.factors,
    required this.durationMinutes,
  });

  final int score;
  final CalendarEnvironmentLevel level;
  final List<CalendarEnvironmentFactor> factors;
  final int durationMinutes;
}

abstract final class CalendarEventEnvironment {
  CalendarEventEnvironment._();

  static CalendarEnvironmentAssessment assess({
    required DateTime start,
    DateTime? end,
    required bool allDay,
    DateTime? now,
    int? moodScore,
    int focusMinutesToday = 0,
    int overlappingEvents = 0,
    double? sleepHoursLastNight,
  }) {
    if (allDay) {
      return const CalendarEnvironmentAssessment(
        score: 100,
        level: CalendarEnvironmentLevel.ready,
        factors: [],
        durationMinutes: 0,
      );
    }

    final clock = now ?? DateTime.now();
    final eventEnd = end ?? start.add(const Duration(hours: 1));
    final durationMinutes =
        eventEnd.difference(start).inMinutes.clamp(1, 480);
    final factors = <CalendarEnvironmentFactor>[];
    var score = 100;

    if (eventEnd.isBefore(clock)) {
      factors.add(const CalendarEnvironmentFactor(id: 'past', impact: -40));
      score -= 40;
    } else if (start.isAfter(clock.add(const Duration(hours: 2)))) {
      factors.add(const CalendarEnvironmentFactor(id: 'too_early', impact: -12));
      score -= 12;
    } else if (start.isAfter(clock) &&
        start.difference(clock) <= const Duration(minutes: 15)) {
      factors.add(const CalendarEnvironmentFactor(id: 'starting_soon', impact: 8));
      score += 8;
    }

    if (moodScore != null) {
      if (moodScore <= 2) {
        factors.add(const CalendarEnvironmentFactor(id: 'low_mood', impact: -22));
        score -= 22;
      } else if (moodScore == 3) {
        factors.add(const CalendarEnvironmentFactor(id: 'neutral_mood', impact: -8));
        score -= 8;
      } else if (moodScore >= 4) {
        factors.add(const CalendarEnvironmentFactor(id: 'good_mood', impact: 6));
        score += 6;
      }
    } else {
      factors.add(const CalendarEnvironmentFactor(id: 'no_mood', impact: -10));
      score -= 10;
    }

    if (overlappingEvents >= 2) {
      factors.add(
        const CalendarEnvironmentFactor(id: 'heavy_overlap', impact: -25),
      );
      score -= 25;
    } else if (overlappingEvents == 1) {
      factors.add(
        const CalendarEnvironmentFactor(id: 'some_overlap', impact: -12),
      );
      score -= 12;
    }

    if (focusMinutesToday >= 120 && durationMinutes >= 30) {
      factors.add(
        const CalendarEnvironmentFactor(id: 'focus_fatigue', impact: -15),
      );
      score -= 15;
    }

    if (sleepHoursLastNight != null && sleepHoursLastNight > 0) {
      if (sleepHoursLastNight < 5) {
        factors.add(
          const CalendarEnvironmentFactor(id: 'low_sleep', impact: -18),
        );
        score -= 18;
      } else if (sleepHoursLastNight >= 7) {
        factors.add(
          const CalendarEnvironmentFactor(id: 'good_sleep', impact: 5),
        );
        score += 5;
      }
    }

    score = score.clamp(0, 100);
    final level = score >= 70
        ? CalendarEnvironmentLevel.ready
        : score >= 45
            ? CalendarEnvironmentLevel.caution
            : CalendarEnvironmentLevel.notReady;

    return CalendarEnvironmentAssessment(
      score: score,
      level: level,
      factors: factors,
      durationMinutes: durationMinutes,
    );
  }
}
