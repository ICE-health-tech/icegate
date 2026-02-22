class GoalProtocol {
  final String id;
  final int goalID;
  final int personID;
  final int? projectID;
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
  final int habitID;
  final int personID;
  final int? goalID;
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
  final int skillID;
  final int personID;
  final String skillName;
  final String? skillCategory;
  final String proficiencyLevel;
  final int yearsOfExperience;
  final String? description;
  final bool isFeatured;

  SkillProtocol({
    required this.id,
    required this.skillID,
    required this.personID,
    required this.skillName,
    this.skillCategory,
    this.proficiencyLevel = 'beginner',
    this.yearsOfExperience = 0,
    this.description,
    this.isFeatured = false,
  });
}
