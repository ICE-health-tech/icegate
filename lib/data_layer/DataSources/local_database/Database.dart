// 1. Core Drift and Platform Imports
import 'package:drift/drift.dart';
import 'package:drift/native.dart'; // For NativeDatabase on mobile/desktop
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:ice_shield/initial_layer/ThemeLayer/CurrentThemeData.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:ice_shield/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/PersonalInformationProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/ProfileProtocol.dart';
import 'package:ice_shield/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'dart:io'; // For File
import 'dart:math'; // For Random() used in DAOs
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // For finding the database path
import 'package:path/path.dart' as p; // For path joining
import 'package:ice_shield/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';

// 2. Part Directives (Crucial for generated code)
// NOTE: You must run `flutter pub run build_runner build` to generate this file.
part 'Database.g.dart';
// NOTE: I'm using 'app_database.g.dart' as the standard naming convention.

// --- 3. Table Definitions ---

// // Constants for ExternalWidgetsTable (Optional, but good for clarity)
// const String columnId = 'widget_id';
// const String columnName = 'name';
// const String columnAlias = 'alias';
// const String columnProtocol = 'protocol';
// const String columnHost = 'host';
// const String columnUrl = 'url';
// const String columnDate = 'date_added';
// const String columnImageUrl = 'image_url';

@DataClassName("InternalWidgetData") // 3.1 ExternalWidgetsTable Definition
// const InternalWidgetData({
//   required super.url,
//   required super.name,
//   required super.imageUrl,
//   required super.dateAdded,
//   required super.widgetID,
class InternalWidgetsTable extends Table {
  IntColumn get widgetID =>
      integer().autoIncrement().named("internal_widget_id")();
  TextColumn get name =>
      text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get url => text()
      .withLength(min: 1, max: 100)
      .named("url")
      .nullable()(); // Added .nullable() as it can be generated
  TextColumn get dateAdded => text().named("date_added")();
  TextColumn get imageUrl => text().named("image_url")();
  TextColumn get alias => text().named("alias")();
}

@DriftAccessor(tables: [InternalWidgetsTable])
class InternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$InternalWidgetsDAOMixin {
  InternalWidgetsDAO(super.db);
  Future<InternalWidgetData?> getInternalWidgetByName(String name) {
    // return (select(internalWidgetsTable)..where((table)=>table.name.equals(_name)).getSingleOrNull());
    return (select(internalWidgetsTable)
          ..where((table) => table.name.equals(name)))
        .getSingleOrNull(); // <--- CRITICAL CHANGE

    // return (select(internalWidgetTable)
    //     ..where((table) => table.name.equals(name)))
    //     .getSingleOrNull();
  }

  Future<List<InternalWidgetData>> getInternaListWidgetByListName(
    List<String> listName,
  ) {
    return (select(
      internalWidgetsTable,
    )..where((tbl) => tbl.name.isIn(listName))).get();
  }

  Stream<List<InternalWidgetData>> watchAllWidgets() {
    return select(internalWidgetsTable).watch();
  }

  // void insertInternalWidget(){
  Future<int> insertInternalWidget({
    required String name,
    // required String protocol,
    // required widgetID,
    required String alias,
    required String url,
    String? imageUrl,
  }) {
    // final alias = _generateRandomAlias(8);
    final dateAdded = DateTime.now().toIso8601String();

    final entry = InternalWidgetsTableCompanion.insert(
      // alias: Value(alias),
      name: Value(name),
      // protocol: protocol,
      // host: host,
      // widgetID: widgetID,
      alias: alias,
      url: Value(url),
      imageUrl: imageUrl ?? "",
      dateAdded: dateAdded,
    );

    return into(internalWidgetsTable).insert(entry);
  }

  Future<int> deleteInternalWidget(String name) {
    return (delete(
      internalWidgetsTable,
    )..where((t) => t.name.equals(name))).go();
  }

  Future<int> renameInternalWidget(String oldName, String newName) {
    return (update(internalWidgetsTable)..where((t) => t.name.equals(oldName)))
        .write(InternalWidgetsTableCompanion(name: Value(newName)));
  }
}

@DataClassName('ExternalWidgetData') // The generated data class name
class ExternalWidgetsTable extends Table {
  IntColumn get widgetID => integer().autoIncrement().named("widget_id")();
  TextColumn get name => text().withLength(min: 1, max: 100).named("name")();
  TextColumn get alias => text()
      .withLength(min: 1, max: 100)
      .named("alias")
      .nullable()(); // Added .nullable() as it can be generated
  TextColumn get protocol => text().named("protocol")();
  TextColumn get host => text().named("host")();
  TextColumn get url => text().named("url")();
  TextColumn get imageUrl => text().nullable().named("image_url")();
  TextColumn get dateAdded => text().named("date_added")();
}

// 3.2 ThemesTable Definition
@DataClassName('LocalThemeData')
class ThemesTable extends Table {
  IntColumn get themeID => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get alias => text().withLength(min: 1, max: 50).unique()();
  TextColumn get json => text().named('json_content')();
  TextColumn get author => text().withLength(min: 1, max: 50)();
  DateTimeColumn get addedDate => dateTime()();
}

// 3.3 ProjectNotesTable Definition
@DataClassName('ProjectNoteData')
class ProjectNotesTable extends Table {
  IntColumn get noteID => integer().autoIncrement()();
  IntColumn get personID => integer().nullable().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()(); // JSON string of the note content
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get projectID => integer().nullable().references(
    ProjectsTable,
    #projectID,
    onDelete: KeyAction.cascade,
  )();
}

