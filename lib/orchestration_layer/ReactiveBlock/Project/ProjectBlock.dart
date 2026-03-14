import 'dart:async';
import 'package:drift/drift.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:provider/provider.dart';
import 'package:flutter/widgets.dart'; // For BuildContext

import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/ProjectPoint.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

class ProjectBlock {
  final projects = signal<List<ProjectProtocol>>([]);
  final selectedProject = signal<ProjectProtocol?>(null);

  StreamSubscription? _projectsSubscription;
  late ProjectsDAO _dao;
  late String _personId;

  void init(ProjectsDAO dao, String personId) {
    if (personId.isEmpty) {
      debugPrint("ProjectBlock: Skipping init, personId is empty.");
      return;
    }
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
                    projectID: e.projectID ?? "",
                    personID: e.personID ?? "",
                    name: e.name,
                    description: e.description,
                    color: e.color,
                    sshHostId: e.sshHostId,
                    remotePath: e.remotePath,
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

  Future<String> createProject(
    String name,
    String? description,
    String? color,
  ) async {
    if (_personId.isEmpty) return "";
    final uuid = IDGen.UUIDV7();
    await _dao.insertProject(
      ProjectsTableCompanion.insert(
        id: uuid, // Use the same UUID
        projectID: Value(uuid), // Consistently set projectID
        personID: Value(_personId),
        name: name,
        description: Value(description),
        color: Value(color),
        createdAt: Value(DateTime.now().toUtc()),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
    return uuid;
  }

  Future<void> deleteProject(String id) async {
    await _dao.deleteProjectByProjectId(id);
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
        sshHostId: project.sshHostId,
        remotePath: project.remotePath,
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

  Future<void> updateProjectRemoteSettings(
    String id,
    String? sshHostId,
    String? remotePath,
  ) async {
    await _dao.updateProjectManual(
      id,
      ProjectsTableCompanion(
        sshHostId: Value(sshHostId),
        remotePath: Value(remotePath),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void dispose() {
    _projectsSubscription?.cancel();
  }
}
