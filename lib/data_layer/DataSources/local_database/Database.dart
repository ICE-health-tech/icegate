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
  @override
  String get tableName => 'internal_widgets';
  TextColumn get id => text()();
  IntColumn get widgetID => integer().nullable().named("widget_id")();

  // These are currently nullable in your DB
  TextColumn get name =>
      text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get url =>
      text().withLength(min: 1, max: 100).named("url").nullable()();

  TextColumn get dateAdded => text().named("date_added").nullable()();

  TextColumn get imageUrl => text().named("image_url").nullable()();
  TextColumn get alias => text().named("alias").nullable()();

  @override
  Set<Column> get primaryKey => {id};
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
    return customSelect(
      'SELECT * FROM internal_widgets',
      readsFrom: {internalWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null) // Skip rows with null id
          .map(
            (row) => InternalWidgetData(
              id: row.data['id'] as String,
              widgetID: row.data['widget_id'] as int?,
              name: row.data['name'] as String?,
              url: row.data['url'] as String?,
              dateAdded: row.data['date_added'] as String?,
              imageUrl: row.data['image_url'] as String?,
              alias: row.data['alias'] as String?,
            ),
          )
          .toList();
    });
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
      id: IDGen.generateUuid(),
      name: Value(name),
      alias: Value(alias), // This must be a String, not null
      url: Value(url),
      widgetID: Value(IDGen.generate()),
      // If imageUrl is null, provide a valid fallback string immediately
      imageUrl: Value(imageUrl ?? "assets/internalwidget/default_plugin.png"),
      dateAdded: Value(dateAdded),
    );

    print("DUYLONG insertInternalWidget: $entry");
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
  @override
  String get tableName => 'external_widgets';
  TextColumn get id => text()();
  IntColumn get widgetID => integer().nullable().named("widget_id")();
  TextColumn get name =>
      text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get alias => text()
      .withLength(min: 1, max: 100)
      .named("alias")
      .nullable()(); // Added .nullable() as it can be generated
  TextColumn get protocol => text().named("protocol").nullable()();
  TextColumn get host => text().named("host").nullable()();
  TextColumn get url => text().named("url").nullable()();
  TextColumn get imageUrl => text().nullable().named("image_url")();
  TextColumn get dateAdded => text().named("date_added").nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// 3.2 ThemesTable Definition
