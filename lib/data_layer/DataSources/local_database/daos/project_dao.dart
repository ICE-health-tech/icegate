part of '../Database.dart';

@DriftAccessor(tables: [ProjectsTable])
class ProjectDAO extends DatabaseAccessor<AppDatabase> with _$ProjectDAOMixin {
  ProjectDAO(super.db);

  Future<int> insertProject(ProjectsTableCompanion entry) {
    return into(projectsTable).insert(entry);
  }

  Future<bool> updateProject(ProjectData entry) {
    return update(projectsTable).replace(entry);
  }

  Future<int> deleteProject(String id) {
    return (delete(projectsTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ProjectData>> watchAllProjects(String personId) {
    return (select(projectsTable)..where((t) => t.personID.equals(personId)))
        .watch();
  }

  Future<ProjectData?> getProjectById(String id) {
    return (select(projectsTable)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }
}
