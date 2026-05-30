class GoalProtocol {
  final String id;
  final String goalID;
  final String personID;
  final String? projectID;
  final String title;
  final String? description;
  final String category;
  final int priority;
  final String status;
  final DateTime? targetDate;
  final DateTime? completionDate;
  final int progressPercentage;

  GoalProtocol({
    required this.id,
    required this.goalID,
    required this.personID,
    this.projectID,
    required this.title,
    this.description,
    this.category = 'personal',
    this.priority = 3,
    this.status = 'active',
    this.targetDate,
    this.completionDate,
    this.progressPercentage = 0,
  });
}

class HabitProtocol {
  final String id;
  final String habitID;
  final String personID;
  final String? goalID;
  final String habitName;
  final String? description;
  final String frequency;
  final String? frequencyDetails;
  final int targetCount;
  final bool isActive;
  final DateTime startedDate;

  HabitProtocol({
    required this.id,
    required this.habitID,
    required this.personID,
    this.goalID,
    required this.habitName,
    this.description,
    required this.frequency,
    this.frequencyDetails,
    this.targetCount = 1,
    this.isActive = true,
    required this.startedDate,
  });
}

class SkillProtocol {
  final String id;
  final String skillID;
  final String personID;
  final String skillName;
  final String? skillCategory;
  final String proficiencyLevel;
  /// Total practice XP (stored in `skills.years_of_experience` for project skills).
  final int practicePoints;
  final String? description;
  final bool isFeatured;

  SkillProtocol({
    required this.id,
    required this.skillID,
    required this.personID,
    required this.skillName,
    this.skillCategory,
    this.proficiencyLevel = 'beginner',
    int practicePoints = 0,
    @Deprecated('Use practicePoints') int? yearsOfExperience,
    this.description,
    this.isFeatured = false,
  }) : practicePoints = yearsOfExperience ?? practicePoints;

  /// `skill_category` = `project:<projectId>`
  String? get linkedProjectId {
    final cat = skillCategory;
    if (cat == null || !cat.startsWith('project:')) return null;
    return cat.substring('project:'.length);
  }

  int get levelIndex {
    switch (proficiencyLevel) {
      case 'intermediate':
        return 2;
      case 'advanced':
        return 3;
      case 'expert':
        return 4;
      default:
        return 1;
    }
  }

  int get xpIntoCurrentLevel {
    final xp = practicePoints;
    if (xp >= 500) return xp - 500;
    if (xp >= 250) return xp - 250;
    if (xp >= 100) return xp - 100;
    return xp;
  }

  int get xpToNextLevel {
    final xp = practicePoints;
    if (xp < 100) return 100 - xp;
    if (xp < 250) return 250 - xp;
    if (xp < 500) return 500 - xp;
    return 100;
  }

  double get levelProgress {
    final need = xpToNextLevel + xpIntoCurrentLevel;
    if (need <= 0) return 1;
    return (xpIntoCurrentLevel / need).clamp(0.0, 1.0);
  }

  /// Shared XP math when displaying a unified total across project rows.
  static int practiceXpToNextLevel(int xp) {
    if (xp < 100) return 100 - xp;
    if (xp < 250) return 250 - xp;
    if (xp < 500) return 500 - xp;
    return 100;
  }

  static double practiceLevelProgress(int xp) {
    int intoCurrent() {
      if (xp >= 500) return xp - 500;
      if (xp >= 250) return xp - 250;
      if (xp >= 100) return xp - 100;
      return xp;
    }

    final into = intoCurrent();
    final need = practiceXpToNextLevel(xp) + into;
    if (need <= 0) return 1;
    return (into / need).clamp(0.0, 1.0);
  }
}