@DataClassName('LocalThemeData')
class ThemesTable extends Table {
  @override
  String get tableName => 'themes';
  TextColumn get id => text()();
  IntColumn get themeID =>
      integer().withDefault(const Constant(0)).named('theme_id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get alias =>
      text().withLength(min: 1, max: 50).unique().named('alias')();
  TextColumn get json => text().named('json_content')();
  TextColumn get author => text().withLength(min: 1, max: 50).named('author')();
  DateTimeColumn get addedDate => dateTime().named('added_date')();

  @override
  Set<Column> get primaryKey => {id};
}

// 3.3 ProjectNotesTable Definition
@DataClassName('ProjectNoteData')
class ProjectNotesTable extends Table {
  @override
  String get tableName => 'project_notes';
  TextColumn get id => text()(); // PowerSync UUID Primary Key
  IntColumn get noteID =>
      integer().withDefault(const Constant(0)).named('note_id')();
  IntColumn get personID => integer()
      .nullable()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content =>
      text().named('content')(); // JSON string of the note content
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();
  IntColumn get projectID => integer()
      .nullable()
      .references(ProjectsTable, #projectID, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectData')
class ProjectsTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text()(); // PowerSync UUID Primary Key
  IntColumn get projectID =>
      integer().withDefault(const Constant(0)).named('project_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category =>
      text().nullable().named('category')(); // Added category column
  TextColumn get color => text().nullable().named('color')();
  IntColumn get status =>
      integer().withDefault(const Constant(0)).named('status')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
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
  @override
  String get tableName => 'persons';
  TextColumn get id => text()(); // PowerSync UUID Primary Key
  IntColumn get personID => integer().named('person_id')();
  TextColumn get firstName =>
      text().withLength(min: 1, max: 100).named('first_name')();
  TextColumn get lastName => text().nullable().named('last_name')();
  // Full name can be computed in Dart, not stored
  DateTimeColumn get dateOfBirth =>
      dateTime().nullable().named('date_of_birth')();
  TextColumn get gender =>
      text().nullable().named('gender')(); // 'male', 'female', etc.
  TextColumn get phoneNumber =>
      text().withLength(max: 20).nullable().named('phone_number')();
  TextColumn get profileImageUrl =>
      text().nullable().named('profile_image_url')();
  TextColumn get relationship => text()
      .withDefault(const Constant('none'))
      .named('relationship')(); // 'friend', 'dating', 'family'
  IntColumn get affection =>
      integer().withDefault(const Constant(0)).named('affection')();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EmailAddressData')
class EmailAddressesTable extends Table {
  @override
  String get tableName => 'email_addresses';
  TextColumn get id => text()();
  IntColumn get emailAddressID =>
      integer().withDefault(const Constant(0)).named('email_address_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get emailAddress =>
      text().withLength(max: 320).named('email_address')();
  TextColumn get emailType =>
      text().withDefault(const Constant('personal')).named('email_type')();
  BoolColumn get isPrimary =>
      boolean().withDefault(const Constant(false)).named('is_primary')();
  TextColumn get status => textEnum<EmailStatus>()
      .withDefault(const Constant('pending'))
      .named('status')();
  DateTimeColumn get verifiedAt => dateTime().nullable().named('verified_at')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserAccountData')
class UserAccountsTable extends Table {
  @override
  String get tableName => 'user_accounts';
  TextColumn get id => text()();
  IntColumn get accountID =>
      integer().withDefault(const Constant(0)).named('account_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get username =>
      text().withLength(min: 3, max: 50).unique().named('username')();
  TextColumn get passwordHash => text().named('password_hash')();
  IntColumn get primaryEmailID => integer()
      .nullable()
      .named('primary_email_id')
      .references(EmailAddressesTable, #emailAddressID)();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(const Constant('user')).named('role')();
  BoolColumn get isLocked =>
      boolean().withDefault(const Constant(false)).named('is_locked')();
  IntColumn get failedLoginAttempts =>
      integer().withDefault(const Constant(0)).named('failed_login_attempts')();
  DateTimeColumn get lastLoginAt =>
      dateTime().nullable().named('last_login_at')();
  DateTimeColumn get passwordChangedAt =>
      dateTime().withDefault(currentDateAndTime).named('password_changed_at')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProfileData')
class ProfilesTable extends Table {
  @override
  String get tableName => 'profiles';
  TextColumn get id => text()();
  IntColumn get profileID =>
      integer().withDefault(const Constant(0)).named('profile_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')();
  TextColumn get bio => text().nullable().named('bio')();
  TextColumn get occupation => text().nullable().named('occupation')();
  TextColumn get educationLevel => text().nullable().named('education_level')();
  TextColumn get location => text().nullable().named('location')();
  TextColumn get websiteUrl => text().nullable().named('website_url')();
  TextColumn get linkedinUrl => text().nullable().named('linkedin_url')();
  TextColumn get githubUrl => text().nullable().named('github_url')();
  TextColumn get timezone => text().nullable().named('timezone')();
  TextColumn get preferredLanguage =>
      text().nullable().named('preferred_language')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CVAddressData')
class CVAddressesTable extends Table {
  @override
  String get tableName => 'detail_information';
  TextColumn get id => text()();
  IntColumn get cvAddressID =>
      integer().withDefault(const Constant(0)).named('cv_address_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')();
  TextColumn get githubUrl => text().nullable().named('github_url')();
  TextColumn get websiteUrl => text().nullable().named('website_url')();
  TextColumn get company => text().nullable().named('company')();
  TextColumn get university => text().nullable().named('university')();
  TextColumn get location => text().nullable().named('location')();
  TextColumn get country => text().nullable().named('country')();
  TextColumn get bio => text().nullable().named('bio')();
  TextColumn get occupation => text().nullable().named('occupation')();
  TextColumn get educationLevel => text().nullable().named('education_level')();
  TextColumn get linkedinUrl => text().nullable().named('linkedin_url')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SkillData')
class SkillsTable extends Table {
  @override
  String get tableName => 'skills';
  TextColumn get id => text()();
  IntColumn get skillID =>
      integer().withDefault(const Constant(0)).named('skill_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get skillName => text().named('skill_name')();
  TextColumn get skillCategory => text().nullable().named('skill_category')();
  TextColumn get proficiencyLevel => textEnum<SkillLevel>()
      .withDefault(const Constant('beginner'))
      .named('proficiency_level')();
  IntColumn get yearsOfExperience =>
      integer().withDefault(const Constant(0)).named('years_of_experience')();
  TextColumn get description => text().nullable().named('description')();
  BoolColumn get isFeatured =>
      boolean().withDefault(const Constant(false)).named('is_featured')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinancialAccountData')
class FinancialAccountsTable extends Table {
  @override
  String get tableName => 'financial_accounts';
  TextColumn get id => text()();
  IntColumn get accountID =>
      integer().withDefault(const Constant(0)).named('account_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get accountName => text().named('account_name')();
  TextColumn get accountType =>
      text().withDefault(const Constant('checking')).named('account_type')();
  RealColumn get balance =>
      real().withDefault(const Constant(0.0)).named('balance')();
  TextColumn get currency => textEnum<CurrencyType>()
      .withDefault(const Constant('USD'))
      .named('currency')();
  BoolColumn get isPrimary =>
      boolean().withDefault(const Constant(false)).named('is_primary')();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AssetData')
class AssetsTable extends Table {
  @override
  String get tableName => 'assets';
  TextColumn get id => text()();
  IntColumn get assetID =>
      integer().withDefault(const Constant(0)).named('asset_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get assetName => text().named('asset_name')();
  TextColumn get assetCategory => text().named('asset_category')();
  DateTimeColumn get purchaseDate =>
      dateTime().nullable().named('purchase_date')();
  RealColumn get purchasePrice => real().nullable().named('purchase_price')();
  RealColumn get currentEstimatedValue =>
      real().nullable().named('current_estimated_value')();
  TextColumn get currency => textEnum<CurrencyType>()
      .withDefault(const Constant('USD'))
      .named('currency')();
  TextColumn get condition =>
      text().withDefault(const Constant('good')).named('condition')();
  TextColumn get location => text().nullable().named('location')();
  TextColumn get notes => text().nullable().named('notes')();
  BoolColumn get isInsured =>
      boolean().withDefault(const Constant(false)).named('is_insured')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';
  TextColumn get id => text()();
  IntColumn get transactionID =>
      integer().withDefault(const Constant(0)).named('transaction_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get category => text().named(
    'category',
  )(); // e.g. 'food', 'transport', 'salary', 'savings'
  TextColumn get type =>
      text().named('type')(); // 'income', 'expense', 'savings'
  RealColumn get amount => real().named('amount')();
  TextColumn get description => text().nullable().named('description')();
  DateTimeColumn get transactionDate =>
      dateTime().withDefault(currentDateAndTime).named('transaction_date')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  IntColumn get projectID => integer()
      .nullable()
      .references(ProjectsTable, #projectID, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalData')
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';
  TextColumn get id => text()();
  IntColumn get goalID =>
      integer().withDefault(const Constant(0)).named('goal_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get title => text().named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category =>
      text().withDefault(const Constant('personal')).named('category')();
  IntColumn get priority =>
      integer().withDefault(const Constant(3)).named('priority')();
  TextColumn get status => text()
      .withDefault(const Constant('active'))
      .named('status')(); // planning, active, etc.
  DateTimeColumn get targetDate => dateTime().nullable().named('target_date')();
  DateTimeColumn get completionDate =>
      dateTime().nullable().named('completion_date')();
  IntColumn get progressPercentage =>
      integer().withDefault(const Constant(0)).named('progress_percentage')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();
  IntColumn get projectID => integer()
      .nullable()
      .references(ProjectsTable, #projectID, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("ScoreLocalData")
class ScoresTable extends Table {
  @override
  String get tableName => 'scores';
  TextColumn get id => text()();
  IntColumn get scoreID => integer().named('score_id').nullable()();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')
      .nullable()();
  RealColumn get healthGlobalScore => real()
      .withDefault(const Constant(0.0))
      .named('health_global_score')
      .nullable()();
  RealColumn get socialGlobalScore => real()
      .withDefault(const Constant(0.0))
      .named('social_global_score')
      .nullable()();
  RealColumn get financialGlobalScore => real()
      .withDefault(const Constant(0.0))
      .named('financial_global_score')
      .nullable()();
  RealColumn get careerGlobalScore => real()
      .withDefault(const Constant(0.0))
      .named('career_global_score')
      .nullable()();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .named('updated_at')
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HabitData')
class HabitsTable extends Table {
  @override
  String get tableName => 'habits';
  TextColumn get id => text()();
  IntColumn get habitID =>
      integer().withDefault(const Constant(0)).named('habit_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  IntColumn get goalID => integer()
      .nullable()
      .references(GoalsTable, #goalID, onDelete: KeyAction.setNull)
      .named('goal_id')();
  TextColumn get habitName => text().named('habit_name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get frequency =>
      text().named('frequency')(); // daily, weekly, etc.
  TextColumn get frequencyDetails =>
      text().nullable().named('frequency_details')(); // JSON
  IntColumn get targetCount =>
      integer().withDefault(const Constant(1)).named('target_count')();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get startedDate =>
      dateTime().withDefault(currentDateAndTime).named('started_date')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('BlogPostData')
class BlogPostsTable extends Table {
  @override
  String get tableName => 'blog_posts';
  TextColumn get id => text()();
  IntColumn get postID =>
      integer().withDefault(const Constant(0)).named('post_id')();
  IntColumn get authorID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.restrict)
      .named('author_id')();
  TextColumn get title => text().named('title')();
  TextColumn get slug => text().unique().named('slug')();
  TextColumn get excerpt => text().nullable().named('excerpt')();
  TextColumn get content => text().named('content')();
  TextColumn get featuredImageUrl =>
      text().nullable().named('featured_image_url')();
  TextColumn get status => textEnum<PostStatus>()
      .withDefault(const Constant('draft'))
      .named('status')();
  BoolColumn get isFeatured =>
      boolean().withDefault(const Constant(false)).named('is_featured')();
  IntColumn get viewCount =>
      integer().withDefault(const Constant(0)).named('view_count')();
  IntColumn get likeCount =>
      integer().withDefault(const Constant(0)).named('like_count')();
  DateTimeColumn get publishedAt =>
      dateTime().nullable().named('published_at')();
  DateTimeColumn get scheduledFor =>
      dateTime().nullable().named('scheduled_for')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PersonWidgetData')
class PersonWidgetsTable extends Table {
  @override
  String get tableName => 'person_widgets';
  TextColumn get id => text()();
  IntColumn get personWidgetID =>
      integer().withDefault(const Constant(0)).named('person_widget_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get widgetName => text().named('widget_name')();
  TextColumn get widgetType => text().named('widget_type')();
  TextColumn get configuration =>
      text().withDefault(const Constant('{}')).named('configuration')(); // JSON
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0)).named('display_order')();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(const Constant('admin')).named('role')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .named('updated_at')
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HealthMetricsLocal')
class HealthMetricsTable extends Table {
  @override
  String get tableName => 'health_metrics';
  TextColumn get id => text()();
  IntColumn get metricID =>
      integer().withDefault(const Constant(0)).named('metric_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get date => dateTime().named('date')();
  IntColumn get steps =>
      integer().withDefault(const Constant(0)).named('steps')();
  IntColumn get heartRate =>
      integer().withDefault(const Constant(0)).named('heart_rate')();
  RealColumn get sleepHours =>
      real().withDefault(const Constant(0.0)).named('sleep_hours')();
  IntColumn get waterGlasses =>
      integer().withDefault(const Constant(0)).named('water_glasses')();
  IntColumn get exerciseMinutes =>
      integer().withDefault(const Constant(0)).named('exercise_minutes')();
  IntColumn get focusMinutes =>
      integer().withDefault(const Constant(0)).named('focus_minutes')();
  RealColumn get weightKg =>
      real().withDefault(const Constant(0.0)).named('weight_kg')();
  IntColumn get caloriesConsumed =>
      integer().withDefault(const Constant(0)).named('calories_consumed')();
  IntColumn get caloriesBurned =>
      integer().withDefault(const Constant(0)).named('calories_burned')();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime).named('updated_at')();

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date},
  ];

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MealData')
class MealsTable extends Table {
  @override
  String get tableName => 'meals';
  TextColumn get id => text()();
  IntColumn get mealID =>
      integer().withDefault(const Constant(0)).named("meal_id")();
  TextColumn get mealName => text()
      .withLength(min: 1, max: 50)
      .named("meal_name")(); // breakfast, lunch, etc.
  TextColumn get mealImageUrl => text().nullable().named("meal_image_url")();
  RealColumn get fat => real().withDefault(const Constant(0.0)).named("fat")();
  RealColumn get carbs =>
      real().withDefault(const Constant(0.0)).named("carbs")();
  RealColumn get protein =>
      real().withDefault(const Constant(0.0)).named("protein")();
  RealColumn get calories =>
      real().withDefault(const Constant(0.0)).named("calories")();
  DateTimeColumn get eatenAt =>
      dateTime().withDefault(currentDateAndTime).named("eaten_at")();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayData')
class DaysTable extends Table {
  @override
  String get tableName => 'days';
  TextColumn get id => text()();
  DateTimeColumn get dayID => dateTime().named('day_id')();
  IntColumn get weight =>
      integer().withDefault(const Constant(0)).named('weight')();
  IntColumn get caloriesOut =>
      integer().withDefault(const Constant(0)).named('calories_out')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SessionData')
class SessionTable extends Table {
  @override
  String get tableName => 'sessions';
  TextColumn get id => text()(); // PowerSync UUID
  IntColumn get localID => integer()
      .withDefault(const Constant(0))
      .named('local_id')(); // Renamed from id
  TextColumn get jwt => text().named('jwt')();
  TextColumn get username => text().nullable().named('username')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WaterLogData')
class WaterLogsTable extends Table {
  @override
  String get tableName => 'water_logs';
  TextColumn get id => text()();
  IntColumn get logID =>
      integer().withDefault(const Constant(0)).named('log_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  IntColumn get amount => integer()
      .withDefault(const Constant(0))
      .named('amount')(); // ml or glasses
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime).named('timestamp')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SleepLogData')
class SleepLogsTable extends Table {
  @override
  String get tableName => 'sleep_logs';
  TextColumn get id => text()();
  IntColumn get logID =>
      integer().withDefault(const Constant(0)).named('log_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().nullable().named('end_time')();
  IntColumn get quality =>
      integer().withDefault(const Constant(3)).named('quality')(); // 1-5 rating

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExerciseLogData')
class ExerciseLogsTable extends Table {
  @override
  String get tableName => 'exercise_logs';
  TextColumn get id => text()();
  IntColumn get logID =>
      integer().withDefault(const Constant(0)).named('log_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get type => text().named('type')(); // e.g., 'Gym', 'Running'
  IntColumn get durationMinutes => integer().named('duration_minutes')();
  TextColumn get intensity => text()
      .withDefault(const Constant('medium'))
      .named('intensity')(); // low, medium, high
  DateTimeColumn get timestamp =>
      dateTime().withDefault(currentDateAndTime).named('timestamp')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ThemeData')
class ThemeTable extends Table {
  @override
  String get tableName => 'themes_config';
  TextColumn get id => text()();
  IntColumn get themeID =>
      integer().withDefault(const Constant(0)).named('theme_id')();
  TextColumn get themeName => text().named('theme_name')();
  TextColumn get themePath => text().named('theme_path')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomNotificationData')
class CustomNotificationsTable extends Table {
  @override
  String get tableName => 'custom_notifications';
  TextColumn get id => text()();
  IntColumn get notificationID =>
      integer().withDefault(const Constant(0)).named('notification_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content => text().named('content')();
  DateTimeColumn get scheduledTime => dateTime().named('scheduled_time')();
  TextColumn get repeatFrequency => text()
      .nullable()
      .withDefault(const Constant('none'))
      .named('repeat_frequency')(); // none, hourly, daily, weekly
  TextColumn get repeatDays => text().nullable().named(
    'repeat_days',
  )(); // Comma-separated: 1,3,5 (Mon, Wed, Fri)
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(true)).named('is_enabled')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuestData')
class QuestsTable extends Table {
  @override
  String get tableName => 'quests';
  TextColumn get id => text()();
  IntColumn get questID =>
      integer().withDefault(const Constant(0)).named('quest_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get type => text()
      .withDefault(const Constant('daily'))
      .named('type')(); // daily, weekly, permanent
  RealColumn get targetValue =>
      real().withDefault(const Constant(0.0)).named('target_value')();
  RealColumn get currentValue =>
      real().withDefault(const Constant(0.0)).named('current_value')();
  TextColumn get category =>
      text().withDefault(const Constant('health')).named('category')();
  IntColumn get rewardExp =>
      integer().withDefault(const Constant(10)).named('reward_exp')();
  BoolColumn get isCompleted =>
      boolean().withDefault(const Constant(false)).named('is_completed')();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
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
            careerGlobalScore: Value(
              (existing.careerGlobalScore ?? 0.0) + points,
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: IDGen.generateUuid(),
            personID: Value(personID),
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
            id: IDGen.generateUuid(),
            personID: Value(personID),
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
            id: IDGen.generateUuid(),
            personID: Value(personID),
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
            healthGlobalScore: Value(
              (existing.healthGlobalScore ?? 0.0) + points,
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: IDGen.generateUuid(),
            personID: Value(personID),
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
            id: IDGen.generateUuid(),
            personID: Value(personID),
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
      id: IDGen.generateUuid(),
      name: Value(
        externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
      ),
      alias: Value(_generateRandomAlias(8)),
      widgetID: Value(IDGen.generate()),
      host: Value(externalWidgetProtocol.host),
      protocol: Value(externalWidgetProtocol.protocol),
      dateAdded: Value(DateTime.now().toString()),
      url: Value(externalWidgetProtocol.url),
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
    return customSelect(
      'SELECT * FROM external_widgets',
      readsFrom: {externalWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => ExternalWidgetData(
              id: row.data['id'] as String,
              widgetID: row.data['widget_id'] as int?,
              name: row.data['name'] as String?,
              alias: row.data['alias'] as String?,
              protocol: row.data['protocol'] as String?,
              host: row.data['host'] as String?,
              url: row.data['url'] as String?,
              imageUrl: row.data['image_url'] as String?,
              dateAdded: row.data['date_added'] as String?,
            ),
          )
          .toList();
    });
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
      id: IDGen.generateUuid(),
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
        id: IDGen.generateUuid(),
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

  Stream<List<ProjectData>> watchAllProjects(int personID) {
    return customSelect(
      'SELECT * FROM projects WHERE person_id = ?',
      variables: [Variable.withInt(personID)],
      readsFrom: {projectsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => ProjectData(
              id: row.data['id'] as String,
              projectID: (row.data['project_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personID,
              name: (row.data['name'] as String?) ?? 'Untitled',
              description: row.data['description'] as String?,
              category: row.data['category'] as String?,
              color: row.data['color'] as String?,
              status: (row.data['status'] as int?) ?? 0,
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  Future<bool> updateProject(ProjectData project) =>
      update(projectsTable).replace(project);

  Future<int> deleteProjectByUuid(String id) =>
      (delete(projectsTable)..where((t) => t.id.equals(id))).go();

  Future<int> deleteProjectByIntId(int projectID) =>
      (delete(projectsTable)..where((t) => t.projectID.equals(projectID))).go();

  Future<ProjectData?> getProjectByUuid(String id) =>
      (select(projectsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProjectData?> getProjectByIntId(int projectID) => (select(
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
    print("Person that is inserted: " + person.personID.toString());
    final companion = PersonsTableCompanion.insert(
      id: IDGen.generateUuid(),
      personID: person.personID,
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
    // print("person ID: $id");
    if (relationship != null) {
      await customUpdate(
        'UPDATE persons SET relationship = ? WHERE person_id = ?',
        variables: [
          Variable.withString(relationship),
          Variable.withInt(person.personID),
        ],
        updates: {personsTable},
        updateKind: UpdateKind.update,
      );
    }
    return id;
  }

  Future<int> createMailAddress(EmailAddressProtocol email) {
    final companion = EmailAddressesTableCompanion.insert(
      id: IDGen.generateUuid(),
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
      'SELECT * FROM persons WHERE relationship = ?',
      variables: [Variable.withString(type)],
      readsFrom: {personsTable},
    ).watch().map((rows) {
      return rows.where((row) => row.data['id'] != null).map((row) {
        final person = PersonData(
          id: row.data['id'] as String,
          personID: (row.data['person_id'] as int?) ?? 0,
          firstName: (row.data['first_name'] as String?) ?? 'Unknown',
          lastName: row.data['last_name'] as String?,
          dateOfBirth: row.data['date_of_birth'] != null
              ? DateTime.tryParse(row.data['date_of_birth'].toString())
              : null,
          gender: row.data['gender'] as String?,
          phoneNumber: row.data['phone_number'] as String?,
          profileImageUrl: row.data['profile_image_url'] as String?,
          relationship: (row.data['relationship'] as String?) ?? 'none',
          affection: (row.data['affection'] as int?) ?? 0,
          isActive: row.data['is_active'] == 1 || row.data['is_active'] == true,
          createdAt: row.data['created_at'] != null
              ? DateTime.tryParse(row.data['created_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
          updatedAt: row.data['updated_at'] != null
              ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
        final affection = row.data['affection'] as int? ?? 0;
        return SocialContact(person: person, affection: affection);
      }).toList();
    });
  }

  Stream<List<SocialContact>> getAllContacts() {
    return customSelect(
      "SELECT * FROM persons WHERE relationship != 'none' AND relationship != 'me'",
      readsFrom: {personsTable},
    ).watch().map((rows) {
      return rows.where((row) => row.data['id'] != null).map((row) {
        final person = PersonData(
          id: row.data['id'] as String,
          personID: (row.data['person_id'] as int?) ?? 0,
          firstName: (row.data['first_name'] as String?) ?? 'Unknown',
          lastName: row.data['last_name'] as String?,
          dateOfBirth: row.data['date_of_birth'] != null
              ? DateTime.tryParse(row.data['date_of_birth'].toString())
              : null,
          gender: row.data['gender'] as String?,
          phoneNumber: row.data['phone_number'] as String?,
          profileImageUrl: row.data['profile_image_url'] as String?,
          relationship: (row.data['relationship'] as String?) ?? 'none',
          affection: (row.data['affection'] as int?) ?? 0,
          isActive: row.data['is_active'] == 1 || row.data['is_active'] == true,
          createdAt: row.data['created_at'] != null
              ? DateTime.tryParse(row.data['created_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
          updatedAt: row.data['updated_at'] != null
              ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                    DateTime.now()
              : DateTime.now(),
        );
        final affection = row.data['affection'] as int? ?? 0;
        return SocialContact(person: person, affection: affection);
      }).toList();
    });
  }

  Future<void> increaseAffection(int personId, {int amount = 1}) async {
    await customUpdate(
      'UPDATE persons SET affection = affection + ? WHERE personID = ?',
      variables: [Variable.withInt(amount), Variable.withInt(personId)],
      updates: {personsTable},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> updateRelationship(int personId, String relationship) async {
    await customUpdate(
      'UPDATE persons SET relationship = ? WHERE personID = ?',
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
      id: IDGen.generateUuid(),
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
      id: IDGen.generateUuid(),
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
      id: IDGen.generateUuid(),
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
      id: IDGen.generateUuid(),
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
  Stream<List<FinancialAccountData>> watchAccounts(int personId) {
    return customSelect(
      'SELECT * FROM financial_accounts WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {financialAccountsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => FinancialAccountData(
              id: row.data['id'] as String,
              accountID: (row.data['account_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              accountName:
                  (row.data['account_name'] as String?) ?? 'Untitled Account',
              accountType: (row.data['account_type'] as String?) ?? 'checking',
              balance: (row.data['balance'] as num?)?.toDouble() ?? 0.0,
              currency: CurrencyType.values.firstWhere(
                (e) => e.name == row.data['currency'],
                orElse: () => CurrencyType.USD,
              ),
              isPrimary:
                  (row.data['is_primary'] == 1 ||
                  row.data['is_primary'] == true),
              isActive:
                  (row.data['is_active'] == 1 || row.data['is_active'] == true),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  // Assets
  Future<int> createAsset(AssetsTableCompanion asset) =>
      into(assetsTable).insert(asset);
  Stream<List<AssetData>> watchAssets(int personId) {
    return customSelect(
      'SELECT * FROM assets WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {assetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => AssetData(
              id: row.data['id'] as String,
              assetID: (row.data['asset_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              assetName:
                  (row.data['asset_name'] as String?) ?? 'Untitled Asset',
              assetCategory: (row.data['asset_category'] as String?) ?? 'other',
              purchaseDate: row.data['purchase_date'] != null
                  ? DateTime.tryParse(row.data['purchase_date'].toString())
                  : null,
              purchasePrice: (row.data['purchase_price'] as num?)?.toDouble(),
              currentEstimatedValue:
                  (row.data['current_estimated_value'] as num?)?.toDouble(),
              currency: CurrencyType.values.firstWhere(
                (e) => e.name == row.data['currency'],
                orElse: () => CurrencyType.USD,
              ),
              condition: (row.data['condition'] as String?) ?? 'good',
              location: row.data['location'] as String?,
              notes: row.data['notes'] as String?,
              isInsured:
                  (row.data['is_insured'] == 1 ||
                  row.data['is_insured'] == true),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  // Transactions
  Future<int> insertTransaction(TransactionsTableCompanion txn) =>
      into(transactionsTable).insert(txn);

  Future<void> deleteTransaction(int transactionID) => (delete(
    transactionsTable,
  )..where((t) => t.transactionID.equals(transactionID))).go();

  Stream<List<TransactionData>> watchAllTransactions(int personId) {
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? ORDER BY transaction_date DESC',
      variables: [Variable.withInt(personId)],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  Stream<List<TransactionData>> watchTransactionsByType(
    int personId,
    String type,
  ) {
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? AND type = ? ORDER BY transaction_date DESC',
      variables: [Variable.withInt(personId), Variable.withString(type)],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  Stream<List<TransactionData>> watchMonthlyTransactions(
    int personId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    // SQLite stores dates as ISO8601 strings usually, drifting it via custom requires string mapping
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? AND transaction_date >= ? AND transaction_date <= ? ORDER BY transaction_date DESC',
      variables: [
        Variable.withInt(personId),
        Variable.withString(start.toIso8601String()),
        Variable.withString(end.toIso8601String()),
      ],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  List<TransactionData> _mapTransactions(List<QueryRow> rows, int personId) {
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => TransactionData(
            id: row.data['id'] as String,
            transactionID: (row.data['transaction_id'] as int?) ?? 0,
            personID: (row.data['person_id'] as int?) ?? personId,
            category: (row.data['category'] as String?) ?? 'uncategorized',
            type: (row.data['type'] as String?) ?? 'expense',
            amount: (row.data['amount'] as num?)?.toDouble() ?? 0.0,
            description: row.data['description'] as String?,
            transactionDate: row.data['transaction_date'] != null
                ? DateTime.tryParse(row.data['transaction_date'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            createdAt: row.data['created_at'] != null
                ? DateTime.tryParse(row.data['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            projectID: row.data['project_id'] as int?,
          ),
        )
        .toList();
  }
}

// 4.6 GrowthDAO
@DriftAccessor(tables: [GoalsTable, HabitsTable, SkillsTable])
class GrowthDAO extends DatabaseAccessor<AppDatabase> with _$GrowthDAOMixin {
  GrowthDAO(super.db);

  Future<int> createGoal(GoalsTableCompanion goal) =>
      into(goalsTable).insert(goal);
  Stream<List<GoalData>> watchGoals(int personId) {
    return customSelect(
      'SELECT * FROM goals WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: (row.data['goal_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              title: (row.data['title'] as String?) ?? 'Untitled Task',
              description: row.data['description'] as String?,
              category: (row.data['category'] as String?) ?? 'personal',
              priority: (row.data['priority'] as int?) ?? 3,
              status: (row.data['status'] as String?) ?? 'active',
              targetDate: row.data['target_date'] != null
                  ? DateTime.tryParse(row.data['target_date'].toString())
                  : null,
              completionDate: row.data['completion_date'] != null
                  ? DateTime.tryParse(row.data['completion_date'].toString())
                  : null,
              progressPercentage:
                  (row.data['progress_percentage'] as int?) ?? 0,
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              projectID: row.data['project_id'] as int?,
            ),
          )
          .toList();
    });
  }

  Stream<List<GoalData>> watchGoalsByProject(int projectID) {
    return customSelect(
      'SELECT * FROM goals WHERE project_id = ?',
      variables: [Variable.withInt(projectID)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: (row.data['goal_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? 0,
              title: (row.data['title'] as String?) ?? 'Untitled Task',
              description: row.data['description'] as String?,
              category: (row.data['category'] as String?) ?? 'personal',
              priority: (row.data['priority'] as int?) ?? 3,
              status: (row.data['status'] as String?) ?? 'active',
              targetDate: row.data['target_date'] != null
                  ? DateTime.tryParse(row.data['target_date'].toString())
                  : null,
              completionDate: row.data['completion_date'] != null
                  ? DateTime.tryParse(row.data['completion_date'].toString())
                  : null,
              progressPercentage:
                  (row.data['progress_percentage'] as int?) ?? 0,
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              projectID: row.data['project_id'] as int?,
            ),
          )
          .toList();
    });
  }

  Future<void> updateGoalStatusByUuid(String id, String status) async {
    await (update(goalsTable)..where((t) => t.id.equals(id))).write(
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

  Future<void> updateGoalStatusByIntId(int goalID, String status) async {
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
  Stream<List<HabitData>> watchHabits(int personId) {
    return customSelect(
      'SELECT * FROM habits WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {habitsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => HabitData(
              id: row.data['id'] as String,
              habitID: (row.data['habit_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              goalID: row.data['goal_id'] as int?,
              habitName: (row.data['habit_name'] as String?) ?? 'Untitled',
              description: row.data['description'] as String?,
              frequency: (row.data['frequency'] as String?) ?? 'daily',
              frequencyDetails: row.data['frequency_details'] as String?,
              targetCount: (row.data['target_count'] as int?) ?? 1,
              isActive:
                  (row.data['is_active'] == 1 || row.data['is_active'] == true),
              startedDate: row.data['started_date'] != null
                  ? DateTime.tryParse(row.data['started_date'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  // Skills
  Future<int> createSkill(SkillsTableCompanion skill) =>
      into(skillsTable).insert(skill);
  Stream<List<SkillData>> watchSkills(int personId) {
    return customSelect(
      'SELECT * FROM skills WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {skillsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => SkillData(
              id: row.data['id'] as String,
              skillID: (row.data['skill_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              skillName: (row.data['skill_name'] as String?) ?? 'Untitled',
              skillCategory: row.data['skill_category'] as String?,
              proficiencyLevel: SkillLevel.values.firstWhere(
                (e) => e.name == row.data['proficiency_level'],
                orElse: () => SkillLevel.beginner,
              ),
              yearsOfExperience: (row.data['years_of_experience'] as int?) ?? 0,
              description: row.data['description'] as String?,
              isFeatured:
                  (row.data['is_featured'] == 1 ||
                  row.data['is_featured'] == true),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }
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

  Stream<List<PersonWidgetData>> watchWidgets(int personId) {
    return customSelect(
      'SELECT * FROM person_widgets WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {personWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => PersonWidgetData(
              id: row.data['id'] as String,
              personWidgetID: (row.data['person_widget_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as int?) ?? personId,
              widgetName: (row.data['widget_name'] as String?) ?? '',
              widgetType: (row.data['widget_type'] as String?) ?? '',
              configuration: (row.data['configuration'] as String?) ?? '{}',
              displayOrder: (row.data['display_order'] as int?) ?? 0,
              isActive: (row.data['is_active'] as int?) == 1,
              role: UserRole.values.firstWhere(
                (e) => e.name == (row.data['role'] as String? ?? 'admin'),
                orElse: () => UserRole.admin,
              ),
              createdAt: row.data['created_at'] != null
                  ? DateTime.tryParse(row.data['created_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
              updatedAt: row.data['updated_at'] != null
                  ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                        DateTime.now()
                  : DateTime.now(),
            ),
          )
          .toList();
    });
  }

  Future<List<PersonWidgetData>> getAllWidgets(int personId) async {
    final rows = await customSelect(
      'SELECT * FROM person_widgets WHERE person_id = ?',
      variables: [Variable.withInt(personId)],
      readsFrom: {personWidgetsTable},
    ).get();
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => PersonWidgetData(
            id: row.data['id'] as String,
            personWidgetID: (row.data['person_widget_id'] as int?) ?? 0,
            personID: (row.data['person_id'] as int?) ?? personId,
            widgetName: (row.data['widget_name'] as String?) ?? '',
            widgetType: (row.data['widget_type'] as String?) ?? '',
            configuration: (row.data['configuration'] as String?) ?? '{}',
            displayOrder: (row.data['display_order'] as int?) ?? 0,
            isActive: (row.data['is_active'] as int?) == 1,
            role: UserRole.values.firstWhere(
              (e) => e.name == (row.data['role'] as String? ?? 'admin'),
              orElse: () => UserRole.admin,
            ),
            createdAt: row.data['created_at'] != null
                ? DateTime.tryParse(row.data['created_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
            updatedAt: row.data['updated_at'] != null
                ? DateTime.tryParse(row.data['updated_at'].toString()) ??
                      DateTime.now()
                : DateTime.now(),
          ),
        )
        .toList();
  }

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
            id: IDGen.generateUuid(),
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
        SessionTableCompanion.insert(
          id: IDGen.generateUuid(),
          jwt: jwt,
          username: Value(username),
        ),
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
  @override
  String get tableName => 'focus_sessions';
  TextColumn get id => text()();
  IntColumn get sessionID =>
      integer().withDefault(const Constant(0)).named('session_id')();
  IntColumn get personID => integer()
      .references(PersonsTable, #personID, onDelete: KeyAction.cascade)
      .named('person_id')();
  IntColumn get projectID => integer()
      .nullable()
      .references(ProjectsTable, #projectID, onDelete: KeyAction.cascade)
      .named('project_id')();
  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().nullable().named('end_time')();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .named('status')(); // 'completed', 'interrupted'
  IntColumn get taskID => integer()
      .nullable()
      .references(GoalsTable, #goalID, onDelete: KeyAction.cascade)
      .named('task_id')();
  TextColumn get notes => text().nullable().named('notes')();

  @override
  Set<Column> get primaryKey => {id};
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
  @override
  String get tableName => 'quotes';
  TextColumn get id => text()();
  IntColumn get quoteID => integer().withDefault(const Constant(0))();
  TextColumn get content => text()();
  TextColumn get author => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
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

@DriftAccessor(tables: [QuestsTable])
class QuestDAO extends DatabaseAccessor<AppDatabase> with _$QuestDAOMixin {
  QuestDAO(super.db);

  Future<int> insertQuest(QuestsTableCompanion entry) =>
      into(questsTable).insert(entry);

  Future<bool> updateQuest(QuestData entry) =>
      update(questsTable).replace(entry);

  Future<int> deleteQuest(int id) =>
      (delete(questsTable)..where((t) => t.questID.equals(id))).go();

  Stream<List<QuestData>> watchActiveQuests() {
    return (select(
      questsTable,
    )..where((t) => t.isCompleted.equals(false))).watch();
  }

  Future<List<QuestData>> getAllQuests() => select(questsTable).get();

  Future<void> updateQuestProgress(int id, double value) async {
    final existing = await (select(
      questsTable,
    )..where((t) => t.questID.equals(id))).getSingleOrNull();

    if (existing != null) {
      final newValue = value;
      final isNowCompleted = newValue >= existing.targetValue;
      await (update(questsTable)..where((t) => t.questID.equals(id))).write(
        QuestsTableCompanion(
          currentValue: Value(newValue),
          isCompleted: Value(isNowCompleted),
        ),
      );
    }
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
    QuestsTable,
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
    QuestDAO,
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
  int get schemaVersion => 23; // Increment schema version to 23

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
              "ALTER TABLE focus_sessions ADD COLUMN taskID INTEGER REFERENCES goals(goalID) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Error adding taskID column to focus_sessions: $e');
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
              'ALTER TABLE project_notes ADD COLUMN personID INTEGER REFERENCES persons(personID) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE project_notes ADD COLUMN projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE goals ADD COLUMN projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE',
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
              'DELETE FROM health_metrics WHERE metricID NOT IN (SELECT MIN(metricID) FROM health_metrics GROUP BY personID, date)',
            );
          } catch (e) {
            print('Error deleting duplicates: $e');
          }

          // Add unique index (this mimics uniqueKeys logic for the DB engine)
          try {
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_health_metrics_unique ON health_metrics (personID, date)',
            );
          } catch (e) {
            print('Error creating unique index: $e');
          }
        }

        if (from < 20) {
          // Duplicate cleanup for scores
          try {
            print('Drift: Cleaning up duplicate scores for version 20');
            await customStatement(
              'DELETE FROM scores WHERE scoreID NOT IN (SELECT MIN(scoreID) FROM scores GROUP BY personID)',
            );

            // Create the unique index if needed (SQLite table constraints are hard to add via ALTER)
            // But with .unique() in the table definition and a version bump, Drift's build_runner might handle it
            // or we manually ensure it here.
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_scores_person_unique ON scores (personID)',
            );
          } catch (e) {
            print('Drift: Error in version 20 migration: $e');
          }
        }

        if (from < 11) {
          try {
            await customStatement(
              "ALTER TABLE persons ADD COLUMN relationship TEXT DEFAULT 'none';",
            );
          } catch (e) {
            print('Error adding relationship column: $e');
          }
        }
        if (from < 12) {
          try {
            await customStatement(
              "ALTER TABLE persons ADD COLUMN affection INTEGER DEFAULT 0;",
            );
          } catch (e) {
            print('Error adding affection column: $e');
          }
        }
        if (from < 13) {
          try {
            await customStatement(
              "ALTER TABLE projects ADD COLUMN category TEXT;",
            );
          } catch (e) {
            print('Error adding category column to projects: $e');
          }
        }
        if (from < 14) {
          try {
            await customStatement(
              "ALTER TABLE transactions ADD COLUMN projectID INTEGER REFERENCES projects(projectID) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Error adding projectID column to transactions: $e');
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
              "ALTER TABLE health_metrics ADD COLUMN focus_minutes INTEGER DEFAULT 0;",
            );
          } catch (e) {
            print('Error adding focus_minutes column to health_metrics: $e');
          }
        }
        if (from < 22) {
          await m.createTable(questsTable);
        }
        if (from < 23) {
          // Comprehensive migration to add 'id' column to all tables if it's missing.
          // This is critical for existing users after we made 'id' non-nullable.
          final tableNames = [
            'internal_widgets',
            'external_widgets',
            'themes',
            'project_notes',
            'projects',
            'persons',
            'email_addresses',
            'user_accounts',
            'profiles',
            'skills',
            'financial_accounts',
            'assets',
            'goals',
            'habits',
            'blog_posts',
            'person_widgets',
            'health_metrics',
            'meals',
            'days',
            'scores',
            'transactions',
            'focus_sessions',
            'custom_notifications',
            'quotes',
            'water_logs',
            'sleep_logs',
            'exercise_logs',
            'quests',
          ];

          for (final tableName in tableNames) {
            try {
              await customStatement(
                'ALTER TABLE $tableName ADD COLUMN id TEXT;',
              );
            } catch (e) {
              print('Drift: Error adding id column to $tableName: $e');
            }
          }
        }
      },
      beforeOpen: (details) async {
        print(
          "Drift: beforeOpen triggered. Version: ${details.versionBefore} -> ${details.versionNow}",
        );

        // 1. persons cleanup
        try {
          await customStatement(
            "ALTER TABLE persons ADD COLUMN affection INTEGER DEFAULT 0;",
          );
        } catch (_) {}
        try {
          await customStatement(
            "UPDATE persons SET affection = 0 WHERE affection IS NULL;",
          );
        } catch (_) {}

        // 2. custom_notifications cleanup (Fixes NULL check operator error)
        try {
          await customStatement(
            "UPDATE custom_notifications SET repeat_frequency = 'none' WHERE repeat_frequency IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications SET is_enabled = 1 WHERE is_enabled IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications SET title = 'Reminder' WHERE title IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications SET content = '' WHERE content IS NULL;",
          );
        } catch (_) {}
      },
    );
  }
}
