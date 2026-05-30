import 'dart:async';
import 'package:drift/drift.dart';
import 'package:signals/signals.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Project/ProjectProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/GrowthProtocols.dart';
import 'package:flutter/widgets.dart'; // For BuildContext

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
    // Upload local sub-project links (parent_project_id) so other devices get hierarchy.
    Future.microtask(() => dao.pushAllProjectsForPerson(personId));

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
                    aiModel: e.aiModel,
                    parentProjectId: e.parentProjectId,
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

  /// Canonical link id for tasks, notes, and finance on this project.
  static String linkId(ProjectProtocol project) =>
      project.projectID.isNotEmpty ? project.projectID : project.id;

  Future<String> createProject(
    String name,
    String? description,
    String? color, {
    String? parentProjectId,
  }) async {
    if (_personId.isEmpty) return "";
    final uuid = IDGen.UUIDV7();
    await _dao.insertProject(
      ProjectsTableCompanion.insert(
        id: uuid,
        projectID: Value(uuid),
        parentProjectId: Value(parentProjectId),
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

  List<ProjectProtocol> childrenOf(String parentId) =>
      projects.value.childrenOf(parentId);

  List<ProjectProtocol> get rootProjects => projects.value.rootsOnly;

  /// Project id + projectID values used for goals, notes, and finance links.
  Set<String> scopeIdsFor(ProjectProtocol project) {
    final ids = <String>{project.id, project.projectID}
      ..removeWhere((id) => id.isEmpty);
    for (final child in childrenOf(project.id)) {
      ids.add(child.id);
      if (child.projectID.isNotEmpty) ids.add(child.projectID);
    }
    return ids;
  }

  bool goalBelongsToScope(GoalProtocol goal, ProjectProtocol project) {
    final pid = goal.projectID;
    if (pid == null || pid.isEmpty) return false;
    return scopeIdsFor(project).contains(pid);
  }

  /// Sub-project name when [goal] belongs to a child of [project]; null if own task.
  String? subProjectLabelForGoal(GoalProtocol goal, ProjectProtocol project) {
    final pid = goal.projectID;
    if (pid == null || pid.isEmpty) return null;
    if (pid == project.id || pid == project.projectID) return null;
    for (final child in childrenOf(project.id)) {
      if (pid == child.id || pid == child.projectID) return child.name;
    }
    return null;
  }

  List<GoalProtocol> goalsInScope(
    List<GoalProtocol> allGoals,
    ProjectProtocol project,
  ) =>
      allGoals.where((g) => goalBelongsToScope(g, project)).toList();

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
    await _dao.updateProject(
      ProjectData(
        id: project.id,
        projectID: project.projectID,
        parentProjectId: project.parentProjectId,
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

  Future<void> updateProjectAiModel(
    String id,
    String? aiModel,
  ) async {
    await _dao.updateProjectManual(
      id,
      ProjectsTableCompanion(
        aiModel: Value(aiModel),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  void dispose() {
    _projectsSubscription?.cancel();
  }
}
