// 1. Core Drift and Platform Imports
import 'package:drift/drift.dart';
import 'package:drift/native.dart'; // For NativeDatabase on mobile/desktop
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/initial_layer/ThemeLayer/CurrentThemeData.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonalInformationProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/ProfileProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:io'; // For File
import 'dart:math'; // For Random() used in DAOs
import 'dart:convert';
import 'package:path_provider/path_provider.dart'; // For finding the database path
import 'package:path/path.dart' as p; // For path joining
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';

// 2. Part Directives (Crucial for generated code)
// NOTE: You must run `flutter pub run build_runner build` to generate this file.
part 'Database.g.dart';
// NOTE: I'm using 'app_database.g.dart' as the standard naming convention.

// --- 3. Table Definitions ---

class DateTimeConverter extends TypeConverter<DateTime, String> {
  const DateTimeConverter();

  @override
  DateTime fromSql(String fromDb) => DateTime.parse(fromDb).toLocal();

  @override
  String toSql(DateTime value) => value.toUtc().toIso8601String();
}

class DateTimeUTCConverter extends TypeConverter<DateTime, DateTime> {
  const DateTimeUTCConverter();

  @override
  DateTime fromSql(DateTime fromDb) {
    // PowerSync might pass a String or int even if the column is DateTime
    final dynamic value = fromDb;
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.parse(value).toLocal();
    if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value).toLocal();
    }
    return DateTime.now(); // Fallback for unexpected types
  }

  @override
  DateTime toSql(DateTime value) => value.toUtc();
}

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
class InternalWidgetsTable extends Table {
  @override
  String get tableName => 'internal_widgets';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get widgetID => text().nullable().named("widget_id")();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();

  // These are currently nullable in your DB
  TextColumn get name =>
      text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get url =>
      text().withLength(min: 1, max: 100).named("url").nullable()();

  TextColumn get dateAdded => text().named("date_added").nullable()();

  TextColumn get imageUrl => text().named("image_url").nullable()();
  TextColumn get alias => text().named("alias").nullable()();
  TextColumn get scope => text().named("scope").nullable()(); // Added scope

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

  Stream<List<InternalWidgetData>> watchScopedWidgets(
    String personID,
    String scope,
  ) {
    return (select(internalWidgetsTable)..where(
          (tbl) =>
              (tbl.personID.equals(personID) | tbl.personID.isNull()) &
              tbl.scope.equals(scope),
        ))
        .watch();
  }

