part of '../Database.dart';

@DriftAccessor(tables: [ThemesTable])
class ThemeDAO extends DatabaseAccessor<AppDatabase> with _$ThemeDAOMixin {
  ThemeDAO(super.db);

  Stream<List<LocalThemeData>> watchAllThemes() => select(themesTable).watch();

  Future<int> insertTheme(ThemesTableCompanion entry) =>
      into(themesTable).insert(entry);

  Future<bool> updateTheme(LocalThemeData entry) =>
      update(themesTable).replace(entry);

  Future<int> deleteTheme(String id) =>
      (delete(themesTable)..where((t) => t.id.equals(id))).go();

  Future<LocalThemeData?> getThemeByAlias(String alias) =>
      (select(themesTable)..where((t) => t.alias.equals(alias)))
          .getSingleOrNull();
}
