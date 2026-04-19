// 1. Core Drift and Platform Imports
import 'package:flutter/foundation.dart';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:drift_sqlite_async/drift_sqlite_async.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:ice_gate/initial_layer/CoreLogics/PowerPoint/GameConst.dart';
import 'package:ice_gate/initial_layer/ThemeLayer/CurrentThemeData.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/ExternalWidgetProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/PersonalInformationProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/UserAccountProtocol.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/data_layer/Protocol/User/EmailAddressProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/ProfileProtocol.dart';
import 'package:ice_gate/data_layer/Protocol/User/CVAddressProtocol.dart';
import 'package:rxdart/rxdart.dart';
// For File
import 'dart:math'; // For Random() used in DAOs
import 'dart:convert';
// For finding the database path
// For path joining
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/Services/cloud/SupabaseService.dart';
import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';

// 2. Part Directives (Crucial for generated code)
// NOTE: You must run `flutter pub run build_runner build` to generate this file.
part 'database.g.dart';
// NOTE: I'm using 'app_database.g.dart' as the standard naming convention.

const String DEFAULT_TENANT_ID = '00000000-0000-0000-0000-000000000001';

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get widgetID => text().nullable().named("widget_id")();
  TextColumn get personID => text().nullable().named('person_id')();

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

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(internalWidgetsTable).insertOnConflictUpdate(
      InternalWidgetsTableCompanion.insert(
        id: r['id'] as String,
        tenantID: Value(r['tenant_id'] as String?),
        widgetID: Value(r['widget_id'] as String?),
        personID: Value(r['person_id'] as String?),
        name: Value(r['name'] as String?),
        url: Value(r['url'] as String?),
        dateAdded: Value(r['date_added'] as String?),
        imageUrl: Value(r['image_url'] as String?),
        alias: Value(r['alias'] as String?),
        scope: Value(r['scope'] as String?),
      ),
    );
  }

  Future<InternalWidgetData?> getInternalWidgetByName(String name) {
    // return (select(internalWidgetsTable)..where((table)=>table.name.equals(_name)).getSingleOrNull());
    return (select(internalWidgetsTable)
          ..where((table) => table.name.equals(name))
          ..limit(1))
        .getSingleOrNull();

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
  }) async {
    final idToUse = id ?? IDGen.UUIDV7();
    final widgetIdToUse = widgetID ?? IDGen.UUIDV7();
    final img = imageUrl ?? "assets/internalwidget/default_plugin.png";
    final now = DateTime.now().toIso8601String();

    final res = await into(internalWidgetsTable).insert(
      InternalWidgetsTableCompanion.insert(
        id: idToUse,
        widgetID: Value(widgetIdToUse),
        personID: Value(personID),
        name: Value(name),
        alias: Value(alias),
        url: Value(url),
        imageUrl: Value(img),
        scope: Value(scope),
        dateAdded: Value(now),
      ),
    );

    attachedDatabase.pushToSupabase(
      table: 'internal_widgets',
      payload: {
        'id': idToUse,
        'widget_id': widgetIdToUse,
        'person_id': personID,
        'name': name,
        'alias': alias,
        'url': url,
        'image_url': img,
        'scope': scope,
        'date_added': now,
      },
    );

    return res;
  }

  Future<int> deleteInternalWidget(String name) async {
    final widget = await getInternalWidgetByName(name);
    final res = await (delete(
      internalWidgetsTable,
    )..where((t) => t.name.equals(name))).go();

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id},
        isDelete: true,
      );
    }
    return res;
  }

  Future<int> renameInternalWidget(String oldName, String newName) async {
    final widget = await getInternalWidgetByName(oldName);
    final res =
        await (update(internalWidgetsTable)
              ..where((t) => t.name.equals(oldName)))
            .write(InternalWidgetsTableCompanion(name: Value(newName)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id, 'name': newName},
      );
    }
    return res;
  }

  Future<int> updateInternalWidgetUrl(String alias, String newUrl) async {
    final widget = await getInternalWidgetByAlias(alias);
    final res =
        await (update(internalWidgetsTable)
              ..where((t) => t.alias.equals(alias)))
            .write(InternalWidgetsTableCompanion(url: Value(newUrl)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'internal_widgets',
        payload: {'id': widget.id, 'url': newUrl},
      );
    }
    return res;
  }

  Future<InternalWidgetData?> getInternalWidgetByAlias(String alias) {
    return (select(internalWidgetsTable)
          ..where((table) => table.alias.equals(alias))
          ..limit(1))
        .getSingleOrNull();
  }
}

@DataClassName('HourlyActivityLogData')
class HourlyActivityLogTable extends Table {
  @override
  String get tableName => 'hourly_activity_log';

  TextColumn get id => text()(); // UUID PK
  TextColumn get personID => text().named('person_id')();

  DateTimeColumn get startTime =>
      dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime()
      .map(const DateTimeUTCConverter())
      .nullable()
      .named('end_time')();

  // log_date is generated in Postgres, but we can model it as a simple Date field locally for PowerSync mapping
  DateTimeColumn get logDate =>
      dateTime().map(const DateTimeUTCConverter()).named('log_date')();

  IntColumn get stepsCount =>
      integer().withDefault(const Constant(0)).named('steps_count')();
  RealColumn get distanceKm =>
      real().withDefault(const Constant(0.0)).named('distance_km')();
  IntColumn get caloriesBurned =>
      integer().withDefault(const Constant(0)).named('calories_burned')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [HourlyActivityLogTable])
