import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// No description provided for @helloWorld.
  ///
  /// In en, this message translates to:
  /// **'Hello World!'**
  String get helloWorld;

  /// No description provided for @homepage_four_life_elements.
  ///
  /// In en, this message translates to:
  /// **'4 Life Elements'**
  String get homepage_four_life_elements;

  /// No description provided for @homepage_plugin.
  ///
  /// In en, this message translates to:
  /// **'Plugin'**
  String get homepage_plugin;

  /// No description provided for @record_achievement.
  ///
  /// In en, this message translates to:
  /// **'RECORD ACHIEVEMENT'**
  String get record_achievement;

  /// No description provided for @update_achievement.
  ///
  /// In en, this message translates to:
  /// **'UPDATE ACHIEVEMENT'**
  String get update_achievement;

  /// No description provided for @achievement_title_label.
  ///
  /// In en, this message translates to:
  /// **'Achievement Title (e.g. Swinging in 2h)'**
  String get achievement_title_label;

  /// No description provided for @system_exp_reward.
  ///
  /// In en, this message translates to:
  /// **'System EXP Reward'**
  String get system_exp_reward;

  /// No description provided for @image_url.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get image_url;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @achievement_recorded.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT RECORDED IN SYSTEM'**
  String get achievement_recorded;

  /// No description provided for @achievement_updated.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENT UPDATED'**
  String get achievement_updated;

  /// No description provided for @system_error.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM ERROR: {error}'**
  String system_error(String error);

  /// No description provided for @record_feat.
  ///
  /// In en, this message translates to:
  /// **'RECORD FEAT'**
  String get record_feat;

  /// No description provided for @update_feat.
  ///
  /// In en, this message translates to:
  /// **'UPDATE FEAT'**
  String get update_feat;

  /// No description provided for @import_from_contacts.
  ///
  /// In en, this message translates to:
  /// **'Import from Contacts'**
  String get import_from_contacts;

  /// No description provided for @add_manually.
  ///
  /// In en, this message translates to:
  /// **'Add Manually'**
  String get add_manually;

  /// No description provided for @register_agent.
  ///
  /// In en, this message translates to:
  /// **'REGISTER AGENT'**
  String get register_agent;

  /// No description provided for @first_name.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name;

  /// No description provided for @last_name.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name;

  /// No description provided for @relationship_type.
  ///
  /// In en, this message translates to:
  /// **'RELATIONSHIP TYPE'**
  String get relationship_type;

  /// No description provided for @create_link.
  ///
  /// In en, this message translates to:
  /// **'CREATE LINK'**
  String get create_link;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'RANKING'**
  String get ranking;

  /// No description provided for @relationships.
  ///
  /// In en, this message translates to:
  /// **'RELATIONSHIPS'**
  String get relationships;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENTS'**
  String get achievements;

  /// No description provided for @current_rankings.
  ///
  /// In en, this message translates to:
  /// **'Current Rankings'**
  String get current_rankings;

  /// No description provided for @updated_time_ago.
  ///
  /// In en, this message translates to:
  /// **'UPDATED {time} AGO'**
  String updated_time_ago(String time);

  /// No description provided for @no_data_global_board.
  ///
  /// In en, this message translates to:
  /// **'No data in the Global Supremacy Board.'**
  String get no_data_global_board;

  /// No description provided for @calorie_tracker.
  ///
  /// In en, this message translates to:
  /// **'Calorie Tracker'**
  String get calorie_tracker;

  /// No description provided for @nutrition_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Dashboard'**
  String get nutrition_dashboard;

  /// No description provided for @net_calories.
  ///
  /// In en, this message translates to:
  /// **'Net Calories'**
  String get net_calories;

  /// No description provided for @goal_kcal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} kcal'**
  String goal_kcal(int goal);

  /// No description provided for @under_goal.
  ///
  /// In en, this message translates to:
  /// **'Under Goal'**
  String get under_goal;

  /// No description provided for @on_track.
  ///
  /// In en, this message translates to:
  /// **'On Track'**
  String get on_track;

  /// No description provided for @over_goal.
  ///
  /// In en, this message translates to:
  /// **'Over Goal'**
  String get over_goal;

  /// No description provided for @percent_of_daily_goal.
  ///
  /// In en, this message translates to:
  /// **'{percent}% of daily goal'**
  String percent_of_daily_goal(String percent);

  /// No description provided for @consumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get consumed;

  /// No description provided for @burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get burned;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @total_burn.
  ///
  /// In en, this message translates to:
  /// **'Total Burn'**
  String get total_burn;

  /// No description provided for @add_food.
  ///
  /// In en, this message translates to:
  /// **'Add Food'**
  String get add_food;

  /// No description provided for @lidar_scan.
  ///
  /// In en, this message translates to:
  /// **'LiDAR Scan'**
  String get lidar_scan;

  /// No description provided for @log_exercise.
  ///
  /// In en, this message translates to:
  /// **'Log Exercise'**
  String get log_exercise;

  /// No description provided for @calories_burned_label.
  ///
  /// In en, this message translates to:
  /// **'Calories burned'**
  String get calories_burned_label;

  /// No description provided for @quick_add_exercise.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Exercise'**
  String get quick_add_exercise;

  /// No description provided for @added_food_msg.
  ///
  /// In en, this message translates to:
  /// **'Added {name} ({cal} kcal)'**
  String added_food_msg(String name, int cal);

  /// No description provided for @lidar_ios_only.
  ///
  /// In en, this message translates to:
  /// **'LiDAR scanning is only available on iOS devices.'**
  String get lidar_ios_only;

  /// No description provided for @lidar_completed.
  ///
  /// In en, this message translates to:
  /// **'LiDAR scan completed! Processing volume data...'**
  String get lidar_completed;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @progress_to_level.
  ///
  /// In en, this message translates to:
  /// **'Progress to Level {level}'**
  String progress_to_level(int level);

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get health;

  /// No description provided for @finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get finance;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @kcal_consume.
  ///
  /// In en, this message translates to:
  /// **'Kcal Consume'**
  String get kcal_consume;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'HR'**
  String get hr;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get savings;

  /// No description provided for @total_users.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get total_users;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @mutual.
  ///
  /// In en, this message translates to:
  /// **'Mutual'**
  String get mutual;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @projs.
  ///
  /// In en, this message translates to:
  /// **'Projs'**
  String get projs;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add_app_plugin.
  ///
  /// In en, this message translates to:
  /// **'Add App Plugin'**
  String get add_app_plugin;

  /// No description provided for @plugin_desc.
  ///
  /// In en, this message translates to:
  /// **'Choose a plugin to extend your dashboard'**
  String get plugin_desc;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @canvas_add_custom_widget.
  ///
  /// In en, this message translates to:
  /// **'Add Custom Widget'**
  String get canvas_add_custom_widget;

  /// No description provided for @canvas_add_widget_desc.
  ///
  /// In en, this message translates to:
  /// **'Enter the name and URL of the website you want to add.'**
  String get canvas_add_widget_desc;

  /// No description provided for @canvas_notification_center.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get canvas_notification_center;

  /// No description provided for @canvas_notification_desc.
  ///
  /// In en, this message translates to:
  /// **'Manage your alerts and focus history'**
  String get canvas_notification_desc;

  /// No description provided for @canvas_goal_center.
  ///
  /// In en, this message translates to:
  /// **'Goal Center'**
  String get canvas_goal_center;

  /// No description provided for @canvas_goal_desc.
  ///
  /// In en, this message translates to:
  /// **'Track your daily health evolution'**
  String get canvas_goal_desc;

  /// No description provided for @goal_target_evolution.
  ///
  /// In en, this message translates to:
  /// **'TARGET EVOLUTION'**
  String get goal_target_evolution;

  /// No description provided for @goal_mission.
  ///
  /// In en, this message translates to:
  /// **'MISSION'**
  String get goal_mission;

  /// No description provided for @goal_mission_desc.
  ///
  /// In en, this message translates to:
  /// **'Configure your physical parameters to ensure optimal AI synchronization and field performance.'**
  String get goal_mission_desc;

  /// No description provided for @goal_step_target.
  ///
  /// In en, this message translates to:
  /// **'STEP TARGET'**
  String get goal_step_target;

  /// No description provided for @goal_calorie_limit.
  ///
  /// In en, this message translates to:
  /// **'CALORIE LIMIT'**
  String get goal_calorie_limit;

  /// No description provided for @goal_water_target.
  ///
  /// In en, this message translates to:
  /// **'WATER TARGET'**
  String get goal_water_target;

  /// No description provided for @goal_focus_target.
  ///
  /// In en, this message translates to:
  /// **'FOCUS TARGET'**
  String get goal_focus_target;

  /// No description provided for @goal_exercise_target.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE TARGET'**
  String get goal_exercise_target;

  /// No description provided for @goal_sleep_target.
  ///
  /// In en, this message translates to:
  /// **'SLEEP TARGET'**
  String get goal_sleep_target;

  /// No description provided for @unit_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get unit_kcal;

  /// No description provided for @unit_ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unit_ml;

  /// No description provided for @unit_min.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unit_min;

  /// No description provided for @unit_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get unit_hours;

  /// No description provided for @scoring_rules_title.
  ///
  /// In en, this message translates to:
  /// **'Scoring Rules'**
  String get scoring_rules_title;

  /// No description provided for @scoring_health.
  ///
  /// In en, this message translates to:
  /// **'🏃 Health'**
  String get scoring_health;

  /// No description provided for @scoring_career.
  ///
  /// In en, this message translates to:
  /// **'💼 Career (Projects)'**
  String get scoring_career;

  /// No description provided for @scoring_finance.
  ///
  /// In en, this message translates to:
  /// **'💰 Finance'**
  String get scoring_finance;

  /// No description provided for @scoring_social.
  ///
  /// In en, this message translates to:
  /// **'❤️ Social'**
  String get scoring_social;

  /// No description provided for @rule_health_steps.
  ///
  /// In en, this message translates to:
  /// **'1 Point per {steps} steps walked'**
  String rule_health_steps(int steps);

  /// No description provided for @rule_health_calories.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for staying under {limit} kcal/day'**
  String rule_health_calories(int points, int limit);

  /// No description provided for @rule_health_auto.
  ///
  /// In en, this message translates to:
  /// **'Points automatically update when health metrics are recorded'**
  String get rule_health_auto;

  /// No description provided for @rule_career_project.
  ///
  /// In en, this message translates to:
  /// **'{points} Base Points for completing a project'**
  String rule_career_project(int points);

  /// No description provided for @rule_career_task.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for each task completed'**
  String rule_career_task(int points);

  /// No description provided for @rule_career_bonus_5.
  ///
  /// In en, this message translates to:
  /// **'{points} Bonus Points for projects with 5+ tasks'**
  String rule_career_bonus_5(int points);

  /// No description provided for @rule_career_bonus_10.
  ///
  /// In en, this message translates to:
  /// **'{points} Bonus Points for projects with 10+ tasks'**
  String rule_career_bonus_10(int points);

  /// No description provided for @rule_career_bonus_doc.
  ///
  /// In en, this message translates to:
  /// **'{points} Bonus Points for having 3+ research notes'**
  String rule_career_bonus_doc(int points);

  /// No description provided for @rule_career_bonus_week.
  ///
  /// In en, this message translates to:
  /// **'{points} Bonus Points for projects active for 7+ days'**
  String rule_career_bonus_week(int points);

  /// No description provided for @rule_finance_savings.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for every \${milestone} saved (Net Worth)'**
  String rule_finance_savings(int points, int milestone);

  /// No description provided for @rule_finance_investment.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for every {threshold}% investment return'**
  String rule_finance_investment(int points, int threshold);

  /// No description provided for @rule_finance_auto.
  ///
  /// In en, this message translates to:
  /// **'Points update as account balances and asset values change'**
  String get rule_finance_auto;

  /// No description provided for @rule_social_contact.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for each unique contact added'**
  String rule_social_contact(int points);

  /// No description provided for @rule_social_affection.
  ///
  /// In en, this message translates to:
  /// **'{points} Points for every {unit} affection points earned'**
  String rule_social_affection(int points, int unit);

  /// No description provided for @rule_social_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain relationships to keep your social score high'**
  String get rule_social_maintain;

  /// No description provided for @how_it_works.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get how_it_works;

  /// No description provided for @scoring_intro.
  ///
  /// In en, this message translates to:
  /// **'The Ice Gate scoring system measures your growth across four key life elements. Your Global Level is calculated from the sum of these scores. Maintain a high score to unlock legendary status.'**
  String get scoring_intro;

  /// No description provided for @scoring_footer.
  ///
  /// In en, this message translates to:
  /// **'Balance your physical, social, financial, and workspace growth to become a Legend.'**
  String get scoring_footer;

  /// No description provided for @personal_info_title.
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personal_info_title;

  /// No description provided for @personal_info_identification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get personal_info_identification;

  /// No description provided for @personal_info_professional_matrix.
  ///
  /// In en, this message translates to:
  /// **'Professional Matrix'**
  String get personal_info_professional_matrix;

  /// No description provided for @personal_info_education_node.
  ///
  /// In en, this message translates to:
  /// **'Education Node'**
  String get personal_info_education_node;

  /// No description provided for @personal_info_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get personal_info_location;

  /// No description provided for @personal_info_digital.
  ///
  /// In en, this message translates to:
  /// **'Digital'**
  String get personal_info_digital;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @first_name_label.
  ///
  /// In en, this message translates to:
  /// **'First Name'**
  String get first_name_label;

  /// No description provided for @last_name_label.
  ///
  /// In en, this message translates to:
  /// **'Last Name'**
  String get last_name_label;

  /// No description provided for @email_label.
  ///
  /// In en, this message translates to:
  /// **'eMail'**
  String get email_label;

  /// No description provided for @phone_number_label.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number_label;

  /// No description provided for @role_label.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get role_label;

  /// No description provided for @organization_label.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization_label;

  /// No description provided for @institution_label.
  ///
  /// In en, this message translates to:
  /// **'Institution'**
  String get institution_label;

  /// No description provided for @education_level_label.
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get education_level_label;

  /// No description provided for @country_label.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country_label;

  /// No description provided for @city_label.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city_label;

  /// No description provided for @github_label.
  ///
  /// In en, this message translates to:
  /// **'GitHub'**
  String get github_label;

  /// No description provided for @linkedin_label.
  ///
  /// In en, this message translates to:
  /// **'LinkedIn'**
  String get linkedin_label;

  /// No description provided for @personal_web_label.
  ///
  /// In en, this message translates to:
  /// **'Personal Web'**
  String get personal_web_label;

  /// No description provided for @msg_personal_info_saved.
  ///
  /// In en, this message translates to:
  /// **'Personal information saved successfully'**
  String get msg_personal_info_saved;

  /// No description provided for @msg_err_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes: {error}'**
  String msg_err_save_failed(String error);

  /// No description provided for @msg_avatar_updated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated!'**
  String get msg_avatar_updated;

  /// No description provided for @msg_avatar_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Avatar upload cancelled'**
  String get msg_avatar_cancelled;

  /// No description provided for @msg_cover_updated.
  ///
  /// In en, this message translates to:
  /// **'Cover updated!'**
  String get msg_cover_updated;

  /// No description provided for @msg_cover_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cover upload cancelled'**
  String get msg_cover_cancelled;

  /// No description provided for @msg_err_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String msg_err_upload_failed(String error);

  /// No description provided for @msg_err_not_authenticated.
  ///
  /// In en, this message translates to:
  /// **'Error: Not authenticated'**
  String get msg_err_not_authenticated;

  /// No description provided for @change_cover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get change_cover;

  /// No description provided for @change_avatar.
  ///
  /// In en, this message translates to:
  /// **'Change Avatar'**
  String get change_avatar;

  /// No description provided for @analysis_user_title.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Analysis'**
  String analysis_user_title(String name);

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'LIFE GATEWAY'**
  String get tagline;

  /// No description provided for @username_email_hint.
  ///
  /// In en, this message translates to:
  /// **'USERNAME / eMAIL'**
  String get username_email_hint;

  /// No description provided for @password_hint.
  ///
  /// In en, this message translates to:
  /// **'PASSWORD'**
  String get password_hint;

  /// No description provided for @go_to_gate.
  ///
  /// In en, this message translates to:
  /// **'GO TO GATE'**
  String get go_to_gate;

  /// No description provided for @secure_login.
  ///
  /// In en, this message translates to:
  /// **'SECURE LOGIN'**
  String get secure_login;

  /// No description provided for @google_login.
  ///
  /// In en, this message translates to:
  /// **'GOOGLE'**
  String get google_login;

  /// No description provided for @guest_access.
  ///
  /// In en, this message translates to:
  /// **'GUEST ACCESS'**
  String get guest_access;

  /// No description provided for @enroll_hub.
  ///
  /// In en, this message translates to:
  /// **'ENROLL HUB'**
  String get enroll_hub;

  /// No description provided for @msg_enter_credentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter username and password'**
  String get msg_enter_credentials;

  /// No description provided for @msg_secure_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Secure Login failed: {error}'**
  String msg_secure_login_failed(String error);

  /// No description provided for @performance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get performance;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @guest_mode.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guest_mode;

  /// No description provided for @sync_desc.
  ///
  /// In en, this message translates to:
  /// **'Synchronize to save your progress.'**
  String get sync_desc;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @score_balance.
  ///
  /// In en, this message translates to:
  /// **'SCORE BALANCE'**
  String get score_balance;

  /// No description provided for @percent_to_level.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to level {level}'**
  String percent_to_level(int percent, int level);

  /// No description provided for @total_xp.
  ///
  /// In en, this message translates to:
  /// **'Total XP: {xp}'**
  String total_xp(int xp);

  /// No description provided for @breakdown_steps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get breakdown_steps;

  /// No description provided for @breakdown_diet.
  ///
  /// In en, this message translates to:
  /// **'DIET'**
  String get breakdown_diet;

  /// No description provided for @breakdown_exercise.
  ///
  /// In en, this message translates to:
  /// **'EXERCISE'**
  String get breakdown_exercise;

  /// No description provided for @breakdown_focus.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get breakdown_focus;

  /// No description provided for @breakdown_water.
  ///
  /// In en, this message translates to:
  /// **'WATER'**
  String get breakdown_water;

  /// No description provided for @breakdown_sleep.
  ///
  /// In en, this message translates to:
  /// **'SLEEP'**
  String get breakdown_sleep;

  /// No description provided for @breakdown_contacts.
  ///
  /// In en, this message translates to:
  /// **'CONTACTS'**
  String get breakdown_contacts;

  /// No description provided for @breakdown_affection.
  ///
  /// In en, this message translates to:
  /// **'AFFECTION'**
  String get breakdown_affection;

  /// No description provided for @breakdown_quests.
  ///
  /// In en, this message translates to:
  /// **'QUESTS'**
  String get breakdown_quests;

  /// No description provided for @breakdown_accounts.
  ///
  /// In en, this message translates to:
  /// **'ACCOUNTS'**
  String get breakdown_accounts;

  /// No description provided for @breakdown_assets.
  ///
  /// In en, this message translates to:
  /// **'ASSETS'**
  String get breakdown_assets;

  /// No description provided for @breakdown_tasks.
  ///
  /// In en, this message translates to:
  /// **'TASKS'**
  String get breakdown_tasks;

  /// No description provided for @breakdown_projects.
  ///
  /// In en, this message translates to:
  /// **'PROJECTS'**
  String get breakdown_projects;

  /// No description provided for @breakdown_system.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM'**
  String get breakdown_system;

  /// No description provided for @app_settings_title.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get app_settings_title;

  /// No description provided for @guest_user.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest_user;

  /// No description provided for @msg_sign_in_to_sync.
  ///
  /// In en, this message translates to:
  /// **'Sign in to sync your data'**
  String get msg_sign_in_to_sync;

  /// No description provided for @member_status.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get member_status;

  /// No description provided for @account_section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_section;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @edit_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your name and photo'**
  String get edit_profile_subtitle;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @change_username.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get change_username;

  /// No description provided for @preferences_section.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences_section;

  /// No description provided for @change_theme.
  ///
  /// In en, this message translates to:
  /// **'Change Theme'**
  String get change_theme;

  /// No description provided for @system_notifications.
  ///
  /// In en, this message translates to:
  /// **'System Notifications'**
  String get system_notifications;

  /// No description provided for @notifications_active.
  ///
  /// In en, this message translates to:
  /// **'Notifications are active'**
  String get notifications_active;

  /// No description provided for @notifications_paused.
  ///
  /// In en, this message translates to:
  /// **'Notifications are paused'**
  String get notifications_paused;

  /// No description provided for @about_support_section.
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get about_support_section;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manual;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @reset_database_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Database?'**
  String get reset_database_title;

  /// No description provided for @reset_database_msg.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your local data including focus sessions, health logs, and settings. This action cannot be undone.'**
  String get reset_database_msg;

  /// No description provided for @msg_database_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Database reset successful.'**
  String get msg_database_reset_success;

  /// No description provided for @btn_reset_all_data.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL DATA'**
  String get btn_reset_all_data;

  /// No description provided for @security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security_title;

  /// No description provided for @set_password.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get set_password;

  /// No description provided for @msg_password_requirement.
  ///
  /// In en, this message translates to:
  /// **'Your new password must be at least 6 characters long and different from previous ones.'**
  String get msg_password_requirement;

  /// No description provided for @msg_no_local_password.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t set a local password yet. Create one to enable email/password login.'**
  String get msg_no_local_password;

  /// No description provided for @current_password_label.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get current_password_label;

  /// No description provided for @enter_current_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter current password'**
  String get enter_current_password_hint;

  /// No description provided for @err_enter_current_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter current password'**
  String get err_enter_current_password;

  /// No description provided for @new_password_label.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password_label;

  /// No description provided for @enter_new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enter_new_password_hint;

  /// No description provided for @err_enter_password.
  ///
  /// In en, this message translates to:
  /// **'Please enter a password'**
  String get err_enter_password;

  /// No description provided for @err_password_length.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get err_password_length;

  /// No description provided for @confirm_password_label.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password_label;

  /// No description provided for @confirm_new_password_hint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirm_new_password_hint;

  /// No description provided for @err_confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get err_confirm_password;

  /// No description provided for @err_passwords_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get err_passwords_not_match;

  /// No description provided for @btn_update_password.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get btn_update_password;

  /// No description provided for @msg_password_success.
  ///
  /// In en, this message translates to:
  /// **'Password set successfully!'**
  String get msg_password_success;

  /// No description provided for @err_unexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String err_unexpected(String error);

  /// No description provided for @err_verification_failed.
  ///
  /// In en, this message translates to:
  /// **'Current password verification failed. Please check your credentials.'**
  String get err_verification_failed;

  /// No description provided for @change_username_title.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get change_username_title;

  /// No description provided for @unique_username_header.
  ///
  /// In en, this message translates to:
  /// **'Your Unique Username'**
  String get unique_username_header;

  /// No description provided for @username_description.
  ///
  /// In en, this message translates to:
  /// **'Your username is used to log in and identify you within the application. It must be at least 3 characters long.'**
  String get username_description;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @enter_new_username_hint.
  ///
  /// In en, this message translates to:
  /// **'Enter new username'**
  String get enter_new_username_hint;

  /// No description provided for @err_enter_username.
  ///
  /// In en, this message translates to:
  /// **'Please enter a username'**
  String get err_enter_username;

  /// No description provided for @err_username_length.
  ///
  /// In en, this message translates to:
  /// **'Username must be at least 3 characters'**
  String get err_username_length;

  /// No description provided for @err_username_invalid_char.
  ///
  /// In en, this message translates to:
  /// **'Username cannot contain \"@\"'**
  String get err_username_invalid_char;

  /// No description provided for @btn_update_username.
  ///
  /// In en, this message translates to:
  /// **'UPDATE USERNAME'**
  String get btn_update_username;

  /// No description provided for @msg_username_success.
  ///
  /// In en, this message translates to:
  /// **'Username updated successfully!'**
  String get msg_username_success;

  /// No description provided for @err_username_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update username: {error}'**
  String err_username_failed(String error);

  /// No description provided for @added_calories_burned.
  ///
  /// In en, this message translates to:
  /// **'Added {cal} kcal burned'**
  String added_calories_burned(int cal);

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @health_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get health_insights;

  /// No description provided for @health_log_water.
  ///
  /// In en, this message translates to:
  /// **'Log Water'**
  String get health_log_water;

  /// No description provided for @health_log_food.
  ///
  /// In en, this message translates to:
  /// **'Log Food'**
  String get health_log_food;

  /// No description provided for @health_exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get health_exercise;

  /// No description provided for @health_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get health_focus;

  /// No description provided for @health_log_exercise.
  ///
  /// In en, this message translates to:
  /// **'Log Exercise'**
  String get health_log_exercise;

  /// No description provided for @health_calories_burned_label.
  ///
  /// In en, this message translates to:
  /// **'Calories burned'**
  String get health_calories_burned_label;

  /// No description provided for @health_quick_add_exercise.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Exercise'**
  String get health_quick_add_exercise;

  /// No description provided for @health_walking_30min.
  ///
  /// In en, this message translates to:
  /// **'Walking 30min'**
  String get health_walking_30min;

  /// No description provided for @health_running_30min.
  ///
  /// In en, this message translates to:
  /// **'Running 30min'**
  String get health_running_30min;

  /// No description provided for @health_cycling_30min.
  ///
  /// In en, this message translates to:
  /// **'Cycling 30min'**
  String get health_cycling_30min;

  /// No description provided for @health_swimming_30min.
  ///
  /// In en, this message translates to:
  /// **'Swimming 30min'**
  String get health_swimming_30min;

  /// No description provided for @health_yoga_30min.
  ///
  /// In en, this message translates to:
  /// **'Yoga 30min'**
  String get health_yoga_30min;

  /// No description provided for @health_water_log.
  ///
  /// In en, this message translates to:
  /// **'Water Log'**
  String get health_water_log;

  /// No description provided for @health_water_goal.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get health_water_goal;

  /// No description provided for @health_water_points.
  ///
  /// In en, this message translates to:
  /// **'POINTS'**
  String get health_water_points;

  /// No description provided for @health_water_left.
  ///
  /// In en, this message translates to:
  /// **'LEFT'**
  String get health_water_left;

  /// No description provided for @health_water_of_ml.
  ///
  /// In en, this message translates to:
  /// **'OF {goal} ML'**
  String health_water_of_ml(int goal);

  /// No description provided for @health_stay_hydrated.
  ///
  /// In en, this message translates to:
  /// **'STAY HYDRATED'**
  String get health_stay_hydrated;

  /// No description provided for @health_custom_intake.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM INTAKE'**
  String get health_custom_intake;

  /// No description provided for @health_unit_ml.
  ///
  /// In en, this message translates to:
  /// **'ML'**
  String get health_unit_ml;

  /// No description provided for @health_sleep_tracker.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracker'**
  String get health_sleep_tracker;

  /// No description provided for @health_healthkit_sleep.
  ///
  /// In en, this message translates to:
  /// **'HealthKit Sleep'**
  String get health_healthkit_sleep;

  /// No description provided for @health_last_24h_apple.
  ///
  /// In en, this message translates to:
  /// **'Last 24h from Apple Health'**
  String get health_last_24h_apple;

  /// No description provided for @health_last_session.
  ///
  /// In en, this message translates to:
  /// **'Last Session'**
  String get health_last_session;

  /// No description provided for @health_no_sleep_records.
  ///
  /// In en, this message translates to:
  /// **'No sleep sessions recorded yet.'**
  String get health_no_sleep_records;

  /// No description provided for @health_log_sleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep'**
  String get health_log_sleep;

  /// No description provided for @health_bedtime.
  ///
  /// In en, this message translates to:
  /// **'Bedtime'**
  String get health_bedtime;

  /// No description provided for @health_wake_up.
  ///
  /// In en, this message translates to:
  /// **'Wake up'**
  String get health_wake_up;

  /// No description provided for @health_quality.
  ///
  /// In en, this message translates to:
  /// **'Quality'**
  String get health_quality;

  /// No description provided for @health_save_session.
  ///
  /// In en, this message translates to:
  /// **'Save Session'**
  String get health_save_session;

  /// No description provided for @health_history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get health_history;

  /// No description provided for @health_sleep_saved.
  ///
  /// In en, this message translates to:
  /// **'Sleep session saved!'**
  String get health_sleep_saved;

  /// No description provided for @health_hrs.
  ///
  /// In en, this message translates to:
  /// **'{hours} hrs'**
  String health_hrs(String hours);

  /// No description provided for @health_quality_stars.
  ///
  /// In en, this message translates to:
  /// **'Quality: {stars}'**
  String health_quality_stars(String stars);

  /// No description provided for @health_activity_tracker.
  ///
  /// In en, this message translates to:
  /// **'Activity Tracker'**
  String get health_activity_tracker;

  /// No description provided for @health_syncing_data.
  ///
  /// In en, this message translates to:
  /// **'Syncing health data...'**
  String get health_syncing_data;

  /// No description provided for @health_refresh_steps.
  ///
  /// In en, this message translates to:
  /// **'Refresh Steps'**
  String get health_refresh_steps;

  /// No description provided for @health_steps_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Steps Dashboard'**
  String get health_steps_dashboard;

  /// No description provided for @health_steps_taken.
  ///
  /// In en, this message translates to:
  /// **'Steps Taken'**
  String get health_steps_taken;

  /// No description provided for @health_percent_completed.
  ///
  /// In en, this message translates to:
  /// **'{percent}% Completed'**
  String health_percent_completed(String percent);

  /// No description provided for @health_daily_statistics.
  ///
  /// In en, this message translates to:
  /// **'Daily Statistics'**
  String get health_daily_statistics;

  /// No description provided for @health_lifetime_total.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Total'**
  String get health_lifetime_total;

  /// No description provided for @health_remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get health_remaining;

  /// No description provided for @health_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get health_distance;

  /// No description provided for @health_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get health_calories;

  /// No description provided for @health_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active Time'**
  String get health_active_time;

  /// No description provided for @health_metrics_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get health_metrics_water;

  /// No description provided for @health_metrics_exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get health_metrics_exercise;

  /// No description provided for @health_metrics_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get health_metrics_focus;

  /// No description provided for @health_metrics_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get health_metrics_distance;

  /// No description provided for @health_metrics_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get health_metrics_calories;

  /// No description provided for @health_metrics_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active Time'**
  String get health_metrics_active_time;

  /// No description provided for @health_metrics_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get health_metrics_steps;

  /// No description provided for @health_metrics_heart_rate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get health_metrics_heart_rate;

  /// No description provided for @health_metrics_sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get health_metrics_sleep;

  /// No description provided for @health_metrics_calories_consumed.
  ///
  /// In en, this message translates to:
  /// **'Calories Consumed'**
  String get health_metrics_calories_consumed;

  /// No description provided for @health_metrics_calories_burned.
  ///
  /// In en, this message translates to:
  /// **'Calories Burned'**
  String get health_metrics_calories_burned;

  /// No description provided for @health_metrics_net_calories.
  ///
  /// In en, this message translates to:
  /// **'Net Calories'**
  String get health_metrics_net_calories;

  /// No description provided for @health_metrics_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get health_metrics_weight;

  /// No description provided for @health_metrics_detail_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Detail page for {name} coming soon!'**
  String health_metrics_detail_coming_soon(String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
