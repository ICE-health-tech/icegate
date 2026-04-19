part of '../Database.dart';

@DriftAccessor(tables: [SkillsTable])
class SkillDAO extends DatabaseAccessor<AppDatabase> with _$SkillDAOMixin {
  SkillDAO(super.db);

  Future<int> insertSkill(SkillsTableCompanion entry) =>
      into(skillsTable).insert(entry);

  Future<bool> updateSkill(SkillData entry) => update(skillsTable).replace(entry);

  Future<int> deleteSkill(String id) =>
      (delete(skillsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<SkillData>> watchSkillsByPerson(String personId) =>
      (select(skillsTable)..where((t) => t.personID.equals(personId))).watch();
}

@DriftAccessor(tables: [AiAnalysisTable])
class AiAnalysisDAO extends DatabaseAccessor<AppDatabase>
    with _$AiAnalysisDAOMixin {
  AiAnalysisDAO(super.db);

  Future<int> insertAnalysis(AiAnalysisTableCompanion entry) =>
      into(aiAnalysisTable).insert(entry);

  Future<bool> updateAnalysis(AiAnalysisData entry) =>
      update(aiAnalysisTable).replace(entry);

  Future<int> deleteAnalysis(String id) =>
      (delete(aiAnalysisTable)..where((t) => t.id.equals(id))).go();

  Stream<List<AiAnalysisData>> watchAllAnalysis(String personId) =>
      (select(aiAnalysisTable)..where((t) => t.personID.equals(personId))).watch();
}

@DriftAccessor(tables: [PersonWidgetsTable])
class PersonWidgetDAO extends DatabaseAccessor<AppDatabase>
    with _$PersonWidgetDAOMixin {
  PersonWidgetDAO(super.db);

  Future<int> insertWidget(PersonWidgetsTableCompanion entry) =>
      into(personWidgetsTable).insert(entry);

  Future<bool> updateWidget(PersonWidgetData entry) =>
      update(personWidgetsTable).replace(entry);

  Future<int> deleteWidget(String id) =>
      (delete(personWidgetsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<PersonWidgetData>> watchAllWidgets(String personId) =>
      (select(personWidgetsTable)..where((t) => t.personID.equals(personId)))
          .watch();
}

@DriftAccessor(tables: [SessionTable])
class SessionDAO extends DatabaseAccessor<AppDatabase> with _$SessionDAOMixin {
  SessionDAO(super.db);

  Future<int> insertSession(SessionTableCompanion entry) =>
      into(sessionTable).insert(entry);

  Future<int> deleteSession(String id) =>
      (delete(sessionTable)..where((t) => t.id.equals(id))).go();

  Future<SessionData?> getLatestSession() =>
      (select(sessionTable)..orderBy([(t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc)]))
          .getSingleOrNull();
}

@DriftAccessor(tables: [CustomNotificationsTable])
class CustomNotificationDAO extends DatabaseAccessor<AppDatabase>
    with _$CustomNotificationDAOMixin {
  CustomNotificationDAO(super.db);

  Future<int> insertNotification(CustomNotificationsTableCompanion entry) {
    return into(customNotificationsTable).insert(entry);
  }

  Future<bool> updateNotification(CustomNotificationData entry) {
    return update(customNotificationsTable).replace(entry);
  }

  Future<int> deleteNotification(String id) {
    return (delete(
      customNotificationsTable,
    )..where((t) => t.id.equals(id))).go();
  }

  Stream<List<CustomNotificationData>> watchAllNotifications(String personId) {
    return (select(customNotificationsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.scheduledTime,
              mode: OrderingMode.asc,
            ),
          ]))
        .watch();
  }

  Future<List<CustomNotificationData>> getAllEnabledNotifications(
    String personId,
  ) {
    return (select(
          customNotificationsTable,
        )..where((t) => t.isEnabled.equals(true) & t.personID.equals(personId)))
        .get();
  }
}

@DriftAccessor(tables: [FeedbacksTable])
class FeedbackDAO extends DatabaseAccessor<AppDatabase>
    with _$FeedbackDAOMixin {
  FeedbackDAO(super.db);

  Future<int> insertFeedback(FeedbackLocalData feedback) {
    return into(feedbacksTable).insert(feedback);
  }

  Future<void> markAsSynced(String id) {
    return (update(feedbacksTable)..where((t) => t.id.equals(id))).write(
      const FeedbacksTableCompanion(status: Value('synced')),
    );
  }

  Stream<List<FeedbackLocalData>> watchAllFeedbacks() {
    return select(feedbacksTable).watch();
  }
}