@DataClassName('ProjectData')
class ProjectsTable extends Table {
  IntColumn get projectID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get name => text().withLength(min: 1, max: 200)();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()(); // Added category column
  TextColumn get color => text().nullable()();
  IntColumn get status =>
      integer().withDefault(const Constant(0))(); // 0: active, 1: done
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

// --- 3.4 Person Management Tables ---

// Enums
enum UserRole { user, admin, viewer }

enum PostStatus { draft, published, archived, deleted }

enum EmailStatus { pending, verified, bounced, disabled }

enum CurrencyType { USD, EUR, VND, JPY, GBP, CNY }

enum SkillLevel { beginner, intermediate, advanced, expert }

@DataClassName('PersonData')
class PersonsTable extends Table {
  IntColumn get personID => integer().autoIncrement()();
  TextColumn get firstName => text().withLength(min: 1, max: 100)();
  TextColumn get lastName => text().nullable()();
  // Full name can be computed in Dart, not stored
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  TextColumn get gender => text().nullable()(); // 'male', 'female', etc.
  TextColumn get phoneNumber => text().withLength(max: 20).nullable()();
  TextColumn get profileImageUrl => text().nullable()();
  TextColumn get relationship => text().withDefault(
    const Constant('none'),
  )(); // 'friend', 'dating', 'family'
  IntColumn get affection => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('EmailAddressData')
class EmailAddressesTable extends Table {
  IntColumn get emailAddressID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get emailAddress => text().withLength(max: 320)();
  TextColumn get emailType => text().withDefault(const Constant('personal'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  TextColumn get status =>
      textEnum<EmailStatus>().withDefault(const Constant('pending'))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('UserAccountData')
class UserAccountsTable extends Table {
  IntColumn get accountID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get username => text().withLength(min: 3, max: 50).unique()();
  TextColumn get passwordHash => text()();
  IntColumn get primaryEmailID =>
      integer().nullable().references(EmailAddressesTable, #emailAddressID)();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(const Constant('user'))();
  BoolColumn get isLocked => boolean().withDefault(const Constant(false))();
  IntColumn get failedLoginAttempts =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get lastLoginAt => dateTime().nullable()();
  DateTimeColumn get passwordChangedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ProfileData')
class ProfilesTable extends Table {
  IntColumn get profileID => integer().autoIncrement()();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()();
  TextColumn get bio => text().nullable()();
  TextColumn get occupation => text().nullable()();
  TextColumn get educationLevel => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get websiteUrl => text().nullable()();
  TextColumn get linkedinUrl => text().nullable()();
  TextColumn get githubUrl => text().nullable()();
  TextColumn get timezone => text().withDefault(const Constant('UTC'))();
  TextColumn get preferredLanguage =>
      text().withDefault(const Constant('en'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('CVAddressData')
class CVAddressesTable extends Table {
  @override
  String get tableName => 'cv_addresses';
  IntColumn get cvAddressID => integer().autoIncrement()();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()();
  TextColumn get githubUrl => text().nullable()();
  TextColumn get websiteUrl => text().nullable()();
  TextColumn get company => text().nullable()();
  TextColumn get university => text().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get country => text().nullable()();
  TextColumn get bio => text().nullable()();
  TextColumn get occupation => text().nullable()();
  TextColumn get educationLevel => text().nullable()();
  TextColumn get linkedinUrl => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SkillData')
class SkillsTable extends Table {
  IntColumn get skillID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get skillName => text()();
  TextColumn get skillCategory => text().nullable()();
  TextColumn get proficiencyLevel =>
      textEnum<SkillLevel>().withDefault(const Constant('beginner'))();
  IntColumn get yearsOfExperience => integer().withDefault(const Constant(0))();
  TextColumn get description => text().nullable()();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('FinancialAccountData')
class FinancialAccountsTable extends Table {
  IntColumn get accountID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get accountName => text()();
  TextColumn get accountType =>
      text().withDefault(const Constant('checking'))();
  RealColumn get balance => real().withDefault(const Constant(0.0))();
  TextColumn get currency =>
      textEnum<CurrencyType>().withDefault(const Constant('USD'))();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('AssetData')
class AssetsTable extends Table {
  IntColumn get assetID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get assetName => text()();
  TextColumn get assetCategory => text()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  RealColumn get purchasePrice => real().nullable()();
  RealColumn get currentEstimatedValue => real().nullable()();
  TextColumn get currency =>
      textEnum<CurrencyType>().withDefault(const Constant('USD'))();
  TextColumn get condition => text().withDefault(const Constant('good'))();
  TextColumn get location => text().nullable()();
  TextColumn get notes => text().nullable()();
  BoolColumn get isInsured => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  IntColumn get transactionID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get category =>
      text()(); // e.g. 'food', 'transport', 'salary', 'savings'
  TextColumn get type => text()(); // 'income', 'expense', 'savings'
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get transactionDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get projectID => integer().nullable().references(
    ProjectsTable,
    #projectID,
    onDelete: KeyAction.cascade,
  )();
}

@DataClassName('GoalData')
class GoalsTable extends Table {
  IntColumn get goalID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().withDefault(const Constant('personal'))();
  IntColumn get priority => integer().withDefault(const Constant(3))();
  TextColumn get status =>
      text().withDefault(const Constant('active'))(); // planning, active, etc.
  DateTimeColumn get targetDate => dateTime().nullable()();
  DateTimeColumn get completionDate => dateTime().nullable()();
  IntColumn get progressPercentage =>
      integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get projectID => integer().nullable().references(
    ProjectsTable,
    #projectID,
    onDelete: KeyAction.cascade,
  )();
}

@DataClassName("ScoreLocalData")
class ScoresTable extends Table {
  IntColumn get scoreID => integer().autoIncrement()();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()();
  RealColumn get healthGlobalScore => real().withDefault(const Constant(0.0))();
  RealColumn get socialGlobalScore => real().withDefault(const Constant(0.0))();
  RealColumn get financialGlobalScore =>
      real().withDefault(const Constant(0.0))();
  RealColumn get careerGlobalScore => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('HabitData')
class HabitsTable extends Table {
  IntColumn get habitID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get goalID => integer().nullable().references(
    GoalsTable,
    #goalID,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get habitName => text()();
  TextColumn get description => text().nullable()();
  TextColumn get frequency => text()(); // daily, weekly, etc.
  TextColumn get frequencyDetails => text().nullable()(); // JSON
  IntColumn get targetCount => integer().withDefault(const Constant(1))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get startedDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('BlogPostData')
class BlogPostsTable extends Table {
  IntColumn get postID => integer().autoIncrement()();
  IntColumn get authorID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get title => text()();
  TextColumn get slug => text().unique()();
  TextColumn get excerpt => text().nullable()();
  TextColumn get content => text()();
  TextColumn get featuredImageUrl => text().nullable()();
  TextColumn get status =>
      textEnum<PostStatus>().withDefault(const Constant('draft'))();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false))();
  IntColumn get viewCount => integer().withDefault(const Constant(0))();
  IntColumn get likeCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get publishedAt => dateTime().nullable()();
  DateTimeColumn get scheduledFor => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('PersonWidgetData')
class PersonWidgetsTable extends Table {
  IntColumn get personWidgetID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get widgetName => text()();
  TextColumn get widgetType => text()();
  TextColumn get configuration =>
      text().withDefault(const Constant('{}'))(); // JSON
  IntColumn get displayOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(const Constant('admin'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('HealthMetricsLocal')
class HealthMetricsTable extends Table {
  IntColumn get metricID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get date => dateTime()();
  IntColumn get steps => integer().withDefault(const Constant(0))();
  IntColumn get heartRate => integer().withDefault(const Constant(0))();
  RealColumn get sleepHours => real().withDefault(const Constant(0.0))();
  IntColumn get waterGlasses => integer().withDefault(const Constant(0))();
  IntColumn get exerciseMinutes => integer().withDefault(const Constant(0))();
  IntColumn get focusMinutes => integer().withDefault(const Constant(0))();
  RealColumn get weightKg => real().withDefault(const Constant(0.0))();
  IntColumn get caloriesConsumed => integer().withDefault(const Constant(0))();
  IntColumn get caloriesBurned => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date},
  ];
}

@DataClassName('MealData')
class MealsTable extends Table {
  IntColumn get mealID => integer().named("meal_id").autoIncrement()();
  TextColumn get mealName =>
      text().withLength(min: 1, max: 50)(); // breakfast, lunch, etc.
  TextColumn get mealImageUrl => text().nullable()();
  RealColumn get fat => real().withDefault(const Constant(0.0))();
  RealColumn get carbs => real().withDefault(const Constant(0.0))();
  RealColumn get protein => real().withDefault(const Constant(0.0))();
  RealColumn get calories => real().withDefault(const Constant(0.0))();
  DateTimeColumn get eatenAt => dateTime().withDefault(currentDateAndTime)();
  // DateColumn get date => dateTime().withDefault(currentDate)();
}

@DataClassName('DayData')
class DaysTable extends Table {
  DateTimeColumn get dayID => dateTime().named('day_id')();
  IntColumn get weight => integer().withDefault(const Constant(0))();
  // DateTimeColumn get entryDateTime => dateTime()();
  IntColumn get caloriesOut => integer().withDefault(const Constant(0))();
}

@DataClassName('SessionData')
class SessionTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get jwt => text()();
  TextColumn get username => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('WaterLogData')
class WaterLogsTable extends Table {
  IntColumn get logID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get amount =>
      integer().withDefault(const Constant(0))(); // ml or glasses
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('SleepLogData')
class SleepLogsTable extends Table {
  IntColumn get logID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get quality =>
      integer().withDefault(const Constant(3))(); // 1-5 rating
}

@DataClassName('ExerciseLogData')
class ExerciseLogsTable extends Table {
  IntColumn get logID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get type => text()(); // e.g., 'Gym', 'Running'
  IntColumn get durationMinutes => integer()();
  TextColumn get intensity =>
      text().withDefault(const Constant('medium'))(); // low, medium, high
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime)();
}

@DataClassName('ThemeData')
class ThemeTable extends Table {
  IntColumn get themeID => integer().autoIncrement()();
  TextColumn get themeName => text()();
  TextColumn get themePath => text()();
}

@DataClassName('CustomNotificationData')
class CustomNotificationsTable extends Table {
  IntColumn get notificationID => integer().autoIncrement()();
  TextColumn get title => text().withLength(min: 1, max: 200)();
  TextColumn get content => text()();
  DateTimeColumn get scheduledTime => dateTime()();
  TextColumn get repeatFrequency => text().nullable().withDefault(
    const Constant('none'),
  )(); // none, hourly, daily, weekly
  TextColumn get repeatDays =>
      text().nullable()(); // Comma-separated: 1,3,5 (Mon, Wed, Fri)
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftAccessor(tables: [ThemeTable])
class ThemeDAO extends DatabaseAccessor<AppDatabase> with _$ThemeDAOMixin {
  ThemeDAO(super.db);

  Future<int> saveCurrentTheme(CurrentThemeData theme) async {
    return (update(themeTable)
          ..where((t) => t.themeName.equals("CurrentTheme")))
        .write(ThemeTableCompanion(themePath: Value(theme.themePath)));
  }

  Future<ThemeData?> getCurrentTheme() async {
    return (select(
      themeTable,
    )..where((t) => t.themeName.equals("CurrentTheme"))).getSingleOrNull();
  }

  Future<int> insertTheme({
    required String themeName,
    required String themePath,
  }) async {
    return into(themeTable).insert(
      ThemeTableCompanion(
        themeName: Value(themeName),
        themePath: Value(themePath),
      ),
    );
  }
}

// --- 4. DAO Definitions ---
//remove admin
@DriftAccessor(tables: [PersonsTable])
class PersonDAO extends DatabaseAccessor<AppDatabase> with _$PersonDAOMixin {
  PersonDAO(super.db);
  Stream<List<PersonData>> getAllPersons() {
    return (select(
      personsTable,
    )..where((t) => t.personID.isBiggerThanValue(1))).watch();
  }

  Future<PersonData?> getPersonByID(int id) async {
    final query = select(personsTable)..where((t) => t.personID.equals(id));
    return query.getSingleOrNull();
  }
}

@DriftAccessor(tables: [ScoresTable])
class ScoreDAO extends DatabaseAccessor<AppDatabase> with _$ScoreDAOMixin {
  ScoreDAO(super.db);

  Future<int> insertOrUpdateScore(ScoreLocalData score) {
    return into(scoresTable).insertOnConflictUpdate(score);
  }

  Future<ScoreLocalData?> getScoreByPersonID(int personID) {
    return (select(scoresTable)..where((tbl) => tbl.personID.equals(personID)))
        .get()
        .then((list) => list.firstOrNull);
  }

  Stream<ScoreLocalData?> watchScoreByPersonID(int personID) {
    return (select(
      scoresTable,
    )..where((tbl) => tbl.personID.equals(personID))).watchSingleOrNull();
  }

  Future<void> incrementCareerScore(int personID, double points) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            careerGlobalScore: Value(existing.careerGlobalScore + points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            personID: personID,
            careerGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateSocialScore(int personID, double score) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            socialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            personID: personID,
            socialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateFinancialScore(int personID, double score) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            financialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            personID: personID,
            financialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> incrementHealthScore(int personID, double points) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            healthGlobalScore: Value(existing.healthGlobalScore + points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            personID: personID,
            healthGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateHealthScore(int personID, double score) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            healthGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            personID: personID,
            healthGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}

// 4.1 ExternalWidgetsDAO
@DriftAccessor(tables: [ExternalWidgetsTable])
class ExternalWidgetsDAO extends DatabaseAccessor<AppDatabase>
    with _$ExternalWidgetsDAOMixin {
  ExternalWidgetsDAO(super.db);

  String _generateRandomAlias(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<int> insertNewWidget({
    required ExternalWidgetProtocol externalWidgetProtocol,
  }) {
    final entry = ExternalWidgetsTableCompanion.insert(
      name: externalWidgetProtocol.name.isEmpty
          ? 'Unnamed Widget'
          : externalWidgetProtocol.name,
      alias: Value(_generateRandomAlias(8)),
      widgetID: Value(IDGen.generate()),
      // jsonContent: externalWidgetProtocol.jsonContent,
      // author: externalWidgetProtocol.imageUrl,
      host: externalWidgetProtocol.host,
      protocol: externalWidgetProtocol.protocol,
      dateAdded: DateTime.now().toString(),
      url: externalWidgetProtocol.url,
      imageUrl: Value(externalWidgetProtocol.imageUrl),
    );

    return into(externalWidgetsTable).insert(entry);

    //      IntColumn get widgetID => integer().autoIncrement().named("widget_id")();
    // TextColumn get name => text().withLength(min: 1, max: 100).named("name")();
    // TextColumn get alias => text()
    //     .withLength(min: 1, max: 100)
    //     .named("alias")
    //     .nullable()(); // Added .nullable() as it can be generated
    // TextColumn get protocol => text().named("protocol")();
    // TextColumn get host => text().named("host")();
    // TextColumn get url => text().named("url")();
    // TextColumn get imageUrl => text().nullable().named("image_url")();
    // TextColumn get dateAdded => text().named("date_added")();
    // );

    // return into(externalWidgetsTable).insert(entry);
  }

  Future<int> deleteWidget(int widgetID) async {
    return (delete(
      externalWidgetsTable,
    )..where((tbl) => tbl.widgetID.equals(widgetID))).go();
  }

  Future<int> renameExternalWidget(int widgetID, String newName) {
    return (update(externalWidgetsTable)
          ..where((tbl) => tbl.widgetID.equals(widgetID)))
        .write(ExternalWidgetsTableCompanion(name: Value(newName)));
  }

  Stream<List<ExternalWidgetData>> watchAllWidgets() {
    return select(externalWidgetsTable).watch();
  }
}

// 4.2 ThemesTableDAO
@DriftAccessor(tables: [ThemesTable])
class ThemesTableDAO extends DatabaseAccessor<AppDatabase>
    with _$ThemesTableDAOMixin {
  ThemesTableDAO(super.db);

  String _generateRandomAlias(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();

    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  Future<int> insertNewTheme({
    required String name,
    required String jsonContent,
    required String author,
  }) {
    final alias = _generateRandomAlias(8);

    final entry = ThemesTableCompanion.insert(
      name: name,
      alias: alias,
      json: jsonContent,
      author: author,
      addedDate: DateTime.now(),
    );

    return into(themesTable).insert(entry);
  }

  Stream<List<LocalThemeData>> watchAllThemes() {
    return select(themesTable).watch();
  }
}

// 4.3 ProjectNoteDAO
@DriftAccessor(tables: [ProjectNotesTable])
class ProjectNoteDAO extends DatabaseAccessor<AppDatabase>
    with _$ProjectNoteDAOMixin {
  ProjectNoteDAO(super.db);

  Future<int> insertNote({
    required String title,
    required String content,
    int? projectID,
  }) {
    return into(projectNotesTable).insert(
      ProjectNotesTableCompanion.insert(
        title: title,
        content: content,
        projectID: Value(projectID),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<bool> updateNote(ProjectNoteData note) {
    return update(
      projectNotesTable,
    ).replace(note.copyWith(updatedAt: DateTime.now()));
  }

  Future<int> deleteNote(int id) {
    return (delete(
      projectNotesTable,
    )..where((tbl) => tbl.noteID.equals(id))).go();
  }

  Stream<List<ProjectNoteData>> watchAllNotes() {
    return select(projectNotesTable).watch();
  }

  Stream<List<ProjectNoteData>> watchRecentNotes(int limit) {
    return (select(projectNotesTable)
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<ProjectNoteData>> watchNotesByProject(int projectID) {
    return (select(projectNotesTable)
          ..where((tbl) => tbl.projectID.equals(projectID))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<ProjectNoteData?> getNoteById(int id) {
    return (select(
      projectNotesTable,
    )..where((tbl) => tbl.noteID.equals(id))).getSingleOrNull();
  }
}

@DriftAccessor(tables: [ProjectsTable])
class ProjectsDAO extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDAOMixin {
  ProjectsDAO(super.db);

  Future<int> insertProject(ProjectsTableCompanion project) =>
      into(projectsTable).insert(project);

  Stream<List<ProjectData>> watchAllProjects(int personID) => (select(
    projectsTable,
  )..where((t) => t.personID.equals(personID))).watch();

  Future<bool> updateProject(ProjectData project) =>
      update(projectsTable).replace(project);

  Future<int> deleteProject(int projectID) =>
      (delete(projectsTable)..where((t) => t.projectID.equals(projectID))).go();

  Future<ProjectData?> getProjectById(int projectID) => (select(
    projectsTable,
  )..where((t) => t.projectID.equals(projectID))).getSingleOrNull();
}

// 4.4 PersonManagementDAO
@DriftAccessor(
  tables: [
    PersonsTable,
    EmailAddressesTable,
    UserAccountsTable,
    ProfilesTable,
    CVAddressesTable,
  ],
)
class PersonManagementDAO extends DatabaseAccessor<AppDatabase>
    with _$PersonManagementDAOMixin {
  PersonManagementDAO(super.db);

  // Persons
  Future<int> createPerson(
    PersonProtocol person, {
    String? relationship,
  }) async {
    final companion = PersonsTableCompanion.insert(
      personID: Value(person.personID),
      firstName: person.firstName,
      lastName: Value(person.lastName),
      dateOfBirth: Value(person.dateOfBirth),
      gender: Value(person.gender),
      phoneNumber: Value(person.phoneNumber),
      profileImageUrl: Value(person.profileImageUrl),
      // relationship: Value(relationship ?? 'none'), // Removed because not generated
      isActive: Value(person.isActive),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    final id = await into(personsTable).insert(companion);
    if (relationship != null) {
      await customUpdate(
        'UPDATE persons_table SET relationship = ? WHERE person_i_d = ?',
        variables: [Variable.withString(relationship), Variable.withInt(id)],
        updates: {personsTable},
        updateKind: UpdateKind.update,
      );
    }
    return id;
  }

  Future<int> createMailAddress(EmailAddressProtocol email) {
    final companion = EmailAddressesTableCompanion.insert(
      emailAddressID: Value(email.emailAddressID),
      emailAddress: email.emailAddress,
      personID: email.personID,
      emailType: Value(email.emailType),
      isPrimary: Value(email.isPrimary),
      status: Value(email.status),
      verifiedAt: Value(email.verifiedAt),
      createdAt: Value(DateTime.now()),
      // updatedAt: Value(DateTime.now()),
    );
    return into(emailAddressesTable).insert(companion);
  }

  Future<PersonData?> getPersonById(int personID) => (select(
    personsTable,
  )..where((t) => t.personID.equals(personID))).getSingleOrNull();
  Future<void> updatePerson(PersonData person) =>
      update(personsTable).replace(person);

  Stream<List<SocialContact>> getContactsByRelationship(String type) {
    return customSelect(
      'SELECT * FROM persons_table WHERE relationship = ?',
      variables: [Variable.withString(type)],
      readsFrom: {personsTable},
    ).watch().map((rows) {
      return rows.map((row) {
        final person = personsTable.map(row.data);
        // Manually extract affection since PersonData might not have it generated yet
        final affection = row.data['affection'] as int? ?? 0;
        return SocialContact(person: person, affection: affection);
      }).toList();
    });
  }

  Stream<List<SocialContact>> getAllContacts() {
    return customSelect(
      "SELECT * FROM persons_table WHERE relationship != 'none' AND relationship != 'me'",
      readsFrom: {personsTable},
    ).watch().map((rows) {
      return rows.map((row) {
        final person = personsTable.map(row.data);
        final affection = row.data['affection'] as int? ?? 0;
        return SocialContact(person: person, affection: affection);
      }).toList();
    });
  }

  Future<void> increaseAffection(int personId, {int amount = 1}) async {
    await customUpdate(
      'UPDATE persons_table SET affection = affection + ? WHERE person_i_d = ?',
      variables: [Variable.withInt(amount), Variable.withInt(personId)],
      updates: {personsTable},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> updateRelationship(int personId, String relationship) async {
    await customUpdate(
      'UPDATE persons_table SET relationship = ? WHERE person_i_d = ?',
      variables: [
        Variable.withString(relationship),
        Variable.withInt(personId),
      ],
      updates: {personsTable},
      updateKind: UpdateKind.update,
    );
  }

  // Emails
  Future<int> addEmail(EmailAddressProtocol email, {int? overridePersonID}) {
    // Convert string status to EmailStatus enum
    EmailStatus emailStatus;
    switch (email.status.toString().toLowerCase()) {
      case 'verified':
        emailStatus = EmailStatus.verified;
        break;
      case 'bounced':
        emailStatus = EmailStatus.bounced;
        break;
      case 'disabled':
        emailStatus = EmailStatus.disabled;
        break;
      default:
        emailStatus = EmailStatus.pending;
    }

    final companion = EmailAddressesTableCompanion.insert(
      emailAddressID: Value(email.emailAddressID),
      personID: overridePersonID ?? email.personID,
      emailAddress: email.emailAddress,
      emailType: Value(email.emailType),
      isPrimary: Value(email.isPrimary),
      status: Value(emailStatus),
      verifiedAt: Value(email.verifiedAt),
      createdAt: Value(DateTime.now()),
    );
    return into(emailAddressesTable).insert(companion);
  }

  Future<List<EmailAddressData>> getEmailsForPerson(int personId) => (select(
    emailAddressesTable,
  )..where((t) => t.personID.equals(personId))).get();

  Future<void> updateEmail(EmailAddressData email) =>
      update(emailAddressesTable).replace(email);

  // Accounts
  Future<int> createAccount(
    UserAccountProtocol account, {
    int? overridePersonID,
    String? passwordHash,
  }) {
    // Convert string role to UserRole enum
    UserRole userRole;
    switch (account.role.toLowerCase()) {
      case 'admin':
        userRole = UserRole.admin;
        break;
      case 'viewer':
        userRole = UserRole.viewer;
        break;
      default:
        userRole = UserRole.user;
    }

    // Defensive check for username length (Drift constraint: min 3)
    String safeUsername = account.username;
    if (safeUsername.length < 3) {
      safeUsername = "user_${DateTime.now().millisecondsSinceEpoch % 1000}";
    }

    final companion = UserAccountsTableCompanion.insert(
      accountID: Value(account.accountID),
      personID: overridePersonID ?? account.personID,
      username: safeUsername,
      passwordHash: passwordHash ?? '', // Default empty if not provided
      primaryEmailID: const Value.absent(),
      role: Value(userRole),
      isLocked: Value(account.isLocked),
      lastLoginAt: Value(account.lastLoginAt),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return into(userAccountsTable).insert(companion);
  }

  Future<UserAccountData?> getAccountByUsername(String username) => (select(
    userAccountsTable,
  )..where((t) => t.username.equals(username))).getSingleOrNull();

  Future<void> updateAccount(UserAccountData account) =>
      update(userAccountsTable).replace(account);

  // Profiles
  Future<int> createProfile(ProfileProtocol profile, {int? overridePersonID}) {
    final companion = ProfilesTableCompanion.insert(
      profileID: Value(profile.profileID),
      personID: overridePersonID ?? profile.personID,
      bio: Value(profile.bio),
      occupation: Value(profile.occupation),
      educationLevel: Value(profile.educationLevel),
      location: Value(profile.location),
      websiteUrl: Value(profile.websiteUrl),
      linkedinUrl: Value(profile.linkedinUrl),
      githubUrl: Value(profile.githubUrl),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return into(profilesTable).insert(companion);
  }

  Future<ProfileData?> getProfileForPerson(int personId) => (select(
    profilesTable,
  )..where((t) => t.personID.equals(personId))).getSingleOrNull();

  Future<void> updateProfile(ProfileData profile) =>
      update(profilesTable).replace(profile);

  // CV Addresses
  Future<int> createCVAddress(
    CVAddressProtocol cvAddress, {
    int? overridePersonID,
  }) {
    final companion = CVAddressesTableCompanion.insert(
      cvAddressID: Value(cvAddress.cvAddressID),
      personID: overridePersonID ?? cvAddress.personID,
      githubUrl: Value(cvAddress.githubUrl),
      websiteUrl: Value(cvAddress.websiteUrl),
      company: Value(cvAddress.company),
      university: Value(cvAddress.university),
      location: Value(cvAddress.location),
      bio: Value(cvAddress.bio),
      occupation: Value(cvAddress.occupation),
      educationLevel: Value(cvAddress.educationLevel),
      linkedinUrl: Value(cvAddress.linkedinUrl),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    return into(cVAddressesTable).insert(companion);
  }

  Future<PersonalInformationProtocol> getAllInformation(int id) async {
    final emailData = await (select(
      emailAddressesTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();
    final accountData = await (select(
      userAccountsTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();

    final personData = await (select(
      personsTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();
    // final accountData =  getAccountByID(emailData!.personID);
    // final profileData =  getProfileForPerson(accountData!.personID);
    final cvAddressData = await (select(
      cVAddressesTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();

    final personalInformation = PersonalInformationProtocol(
      name: personData?.firstName ?? 'User',
      email: emailData?.emailAddress ?? '',

      // cvAddress: cvAddressData,
      username: accountData?.username ?? 'user',
      phoneNumber: personData?.phoneNumber,
      address: cvAddressData?.location,
      gender: personData?.gender,
      city: cvAddressData?.location,
      country: cvAddressData?.country,
      // postalCode: cvAddressData?.postalCode,
      birthday: personData?.dateOfBirth?.toString(),
      bio: cvAddressData?.bio,
      occupation: cvAddressData?.occupation,
      // profileImageUrl: accountData!.,
      isActive: accountData?.isLocked ?? false,
      company: cvAddressData?.company,
      website: cvAddressData?.websiteUrl,
      // postalCode: cvAddressData.postalCode, // CVAddress doesn't have it yet?
      // Let's check table definition again...
      // Line 248 has country. Let's see if 249 has bio.
      // I'll just skip postalCode for now if it's not in the table.
    );
    return personalInformation;
  }

  Future<CVAddressData?> getCVAddressForPerson(int personId) => (select(
    cVAddressesTable,
  )..where((t) => t.personID.equals(personId))).getSingleOrNull();

  Future<void> updateCVAddress(CVAddressData cvAddress) =>
      update(cVAddressesTable).replace(cvAddress);

  // Helper lookups
  Future<PersonData?> getPersonByEmail(String email) async {
    final emailData = await (select(
      emailAddressesTable,
    )..where((t) => t.emailAddress.equals(email))).getSingleOrNull();

    if (emailData != null) {
      return getPersonById(emailData.personID);
    }
    return null;
  }

  Future<PersonData?> getPersonByUsername(String username) async {
    final accountData = await getAccountByUsername(username);
    if (accountData != null) {
      return getPersonById(accountData.personID);
    }
    return null;
  }

  // Full Profile Creation (Transaction)
  Future<int> createFullProfile({
    required PersonProtocol person,
    required EmailAddressProtocol email,
    required UserAccountProtocol account,
    required ProfileProtocol profile,
    required CVAddressProtocol cvAddress,
    String? passwordHash,
  }) {
    return transaction(() async {
      final personID = await createPerson(person);

      await addEmail(email, overridePersonID: personID);
      await createAccount(
        account,
        overridePersonID: personID,
        passwordHash: passwordHash,
      );
      await createProfile(profile, overridePersonID: personID);
      await createCVAddress(cvAddress, overridePersonID: personID);

      return personID;
    });
  }
}

// 4.5 FinanceDAO
@DriftAccessor(tables: [FinancialAccountsTable, AssetsTable, TransactionsTable])
class FinanceDAO extends DatabaseAccessor<AppDatabase> with _$FinanceDAOMixin {
  FinanceDAO(super.db);

  // Accounts
  Future<int> createAccount(FinancialAccountsTableCompanion account) =>
      into(financialAccountsTable).insert(account);
  Stream<List<FinancialAccountData>> watchAccounts(int personId) => (select(
    financialAccountsTable,
  )..where((t) => t.personID.equals(personId))).watch();

  // Assets
  Future<int> createAsset(AssetsTableCompanion asset) =>
      into(assetsTable).insert(asset);
  Stream<List<AssetData>> watchAssets(int personId) =>
      (select(assetsTable)..where((t) => t.personID.equals(personId))).watch();

  // Transactions
  Future<int> insertTransaction(TransactionsTableCompanion txn) =>
      into(transactionsTable).insert(txn);

  Future<void> deleteTransaction(int transactionID) => (delete(
    transactionsTable,
  )..where((t) => t.transactionID.equals(transactionID))).go();

  Stream<List<TransactionData>> watchAllTransactions(int personId) =>
      (select(transactionsTable)
            ..where((t) => t.personID.equals(personId))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Stream<List<TransactionData>> watchTransactionsByType(
    int personId,
    String type,
  ) =>
      (select(transactionsTable)
            ..where((t) => t.personID.equals(personId) & t.type.equals(type))
            ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
          .watch();

  Stream<List<TransactionData>> watchMonthlyTransactions(
    int personId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);
    return (select(transactionsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.transactionDate.isBiggerOrEqualValue(start) &
                t.transactionDate.isSmallerOrEqualValue(end),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .watch();
  }
}

// 4.6 GrowthDAO
@DriftAccessor(tables: [GoalsTable, HabitsTable, SkillsTable])
class GrowthDAO extends DatabaseAccessor<AppDatabase> with _$GrowthDAOMixin {
  GrowthDAO(super.db);

  // Goals
  Future<int> createGoal(GoalsTableCompanion goal) =>
      into(goalsTable).insert(goal);
  Stream<List<GoalData>> watchGoals(int personId) =>
      (select(goalsTable)..where((t) => t.personID.equals(personId))).watch();

  Stream<List<GoalData>> watchGoalsByProject(int projectID) =>
      (select(goalsTable)..where((t) => t.projectID.equals(projectID))).watch();

  Future<void> updateGoalStatus(int goalID, String status) async {
    await (update(goalsTable)..where((t) => t.goalID.equals(goalID))).write(
      GoalsTableCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
        completionDate: status == 'done'
            ? Value(DateTime.now())
            : const Value.absent(),
        progressPercentage: status == 'done'
            ? const Value(100)
            : const Value.absent(),
      ),
    );
  }

  // Habits
  Future<int> createHabit(HabitsTableCompanion habit) =>
      into(habitsTable).insert(habit);
  Stream<List<HabitData>> watchHabits(int personId) =>
      (select(habitsTable)..where((t) => t.personID.equals(personId))).watch();

  // Skills
  Future<int> createSkill(SkillsTableCompanion skill) =>
      into(skillsTable).insert(skill);
  Stream<List<SkillData>> watchSkills(int personId) =>
      (select(skillsTable)..where((t) => t.personID.equals(personId))).watch();
}

// 4.7 ContentDAO
@DriftAccessor(tables: [BlogPostsTable])
class ContentDAO extends DatabaseAccessor<AppDatabase> with _$ContentDAOMixin {
  ContentDAO(super.db);

  Future<int> createPost(BlogPostsTableCompanion post) =>
      into(blogPostsTable).insert(post);
  Stream<List<BlogPostData>> watchPosts(int authorID) => (select(
    blogPostsTable,
  )..where((t) => t.authorID.equals(authorID))).watch();
  Future<BlogPostData?> getPostBySlug(String slug) => (select(
    blogPostsTable,
  )..where((t) => t.slug.equals(slug))).getSingleOrNull();
}

// 4.8 WidgetDAO
@DriftAccessor(tables: [PersonWidgetsTable])
class WidgetDAO extends DatabaseAccessor<AppDatabase> with _$WidgetDAOMixin {
  WidgetDAO(super.db);

  Future<int> createWidget(PersonWidgetsTableCompanion widget) =>
      into(personWidgetsTable).insert(widget);

  Stream<List<PersonWidgetData>> watchWidgets(int personId) => (select(
    personWidgetsTable,
  )..where((t) => t.personID.equals(personId))).watch();

  Future<List<PersonWidgetData>> getAllWidgets(int personId) => (select(
    personWidgetsTable,
  )..where((t) => t.personID.equals(personId))).get();

  Future<void> updateWidgetConfig(int id, String newConfig) =>
      (update(personWidgetsTable)..where((t) => t.personWidgetID.equals(id)))
          .write(PersonWidgetsTableCompanion(configuration: Value(newConfig)));

  Future<void> saveAllWidgets(
    int personId,
    List<InternalWidgetDragProtocol> widgets,
  ) {
    return transaction(() async {
      // 1. Delete all existing widgets for this person
      await (delete(
        personWidgetsTable,
      )..where((t) => t.personID.equals(personId))).go();

      // 2. Insert non-empty ones with their index
      for (int i = 0; i < widgets.length; i++) {
        final widget = widgets[i];
        if (widget.isEmpty) continue;

        await into(personWidgetsTable).insert(
          PersonWidgetsTableCompanion.insert(
            personID: personId,
            widgetName: widget.name,
            widgetType: widget.alias,
            displayOrder: Value(i),
            configuration: Value(jsonEncode(widget.toJson())),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }
}

@DriftAccessor(tables: [SessionTable])
class SessionDAO extends DatabaseAccessor<AppDatabase> with _$SessionDAOMixin {
  SessionDAO(super.db);

  Future<int> saveSession(String jwt, String? username) {
    return transaction(() async {
      await delete(sessionTable).go(); // Only one session at a time
      return into(sessionTable).insert(
        SessionTableCompanion.insert(jwt: jwt, username: Value(username)),
      );
    });
  }

  Future<SessionData?> getSession() => select(sessionTable).getSingleOrNull();

  Future<void> clearSession() => delete(sessionTable).go();
}

@DriftAccessor(tables: [HealthMetricsTable])
class HealthMetricsDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthMetricsDAOMixin {
  HealthMetricsDAO(super.db);

  Stream<List<HealthMetricsLocal>> watchAllMetrics(int personID) {
    return (select(healthMetricsTable)
          ..where((t) => t.personID.equals(personID))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<HealthMetricsLocal?> getMetricsForDate(int personID, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(healthMetricsTable)
          ..where(
            (t) =>
                t.personID.equals(personID) &
                t.date.isBiggerOrEqualValue(startOfDay) &
                t.date.isSmallerThanValue(endOfDay),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> insertOrUpdateMetrics(HealthMetricsTableCompanion entry) {
    HealthMetricsTableCompanion finalEntry = entry;
    if (entry.date.present) {
      final d = entry.date.value;
      final normalized = DateTime(d.year, d.month, d.day);
      finalEntry = entry.copyWith(date: Value(normalized));
    }
    return into(healthMetricsTable).insert(
      finalEntry,
      onConflict: DoUpdate(
        (old) => finalEntry,
        target: [healthMetricsTable.personID, healthMetricsTable.date],
      ),
    );
  }

  Future<int> deleteMetricsForPerson(int personID) {
    return (delete(
      healthMetricsTable,
    )..where((t) => t.personID.equals(personID))).go();
  }
}

@DriftAccessor(tables: [MealsTable, DaysTable])
class HealthMealDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthMealDAOMixin {
  HealthMealDAO(super.db);

  // Meals
  Future<int> insertMeal(MealsTableCompanion meal) =>
      into(mealsTable).insert(meal);
  Future<List<MealData>> getAllMeals() => select(mealsTable).get();
  Future<MealData?> getMealById(int id) =>
      (select(mealsTable)..where((t) => t.mealID.equals(id))).getSingleOrNull();

  // Days (Meal Logs)
  Future<int> insertDay(DaysTableCompanion day) => into(daysTable).insert(day);
  Future<double> getCaloriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final rows =
        await (select(mealsTable)..where(
              (tbl) =>
                  tbl.eatenAt.isBiggerOrEqualValue(startOfDay) &
                  tbl.eatenAt.isSmallerThanValue(endOfDay),
            ))
            .get();

    // Sum the calories
    double calories = 0.0;
    for (var row in rows) {
      calories += row.calories;
    }
    return calories;
  }

  Future<List<DayWithMeal>> getHealthMetricByDay(DateTime date) {
    // 1. Chuẩn hóa ngày về 00:00:00
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    final query =
        select(daysTable).join([
          innerJoin(
            mealsTable,
            // So sánh trực tiếp giá trị thời gian để tận dụng Index
            mealsTable.eatenAt.isBetweenValues(startOfDay, endOfDay),
          ),
        ])..where(
          daysTable.dayID.equals(startOfDay),
        ); // Giả sử dayID lưu mốc 00:00:00

    return query.get().then((rows) {
      return rows.map((row) {
        return DayWithMeal(
          day: row.readTable(daysTable),
          meal: row.readTable(mealsTable),
        );
      }).toList();
    });
  }

  Stream<List<DayWithMeal>> watchDaysWithMeals() {
    final query = select(daysTable).join([
      innerJoin(mealsTable, mealsTable.eatenAt.equalsExp(daysTable.dayID)),
    ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        return DayWithMeal(
          day: row.readTable(daysTable),
          meal: row.readTable(mealsTable),
        );
      }).toList();
    });
  }
}

class DayWithMeal {
  final DayData day;
  final MealData meal;

  DayWithMeal({required this.day, required this.meal});
}

// --- 5. Database Connection Helper ---

class SocialContact {
  final PersonData person;
  final int affection;

  SocialContact({required this.person, required this.affection});
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    // print("Database directory: ${dbFolder.path}");
    final file = File(p.join(dbFolder.path, 'db9.sqlite'));

    try {
      if (await file.exists()) {
        // print("Database file exists at: ${file.path}");
      } else {
        // print(
        //   "Database file does not exist. It will be created at: ${file.path}",
        // );
      }

      // print("Finalizing database connection...");
      // Using NativeDatabase directly instead of inBackground for testing iOS stability
      return NativeDatabase(file, logStatements: true);
    } catch (e) {
      print("❌ Error opening database: $e");
      rethrow;
    }
  });
}

// --- Focus Session ---
@DataClassName('FocusSessionData')
class FocusSessionsTable extends Table {
  IntColumn get sessionID => integer().autoIncrement()();
  IntColumn get personID => integer().references(
    PersonsTable,
    #personID,
    onDelete: KeyAction.cascade,
  )();
  IntColumn get projectID => integer().nullable().references(
    ProjectsTable,
    #projectID,
    onDelete: KeyAction.cascade,
  )();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()();
  IntColumn get durationSeconds => integer()();
  TextColumn get status =>
      text().withLength(min: 1, max: 20)(); // 'completed', 'interrupted'
  IntColumn get taskID => integer().nullable().references(
    GoalsTable,
    #goalID,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get notes => text().nullable()();
}

@DriftAccessor(tables: [FocusSessionsTable])
class FocusSessionsDAO extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDAOMixin {
  FocusSessionsDAO(super.db);

  Future<int> insertSession(FocusSessionsTableCompanion session) {
    return into(focusSessionsTable).insert(session);
  }

  Stream<List<FocusSessionData>> watchSessionsByPerson(int personId) {
    return (select(
      focusSessionsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }
}

@DataClassName('QuoteData')
class QuotesTable extends Table {
  IntColumn get quoteID => integer().autoIncrement()();
  TextColumn get content => text()();
  TextColumn get author => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

@DriftAccessor(tables: [QuotesTable])
class QuoteDAO extends DatabaseAccessor<AppDatabase> with _$QuoteDAOMixin {
  QuoteDAO(super.db);

  Future<int> insertQuote(QuotesTableCompanion entry) =>
      into(quotesTable).insert(entry);

  Future<bool> updateQuote(QuoteData entry) =>
      update(quotesTable).replace(entry);

  Future<int> deleteQuote(int id) =>
      (delete(quotesTable)..where((t) => t.quoteID.equals(id))).go();

  Future<List<QuoteData>> getAllQuotes() => select(quotesTable).get();

  Stream<List<QuoteData>> watchActiveQuotes() {
    return (select(quotesTable)..where((t) => t.isActive.equals(true))).watch();
  }
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

  Future<int> deleteNotification(int id) {
    return (delete(
      customNotificationsTable,
    )..where((t) => t.notificationID.equals(id))).go();
  }

  Stream<List<CustomNotificationData>> watchAllNotifications() {
    return (select(customNotificationsTable)..orderBy([
          (t) =>
              OrderingTerm(expression: t.scheduledTime, mode: OrderingMode.asc),
        ]))
        .watch();
  }

  Future<List<CustomNotificationData>> getAllEnabledNotifications() {
    return (select(
      customNotificationsTable,
    )..where((t) => t.isEnabled.equals(true))).get();
  }
}

@DriftAccessor(tables: [WaterLogsTable, SleepLogsTable, ExerciseLogsTable])
class HealthLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthLogsDAOMixin {
  HealthLogsDAO(super.db);

  // Water Logs
  Future<int> insertWaterLog(WaterLogsTableCompanion entry) =>
      into(waterLogsTable).insert(entry);
  Stream<List<WaterLogData>> watchDailyWaterLogs(int personId, DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterLogsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.timestamp.isBetweenValues(start, end),
        ))
        .watch();
  }

  // Sleep Logs
  Future<int> insertSleepLog(SleepLogsTableCompanion entry) =>
      into(sleepLogsTable).insert(entry);
  Stream<List<SleepLogData>> watchSleepLogs(int personId) {
    return (select(
      sleepLogsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  // Exercise Logs
  Future<int> insertExerciseLog(ExerciseLogsTableCompanion entry) =>
      into(exerciseLogsTable).insert(entry);
  Stream<List<ExerciseLogData>> watchDailyExerciseLogs(
    int personId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(exerciseLogsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.timestamp.isBetweenValues(start, end),
        ))
        .watch();
  }
}

// --- 6. Main Database Class ---

@DriftDatabase(
  tables: [
    ExternalWidgetsTable,
    ThemesTable,
    InternalWidgetsTable,
    ProjectNotesTable,
    PersonsTable,
    EmailAddressesTable,
    UserAccountsTable,
    ProfilesTable,
    SkillsTable,
    FinancialAccountsTable,
    AssetsTable,
    GoalsTable,
    HabitsTable,
    BlogPostsTable,
    PersonWidgetsTable,
    CVAddressesTable,
    SessionTable,
    HealthMetricsTable,
    MealsTable,
    DaysTable,
    ScoresTable,
    ThemeTable,
    ProjectsTable,
    TransactionsTable,
    FocusSessionsTable,
    CustomNotificationsTable,
    QuotesTable,
    WaterLogsTable,
    SleepLogsTable,
    ExerciseLogsTable,
  ],
  daos: [
    ThemesTableDAO,
    ExternalWidgetsDAO,
    InternalWidgetsDAO,
    ProjectNoteDAO,
    ProjectsDAO,
    // New DAOs
    PersonManagementDAO,
    FinanceDAO,
    GrowthDAO,
    ContentDAO,
    WidgetDAO,
    PersonDAO,
    SessionDAO,
    HealthMetricsDAO,
    HealthMealDAO,
    ScoreDAO,
    ThemeDAO,
    FocusSessionsDAO,
    CustomNotificationDAO,
    QuoteDAO,
    HealthLogsDAO,
  ],
)
class AppDatabase extends _$AppDatabase {
  final PowerSyncDatabase? powerSync;

  AppDatabase([QueryExecutor? executor, this.powerSync])
    : super(executor ?? _openConnection());

  factory AppDatabase.powersync(PowerSyncDatabase db) {
    return AppDatabase(SqliteAsyncDriftConnection(db), db);
  }

  @override
  int get schemaVersion => 21; // Increment schema version

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  // Migration strategy would be needed here for a real app update
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Create new tables
          await m.createTable(personsTable);
          await m.createTable(emailAddressesTable);
          await m.createTable(userAccountsTable);
          await m.createTable(profilesTable);
          await m.createTable(skillsTable);
          await m.createTable(financialAccountsTable);
          await m.createTable(assetsTable);
          await m.createTable(goalsTable);
          await m.createTable(habitsTable);
          await m.createTable(blogPostsTable);
          await m.createTable(personWidgetsTable);
        }
        if (from < 3) {
          await m.createTable(cVAddressesTable);
        }
        if (from < 4) {
          await m.createTable(sessionTable);
        }
        if (from < 15) {
          await m.createTable(focusSessionsTable);
        }
        if (from < 16) {
          try {
            await customStatement(
              "ALTER TABLE focus_sessions_table ADD COLUMN task_i_d INTEGER REFERENCES goals_table(goal_i_d) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Error adding task_i_d column to focus_sessions_table: $e');
          }
        }
        if (from < 5) {
          await m.createTable(healthMetricsTable);
        }
        if (from < 6) {
          await m.createTable(mealsTable);
          await m.createTable(daysTable);
        }
        if (from < 7) {
          await m.createTable(projectsTable);
        }
        if (from < 8) {
          // Safely add columns - catch errors if they already exist
          try {
            await customStatement(
              'ALTER TABLE project_notes_table ADD COLUMN person_i_d INTEGER REFERENCES persons_table(person_i_d) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE project_notes_table ADD COLUMN project_i_d INTEGER REFERENCES projects_table(project_i_d) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE goals_table ADD COLUMN project_i_d INTEGER REFERENCES projects_table(project_i_d) ON DELETE CASCADE',
            );
          } catch (_) {}
        }
        if (from < 9) {
          await m.createTable(transactionsTable);
        }

        if (from < 10) {
          // Attempt to clean duplicates (exact matches only for safety)
          try {
            await customStatement(
              'DELETE FROM health_metrics_table WHERE metric_i_d NOT IN (SELECT MIN(metric_i_d) FROM health_metrics_table GROUP BY person_i_d, date)',
            );
          } catch (e) {
            print('Error deleting duplicates: $e');
          }

          // Add unique index (this mimics uniqueKeys logic for the DB engine)
          try {
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_health_metrics_unique ON health_metrics_table (person_i_d, date)',
            );
          } catch (e) {
            print('Error creating unique index: $e');
          }
        }

        if (from < 20) {
          // Duplicate cleanup for scores_table
          try {
            print('Drift: Cleaning up duplicate scores for version 20');
            await customStatement(
              'DELETE FROM scores_table WHERE score_i_d NOT IN (SELECT MIN(score_i_d) FROM scores_table GROUP BY person_i_d)',
            );

            // Create the unique index if needed (SQLite table constraints are hard to add via ALTER)
            // But with .unique() in the table definition and a version bump, Drift's build_runner might handle it
            // or we manually ensure it here.
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_scores_person_unique ON scores_table (person_i_d)',
            );
          } catch (e) {
            print('Drift: Error in version 20 migration: $e');
          }
        }

        if (from < 11) {
          try {
            await customStatement(
              "ALTER TABLE persons_table ADD COLUMN relationship TEXT DEFAULT 'none';",
            );
          } catch (e) {
            print('Error adding relationship column: $e');
          }
        }
        if (from < 12) {
          try {
            await customStatement(
              "ALTER TABLE persons_table ADD COLUMN affection INTEGER DEFAULT 0;",
            );
          } catch (e) {
            print('Error adding affection column: $e');
          }
        }
        if (from < 13) {
          try {
            await customStatement(
              "ALTER TABLE projects_table ADD COLUMN category TEXT;",
            );
          } catch (e) {
            print('Error adding category column to projects_table: $e');
          }
        }
        if (from < 14) {
          try {
            await customStatement(
              "ALTER TABLE transactions_table ADD COLUMN project_i_d INTEGER REFERENCES projects_table(project_i_d) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Error adding project_i_d column to transactions_table: $e');
          }
        }
        if (from < 17) {
          await m.createTable(customNotificationsTable);
        }
        if (from < 18) {
          await m.createTable(quotesTable);
          try {
            await customStatement(
              "ALTER TABLE custom_notifications_table ADD COLUMN repeat_frequency TEXT DEFAULT 'none';",
            );
          } catch (_) {}
          try {
            await customStatement(
              "ALTER TABLE custom_notifications_table ADD COLUMN repeat_days TEXT;",
            );
          } catch (_) {}
        }
        if (from < 19) {
          await m.createTable(waterLogsTable);
          await m.createTable(sleepLogsTable);
          await m.createTable(exerciseLogsTable);
        }
        if (from < 21) {
          try {
            await customStatement(
              "ALTER TABLE health_metrics_table ADD COLUMN focus_minutes INTEGER DEFAULT 0;",
            );
          } catch (e) {
            print(
              'Error adding focus_minutes column to health_metrics_table: $e',
            );
          }
        }
      },
      beforeOpen: (details) async {
        print(
          "Drift: beforeOpen triggered. Version: ${details.versionBefore} -> ${details.versionNow}",
        );

        // 1. persons_table cleanup
        try {
          await customStatement(
            "ALTER TABLE persons_table ADD COLUMN affection INTEGER DEFAULT 0;",
          );
          print("Drift: Added affection column to persons_table");
        } catch (_) {}
        try {
          await customStatement(
            "UPDATE persons_table SET affection = 0 WHERE affection IS NULL;",
          );
        } catch (_) {}

        // 2. custom_notifications_table cleanup (Fixes NULL check operator error)
        try {
          print("Drift: Cleaning up custom_notifications_table NULLs...");
          // Ensure all non-nullable columns have defaults if they somehow got NULLs
          await customStatement(
            "UPDATE custom_notifications_table SET repeat_frequency = 'none' WHERE repeat_frequency IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications_table SET is_enabled = 1 WHERE is_enabled IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications_table SET title = 'Reminder' WHERE title IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications_table SET content = '' WHERE content IS NULL;",
          );

          // Verify if the columns even exist if we still crash
          print("Drift: custom_notifications_table cleanup completed.");
        } catch (e) {
          print("Drift: Error cleaning up custom_notifications_table: $e");
        }
      },
    );
  }
}
