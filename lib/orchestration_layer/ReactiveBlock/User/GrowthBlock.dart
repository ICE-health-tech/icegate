import 'dart:async';
import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/ProjectPoint.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class GrowthBlock {
  final goals = signal<List<GoalProtocol>>([]);
  final habits = signal<List<HabitProtocol>>([]);
  final skills = signal<List<SkillProtocol>>([]);

  StreamSubscription? _goalsSubscription;
  StreamSubscription? _habitsSubscription;
  StreamSubscription? _skillsSubscription;

  late GrowthDAO _dao;
  late String _personId;

  void updateGoals(List<GoalProtocol> data) => goals.value = data;
  void updateHabits(List<HabitProtocol> data) => habits.value = data;
  void updateSkills(List<SkillProtocol> data) => skills.value = data;

  void init(GrowthDAO dao, String personId) {
    if (personId.isEmpty) {
      debugPrint("GrowthBlock: Skipping init, personId is empty.");
      return;
    }
    _dao = dao;
    _personId = personId;

    _goalsSubscription?.cancel();
    _goalsSubscription = dao.watchGoals(personId).listen((data) {
      untracked(() {
        updateGoals(
          data
              .map(
                (e) => GoalProtocol(
                  id: e.id,
                  goalID: e.goalID ?? "",
                  personID: e.personID ?? "",
                  title: e.title,
                  description: e.description,
                  category: e.category,
                  priority: e.priority,
                  status: e.status,
                  targetDate: e.targetDate,
                  completionDate: e.completionDate,
                  progressPercentage: e.progressPercentage,
                  projectID: e.projectID,
                ),
              )
              .toList(),
        );
      });
    });

    _habitsSubscription?.cancel();
    _habitsSubscription = dao.watchHabits(personId).listen((data) {
      untracked(() {
        updateHabits(
          data
              .map(
                (e) => HabitProtocol(
                  id: e.id,
                  habitID: e.habitID ?? "",
                  personID: e.personID ?? "",
                  goalID: e.goalID,
                  habitName: e.habitName,
                  description: e.description,
                  frequency: e.frequency,
                  frequencyDetails: e.frequencyDetails,
                  targetCount: e.targetCount,
                  isActive: e.isActive,
                  startedDate: e.startedDate,
                ),
              )
              .toList(),
        );
      });
    });

    _skillsSubscription?.cancel();
    _skillsSubscription = dao.watchSkills(personId).listen((data) {
      untracked(() {
        updateSkills(
          data
              .map(
                (e) => SkillProtocol(
                  id: e.id,
                  skillID: e.skillID ?? "",
                  personID: e.personID ?? "",
                  skillName: e.skillName,
                  skillCategory: e.skillCategory,
                  proficiencyLevel: e.proficiencyLevel.name,
                  yearsOfExperience: e.yearsOfExperience,
                  description: e.description,
                  isFeatured: e.isFeatured,
                ),
              )
              .toList(),
        );
      });
    });
  }

  Future<void> completeGoal(String id, {ScoreBlock? scoreBlock}) async {
    await _dao.updateGoalStatusByUuid(id, 'done');
    await _awardPoints(scoreBlock);
  }

  Future<void> completeGoalByGoalId(
    String goalID, {
    ScoreBlock? scoreBlock,
  }) async {
    await _dao.updateGoalStatusByUuid(goalID, 'done');
    await _awardPoints(scoreBlock);
  }

  Future<void> _awardPoints(ScoreBlock? scoreBlock) async {
    // Award points for task completion
    if (scoreBlock != null) {
      final completedCount = goals.value
          .where((g) => g.status == 'done')
          .length;
      final totalCount = goals.value.length;
      final bonus = ProjectPoint.calculateTaskBonus(completedCount, totalCount);
      await scoreBlock.persistentCareerIncrement(bonus);
    }
  }

  Future<void> createNewTask(
    String title,
    String description, {
    String? projectID,
  }) async {
    if (_personId.isEmpty) return;
    await _dao.createGoal(
      GoalsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: Value(_personId),
        title: title,
        projectID: Value(projectID),
        description: Value(description),
        status: const Value('active'),
        category: const Value('project'),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  void dispose() {
    _goalsSubscription?.cancel();
    _habitsSubscription?.cancel();
    _skillsSubscription?.cancel();
  }
}
