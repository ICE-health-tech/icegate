part of 'Database.dart';

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

// Enums
enum UserRole { user, admin, viewer }
enum PostStatus { draft, published, archived, deleted }
enum EmailStatus { pending, verified, bounced, disabled }
enum CurrencyType { USD, EUR, VND, JPY, GBP, CNY }
enum SkillLevel { beginner, intermediate, advanced, expert }

@DataClassName("InternalWidgetData")
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
  TextColumn get name => text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get url => text().withLength(min: 1, max: 100).named("url").nullable()();
  TextColumn get dateAdded => text().named("date_added").nullable()();
  TextColumn get imageUrl => text().named("image_url").nullable()();
  TextColumn get alias => text().named("alias").nullable()();
  TextColumn get scope => text().named("scope").nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HourlyActivityLogData')
class HourlyActivityLogTable extends Table {
  @override
  String get tableName => 'hourly_activity_log';
  TextColumn get id => text()();
  TextColumn get personID => text().named('person_id')();
  DateTimeColumn get startTime => dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime().map(const DateTimeUTCConverter()).nullable().named('end_time')();
  DateTimeColumn get logDate => dateTime().map(const DateTimeUTCConverter()).named('log_date')();
  IntColumn get stepsCount => integer().withDefault(const Constant(0)).named('steps_count')();
  RealColumn get distanceKm => real().withDefault(const Constant(0.0)).named('distance_km')();
  IntColumn get caloriesBurned => integer().withDefault(const Constant(0)).named('calories_burned')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExternalWidgetData')
class ExternalWidgetsTable extends Table {
  @override
  String get tableName => 'external_widgets';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get widgetID => text().nullable().named("widget_id")();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named("name").nullable()();
  TextColumn get alias => text().withLength(min: 1, max: 100).named("alias").nullable()();
  TextColumn get protocol => text().named("protocol").nullable()();
  TextColumn get host => text().named("host").nullable()();
  TextColumn get url => text().named("url").nullable()();
  TextColumn get imageUrl => text().nullable().named("image_url")();
  TextColumn get dateAdded => text().named("date_added").nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('LocalThemeData')
class ThemesTable extends Table {
  @override
  String get tableName => 'themes';
  TextColumn get id => text()();
  TextColumn get organizationId => text().nullable()();
  TextColumn get themeID => text().nullable().named('theme_id')();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get alias => text().withLength(min: 1, max: 50).unique().named('alias')();
  TextColumn get json => text().named('json_content')();
  TextColumn get author => text().withLength(min: 1, max: 50).named('author')();
  TextColumn get addedDate => text().map(const DateTimeConverter()).named('added_date')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectNoteData')
class ProjectNotesTable extends Table {
  @override
  String get tableName => 'project_notes';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get noteID => text().nullable().named('note_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content => text().named('content')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get category => text().withDefault(const Constant('projects')).named('category')();
  TextColumn get mood => text().nullable().named('mood')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProjectData')
class ProjectsTable extends Table {
  @override
  String get tableName => 'projects';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category => text().nullable().named('category')();
  TextColumn get color => text().nullable().named('color')();
  IntColumn get status => integer().withDefault(const Constant(0)).named('status')();
  TextColumn get sshHostId => text().nullable().named('ssh_host_id')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  TextColumn get aiModel => text().nullable().named('ai_model')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SSHHostData')
class SSHHostsTable extends Table {
  @override
  String get tableName => 'ssh_hosts';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get name => text().withLength(min: 1, max: 200).named('name')();
  TextColumn get host => text().named('host')();
  IntColumn get port => integer().withDefault(const Constant(22)).named('port')();
  TextColumn get user => text().named('username')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SSHSessionData')
class SSHSessionsTable extends Table {
  @override
  String get tableName => 'ssh_sessions';
  TextColumn get id => text()();
  TextColumn get ipAddress => text().named('ip_address')();
  TextColumn get localPath => text().nullable().named('local_path')();
  TextColumn get remotePath => text().nullable().named('remote_path')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get sessionName => text().named('session_name')();
  TextColumn get aiModel => text().nullable().named('ai_model')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrganizationData')
class OrganizationsTable extends Table {
  @override
  String get tableName => 'organizations';
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100).named('name')();
  TextColumn get domain => text().nullable().named('domain')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PersonData')
class PersonsTable extends Table {
  @override
  String get tableName => 'persons';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get firstName => text().withLength(min: 1, max: 100).named('first_name')();
  TextColumn get lastName => text().nullable().named('last_name')();
  DateTimeColumn get dateOfBirth => dateTime().nullable().map(const DateTimeUTCConverter()).named('date_of_birth')();
  TextColumn get gender => text().nullable().named('gender')();
  TextColumn get phoneNumber => text().withLength(max: 20).nullable().named('phone_number')();
  TextColumn get profileImageUrl => text().nullable().named('profile_image_url')();
  TextColumn get coverImageUrl => text().nullable().named('cover_image_url')();
  TextColumn get avatarLocalPath => text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath => text().nullable().named('cover_local_path')();
  TextColumn get relationship => text().withDefault(const Constant('none')).named('relationship')();
  IntColumn get affection => integer().withDefault(const Constant(0)).named('affection')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PersonContactData')
class PersonContactsTable extends Table {
  @override
  String get tableName => 'person_contacts';
  TextColumn get id => text()();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get firstName => text().withLength(min: 1, max: 100).named('first_name')();
  TextColumn get lastName => text().nullable().named('last_name')();
  TextColumn get phoneNumber => text().withLength(max: 20).nullable().named('phone_number')();
  TextColumn get profileImageUrl => text().nullable().named('profile_image_url')();
  TextColumn get relationship => text().withDefault(const Constant('friend')).named('relationship')();
  IntColumn get affection => integer().withDefault(const Constant(0)).named('affection')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('EmailAddressData')
class EmailAddressesTable extends Table {
  @override
  String get tableName => 'email_addresses';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get emailAddressID => text().nullable().named('email_address_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get emailAddress => text().withLength(max: 320).named('email_address')();
  TextColumn get emailType => text().withDefault(const Constant('personal')).named('email_type')();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false)).named('is_primary')();
  TextColumn get status => textEnum<EmailStatus>().withDefault(const Constant('pending')).named('status')();
  DateTimeColumn get verifiedAt => dateTime().nullable().map(const DateTimeUTCConverter()).named('verified_at')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('UserAccountData')
class UserAccountsTable extends Table {
  @override
  String get tableName => 'user_accounts';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text().nullable().unique().named('person_id')();
  TextColumn get username => text().withLength(min: 3, max: 50).nullable().unique().named('username')();
  TextColumn get passwordHash => text().nullable().named('password_hash')();
  TextColumn get primaryEmailID => text().nullable().named('primary_email_id')();
  TextColumn get role => textEnum<UserRole>().withDefault(const Constant('user')).named('role')();
  BoolColumn get isLocked => boolean().nullable().withDefault(const Constant(false)).named('is_locked')();
  IntColumn get failedLoginAttempts => integer().nullable().withDefault(const Constant(0)).named('failed_login_attempts')();
  DateTimeColumn get lastLoginAt => dateTime().nullable().map(const DateTimeUTCConverter()).named('last_login_at')();
  DateTimeColumn get passwordChangedAt => dateTime().nullable().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('password_changed_at')();
  DateTimeColumn get createdAt => dateTime().nullable().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ProfileData')
class ProfilesTable extends Table {
  @override
  String get tableName => 'profiles';
  TextColumn get id => text()();
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
  TextColumn get avatarLocalPath => text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath => text().nullable().named('cover_local_path')();
  TextColumn get timezone => text().nullable().named('timezone')();
  TextColumn get preferredLanguage => text().nullable().named('preferred_language')();
  DateTimeColumn get lastQuestGeneratedAt => dateTime().nullable().map(const DateTimeUTCConverter()).named('last_quest_generated_at')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CVAddressData')
class CVAddressesTable extends Table {
  @override
  String get tableName => 'detail_information';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
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
  TextColumn get avatarLocalPath => text().nullable().named('avatar_local_path')();
  TextColumn get coverLocalPath => text().nullable().named('cover_local_path')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SkillData')
class SkillsTable extends Table {
  @override
  String get tableName => 'skills';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get skillID => text().nullable().named('skill_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get skillName => text().named('skill_name')();
  TextColumn get skillCategory => text().nullable().named('skill_category')();
  TextColumn get proficiencyLevel => textEnum<SkillLevel>().withDefault(const Constant('beginner')).named('proficiency_level')();
  IntColumn get yearsOfExperience => integer().withDefault(const Constant(0)).named('years_of_experience')();
  TextColumn get description => text().nullable().named('description')();
  BoolColumn get isFeatured => boolean().withDefault(const Constant(false)).named('is_featured')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FinancialAccountData')
class FinancialAccountsTable extends Table {
  @override
  String get tableName => 'financial_accounts';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get accountID => text().nullable().named('account_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get accountName => text().named('account_name')();
  TextColumn get accountType => text().withDefault(const Constant('checking')).named('account_type')();
  RealColumn get balance => real().withDefault(const Constant(0.0)).named('balance')();
  TextColumn get currency => textEnum<CurrencyType>().withDefault(const Constant('USD')).named('currency')();
  BoolColumn get isPrimary => boolean().withDefault(const Constant(false)).named('is_primary')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AssetData')
class AssetsTable extends Table {
  @override
  String get tableName => 'assets';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get assetID => text().nullable().named('asset_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get assetName => text().named('asset_name')();
  TextColumn get assetCategory => text().named('asset_category')();
  DateTimeColumn get purchaseDate => dateTime().nullable().named('purchase_date')();
  RealColumn get purchasePrice => real().nullable().named('purchase_price')();
  RealColumn get currentEstimatedValue => real().nullable().named('current_estimated_value')();
  TextColumn get currency => textEnum<CurrencyType>().withDefault(const Constant('USD')).named('currency')();
  TextColumn get condition => text().withDefault(const Constant('good')).named('condition')();
  TextColumn get location => text().nullable().named('location')();
  TextColumn get notes => text().nullable().named('notes')();
  BoolColumn get isInsured => boolean().withDefault(const Constant(false)).named('is_insured')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('TransactionData')
class TransactionsTable extends Table {
  @override
  String get tableName => 'transactions';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get transactionID => text().nullable().named('transaction_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get category => text().named('category')();
  TextColumn get type => text().named('type')();
  RealColumn get amount => real().named('amount')();
  TextColumn get description => text().nullable().named('description')();
  DateTimeColumn get transactionDate => dateTime().withDefault(currentDateAndTime).named('transaction_date')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  TextColumn get projectID => text().nullable().named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SubscriptionData')
class SubscriptionsTable extends Table {
  @override
  String get tableName => 'subscriptions';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().named('tenant_id')();
  TextColumn get personID => text().named('person_id')();
  TextColumn get name => text().named('name')();
  RealColumn get amount => real().named('amount')();
  IntColumn get billingDay => integer().named('billing_day')();
  TextColumn get category => text().nullable().named('category')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('GoalData')
class GoalsTable extends Table {
  @override
  String get tableName => 'goals';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get goalID => text().nullable().named('goal_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get category => text().withDefault(const Constant('personal')).named('category')();
  IntColumn get priority => integer().withDefault(const Constant(3)).named('priority')();
  TextColumn get status => text().withDefault(const Constant('active')).named('status')();
  DateTimeColumn get targetDate => dateTime().nullable().map(const DateTimeUTCConverter()).named('target_date')();
  DateTimeColumn get completionDate => dateTime().nullable().map(const DateTimeUTCConverter()).named('completion_date')();
  IntColumn get progressPercentage => integer().withDefault(const Constant(0)).named('progress_percentage')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();
  TextColumn get projectID => text().nullable().named('project_id')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName("ScoreLocalData")
class ScoresTable extends Table {
  @override
  String get tableName => 'scores';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get scoreID => text().named('score_id').nullable()();
  TextColumn get personID => text().nullable().nullable().unique().named('person_id')();
  RealColumn get healthGlobalScore => real().withDefault(const Constant(0.0)).named('health_global_score').nullable()();
  RealColumn get socialGlobalScore => real().withDefault(const Constant(0.0)).named('social_global_score').nullable()();
  RealColumn get financialGlobalScore => real().withDefault(const Constant(0.0)).named('financial_global_score').nullable()();
  RealColumn get careerGlobalScore => real().withDefault(const Constant(0.0)).named('career_global_score').nullable()();
  RealColumn get penaltyScore => real().withDefault(const Constant(0.0)).named('penalty_score').nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HabitData')
class HabitsTable extends Table {
  @override
  String get tableName => 'habits';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get habitID => text().nullable().named('habit_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get goalID => text().nullable().named('goal_id')();
  TextColumn get habitName => text().named('habit_name')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get frequency => text().named('frequency')();
  TextColumn get frequencyDetails => text().nullable().named('frequency_details')();
  IntColumn get targetCount => integer().withDefault(const Constant(1)).named('target_count')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get startedDate => dateTime().withDefault(currentDateAndTime).named('started_date')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AiAnalysisData')
class AiAnalysisTable extends Table {
  @override
  String get tableName => 'ai_analysis';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().named('title')();
  TextColumn get summary => text().nullable().named('summary')();
  TextColumn get detailedAnalysis => text().named('detailed_analysis')();
  TextColumn get status => text().withDefault(const Constant('draft')).named('status')();
  BoolColumn get isFeatured => boolean().nullable().withDefault(const Constant(false)).named('is_featured')();
  DateTimeColumn get publishedAt => dateTime().nullable().named('published_at')();
  DateTimeColumn get createdAt => dateTime().nullable().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().nullable().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();
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
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  IntColumn get personWidgetID => integer().nullable().named('person_widget_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get widgetName => text().named('widget_name')();
  TextColumn get widgetType => text().named('widget_type')();
  TextColumn get configuration => text().withDefault(const Constant('{}')).named('configuration')();
  IntColumn get displayOrder => integer().withDefault(const Constant(0)).named('display_order')();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  TextColumn get role => textEnum<UserRole>().withDefault(const Constant('admin')).named('role')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('HealthMetricsLocal')
class HealthMetricsTable extends Table {
  @override
  String get tableName => 'health_metrics';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get date => dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get steps => integer().withDefault(const Constant(0)).named('steps').nullable()();
  IntColumn get heartRate => integer().withDefault(const Constant(0)).named('heart_rate').nullable()();
  RealColumn get sleepHours => real().withDefault(const Constant(0.0)).named('sleep_hours').nullable()();
  IntColumn get waterGlasses => integer().withDefault(const Constant(0)).named('water_glasses').nullable()();
  IntColumn get exerciseMinutes => integer().withDefault(const Constant(0)).named('exercise_minutes').nullable()();
  IntColumn get focusMinutes => integer().withDefault(const Constant(0)).named('focus_minutes').nullable()();
  RealColumn get weightKg => real().withDefault(const Constant(0.0)).named('weight_kg').nullable()();
  IntColumn get caloriesConsumed => integer().withDefault(const Constant(0)).named('calories_consumed').nullable()();
  IntColumn get caloriesBurned => integer().withDefault(const Constant(0)).named('calories_burned').nullable()();
  RealColumn get questPoints => real().withDefault(const Constant(0.0)).named('quest_points').nullable()();
  TextColumn get category => text().nullable().named('category')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{personID, date, category}];
}

@DataClassName('FinancialMetricsLocal')
class FinancialMetricsTable extends Table {
  @override
  String get tableName => 'financial_metrics';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get date => dateTime().map(const DateTimeUTCConverter()).named('date')();
  RealColumn get totalBalance => real().withDefault(const Constant(0.0)).named('total_balance').nullable()();
  RealColumn get totalSavings => real().withDefault(const Constant(0.0)).named('total_savings').nullable()();
  RealColumn get totalInvestments => real().withDefault(const Constant(0.0)).named('total_investments').nullable()();
  RealColumn get dailyExpenses => real().withDefault(const Constant(0.0)).named('daily_expenses').nullable()();
  RealColumn get questPoints => real().withDefault(const Constant(0.0)).named('quest_points').nullable()();
  TextColumn get category => text().withDefault(const Constant('General')).named('category').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{personID, date, category}];
}

@DataClassName('ProjectMetricsLocal')
class ProjectMetricsTable extends Table {
  @override
  String get tableName => 'project_metrics';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get date => dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get tasksCompleted => integer().withDefault(const Constant(0)).named('tasks_completed').nullable()();
  IntColumn get projectsCompleted => integer().withDefault(const Constant(0)).named('projects_completed').nullable()();
  IntColumn get focusMinutes => integer().withDefault(const Constant(0)).named('focus_minutes').nullable()();
  RealColumn get questPoints => real().withDefault(const Constant(0.0)).named('quest_points').nullable()();
  TextColumn get category => text().withDefault(const Constant('General')).named('category').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{personID, date, category}];
}

@DataClassName('SocialMetricsLocal')
class SocialMetricsTable extends Table {
  @override
  String get tableName => 'social_metrics';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get metricID => text().nullable().named('metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get date => dateTime().map(const DateTimeUTCConverter()).named('date')();
  IntColumn get contactsCount => integer().withDefault(const Constant(0)).named('contacts_count').nullable()();
  IntColumn get totalAffection => integer().withDefault(const Constant(0)).named('total_affection').nullable()();
  RealColumn get questPoints => real().withDefault(const Constant(0.0)).named('quest_points').nullable()();
  TextColumn get category => text().withDefault(const Constant('General')).named('category').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{personID, date, category}];
}

@DataClassName('MealData')
class MealsTable extends Table {
  @override
  String get tableName => 'meals';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get mealID => text().nullable().named("meal_id")();
  TextColumn get personID => text().nullable().named("person_id")();
  TextColumn get mealName => text().withLength(min: 1, max: 50).named("meal_name")();
  TextColumn get mealImageUrl => text().nullable().named("meal_image_url")();
  RealColumn get fat => real().withDefault(const Constant(0.0)).named("fat")();
  RealColumn get carbs => real().withDefault(const Constant(0.0)).named("carbs")();
  RealColumn get protein => real().withDefault(const Constant(0.0)).named("protein")();
  RealColumn get calories => real().withDefault(const Constant(0.0)).named("calories")();
  DateTimeColumn get eatenAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named("eaten_at")();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('DayData')
class DaysTable extends Table {
  @override
  String get tableName => 'days';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  DateTimeColumn get dayID => dateTime().map(const DateTimeUTCConverter()).named('day_id')();
  IntColumn get weight => integer().withDefault(const Constant(0)).named('weight')();
  IntColumn get caloriesOut => integer().withDefault(const Constant(0)).named('calories_out')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SessionData')
class SessionTable extends Table {
  @override
  String get tableName => 'sessions';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get localID => text().nullable().named('local_id')();
  TextColumn get jwt => text().named('jwt')();
  TextColumn get username => text().nullable().named('username')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WaterLogData')
class WaterLogsTable extends Table {
  @override
  String get tableName => 'water_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  IntColumn get amount => integer().withDefault(const Constant(0)).named('amount')();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('timestamp')();
  TextColumn get healthMetricID => text().nullable().named('health_metric_id')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('WeightLogData')
class WeightLogsTable extends Table {
  @override
  String get tableName => 'weight_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  RealColumn get weightKg => real().withDefault(const Constant(0.0)).named('weight_kg')();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('timestamp')();
  TextColumn get healthMetricID => text().nullable().named('health_metric_id')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('SleepLogData')
class SleepLogsTable extends Table {
  @override
  String get tableName => 'sleep_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get logID => text().nullable().named('log_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  DateTimeColumn get startTime => dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime().map(const DateTimeUTCConverter()).nullable().named('end_time')();
  IntColumn get quality => integer().withDefault(const Constant(3)).named('quality')();
  TextColumn get healthMetricID => text().nullable().named('health_metric_id')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ExerciseLogData')
class ExerciseLogsTable extends Table {
  @override
  String get tableName => 'exercise_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get healthMetricID => text().nullable().named('health_metric_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get type => text().named('type')();
  IntColumn get durationMinutes => integer().named('duration_minutes')();
  TextColumn get intensity => text().withDefault(const Constant('medium')).named('intensity')();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('timestamp')();
  TextColumn get focusSessionID => text().nullable().named('focus_session_id')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('CustomNotificationData')
class CustomNotificationsTable extends Table {
  @override
  String get tableName => 'custom_notifications';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get notificationID => text().nullable().named('notification_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get content => text().named('content')();
  DateTimeColumn get scheduledTime => dateTime().map(const DateTimeUTCConverter()).named('scheduled_time')();
  TextColumn get repeatFrequency => text().nullable().withDefault(const Constant('none')).named('repeat_frequency')();
  TextColumn get repeatDays => text().nullable().named('repeat_days')();
  TextColumn get category => text().withDefault(const Constant('General')).named('category')();
  TextColumn get priority => text().withDefault(const Constant('Normal')).named('priority')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get icon => text().nullable().named('icon')();
  BoolColumn get isEnabled => boolean().withDefault(const Constant(true)).named('is_enabled')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuestData')
class QuestsTable extends Table {
  @override
  String get tableName => 'quests';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).nullable().named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get type => text().nullable().withDefault(const Constant('daily')).named('type')();
  TextColumn get questType => text().nullable().named('quest_type')();
  RealColumn get targetValue => real().nullable().withDefault(const Constant(0.0)).named('target_value')();
  RealColumn get currentValue => real().nullable().withDefault(const Constant(0.0)).named('current_value')();
  TextColumn get category => text().nullable().withDefault(const Constant('health')).named('category')();
  IntColumn get rewardExp => integer().nullable().withDefault(const Constant(10)).named('reward_exp')();
  BoolColumn get isCompleted => boolean().nullable().withDefault(const Constant(false)).named('is_completed')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  TextColumn get imageUrl => text().nullable().named('image_url')();
  IntColumn get penaltyScore => integer().nullable().withDefault(const Constant(0)).named('penalty_score')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('PortfolioSnapshotData')
class PortfolioSnapshotsTable extends Table {
  @override
  String get tableName => 'portfolio_snapshots';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  RealColumn get totalNetWorth => real().named('total_net_worth')();
  RealColumn get athAtTime => real().named('ath_at_time')();
  DateTimeColumn get timestamp => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('timestamp')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AchievementData')
class AchievementsTable extends Table {
  @override
  String get tableName => 'achievements';
  TextColumn get id => text()();
  TextColumn get tenantID => text().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get title => text().withLength(min: 1, max: 200).named('title')();
  TextColumn get description => text().nullable().named('description')();
  TextColumn get domain => text().withDefault(const Constant('project')).named('domain')();
  IntColumn get meaningScore => integer().nullable().withDefault(const Constant(5)).named('meaning_score')();
  IntColumn get impactScore => integer().named('impact_score')();
  TextColumn get moodPre => text().nullable().named('mood_pre')();
  TextColumn get moodPost => text().nullable().named('mood_post')();
  TextColumn get impactDescWho => text().named('impact_desc_who')();
  TextColumn get impactDescHow => text().named('impact_desc_how')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('MindLogData')
class MindLogsTable extends Table {
  @override
  String get tableName => 'mind_logs';
  TextColumn get id => text()();
  TextColumn get tenantID => text().nullable().named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  IntColumn get moodScore => integer().named('mood_score')();
  TextColumn get moodEmoji => text().nullable().named('mood_emoji')();
  TextColumn get activities => text().named('activities')();
  TextColumn get note => text().nullable().named('note')();
  DateTimeColumn get logDate => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('log_date')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FeedbackLocalData')
class FeedbacksTable extends Table {
  @override
  String get tableName => 'feedbacks';
  TextColumn get id => text()();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get message => text()();
  TextColumn get type => text()();
  TextColumn get localImagePath => text().nullable().named('local_image_path')();
  TextColumn get systemContext => text().nullable().named('system_context')();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('FocusSessionData')
class FocusSessionsTable extends Table {
  @override
  String get tableName => 'focus_sessions';
  TextColumn get id => text()();
  TextColumn get tenantID => text().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get projectID => text().nullable().named('project_id')();
  TextColumn get taskID => text().nullable().named('task_id')();
  DateTimeColumn get startTime => dateTime().map(const DateTimeUTCConverter()).named('start_time')();
  DateTimeColumn get endTime => dateTime().map(const DateTimeUTCConverter()).nullable().named('end_time')();
  IntColumn get durationSeconds => integer().named('duration_seconds')();
  TextColumn get status => text().withLength(min: 1, max: 20).named('status')();
  TextColumn get sessionType => text().withLength(min: 1, max: 20).withDefault(const Constant('Focus')).named('session_type')();
  TextColumn get notes => text().nullable().named('notes')();
  TextColumn get categories => text().nullable().named('categories')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at').nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at').nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('QuoteData')
class QuotesTable extends Table {
  @override
  String get tableName => 'quotes';
  TextColumn get id => text()();
  TextColumn get tenantID => text().withDefault(const Constant(DEFAULT_TENANT_ID)).named('tenant_id')();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get content => text()();
  TextColumn get author => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true)).named('is_active')();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('created_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('AiPromptData')
class AiPromptsTable extends Table {
  @override
  String get tableName => 'ai_prompts';
  TextColumn get id => text()();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get aiModel => text().named('ai_model')();
  TextColumn get prompt => text().named('prompt')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ConfigData')
class ConfigsTable extends Table {
  @override
  String get tableName => 'themes_config';
  TextColumn get id => text()();
  TextColumn get personID => text().nullable().named('person_id')();
  TextColumn get configKey => text().named('config_key')();
  TextColumn get configValue => text().named('config_value')();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime).map(const DateTimeUTCConverter()).named('updated_at')();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [{personID, configKey}];
}