class HourlyActivityLogDAO extends DatabaseAccessor<AppDatabase>
    with _$HourlyActivityLogDAOMixin {
  HourlyActivityLogDAO(super.db);

  Stream<List<HourlyActivityLogData>> watchHourlyLogs(
    String personId,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(hourlyActivityLogTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.startTime.isBetweenValues(startOfDay, endOfDay),
          )
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  Future<void> upsertHourlyLog(HourlyActivityLogTableCompanion entry) async {
    final existing = await (select(
      hourlyActivityLogTable,
    )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();

    if (existing != null) {
      final currentSteps = entry.stepsCount.present
          ? entry.stepsCount.value
          : 0;
      final existingSteps = existing.stepsCount;
      if (currentSteps > existingSteps) {
        await (update(
          hourlyActivityLogTable,
        )..where((t) => t.id.equals(entry.id.value))).write(entry);
      }
    } else {
      await into(hourlyActivityLogTable).insert(entry);
    }

    // Direct push to Supabase
    final Map<String, dynamic> payload = {};
    for (final col in hourlyActivityLogTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(table: 'hourly_activity_log', payload: payload);
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = HourlyActivityLogTableCompanion(
      id: Value(r['id'] as String),
      personID: Value(r['person_id'] as String),
      startTime: Value(DateTime.parse(r['start_time'] as String)),
      endTime: Value(
        r['end_time'] != null ? DateTime.parse(r['end_time'] as String) : null,
      ),
      logDate: Value(DateTime.parse(r['log_date'] as String)),
      stepsCount: Value(r['steps_count'] as int? ?? 0),
      distanceKm: Value((r['distance_km'] as num?)?.toDouble() ?? 0.0),
      caloriesBurned: Value(r['calories_burned'] as int? ?? 0),
    );
    await into(
      hourlyActivityLogTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }
}

@DataClassName('ExternalWidgetData') // The generated data class name
class ExternalWidgetsTable extends Table {
  @override
  String get tableName => 'external_widgets';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get widgetID => text().nullable().named("widget_id")();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get noteID => text().nullable().named('note_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
  TextColumn get projectID => text().nullable().named('project_id')();

  TextColumn get category =>
      text().withDefault(const Constant('projects')).named('category')();

  TextColumn get mood => text().nullable().named('mood')();

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category =>
      text().nullable().named('category')(); // Added category column
  TextColumn get color => text().nullable().named('color')();
  IntColumn get status =>
      integer().withDefault(const Constant(0)).named('status')();
  TextColumn get sshHostId => text().nullable().named('ssh_host_id')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  TextColumn get aiModel => text().nullable().named('ai_model')();
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

@DataClassName('SSHHostData')
class SSHHostsTable extends Table {
  @override
  String get tableName => 'ssh_hosts';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get host => text().named('host')();
  IntColumn get port =>
      integer().withDefault(const Constant(22)).named('port')();
  TextColumn get user => text().named('username')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
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

@DataClassName('SSHSessionData')
class SSHSessionsTable extends Table {
  @override
  String get tableName => 'ssh_sessions';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get ipAddress => text().named('ip_address')();
  TextColumn get localPath => text().nullable().named('local_path')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get sessionName => text().named('session_name')();
  TextColumn get aiModel => text().nullable().named('ai_model')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get emailAddressID =>
      text().nullable().named('email_address_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text().nullable().unique().named('person_id')();
  TextColumn get username => text()
      .withLength(min: 3, max: 50)
      .nullable()
      .unique()
      .named('username')();
  TextColumn get passwordHash => text().nullable().named('password_hash')();
  TextColumn get primaryEmailID =>
      text().nullable().named('primary_email_id')();
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
  TextColumn get personID => text().nullable().unique().named('person_id')();
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
  DateTimeColumn get lastQuestGeneratedAt => dateTime()
      .nullable()
      .map(const DateTimeUTCConverter())
      .named('last_quest_generated_at')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get cvAddressID => text().nullable().named('cv_address_id')();
  TextColumn get personID => text().nullable().unique().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get skillID => text().nullable().named('skill_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get assetID => text().nullable().named('asset_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get transactionID => text().nullable().named('transaction_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
  TextColumn get projectID => text().nullable().named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubscriptionData')
class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text().nullable().named('tenant_id')();
  TextColumn get personID => text().named('person_id')();
  TextColumn get name => text().named('name')();
  RealColumn get amount => real().named('amount')();
  IntColumn get billingDay => integer().named('billing_day')(); // 1-31
  TextColumn get category =>
      text().nullable().named('category')(); // e.g. 'software', 'entertainment'
  BoolColumn get isActive =>
      boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get goalID => text().nullable().named('goal_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
  TextColumn get projectID => text().nullable().named('project_id')();

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get scoreID => text().named('score_id').nullable()();
  TextColumn get personID =>
      text().nullable().nullable().unique().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get habitID => text().nullable().named('habit_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get goalID => text().nullable().named('goal_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  IntColumn get personWidgetID =>
      integer().nullable().named('person_widget_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
  TextColumn get category => text().nullable().named('category')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get mealID => text().nullable().named("meal_id")();
  TextColumn get personID => text().nullable().named("person_id")();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  DateTimeColumn get dayID =>
      dateTime().map(const DateTimeUTCConverter()).named('day_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
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
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  IntColumn get amount =>
      integer().withDefault(const Constant(0)).named('amount')();
  DateTimeColumn get timestamp => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('timestamp')();

  TextColumn get healthMetricID =>
      text().nullable().named('health_metric_id')();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeightLogData')
class WeightLogsTable extends Table {
  @override
  String get tableName => 'weight_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  RealColumn get weightKg =>
      real().withDefault(const Constant(0.0)).named('weight_kg')();
  DateTimeColumn get timestamp => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('timestamp')();

  TextColumn get healthMetricID =>
      text().nullable().named('health_metric_id')();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')
      .nullable()();

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get logID => text().nullable().named('log_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get startTime =>
      dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime()
      .map(const DateTimeUTCConverter())
      .nullable()
      .named('end_time')();
  IntColumn get quality =>
      integer().withDefault(const Constant(3)).named('quality')(); // 1-5 rating

  TextColumn get healthMetricID =>
      text().nullable().named('health_metric_id')();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')
      .nullable()();

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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get healthMetricID =>
      text().nullable().named('health_metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get type => text().named('type')(); // e.g., 'Gym', 'Running'
  IntColumn get durationMinutes => integer().named('duration_minutes')();
  TextColumn get intensity => text()
      .withDefault(const Constant('medium'))
      .named('intensity')(); // low, medium, high
  DateTimeColumn get timestamp => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('timestamp')();
  TextColumn get focusSessionID =>
      text().nullable().named('focus_session_id')();
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

@DataClassName('CustomNotificationData')
class CustomNotificationsTable extends Table {
  @override
  String get tableName => 'custom_notifications';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
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
  TextColumn get personID => text().nullable().named('person_id')();
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
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title =>
      text().withLength(min: 1, max: 200).nullable().named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get type => text()
      .nullable()
      .withDefault(const Constant('daily'))
      .named('type')(); // daily, weekly, secret, system
  TextColumn get questType => text().nullable().named(
    'quest_type',
  )(); // walking, running, swimming, pushups, etc.
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

@DataClassName('PortfolioSnapshotData')
class PortfolioSnapshotsTable extends Table {
  @override
  String get tableName => 'portfolio_snapshots';
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .nullable()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  RealColumn get totalNetWorth => real().named('total_net_worth')();
  RealColumn get athAtTime => real().named('ath_at_time')();
  DateTimeColumn get timestamp => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('timestamp')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AchievementData')
class AchievementsTable extends Table {
  @override
  String get tableName => 'achievements';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get description => text().nullable().named('description')();

  // 'health', 'finance', 'good social impact', 'relationship', 'project', 'knowledge'
  TextColumn get domain =>
      text().withDefault(const Constant('project')).named('domain')();

  // 1-10
  IntColumn get meaningScore => integer()
      .nullable()
      .withDefault(const Constant(5))
      .named('meaning_score')();

  // 1-10 mandatory
  IntColumn get impactScore => integer().named('impact_score')();

  TextColumn get moodPre => text().nullable().named('mood_pre')();
  TextColumn get moodPost => text().nullable().named('mood_post')();
  TextColumn get impactDescWho => text().named('impact_desc_who')();
  TextColumn get impactDescHow => text().named('impact_desc_how')();

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

@DataClassName('MindLogData')
class MindLogsTable extends Table {
  @override
  String get tableName => 'mind_logs';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get tenantID => text().nullable().named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();

  // 1=Awful, 2=Bad, 3=Meh, 4=Good, 5=Rad
  IntColumn get moodScore => integer().named('mood_score')();
  TextColumn get moodEmoji => text().nullable().named('mood_emoji')();

  // JSON array of strings: ["Deep Work", "Exercise", "Family"]
  TextColumn get activities => text().named('activities')();
  TextColumn get note => text().nullable().named('note')();

  DateTimeColumn get logDate => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('log_date')();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [MindLogsTable])
class MindLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$MindLogsDAOMixin {
  MindLogsDAO(super.db);

  Stream<List<MindLogData>> watchLogsByPerson(String personId) {
    return (select(mindLogsTable)
          ..where((tbl) => tbl.personID.equals(personId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> insertLog(MindLogsTableCompanion entry) async {
    await into(mindLogsTable).insert(entry);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in mindLogsTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'mind_logs', payload: payload);
  }

  Future<void> deleteLog(String id) async {
    await (delete(mindLogsTable)..where((tbl) => tbl.id.equals(id))).go();
    // Direct delete from Supabase
    await db.pushToSupabase(
      table: 'mind_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Stream<List<MindLogData>> watchLogsByMood(String personId, int moodScore) {
    return (select(mindLogsTable)
          ..where(
            (tbl) =>
                tbl.personID.equals(personId) & tbl.moodScore.equals(moodScore),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<MindLogData>> watchAllLogs(String personId) {
    return (select(
      mindLogsTable,
    )..where((tbl) => tbl.personID.equals(personId))).watch();
  }

  Stream<List<MindLogData>> watchLogsByDay(String personId, DateTime date) {
    // We normalize to UTC to avoid timezone shifts during sync.
    // If Supabase stores '2026-04-18', it's exactly what we want to find.
    final startOfDay = DateTime.utc(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return (select(mindLogsTable)
          ..where(
            (tbl) =>
                tbl.personID.equals(personId) &
                tbl.logDate.isBetweenValues(startOfDay, endOfDay),
          )
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.logDate, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = MindLogsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(r['tenant_id'] as String?),
      personID: Value(r['person_id'] as String?),
      moodScore: Value(r['mood_score'] as int),
      moodEmoji: Value(r['mood_emoji'] as String?),
      activities: Value(
        r['activities'] is String
            ? r['activities'] as String
            : jsonEncode(r['activities']),
      ),
      note: Value(r['note'] as String?),
      logDate: Value(DateTime.parse(r['log_date'] as String)),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
    );
    await into(
      mindLogsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }
}

@DataClassName('FeedbackLocalData')
class FeedbacksTable extends Table {
  @override
  String get tableName => 'feedbacks';
  TextColumn get id => text()(); // UUID
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get message => text()();
  TextColumn get type => text()(); // bug, feature, other
  TextColumn get localImagePath =>
      text().nullable().named('local_image_path')();
  TextColumn get systemContext =>
      text().nullable().named('system_context')(); // JSON
  TextColumn get status =>
      text().withDefault(const Constant('pending'))(); // pending, synced
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

class ThemeDAO {
  final AppDatabase db;
  ThemeDAO(this.db);

  static const String _themeKey = 'current_theme_path';
  static const String _defaultThemePath = 'assets/DefaultTheme.json';

  Future<void> saveCurrentTheme(CurrentThemeData theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.themePath);
  }

  Future<CurrentThemeData> getCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_themeKey) ?? _defaultThemePath;
    return CurrentThemeData(themePath: path);
  }

  Future<void> insertTheme({
    required String themeName,
    required String themePath,
  }) async {
    // Legacy no-op
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

  Future<void> _pushScoreToSupabase(ScoresTableCompanion entry) async {
    final Map<String, dynamic> payload = {};
    for (final col in scoresTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(table: 'scores', payload: payload);
  }

  Future<void> updateScores(
    ScoresTableCompanion entry, {
    bool force = false,
  }) async {
    final String? personId = entry.personID.value;
    if (personId == null) return;

    final existing = await (select(
      scoresTable,
    )..where((t) => t.personID.equals(personId))).getSingleOrNull();

    _pushScoreToSupabase(entry);

    ScoresTableCompanion finalEntry;

    if (existing != null) {
      final updatedHealth = entry.healthGlobalScore.present
          ? (force ||
                    (entry.healthGlobalScore.value ?? 0.0) >
                        (existing.healthGlobalScore ?? 0.0)
                ? entry.healthGlobalScore
                : Value(existing.healthGlobalScore))
          : Value(existing.healthGlobalScore);

      final updatedSocial = entry.socialGlobalScore.present
          ? (force ||
                    (entry.socialGlobalScore.value ?? 0.0) >
                        (existing.socialGlobalScore ?? 0.0)
                ? entry.socialGlobalScore
                : Value(existing.socialGlobalScore))
          : Value(existing.socialGlobalScore);

      final updatedFinancial = entry.financialGlobalScore.present
          ? (force ||
                    (entry.financialGlobalScore.value ?? 0.0) >
                        (existing.financialGlobalScore ?? 0.0)
                ? entry.financialGlobalScore
                : Value(existing.financialGlobalScore))
          : Value(existing.financialGlobalScore);

      final updatedCareer = entry.careerGlobalScore.present
          ? (force ||
                    (entry.careerGlobalScore.value ?? 0.0) >
                        (existing.careerGlobalScore ?? 0.0)
                ? entry.careerGlobalScore
                : Value(existing.careerGlobalScore))
          : Value(existing.careerGlobalScore);

      final updatedPenalty = entry.penaltyScore.present
          ? (force ||
                    (entry.penaltyScore.value ?? 0.0) >
                        (existing.penaltyScore ?? 0.0)
                ? entry.penaltyScore
                : Value(existing.penaltyScore))
          : Value(existing.penaltyScore);

      finalEntry = entry.copyWith(
        id: Value(existing.id),
        healthGlobalScore: updatedHealth,
        socialGlobalScore: updatedSocial,
        financialGlobalScore: updatedFinancial,
        careerGlobalScore: updatedCareer,
        penaltyScore: updatedPenalty,
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        scoresTable,
      )..where((t) => t.id.equals(existing.id))).write(finalEntry);
    } else {
      final id = entry.id.present ? entry.id.value : IDGen.generateUuid();
      finalEntry = entry.copyWith(
        id: Value(id),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      await into(scoresTable).insert(finalEntry);
    }
  }

  Future<void> incrementScore(
    String personId,
    DateTime date,
    double amount,
    String category, [
    String? tenantId,
  ]) async {
    final existing = await (select(
      scoresTable,
    )..where((t) => t.personID.equals(personId))).getSingleOrNull();

    ScoresTableCompanion companion;
    if (existing == null) {
      companion = ScoresTableCompanion.insert(
        id: IDGen.generateUuid(),
        personID: Value(personId),
        tenantID: Value(tenantId),
        healthGlobalScore: Value(category == 'health' ? amount : 0.0),
        socialGlobalScore: Value(category == 'social' ? amount : 0.0),
        financialGlobalScore: Value(category == 'finance' ? amount : 0.0),
        careerGlobalScore: Value(category == 'career' ? amount : 0.0),
        updatedAt: Value(DateTime.now()),
      );
      await into(scoresTable).insert(companion);
    } else {
      double health = existing.healthGlobalScore ?? 0.0;
      double social = existing.socialGlobalScore ?? 0.0;
      double finance = existing.financialGlobalScore ?? 0.0;
      double career = existing.careerGlobalScore ?? 0.0;

      if (category == 'health') health += amount;
      if (category == 'social') social += amount;
      if (category == 'finance') finance += amount;
      if (category == 'career') career += amount;

      companion = ScoresTableCompanion(
        id: Value(existing.id),
        healthGlobalScore: Value(health),
        socialGlobalScore: Value(social),
        financialGlobalScore: Value(finance),
        careerGlobalScore: Value(career),
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        scoresTable,
      )..where((t) => t.id.equals(existing.id))).write(companion);
    }

    _pushScoreToSupabase(companion);
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    final personId = record['person_id'] as String;
    await into(scoresTable).insert(
      ScoresTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(personId),
        healthGlobalScore: Value(
          (record['health_global_score'] as num?)?.toDouble() ?? 0.0,
        ),
        socialGlobalScore: Value(
          (record['social_global_score'] as num?)?.toDouble() ?? 0.0,
        ),
        financialGlobalScore: Value(
          (record['financial_global_score'] as num?)?.toDouble() ?? 0.0,
        ),
        careerGlobalScore: Value(
          (record['career_global_score'] as num?)?.toDouble() ?? 0.0,
        ),
        penaltyScore: Value(
          (record['penalty_score'] as num?)?.toDouble() ?? 0.0,
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
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

  Future<void> updateCareerScore(
    String personID,
    double score, {
    String? tenantId,
  }) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.id.equals(existing.id))).write(
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
            tenantID: Value(tenantId),
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

  Future<void> updateMindScore(
    String personID, {
    required int strategyNoteCount,
    required double questXP,
    String? tenantId,
  }) async {
    if (personID.isEmpty) return;

    final notePoints = (strategyNoteCount * STRATEGY_NOTE_POINTS).toDouble();
    final finalScore = notePoints + questXP;

    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.id.equals(existing.id))).write(
          ScoresTableCompanion(
            socialGlobalScore: Value(finalScore),
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
            tenantID: Value(tenantId),
            socialGlobalScore: Value(finalScore),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateFinancialScore(
    String personID,
    double score, {
    String? tenantId,
  }) async {
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
            tenantID: Value(tenantId),
            financialGlobalScore: Value(score),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> incrementHealthScore(
    String personID,
    double points, {
    String? tenantId,
  }) async {
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
            tenantID: Value(tenantId),
            healthGlobalScore: Value(points),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
    });
  }

  Future<void> updateHealthScore(
    String personID,
    double score, {
    String? tenantId,
  }) async {
    await transaction(() async {
      final existing = await getScoreByPersonID(personID);
      if (existing != null) {
        await (update(
          scoresTable,
        )..where((t) => t.id.equals(existing.id))).write(
          ScoresTableCompanion(
            healthGlobalScore: Value(score),
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
            tenantID: Value(tenantId),
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

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(externalWidgetsTable).insertOnConflictUpdate(
      ExternalWidgetsTableCompanion.insert(
        id: r['id'] as String,
        tenantID: Value(r['tenant_id'] as String?),
        widgetID: Value(r['widget_id'] as String?),
        personID: Value(r['person_id'] as String?),
        name: Value(r['name'] as String?),
        alias: Value(r['alias'] as String?),
        protocol: Value(r['protocol'] as String?),
        host: Value(r['host'] as String?),
        url: Value(r['url'] as String?),
        imageUrl: Value(r['image_url'] as String?),
        dateAdded: Value(r['date_added'] as String?),
      ),
    );
  }

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
  }) async {
    final id = IDGen.UUIDV7();
    final widgetID = IDGen.UUIDV7();
    final alias = _generateRandomAlias(8);
    final now = DateTime.now().toIso8601String();

    final entry = ExternalWidgetsTableCompanion.insert(
      id: id,
      personID: Value(personID),
      name: Value(
        externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
      ),
      alias: Value(alias),
      widgetID: Value(widgetID),
      host: Value(externalWidgetProtocol.host),
      protocol: Value(externalWidgetProtocol.protocol),
      dateAdded: Value(now),
      url: Value(externalWidgetProtocol.url),
      imageUrl: Value(externalWidgetProtocol.imageUrl),
    );

    final res = await into(attachedDatabase.externalWidgetsTable).insert(entry);

    attachedDatabase.pushToSupabase(
      table: 'external_widgets',
      payload: {
        'id': id,
        'person_id': personID,
        'widget_id': widgetID,
        'name': externalWidgetProtocol.name.isEmpty
            ? 'Unnamed Widget'
            : externalWidgetProtocol.name,
        'alias': alias,
        'host': externalWidgetProtocol.host,
        'protocol': externalWidgetProtocol.protocol,
        'url': externalWidgetProtocol.url,
        'image_url': externalWidgetProtocol.imageUrl,
        'date_added': now,
      },
    );

    return res;
  }

  Future<int> deleteWidget(String id) async {
    final res = await (delete(
      attachedDatabase.externalWidgetsTable,
    )..where((tbl) => tbl.id.equals(id))).go();

    attachedDatabase.pushToSupabase(
      table: 'external_widgets',
      payload: {'id': id},
      isDelete: true,
    );

    return res;
  }

  Future<int> renameExternalWidget(String widgetID, String newName) async {
    final widgetQuery = select(externalWidgetsTable)
      ..where((tbl) => tbl.widgetID.equals(widgetID));
    final widget = await widgetQuery.getSingleOrNull();

    final res =
        await (update(externalWidgetsTable)
              ..where((tbl) => tbl.widgetID.equals(widgetID)))
            .write(ExternalWidgetsTableCompanion(name: Value(newName)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'external_widgets',
        payload: {'id': widget.id, 'name': newName},
      );
    }

    return res;
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
    String? tenantID,
    String? category,
    String? mood,
  }) async {
    final uuid = IDGen.UUIDV7();
    final companion = ProjectNotesTableCompanion.insert(
      id: uuid,
      tenantID: Value(tenantID),
      title: title,
      content: content,
      projectID: Value(projectID),
      personID: Value(personID),
      category: Value(category ?? 'projects'),
      mood: Value(mood),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await into(projectNotesTable).insert(companion);

    await db.pushToSupabase(
      table: 'project_notes',
      payload: db.companionToMap(companion, projectNotesTable),
    );
    return uuid;
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(projectNotesTable).insert(
      ProjectNotesTableCompanion(
        id: Value(record['id'] as String),
        tenantID: Value(record['tenant_id'] as String?),
        personID: Value(record['person_id'] as String?),
        title: Value(record['title'] as String? ?? 'Untitled Note'),
        content: Value(record['content'] as String? ?? ''),
        projectID: Value(record['project_id'] as String?),
        category: Value(record['category'] as String? ?? 'projects'),
        mood: Value(record['mood'] as String?),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> updateNote(ProjectNoteData note) async {
    final updatedNote = note.copyWith(updatedAt: DateTime.now());
    final success = await update(projectNotesTable).replace(updatedNote);
    if (success) {
      await db.pushToSupabase(
        table: 'project_notes',
        payload: updatedNote.toJson(),
      );
    }
    return success;
  }

  Future<int> deleteNote(String id) async {
    final count = await (delete(
      projectNotesTable,
    )..where((tbl) => tbl.id.equals(id))).go();
    if (count > 0) {
      await db.pushToSupabase(
        table: 'project_notes',
        payload: {'id': id},
        isDelete: true,
      );
    }
    return count;
  }

  Stream<List<ProjectNoteData>> watchAllNotes(String personID) {
    return (select(projectNotesTable)..where(
          (tbl) => tbl.personID.equals(personID) | tbl.personID.isNull(),
        ))
        .watch();
  }

  Stream<List<ProjectNoteData>> watchNotesByCategory(
    String personID,
    String category,
  ) {
    return (select(projectNotesTable)..where(
          (tbl) =>
              (tbl.personID.equals(personID) | tbl.personID.isNull()) &
              tbl.category.equals(category),
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

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = ProjectsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(r['tenant_id'] as String?),
      projectID: Value(r['project_id'] as String?),
      personID: Value(r['person_id'] as String?),
      name: Value(r['name'] as String? ?? 'Untitled Project'),
      description: Value(r['description'] as String?),
      category: Value(r['category'] as String?),
      color: Value(r['color'] as String?),
      status: Value(r['status'] as int? ?? 0),
      sshHostId: Value(r['ssh_host_id'] as String?),
      remotePath: Value(r['remote_path'] as String?),
      aiModel: Value(r['ai_model'] as String?),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
      updatedAt: Value(DateTime.parse(r['updated_at'] as String)),
    );
    await into(
      projectsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertProject(ProjectsTableCompanion project) async {
    await into(projectsTable).insert(project);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in projectsTable.$columns) {
      final value = project.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'projects', payload: payload);
  }

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
              sshHostId: row.data['ssh_host_id'] as String?,
              remotePath: row.data['remote_path'] as String?,
              aiModel: row.data['ai_model'] as String?,
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

  Future<void> updateProject(ProjectData project) async {
    await update(projectsTable).replace(project);
    // Convert data class to map
    final payload = project.toJson();
    await db.pushToSupabase(table: 'projects', payload: payload);
  }

  Future<void> updateProjectManual(
    String id,
    ProjectsTableCompanion project,
  ) async {
    await (update(projectsTable)..where((t) => t.id.equals(id))).write(project);

    // Construct payload from companion + ID
    final Map<String, dynamic> payload = {'id': id};
    for (final col in projectsTable.$columns) {
      final value = project.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'projects', payload: payload);
  }

  Future<void> deleteProjectByUuid(String id) async {
    await (delete(projectsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'projects',
      payload: {'id': id},
      isDelete: true,
    );
  }

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
    QuestsTable,
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
    String? tenantId,
  }) async {
    final String newUuid = id ?? IDGen.UUIDV7();

    final companion = PersonsTableCompanion.insert(
      id: newUuid,
      tenantID: Value(tenantId),
      firstName: person.firstName,
      lastName: Value(person.lastName),
      dateOfBirth: Value(person.dateOfBirth),
      gender: Value(person.gender),
      phoneNumber: Value(person.phoneNumber),
      profileImageUrl: Value(person.profileImageUrl),
      isActive: Value(person.isActive),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await into(personsTable).insert(companion);

    if (relationship != null) {
      await (update(personsTable)..where((t) => t.id.equals(newUuid))).write(
        PersonsTableCompanion(relationship: Value(relationship)),
      );
    }

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in personsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'persons', payload: payload);

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

  Future<void> updatePerson(PersonData person) async {
    await update(personsTable).replace(person);
    final companion = PersonsTableCompanion.insert(
      id: person.id,
      firstName: person.firstName,
      lastName: Value(person.lastName),
      dateOfBirth: Value(person.dateOfBirth),
      gender: Value(person.gender),
      phoneNumber: Value(person.phoneNumber),
      profileImageUrl: Value(person.profileImageUrl),
      isActive: Value(person.isActive),
      relationship: Value(person.relationship),
      affection: Value(person.affection),
      tenantID: Value(person.tenantID),
      updatedAt: Value(person.updatedAt),
    );

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in personsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'persons', payload: payload);
  }

  Future<void> updateTenantId(String personId, String tenantId) async {
    final updateCompanion = PersonsTableCompanion(
      tenantID: Value(tenantId),
      updatedAt: Value(DateTime.now()),
    );
    await (update(
      personsTable,
    )..where((t) => t.id.equals(personId))).write(updateCompanion);

    // We only push what changed + ID
    await db.pushToSupabase(
      table: 'persons',
      payload: {
        'id': personId,
        'tenant_id': tenantId,
        'updated_at': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Migrates all data from the guest user account to a new authenticated account.
  /// This is called immediately after a real login to ensure "orphaned" local
  /// progress is promoted to the cloud.
  Future<void> migrateGuestData(
    String newPersonId, [
    String tenantId = DEFAULT_TENANT_ID,
  ]) async {
    const guestId = DataSeeder.guestPersonId;
    if (newPersonId == guestId) return; // No self-migration

    print(
      "🛰️ [Migration] Promoting guest data to user $newPersonId with tenant $tenantId...",
    );

    final tables = [
      'scores',
      'achievements',
      'mind_logs',
      'habits',
      'goals',
      'health_metrics',
      'weight_logs',
      'exercise_logs',
      'sleep_logs',
      'water_logs',
      'financial_metrics',
      'financial_accounts',
      'assets',
      'transactions',
      'subscriptions',
      'portfolio_snapshots',
      'projects',
      'project_notes',
      'project_metrics',
      'skills',
      'focus_sessions',
      'quests',
      'feedbacks',
      'ai_analysis',
      'person_widgets',
      'meals',
      'custom_notifications',
      'quotes',
      'ai_prompts',
    ];

    await transaction(() async {
      for (final table in tables) {
        try {
          // Use raw SQL for speed and to avoid Companion naming discrepancies
          await customUpdate(
            'UPDATE $table SET person_id = ?, tenant_id = ? WHERE person_id = ?',
            variables: [
              Variable(newPersonId),
              Variable(tenantId),
              Variable(guestId),
            ],
          );
        } catch (e) {
          print("⚠️ [Migration] Could not migrate table $table: $e");
        }
      }
      print("✅ [Migration] Comprehensive Guest data migration complete.");
    });
  }

  Future<void> upsertPerson(
    PersonsTableCompanion entry, {
    bool force = false,
  }) async {
    final id = entry.id.value;
    final existing = await getPersonById(id);

    PersonsTableCompanion finalEntry;

    if (existing != null) {
      final updatedAffection = entry.affection.present
          ? (force || (entry.affection.value ?? 0) > (existing.affection ?? 0)
                ? entry.affection
                : Value(existing.affection))
          : Value(existing.affection);

      finalEntry = entry.copyWith(
        affection: updatedAffection,
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        personsTable,
      )..where((t) => t.id.equals(id))).write(finalEntry);
    } else {
      finalEntry = entry.copyWith(
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      );
      await into(personsTable).insert(finalEntry);
    }

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in personsTable.$columns) {
      final value = finalEntry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'persons', payload: payload);
  }

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
  Future<void> addEmail(
    EmailAddressProtocol email, {
    String? overridePersonID,
  }) async {
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
      personID: Value(overridePersonID ?? email.personID),
      emailAddress: email.emailAddress,
      emailType: Value(email.emailType),
      isPrimary: Value(email.isPrimary),
      status: Value(emailStatus),
      verifiedAt: Value(email.verifiedAt),
      createdAt: Value(DateTime.now()),
    );
    await into(emailAddressesTable).insert(companion);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in emailAddressesTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'email_addresses', payload: payload);
  }

  Future<List<EmailAddressData>> getEmailsForPerson(String personId) => (select(
    emailAddressesTable,
  )..where((t) => t.personID.equals(personId))).get();

  Future<void> updateEmail(EmailAddressData email) =>
      update(emailAddressesTable).replace(email);

  // Accounts
  Future<void> createAccount(
    UserAccountProtocol account, {
    String? overridePersonID,
    String? passwordHash,
  }) async {
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

    // Defensive check for username length
    String safeUsername = account.username;
    if (safeUsername.length < 3) {
      safeUsername = "user_${DateTime.now().millisecondsSinceEpoch % 1000}";
    }

    final companion = UserAccountsTableCompanion.insert(
      id: IDGen.UUIDV7(),
      accountID: Value(account.accountID),
      personID: Value(overridePersonID ?? account.personID),
      username: Value(safeUsername),
      passwordHash: Value(passwordHash ?? ''),
      role: Value(userRole),
      isLocked: Value(account.isLocked),
      lastLoginAt: Value(account.lastLoginAt),
      createdAt: Value(DateTime.now()),
      updatedAt: Value(DateTime.now()),
    );
    await into(userAccountsTable).insert(companion);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in userAccountsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'user_accounts', payload: payload);
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
  Future<void> createProfile(
    ProfileProtocol profile,
    String? overridePersonID,
  ) async {
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
    await into(profilesTable).insert(companion);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in profilesTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'profiles', payload: payload);
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
  Future<void> createCVAddress(
    CVAddressProtocol cvAddress, {
    String? overridePersonID,
  }) async {
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
    await into(cVAddressesTable).insert(companion);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in cVAddressesTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'cv_addresses', payload: payload);
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

  Future<void> updateLastQuestGeneratedAt(String personID, DateTime timestamp) {
    return (update(profilesTable)..where((t) => t.personID.equals(personID)))
        .write(ProfilesTableCompanion(lastQuestGeneratedAt: Value(timestamp)));
  }

  Future<void> deleteAllQuestsByPerson(String personID) {
    return (delete(
      questsTable,
    )..where((t) => t.personID.equals(personID))).go();
  }
}

// 4.5 FinanceDAO
@DriftAccessor(
  tables: [
    FinancialAccountsTable,
    AssetsTable,
    TransactionsTable,
    SubscriptionsTable,
  ],
)
class FinanceDAO extends DatabaseAccessor<AppDatabase> with _$FinanceDAOMixin {
  FinanceDAO(super.db);

  // Subscriptions
  Future<void> insertSubscription(
    SubscriptionsTableCompanion subscription,
  ) async {
    await into(subscriptionsTable).insert(subscription);
    await db.pushToSupabase(
      table: 'subscriptions',
      payload: db.companionToMap(subscription, subscriptionsTable),
    );
  }

  Future<void> deleteSubscription(String id) async {
    await (delete(subscriptionsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'subscriptions',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> updateSubscription(
    SubscriptionsTableCompanion subscription,
  ) async {
    await update(subscriptionsTable).replace(subscription);
    await db.pushToSupabase(
      table: 'subscriptions',
      payload: db.companionToMap(subscription, subscriptionsTable),
    );
  }

  Future<void> upsertFromSupabaseSubscription(
    Map<String, dynamic> record,
  ) async {
    await into(subscriptionsTable).insert(
      SubscriptionsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        name: Value(record['name'] as String),
        amount: Value((record['amount'] as num).toDouble()),
        billingDay: Value((record['billing_day'] as num).toInt()),
        category: Value(record['category'] as String?),
        isActive: Value(
          record['is_active'] == true || record['is_active'] == 1,
        ),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<SubscriptionData>> watchSubscriptions(String personId) {
    return (select(subscriptionsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([(t) => OrderingTerm(expression: t.createdAt)]))
        .watch();
  }

  // Accounts
  Future<void> createAccount(FinancialAccountsTableCompanion account) async {
    await into(financialAccountsTable).insert(account);
    await db.pushToSupabase(
      table: 'financial_accounts',
      payload: db.companionToMap(account, financialAccountsTable),
    );
  }

  Future<void> deleteAccount(String id) async {
    await (delete(financialAccountsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'financial_accounts',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> upsertFromSupabaseAccount(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    final personId = record['person_id'] as String;

    final companion = FinancialAccountsTableCompanion(
      id: Value(id),
      accountID: Value(record['account_id'] as String?),
      personID: Value(personId),
      accountName: Value(
        record['account_name'] as String? ?? 'Untitled Account',
      ),
      accountType: Value(record['account_type'] as String? ?? 'checking'),
      balance: Value((record['balance'] as num?)?.toDouble() ?? 0.0),
      currency: Value(
        CurrencyType.values.firstWhere(
          (e) => e.name == record['currency'],
          orElse: () => CurrencyType.USD,
        ),
      ),
      isPrimary: Value(
        record['is_primary'] == true || record['is_primary'] == 1,
      ),
      isActive: Value(record['is_active'] == true || record['is_active'] == 1),
      createdAt: Value(
        record['created_at'] != null
            ? DateTime.parse(record['created_at'].toString())
            : DateTime.now(),
      ),
      updatedAt: Value(
        record['updated_at'] != null
            ? DateTime.parse(record['updated_at'].toString())
            : DateTime.now(),
      ),
    );

    await into(
      financialAccountsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

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
  Future<void> createAsset(AssetsTableCompanion asset) async {
    await into(assetsTable).insert(asset);
    await db.pushToSupabase(
      table: 'assets',
      payload: db.companionToMap(asset, assetsTable),
    );
  }

  Future<void> deleteAsset(String id) async {
    await (delete(assetsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'assets',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> upsertFromSupabaseAsset(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    final personId = record['person_id'] as String;

    await into(assetsTable).insert(
      AssetsTableCompanion(
        id: Value(id),
        assetID: Value(record['asset_id'] as String?),
        personID: Value(personId),
        assetName: Value(record['asset_name'] as String? ?? 'Untitled Asset'),
        assetCategory: Value(record['asset_category'] as String? ?? 'other'),
        purchaseDate: Value(
          record['purchase_date'] != null
              ? DateTime.parse(record['purchase_date'].toString())
              : null,
        ),
        purchasePrice: Value((record['purchase_price'] as num?)?.toDouble()),
        currentEstimatedValue: Value(
          (record['current_estimated_value'] as num?)?.toDouble(),
        ),
        currency: Value(
          CurrencyType.values.firstWhere(
            (e) => e.name == record['currency'],
            orElse: () => CurrencyType.USD,
          ),
        ),
        condition: Value(record['condition'] as String? ?? 'good'),
        location: Value(record['location'] as String?),
        notes: Value(record['notes'] as String?),
        isInsured: Value(
          record['is_insured'] == true || record['is_insured'] == 1,
        ),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

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
  Future<void> insertTransaction(TransactionsTableCompanion txn) async {
    await into(transactionsTable).insert(txn);
    await db.pushToSupabase(
      table: 'transactions',
      payload: db.companionToMap(txn, transactionsTable),
    );
  }

  Future<void> upsertFromSupabaseTransaction(
    Map<String, dynamic> record,
  ) async {
    final id = record['id'] as String;
    final personId = record['person_id'] as String;

    await into(transactionsTable).insert(
      TransactionsTableCompanion(
        id: Value(id),
        transactionID: Value(record['transaction_id'] as String?),
        personID: Value(personId),
        category: Value(record['category'] as String? ?? 'uncategorized'),
        type: Value(record['type'] as String? ?? 'expense'),
        amount: Value((record['amount'] as num?)?.toDouble() ?? 0.0),
        description: Value(record['description'] as String?),
        transactionDate: Value(
          record['transaction_date'] != null
              ? DateTime.parse(record['transaction_date'].toString())
              : DateTime.now(),
        ),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        projectID: Value(record['project_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteTransaction(String id) async {
    await (delete(transactionsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'financial_transactions',
      payload: {'id': id},
      isDelete: true,
    );
  }

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
  Future<void> createHabit(HabitsTableCompanion habit) async {
    await into(habitsTable).insert(habit);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in habitsTable.$columns) {
      final value = habit.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'habits', payload: payload);
  }

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

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    await into(personWidgetsTable).insertOnConflictUpdate(
      PersonWidgetsTableCompanion.insert(
        id: r['id'] as String,
        tenantID: Value(r['tenant_id'] as String?),
        personWidgetID: Value(r['person_widget_id'] as int?),
        personID: Value(r['person_id'] as String?),
        widgetName: r['widget_name'] as String,
        widgetType: r['widget_type'] as String,
        configuration: Value(r['configuration'] as String),
        displayOrder: Value(r['display_order'] as int),
        isActive: Value(r['is_active'] as bool),
        role: Value(
          UserRole.values.firstWhere(
            (e) => e.name == r['role'],
            orElse: () => UserRole.admin,
          ),
        ),
        createdAt: Value(
          r['created_at'] != null
              ? DateTime.tryParse(r['created_at'].toString())
              : null,
        ),
        updatedAt: Value(
          r['updated_at'] != null
              ? DateTime.tryParse(r['updated_at'].toString())
              : null,
        ),
      ),
    );
  }

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

  Future<void> updateWidgetConfig(int id, String newConfig) async {
    final widgetQuery = select(attachedDatabase.personWidgetsTable)
      ..where((t) => t.personWidgetID.equals(id));
    final widget = await widgetQuery.getSingleOrNull();

    await (update(attachedDatabase.personWidgetsTable)
          ..where((t) => t.personWidgetID.equals(id)))
        .write(PersonWidgetsTableCompanion(configuration: Value(newConfig)));

    if (widget != null) {
      attachedDatabase.pushToSupabase(
        table: 'person_widgets',
        payload: {
          'id': widget.id,
          'configuration': newConfig,
          'updated_at': DateTime.now().toIso8601String(),
        },
      );
    }
  }

  Future<void> saveAllWidgets(
    String personId,
    List<InternalWidgetDragProtocol> widgets,
  ) async {
    // 1. Get current widgets to identify what to delete in cloud
    final currentWidgets = await getAllWidgets(personId);

    await transaction(() async {
      // 2. Delete all existing widgets for this person locally
      await (delete(
        attachedDatabase.personWidgetsTable,
      )..where((t) => t.personID.equals(personId))).go();

      // 3. Clear cloud widgets for this person
      // Since we don't have a bulk delete by person_id in pushToSupabase yet,
      // we push individual deletions for simplicity and consistency with the "delete-then-reinsert" reorder pattern.
      for (var oldWidget in currentWidgets) {
        attachedDatabase.pushToSupabase(
          table: 'person_widgets',
          payload: {'id': oldWidget.id},
          isDelete: true,
        );
      }

      // 4. Insert non-empty ones locally and push to cloud
      for (int i = 0; i < widgets.length; i++) {
        final widget = widgets[i];
        if (widget.isEmpty) continue;

        final newId = IDGen.UUIDV7();
        final now = DateTime.now();

        await into(attachedDatabase.personWidgetsTable).insert(
          PersonWidgetsTableCompanion.insert(
            id: newId,
            personID: Value(personId),
            widgetName: widget.name,
            widgetType: widget.alias,
            displayOrder: Value(i),
            configuration: Value(jsonEncode(widget.toJson())),
            updatedAt: Value(now),
          ),
        );

        attachedDatabase.pushToSupabase(
          table: 'person_widgets',
          payload: {
            'id': newId,
            'person_id': personId,
            'widget_name': widget.name,
            'widget_type': widget.alias,
            'display_order': i,
            'configuration': jsonEncode(widget.toJson()),
            'updated_at': now.toIso8601String(),
            'is_active': true,
            'role': 'admin',
          },
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

    final normalized = DateTime(date.year, date.month, date.day, 12, 0, 0);
    final dateStr =
        "${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}";

    // 1. Preferred path: check deterministic ID for 'General' category
    final targetId = IDGen.generateDeterministicUuid(
      personID,
      "$dateStr:General",
    );
    final existingById = await (select(
      healthMetricsTable,
    )..where((t) => t.id.equals(targetId))).getSingleOrNull();
    if (existingById != null) return existingById;

    // 2. Fallback: Search for ANY record within the same logical day for this person
    // A logical day is +/- 12 hours from noon.
    final start = normalized.subtract(const Duration(hours: 12));
    final end = normalized.add(const Duration(hours: 12));

    final records =
        await (select(healthMetricsTable)..where(
              (t) =>
                  t.personID.equals(personID) &
                  t.date.isBetweenValues(start, end),
            ))
            .get();

    if (records.isEmpty) return null;

    // If multiple exist (which cleanupDuplicates should fix), prefer the one with most data or 'General'
    HealthMetricsLocal best = records.first;
    for (var r in records) {
      if (r.category == 'General') {
        best = r;
        break;
      }
      // Or prefer one that actually has steps
      if ((r.steps ?? 0) > (best.steps ?? 0)) {
        best = r;
      }
    }
    return best;
  }

  Future<void> insertOrUpdateMetrics(
    HealthMetricsTableCompanion entry, {
    bool force = false,
  }) async {
    final d = entry.date.value;
    final normalized = DateTime(d.year, d.month, d.day, 12, 0, 0);
    final personId = entry.personID.value;

    if (personId == null || personId.isEmpty) {
      debugPrint("HealthMetricsDAO: Skipping save, personId is empty");
      return;
    }

    final dateStr =
        "${normalized.year}-${normalized.month.toString().padLeft(2, '0')}-${normalized.day.toString().padLeft(2, '0')}";
    final category = entry.category.present
        ? entry.category.value ?? 'General'
        : 'General';
    final deterministicId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:$category",
    );

    // We prefer the record with the deterministic ID
    final existingById = await (select(
      healthMetricsTable,
    )..where((t) => t.id.equals(deterministicId))).getSingleOrNull();

    // Fallback: check if any other record exists for this date/person (to merge and clean up)
    final existingAny = await getMetricsForDate(personId, normalized);

    final HealthMetricsLocal? existing = existingById ?? existingAny;

    if (existing != null) {
      if (existingById == null && existingAny != null) {
        debugPrint(
          "HealthMetricsDAO: FOUND RECORD WITH WRONG ID (${existingAny.id}). Merging into $deterministicId...",
        );
      } else {
        debugPrint(
          "HealthMetricsDAO: Updating existing record ${existing.id}...",
        );
      }

      final currentSteps = entry.steps.present ? entry.steps.value ?? 0 : 0;
      final savedSteps = existing.steps ?? 0;
      final updatedSteps = entry.steps.present
          ? (force || currentSteps > savedSteps
                ? entry.steps
                : Value(savedSteps))
          : Value(savedSteps);

      final currentCalories = entry.caloriesBurned.present
          ? entry.caloriesBurned.value ?? 0
          : 0;
      final savedCalories = existing.caloriesBurned ?? 0;
      final updatedCaloriesBurned = entry.caloriesBurned.present
          ? (force || currentCalories > savedCalories
                ? entry.caloriesBurned
                : Value(savedCalories))
          : Value(savedCalories);

      final currentCaloriesConsumed = entry.caloriesConsumed.present
          ? entry.caloriesConsumed.value ?? 0
          : 0;
      final savedCaloriesConsumed = existing.caloriesConsumed ?? 0;
      final updatedCaloriesConsumed = entry.caloriesConsumed.present
          ? (force || currentCaloriesConsumed > savedCaloriesConsumed
                ? entry.caloriesConsumed
                : Value(savedCaloriesConsumed))
          : Value(savedCaloriesConsumed);

      final updatedSleep = entry.sleepHours.present
          ? (entry.sleepHours.value != null &&
                    (force ||
                        entry.sleepHours.value! > (existing.sleepHours ?? 0))
                ? entry.sleepHours
                : Value(existing.sleepHours))
          : Value(existing.sleepHours);

      final updatedWater = entry.waterGlasses.present
          ? (entry.waterGlasses.value != null &&
                    (force ||
                        entry.waterGlasses.value! >
                            (existing.waterGlasses ?? 0))
                ? entry.waterGlasses
                : Value(existing.waterGlasses))
          : Value(existing.waterGlasses);

      final updatedExercise = entry.exerciseMinutes.present
          ? (entry.exerciseMinutes.value != null &&
                    (force ||
                        entry.exerciseMinutes.value! >
                            (existing.exerciseMinutes ?? 0))
                ? entry.exerciseMinutes
                : Value(existing.exerciseMinutes))
          : Value(existing.exerciseMinutes);

      final updatedFocus = entry.focusMinutes.present
          ? (entry.focusMinutes.value != null &&
                    (force ||
                        entry.focusMinutes.value! >
                            (existing.focusMinutes ?? 0))
                ? entry.focusMinutes
                : Value(existing.focusMinutes))
          : Value(existing.focusMinutes);

      final updatedWeight = entry.weightKg.present
          ? (entry.weightKg.value != null && entry.weightKg.value! > 0
                ? entry.weightKg
                : Value(existing.weightKg))
          : Value(existing.weightKg);

      final updatedHeartRate = entry.heartRate.present
          ? (entry.heartRate.value != null && entry.heartRate.value! > 0
                ? entry.heartRate
                : Value(existing.heartRate))
          : Value(existing.heartRate);

      final updatedQuestPoints = entry.questPoints.present
          ? (force ||
                    (entry.questPoints.value ?? 0.0) >
                        (existing.questPoints ?? 0.0)
                ? entry.questPoints
                : Value(existing.questPoints))
          : Value(existing.questPoints);

      // Perform upsert on the deterministic ID manually because health_metrics is a view
      final tbl = healthMetricsTable;
      final existingRecord = await (select(
        tbl,
      )..where((t) => t.id.equals(deterministicId))).getSingleOrNull();

      final updatedCompanion = entry.copyWith(
        id: Value(deterministicId),
        date: Value(normalized),
        category: Value(category),
        steps: updatedSteps,
        caloriesBurned: updatedCaloriesBurned,
        caloriesConsumed: updatedCaloriesConsumed,
        sleepHours: updatedSleep,
        waterGlasses: updatedWater,
        exerciseMinutes: updatedExercise,
        focusMinutes: updatedFocus,
        weightKg: updatedWeight,
        heartRate: updatedHeartRate,
        questPoints: updatedQuestPoints,
        updatedAt: Value(DateTime.now()),
      );

      HealthMetricsTableCompanion finalCompanion;

      if (existingRecord != null) {
        finalCompanion = updatedCompanion;
        await (update(
          tbl,
        )..where((t) => t.id.equals(deterministicId))).write(finalCompanion);
      } else {
        finalCompanion = updatedCompanion;
        await into(tbl).insert(finalCompanion);
      }

      // Clean up the legacy record if it had a different ID
      if (existingAny != null && existingAny.id != deterministicId) {
        debugPrint(
          "HealthMetricsDAO: Deleting legacy duplicated record ${existingAny.id}...",
        );
        await (delete(
          healthMetricsTable,
        )..where((t) => t.id.equals(existingAny.id))).go();
      }

      debugPrint(
        "HealthMetricsDAO: ✅ Record converged to $deterministicId successfully.",
      );

      // Convert companion to map with raw values
      final Map<String, dynamic> payload = {};
      for (final col in healthMetricsTable.$columns) {
        final value = finalCompanion.toColumns(true)[col.name];
        if (value is Variable) {
          payload[col.name] = value.value;
        }
      }

      // Direct push to Supabase
      await db.pushToSupabase(table: 'health_metrics', payload: payload);
    } else {
      debugPrint(
        "HealthMetricsDAO: Inserting new record (ID: $deterministicId)...",
      );
      final finalCompanion = entry.copyWith(
        id: Value(deterministicId),
        date: Value(normalized),
        category: Value(category),
        updatedAt: Value(DateTime.now()),
      );
      await into(
        healthMetricsTable,
      ).insert(finalCompanion, mode: InsertMode.insertOrReplace);
      debugPrint("HealthMetricsDAO: ✅ New record inserted successfully.");

      // Convert companion to map with raw values
      final Map<String, dynamic> payload = {};
      for (final col in healthMetricsTable.$columns) {
        final value = finalCompanion.toColumns(true)[col.name];
        if (value is Variable) {
          payload[col.name] = value.value;
        }
      }

      // Direct push to Supabase
      await db.pushToSupabase(table: 'health_metrics', payload: payload);
    }
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = HealthMetricsTableCompanion(
      id: Value(r['id'] as String),
      personID: Value(r['person_id'] as String?),
      date: Value(DateTime.parse(r['date'] as String)),
      steps: Value(r['steps'] as int?),
      caloriesBurned: Value(r['calories_burned'] as int?),
      caloriesConsumed: Value(r['calories_consumed'] as int?),
      sleepHours: Value((r['sleep_hours'] as num?)?.toDouble()),
      waterGlasses: Value(r['water_glasses'] as int?),
      exerciseMinutes: Value(r['exercise_minutes'] as int?),
      focusMinutes: Value(r['focus_minutes'] as int?),
      weightKg: Value((r['weight_kg'] as num?)?.toDouble()),
      heartRate: Value((r['heart_rate'] as num?)?.toInt()),
      questPoints: Value((r['quest_points'] as num?)?.toDouble()),
      updatedAt: Value(
        r['updated_at'] != null
            ? DateTime.parse(r['updated_at'] as String)
            : DateTime.now(),
      ),
      category: Value(r['category'] as String?),
    );
    await into(
      healthMetricsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
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

    if (all.isEmpty) return;

    final Map<String, List<HealthMetricsLocal>> grouped = {};
    for (var m in all) {
      final key =
          "${m.date.year}-${m.date.month.toString().padLeft(2, '0')}-${m.date.day.toString().padLeft(2, '0')}";
      grouped.putIfAbsent(key, () => []).add(m);
    }

    for (var entry in grouped.entries) {
      if (entry.value.length > 1) {
        // Find or create a winner (prefer General category or the one with deterministic ID)
        final dateStr = entry.key;
        final targetId = IDGen.generateDeterministicUuid(
          personId,
          "$dateStr:General",
        );

        HealthMetricsLocal winner = entry.value.first;
        for (var m in entry.value) {
          if (m.id == targetId) {
            winner = m;
            break;
          }
          if (m.category == 'General') {
            winner = m;
          }
        }

        // Merge all data from others into the winner
        int maxSteps = winner.steps ?? 0;
        int maxCaloriesBurned = winner.caloriesBurned ?? 0;
        int maxWater = winner.waterGlasses ?? 0;
        int maxExercise = winner.exerciseMinutes ?? 0;
        int maxFocus = winner.focusMinutes ?? 0;
        double maxSleep = winner.sleepHours ?? 0.0;
        double latestWeight = winner.weightKg ?? 0.0;
        int latestHeartRate = winner.heartRate ?? 0;

        for (var m in entry.value) {
          if (m.id == winner.id) continue;
          if ((m.steps ?? 0) > maxSteps) maxSteps = m.steps!;
          if ((m.caloriesBurned ?? 0) > maxCaloriesBurned) {
            maxCaloriesBurned = m.caloriesBurned!;
          }
          if ((m.waterGlasses ?? 0) > maxWater) maxWater = m.waterGlasses!;
          if ((m.exerciseMinutes ?? 0) > maxExercise) {
            maxExercise = m.exerciseMinutes!;
          }
          if ((m.focusMinutes ?? 0) > maxFocus) maxFocus = m.focusMinutes!;
          if ((m.sleepHours ?? 0.0) > maxSleep) maxSleep = m.sleepHours!;
          if ((m.weightKg ?? 0.0) > 0) latestWeight = m.weightKg!;
          if ((m.heartRate ?? 0) > 0) latestHeartRate = m.heartRate!;
        }

        // Update winner
        await (update(
          healthMetricsTable,
        )..where((t) => t.id.equals(winner.id))).write(
          HealthMetricsTableCompanion(
            steps: Value(maxSteps),
            caloriesBurned: Value(maxCaloriesBurned),
            waterGlasses: Value(maxWater),
            exerciseMinutes: Value(maxExercise),
            focusMinutes: Value(maxFocus),
            sleepHours: Value(maxSleep),
            weightKg: Value(latestWeight),
            heartRate: Value(latestHeartRate),
            updatedAt: Value(DateTime.now()),
          ),
        );

        // Delete others
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

  Future<void> updateWeight(
    String personID,
    DateTime date,
    double weight,
  ) async {
    await insertOrUpdateMetrics(
      HealthMetricsTableCompanion.insert(
        id: IDGen.generateDeterministicUuid(
          personID,
          "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}:General",
        ),
        personID: Value(personID),
        date: date,
        weightKg: Value(weight),
      ),
    );
  }
}

@DriftAccessor(
  tables: [
    HealthMetricsTable,
    FinancialMetricsTable,
    ProjectMetricsTable,
    SocialMetricsTable,
    WeightLogsTable,
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
      "$dateStr:$category",
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

        // Sum points from all records in existingList
        double totalExistingPoints = 0.0;
        for (var m in existingList) {
          totalExistingPoints += (m.questPoints ?? 0.0);
        }

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
            questPoints: Value(totalExistingPoints + points),
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
      "$dateStr:$category",
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

        // Sum points from all records in existingList
        double totalExistingPoints = 0.0;
        for (var m in existingList) {
          totalExistingPoints += (m.questPoints ?? 0.0);
        }

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
            questPoints: Value(totalExistingPoints + points),
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
      "$dateStr:$category",
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

        // Sum points from all records in existingList
        double totalExistingPoints = 0.0;
        for (var m in existingList) {
          totalExistingPoints += (m.questPoints ?? 0.0);
        }

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
            questPoints: Value(totalExistingPoints + points),
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
      "$dateStr:$category",
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

        // Sum points from all records in existingList
        double totalExistingPoints = 0.0;
        for (var m in existingList) {
          totalExistingPoints += (m.questPoints ?? 0.0);
        }

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
            questPoints: Value(totalExistingPoints + points),
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

  Future<void> insertOrUpdateSocialMetrics(
    SocialMetricsTableCompanion entry, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    final personId = entry.personID.value;
    if (personId == null) return;

    final date = entry.date.value;
    final today = DateTime(date.year, date.month, date.day);
    final category = entry.category.present
        ? entry.category.value ?? 'General'
        : 'General';
    final dateStr = _getDateStr(today);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:$category",
    );

    await transaction(() async {
      final existing = await (select(
        socialMetricsTable,
      )..where((t) => t.id.equals(targetId))).getSingleOrNull();

      if (existing != null) {
        final updatedPoints = entry.questPoints.present
            ? (force ||
                      (entry.questPoints.value ?? 0.0) >
                          (existing.questPoints ?? 0.0)
                  ? entry.questPoints
                  : Value(existing.questPoints))
            : Value(existing.questPoints);

        final updatedAffection = entry.totalAffection.present
            ? (force ||
                      (entry.totalAffection.value ?? 0) >
                          (existing.totalAffection ?? 0)
                  ? entry.totalAffection
                  : Value(existing.totalAffection))
            : Value(existing.totalAffection);

        final updatedCount = entry.contactsCount.present
            ? (force ||
                      (entry.contactsCount.value ?? 0) >
                          (existing.contactsCount ?? 0)
                  ? entry.contactsCount
                  : Value(existing.contactsCount))
            : Value(existing.contactsCount);

        await (update(
          socialMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          entry.copyWith(
            questPoints: updatedPoints,
            totalAffection: updatedAffection,
            contactsCount: updatedCount,
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(socialMetricsTable).insert(
          entry.copyWith(
            id: Value(targetId),
            date: Value(today),
            category: Value(category),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> insertOrUpdateFinancialMetrics(
    FinancialMetricsTableCompanion entry, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    final personId = entry.personID.value;
    if (personId == null) return;

    final date = entry.date.value;
    final today = DateTime(date.year, date.month, date.day);
    final category = entry.category.present
        ? entry.category.value ?? 'General'
        : 'General';
    final dateStr = _getDateStr(today);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:$category",
    );

    await transaction(() async {
      final existing = await (select(
        financialMetricsTable,
      )..where((t) => t.id.equals(targetId))).getSingleOrNull();

      if (existing != null) {
        final updatedPoints = entry.questPoints.present
            ? (force ||
                      (entry.questPoints.value ?? 0.0) >
                          (existing.questPoints ?? 0.0)
                  ? entry.questPoints
                  : Value(existing.questPoints))
            : Value(existing.questPoints);

        // For balance, we use Latest Wins (default) unless it's specifically quest points
        await (update(
          financialMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          entry.copyWith(questPoints: updatedPoints, updatedAt: Value(now)),
        );
      } else {
        await into(financialMetricsTable).insert(
          entry.copyWith(
            id: Value(targetId),
            date: Value(today),
            category: Value(category),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  Future<void> insertOrUpdateProjectMetrics(
    ProjectMetricsTableCompanion entry, {
    bool force = false,
  }) async {
    final now = DateTime.now();
    final personId = entry.personID.value;
    if (personId == null) return;

    final date = entry.date.value;
    final today = DateTime(date.year, date.month, date.day);
    final category = entry.category.present
        ? entry.category.value ?? 'General'
        : 'General';
    final dateStr = _getDateStr(today);
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:$category",
    );

    await transaction(() async {
      final existing = await (select(
        projectMetricsTable,
      )..where((t) => t.id.equals(targetId))).getSingleOrNull();

      if (existing != null) {
        final updatedPoints = entry.questPoints.present
            ? (force ||
                      (entry.questPoints.value ?? 0.0) >
                          (existing.questPoints ?? 0.0)
                  ? entry.questPoints
                  : Value(existing.questPoints))
            : Value(existing.questPoints);

        final updatedTasks = entry.tasksCompleted.present
            ? (force ||
                      (entry.tasksCompleted.value ?? 0) >
                          (existing.tasksCompleted ?? 0)
                  ? entry.tasksCompleted
                  : Value(existing.tasksCompleted))
            : Value(existing.tasksCompleted);

        final updatedProjects = entry.projectsCompleted.present
            ? (force ||
                      (entry.projectsCompleted.value ?? 0) >
                          (existing.projectsCompleted ?? 0)
                  ? entry.projectsCompleted
                  : Value(existing.projectsCompleted))
            : Value(existing.projectsCompleted);

        final updatedFocus = entry.focusMinutes.present
            ? (force ||
                      (entry.focusMinutes.value ?? 0) >
                          (existing.focusMinutes ?? 0)
                  ? entry.focusMinutes
                  : Value(existing.focusMinutes))
            : Value(existing.focusMinutes);

        await (update(
          projectMetricsTable,
        )..where((t) => t.id.equals(existing.id))).write(
          entry.copyWith(
            questPoints: updatedPoints,
            tasksCompleted: updatedTasks,
            projectsCompleted: updatedProjects,
            focusMinutes: updatedFocus,
            updatedAt: Value(now),
          ),
        );
      } else {
        await into(projectMetricsTable).insert(
          entry.copyWith(
            id: Value(targetId),
            date: Value(today),
            category: Value(category),
            updatedAt: Value(now),
          ),
        );
      }
    });
  }

  // Watchers for today's metrics
  Stream<HealthMetricsLocal?> watchTodayHealth(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:General",
    );
    return (select(
      healthMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<SocialMetricsLocal?> watchTodaySocial(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:General",
    );
    return (select(
      socialMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<ProjectMetricsLocal?> watchTodayProject(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:General",
    );
    return (select(
      projectMetricsTable,
    )..where((t) => t.id.equals(targetId))).watchSingleOrNull();
  }

  Stream<FinancialMetricsLocal?> watchTodayFinancial(String personId) {
    final dateStr = _getDateStr(DateTime.now());
    final targetId = IDGen.generateDeterministicUuid(
      personId,
      "$dateStr:General",
    );
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

  // --- Today's Quest Points Watchers ---

  Stream<double> watchTodayHealthQuestPoints(String personId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return customSelect(
      'SELECT SUM(quest_points) as total FROM health_metrics WHERE person_id = ? AND date = ?',
      variables: [Variable.withString(personId), Variable.withDateTime(today)],
      readsFrom: {healthMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTodaySocialQuestPoints(String personId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return customSelect(
      'SELECT SUM(quest_points) as total FROM social_metrics WHERE person_id = ? AND date = ?',
      variables: [Variable.withString(personId), Variable.withDateTime(today)],
      readsFrom: {socialMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTodayProjectQuestPoints(String personId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return customSelect(
      'SELECT SUM(quest_points) as total FROM project_metrics WHERE person_id = ? AND date = ?',
      variables: [Variable.withString(personId), Variable.withDateTime(today)],
      readsFrom: {projectMetricsTable},
    ).watchSingle().map((row) {
      final val = row.data['total'];
      return (val as num?)?.toDouble() ?? 0.0;
    });
  }

  Stream<double> watchTodayFinancialQuestPoints(String personId) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return customSelect(
      'SELECT SUM(quest_points) as total FROM financial_metrics WHERE person_id = ? AND date = ?',
      variables: [Variable.withString(personId), Variable.withDateTime(today)],
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
  Future<int> insertDay(DaysTableCompanion day) =>
      into(attachedDatabase.daysTable).insert(day);

  Future<void> upsertDay(DaysTableCompanion entry) async {
    final tbl = attachedDatabase.daysTable;
    final existing = await (select(
      tbl,
    )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();

    if (existing != null) {
      final currentCalories = entry.caloriesOut.present
          ? entry.caloriesOut.value
          : 0;
      final existingCalories = existing.caloriesOut;
      if (currentCalories > existingCalories) {
        await (update(
          tbl,
        )..where((t) => t.id.equals(existing.id))).write(entry);
      }
    } else {
      await into(tbl).insert(entry);
    }
  }

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

QueryExecutor _openConnection() {
  return driftDatabase(name: 'db9');
}

// --- Focus Session ---
@DataClassName('FocusSessionData')
class FocusSessionsTable extends Table {
  @override
  String get tableName => 'focus_sessions';
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get taskID => text().nullable().named('task_id')();
  DateTimeColumn get startTime =>
      dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime()
      .map(const DateTimeUTCConverter())
      .nullable()
      .named('end_time')();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
  TextColumn get status => text()
      .withLength(min: 1, max: 20)
      .named('status')(); // 'completed', 'interrupted'
  TextColumn get sessionType => text()
      .withLength(min: 1, max: 20)
      .withDefault(const Constant('Focus'))
      .named('session_type')();
  TextColumn get notes => text().nullable().named('notes')();

  /// e.g. `health-exercise` when session was started from exercise timer flow.
  TextColumn get categories => text().nullable().named('categories')();

  DateTimeColumn get createdAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('created_at')
      .nullable()();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')
      .nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [FocusSessionsTable])
class FocusSessionsDAO extends DatabaseAccessor<AppDatabase>
    with _$FocusSessionsDAOMixin {
  FocusSessionsDAO(super.db);

  Future<void> upsertFromSupabase(Map<String, dynamic> r) async {
    final companion = FocusSessionsTableCompanion(
      id: Value(r['id'] as String),
      tenantID: Value(
        r['tenant_id'] as String? ?? '00000000-0000-0000-0000-000000000000',
      ),
      personID: Value(r['person_id'] as String?),
      projectID: Value(r['project_id'] as String?),
      taskID: Value(r['task_id'] as String?),
      startTime: Value(DateTime.parse(r['start_time'] as String)),
      endTime: Value(
        r['end_time'] != null ? DateTime.parse(r['end_time'] as String) : null,
      ),
      durationSeconds: Value(r['duration_seconds'] as int? ?? 0),
      status: Value(r['status'] as String? ?? 'completed'),
      sessionType: Value(r['session_type'] as String? ?? 'Focus'),
      createdAt: Value(DateTime.parse(r['created_at'] as String)),
      updatedAt: Value(
        r['updated_at'] != null
            ? DateTime.parse(r['updated_at'] as String)
            : DateTime.now(),
      ),
    );
    await into(
      focusSessionsTable,
    ).insert(companion, mode: InsertMode.insertOrReplace);
  }

  Future<void> insertSession(FocusSessionsTableCompanion session) async {
    await into(focusSessionsTable).insert(session);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in focusSessionsTable.$columns) {
      final value = session.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'focus_sessions', payload: payload);
  }

  Stream<List<FocusSessionData>> watchSessionsByPerson(String personId) {
    return (select(
      focusSessionsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  Stream<List<FocusSessionData>> watchAllSessions() {
    return select(focusSessionsTable).watch();
  }

  Future<void> deleteSession(String id) async {
    await (delete(focusSessionsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'focus_sessions',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Future<void> patchSession(
    String id,
    FocusSessionsTableCompanion companion,
  ) async {
    await (update(
      focusSessionsTable,
    )..where((t) => t.id.equals(id))).write(companion);

    // Construct payload from companion + ID
    final Map<String, dynamic> payload = {'id': id};
    for (final col in focusSessionsTable.$columns) {
      final value = companion.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    await db.pushToSupabase(table: 'focus_sessions', payload: payload);
  }
}

@DataClassName('QuoteData')
class QuotesTable extends Table {
  @override
  String get tableName => 'quotes';
  TextColumn get id => text()();
  TextColumn get tenantID => text()
      .withDefault(const Constant(DEFAULT_TENANT_ID))
      .named('tenant_id')();
  // IntColumn get quoteID => integer().nullable().named('quote_id')();
  TextColumn get personID => text().nullable().named('person_id')();
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

  Future<void> insertQuote(QuotesTableCompanion entry) async {
    await into(quotesTable).insert(entry);

    // Convert companion to map with raw values
    final Map<String, dynamic> payload = {};
    for (final col in quotesTable.$columns) {
      final value = entry.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }

    // Direct push to Supabase
    await db.pushToSupabase(table: 'quotes', payload: payload);
  }

  Future<bool> updateQuote(QuoteData entry) =>
      update(quotesTable).replace(entry);

  Future<int> deleteQuote(String id) =>
      (delete(quotesTable)..where((t) => t.id.equals(id))).go();

  Future<List<QuoteData>> getAllQuotes() async {
    final rows = await customSelect('SELECT * FROM quotes').get();
    return rows
        .map((row) {
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
            tenantID: row.data['tenant_id'] as String? ?? DEFAULT_TENANT_ID,
            personID: row.data['person_id'] as String? ?? '',
            content: row.data['content'] as String? ?? '',
            author: row.data['author'] as String?,
            isActive:
                (row.data['is_active'] as int?) == 1 ||
                (row.data['is_active'] as bool?) == true,
            createdAt: createdAt ?? DateTime.now(),
          );
        })
        .cast<QuoteData>()
        .toList();
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
              tenantID: row.data['tenant_id'] as String? ?? DEFAULT_TENANT_ID,
              personID: row.data['person_id'] as String? ?? '',
              content: row.data['content'] as String? ?? '',
              author: row.data['author'] as String?,
              isActive:
                  (row.data['is_active'] as int?) == 1 ||
                  (row.data['is_active'] as bool?) == true,
              createdAt: _parseDate(row.data['created_at']),
            ),
          )
          .cast<QuoteData>()
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

  Stream<int> watchEnabledNotificationsCount(String personId) {
    return (select(
          customNotificationsTable,
        )..where((t) => t.isEnabled.equals(true) & t.personID.equals(personId)))
        .watch()
        .map((list) => list.length);
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

@DriftAccessor(tables: [SSHHostsTable])
class SSHHostsDAO extends DatabaseAccessor<AppDatabase>
    with _$SSHHostsDAOMixin {
  SSHHostsDAO(super.db);

  Future<int> insertSSHHost(SSHHostsTableCompanion entry) =>
      into(sSHHostsTable).insert(entry);

  Future<bool> updateSSHHost(SSHHostData entry) =>
      update(sSHHostsTable).replace(entry);

  Future<int> deleteSSHHost(String id) =>
      (delete(sSHHostsTable)..where((t) => t.id.equals(id))).go();

  Stream<List<SSHHostData>> watchAllSSHHosts() => select(sSHHostsTable).watch();

  Future<SSHHostData?> getSSHHostById(String id) =>
      (select(sSHHostsTable)..where((t) => t.id.equals(id))).getSingleOrNull();
}

@DriftAccessor(tables: [FeedbacksTable])
class FeedbackDAO extends DatabaseAccessor<AppDatabase>
    with _$FeedbackDAOMixin {
  FeedbackDAO(super.db);

  Future<int> insertFeedback(FeedbackLocalData feedback) {
    return into(feedbacksTable).insert(feedback);
  }

  Future<List<FeedbackLocalData>> getPendingFeedbacks() {
    return (select(
      feedbacksTable,
    )..where((t) => t.status.equals('pending'))).get();
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

@DriftAccessor(tables: [QuestsTable])
class QuestDAO extends DatabaseAccessor<AppDatabase> with _$QuestDAOMixin {
  QuestDAO(super.db);

  Future<void> insertQuest(QuestsTableCompanion entry) async {
    // Force category to lowercase if present
    var updatedEntry = entry;
    if (entry.category.present) {
      final categoryValue = entry.category.value;
      updatedEntry = entry.copyWith(
        category: Value(categoryValue?.toLowerCase()),
      );
    }
    await into(questsTable).insert(updatedEntry);

    // Direct push to Supabase using shared helper
    await db.pushToSupabase(
      table: 'quests',
      payload: db.companionToMap(updatedEntry, questsTable),
    );
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(questsTable).insert(
      QuestsTableCompanion(
        id: Value(record['id'] as String),
        tenantID: Value(record['tenant_id'] as String?),
        personID: Value(record['person_id'] as String?),
        title: Value(record['title'] as String?),
        description: Value(record['description'] as String?),
        type: Value(record['type'] as String?),
        targetValue: Value((record['target_value'] as num?)?.toDouble()),
        currentValue: Value((record['current_value'] as num?)?.toDouble()),
        category: Value(record['category'] as String?),
        rewardExp: Value(record['reward_exp'] as int?),
        isCompleted: Value(record['is_completed'] as bool?),
        createdAt: Value(
          record['created_at'] != null
              ? DateTime.parse(record['created_at'].toString())
              : DateTime.now(),
        ),
        penaltyScore: Value(record['penalty_score'] as int?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<bool> updateQuest(QuestData entry) {
    final updatedEntry = entry.copyWith(
      category: Value(entry.category?.toLowerCase()),
    );
    return update(questsTable).replace(updatedEntry);
  }

  Future<int> deleteQuest(String id) async {
    final count = await (delete(
      questsTable,
    )..where((t) => t.id.equals(id))).go();
    if (count > 0) {
      await db.pushToSupabase(
        table: 'quests',
        payload: {'id': id},
        isDelete: true,
      );
    }
    return count;
  }

  /// Clears stale auto-generated dailies before inserting a new day's batch.
  Future<int> deleteIncompleteDailyQuestsForPerson(String personId) {
    return (delete(questsTable)..where(
          (t) =>
              t.personID.equals(personId) &
              t.isCompleted.equals(false) &
              t.type.equals('daily'),
        ))
        .go();
  }

  /// Removes all secret quests for a person. Used to clean up mock mysterious quests.
  Future<int> deleteSecretQuestsForPerson(String personId) {
    return (delete(questsTable)
          ..where((t) => t.personID.equals(personId) & t.type.equals('secret')))
        .go();
  }

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
      final companion = QuestsTableCompanion(
        id: Value(id),
        currentValue: Value(newValue),
        isCompleted: Value(isNowCompleted),
      );
      await (update(
        questsTable,
      )..where((t) => t.id.equals(id))).write(companion);

      await db.pushToSupabase(
        table: 'quests',
        payload: db.companionToMap(companion, questsTable),
      );
    }
  }
}

/// Lightweight result class returned by [HealthLogsDAO.getDailyExerciseWithSession].
/// Combines an exercise_logs row with the exact duration_seconds from the
/// parent focus_session (via LEFT JOIN). For manually-logged entries,
/// [exactDurationSeconds] is null and [durationMinutes] holds the directly stored value.
class ExerciseWithFocusSession {
  /// Primary key of the exercise_log row
  final String id;
  final String personId;

  /// Activity type string, e.g. "Running", "Gym"
  final String type;

  /// Duration in minutes — either derived from [exactDurationSeconds] ~/ 60
  /// (if this log was created by the FocusBlock timer) or stored directly.
  final int durationMinutes;

  /// Exact seconds from the parent focus_session.duration_seconds.
  /// NULL for manually-logged entries (those have no parent focus session).
  final int? exactDurationSeconds;

  final String intensity;
  final DateTime timestamp;

  /// FK to focus_sessions.id — null for manual entries.
  final String? focusSessionId;

  const ExerciseWithFocusSession({
    required this.id,
    required this.personId,
    required this.type,
    required this.durationMinutes,
    required this.exactDurationSeconds,
    required this.intensity,
    required this.timestamp,
    required this.focusSessionId,
  });

  /// Returns the authoritative duration in seconds:
  /// exact seconds from focus_session if available, otherwise durationMinutes * 60.
  int get durationSeconds => exactDurationSeconds ?? (durationMinutes * 60);
}

// Adding FocusSessionsTable to the DAO's accessor list gives Drift's generated
// mixin the focusSessionsTable getter, which is required for the JOIN readsFrom set.
@DriftAccessor(
  tables: [
    WaterLogsTable,
    SleepLogsTable,
    ExerciseLogsTable,
    WeightLogsTable,
    FocusSessionsTable,
  ],
)
class HealthLogsDAO extends DatabaseAccessor<AppDatabase>
    with _$HealthLogsDAOMixin {
  HealthLogsDAO(super.db);

  // Water Logs
  Future<void> insertWaterLog(WaterLogsTableCompanion entry) async {
    await into(waterLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'water_logs',
      payload: db.companionToMap(entry, waterLogsTable),
    );
  }

  Future<void> upsertFromSupabaseWater(Map<String, dynamic> record) async {
    await into(waterLogsTable).insert(
      WaterLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        amount: Value((record['amount'] as num).toInt()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

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

  Future<void> deleteWaterLog(String id) async {
    await (delete(waterLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'water_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  /// Sum all water log amounts (in ml) for a given person on a specific day.
  /// This is the "group by day" aggregation used to populate health_metrics.water_glasses.
  /// Returns total ml consumed for that day (0 if no records exist).
  Future<int> getDailyWaterTotal(String personId, DateTime date) async {
    // Define the day's time boundary: [start of day, start of next day)
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // Fetch all water log entries for this person on this day
    final logs =
        await (select(waterLogsTable)..where(
              (t) =>
                  t.personID.equals(personId) &
                  t.timestamp.isBetweenValues(start, end),
            ))
            .get();

    // Sum the amount column — this replaces the need for a raw SQL GROUP BY
    return logs.fold<int>(0, (sum, log) => sum + log.amount);
  }

  // Sleep Logs
  Future<void> insertSleepLog(SleepLogsTableCompanion entry) async {
    await into(sleepLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'sleep_logs',
      payload: db.companionToMap(entry, sleepLogsTable),
    );
  }

  Future<void> upsertFromSupabaseSleep(Map<String, dynamic> record) async {
    await into(sleepLogsTable).insert(
      SleepLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        startTime: Value(DateTime.parse(record['start_time'].toString())),
        endTime: Value(DateTime.parse(record['end_time'].toString())),
        quality: Value((record['quality'] as num?)?.toInt() ?? 3),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteSleepLog(String id) async {
    await (delete(sleepLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'sleep_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

  Stream<List<SleepLogData>> watchSleepLogs(String personId) {
    return (select(
      sleepLogsTable,
    )..where((t) => t.personID.equals(personId))).watch();
  }

  // Exercise Logs
  Future<void> insertExerciseLog(ExerciseLogsTableCompanion entry) async {
    await into(exerciseLogsTable).insert(entry);
    await db.pushToSupabase(
      table: 'exercise_logs',
      payload: db.companionToMap(entry, exerciseLogsTable),
    );
  }

  Future<void> upsertFromSupabaseExercise(Map<String, dynamic> record) async {
    await into(exerciseLogsTable).insert(
      ExerciseLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        type: Value(record['type'] as String),
        durationMinutes: Value((record['duration_minutes'] as num).toInt()),
        intensity: Value(record['intensity'] as String),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        focusSessionID: Value(record['focus_session_id'] as String?),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> deleteExerciseLog(String id) async {
    await (delete(exerciseLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'exercise_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }

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

  /// Sum all durationMinutes from exercise_logs for a given person/day.
  /// Equivalent to: SELECT SUM(duration_minutes) FROM exercise_logs
  ///                WHERE person_id = ? AND timestamp BETWEEN start AND end
  /// The result feeds into health_metrics.exercise_minutes via HealthBlock._saveExercise().
  Future<int> getDailyExerciseTotal(String personId, DateTime date) async {
    // Define day boundary: [start of day, start of next day)
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // Fetch all exercise log entries for this person on this day
    final logs =
        await (select(exerciseLogsTable)..where(
              (t) =>
                  t.personID.equals(personId) &
                  t.timestamp.isBetweenValues(start, end),
            ))
            .get();

    // SUM(duration_minutes) — Dart-side aggregation (no raw SQL GROUP BY needed)
    return logs.fold<int>(0, (sum, log) => sum + log.durationMinutes);
  }

  /// JOIN exercise_logs with focus_sessions to get enriched session data.
  ///
  /// Returns each exercise log for the given person/day, enriched with the
  /// parent focus session's exact [duration_seconds]. This is the authoritative
  /// duration for timer-driven sessions (avoids rounding error in duration_minutes).
  ///
  /// Manually-logged entries (focus_session_id IS NULL) are still returned;
  /// their focusDurationSeconds will be null — fall back to durationMinutes * 60.
  ///
  /// SQL equivalent:
  ///   SELECT e.*, f.duration_seconds AS focus_duration_seconds
  ///   FROM exercise_logs e
  ///   LEFT JOIN focus_sessions f ON e.focus_session_id = f.id
  ///   WHERE e.person_id = :personId
  ///     AND e.timestamp >= :start AND e.timestamp < :end
  ///   ORDER BY e.timestamp ASC
  Future<List<ExerciseWithFocusSession>> getDailyExerciseWithSession(
    String personId,
    DateTime date,
  ) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));

    // Raw SQL JOIN — Drift's typed join API works here but raw is clearer
    final rows = await customSelect(
      '''
      SELECT
        e.id,
        e.person_id,
        e.type,
        e.duration_minutes,
        e.intensity,
        e.timestamp,
        e.focus_session_id,
        e.health_metric_id,
        f.duration_seconds AS focus_duration_seconds
      FROM exercise_logs e
      LEFT JOIN focus_sessions f ON e.focus_session_id = f.id
      WHERE e.person_id = :personId
        AND e.timestamp >= :start
        AND e.timestamp < :end
      ORDER BY e.timestamp ASC
      ''',
      variables: [
        Variable.withString(personId),
        Variable.withString(start.toIso8601String()),
        Variable.withString(end.toIso8601String()),
      ],
      readsFrom: {exerciseLogsTable, focusSessionsTable},
    ).get();

    // Map raw rows to a lightweight data class
    return rows.map((row) {
      return ExerciseWithFocusSession(
        id: row.read<String>('id'),
        personId: row.read<String>('person_id'),
        type: row.read<String>('type'),
        // Prefer focus session's exact seconds ÷ 60; fall back to stored minutes
        durationMinutes: row.readNullable<int>('focus_duration_seconds') != null
            ? (row.read<int>('focus_duration_seconds') ~/ 60)
            : row.read<int>('duration_minutes'),
        exactDurationSeconds: row.readNullable<int>('focus_duration_seconds'),
        intensity: row.read<String>('intensity'),
        timestamp: DateTime.parse(row.read<String>('timestamp')),
        focusSessionId: row.readNullable<String>('focus_session_id'),
      );
    }).toList();
  }

  // Weight Logs
  Future<void> insertWeightLog(WeightLogsTableCompanion entry) async {
    final existing = await (select(
      weightLogsTable,
    )..where((t) => t.id.equals(entry.id.value))).getSingleOrNull();

    if (existing == null) {
      await into(weightLogsTable).insert(entry);
      await db.pushToSupabase(
        table: 'weight_logs',
        payload: db.companionToMap(entry, weightLogsTable),
      );
    }
  }

  Future<void> upsertFromSupabaseWeight(Map<String, dynamic> record) async {
    await into(weightLogsTable).insert(
      WeightLogsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String?),
        weightKg: Value((record['weight_kg'] as num).toDouble()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
        healthMetricID: Value(record['health_metric_id'] as String?),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<List<WeightLogData>> watchDailyWeightLogs(
    String personId,
    DateTime date,
  ) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(weightLogsTable)
          ..where(
            (t) =>
                t.personID.equals(personId) &
                t.timestamp.isBetweenValues(start, end),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<WeightLogData?> watchLatestWeightLog(String personId) {
    return (select(weightLogsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<void> deleteWeightLog(String id) async {
    await (delete(weightLogsTable)..where((t) => t.id.equals(id))).go();
    await db.pushToSupabase(
      table: 'weight_logs',
      payload: {'id': id},
      isDelete: true,
    );
  }
}

@DataClassName('AiPromptData')
class AiPromptsTable extends Table {
  @override
  String get tableName => 'ai_prompts';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get aiModel =>
      text().named('ai_model')(); // gemini, opencode, etc.
  TextColumn get prompt => text().named('prompt')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftAccessor(tables: [AiPromptsTable])
class AiPromptsDAO extends DatabaseAccessor<AppDatabase>
    with _$AiPromptsDAOMixin {
  AiPromptsDAO(super.db);

  Future<AiPromptData?> getPrompt(String personID, String model) {
    return (select(aiPromptsTable)
          ..where((t) => t.personID.equals(personID) & t.aiModel.equals(model)))
        .getSingleOrNull();
  }

  Future<void> savePrompt(String personID, String model, String prompt) async {
    final existing = await getPrompt(personID, model);
    if (existing != null) {
      final companion = AiPromptsTableCompanion(
        id: Value(existing.id),
        prompt: Value(prompt),
        updatedAt: Value(DateTime.now()),
      );
      await (update(
        aiPromptsTable,
      )..where((t) => t.id.equals(existing.id))).write(companion);

      await db.pushToSupabase(
        table: 'ai_prompts',
        payload: db.companionToMap(companion, aiPromptsTable),
      );
    } else {
      final id = IDGen.UUIDV7();
      final companion = AiPromptsTableCompanion.insert(
        id: id,
        personID: Value(personID),
        aiModel: model,
        prompt: prompt,
        updatedAt: Value(DateTime.now()),
      );
      await into(aiPromptsTable).insert(companion);

      await db.pushToSupabase(
        table: 'ai_prompts',
        payload: db.companionToMap(companion, aiPromptsTable),
      );
    }
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    await into(aiPromptsTable).insert(
      AiPromptsTableCompanion(
        id: Value(record['id'] as String),
        personID: Value(record['person_id'] as String),
        aiModel: Value(record['ai_model'] as String),
        prompt: Value(record['prompt'] as String),
        updatedAt: Value(
          record['updated_at'] != null
              ? DateTime.parse(record['updated_at'].toString())
              : DateTime.now(),
        ),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }
}

@DataClassName('ConfigData')
class ConfigsTable extends Table {
  @override
  String get tableName => 'themes_config';
  TextColumn get id => text()(); // UUID Primary Key
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get configKey =>
      text().named('config_key')(); // e.g., 'finance_currency'
  TextColumn get configValue => text().named('config_value')();
  DateTimeColumn get updatedAt => dateTime()
      .withDefault(currentDateAndTime)
      .map(const DateTimeUTCConverter())
      .named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {personID, configKey},
  ];
}

@DriftAccessor(tables: [ConfigsTable])
class ConfigsDAO extends DatabaseAccessor<AppDatabase> with _$ConfigsDAOMixin {
  ConfigsDAO(super.db);

  Future<ConfigData?> getConfig(String personID, String key) {
    return (select(configsTable)
          ..where((t) => t.personID.equals(personID) & t.configKey.equals(key)))
        .getSingleOrNull();
  }

  Future<int> setConfig(String personID, String key, String value) async {
    final existing = await getConfig(personID, key);
    if (existing != null) {
      return (update(configsTable)..where(
            (t) => t.personID.equals(personID) & t.configKey.equals(key),
          ))
          .write(
            ConfigsTableCompanion(
              configValue: Value(value),
              updatedAt: Value(DateTime.now()),
            ),
          );
    } else {
      return into(configsTable).insert(
        ConfigsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: Value(personID),
          configKey: key,
          configValue: value,
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }
}

@DriftAccessor(tables: [SSHSessionsTable])
class SSHSessionsDAO extends DatabaseAccessor<AppDatabase>
    with _$SSHSessionsDAOMixin {
  SSHSessionsDAO(super.db);

  Future<int> insertSSHSession(SSHSessionsTableCompanion entry) =>
      into(sSHSessionsTable).insert(entry);

  Future<bool> updateSSHSession(SSHSessionData entry) =>
      update(sSHSessionsTable).replace(entry);

  Future<int> deleteSSHSession(String id) =>
      (delete(sSHSessionsTable)..where((t) => t.id.equals(id))).go();

  Future<int> markSessionAsDeleted(String id) =>
      (update(sSHSessionsTable)..where((t) => t.id.equals(id))).write(
        const SSHSessionsTableCompanion(isActive: Value(false)),
      );

  Stream<List<SSHSessionData>> watchActiveSessions() =>
      (select(sSHSessionsTable)..where((t) => t.isActive.equals(true))).watch();

  Future<SSHSessionData?> getSessionById(String id) => (select(
    sSHSessionsTable,
  )..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<int> deleteSessionsByIp(String ip) =>
      (delete(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).go();

  Future<int> updateAiModelByIp(String ip, String aiModel) =>
      (update(sSHSessionsTable)..where((t) => t.ipAddress.equals(ip))).write(
        SSHSessionsTableCompanion(aiModel: Value(aiModel)),
      );
}

@DriftAccessor(tables: [AchievementsTable])
class AchievementsDAO extends DatabaseAccessor<AppDatabase>
    with _$AchievementsDAOMixin {
  AchievementsDAO(super.db);

  Future<int> insertAchievement(AchievementsTableCompanion entry) {
    return into(achievementsTable).insert(entry);
  }

  Stream<List<AchievementData>> watchAchievementsByPerson(String personId) {
    return (select(achievementsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
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
    FeedbacksTable,
    FinancialMetricsTable,
    ProjectMetricsTable,
    SocialMetricsTable,
    MealsTable,
    DaysTable,
    SSHHostsTable,
    SSHSessionsTable,
    ScoresTable,
    ProjectsTable,
    TransactionsTable,
    SubscriptionsTable,
    FocusSessionsTable,
    CustomNotificationsTable,
    QuotesTable,
    WaterLogsTable,
    SleepLogsTable,
    WeightLogsTable,
    ExerciseLogsTable,
    QuestsTable,
    PersonContactsTable,
    AiPromptsTable,
    ConfigsTable,
    HourlyActivityLogTable,
    PortfolioSnapshotsTable,
    AchievementsTable,
    MindLogsTable,
  ],
  daos: [
    ThemesTableDAO,
    ExternalWidgetsDAO,
    InternalWidgetsDAO,
    ProjectNoteDAO,
    ProjectsDAO,
    PortfolioSnapshotsDAO,
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
    FocusSessionsDAO,
    CustomNotificationDAO,
    QuoteDAO,
    HealthLogsDAO,
    AiPromptsDAO,
    ConfigsDAO,
    QuestDAO,
    SSHHostsDAO,
    SSHSessionsDAO,
    MetricsDAO,
    FeedbackDAO,
    HourlyActivityLogDAO,
    AchievementsDAO,
    MindLogsDAO,
  ],
)
class AppDatabase extends _$AppDatabase {
  final PowerSyncDatabase? powerSync;
  SupabaseService? supabaseSync;

  AppDatabase([QueryExecutor? executor, this.powerSync])
    : super(executor ?? _openConnection()) {
    print("OBVIOUS LOG: DATABASE VERSION IS 49");
  }

  /// Direct push to Supabase as requested for this branch (bypassing PowerSync upload queue)
  Future<void> pushToSupabase({
    required String table,
    required Map<String, dynamic> payload,
    bool isDelete = false,
  }) async {
    if (supabaseSync != null) {
      await supabaseSync!.pushData(
        table: table,
        payload: payload,
        isDelete: isDelete,
      );
      return;
    }
    debugPrint(
      "📡 [Supabase] pushToSupabase called for $table (isDelete: $isDelete)",
    );
    try {
      final client = Supabase.instance.client;

      // 1. Skip if Guest data
      final idValue = payload['id']?.toString() ?? "";
      if (_isGuest(idValue, payload)) {
        debugPrint(
          "⏭️ [Supabase] Skipping direct push for guest data in $table (ID: $idValue)",
        );
        return;
      }

      // 2. Transform payload (remove local-only columns)
      final transformed = _transformOpData(table, payload);
      final Map<String, dynamic> encodablePayload = Map.from(transformed).map((
        key,
        value,
      ) {
        if (value is DateTime) {
          return MapEntry(key, value.toIso8601String());
        }
        return MapEntry(key, value);
      });
      if (isDelete) {
        debugPrint(
          "🗑️ [Supabase] Direct deleting ${payload['id']} from $table",
        );
        await client.from(table).delete().eq('id', payload['id']);
      } else {
        debugPrint(
          "📤 [Supabase] Direct pushing to $table: ${transformed['id']}",
        );

        // Special handling for metrics tables (upsert with conflict targets)
        final isMetricsTable = [
          'health_metrics',
          'financial_metrics',
          'project_metrics',
          'social_metrics',
          'scores', // Unified scores
        ].contains(table);

        if (isMetricsTable) {
          await client
              .from(table)
              .upsert(encodablePayload, onConflict: 'person_id,date,category');
        } else {
          await client.from(table).upsert(encodablePayload);
        }
        debugPrint(
          "✅ [Supabase] Direct push SUCCESS for $table: ${transformed['id']}",
        );
      }
    } catch (e) {
      debugPrint("❌ [Supabase] Direct push FAILED for $table: $e");
      rethrow;
    }
  }

  // Helper to standardise companion mapping for DAOs
  Map<String, dynamic> companionToMap(
    UpdateCompanion companion,
    TableInfo table,
  ) {
    final Map<String, dynamic> payload = {};
    for (final col in table.$columns) {
      final val = companion.toColumns(true)[col.name];
      if (val is Variable) {
        payload[col.name] = val.value;
      }
    }
    return payload;
  }

  // Helper logic migrated from PowerSync connector to support direct pushes
  static const _globalLocalOnlyColumns = {
    'avatar_local_path',
    'cover_local_path',
  };

  static const _tableLocalOnlyColumns = <String, Set<String>>{
    'persons': {'person_id'},
    'quests': {'quest_type', 'image_url'},
    'profiles': {'last_quest_generated_at'},
    'health_metrics': {'created_at', 'updated_at'},
    'water_logs': {'created_at', 'updated_at'},
    'weight_logs': {'created_at', 'updated_at'},
    'sleep_logs': {'created_at', 'updated_at'},
    'exercise_logs': {'created_at', 'updated_at'},
    'focus_sessions': {'created_at', 'updated_at'},
    'mind_logs': {'created_at', 'updated_at'},
    'feedbacks': {'status'},
  };

  Map<String, dynamic> _transformOpData(
    String table,
    Map<String, dynamic> data,
  ) {
    final result = Map<String, dynamic>.from(data);
    result.removeWhere((key, _) => _globalLocalOnlyColumns.contains(key));
    final tableSpecific = _tableLocalOnlyColumns[table];
    if (tableSpecific != null) {
      result.removeWhere((key, _) => tableSpecific.contains(key));
    }
    return result;
  }

  bool _isGuest(String id, Map<String, dynamic> opData) {
    const guestId = DataSeeder.guestPersonId;
    return id == guestId ||
        opData['person_id']?.toString() == guestId ||
        opData['author_id']?.toString() == guestId ||
        opData['user_id']?.toString() == guestId ||
        opData['owner_id']?.toString() == guestId;
  }

  factory AppDatabase.powersync(PowerSyncDatabase db) {
    return AppDatabase(SqliteAsyncDriftConnection(db), db);
  }

  @override
  QuestDAO get questDAO => QuestDAO(this);
  ThemeDAO get themeDAO => ThemeDAO(this);
  SSHHostsDAO get sshHostsDAO => SSHHostsDAO(this);
  SSHSessionsDAO get sshSessionsDAO => SSHSessionsDAO(this);
  @override
  ConfigsDAO get configsDAO => ConfigsDAO(this);
  @override
  MindLogsDAO get mindLogsDAO => MindLogsDAO(this);

  @override
  DriftDatabaseOptions get options => const DriftDatabaseOptions(
    // Ép Drift lưu DateTime dưới dạng chuỗi ISO8601 thay vì số nguyên
    storeDateTimeAsText: true,
  );
  @override
  // v51 → adds task_id + session_type to focus_sessions (they were missing on existing installs)
  // v52 → adds focus_session_id to exercise_logs so logs JOIN to their parent focus session
  // v53 → adds categories on focus_sessions (e.g. health-exercise for exercise timer sessions)
  // v54 → repair focus_sessions.task_id when v51 was skipped (PowerSync / legacy taskID only)
  // v57 → adds mind_logs table for mental health tracking
  int get schemaVersion => 57;

  /// Ensures `focus_sessions` columns match Drift (PowerSync / legacy DBs may omit them).
  Future<void> repairFocusSessionsSchemaForDrift() async {
    try {
      final rows = await customSelect(
        'PRAGMA table_info(focus_sessions)',
        readsFrom: {focusSessionsTable},
      ).get();
      final names = rows.map((r) => r.read<String>('name')).toSet();
      if (!names.contains('task_id')) {
        try {
          await customStatement(
            'ALTER TABLE focus_sessions ADD COLUMN task_id TEXT REFERENCES quests(id) ON DELETE SET NULL;',
          );
        } catch (_) {
          try {
            await customStatement(
              'ALTER TABLE focus_sessions ADD COLUMN task_id TEXT;',
            );
          } catch (_) {}
        }
        if (names.contains('taskID')) {
          try {
            await customStatement(
              'UPDATE focus_sessions SET task_id = taskID WHERE task_id IS NULL;',
            );
          } catch (_) {}
        }
      }
      if (!names.contains('session_type')) {
        try {
          await customStatement(
            "ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'Focus';",
          );
        } catch (_) {}
      }
      if (!names.contains('categories')) {
        try {
          await customStatement(
            'ALTER TABLE focus_sessions ADD COLUMN categories TEXT;',
          );
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> clearAllData() async {
    await transaction(() async {
      for (final table in allTables) {
        await delete(table).go();
      }
    });
  }

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 55) {
          // focus_session_id is added to PowerSync schema for exercise_logs.
          // Since it's a view, we must NOT use m.addColumn here.
        }
        if (from < 50) {
          // Version 50: Originally removed PowerSync-managed tables (weight_logs, hourly_activity_log).
          // NOTE: hourly_activity_log is now a local-only Drift table (removed from PowerSync schema).
          // We only drop weight_logs if it's still a real table (pre-PowerSync legacy schema).
          // In Drift 2.x, use m.database to access custom query methods.
          final legacyTables = [
            'weight_logs',
          ]; // hourly_activity_log stays as real Drift table
          for (final tableName in legacyTables) {
            try {
              final result = await m.database
                  .customSelect(
                    "SELECT type FROM sqlite_master WHERE name = ?",
                    variables: [Variable.withString(tableName)],
                  )
                  .getSingleOrNull();

              if (result?.read<String>('type') == 'table') {
                debugPrint(
                  "Drift: Dropping legacy table $tableName to allow PowerSync view.",
                );
                await m.database.customStatement(
                  'DROP TABLE IF EXISTS "$tableName";',
                );
              }
            } catch (e) {
              debugPrint("Drift: Error dropping legacy table $tableName: $e");
            }
          }
        }
        if (from < 49) {
          // Version 49: Fix broken FK in hourly_activity_log by recreating it
          // NOTE: This was a temporary fix that is superseded by dropping the table in version 50.
          try {
            await m.deleteTable('hourly_activity_log');
            await m.createTable(hourlyActivityLogTable);
          } catch (_) {}
        }
        if (from < 48) {
          // In case it wasn't created yet in an intermediate update
          try {
            await m.createTable(hourlyActivityLogTable);
          } catch (_) {}
        }
        if (from < 47) {
          // Schema version 47 adds ai_model to the 'projects' table.
          // Since 'projects' is a PowerSync-managed table, its local representation is a view.
          // PowerSync manages its own schema updates via powersync_schema.dart.
          // We must NOT use m.addColumn here for PowerSync tables.
        }
        if (from < 46) {
          await m.createTable(sSHSessionsTable);
        }
        if (from < 45) {
          // Schema version 45 adds quest_type column.
          // Since it's a PowerSync table, we do not use m.addColumn
          // as PowerSync manages the local SQLite table as a view.
        }
        if (from < 44) {
          // Schema version 44 adds the ssh_hosts table.
          // Since it's a PowerSync table, we don't call m.createTable(sshHostsTable) here
          // as Drift uses CREATE TABLE but PowerSync expects to manage its own views.
        }
        if (from < 43) {
          // Schema version 43 adds ssh_host_id, remote_path, and category to the 'projects' table.
          // Since 'projects' is a PowerSync-managed table, its local representation is a view.
          // We must NOT use m.addColumn here as ALTER TABLE on a view is illegal in SQLite.
        }
        if (from < 33) {
          // The image_url column was added to quests
        }
        if (from < 31) {
          // PowerSync tables are views
        }
        if (from < 2) {
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
          await m.createTable(projectNotesTable);
        }
        if (from < 3) {
          await m.createTable(cVAddressesTable);
        }
        if (from < 4) {
          await m.createTable(sessionTable);
        }
        if (from < 15) {
          await m.createTable(organizationsTable);
        }
        if (from < 16) {
          try {
            await customStatement(
              "ALTER TABLE focus_sessions ADD COLUMN taskID TEXT REFERENCES goals(goalID) ON DELETE CASCADE;",
            );
          } catch (e) {
            print('Error adding taskID: $e');
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
          try {
            await customStatement(
              'ALTER TABLE project_notes ADD COLUMN personID TEXT REFERENCES persons(personID) ON DELETE CASCADE',
            );
            await customStatement(
              'ALTER TABLE project_notes ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE',
            );
            await customStatement(
              'ALTER TABLE goals ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE',
            );
          } catch (_) {}
        }
        if (from < 9) {
          await m.createTable(transactionsTable);
        }
        if (from < 10) {
          try {
            await customStatement(
              'DELETE FROM health_metrics WHERE metricID NOT IN (SELECT MIN(metricID) FROM health_metrics GROUP BY personID, date)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_health_metrics_unique ON health_metrics (personID, date)',
            );
          } catch (e) {
            print('Error in version 10: $e');
          }
        }
        if (from < 20) {
          try {
            await customStatement(
              'DELETE FROM scores WHERE scoreID NOT IN (SELECT MIN(scoreID) FROM scores GROUP BY personID)',
            );
            await customStatement(
              'CREATE UNIQUE INDEX IF NOT EXISTS idx_scores_person_unique ON scores (personID)',
            );
          } catch (e) {
            print('Error in version 20: $e');
          }
        }
        if (from < 11) {
          try {
            await customStatement(
              "ALTER TABLE persons ADD COLUMN relationship TEXT DEFAULT 'none';",
            );
          } catch (_) {}
        }
        if (from < 12) {
          try {
            await customStatement(
              "ALTER TABLE persons ADD COLUMN affection INTEGER DEFAULT 0;",
            );
          } catch (_) {}
        }
        if (from < 13) {
          // ALTER TABLE projects ADD COLUMN category TEXT;
          // Skipped for PowerSync view safety.
        }
        if (from < 14) {
          try {
            await customStatement(
              "ALTER TABLE transactions ADD COLUMN projectID TEXT REFERENCES projects(projectID) ON DELETE CASCADE;",
            );
          } catch (_) {}
        }
        if (from < 17) {
          await m.createTable(customNotificationsTable);
        }
        if (from < 18) {
          await m.createTable(quotesTable);
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
          } catch (_) {}
        }
        if (from < 22) {
          await m.createTable(questsTable);
        }
        if (from < 23) {
          // Add ID to all tables if missing
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
              // Only attempt ALTER on tables, not views.
              // We check if it's a view by querying sqlite_master.
              final isView = await customSelect(
                "SELECT type FROM sqlite_master WHERE name = ?",
                variables: [Variable.withString(tableName)],
              ).getSingleOrNull();

              if (isView?.read<String>('type') == 'table') {
                await customStatement(
                  'ALTER TABLE $tableName ADD COLUMN id TEXT;',
                );
              }
            } catch (_) {}
          }
        }
        if (from < 26) {
          try {
            await customStatement(
              "ALTER TABLE meals ADD COLUMN person_id TEXT REFERENCES persons(id) ON DELETE CASCADE;",
            );
          } catch (_) {}
        }
        if (from < 32) {
          try {
            await customStatement(
              "ALTER TABLE custom_notifications ADD COLUMN person_id TEXT REFERENCES persons(id) ON DELETE CASCADE;",
            );
          } catch (_) {}
        }
        if (from < 35) {
          try {
            await m.addColumn(internalWidgetsTable, internalWidgetsTable.scope);
          } catch (_) {}
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
            // Indexes
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
          } catch (_) {}
        }
        if (from < 42) {
          try {
            await m.addColumn(projectNotesTable, projectNotesTable.category);
            await customStatement(
              "UPDATE project_notes SET category = 'projects' WHERE category IS NULL",
            );
          } catch (_) {}
        }

        if (from < 51) {
          // focus_sessions was created at an early schema version without
          // task_id and session_type columns. Add them for existing installs.
          // Using raw SQL because PowerSync-synced tables must not use m.addColumn
          // (it fails on view-backed tables). Wrapped in try/catch to safely
          // ignore "duplicate column name" on fresh installs.
          try {
            await customStatement(
              'ALTER TABLE focus_sessions ADD COLUMN task_id TEXT REFERENCES goals(id) ON DELETE CASCADE;',
            );
          } catch (_) {}
          try {
            await customStatement(
              "ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'Focus';",
            );
          } catch (_) {}
          try {
            await customStatement(
              "UPDATE focus_sessions SET session_type = 'Focus' WHERE session_type IS NULL;",
            );
          } catch (_) {}
        }

        if (from < 52) {
          // focus_session_id is now managed via PowerSync schema in powersync_schema.dart.
          // Manual ALTER TABLE on views is illegal in SQLite.
        }
        if (from < 53) {
          try {
            await customStatement(
              'ALTER TABLE focus_sessions ADD COLUMN categories TEXT;',
            );
          } catch (_) {}
        }
        if (from < 54) {
          // Drift uses task_id; some DBs only have legacy taskID (v16) or PowerSync-created
          // tables that never ran v51. Add task_id and copy from taskID when possible.
          try {
            await customStatement(
              'ALTER TABLE focus_sessions ADD COLUMN task_id TEXT REFERENCES quests(id) ON DELETE SET NULL;',
            );
          } catch (_) {
            try {
              await customStatement(
                'ALTER TABLE focus_sessions ADD COLUMN task_id TEXT;',
              );
            } catch (_) {}
          }
          try {
            await customStatement(
              'UPDATE focus_sessions SET task_id = taskID WHERE task_id IS NULL;',
            );
          } catch (_) {}
          try {
            await customStatement(
              "ALTER TABLE focus_sessions ADD COLUMN session_type TEXT DEFAULT 'Focus';",
            );
          } catch (_) {}
          try {
            await customStatement(
              "UPDATE focus_sessions SET session_type = 'Focus' WHERE session_type IS NULL;",
            );
          } catch (_) {}
          try {
            await customStatement(
              'ALTER TABLE focus_sessions ADD COLUMN categories TEXT;',
            );
          } catch (_) {}
        }
        if (from < 57) {
          await m.createTable(mindLogsTable);
        }
      },
      beforeOpen: (details) async {
        print(
          "Drift: beforeOpen triggered. Version: ${details.versionBefore} -> ${details.versionNow}",
        );
        await repairFocusSessionsSchemaForDrift();
        // Consolidated cleanups
        try {
          await customStatement(
            "UPDATE custom_notifications SET repeat_frequency = 'none' WHERE repeat_frequency IS NULL;",
          );
          await customStatement(
            "UPDATE custom_notifications SET is_enabled = 1 WHERE is_enabled IS NULL;",
          );
          await customStatement(
            "UPDATE project_notes SET category = 'projects' WHERE category IS NULL;",
          );
        } catch (_) {}
      },
    );
  }

  @override
  PortfolioSnapshotsDAO get portfolioSnapshotsDAO =>
      PortfolioSnapshotsDAO(this);
}

@DriftAccessor(tables: [PortfolioSnapshotsTable])
class PortfolioSnapshotsDAO extends DatabaseAccessor<AppDatabase>
    with _$PortfolioSnapshotsDAOMixin {
  PortfolioSnapshotsDAO(super.db);

  Future<void> insertSnapshot(PortfolioSnapshotsTableCompanion snapshot) async {
    await into(portfolioSnapshotsTable).insert(snapshot);

    // Map to Supabase
    final Map<String, dynamic> payload = {};
    for (final col in portfolioSnapshotsTable.$columns) {
      final value = snapshot.toColumns(true)[col.name];
      if (value is Variable) {
        payload[col.name] = value.value;
      }
    }
    await db.pushToSupabase(table: 'portfolio_snapshots', payload: payload);
  }

  Future<void> upsertFromSupabase(Map<String, dynamic> record) async {
    final id = record['id'] as String;
    final personId = record['person_id'] as String;

    await into(portfolioSnapshotsTable).insert(
      PortfolioSnapshotsTableCompanion(
        id: Value(id),
        personID: Value(personId),
        totalNetWorth: Value((record['total_net_worth'] as num).toDouble()),
        athAtTime: Value((record['ath_at_time'] as num).toDouble()),
        timestamp: Value(DateTime.parse(record['timestamp'].toString())),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Stream<PortfolioSnapshotData?> watchLatestSnapshot(String personId) {
    return (select(portfolioSnapshotsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<PortfolioSnapshotData?> getLatestSnapshot(String personId) {
    return (select(portfolioSnapshotsTable)
          ..where((t) => t.personID.equals(personId))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .getSingleOrNull();
  }
}
