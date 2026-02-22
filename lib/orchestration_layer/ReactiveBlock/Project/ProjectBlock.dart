import 'dart:async';
import 'package:drift/drift.dart';
import 'package:signals/signals.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart'; // For BuildContext

import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/ProjectPoint.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';

class ProjectBlock {
  final projects = signal<List<ProjectProtocol>>([]);
  final selectedProject = signal<ProjectProtocol?>(null);

  StreamSubscription? _projectsSubscription;
  late ProjectsDAO _dao;
  late int _personId;

  void init(ProjectsDAO dao, int personId) {
    _dao = dao;
    _personId = personId;

    _projectsSubscription?.cancel();
    _projectsSubscription = dao
        .watchAllProjects(personId)
        .listen(
          (data) {
            debugPrint(
              "ProjectBlock: Watch projects updated with ${data.length} items",
            );
            projects.value = data
                .map(
                  (e) => ProjectProtocol(
                    id: e.id,
                    projectID: e.projectID,
                    personID: e.personID,
                    name: e.name,
                    description: e.description,
                    color: e.color,
                    createdAt: e.createdAt,
                    updatedAt: e.updatedAt,
                    status: e.status,
                  ),
                )
                .toList();
          },
          onError: (e, stackTrace) {
            debugPrint("ProjectBlock: Error watching projects: $e");
            debugPrint("ProjectBlock Stack: $stackTrace");
          },
        );
  }

  Future<int> createProject(
    String name,
    String? description,
    String? color,
  ) async {
    return await _dao.insertProject(
      ProjectsTableCompanion.insert(
        id: IDGen.generateUuid(),
        personID: _personId,
        name: name,
        description: Value(description),
        color: Value(color),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteProject(String id) async {
    await _dao.deleteProjectByUuid(id);
  }

  void selectProject(ProjectProtocol? project) {
    selectedProject.value = project;
  }

  Future<void> completeProject(
    BuildContext context,
    ProjectProtocol project,
  ) async {
    final scoreBlock = context.read<ScoreBlock>();
    await _dao.updateProject(
      ProjectData(
        id: project.id,
        projectID: project.projectID,
        personID: project.personID,
        name: project.name,
        description: project.description,
        color: project.color,
        createdAt: project.createdAt,
        updatedAt: DateTime.now(),
        status: 1, // 1 for completed
      ),
    );

    // Calculate dynamic bonus based on project effort
    final daysActive = DateTime.now().difference(project.createdAt).inDays;
    final bonus = ProjectPoint.calculateProjectBonus(0, 0, daysActive);

    // Award points
    await scoreBlock.persistentCareerIncrement(bonus);
  }

  void dispose() {
    _projectsSubscription?.cancel();
  }
}
