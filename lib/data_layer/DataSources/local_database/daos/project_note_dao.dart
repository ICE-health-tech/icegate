part of '../Database.dart';

@DriftAccessor(tables: [ProjectNotesTable])
class ProjectNoteDAO extends DatabaseAccessor<AppDatabase>
    with _$ProjectNoteDAOMixin {
  ProjectNoteDAO(super.db);

  Future<int> insertNote(ProjectNotesTableCompanion entry) {
    return into(projectNotesTable).insert(entry);
  }

  Future<bool> updateNote(ProjectNoteData entry) {
    return update(projectNotesTable).replace(entry);
  }

  Future<int> deleteNote(String id) {
    return (delete(projectNotesTable)..where((t) => t.id.equals(id))).go();
  }

  Stream<List<ProjectNoteData>> watchAllNotes(String personId) {
    return (select(projectNotesTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<ProjectNoteData>> watchNotesByProject(String projectId) {
    return (select(projectNotesTable)
          ..where((t) => t.projectID.equals(projectId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }
}