  Stream<List<InternalWidgetData>> watchAllWidgets(String personID) {
    return (select(internalWidgetsTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .watch();
  }

  Future<void> deleteScopedWidgets(String personID, String scope) {
    return (delete(internalWidgetsTable)..where(
          (tbl) => tbl.personID.equals(personID) & tbl.scope.equals(scope),
        ))
        .go();
  }

  // void insertInternalWidget(){
  Future<int> insertInternalWidget({
    String? id,
    String? widgetID,
    required String personID,
    required String name,
    required String alias,
    required String url,
    String? imageUrl,
    String? scope,
  }) {
    return into(internalWidgetsTable).insert(
      InternalWidgetsTableCompanion.insert(
        id: id ?? IDGen.UUIDV7(),
        widgetID: Value(widgetID),
        personID: Value(personID),
        name: Value(name),
        alias: Value(alias),
        url: Value(url),
        imageUrl: Value(imageUrl ?? "assets/internalwidget/default_plugin.png"),
        scope: Value(scope),
        dateAdded: Value(DateTime.now().toIso8601String()),
      ),
    );
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get widgetID => text().nullable().named("widget_id")();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get organizationId => text().nullable()();
  TextColumn get themeID => text().nullable().named('theme_id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get alias =>
      text().withLength(min: 1, max: 50).unique().named('alias')();
  TextColumn get json => text().named('json_content')();
  TextColumn get author => text().withLength(min: 1, max: 50).named('author')();
  TextColumn get addedDate =>
      text().map(const DateTimeConverter()).named('added_date')();

  @override
  Set<Column> get primaryKey => {id};
}

// 3.3 ProjectNotesTable Definition
@DataClassName('ProjectNoteData')
class ProjectNotesTable extends Table {
  @override
  String get tableName => 'project_notes';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get noteID => text().nullable().named('note_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content =>
      text().named('content')(); // JSON string of the note content
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();
  TextColumn get projectID => text()
      .nullable()
      .references(ProjectsTable, #id, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectData')
class ProjectsTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category =>
      text().nullable().named('category')(); // Added category column
  TextColumn get color => text().nullable().named('color')();
  IntColumn get status =>
      integer().withDefault(const Constant(0)).named('status')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

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

@DataClassName('OrganizationData')
class OrganizationsTable extends Table {
  @override
  String get tableName => 'organizations';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get domain => text().nullable().named('domain')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PersonData')
class PersonsTable extends Table {
  @override
  String get tableName => 'persons';
  TextColumn get id => text()(); // PowerSync UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get firstName =>
      text().withLength(min: 1, max: 100).named('first_name')();
  TextColumn get lastName => text().nullable().named('last_name')();
  // Full name can be computed in Dart, not stored
  DateTimeColumn get dateOfBirth => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('date_of_birth')();
  TextColumn get gender =>
      text().nullable().named('gender')(); // 'male', 'female', etc.
  TextColumn get phoneNumber =>
      text().withLength(max: 20).nullable().named('phone_number')();
  TextColumn get profileImageUrl =>
      text().nullable().named('profile_image_url')();
  TextColumn get coverImageUrl => text().nullable().named('cover_image_url')();
  TextColumn get avatarLocalPath =>
      text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath =>
      text().nullable().named('cover_local_path')();
  TextColumn get relationship => text()
      .withDefault(const Constant('none'))
      .named('relationship')(); // 'friend', 'dating', 'family'
  IntColumn get affection =>
      integer().withDefault(const Constant(0)).named('affection')();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

/// Local-only contacts table. NOT synced via PowerSync.
/// Used when importing contacts from the device address book.
@DataClassName('PersonContactData')
class PersonContactsTable extends Table {
  @override
  String get tableName => 'person_contacts';
  TextColumn get id => text()(); // Local UUID
  TextColumn get personID => text().nullable().named(
    'person_id',
  )(); // Owner person ID (the logged-in user)
  TextColumn get firstName =>
      text().withLength(min: 1, max: 100).named('first_name')();
  TextColumn get lastName => text().nullable().named('last_name')();
  TextColumn get phoneNumber =>
      text().withLength(max: 20).nullable().named('phone_number')();
  TextColumn get profileImageUrl =>
      text().nullable().named('profile_image_url')();
  TextColumn get relationship =>
      text().withDefault(const Constant('friend')).named('relationship')();
  IntColumn get affection =>
      integer().withDefault(const Constant(0)).named('affection')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EmailAddressData')
class EmailAddressesTable extends Table {
  @override
  String get tableName => 'email_addresses';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get emailAddressID =>
      text().nullable().named('email_address_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get verifiedAt => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('verified_at')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserAccountData')
class UserAccountsTable extends Table {
  @override
  String get tableName => 'user_accounts';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')();
  TextColumn get username => text()
      .withLength(min: 3, max: 50)
      .nullable()
      .unique()
      .named('username')();
  TextColumn get passwordHash => text().nullable().named('password_hash')();
  TextColumn get primaryEmailID => text()
      .nullable()
      .references(EmailAddressesTable, #id)
      .named('primary_email_id')();
  TextColumn get role =>
      textEnum<UserRole>().withDefault(const Constant('user')).named('role')();
  BoolColumn get isLocked => boolean()
      .nullable()
      .withDefault(const Constant(false))
      .named('is_locked')();
  IntColumn get failedLoginAttempts => integer()
      .nullable()
      .withDefault(const Constant(0))
      .named('failed_login_attempts')();
  DateTimeColumn get lastLoginAt => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('last_login_at')();
  DateTimeColumn get passwordChangedAt => dateTime()
      .nullable()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('password_changed_at')();
  DateTimeColumn get createdAt => dateTime()
      .nullable()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .nullable()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProfileData')
class ProfilesTable extends Table {
  @override
  String get tableName => 'profiles';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get profileID => text().nullable().named('profile_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')();
  TextColumn get bio => text().nullable().named('bio')();
  TextColumn get occupation => text().nullable().named('occupation')();
  TextColumn get educationLevel => text().nullable().named('education_level')();
  TextColumn get location => text().nullable().named('location')();
  TextColumn get websiteUrl => text().nullable().named('website_url')();
  TextColumn get linkedinUrl => text().nullable().named('linkedin_url')();
  TextColumn get githubUrl => text().nullable().named('github_url')();
  TextColumn get coverImageUrl => text().nullable().named('cover_image_url')();
  TextColumn get avatarLocalPath =>
      text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath =>
      text().nullable().named('cover_local_path')();
  TextColumn get timezone => text().nullable().named('timezone')();
  TextColumn get preferredLanguage =>
      text().nullable().named('preferred_language')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CVAddressData')
class CVAddressesTable extends Table {
  @override
  String get tableName => 'detail_information';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get cvAddressID => text().nullable().named('cv_address_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  TextColumn get coverImageUrl => text().nullable().named('cover_image_url')();
  TextColumn get avatarLocalPath =>
      text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath =>
      text().nullable().named('cover_local_path')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SkillData')
class SkillsTable extends Table {
  @override
  String get tableName => 'skills';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get skillID => text().nullable().named('skill_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinancialAccountData')
class FinancialAccountsTable extends Table {
  @override
  String get tableName => 'financial_accounts';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AssetData')
class AssetsTable extends Table {
  @override
  String get tableName => 'assets';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get assetID => text().nullable().named('asset_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get transactionID => text().nullable().named('transaction_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  TextColumn get projectID => text()
      .nullable()
      .references(ProjectsTable, #id, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalData')
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get goalID => text().nullable().named('goal_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  DateTimeColumn get targetDate => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('target_date')();
  DateTimeColumn get completionDate => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('completion_date')();
  IntColumn get progressPercentage =>
      integer().withDefault(const Constant(0)).named('progress_percentage')();
  // Cột lưu dưới dạng ISO 8601 hoặc Unix timestamp tùy cấu hình Drift
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime) // Sử dụng hàm có sẵn của SQL
      .named('created_at')();

  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();
  TextColumn get projectID => text()
      .nullable()
      .references(ProjectsTable, #id, onDelete: KeyAction.cascade)
      .named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("ScoreLocalData")
class ScoresTable extends Table {
  @override
  String get tableName => 'scores';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get scoreID => text().named('score_id').nullable()();
  TextColumn get personID => text()
      .nullable()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .unique()
      .named('person_id')();
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
  RealColumn get penaltyScore => real()
      .withDefault(const Constant(0.0))
      .named('penalty_score')
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get habitID => text().nullable().named('habit_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get goalID => text()
      .nullable()
      .references(GoalsTable, #id, onDelete: KeyAction.setNull)
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
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AiAnalysisData')
class AiAnalysisTable extends Table {
  @override
  String get tableName => 'ai_analysis';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.restrict)
      .named('person_id')();
  TextColumn get title => text().named('title')();
  TextColumn get summary => text().nullable().named('summary')();
  TextColumn get detailedAnalysis => text().named('detailed_analysis')();
  TextColumn get status =>
      text().withDefault(const Constant('draft')).named('status')();
  BoolColumn get isFeatured => boolean()
      .nullable()
      .withDefault(const Constant(false))
      .named('is_featured')();
  DateTimeColumn get publishedAt =>
      dateTime().nullable().named('published_at')();
  DateTimeColumn get createdAt => dateTime()
      .nullable()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .nullable()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();
  TextColumn get category => text().nullable().named('category')();
  TextColumn get aiModel => text().nullable().named('ai_model')();
  TextColumn get promptContext => text().nullable().named('prompt_context')();
  RealColumn get sentimentScore => real().nullable().named('sentiment_score')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PersonWidgetData')
class PersonWidgetsTable extends Table {
  @override
  String get tableName => 'person_widgets';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  IntColumn get personWidgetID =>
      integer().nullable().named('person_widget_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get date =>
      dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get steps =>
      integer().withDefault(const Constant(0)).named('steps').nullable()();
  IntColumn get heartRate =>
      integer().withDefault(const Constant(0)).named('heart_rate').nullable()();
  RealColumn get sleepHours =>
      real().withDefault(const Constant(0.0)).named('sleep_hours').nullable()();
  IntColumn get waterGlasses => integer()
      .withDefault(const Constant(0))
      .named('water_glasses')
      .nullable()();
  IntColumn get exerciseMinutes => integer()
      .withDefault(const Constant(0))
      .named('exercise_minutes')
      .nullable()();
  IntColumn get focusMinutes => integer()
      .withDefault(const Constant(0))
      .named('focus_minutes')
      .nullable()();
  RealColumn get weightKg =>
      real().withDefault(const Constant(0.0)).named('weight_kg').nullable()();
  IntColumn get caloriesConsumed => integer()
      .withDefault(const Constant(0))
      .named('calories_consumed')
      .nullable()();
  IntColumn get caloriesBurned => integer()
      .withDefault(const Constant(0))
      .named('calories_burned')
      .nullable()();
  RealColumn get questPoints => real()
      .withDefault(const Constant(0.0))
      .named('quest_points')
      .nullable()();
  TextColumn get category => text()
      .withDefault(const Constant('General'))
      .named('category')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date, category},
  ];
}

@DataClassName('FinancialMetricsLocal')
class FinancialMetricsTable extends Table {
  @override
  String get tableName => 'financial_metrics';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get date =>
      dateTime().map(const DateTimeUTCConverter()).named('date')();
  RealColumn get totalBalance => real()
      .withDefault(const Constant(0.0))
      .named('total_balance')
      .nullable()();
  RealColumn get totalSavings => real()
      .withDefault(const Constant(0.0))
      .named('total_savings')
      .nullable()();
  RealColumn get totalInvestments => real()
      .withDefault(const Constant(0.0))
      .named('total_investments')
      .nullable()();
  RealColumn get dailyExpenses => real()
      .withDefault(const Constant(0.0))
      .named('daily_expenses')
      .nullable()();
  RealColumn get questPoints => real()
      .withDefault(const Constant(0.0))
      .named('quest_points')
      .nullable()();
  TextColumn get category => text()
      .withDefault(const Constant('General'))
      .named('category')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date, category},
  ];
}

@DataClassName('ProjectMetricsLocal')
class ProjectMetricsTable extends Table {
  @override
  String get tableName => 'project_metrics';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get date =>
      dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get tasksCompleted => integer()
      .withDefault(const Constant(0))
      .named('tasks_completed')
      .nullable()();
  IntColumn get projectsCompleted => integer()
      .withDefault(const Constant(0))
      .named('projects_completed')
      .nullable()();
  IntColumn get focusMinutes => integer()
      .withDefault(const Constant(0))
      .named('focus_minutes')
      .nullable()();
  RealColumn get questPoints => real()
      .withDefault(const Constant(0.0))
      .named('quest_points')
      .nullable()();
  TextColumn get category => text()
      .withDefault(const Constant('General'))
      .named('category')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date, category},
  ];
}

@DataClassName('SocialMetricsLocal')
class SocialMetricsTable extends Table {
  @override
  String get tableName => 'social_metrics';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  DateTimeColumn get date =>
      dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get contactsCount => integer()
      .withDefault(const Constant(0))
      .named('contacts_count')
      .nullable()();
  IntColumn get totalAffection => integer()
      .withDefault(const Constant(0))
      .named('total_affection')
      .nullable()();
  RealColumn get questPoints => real()
      .withDefault(const Constant(0.0))
      .named('quest_points')
      .nullable()();
  TextColumn get category => text()
      .withDefault(const Constant('General'))
      .named('category')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, date, category},
  ];
}

@DataClassName('MealData')
class MealsTable extends Table {
  @override
  String get tableName => 'meals';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get mealID => text().nullable().named("meal_id")();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named("person_id")();
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
  DateTimeColumn get eatenAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named("eaten_at")();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayData')
class DaysTable extends Table {
  @override
  String get tableName => 'days';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get localID => text().nullable().named('local_id')();
  TextColumn get jwt => text().named('jwt')();
  TextColumn get username => text().nullable().named('username')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WaterLogData')
class WaterLogsTable extends Table {
  @override
  String get tableName => 'water_logs';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get logID => text().nullable().named('log_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get logID => text().nullable().named('log_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  IntColumn get logID => integer().nullable().named('log_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
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
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get organizationId => text().nullable()();
  TextColumn get themeID => text().nullable().named('theme_id')();
  TextColumn get themeName => text().named('theme_name')();
  TextColumn get themePath => text().named('theme_path')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomNotificationData')
class CustomNotificationsTable extends Table {
  @override
  String get tableName => 'custom_notifications';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get notificationID => text().nullable().named('notification_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content => text().named('content')();
  DateTimeColumn get scheduledTime =>
      dateTime().map(const DateTimeUTCConverter()).named('scheduled_time')();
  TextColumn get repeatFrequency => text()
      .nullable()
      .withDefault(const Constant('none'))
      .named('repeat_frequency')(); // none, hourly, daily, weekly
  TextColumn get repeatDays => text().nullable().named(
    'repeat_days',
  )(); // Comma-separated: 1,3,5 (Mon, Wed, Fri)
  TextColumn get category => text()
      .withDefault(const Constant('General'))
      .named('category')(); // Health, Finance, Social, Projects, General
  TextColumn get priority => text()
      .withDefault(const Constant('Normal'))
      .named('priority')(); // Low, Normal, High, Urgent
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get icon => text().nullable().named('icon')();
  BoolColumn get isEnabled =>
      boolean().withDefault(const Constant(true)).named('is_enabled')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuestData')
class QuestsTable extends Table {
  @override
  String get tableName => 'quests';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get title =>
      text().withLength(min: 1, max: 200).nullable().named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get type => text()
      .nullable()
      .withDefault(const Constant('daily'))
      .named('type')(); // daily, weekly, permanent
  RealColumn get targetValue => real()
      .nullable()
      .withDefault(const Constant(0.0))
      .named('target_value')();
  RealColumn get currentValue => real()
      .nullable()
      .withDefault(const Constant(0.0))
      .named('current_value')();
  TextColumn get category => text()
      .nullable()
      .withDefault(const Constant('health'))
      .named('category')();
  IntColumn get rewardExp => integer()
      .nullable()
      .withDefault(const Constant(10))
      .named('reward_exp')();
  BoolColumn get isCompleted => boolean()
      .nullable()
      .withDefault(const Constant(false))
      .named('is_completed')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  IntColumn get penaltyScore => integer()
      .nullable()
      .withDefault(const Constant(0))
      .named('penalty_score')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [ThemeTable])
class ThemeDAO extends DatabaseAccessor<AppDatabase> with _$ThemeDAOMixin {
  ThemeDAO(super.db);

  // Theme preference is stored in SharedPreferences to keep it local-only.
  // The themes_config Drift table is kept for schema compatibility but is
  // no longer the source of truth — it is excluded from PowerSync sync so
  // PowerSync can never wipe the user's saved preference.

  static const String _themeKey = 'current_theme_path';
  static const String _defaultThemePath = 'assets/DefaultTheme.json';

  Future<void> saveCurrentTheme(CurrentThemeData theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.themePath);
  }

  /// Returns a lightweight holder with just the saved path.
  Future<CurrentThemeData> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_themeKey) ?? _defaultThemePath;
    return CurrentThemeData(themePath: path);
  }

  /// No-op kept for call-site compatibility.
  Future<void> insertTheme({
    required String themeName,
    required String themePath,
  }) async {
    // Theme is now stored in SharedPreferences; nothing to insert in DB.
  }
}

// --- 4. DAO Definitions ---
//remove admin
@DriftAccessor(tables: [PersonsTable])
class PersonDAO extends DatabaseAccessor<AppDatabase> with _$PersonDAOMixin {
  PersonDAO(super.db);
  Stream<List<PersonData>> getAllPersons() {
    return select(personsTable).watch();
  }

  Future<PersonData?> getPersonByID(String id) async {
    final query = select(personsTable)..where((t) => t.id.equals(id));
    return query.getSingleOrNull();
  }
}

@DriftAccessor(tables: [ScoresTable, PersonsTable])
class ScoreDAO extends DatabaseAccessor<AppDatabase> with _$ScoreDAOMixin {
  ScoreDAO(super.db);

  Stream<List<GlobalRankingEntry>> watchGlobalRanking() {
    final query = select(scoresTable).join([
      innerJoin(personsTable, personsTable.id.equalsExp(scoresTable.personID)),
    ]);

    return query.watch().map((rows) {
      final entries = rows.map((row) {
        return GlobalRankingEntry(
          score: row.readTable(scoresTable),
          person: row.readTable(personsTable),
        );
      }).toList();

      // Sort by total aggregated score
      entries.sort((a, b) => b.totalScore.compareTo(a.totalScore));
      return entries;
    });
  }

  Future<int> insertOrUpdateScore(ScoreLocalData score) {
    return into(scoresTable).insertOnConflictUpdate(score);
  }

  Future<ScoreLocalData?> getScoreByPersonID(String personID) {
    return (select(scoresTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .get()
        .then((list) => list.firstOrNull);
  }

  Stream<ScoreLocalData?> watchScoreByPersonID(String personID) {
    return (select(scoresTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .watchSingleOrNull();
  }

  Future<void> incrementCareerScore(String personID, double points) async {
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
        // Use deterministic ID for score record per person
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            careerGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateCareerScore(String personID, double score) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            careerGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            careerGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> incrementSocialScore(String personID, double points) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.personID.equals(personID))).write(
          ScoresTableCompanion(
            socialGlobalScore: Value(
              (existing.socialGlobalScore ?? 0.0) + points,
            ),
            updatedAt: Value(DateTime.now()),
          ),
        );
      } else {
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            socialGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateSocialScore(String personID, double score) async {
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
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            socialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateFinancialScore(String personID, double score) async {
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
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            financialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> incrementHealthScore(String personID, double points) async {
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
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
            personID: Value(personID),
            healthGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateHealthScore(String personID, double score) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        // Only update if the new score is higher or significantly different
        // This prevents a device with stale/unsynced data from zeroing out the score
        if (score > (existing.healthGlobalScore ?? 0.0)) {
          await (update(
            scoresTable,
          )..where((t) => t.personID.equals(personID))).write(
            ScoresTableCompanion(
              healthGlobalScore: Value(score),
              updatedAt: Value(DateTime.now()),
            ),
          );
        }
      } else {
        final deterministicId = IDGen.generateDeterministicUuid(
          personID,
          "score",
        );
        await into(scoresTable).insert(
          ScoresTableCompanion.insert(
            id: deterministicId,
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
    required String personID,
  }) {
    final entry = ExternalWidgetsTableCompanion.insert(
      id: IDGen.UUIDV7(),
      personID: Value(personID),
      name: Value(
        externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
      ),
      alias: Value(_generateRandomAlias(8)),
      widgetID: Value(IDGen.UUIDV7()),
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

  Future<int> deleteWidget(String id) async {
    return (delete(
      externalWidgetsTable,
    )..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> renameExternalWidget(String widgetID, String newName) {
    return (update(externalWidgetsTable)
          ..where((tbl) => tbl.widgetID.equals(widgetID)))
        .write(ExternalWidgetsTableCompanion(name: Value(newName)));
  }

  Stream<List<ExternalWidgetData>> watchAllWidgets(String personID) {
    return customSelect(
      'SELECT * FROM external_widgets WHERE person_id = ? OR person_id IS NULL',
      variables: [Variable.withString(personID)],
      readsFrom: {externalWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => ExternalWidgetData(
              id: row.data['id']?.toString() ?? '',
              tenantID: row.data['tenant_id']?.toString(),
              personID: row.data['person_id']?.toString(),
              widgetID: row.data['widget_id']?.toString(),
              name: row.data['name']?.toString(),
              alias: row.data['alias']?.toString(),
              protocol: row.data['protocol']?.toString(),
              host: row.data['host']?.toString(),
              url: row.data['url']?.toString(),
              imageUrl: row.data['image_url']?.toString(),
              dateAdded: row.data['date_added']?.toString(),
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
      id: IDGen.UUIDV7(),
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

  Future<String> insertNote({
    required String title,
    required String content,
    String? projectID,
    String? personID,
  }) async {
    final uuid = IDGen.UUIDV7();
    into(projectNotesTable).insert(
      ProjectNotesTableCompanion.insert(
        id: uuid,
        title: title,
        content: content,
        projectID: Value(projectID),
        personID: Value(personID),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    return uuid;
  }

  Future<bool> updateNote(ProjectNoteData note) {
    return update(
      projectNotesTable,
    ).replace(note.copyWith(updatedAt: DateTime.now()));
  }

  Future<int> deleteNote(String id) {
    return (delete(projectNotesTable)..where((tbl) => tbl.id.equals(id))).go();
  }

  Stream<List<ProjectNoteData>> watchAllNotes(String personID) {
    return (select(projectNotesTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .watch();
  }

  Stream<List<ProjectNoteData>> watchRecentNotes(String personID, int limit) {
    return (select(projectNotesTable)
          ..where(
            (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Stream<List<ProjectNoteData>> watchNotesByProject(String projectID) {
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

  Future<ProjectNoteData?> getNoteById(String id) {
    return (select(
      projectNotesTable,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }
}

@DriftAccessor(tables: [ProjectsTable])
class ProjectsDAO extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDAOMixin {
  ProjectsDAO(super.db);

  Future<int> insertProject(ProjectsTableCompanion project) =>
      into(projectsTable).insert(project);

  Stream<List<ProjectData>> watchAllProjects(String personID) {
    return customSelect(
      'SELECT * FROM projects WHERE person_id = ?',
      variables: [Variable.withString(personID)],
      readsFrom: {projectsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => ProjectData(
              id: row.data['id'] as String,
              projectID: row.data['project_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personID,
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

  Future<int> deleteProjectByProjectId(String projectID) =>
      (delete(projectsTable)..where((t) => t.projectID.equals(projectID))).go();

  Future<ProjectData?> getProjectByUuid(String id) =>
      (select(projectsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<ProjectData?> getProjectByProjectId(String projectID) => (select(
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
    PersonContactsTable,
  ],
)
class PersonManagementDAO extends DatabaseAccessor<AppDatabase>
    with _$PersonManagementDAOMixin {
  PersonManagementDAO(super.db);

  // Persons
  Future<String> createPerson(
    PersonProtocol person, {
    String? id,
    String? relationship,
  }) async {
    final String newUuid = id ?? IDGen.UUIDV7();

    final companion = PersonsTableCompanion.insert(
      id: newUuid, // Use the provided or generated UUID
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
    await into(personsTable).insert(companion);
    // print("person ID");
    if (relationship != null) {
      await customUpdate(
        'UPDATE persons SET relationship = ? WHERE id = ?',
        variables: [
          Variable.withString(relationship),
          Variable.withString(newUuid),
        ],
        updates: {personsTable},
        updateKind: UpdateKind.update,
      );
    }
    return newUuid;
  }

  Future<int> createMailAddress(EmailAddressProtocol email) {
    final companion = EmailAddressesTableCompanion.insert(
      id: IDGen.UUIDV7(),
      emailAddressID: Value(email.emailAddressID),
      emailAddress: email.emailAddress,
      personID: Value(email.personID),
      emailType: Value(email.emailType),
      isPrimary: Value(email.isPrimary),
      status: Value(email.status),
      verifiedAt: Value(email.verifiedAt),
      createdAt: Value(DateTime.now()),
      // updatedAt: Value(DateTime.now()),
    );
    return into(emailAddressesTable).insert(companion);
  }

  Future<PersonData?> getPersonById(String? personID) async {
    // Check for null or empty string immediately
    if (personID == null || personID.isEmpty) {
      return null;
    }

    return (select(
      personsTable,
    )..where((t) => t.id.equals(personID))).getSingleOrNull();
  }

  Future<int> deletePerson(String personID) {
    return (delete(personsTable)..where((t) => t.id.equals(personID))).go();
  }

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

  Stream<List<SocialContact>> watchTopRankedContacts({int limit = 10}) {
    return customSelect(
      "SELECT * FROM persons WHERE relationship != 'none' AND relationship != 'me' ORDER BY affection DESC LIMIT ?",
      variables: [Variable.withInt(limit)],
      readsFrom: {personsTable},
    ).watch().map((rows) {
      return rows.where((row) => row.data['id'] != null).map((row) {
        final person = PersonData(
          id: row.data['id'] as String,
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

  Stream<int> watchTotalAffection() {
    return customSelect(
      "SELECT SUM(affection) as total FROM persons WHERE relationship != 'none' AND relationship != 'me'",
      readsFrom: {personsTable},
    ).watchSingle().map((row) => row.data['total'] as int? ?? 0);
  }

  Stream<List<SocialContact>> getAllContacts() {
    return (select(personsTable)
          ..where((t) => t.relationship.isNotIn(['none', 'me'])))
        .watch()
        .map((rows) {
          return rows.map((person) {
            return SocialContact(person: person, affection: person.affection);
          }).toList();
        });
  }

  Stream<List<PersonData>> watchAllPersons() {
    return select(personsTable).watch();
  }

  Future<void> increaseAffection(String personId, {int amount = 1}) async {
    await customUpdate(
      'UPDATE persons SET affection = affection + ? WHERE id = ?',
      variables: [Variable.withInt(amount), Variable.withString(personId)],
      updates: {personsTable},
      updateKind: UpdateKind.update,
    );
  }

  Future<void> updateRelationship(String personId, String relationship) async {
    await customUpdate(
      'UPDATE persons SET relationship = ? WHERE id = ?',
      variables: [
        Variable.withString(relationship),
        Variable.withString(personId),
      ],
      updates: {personsTable},
      updateKind: UpdateKind.update,
    );
  }

  // --- Person Contacts (local-only, NOT synced) ---

  /// Create a local-only contact (not synced to Supabase)
  Future<String> createContact({
    required String firstName,
    String? lastName,
    String? phoneNumber,
    String? personID,
    String relationship = 'friend',
  }) async {
    final newId = IDGen.UUIDV7();
    await into(personContactsTable).insert(
      PersonContactsTableCompanion.insert(
        id: newId,
        firstName: firstName,
        lastName: Value(lastName),
        phoneNumber: Value(phoneNumber),
        personID: Value(personID),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    // Set relationship via raw SQL since it may not be in the generated companion
    await customUpdate(
      'UPDATE person_contacts SET relationship = ? WHERE id = ?',
      variables: [
        Variable.withString(relationship),
        Variable.withString(newId),
      ],
      updates: {personContactsTable},
      updateKind: UpdateKind.update,
    );
    return newId;
  }

  /// Watch all local contacts
  Stream<List<PersonContactData>> watchAllContacts() {
    return select(personContactsTable).watch();
  }

  /// Delete a local contact
  Future<int> deleteContact(String contactId) {
    return (delete(
      personContactsTable,
    )..where((t) => t.id.equals(contactId))).go();
  }

  /// Increase affection on a local contact
  Future<void> increaseContactAffection(
    String contactId, {
    int amount = 1,
  }) async {
    await customUpdate(
      'UPDATE person_contacts SET affection = affection + ? WHERE id = ?',
      variables: [Variable.withInt(amount), Variable.withString(contactId)],
      updates: {personContactsTable},
      updateKind: UpdateKind.update,
    );
  }

  /// Update relationship on a local contact
  Future<void> updateContactRelationship(
    String contactId,
    String relationship,
  ) async {
    await customUpdate(
      'UPDATE person_contacts SET relationship = ? WHERE id = ?',
      variables: [
        Variable.withString(relationship),
        Variable.withString(contactId),
      ],
      updates: {personContactsTable},
      updateKind: UpdateKind.update,
    );
  }

  /// Watch all persons AND local contacts merged into a unified PersonData stream.
  /// Local contacts are converted to PersonData objects for UI compatibility.
  Stream<List<PersonData>> watchAllPersonsAndContacts() {
    final personsStream = select(personsTable).watch();
    final contactsStream = select(personContactsTable).watch();

    return Rx.combineLatest2<
      List<PersonData>,
      List<PersonContactData>,
      List<PersonData>
    >(personsStream, contactsStream, (persons, contacts) {
      final contactsAsPersonData = contacts
          .map(
            (c) => PersonData(
              id: c.id,
              firstName: c.firstName,
              lastName: c.lastName,
              relationship: c.relationship,
              affection: c.affection,
              isActive: true,
              createdAt: c.createdAt,
              updatedAt: c.updatedAt,
              phoneNumber: c.phoneNumber,
              profileImageUrl: c.profileImageUrl,
            ),
          )
          .toList();
      return [...persons, ...contactsAsPersonData];
    });
  }

  // Emails
  Future<int> addEmail(EmailAddressProtocol email, {String? overridePersonID}) {
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
      id: IDGen.UUIDV7(),
      emailAddressID: Value(email.emailAddressID),
      personID: Value(email.personID),
      emailAddress: email.emailAddress,
      emailType: Value(email.emailType),
      isPrimary: Value(email.isPrimary),
      status: Value(emailStatus),
      verifiedAt: Value(email.verifiedAt),
      createdAt: Value(DateTime.now()),
    );
    return into(emailAddressesTable).insert(companion);
  }

  Future<List<EmailAddressData>> getEmailsForPerson(String personId) => (select(
    emailAddressesTable,
  )..where((t) => t.personID.equals(personId))).get();

  Future<void> updateEmail(EmailAddressData email) =>
      update(emailAddressesTable).replace(email);

  // Accounts
  Future<int> createAccount(
    UserAccountProtocol account, {
    String? overridePersonID,
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
      id: IDGen.UUIDV7(),
      accountID: Value(account.accountID),
      personID: Value(overridePersonID ?? account.personID),
      username: Value(safeUsername),
      passwordHash: Value(passwordHash ?? ''), // Default empty if not provided
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

  Future<UserAccountData?> getAccountByPersonId(String personId) => (select(
    userAccountsTable,
  )..where((t) => t.personID.equals(personId))).getSingleOrNull();

  Stream<UserAccountData?> watchAccountByPersonId(String personId) => (select(
    userAccountsTable,
  )..where((t) => t.personID.equals(personId))).watchSingleOrNull();

  Future<void> updateAccount(UserAccountData account) =>
      update(userAccountsTable).replace(account);

  // Profiles
  Future<int> createProfile(ProfileProtocol profile, String? overridePersonID) {
    final companion = ProfilesTableCompanion.insert(
      id: IDGen.UUIDV7(),
      profileID: Value(profile.profileID),
      personID: Value(overridePersonID ?? profile.personID),
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

  Future<ProfileData?> getProfileForPerson(String personId) => (select(
    profilesTable,
  )..where((t) => t.personID.equals(personId))).getSingleOrNull();

  Future<void> updateProfile(ProfileData profile) =>
      update(profilesTable).replace(profile);

  // --- Image Path Updates ---
  Future<void> updateAvatarLocalPath(String personId, String filename) async {
    await (update(personsTable)..where((t) => t.id.equals(personId))).write(
      PersonsTableCompanion(avatarLocalPath: Value(filename)),
    );
  }

  Future<void> updateCoverLocalPath(String personId, String filename) async {
    await (update(cVAddressesTable)..where((t) => t.personID.equals(personId)))
        .write(CVAddressesTableCompanion(coverLocalPath: Value(filename)));
  }

  Future<void> updateAvatarImageUrl(String personId, String url) async {
    await (update(personsTable)..where((t) => t.id.equals(personId))).write(
      PersonsTableCompanion(profileImageUrl: Value(url)),
    );
  }

  Future<void> updateCoverImageUrl(String personId, String url) async {
    await (update(cVAddressesTable)..where((t) => t.personID.equals(personId)))
        .write(CVAddressesTableCompanion(coverImageUrl: Value(url)));
  }

  // CV Addresses
  Future<int> createCVAddress(
    CVAddressProtocol cvAddress, {
    String? overridePersonID,
  }) {
    final companion = CVAddressesTableCompanion.insert(
      id: IDGen.UUIDV7(),
      cvAddressID: Value(cvAddress.cvAddressID),
      personID: Value(overridePersonID ?? cvAddress.personID),
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

  Future<PersonalInformationProtocol> getAllInformation(String id) async {
    final emailData = await (select(
      emailAddressesTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();
    final accountData = await (select(
      userAccountsTable,
    )..where((t) => t.personID.equals(id))).getSingleOrNull();

    final personData = await (select(
      personsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
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

  Future<CVAddressData?> getCVAddressForPerson(String personId) => (select(
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
  Future<String> createFullProfile({
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
      await createProfile(profile, personID);
      await createCVAddress(cvAddress, overridePersonID: personID);

      return personID;
    });
  }

  Future<void> upsertPersonProfileData({
    required String personId,
    String? firstName,
    String? lastName,
    String? profileImageUrl,
    String? coverImageUrl,
    String? avatarLocalPath,
    String? coverLocalPath,
    String? bio,
    String? occupation,
    String? educationLevel,
    String? location,
    String? websiteUrl,
    String? linkedinUrl,
    String? githubUrl,
    String? company,
    String? university,
    String? country,
  }) async {
    final now = DateTime.now();

    await transaction(() async {
      // 1. Update/Insert Person info
      final existingPerson = await (select(
        personsTable,
      )..where((t) => t.id.equals(personId))).getSingleOrNull();
      if (existingPerson != null) {
        await (update(personsTable)..where((t) => t.id.equals(personId))).write(
          PersonsTableCompanion(
            firstName: firstName != null
                ? Value(firstName)
                : const Value.absent(),
            lastName: lastName != null ? Value(lastName) : const Value.absent(),
            profileImageUrl: profileImageUrl != null
                ? Value(profileImageUrl)
                : const Value.absent(),
            coverImageUrl: coverImageUrl != null
                ? Value(coverImageUrl)
                : const Value.absent(),
            avatarLocalPath: avatarLocalPath != null
                ? Value(avatarLocalPath)
                : const Value.absent(),
            coverLocalPath: coverLocalPath != null
                ? Value(coverLocalPath)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(personsTable).insert(
          PersonsTableCompanion.insert(
            id: personId,
            firstName: firstName ?? 'User',
            lastName: Value(lastName),
            profileImageUrl: Value(profileImageUrl),
            coverImageUrl: Value(coverImageUrl),
            avatarLocalPath: Value(avatarLocalPath),
            coverLocalPath: Value(coverLocalPath),
            updatedAt: Value(now),
          ),
        );
      }

      // 2. Update/Insert Profile details
      final existingProfile = await (select(
        profilesTable,
      )..where((t) => t.id.equals(personId))).getSingleOrNull();
      if (existingProfile != null) {
        await (update(
          profilesTable,
        )..where((t) => t.id.equals(personId))).write(
          ProfilesTableCompanion(
            personID: Value(personId),
            bio: bio != null ? Value(bio) : const Value.absent(),
            occupation: occupation != null
                ? Value(occupation)
                : const Value.absent(),
            educationLevel: educationLevel != null
                ? Value(educationLevel)
                : const Value.absent(),
            location: location != null ? Value(location) : const Value.absent(),
            websiteUrl: websiteUrl != null
                ? Value(websiteUrl)
                : const Value.absent(),
            linkedinUrl: linkedinUrl != null
                ? Value(linkedinUrl)
                : const Value.absent(),
            githubUrl: githubUrl != null
                ? Value(githubUrl)
                : const Value.absent(),
            coverImageUrl: coverImageUrl != null
                ? Value(coverImageUrl)
                : const Value.absent(),
            avatarLocalPath: avatarLocalPath != null
                ? Value(avatarLocalPath)
                : const Value.absent(),
            coverLocalPath: coverLocalPath != null
                ? Value(coverLocalPath)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(profilesTable).insert(
          ProfilesTableCompanion.insert(
            id: personId,
            personID: Value(personId),
            bio: Value(bio),
            occupation: Value(occupation),
            educationLevel: Value(educationLevel),
            location: Value(location),
            websiteUrl: Value(websiteUrl),
            linkedinUrl: Value(linkedinUrl),
            githubUrl: Value(githubUrl),
            coverImageUrl: Value(coverImageUrl),
            avatarLocalPath: Value(avatarLocalPath),
            coverLocalPath: Value(coverLocalPath),
            updatedAt: Value(now),
          ),
        );
      }

      // 3. Update/Insert Detail Information (CV Addresses)
      final existingCV = await (select(
        cVAddressesTable,
      )..where((t) => t.id.equals(personId))).getSingleOrNull();
      if (existingCV != null) {
        await (update(
          cVAddressesTable,
        )..where((t) => t.id.equals(personId))).write(
          CVAddressesTableCompanion(
            personID: Value(personId),
            bio: bio != null ? Value(bio) : const Value.absent(),
            occupation: occupation != null
                ? Value(occupation)
                : const Value.absent(),
            educationLevel: educationLevel != null
                ? Value(educationLevel)
                : const Value.absent(),
            location: location != null ? Value(location) : const Value.absent(),
            websiteUrl: websiteUrl != null
                ? Value(websiteUrl)
                : const Value.absent(),
            linkedinUrl: linkedinUrl != null
                ? Value(linkedinUrl)
                : const Value.absent(),
            githubUrl: githubUrl != null
                ? Value(githubUrl)
                : const Value.absent(),
            company: company != null ? Value(company) : const Value.absent(),
            university: university != null
                ? Value(university)
                : const Value.absent(),
            country: country != null ? Value(country) : const Value.absent(),
            coverImageUrl: coverImageUrl != null
                ? Value(coverImageUrl)
                : const Value.absent(),
            avatarLocalPath: avatarLocalPath != null
                ? Value(avatarLocalPath)
                : const Value.absent(),
            coverLocalPath: coverLocalPath != null
                ? Value(coverLocalPath)
                : const Value.absent(),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(cVAddressesTable).insert(
          CVAddressesTableCompanion.insert(
            id: personId,
            personID: Value(personId),
            bio: Value(bio),
            occupation: Value(occupation),
            educationLevel: Value(educationLevel),
            location: Value(location),
            websiteUrl: Value(websiteUrl),
            linkedinUrl: Value(linkedinUrl),
            githubUrl: Value(githubUrl),
            company: Value(company),
            university: Value(university),
            country: Value(country),
            coverImageUrl: Value(coverImageUrl),
            avatarLocalPath: Value(avatarLocalPath),
            coverLocalPath: Value(coverLocalPath),
            updatedAt: Value(now),
          ),
        );
      }
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
  Stream<List<FinancialAccountData>> watchAccounts(String personId) {
    return customSelect(
      'SELECT * FROM financial_accounts WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {financialAccountsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => FinancialAccountData(
              id: row.data['id'] as String,
              accountID: row.data['account_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
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
  Stream<List<AssetData>> watchAssets(String personId) {
    return customSelect(
      'SELECT * FROM assets WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {assetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => AssetData(
              id: row.data['id'] as String,
              assetID: row.data['asset_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
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

  Future<void> deleteTransaction(String id) =>
      (delete(transactionsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<TransactionData>> watchAllTransactions(String personId) {
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? ORDER BY transaction_date DESC',
      variables: [Variable.withString(personId)],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  Stream<List<TransactionData>> watchTransactionsByType(
    String personId,
    String type,
  ) {
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? AND type = ? ORDER BY transaction_date DESC',
      variables: [Variable.withString(personId), Variable.withString(type)],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  Stream<List<TransactionData>> watchMonthlyTransactions(
    String personId,
    int year,
    int month,
  ) {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 0, 23, 59, 59);

    // SQLite stores dates as ISO8601 strings usually, drifting it via custom requires string mapping
    return customSelect(
      'SELECT * FROM transactions WHERE person_id = ? AND transaction_date >= ? AND transaction_date <= ? ORDER BY transaction_date DESC',
      variables: [
        Variable.withString(personId),
        Variable.withString(start.toIso8601String()),
        Variable.withString(end.toIso8601String()),
      ],
      readsFrom: {transactionsTable},
    ).watch().map((rows) => _mapTransactions(rows, personId));
  }

  List<TransactionData> _mapTransactions(List<QueryRow> rows, String personId) {
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => TransactionData(
            id: row.data['id'] as String,
            transactionID: row.data['transaction_id'] as String?,
            personID: (row.data['person_id'] as String?) ?? personId,
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
            projectID: row.data['project_id'] as String?,
          ),
        )
        .toList();
  }
}

// 4.6 GrowthDAO
@DriftAccessor(tables: [GoalsTable, HabitsTable, SkillsTable])
class GrowthDAO extends DatabaseAccessor<AppDatabase> with _$GrowthDAOMixin {
  GrowthDAO(super.db);

  Future<String> createGoal(GoalsTableCompanion goal) async {
    // 1. Generate your unique ID
    final String goalId = IDGen.UUIDV7();

    // 2. Create a new version of the goal including the generated ID
    final goalToInsert = goal.copyWith(
      id: Value(goalId), // Assuming your PK is named 'id' in the table
      // If your column is named goalID in the table, use that instead
    );

    // 3. Insert the new object
    await into(goalsTable).insert(goalToInsert);

    return goalId;
  }

  Stream<List<GoalData>> watchGoals(String personId) {
    return customSelect(
      'SELECT * FROM goals WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: row.data['goal_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
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
              projectID: row.data['project_id'] as String?,
            ),
          )
          .toList();
    });
  }

  Stream<List<GoalData>> watchGoalsByProject(String projectID) {
    return customSelect(
      'SELECT * FROM goals WHERE project_id = ?',
      variables: [Variable.withString(projectID)],
      readsFrom: {goalsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => GoalData(
              id: row.data['id'] as String,
              goalID: row.data['goal_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? '',
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
              projectID: row.data['project_id'] as String?,
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

  Future<void> updateGoalStatusByIntId(String goalID, String status) async {
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
  Stream<List<HabitData>> watchHabits(String personId) {
    return customSelect(
      'SELECT * FROM habits WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {habitsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => HabitData(
              id: row.data['id'] as String,
              habitID: row.data['habit_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
              goalID: row.data['goal_id'] as String?,
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
  Stream<List<SkillData>> watchSkills(String personId) {
    return customSelect(
      'SELECT * FROM skills WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {skillsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => SkillData(
              id: row.data['id'] as String,
              skillID: row.data['skill_id'] as String?,
              personID: (row.data['person_id'] as String?) ?? personId,
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

// 4.7 AiAnalysisDAO
@DriftAccessor(tables: [AiAnalysisTable])
class AiAnalysisDAO extends DatabaseAccessor<AppDatabase>
    with _$AiAnalysisDAOMixin {
  AiAnalysisDAO(super.db);

  Future<int> createAnalysis(AiAnalysisTableCompanion analysis) =>
      into(aiAnalysisTable).insert(analysis);

  Stream<List<AiAnalysisData>> watchAnalyses(String personID) => (select(
    aiAnalysisTable,
  )..where((t) => t.personID.equals(personID) | t.personID.isNull())).watch();

  Future<AiAnalysisData?> getAnalysisById(String id) => (select(
    aiAnalysisTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();
}

// 4.8 WidgetDAO
@DriftAccessor(tables: [PersonWidgetsTable])
class WidgetDAO extends DatabaseAccessor<AppDatabase> with _$WidgetDAOMixin {
  WidgetDAO(super.db);

  Future<int> createWidget(PersonWidgetsTableCompanion widget) =>
      into(personWidgetsTable).insert(widget);

  Stream<List<PersonWidgetData>> watchWidgets(String personId) {
    return customSelect(
      'SELECT * FROM person_widgets WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {personWidgetsTable},
    ).watch().map((rows) {
      return rows
          .where((row) => row.data['id'] != null)
          .map(
            (row) => PersonWidgetData(
              id: row.data['id'] as String,
              personWidgetID: (row.data['person_widget_id'] as int?) ?? 0,
              personID: (row.data['person_id'] as String?) ?? personId,
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

  Future<List<PersonWidgetData>> getAllWidgets(String personId) async {
    final rows = await customSelect(
      'SELECT * FROM person_widgets WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {personWidgetsTable},
    ).get();
    return rows
        .where((row) => row.data['id'] != null)
        .map(
          (row) => PersonWidgetData(
            id: row.data['id'] as String,
            personWidgetID: (row.data['person_widget_id'] as int?) ?? 0,
            personID: (row.data['person_id'] as String?) ?? personId,
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
    String personId,
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
            id: IDGen.UUIDV7(),
            personID: Value(personId),
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
          id: IDGen.UUIDV7(),
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

  Stream<List<HealthMetricsLocal>> watchAllMetrics(String personID) {
    return (select(healthMetricsTable)
          ..where((t) => t.personID.equals(personID) | t.personID.isNull())
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<HealthMetricsLocal>> watchMetricsByPerson(String personID) {
    return watchAllMetrics(personID);
  }

  Future<HealthMetricsLocal?> getMetricsForDate(
    String? personID,
    DateTime date,
  ) async {
    if (personID == null || personID.isEmpty) {
      return null;
    }

    final targetDateStr =
        "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
    final targetId = IDGen.generateDeterministicUuid(personID, targetDateStr);

    // 1. Fast path: check exact deterministic ID
    final existingById = await (select(
      healthMetricsTable,
    )..where((t) => t.id.equals(targetId))).getSingleOrNull();
    if (existingById != null) return existingById;

    // 2. Slow path for legacy records containing random UUIDs
    final all = await (select(
      healthMetricsTable,
    )..where((t) => t.personID.equals(personID))).get();
    if (all.isEmpty) return null;

    final noonTarget = DateTime(date.year, date.month, date.day, 12);
    HealthMetricsLocal? bestMatch;
    int minDiff = 24; // We care if it's within the same logical day

    for (final m in all) {
      final diff = m.date.difference(noonTarget).inHours.abs();
      if (diff < minDiff) {
        minDiff = diff;
        bestMatch = m;
      }
    }

    // A valid match should be securely within 14 hours (max timezone offset is +/- 14)
    if (minDiff <= 14) {
      return bestMatch;
    }

    return null;
  }

  Future<void> insertOrUpdateMetrics(HealthMetricsTableCompanion entry) async {
    final d = entry.date.value;
    final normalized = DateTime(d.year, d.month, d.day, 12, 0, 0);
    final personId = entry.personID.value;

    if (personId == null || personId.isEmpty) return;

    final dateStr =
        "${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}";
    final deterministicId = IDGen.generateDeterministicUuid(personId, dateStr);

    final existing = await getMetricsForDate(personId, normalized);

    if (existing != null) {
      final currentSteps = entry.steps.present ? entry.steps.value ?? 0 : 0;
      final savedSteps = existing.steps ?? 0;
      final updatedSteps = entry.steps.present
          ? (currentSteps > savedSteps)
                ? entry.steps
                : Value(savedSteps)
          : Value(savedSteps);

      final currentCalories = entry.caloriesBurned.present
          ? entry.caloriesBurned.value ?? 0
          : 0;
      final savedCalories = existing.caloriesBurned ?? 0;
      final updatedCaloriesBurned = entry.caloriesBurned.present
          ? (currentCalories > savedCalories)
                ? entry.caloriesBurned
                : Value(savedCalories)
          : Value(savedCalories);

      await (update(
        healthMetricsTable,
      )..where((t) => t.id.equals(existing.id))).write(
        entry.copyWith(
          id: Value(existing.id),
          date: Value(existing.date),
          steps: updatedSteps,
          caloriesBurned: updatedCaloriesBurned,
          updatedAt: Value(DateTime.now()),
        ),
      );
    } else {
      await into(healthMetricsTable).insert(
        entry.copyWith(
          id: Value(deterministicId),
          date: Value(normalized),
          updatedAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrReplace,
      );
    }
  }

  Future<int> deleteMetricsForPerson(String personID) {
    return (delete(
      healthMetricsTable,
    )..where((t) => t.personID.equals(personID))).go();
  }

  Future<void> cleanupDuplicates(String personId) async {
    final all =
        await (select(healthMetricsTable)
              ..where((t) => t.personID.equals(personId))
              ..orderBy([
                (t) => OrderingTerm(expression: t.date, mode: OrderingMode.asc),
              ]))
            .get();

    final Map<String, List<HealthMetricsLocal>> grouped = {};
    for (var m in all) {
      final key =
          "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(key, () => []).add(m);
    }

    for (var entry in grouped.entries) {
      if (entry.value.length > 1) {
        final targetId = IDGen.generateDeterministicUuid(personId, entry.key);
        HealthMetricsLocal? winner;
        for (var m in entry.value) {
          if (m.id == targetId) {
            winner = m;
            break;
          }
        }
        winner ??= entry.value.first;
        for (var m in entry.value) {
          if (m.id != winner.id) {
            await (delete(
              healthMetricsTable,
            )..where((t) => t.id.equals(m.id))).go();
          }
        }
      }
    }
  }
}

@DriftAccessor(
  tables: [
    HealthMetricsTable,
    FinancialMetricsTable,
    ProjectMetricsTable,
    SocialMetricsTable,
  ],
)
class MetricsDAO extends DatabaseAccessor<AppDatabase> with _$MetricsDAOMixin {
  MetricsDAO(super.db);

  String _getDateStr(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
  }

  // --- Health Quests ---
  Future<void> incrementHealthQuestPoints(
    String personId,
    double points, {
    String category = 'General',
    String? tenantId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = _getDateStr(now);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      dateStr + category,
    );

    await transaction(() async {
      final existingList =
          await (select(healthMetricsTable)..where(
                (t) =>
                    t.id.equals(targetId) |
                    (t.personID.equals(personId) &
                        t.date.equals(today) &
                        t.category.equals(category)),
              ))
              .get();

      if (existingList.isNotEmpty) {
        final existing = existingList.firstWhere(
          (e) => e.id == targetId,
          orElse: () => existingList.first,
        );

        if (existingList.length > 1) {
          final idsToDelete = existingList
              .where((e) => e.id != existing.id)
              .map((e) => e.id)
              .toList();
          if (idsToDelete.isNotEmpty) {
            await (delete(
              healthMetricsTable,
            )..where((t) => t.id.isIn(idsToDelete))).go();
          }
        }

        await (update(
          healthMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          HealthMetricsTableCompanion(
            questPoints: Value((existing.questPoints ?? 0.0) + points),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(healthMetricsTable).insert(
          HealthMetricsTableCompanion(
            id: Value(targetId),
            tenantID: Value(tenantId),
            personID: Value(personId),
            date: Value(today),
            category: Value(category),
            questPoints: Value(points),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // --- Social Quests ---
  Future<void> incrementSocialQuestPoints(
    String personId,
    double points, {
    String category = 'General',
    String? tenantId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = _getDateStr(now);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      dateStr + category,
    );

    await transaction(() async {
      final existingList =
          await (select(socialMetricsTable)..where(
                (t) =>
                    t.id.equals(targetId) |
                    (t.personID.equals(personId) &
                        t.date.equals(today) &
                        t.category.equals(category)),
              ))
              .get();

      if (existingList.isNotEmpty) {
        final existing = existingList.firstWhere(
          (e) => e.id == targetId,
          orElse: () => existingList.first,
        );

        if (existingList.length > 1) {
          final idsToDelete = existingList
              .where((e) => e.id != existing.id)
              .map((e) => e.id)
              .toList();
          if (idsToDelete.isNotEmpty) {
            await (delete(
              socialMetricsTable,
            )..where((t) => t.id.isIn(idsToDelete))).go();
          }
        }

        await (update(
          socialMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          SocialMetricsTableCompanion(
            questPoints: Value((existing.questPoints ?? 0.0) + points),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(socialMetricsTable).insert(
          SocialMetricsTableCompanion(
            id: Value(targetId),
            tenantID: Value(tenantId),
            personID: Value(personId),
            date: Value(today),
            category: Value(category),
            questPoints: Value(points),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // --- Financial Quests ---
  Future<void> incrementFinancialQuestPoints(
    String personId,
    double points, {
    String category = 'General',
    String? tenantId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = _getDateStr(now);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      dateStr + category,
    );

    await transaction(() async {
      final existingList =
          await (select(financialMetricsTable)..where(
                (t) =>
                    t.id.equals(targetId) |
                    (t.personID.equals(personId) &
                        t.date.equals(today) &
                        t.category.equals(category)),
              ))
              .get();

      if (existingList.isNotEmpty) {
        final existing = existingList.firstWhere(
          (e) => e.id == targetId,
          orElse: () => existingList.first,
        );

        if (existingList.length > 1) {
          final idsToDelete = existingList
              .where((e) => e.id != existing.id)
              .map((e) => e.id)
              .toList();
          if (idsToDelete.isNotEmpty) {
            await (delete(
              financialMetricsTable,
            )..where((t) => t.id.isIn(idsToDelete))).go();
          }
        }

        await (update(
          financialMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          FinancialMetricsTableCompanion(
            questPoints: Value((existing.questPoints ?? 0.0) + points),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(financialMetricsTable).insert(
          FinancialMetricsTableCompanion(
            id: Value(targetId),
            tenantID: Value(tenantId),
            personID: Value(personId),
            date: Value(today),
            category: Value(category),
            questPoints: Value(points),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // --- Project Quests ---
  Future<void> incrementProjectQuestPoints(
    String personId,
    double points, {
    String category = 'General',
    String? tenantId,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateStr = _getDateStr(now);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      dateStr + category,
    );

    await transaction(() async {
      final existingList =
          await (select(projectMetricsTable)..where(
                (t) =>
                    t.id.equals(targetId) |
                    (t.personID.equals(personId) &
                        t.date.equals(today) &
                        t.category.equals(category)),
              ))
              .get();

      if (existingList.isNotEmpty) {
        final existing = existingList.firstWhere(
          (e) => e.id == targetId,
          orElse: () => existingList.first,
        );

        if (existingList.length > 1) {
          final idsToDelete = existingList
              .where((e) => e.id != existing.id)
              .map((e) => e.id)
              .toList();
          if (idsToDelete.isNotEmpty) {
            await (delete(
              projectMetricsTable,
            )..where((t) => t.id.isIn(idsToDelete))).go();
          }
        }

        await (update(
          projectMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          ProjectMetricsTableCompanion(
            questPoints: Value((existing.questPoints ?? 0.0) + points),
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(projectMetricsTable).insert(
          ProjectMetricsTableCompanion(
            id: Value(targetId),
            tenantID: Value(tenantId),
            personID: Value(personId),
            date: Value(today),
            category: Value(category),
            questPoints: Value(points),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // Watchers for today's metrics
  Stream<HealthMetricsLocal?> watchTodayHealth(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(personId, dateStr);
    return (select(
      healthMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<SocialMetricsLocal?> watchTodaySocial(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(personId, dateStr);
    return (select(
      socialMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<ProjectMetricsLocal?> watchTodayProject(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(personId, dateStr);
    return (select(
      projectMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<FinancialMetricsLocal?> watchTodayFinancial(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(personId, dateStr);
    return (select(
      financialMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  // --- Total Quest Points Watchers (Sum of all time) ---

  Stream<double> watchTotalHealthQuestPoints(String personId) {
    return customSelect(
      'SELECT SUM(quest_points) as total FROM health_metrics WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {healthMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTotalSocialQuestPoints(String personId) {
    return customSelect(
      'SELECT SUM(quest_points) as total FROM social_metrics WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {socialMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTotalProjectQuestPoints(String personId) {
    return customSelect(
      'SELECT SUM(quest_points) as total FROM project_metrics WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {projectMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTotalFinancialQuestPoints(String personId) {
    return customSelect(
      'SELECT SUM(quest_points) as total FROM financial_metrics WHERE person_id = ?',
      variables: [Variable.withString(personId)],
      readsFrom: {financialMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  // --- Breakdown Watchers ---

  Stream<Map<String, double>> watchProjectBreakdown(String personId) {
    return (select(
      projectMetricsTable,
    )..where((t) => t.personID.equals(personId))).watch().map((rows) {
      final breakdown = <String, double>{};
      for (var row in rows) {
        final cat = row.category ?? 'General';
        breakdown[cat] = (breakdown[cat] ?? 0.0) + (row.questPoints ?? 0.0);
      }
      return breakdown;
    });
  }

  Stream<Map<String, double>> watchHealthBreakdown(String personId) {
    return (select(
      healthMetricsTable,
    )..where((t) => t.personID.equals(personId))).watch().map((rows) {
      final breakdown = <String, double>{};
      for (var row in rows) {
        final cat = row.category ?? 'General';
        breakdown[cat] = (breakdown[cat] ?? 0.0) + (row.questPoints ?? 0.0);
      }
      return breakdown;
    });
  }

  Stream<Map<String, double>> watchSocialBreakdown(String personId) {
    return (select(
      socialMetricsTable,
    )..where((t) => t.personID.equals(personId))).watch().map((rows) {
      final breakdown = <String, double>{};
      for (var row in rows) {
        final cat = row.category ?? 'General';
        breakdown[cat] = (breakdown[cat] ?? 0.0) + (row.questPoints ?? 0.0);
      }
      return breakdown;
    });
  }

  Stream<Map<String, double>> watchFinancialBreakdown(String personId) {
    return (select(
      financialMetricsTable,
    )..where((t) => t.personID.equals(personId))).watch().map((rows) {
      final breakdown = <String, double>{};
      for (var row in rows) {
        final cat = row.category ?? 'General';
        breakdown[cat] = (breakdown[cat] ?? 0.0) + (row.questPoints ?? 0.0);
      }
      return breakdown;
    });
  }

  // --- Historical Metric Points (Points derived from steps/etc on previous days) ---

  Stream<double> watchHistoricalHealthMetricPoints(String personId) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    return customSelect(
      'SELECT SUM(max_s) as s, SUM(max_e) as e, SUM(max_sl) as sl FROM (SELECT MAX(steps) as max_s, MAX(exercise_minutes) as max_e, MAX(sleep_hours) as max_sl FROM health_metrics WHERE person_id = ? AND date < ? GROUP BY date)',
      variables: [
        Variable.withString(personId),
        Variable.withDateTime(todayStart),
      ],
      readsFrom: {healthMetricsTable},
    ).watchSingle().map((row) {
      final s = (row.data['s'] as num?)?.toDouble() ?? 0.0;
      final e = (row.data['e'] as num?)?.toDouble() ?? 0.0;
      final sl = (row.data['sl'] as num?)?.toDouble() ?? 0.0;

      // Use same constants as GameConst.dart
      double points = 0;
      if (STEPS_PER_POINT > 0) points += (s / STEPS_PER_POINT);
      if (EXERCISE_PER_POINT > 0) points += (e / EXERCISE_PER_POINT);
      points += (sl * SLEEP_POINTS_PER_HOUR);
      return points;
    });
  }

  /// Removes the old migration "Genesis" records to cleanup the DB.
  Future<void> cleanupGenesisRecords(String personId) async {
    final genesisDate = DateTime(1970, 1, 1).toUtc();
    await (delete(healthMetricsTable)..where(
          (t) => t.personID.equals(personId) & t.date.equals(genesisDate),
        ))
        .go();
    await (delete(socialMetricsTable)..where(
          (t) => t.personID.equals(personId) & t.date.equals(genesisDate),
        ))
        .go();
    await (delete(projectMetricsTable)..where(
          (t) => t.personID.equals(personId) & t.date.equals(genesisDate),
        ))
        .go();
    await (delete(financialMetricsTable)..where(
          (t) => t.personID.equals(personId) & t.date.equals(genesisDate),
        ))
        .go();
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
  Future<MealData?> getMealById(String id) =>
      (select(mealsTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  // Days (Meal Logs)
  Future<int> insertDay(DaysTableCompanion day) => into(daysTable).insert(day);
  Future<int> upsertDay(DaysTableCompanion day) =>
      into(daysTable).insertOnConflictUpdate(day);
  Future<double> getCaloriesByDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    print("The date that fetch: $date");

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
      final seenMealIds = <String>{};
      final results = <DayWithMeal>[];
      for (var row in rows) {
        final meal = row.readTable(mealsTable);
        if (seenMealIds.add(meal.id)) {
          results.add(DayWithMeal(day: row.readTable(daysTable), meal: meal));
        }
      }
      return results;
    });
  }

  Stream<double> watchDailyCalories(String personId, DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(mealsTable)..where(
          (tbl) =>
              tbl.personID.equals(personId) &
              tbl.eatenAt.isBiggerOrEqualValue(startOfDay) &
              tbl.eatenAt.isSmallerThanValue(endOfDay),
        ))
        .watch()
        .map((rows) {
          double calories = 0.0;
          for (var row in rows) {
            calories += row.calories;
          }
          return calories;
        });
  }

  Stream<List<DayWithMeal>> watchDaysWithMeals(String personId) {
    // We join meals by their eaten_at DATE truncated to midnight
    // to match daysTable.dayID which is also truncated to midnight.
    final query = select(daysTable).join([
      innerJoin(
        mealsTable,
        mealsTable.eatenAt.year.equalsExp(daysTable.dayID.year) &
            mealsTable.eatenAt.month.equalsExp(daysTable.dayID.month) &
            mealsTable.eatenAt.day.equalsExp(daysTable.dayID.day),
      ),
    ])..where(mealsTable.personID.equals(personId));
    // final query=select
    print("watchDaysWithMeals: executing query...");
    return query.watch().map((rows) {
      final seenMealIds = <String>{};
      final results = <DayWithMeal>[];

      for (var row in rows) {
        final meal = row.readTable(mealsTable);
        if (seenMealIds.add(meal.id)) {
          results.add(DayWithMeal(day: row.readTable(daysTable), meal: meal));
        }
      }
      return results;
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
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get projectID => text()
      .nullable()
      .references(ProjectsTable, #id, onDelete: KeyAction.cascade)
      .named('project_id')();
  DateTimeColumn get startTime => dateTime().named('start_time')();
  DateTimeColumn get endTime => dateTime().nullable().named('end_time')();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .named('status')(); // 'completed', 'interrupted'
  TextColumn get sessionType => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('Focus'))
      .named('session_type')();
  TextColumn get taskID => text()
      .nullable()
      .references(GoalsTable, #id, onDelete: KeyAction.cascade)
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

  Stream<List<FocusSessionData>> watchSessionsByPerson(String personId) {
    return (select(
      focusSessionsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  Stream<List<FocusSessionData>> watchAllSessions() {
    return select(focusSessionsTable).watch();
  }

  Future<int> deleteSession(String id) {
    return (delete(focusSessionsTable)..where((t) => t.id.equals(id))).go();
  }

  Future<void> patchSession(
    String id,
    FocusSessionsTableCompanion companion,
  ) async {
    await (update(
      focusSessionsTable,
    )..where((t) => t.id.equals(id))).write(companion);
  }
}

@DataClassName('QuoteData')
class QuotesTable extends Table {
  @override
  String get tableName => 'quotes';
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .nullable()
      .references(OrganizationsTable, #id, onDelete: KeyAction.cascade)
      .named('tenant_id')();
  // IntColumn get quoteID => integer().nullable().named('quote_id')();
  TextColumn get personID => text()
      .nullable()
      .references(PersonsTable, #id, onDelete: KeyAction.cascade)
      .named('person_id')();
  TextColumn get content => text()();
  TextColumn get author => text().nullable()();
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();

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

  Future<int> deleteQuote(String id) =>
      (delete(quotesTable)..where((t) => t.id.equals(id))).go();

  Future<List<QuoteData>> getAllQuotes() async {
    final rows = await customSelect('SELECT * FROM quotes').get();
    return rows.map((row) {
      DateTime? createdAt;
      try {
        final val = row.data['created_at'];
        if (val is String) {
          createdAt = DateTime.parse(val);
        } else if (val is int) {
          createdAt = DateTime.fromMillisecondsSinceEpoch(val);
        }
      } catch (_) {}

      return QuoteData(
        id: row.data['id'] as String,
        personID: row.data['person_id'] as String,
        content: row.data['content'] as String? ?? '',
        author: row.data['author'] as String?,
        isActive:
            (row.data['is_active'] as int?) == 1 ||
            (row.data['is_active'] as bool?) == true,
        createdAt: createdAt ?? DateTime.now(),
      );
    }).toList();
  }

  Stream<List<QuoteData>> watchActiveQuotes() {
    return watchAllQuotes().map(
      (quotes) => quotes.where((q) => q.isActive).toList(),
    );
  }

  Stream<List<QuoteData>> watchAllQuotes() {
    return customSelect(
      'SELECT * FROM quotes',
      readsFrom: {quotesTable},
    ).watch().map((rows) {
      return rows
          .map(
            (row) => QuoteData(
              id: row.data['id'] as String,
              personID: row.data['person_id'] as String?,
              content: row.data['content'] as String,
              author: row.data['author'] as String?,
              isActive:
                  (row.data['is_active'] as int?) == 1 ||
                  (row.data['is_active'] as bool?) == true,
              createdAt: _parseDate(row.data['created_at']),
            ),
          )
          .toList();
    });
  }

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      try {
        return DateTime.parse(val);
      } catch (_) {}
    } else if (val is int) {
      return DateTime.fromMillisecondsSinceEpoch(val);
    }
    return DateTime.now();
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

  Future<void> patchNotification(
    String id,
    CustomNotificationsTableCompanion companion,
  ) {
    return (update(
      customNotificationsTable,
    )..where((t) => t.id.equals(id))).write(companion);
  }
}

class GlobalRankingEntry {
  final ScoreLocalData score;
  final PersonData person;

  GlobalRankingEntry({required this.score, required this.person});

  double get totalScore =>
      (score.healthGlobalScore ?? 0.0) +
      (score.socialGlobalScore ?? 0.0) +
      (score.financialGlobalScore ?? 0.0) +
      (score.careerGlobalScore ?? 0.0);
}

@DriftAccessor(tables: [QuestsTable])
class QuestDAO extends DatabaseAccessor<AppDatabase> with _$QuestDAOMixin {
  QuestDAO(super.db);

  Future<int> insertQuest(QuestsTableCompanion entry) {
    // Force category to lowercase if present
    var updatedEntry = entry;
    if (entry.category.present) {
      final categoryValue = entry.category.value;
      updatedEntry = entry.copyWith(
        category: Value(categoryValue?.toLowerCase()),
      );
    }
    return into(questsTable).insert(updatedEntry);
  }

  Future<bool> updateQuest(QuestData entry) {
    final updatedEntry = entry.copyWith(
      category: Value(entry.category?.toLowerCase()),
    );
    return update(questsTable).replace(updatedEntry);
  }

  Future<int> deleteQuest(String id) =>
      (delete(questsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<QuestData>> watchActiveQuests(String personId) {
    return (select(questsTable)..where(
          (t) => t.isCompleted.equals(false) & t.personID.equals(personId),
        ))
        .watch();
  }

  Stream<List<QuestData>> watchAllQuests(String personId) {
    return (select(questsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<QuestData>> watchQuestsByPerson(String personId) {
    return (select(questsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<QuestData>> getAllQuests(String personId) =>
      (select(questsTable)..where((t) => t.personID.equals(personId))).get();

  Future<void> updateQuestProgress(String id, double value) async {
    final existing = await (select(
      questsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      final newValue = value;
      final target = existing.targetValue ?? 0.0;
      final isNowCompleted = newValue >= target;
      await (update(questsTable)..where((t) => t.id.equals(id))).write(
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
  Stream<List<WaterLogData>> watchDailyWaterLogs(
    String personId,
    DateTime date,
  ) {
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
  Stream<List<SleepLogData>> watchSleepLogs(String personId) {
    return (select(
      sleepLogsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  // Exercise Logs
  Future<int> insertExerciseLog(ExerciseLogsTableCompanion entry) =>
      into(exerciseLogsTable).insert(entry);
  Stream<List<ExerciseLogData>> watchDailyExerciseLogs(
    String personId,
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
    OrganizationsTable,
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
    AiAnalysisTable,
    PersonWidgetsTable,
    CVAddressesTable,
    SessionTable,
    HealthMetricsTable,
    FinancialMetricsTable,
    ProjectMetricsTable,
    SocialMetricsTable,
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
    PersonContactsTable,
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
    AiAnalysisDAO,
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
    MetricsDAO,
  ],
)
class AppDatabase extends _$AppDatabase {
  final PowerSyncDatabase? powerSync;

  AppDatabase([QueryExecutor? executor, this.powerSync])
    : super(executor ?? _openConnection()) {
    print("OBVIOUS LOG: DATABASE VERSION IS 25");
  }

  factory AppDatabase.powersync(PowerSyncDatabase db) {
    return AppDatabase(SqliteAsyncDriftConnection(db), db);
  }
  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(
    // Ép Drift lưu DateTime dưới dạng chuỗi ISO8601 thay vì số nguyên
    storeDateTimeAsText: true,
  );
  @override
  int get schemaVersion => 42;

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
        if (from < 33) {
          // The image_url column was added to quests. However, since quests is
          // synced via PowerSync, it is a VIEW in SQLite, not a base table.
          // PowerSync automatically handles recreating this view based on the
          // new schema, so we DO NOT use `m.addColumn` here.
        }
        if (from < 31) {
          // PowerSync tables (like custom_notifications) are views in SQLite.
          // They should be updated via the PowerSync schema, NOT via ALTER TABLE.
          // This block is now empty or contains only local-only table alterations.
        }
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
          await m.createTable(aiAnalysisTable);
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
              "ALTER TABLE focus_sessions ADD COLUMN taskID TEXT REFERENCES goals(goalID) ON DELETE CASCADE;",
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
              'ALTER TABLE project_notes ADD COLUMN personID TEXT REFERENCES persons(personID) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE project_notes ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE',
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE goals ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE',
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
              "ALTER TABLE transactions ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE;",
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

        if (from < 26) {
          try {
            await customStatement(
              "ALTER TABLE meals ADD COLUMN person_id TEXT REFERENCES persons(id) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Drift: Error adding person_id column to meals: $e');
          }
        }
        if (from < 32) {
          try {
            await customStatement(
              "ALTER TABLE custom_notifications ADD COLUMN person_id TEXT REFERENCES persons(id) ON DELETE CASCADE;",
            );
          } catch (e) {
            print(
              'Drift: Error adding person_id column to custom_notifications: $e',
            );
          }
        }

        if (from < 35) {
          try {
            await m.addColumn(internalWidgetsTable, internalWidgetsTable.scope);
          } catch (e) {
            print('Drift: Error adding scope column to internal_widgets: $e');
          }
        }

        if (from < 37) {
          // NOTE: persons, profiles, and cVAddressesTable are synced via PowerSync.
          // They are views in SQLite, so m.addColumn will fail.
          // These columns were added to powersync_schema.dart, and PowerSync
          // will automatically handle the SQLite schema update.
          /*
          try {
            await m.addColumn(personsTable, personsTable.coverImageUrl);
            await m.addColumn(profilesTable, profilesTable.coverImageUrl);
            await m.addColumn(cVAddressesTable, cVAddressesTable.coverImageUrl);
          } catch (e) {
            print('Drift: Error in version 37 migration: $e');
          }
          */
        }

        if (from < 38) {
          // NOTE: avatar_local_path and cover_local_path were also added to
          // powersync_schema.dart for secondary sync/schema consistency.
          /*
          try {
            await m.addColumn(personsTable, personsTable.avatarLocalPath);
            await m.addColumn(personsTable, personsTable.coverLocalPath);
            await m.addColumn(profilesTable, profilesTable.avatarLocalPath);
            await m.addColumn(profilesTable, profilesTable.coverLocalPath);
            await m.addColumn(
              cVAddressesTable,
              cVAddressesTable.avatarLocalPath,
            );
            await m.addColumn(
              cVAddressesTable,
              cVAddressesTable.coverLocalPath,
            );
          } catch (e) {
            print('Drift: Error in version 38 migration: $e');
          }
          */
        }
        if (from < 41) {
          try {
            await m.addColumn(healthMetricsTable, healthMetricsTable.category);
            await m.addColumn(
              financialMetricsTable,
              financialMetricsTable.category,
            );
            await m.addColumn(
              projectMetricsTable,
              projectMetricsTable.category,
            );
            await m.addColumn(socialMetricsTable, socialMetricsTable.category);

            // Fill NULL values for existing rows
            await customStatement(
              "UPDATE health_metrics SET category = 'General' WHERE category IS NULL",
            );
            await customStatement(
              "UPDATE financial_metrics SET category = 'General' WHERE category IS NULL",
            );
            await customStatement(
              "UPDATE project_metrics SET category = 'General' WHERE category IS NULL",
            );
            await customStatement(
              "UPDATE social_metrics SET category = 'General' WHERE category IS NULL",
            );

            // Update unique indexes to include category.
            // We drop standard Drift index names if they existed.
            await customStatement(
              'DROP INDEX IF EXISTS health_metrics_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS financial_metrics_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS project_metrics_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS social_metrics_person_id_date',
            );

            await customStatement(
              'DROP INDEX IF EXISTS index_health_metrics_on_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS index_financial_metrics_on_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS index_project_metrics_on_person_id_date',
            );
            await customStatement(
              'DROP INDEX IF EXISTS index_social_metrics_on_person_id_date',
            );

            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_health_metrics_category_unique ON health_metrics (person_id, date, category)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_financial_metrics_category_unique ON financial_metrics (person_id, date, category)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_project_metrics_category_unique ON project_metrics (person_id, date, category)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_social_metrics_category_unique ON social_metrics (person_id, date, category)',
            );
          } catch (e) {
            print('Drift: Error in version 41 migration: $e');
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
