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

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Ice Gate'**
  String get app_title;

  /// No description provided for @home_welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get home_welcome;

  /// No description provided for @health_title.
  ///
  /// In en, this message translates to:
  /// **'Health & Fitness'**
  String get health_title;

  /// No description provided for @health_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get health_steps;

  /// No description provided for @health_sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get health_sleep;

  /// No description provided for @health_heart_rate.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get health_heart_rate;

  /// No description provided for @health_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get health_water;

  /// No description provided for @health_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get health_weight;

  /// No description provided for @health_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get health_calories;

  /// No description provided for @health_activity.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get health_activity;

  /// No description provided for @health_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get health_goal;

  /// No description provided for @health_avg.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get health_avg;

  /// No description provided for @health_max.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get health_max;

  /// No description provided for @health_min.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get health_min;

  /// No description provided for @health_last_7_days.
  ///
  /// In en, this message translates to:
  /// **'Last 7 Days'**
  String get health_last_7_days;

  /// No description provided for @health_last_30_days.
  ///
  /// In en, this message translates to:
  /// **'Last 30 Days'**
  String get health_last_30_days;

  /// No description provided for @health_sync_title.
  ///
  /// In en, this message translates to:
  /// **'Sync Data'**
  String get health_sync_title;

  /// No description provided for @health_sync_msg.
  ///
  /// In en, this message translates to:
  /// **'Syncing health data...'**
  String get health_sync_msg;

  /// No description provided for @health_sync_success.
  ///
  /// In en, this message translates to:
  /// **'Health data synced!'**
  String get health_sync_success;

  /// No description provided for @health_sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Please try again.'**
  String get health_sync_failed;

  /// No description provided for @health_update_weight.
  ///
  /// In en, this message translates to:
  /// **'Update Weight'**
  String get health_update_weight;

  /// No description provided for @health_log_water.
  ///
  /// In en, this message translates to:
  /// **'Log Water'**
  String get health_log_water;

  /// No description provided for @health_daily_goal_reached.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your daily goal!'**
  String get health_daily_goal_reached;

  /// No description provided for @health_almost_there.
  ///
  /// In en, this message translates to:
  /// **'Almost there! Just a little more.'**
  String get health_almost_there;

  /// No description provided for @health_keep_moving.
  ///
  /// In en, this message translates to:
  /// **'Keep moving to reach your goal.'**
  String get health_keep_moving;

  /// No description provided for @health_good_morning.
  ///
  /// In en, this message translates to:
  /// **'Good Morning'**
  String get health_good_morning;

  /// No description provided for @health_good_afternoon.
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon'**
  String get health_good_afternoon;

  /// No description provided for @health_good_evening.
  ///
  /// In en, this message translates to:
  /// **'Good Evening'**
  String get health_good_evening;

  /// No description provided for @health_good_night.
  ///
  /// In en, this message translates to:
  /// **'Good Night'**
  String get health_good_night;

  /// No description provided for @health_bpm.
  ///
  /// In en, this message translates to:
  /// **'BPM'**
  String get health_bpm;

  /// No description provided for @health_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get health_kcal;

  /// No description provided for @health_meters.
  ///
  /// In en, this message translates to:
  /// **'m'**
  String get health_meters;

  /// No description provided for @health_kilometers.
  ///
  /// In en, this message translates to:
  /// **'km'**
  String get health_kilometers;

  /// No description provided for @health_steps_unit.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get health_steps_unit;

  /// No description provided for @health_hours.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get health_hours;

  /// No description provided for @health_minutes.
  ///
  /// In en, this message translates to:
  /// **'minutes'**
  String get health_minutes;

  /// No description provided for @health_ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get health_ml;

  /// No description provided for @health_kg.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get health_kg;

  /// No description provided for @health_lb.
  ///
  /// In en, this message translates to:
  /// **'lb'**
  String get health_lb;

  /// No description provided for @health_exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get health_exercise;

  /// No description provided for @health_intensity_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get health_intensity_low;

  /// No description provided for @health_intensity_moderate.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get health_intensity_moderate;

  /// No description provided for @health_intensity_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get health_intensity_high;

  /// No description provided for @health_intensity_extreme.
  ///
  /// In en, this message translates to:
  /// **'Extreme'**
  String get health_intensity_extreme;

  /// No description provided for @health_activity_balance.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY BALANCE'**
  String get health_activity_balance;

  /// No description provided for @health_balance_moving_much.
  ///
  /// In en, this message translates to:
  /// **'You\'re moving a lot! Great step count.'**
  String get health_balance_moving_much;

  /// No description provided for @health_balance_optimal.
  ///
  /// In en, this message translates to:
  /// **'Your exercise distribution looks optimal today.'**
  String get health_balance_optimal;

  /// No description provided for @health_weekly_trends.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY TRENDS'**
  String get health_weekly_trends;

  /// No description provided for @health_avg_steps.
  ///
  /// In en, this message translates to:
  /// **'Avg Steps'**
  String get health_avg_steps;

  /// No description provided for @health_avg_sleep.
  ///
  /// In en, this message translates to:
  /// **'Avg Sleep'**
  String get health_avg_sleep;

  /// No description provided for @health_avg_hr.
  ///
  /// In en, this message translates to:
  /// **'Avg HR'**
  String get health_avg_hr;

  /// No description provided for @health_insights_title.
  ///
  /// In en, this message translates to:
  /// **'INSIGHTS'**
  String get health_insights_title;

  /// No description provided for @health_insights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get health_insights;

  /// No description provided for @health_insight_above_avg.
  ///
  /// In en, this message translates to:
  /// **'Above average'**
  String get health_insight_above_avg;

  /// No description provided for @health_insight_keep_pushing.
  ///
  /// In en, this message translates to:
  /// **'Keep pushing'**
  String get health_insight_keep_pushing;

  /// No description provided for @health_insight_activity_higher.
  ///
  /// In en, this message translates to:
  /// **'Your activity is higher than your 7-day average.'**
  String get health_insight_activity_higher;

  /// No description provided for @health_insight_activity_lower.
  ///
  /// In en, this message translates to:
  /// **'Try to take a walk to reach your daily average of {steps} steps.'**
  String health_insight_activity_lower(int steps);

  /// No description provided for @health_insight_goal_reached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached! You\'re very active today.'**
  String get health_insight_goal_reached;

  /// No description provided for @health_insight_goal_percent.
  ///
  /// In en, this message translates to:
  /// **'You\'ve completed {percent}% of your daily goal.'**
  String health_insight_goal_percent(String percent);

  /// No description provided for @health_hydration_title.
  ///
  /// In en, this message translates to:
  /// **'Hydration'**
  String get health_hydration_title;

  /// No description provided for @health_hydration_track_msg.
  ///
  /// In en, this message translates to:
  /// **'You\'re on track with your water intake goals!'**
  String get health_hydration_track_msg;

  /// No description provided for @health_bpm_label.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get health_bpm_label;

  /// No description provided for @health_hours_label.
  ///
  /// In en, this message translates to:
  /// **'hours'**
  String get health_hours_label;

  /// No description provided for @project_title_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get project_title_label;

  /// No description provided for @notification_reminder_new.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get notification_reminder_new;

  /// No description provided for @notification_reminder_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get notification_reminder_edit;

  /// No description provided for @notification_repeat_label.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get notification_repeat_label;

  /// No description provided for @notification_date_label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get notification_date_label;

  /// No description provided for @notification_time_label.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get notification_time_label;

  /// No description provided for @notification_save_reminder.
  ///
  /// In en, this message translates to:
  /// **'Save Reminder'**
  String get notification_save_reminder;

  /// No description provided for @notification_update_reminder.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notification_update_reminder;

  /// No description provided for @notification_category_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get notification_category_general;

  /// No description provided for @notification_category_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get notification_category_daily;

  /// No description provided for @notification_category_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get notification_category_health;

  /// No description provided for @notification_category_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get notification_category_finance;

  /// No description provided for @notification_category_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get notification_category_social;

  /// No description provided for @notification_category_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get notification_category_projects;

  /// No description provided for @notification_priority_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get notification_priority_low;

  /// No description provided for @notification_priority_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get notification_priority_normal;

  /// No description provided for @notification_priority_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get notification_priority_high;

  /// No description provided for @notification_priority_urgent.
  ///
  /// In en, this message translates to:
  /// **'Urgent'**
  String get notification_priority_urgent;

  /// No description provided for @notification_freq_once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get notification_freq_once;

  /// No description provided for @notification_freq_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get notification_freq_daily;

  /// No description provided for @notification_freq_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get notification_freq_weekly;

  /// No description provided for @notification_enter_title_snack.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get notification_enter_title_snack;

  /// No description provided for @nutri_trends_title.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Trends'**
  String get nutri_trends_title;

  /// No description provided for @nutri_weekly_avg.
  ///
  /// In en, this message translates to:
  /// **'Weekly Avg'**
  String get nutri_weekly_avg;

  /// No description provided for @nutri_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Nutri Insights'**
  String get nutri_insights_title;

  /// No description provided for @nutri_advice_low_protein.
  ///
  /// In en, this message translates to:
  /// **'Your protein intake is a bit low this week. Try adding eggs or lean meat.'**
  String get nutri_advice_low_protein;

  /// No description provided for @nutri_advice_high_cal.
  ///
  /// In en, this message translates to:
  /// **'You\'ve exceeded your calorie limit recently. Consider lighter meals tomorrow.'**
  String get nutri_advice_high_cal;

  /// No description provided for @nutri_advice_good_job.
  ///
  /// In en, this message translates to:
  /// **'Great job! You\'re maintaining a good balance and staying on track.'**
  String get nutri_advice_good_job;

  /// No description provided for @nutri_advice_more_water.
  ///
  /// In en, this message translates to:
  /// **'Don\'t forget to drink water. Hydration helps with metabolism.'**
  String get nutri_advice_more_water;

  /// No description provided for @nutri_weekly_calories_chart.
  ///
  /// In en, this message translates to:
  /// **'Weekly Calories'**
  String get nutri_weekly_calories_chart;

  /// No description provided for @nutri_macro_distribution.
  ///
  /// In en, this message translates to:
  /// **'Macro Distribution'**
  String get nutri_macro_distribution;

  /// No description provided for @nutrition_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Nutrition Dashboard'**
  String get nutrition_dashboard;

  /// No description provided for @nutri_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get nutri_total;

  /// No description provided for @nutri_protein.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get nutri_protein;

  /// No description provided for @nutri_carbs.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get nutri_carbs;

  /// No description provided for @nutri_fat.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get nutri_fat;

  /// No description provided for @nutri_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get nutri_today;

  /// No description provided for @nutri_no_meals.
  ///
  /// In en, this message translates to:
  /// **'No meals logged yet'**
  String get nutri_no_meals;

  /// No description provided for @nutri_kcal.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get nutri_kcal;

  /// No description provided for @nutri_cal.
  ///
  /// In en, this message translates to:
  /// **'cal'**
  String get nutri_cal;

  /// No description provided for @todays_gains.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Gains'**
  String get todays_gains;

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

  /// No description provided for @health_metrics_calories_burned.
  ///
  /// In en, this message translates to:
  /// **'Burned'**
  String get health_metrics_calories_burned;

  /// No description provided for @health_metrics_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get health_metrics_weight;

  /// No description provided for @health_metrics_net_calories.
  ///
  /// In en, this message translates to:
  /// **'Net Cal'**
  String get health_metrics_net_calories;

  /// No description provided for @health_metrics_calories_consumed.
  ///
  /// In en, this message translates to:
  /// **'Consumed'**
  String get health_metrics_calories_consumed;

  /// No description provided for @health_metrics_detail_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Detail page for {name} coming soon!'**
  String health_metrics_detail_coming_soon(String name);

  /// No description provided for @widget_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Widget'**
  String get widget_delete_title;

  /// No description provided for @widget_delete_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String widget_delete_msg(String name);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'CANCEL'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'DELETE'**
  String get delete;

  /// No description provided for @health_subtitle_current_weight.
  ///
  /// In en, this message translates to:
  /// **'Current weight'**
  String get health_subtitle_current_weight;

  /// No description provided for @health_ml_label.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get health_ml_label;

  /// No description provided for @health_subtitle_goal_ml.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} ml'**
  String health_subtitle_goal_ml(int goal);

  /// No description provided for @health_min_label.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get health_min_label;

  /// No description provided for @health_subtitle_goal_min.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} min'**
  String health_subtitle_goal_min(int goal);

  /// No description provided for @health_heart_resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get health_heart_resting;

  /// No description provided for @health_heart_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get health_heart_normal;

  /// No description provided for @health_heart_elevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get health_heart_elevated;

  /// No description provided for @health_heart_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get health_heart_high;

  /// No description provided for @health_subtitle_goal_hours.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} h'**
  String health_subtitle_goal_hours(String goal);

  /// No description provided for @health_subtitle_study_time.
  ///
  /// In en, this message translates to:
  /// **'Study Time'**
  String get health_subtitle_study_time;

  /// No description provided for @achievements.
  ///
  /// In en, this message translates to:
  /// **'Achievements'**
  String get achievements;

  /// No description provided for @health_log_food.
  ///
  /// In en, this message translates to:
  /// **'Log Food'**
  String get health_log_food;

  /// No description provided for @health_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get health_focus;

  /// No description provided for @health_subtitle_goal_steps.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} steps'**
  String health_subtitle_goal_steps(int goal);

  /// No description provided for @health_subtitle_health_first.
  ///
  /// In en, this message translates to:
  /// **'Health First'**
  String get health_subtitle_health_first;

  /// No description provided for @health_kcal_label.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get health_kcal_label;

  /// No description provided for @health_subtitle_todays_intake.
  ///
  /// In en, this message translates to:
  /// **'Today\'s intake'**
  String get health_subtitle_todays_intake;

  /// No description provided for @health_steps_label.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get health_steps_label;

  /// No description provided for @health_kg_label.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get health_kg_label;

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
  /// **'Username contains invalid characters'**
  String get err_username_invalid_char;

  /// No description provided for @btn_update_username.
  ///
  /// In en, this message translates to:
  /// **'Update Username'**
  String get btn_update_username;

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
  /// **'Create your own dynamic widget'**
  String get canvas_add_widget_desc;

  /// No description provided for @ranking.
  ///
  /// In en, this message translates to:
  /// **'Ranking'**
  String get ranking;

  /// No description provided for @relationships.
  ///
  /// In en, this message translates to:
  /// **'Relationships'**
  String get relationships;

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

  /// No description provided for @set_password.
  ///
  /// In en, this message translates to:
  /// **'Set Password'**
  String get set_password;

  /// No description provided for @msg_username_success.
  ///
  /// In en, this message translates to:
  /// **'Username updated successfully'**
  String get msg_username_success;

  /// No description provided for @err_username_failed.
  ///
  /// In en, this message translates to:
  /// **'Username update failed: {error}'**
  String err_username_failed(String error);

  /// No description provided for @change_username_title.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get change_username_title;

  /// No description provided for @unique_username_header.
  ///
  /// In en, this message translates to:
  /// **'Unique Username'**
  String get unique_username_header;

  /// No description provided for @username_description.
  ///
  /// In en, this message translates to:
  /// **'Choose a unique username so others can find you.'**
  String get username_description;

  /// No description provided for @username_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username_label;

  /// No description provided for @msg_no_local_password.
  ///
  /// In en, this message translates to:
  /// **'No local password set'**
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
  /// **'Please enter your current password'**
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
  /// **'Please enter a new password'**
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

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Your life, orchestrated.'**
  String get tagline;

  /// No description provided for @username_email_hint.
  ///
  /// In en, this message translates to:
  /// **'Username or Email'**
  String get username_email_hint;

  /// No description provided for @password_hint.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password_hint;

  /// No description provided for @go_to_gate.
  ///
  /// In en, this message translates to:
  /// **'ENTER GATE'**
  String get go_to_gate;

  /// No description provided for @secure_login.
  ///
  /// In en, this message translates to:
  /// **'SECURE'**
  String get secure_login;

  /// No description provided for @google_login.
  ///
  /// In en, this message translates to:
  /// **'GMAIL'**
  String get google_login;

  /// No description provided for @guest_access.
  ///
  /// In en, this message translates to:
  /// **'GUEST ACCESS'**
  String get guest_access;

  /// No description provided for @enroll_hub.
  ///
  /// In en, this message translates to:
  /// **'ENROLL'**
  String get enroll_hub;

  /// No description provided for @msg_secure_login_failed.
  ///
  /// In en, this message translates to:
  /// **'Secure login failed: {error}'**
  String msg_secure_login_failed(String error);

  /// No description provided for @msg_enter_credentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get msg_enter_credentials;

  /// No description provided for @analysis_user_title.
  ///
  /// In en, this message translates to:
  /// **'{name}\'s Analysis'**
  String analysis_user_title(String name);

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
  /// **'Your data is not synced yet.'**
  String get sync_desc;

  /// No description provided for @sync.
  ///
  /// In en, this message translates to:
  /// **'SYNC'**
  String get sync;

  /// No description provided for @percent_to_level.
  ///
  /// In en, this message translates to:
  /// **'{percent}% to Level {level}'**
  String percent_to_level(int percent, int level);

  /// No description provided for @progress_to_level.
  ///
  /// In en, this message translates to:
  /// **'Progress to Level {level}'**
  String progress_to_level(int level);

  /// No description provided for @total_xp.
  ///
  /// In en, this message translates to:
  /// **'Total XP: {xp}'**
  String total_xp(int xp);

  /// No description provided for @scoring_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get scoring_health;

  /// No description provided for @scoring_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get scoring_finance;

  /// No description provided for @scoring_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get scoring_social;

  /// No description provided for @scoring_career.
  ///
  /// In en, this message translates to:
  /// **'Career'**
  String get scoring_career;

  /// No description provided for @breakdown_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get breakdown_steps;

  /// No description provided for @breakdown_diet.
  ///
  /// In en, this message translates to:
  /// **'Diet'**
  String get breakdown_diet;

  /// No description provided for @breakdown_exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get breakdown_exercise;

  /// No description provided for @breakdown_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get breakdown_focus;

  /// No description provided for @breakdown_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get breakdown_water;

  /// No description provided for @breakdown_sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get breakdown_sleep;

  /// No description provided for @breakdown_contacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get breakdown_contacts;

  /// No description provided for @breakdown_affection.
  ///
  /// In en, this message translates to:
  /// **'Affection'**
  String get breakdown_affection;

  /// No description provided for @breakdown_quests.
  ///
  /// In en, this message translates to:
  /// **'Quests'**
  String get breakdown_quests;

  /// No description provided for @breakdown_accounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get breakdown_accounts;

  /// No description provided for @breakdown_assets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get breakdown_assets;

  /// No description provided for @breakdown_tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get breakdown_tasks;

  /// No description provided for @breakdown_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get breakdown_projects;

  /// No description provided for @breakdown_system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get breakdown_system;

  /// No description provided for @score_balance.
  ///
  /// In en, this message translates to:
  /// **'SCORE BALANCE'**
  String get score_balance;

  /// No description provided for @err_verification_failed.
  ///
  /// In en, this message translates to:
  /// **'Current password verification failed'**
  String get err_verification_failed;

  /// No description provided for @err_unexpected.
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred: {error}'**
  String err_unexpected(String error);

  /// No description provided for @msg_password_success.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get msg_password_success;

  /// No description provided for @msg_password_requirement.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password to proceed.'**
  String get msg_password_requirement;

  /// No description provided for @security_title.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security_title;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @personal_info_title.
  ///
  /// In en, this message translates to:
  /// **'Personal Info'**
  String get personal_info_title;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @personal_info_identification.
  ///
  /// In en, this message translates to:
  /// **'Identification'**
  String get personal_info_identification;

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
  /// **'Email'**
  String get email_label;

  /// No description provided for @phone_number_label.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number_label;

  /// No description provided for @personal_info_professional_matrix.
  ///
  /// In en, this message translates to:
  /// **'Professional Matrix'**
  String get personal_info_professional_matrix;

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

  /// No description provided for @personal_info_education_node.
  ///
  /// In en, this message translates to:
  /// **'Education Node'**
  String get personal_info_education_node;

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

  /// No description provided for @personal_info_location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get personal_info_location;

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

  /// No description provided for @personal_info_digital.
  ///
  /// In en, this message translates to:
  /// **'Digital Accounts'**
  String get personal_info_digital;

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

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @msg_err_not_authenticated.
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get msg_err_not_authenticated;

  /// No description provided for @msg_personal_info_saved.
  ///
  /// In en, this message translates to:
  /// **'Personal info saved'**
  String get msg_personal_info_saved;

  /// No description provided for @msg_err_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save changes: {error}'**
  String msg_err_save_failed(String error);

  /// No description provided for @msg_avatar_updated.
  ///
  /// In en, this message translates to:
  /// **'Avatar updated successfully'**
  String get msg_avatar_updated;

  /// No description provided for @msg_avatar_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Avatar update cancelled'**
  String get msg_avatar_cancelled;

  /// No description provided for @msg_err_upload_failed.
  ///
  /// In en, this message translates to:
  /// **'Upload failed: {error}'**
  String msg_err_upload_failed(String error);

  /// No description provided for @msg_cover_updated.
  ///
  /// In en, this message translates to:
  /// **'Cover photo updated successfully'**
  String get msg_cover_updated;

  /// No description provided for @msg_cover_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Cover photo update cancelled'**
  String get msg_cover_cancelled;

  /// No description provided for @change_cover.
  ///
  /// In en, this message translates to:
  /// **'Change Cover'**
  String get change_cover;

  /// No description provided for @social_share_msg.
  ///
  /// In en, this message translates to:
  /// **'Check out my progress on Ice Gate!'**
  String get social_share_msg;

  /// No description provided for @record_achievement.
  ///
  /// In en, this message translates to:
  /// **'Record Achievement'**
  String get record_achievement;

  /// No description provided for @update_achievement.
  ///
  /// In en, this message translates to:
  /// **'Update Achievement'**
  String get update_achievement;

  /// No description provided for @achievement_title_label.
  ///
  /// In en, this message translates to:
  /// **'Achievement Title'**
  String get achievement_title_label;

  /// No description provided for @system_exp_reward.
  ///
  /// In en, this message translates to:
  /// **'EXP Reward'**
  String get system_exp_reward;

  /// No description provided for @image_url.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get image_url;

  /// No description provided for @achievement_recorded.
  ///
  /// In en, this message translates to:
  /// **'Achievement recorded!'**
  String get achievement_recorded;

  /// No description provided for @achievement_updated.
  ///
  /// In en, this message translates to:
  /// **'Achievement updated!'**
  String get achievement_updated;

  /// No description provided for @system_error.
  ///
  /// In en, this message translates to:
  /// **'System Error: {error}'**
  String system_error(String error);

  /// No description provided for @record_feat.
  ///
  /// In en, this message translates to:
  /// **'Record Feat'**
  String get record_feat;

  /// No description provided for @update_feat.
  ///
  /// In en, this message translates to:
  /// **'Update Feat'**
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
  /// **'Register Agent'**
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
  /// **'Relationship Type'**
  String get relationship_type;

  /// No description provided for @create_link.
  ///
  /// In en, this message translates to:
  /// **'Create Link'**
  String get create_link;

  /// No description provided for @social_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Social Dashboard'**
  String get social_dashboard;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get social;

  /// No description provided for @social_rank_first.
  ///
  /// In en, this message translates to:
  /// **'1ST PLACE'**
  String get social_rank_first;

  /// No description provided for @social_rank_second.
  ///
  /// In en, this message translates to:
  /// **'2ND PLACE'**
  String get social_rank_second;

  /// No description provided for @social_rank_third.
  ///
  /// In en, this message translates to:
  /// **'3RD PLACE'**
  String get social_rank_third;

  /// No description provided for @no_data_global_board.
  ///
  /// In en, this message translates to:
  /// **'No global rankings yet'**
  String get no_data_global_board;

  /// No description provided for @current_rankings.
  ///
  /// In en, this message translates to:
  /// **'CURRENT RANKINGS'**
  String get current_rankings;

  /// No description provided for @updated_time_ago.
  ///
  /// In en, this message translates to:
  /// **'Updated {time} ago'**
  String updated_time_ago(String time);

  /// No description provided for @social_points_suffix.
  ///
  /// In en, this message translates to:
  /// **' pts'**
  String get social_points_suffix;

  /// No description provided for @social_tier_veteran.
  ///
  /// In en, this message translates to:
  /// **'Veteran Tier'**
  String get social_tier_veteran;

  /// No description provided for @social_empty_network.
  ///
  /// In en, this message translates to:
  /// **'Your network is empty'**
  String get social_empty_network;

  /// No description provided for @social_trust_level.
  ///
  /// In en, this message translates to:
  /// **'Trust Level'**
  String get social_trust_level;

  /// No description provided for @level.
  ///
  /// In en, this message translates to:
  /// **'Level {level}'**
  String level(int level);

  /// No description provided for @social_bond_strengthened.
  ///
  /// In en, this message translates to:
  /// **'Bond strengthened!'**
  String get social_bond_strengthened;

  /// No description provided for @social_options.
  ///
  /// In en, this message translates to:
  /// **'Social Options'**
  String get social_options;

  /// No description provided for @social_manage_title.
  ///
  /// In en, this message translates to:
  /// **'Manage Link'**
  String get social_manage_title;

  /// No description provided for @social_change_friend.
  ///
  /// In en, this message translates to:
  /// **'Set as Friend'**
  String get social_change_friend;

  /// No description provided for @social_change_dating.
  ///
  /// In en, this message translates to:
  /// **'Set as Dating'**
  String get social_change_dating;

  /// No description provided for @social_change_family.
  ///
  /// In en, this message translates to:
  /// **'Set as Family'**
  String get social_change_family;

  /// No description provided for @social_delete_bond.
  ///
  /// In en, this message translates to:
  /// **'Delete Bond'**
  String get social_delete_bond;

  /// No description provided for @social_no_achievements.
  ///
  /// In en, this message translates to:
  /// **'No achievements yet'**
  String get social_no_achievements;

  /// No description provided for @social_feat.
  ///
  /// In en, this message translates to:
  /// **'Feat'**
  String get social_feat;

  /// No description provided for @add_app_plugin.
  ///
  /// In en, this message translates to:
  /// **'Add App Plugin'**
  String get add_app_plugin;

  /// No description provided for @plugin_desc.
  ///
  /// In en, this message translates to:
  /// **'Add new features to your dashboard'**
  String get plugin_desc;

  /// No description provided for @homepage_four_life_elements.
  ///
  /// In en, this message translates to:
  /// **'LIFE ELEMENTS'**
  String get homepage_four_life_elements;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get done;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'EDIT'**
  String get edit;

  /// No description provided for @analysis.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get analysis;

  /// No description provided for @total_users.
  ///
  /// In en, this message translates to:
  /// **'Total Users'**
  String get total_users;

  /// No description provided for @mutual.
  ///
  /// In en, this message translates to:
  /// **'Mutual'**
  String get mutual;

  /// No description provided for @friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friends;

  /// No description provided for @projs.
  ///
  /// In en, this message translates to:
  /// **'Projs'**
  String get projs;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get tasks;

  /// No description provided for @homepage_plugin.
  ///
  /// In en, this message translates to:
  /// **'PLUGINS'**
  String get homepage_plugin;

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

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @kcal_consume.
  ///
  /// In en, this message translates to:
  /// **'Kcal Consumed'**
  String get kcal_consume;

  /// No description provided for @hr.
  ///
  /// In en, this message translates to:
  /// **'Heart Rate'**
  String get hr;

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

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get steps;

  /// No description provided for @sleep.
  ///
  /// In en, this message translates to:
  /// **'Sleep'**
  String get sleep;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @goal_target_evolution.
  ///
  /// In en, this message translates to:
  /// **'Goal Evolution'**
  String get goal_target_evolution;

  /// No description provided for @goal_mission.
  ///
  /// In en, this message translates to:
  /// **'MISSIONS'**
  String get goal_mission;

  /// No description provided for @goal_mission_desc.
  ///
  /// In en, this message translates to:
  /// **'Adjust daily targets to optimize life performance.'**
  String get goal_mission_desc;

  /// No description provided for @goal_step_target.
  ///
  /// In en, this message translates to:
  /// **'Step Target'**
  String get goal_step_target;

  /// No description provided for @goal_calorie_limit.
  ///
  /// In en, this message translates to:
  /// **'Calorie Limit'**
  String get goal_calorie_limit;

  /// No description provided for @goal_water_target.
  ///
  /// In en, this message translates to:
  /// **'Water Target'**
  String get goal_water_target;

  /// No description provided for @goal_focus_target.
  ///
  /// In en, this message translates to:
  /// **'Focus Target'**
  String get goal_focus_target;

  /// No description provided for @goal_exercise_target.
  ///
  /// In en, this message translates to:
  /// **'Exercise Target'**
  String get goal_exercise_target;

  /// No description provided for @goal_sleep_target.
  ///
  /// In en, this message translates to:
  /// **'Sleep Target'**
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

  /// No description provided for @rule_health_steps.
  ///
  /// In en, this message translates to:
  /// **'Earn points for every {steps} steps.'**
  String rule_health_steps(int steps);

  /// No description provided for @rule_health_calories.
  ///
  /// In en, this message translates to:
  /// **'Earn {calories} bonus points if you consume less than {limit} kcal.'**
  String rule_health_calories(int calories, int limit);

  /// No description provided for @rule_health_auto.
  ///
  /// In en, this message translates to:
  /// **'Health points are calculated automatically based on synced data.'**
  String get rule_health_auto;

  /// No description provided for @rule_career_project.
  ///
  /// In en, this message translates to:
  /// **'{points} points per completed project.'**
  String rule_career_project(int points);

  /// No description provided for @rule_career_task.
  ///
  /// In en, this message translates to:
  /// **'{points} points per completed task.'**
  String rule_career_task(int points);

  /// No description provided for @rule_career_bonus_5.
  ///
  /// In en, this message translates to:
  /// **'Bonus {bonus} points when 5 tasks in a project are completed.'**
  String rule_career_bonus_5(int bonus);

  /// No description provided for @rule_career_bonus_10.
  ///
  /// In en, this message translates to:
  /// **'Bonus {bonus} points for over 10 completed tasks in a project.'**
  String rule_career_bonus_10(int bonus);

  /// No description provided for @rule_career_bonus_doc.
  ///
  /// In en, this message translates to:
  /// **'Bonus {bonus} points for project with detailed documentation.'**
  String rule_career_bonus_doc(int bonus);

  /// No description provided for @rule_career_bonus_week.
  ///
  /// In en, this message translates to:
  /// **'Bonus {bonus} points for project completed within a week.'**
  String rule_career_bonus_week(int bonus);

  /// No description provided for @rule_finance_savings.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points for every \${milestone} saved.'**
  String rule_finance_savings(int points, int milestone);

  /// No description provided for @rule_finance_investment.
  ///
  /// In en, this message translates to:
  /// **'Earn {points} points for investments yielding over {threshold}% gain.'**
  String rule_finance_investment(int points, int threshold);

  /// No description provided for @rule_finance_auto.
  ///
  /// In en, this message translates to:
  /// **'Finance points update every 24 hours based on balance changes.'**
  String get rule_finance_auto;

  /// No description provided for @rule_social_contact.
  ///
  /// In en, this message translates to:
  /// **'{points} points for each new meaningful contact added.'**
  String rule_social_contact(int points);

  /// No description provided for @rule_social_affection.
  ///
  /// In en, this message translates to:
  /// **'{points} points per {unit} affection level reached.'**
  String rule_social_affection(int points, int unit);

  /// No description provided for @rule_social_maintain.
  ///
  /// In en, this message translates to:
  /// **'Maintain bonds to prevent point decay over time.'**
  String get rule_social_maintain;

  /// No description provided for @how_it_works.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get how_it_works;

  /// No description provided for @scoring_intro.
  ///
  /// In en, this message translates to:
  /// **'Our scoring system evaluates your daily performance across four key pillars. Points are rewarded based on consistency, milestones, and efficiency.'**
  String get scoring_intro;

  /// No description provided for @scoring_footer.
  ///
  /// In en, this message translates to:
  /// **'Scores are processed by the Life Orchestration Engine (LOE) every midnight UTC.'**
  String get scoring_footer;

  /// No description provided for @canvas_notification_center.
  ///
  /// In en, this message translates to:
  /// **'Notification Center'**
  String get canvas_notification_center;

  /// No description provided for @canvas_notification_desc.
  ///
  /// In en, this message translates to:
  /// **'Control and oversee all system notifications'**
  String get canvas_notification_desc;

  /// No description provided for @canvas_goal_center.
  ///
  /// In en, this message translates to:
  /// **'Goal Evolution'**
  String get canvas_goal_center;

  /// No description provided for @canvas_goal_desc.
  ///
  /// In en, this message translates to:
  /// **'Adjust tactical goal parameters'**
  String get canvas_goal_desc;

  /// No description provided for @gps_permissions_required.
  ///
  /// In en, this message translates to:
  /// **'GPS permissions required for tracking.'**
  String get gps_permissions_required;

  /// No description provided for @gps_title.
  ///
  /// In en, this message translates to:
  /// **'GPS TRACKING'**
  String get gps_title;

  /// No description provided for @gps_disconnect_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Disconnect device'**
  String get gps_disconnect_tooltip;

  /// No description provided for @gps_map_tab.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get gps_map_tab;

  /// No description provided for @gps_data_tab.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get gps_data_tab;

  /// No description provided for @gps_system_scan.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM SCAN'**
  String get gps_system_scan;

  /// No description provided for @gps_connect_receiver.
  ///
  /// In en, this message translates to:
  /// **'Connect GPS Receiver'**
  String get gps_connect_receiver;

  /// No description provided for @gps_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get gps_connected;

  /// No description provided for @gps_not_connected.
  ///
  /// In en, this message translates to:
  /// **'Not Connected'**
  String get gps_not_connected;

  /// No description provided for @gps_history.
  ///
  /// In en, this message translates to:
  /// **'Location History'**
  String get gps_history;

  /// No description provided for @gps_label_latitude.
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get gps_label_latitude;

  /// No description provided for @gps_label_longitude.
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get gps_label_longitude;

  /// No description provided for @gps_label_altitude.
  ///
  /// In en, this message translates to:
  /// **'Altitude'**
  String get gps_label_altitude;

  /// No description provided for @gps_label_speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get gps_label_speed;

  /// No description provided for @gps_label_heading.
  ///
  /// In en, this message translates to:
  /// **'Heading'**
  String get gps_label_heading;

  /// No description provided for @gps_label_accuracy.
  ///
  /// In en, this message translates to:
  /// **'Accuracy'**
  String get gps_label_accuracy;

  /// No description provided for @gps_label_time.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get gps_label_time;

  /// No description provided for @gps_waiting_signal.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS Signal'**
  String get gps_waiting_signal;

  /// No description provided for @gps_waiting_desc.
  ///
  /// In en, this message translates to:
  /// **'Ensure the receiver has a clear view of the sky.'**
  String get gps_waiting_desc;

  /// No description provided for @gps_disconnect_title.
  ///
  /// In en, this message translates to:
  /// **'Disconnect GPS?'**
  String get gps_disconnect_title;

  /// No description provided for @gps_disconnect_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to disconnect from the GPS receiver?'**
  String get gps_disconnect_msg;

  /// No description provided for @gps_permissions_denied.
  ///
  /// In en, this message translates to:
  /// **'GPS permissions denied.'**
  String get gps_permissions_denied;

  /// No description provided for @gps_status_tracking.
  ///
  /// In en, this message translates to:
  /// **'Tracking'**
  String get gps_status_tracking;

  /// No description provided for @gps_status_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get gps_status_paused;

  /// No description provided for @gps_btn_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get gps_btn_start;

  /// No description provided for @gps_btn_pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get gps_btn_pause;

  /// No description provided for @gps_btn_stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get gps_btn_stop;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @health_analysis_title.
  ///
  /// In en, this message translates to:
  /// **'Health Analysis'**
  String get health_analysis_title;

  /// No description provided for @health_no_data.
  ///
  /// In en, this message translates to:
  /// **'No health data available'**
  String get health_no_data;

  /// No description provided for @health_metabolism_active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get health_metabolism_active;

  /// No description provided for @health_metabolism_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get health_metabolism_normal;

  /// No description provided for @health_intensity_optimal.
  ///
  /// In en, this message translates to:
  /// **'Optimal'**
  String get health_intensity_optimal;

  /// No description provided for @health_analysis_performance.
  ///
  /// In en, this message translates to:
  /// **'PERFORMANCE ANALYSIS'**
  String get health_analysis_performance;

  /// No description provided for @health_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get health_efficiency;

  /// No description provided for @health_consistency.
  ///
  /// In en, this message translates to:
  /// **'Consistency'**
  String get health_consistency;

  /// No description provided for @health_consistency_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get health_consistency_high;

  /// No description provided for @health_consistency_medium.
  ///
  /// In en, this message translates to:
  /// **'Medium'**
  String get health_consistency_medium;

  /// No description provided for @health_consistency_low.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get health_consistency_low;

  /// No description provided for @health_metabolism.
  ///
  /// In en, this message translates to:
  /// **'Metabolism'**
  String get health_metabolism;

  /// No description provided for @health_intensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get health_intensity;

  /// No description provided for @health_water_log.
  ///
  /// In en, this message translates to:
  /// **'Water Log'**
  String get health_water_log;

  /// No description provided for @health_water_goal.
  ///
  /// In en, this message translates to:
  /// **'Daily Goal'**
  String get health_water_goal;

  /// No description provided for @health_water_points.
  ///
  /// In en, this message translates to:
  /// **'Points Earned'**
  String get health_water_points;

  /// No description provided for @health_water_left.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get health_water_left;

  /// No description provided for @health_stay_hydrated.
  ///
  /// In en, this message translates to:
  /// **'Stay hydrated today!'**
  String get health_stay_hydrated;

  /// No description provided for @health_custom_intake.
  ///
  /// In en, this message translates to:
  /// **'Custom Intake'**
  String get health_custom_intake;

  /// No description provided for @health_unit_ml.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get health_unit_ml;

  /// No description provided for @health_sleep_tracker.
  ///
  /// In en, this message translates to:
  /// **'Sleep Tracker'**
  String get health_sleep_tracker;

  /// No description provided for @health_last_24h_apple.
  ///
  /// In en, this message translates to:
  /// **'Last 24h via Apple Health'**
  String get health_last_24h_apple;

  /// No description provided for @health_last_session.
  ///
  /// In en, this message translates to:
  /// **'LAST SESSION'**
  String get health_last_session;

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

  /// No description provided for @health_no_sleep_records.
  ///
  /// In en, this message translates to:
  /// **'No sleep records yet'**
  String get health_no_sleep_records;

  /// No description provided for @health_log_sleep.
  ///
  /// In en, this message translates to:
  /// **'Log Sleep Session'**
  String get health_log_sleep;

  /// No description provided for @health_quality.
  ///
  /// In en, this message translates to:
  /// **'Sleep Quality'**
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
  /// **'Sleep session saved'**
  String get health_sleep_saved;

  /// No description provided for @health_activity_tracker.
  ///
  /// In en, this message translates to:
  /// **'Activity Tracker'**
  String get health_activity_tracker;

  /// No description provided for @health_syncing_data.
  ///
  /// In en, this message translates to:
  /// **'Syncing Health data...'**
  String get health_syncing_data;

  /// No description provided for @health_refresh_steps.
  ///
  /// In en, this message translates to:
  /// **'Refresh steps from HealthKit'**
  String get health_refresh_steps;

  /// No description provided for @health_steps_dashboard.
  ///
  /// In en, this message translates to:
  /// **'Steps Dashboard'**
  String get health_steps_dashboard;

  /// No description provided for @health_steps_taken.
  ///
  /// In en, this message translates to:
  /// **'TOTAL STEPS TAKEN'**
  String get health_steps_taken;

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
  /// **'Remaining Goal'**
  String get health_remaining;

  /// No description provided for @health_distance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get health_distance;

  /// No description provided for @health_active_time.
  ///
  /// In en, this message translates to:
  /// **'Active Time'**
  String get health_active_time;

  /// No description provided for @health_latest_apple.
  ///
  /// In en, this message translates to:
  /// **'LATEST FROM HEALTH'**
  String get health_latest_apple;

  /// No description provided for @health_realtime_sync.
  ///
  /// In en, this message translates to:
  /// **'Real-time sync from Watch'**
  String get health_realtime_sync;

  /// No description provided for @health_zone_resting.
  ///
  /// In en, this message translates to:
  /// **'Resting'**
  String get health_zone_resting;

  /// No description provided for @health_zone_normal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get health_zone_normal;

  /// No description provided for @health_zone_elevated.
  ///
  /// In en, this message translates to:
  /// **'Elevated'**
  String get health_zone_elevated;

  /// No description provided for @health_zone_high.
  ///
  /// In en, this message translates to:
  /// **'High'**
  String get health_zone_high;

  /// No description provided for @health_zone_very_high.
  ///
  /// In en, this message translates to:
  /// **'Very High'**
  String get health_zone_very_high;

  /// No description provided for @health_add_reading_desc.
  ///
  /// In en, this message translates to:
  /// **'Add a reading below to get started'**
  String get health_add_reading_desc;

  /// No description provided for @health_average.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get health_average;

  /// No description provided for @health_peak.
  ///
  /// In en, this message translates to:
  /// **'Peak'**
  String get health_peak;

  /// No description provided for @health_samples.
  ///
  /// In en, this message translates to:
  /// **'Samples'**
  String get health_samples;

  /// No description provided for @health_manual_entry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry'**
  String get health_manual_entry;

  /// No description provided for @health_enter_bpm.
  ///
  /// In en, this message translates to:
  /// **'Enter BPM'**
  String get health_enter_bpm;

  /// No description provided for @health_quick_entry.
  ///
  /// In en, this message translates to:
  /// **'Quick Entry'**
  String get health_quick_entry;

  /// No description provided for @health_exercise_analysis.
  ///
  /// In en, this message translates to:
  /// **'Exercise Analysis'**
  String get health_exercise_analysis;

  /// No description provided for @health_no_exercise_history.
  ///
  /// In en, this message translates to:
  /// **'No exercise history found'**
  String get health_no_exercise_history;

  /// No description provided for @health_weekly_minutes.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY MINUTES'**
  String get health_weekly_minutes;

  /// No description provided for @health_intensity_distribution.
  ///
  /// In en, this message translates to:
  /// **'Intensity Distribution'**
  String get health_intensity_distribution;

  /// No description provided for @health_type_distribution.
  ///
  /// In en, this message translates to:
  /// **'Type Distribution'**
  String get health_type_distribution;

  /// No description provided for @health_exercise_history.
  ///
  /// In en, this message translates to:
  /// **'Exercise History'**
  String get health_exercise_history;

  /// No description provided for @project_mark_done_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark as completed'**
  String get project_mark_done_tooltip;

  /// No description provided for @project_completed_msg.
  ///
  /// In en, this message translates to:
  /// **'Project completed! +{score} EXP'**
  String project_completed_msg(int score);

  /// No description provided for @project_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete project'**
  String get project_delete_tooltip;

  /// No description provided for @project_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Project'**
  String get project_delete_confirm_title;

  /// No description provided for @project_delete_confirm_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This action cannot be undone.'**
  String project_delete_confirm_msg(String name);

  /// No description provided for @project_deleted_msg.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get project_deleted_msg;

  /// No description provided for @project_complete_label.
  ///
  /// In en, this message translates to:
  /// **'COMPLETE'**
  String get project_complete_label;

  /// No description provided for @project_no_tasks.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet. Tap + to add one.'**
  String get project_no_tasks;

  /// No description provided for @project_notes_label.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get project_notes_label;

  /// No description provided for @project_no_notes.
  ///
  /// In en, this message translates to:
  /// **'No notes yet. Tap + to create one.'**
  String get project_no_notes;

  /// No description provided for @project_no_notes_list.
  ///
  /// In en, this message translates to:
  /// **'No notes found'**
  String get project_no_notes_list;

  /// No description provided for @project_finance_label.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get project_finance_label;

  /// No description provided for @project_no_finance.
  ///
  /// In en, this message translates to:
  /// **'No financial records linked to this project.'**
  String get project_no_finance;

  /// No description provided for @project_add_task_title.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get project_add_task_title;

  /// No description provided for @project_task_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get project_task_title_hint;

  /// No description provided for @project_add_investment_title.
  ///
  /// In en, this message translates to:
  /// **'Add Investment'**
  String get project_add_investment_title;

  /// No description provided for @project_add_investment_desc.
  ///
  /// In en, this message translates to:
  /// **'Record an expense or investment for this project.'**
  String get project_add_investment_desc;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @description_optional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get description_optional;

  /// No description provided for @project_investment_default_desc.
  ///
  /// In en, this message translates to:
  /// **'Project investment'**
  String get project_investment_default_desc;

  /// No description provided for @project_add_investment_btn.
  ///
  /// In en, this message translates to:
  /// **'Add Investment'**
  String get project_add_investment_btn;

  /// No description provided for @project_new_note_title.
  ///
  /// In en, this message translates to:
  /// **'New Note'**
  String get project_new_note_title;

  /// No description provided for @project_last_edited_msg.
  ///
  /// In en, this message translates to:
  /// **'Last edited {date}'**
  String project_last_edited_msg(String date);

  /// No description provided for @project_note_untitled.
  ///
  /// In en, this message translates to:
  /// **'Untitled'**
  String get project_note_untitled;

  /// No description provided for @project_unknown_date.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get project_unknown_date;

  /// No description provided for @project_delete_note_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Note'**
  String get project_delete_note_title;

  /// No description provided for @project_delete_note_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this note?'**
  String get project_delete_note_msg;

  /// No description provided for @project_note_no_content.
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get project_note_no_content;

  /// No description provided for @calorie_tracker.
  ///
  /// In en, this message translates to:
  /// **'Calorie Tracker'**
  String get calorie_tracker;

  /// No description provided for @net_calories.
  ///
  /// In en, this message translates to:
  /// **'NET CALORIES'**
  String get net_calories;

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

  /// No description provided for @goal_kcal.
  ///
  /// In en, this message translates to:
  /// **'Goal: {goal} kcal'**
  String goal_kcal(int goal);

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

  /// No description provided for @health_log_exercise.
  ///
  /// In en, this message translates to:
  /// **'Log Exercise'**
  String get health_log_exercise;

  /// No description provided for @health_calories_burned_label.
  ///
  /// In en, this message translates to:
  /// **'Calories Burned'**
  String get health_calories_burned_label;

  /// No description provided for @added_food_msg.
  ///
  /// In en, this message translates to:
  /// **'Added {name} ({calories} kcal)'**
  String added_food_msg(String name, int calories);

  /// No description provided for @lidar_ios_only.
  ///
  /// In en, this message translates to:
  /// **'LiDAR scanning is only available on iOS Pro devices.'**
  String get lidar_ios_only;

  /// No description provided for @lidar_completed.
  ///
  /// In en, this message translates to:
  /// **'LiDAR scan completed!'**
  String get lidar_completed;

  /// No description provided for @health_quick_add_exercise.
  ///
  /// In en, this message translates to:
  /// **'Quick Add Exercise'**
  String get health_quick_add_exercise;

  /// No description provided for @health_walking_30min.
  ///
  /// In en, this message translates to:
  /// **'Walking (30 min)'**
  String get health_walking_30min;

  /// No description provided for @health_running_30min.
  ///
  /// In en, this message translates to:
  /// **'Running (30 min)'**
  String get health_running_30min;

  /// No description provided for @health_cycling_30min.
  ///
  /// In en, this message translates to:
  /// **'Cycling (30 min)'**
  String get health_cycling_30min;

  /// No description provided for @health_swimming_30min.
  ///
  /// In en, this message translates to:
  /// **'Swimming (30 min)'**
  String get health_swimming_30min;

  /// No description provided for @health_yoga_30min.
  ///
  /// In en, this message translates to:
  /// **'Yoga (30 min)'**
  String get health_yoga_30min;

  /// No description provided for @added_calories_burned.
  ///
  /// In en, this message translates to:
  /// **'Added {calories} kcal burned'**
  String added_calories_burned(int calories);

  /// No description provided for @exercise_tracker.
  ///
  /// In en, this message translates to:
  /// **'Exercise Tracker'**
  String get exercise_tracker;

  /// No description provided for @daily_routines.
  ///
  /// In en, this message translates to:
  /// **'Daily Routines'**
  String get daily_routines;

  /// No description provided for @activity_history.
  ///
  /// In en, this message translates to:
  /// **'Activity History'**
  String get activity_history;

  /// No description provided for @no_activities_recorded.
  ///
  /// In en, this message translates to:
  /// **'No activities recorded yet.'**
  String get no_activities_recorded;

  /// No description provided for @custom_activity_title.
  ///
  /// In en, this message translates to:
  /// **'CUSTOM ACTIVITY'**
  String get custom_activity_title;

  /// No description provided for @activity_type_label.
  ///
  /// In en, this message translates to:
  /// **'Activity Type (e.g. Gym)'**
  String get activity_type_label;

  /// No description provided for @duration_min_label.
  ///
  /// In en, this message translates to:
  /// **'Duration (min)'**
  String get duration_min_label;

  /// No description provided for @intensity_label.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get intensity_label;

  /// No description provided for @log_activity_btn.
  ///
  /// In en, this message translates to:
  /// **'LOG ACTIVITY'**
  String get log_activity_btn;

  /// No description provided for @app_settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get app_settings_title;

  /// No description provided for @account_section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_section;

  /// No description provided for @preferences_section.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences_section;

  /// No description provided for @about_support_section.
  ///
  /// In en, this message translates to:
  /// **'About & Support'**
  String get about_support_section;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @edit_profile_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Profile details & identification'**
  String get edit_profile_subtitle;

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
  /// **'Active'**
  String get notifications_active;

  /// No description provided for @notifications_paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get notifications_paused;

  /// No description provided for @change_language.
  ///
  /// In en, this message translates to:
  /// **'Change Language'**
  String get change_language;

  /// No description provided for @manual.
  ///
  /// In en, this message translates to:
  /// **'User Manual'**
  String get manual;

  /// No description provided for @version.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// No description provided for @reset_database_title.
  ///
  /// In en, this message translates to:
  /// **'Reset Database'**
  String get reset_database_title;

  /// No description provided for @reset_database_msg.
  ///
  /// In en, this message translates to:
  /// **'Warning: This will delete all your local data. This action cannot be undone.'**
  String get reset_database_msg;

  /// No description provided for @btn_reset_all_data.
  ///
  /// In en, this message translates to:
  /// **'RESET ALL DATA'**
  String get btn_reset_all_data;

  /// No description provided for @msg_database_reset_success.
  ///
  /// In en, this message translates to:
  /// **'Database reset successfully'**
  String get msg_database_reset_success;

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

  /// No description provided for @change_username.
  ///
  /// In en, this message translates to:
  /// **'Change Username'**
  String get change_username;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @notification_manager_title.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION HUB'**
  String get notification_manager_title;

  /// No description provided for @notification_hunter_hub.
  ///
  /// In en, this message translates to:
  /// **'Hunter Hub'**
  String get notification_hunter_hub;

  /// No description provided for @notification_tab_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get notification_tab_active;

  /// No description provided for @notification_tab_reminders.
  ///
  /// In en, this message translates to:
  /// **'REMINDERS'**
  String get notification_tab_reminders;

  /// No description provided for @notification_tab_wisdom.
  ///
  /// In en, this message translates to:
  /// **'WISDOM'**
  String get notification_tab_wisdom;

  /// No description provided for @notification_ai_no_data.
  ///
  /// In en, this message translates to:
  /// **'No tactical data available.'**
  String get notification_ai_no_data;

  /// No description provided for @notification_ai_advice.
  ///
  /// In en, this message translates to:
  /// **'TACTICAL ADVICE'**
  String get notification_ai_advice;

  /// No description provided for @notification_ai_waiting.
  ///
  /// In en, this message translates to:
  /// **'Gathering intelligence...'**
  String get notification_ai_waiting;

  /// No description provided for @notification_ai_analysis.
  ///
  /// In en, this message translates to:
  /// **'AI ANALYSIS'**
  String get notification_ai_analysis;

  /// No description provided for @notification_daily_quest.
  ///
  /// In en, this message translates to:
  /// **'DAILY QUEST'**
  String get notification_daily_quest;

  /// No description provided for @notification_quest_completed_snack.
  ///
  /// In en, this message translates to:
  /// **'Quest completed: {title} (+{exp} EXP)'**
  String notification_quest_completed_snack(String title, int exp);

  /// No description provided for @notification_personal_reminders.
  ///
  /// In en, this message translates to:
  /// **'Personal Reminders'**
  String get notification_personal_reminders;

  /// No description provided for @notification_add_new.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW'**
  String get notification_add_new;

  /// No description provided for @notification_no_reminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders set.'**
  String get notification_no_reminders;

  /// No description provided for @notification_disabled_desc.
  ///
  /// In en, this message translates to:
  /// **'System notifications are currently disabled.'**
  String get notification_disabled_desc;

  /// No description provided for @notification_wisdom_board.
  ///
  /// In en, this message translates to:
  /// **'Wisdom Board'**
  String get notification_wisdom_board;

  /// No description provided for @notification_add_quote.
  ///
  /// In en, this message translates to:
  /// **'ADD QUOTE'**
  String get notification_add_quote;

  /// No description provided for @notification_quote_empty.
  ///
  /// In en, this message translates to:
  /// **'The board of wisdom is empty.'**
  String get notification_quote_empty;

  /// No description provided for @notification_add_wisdom_title.
  ///
  /// In en, this message translates to:
  /// **'Add Wisdom'**
  String get notification_add_wisdom_title;

  /// No description provided for @notification_wisdom_content.
  ///
  /// In en, this message translates to:
  /// **'Wisdom Content'**
  String get notification_wisdom_content;

  /// No description provided for @notification_wisdom_author.
  ///
  /// In en, this message translates to:
  /// **'Author'**
  String get notification_wisdom_author;

  /// No description provided for @notification_inbox_title.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATION CENTER'**
  String get notification_inbox_title;

  /// No description provided for @notification_mission_history.
  ///
  /// In en, this message translates to:
  /// **'Mission History'**
  String get notification_mission_history;

  /// No description provided for @notification_mission_success.
  ///
  /// In en, this message translates to:
  /// **'MISSION SUCCESS'**
  String get notification_mission_success;

  /// No description provided for @notification_focus_complete.
  ///
  /// In en, this message translates to:
  /// **'FOCUS COMPLETE'**
  String get notification_focus_complete;

  /// No description provided for @notification_reminder.
  ///
  /// In en, this message translates to:
  /// **'REMINDER'**
  String get notification_reminder;

  /// No description provided for @notification_no_logs.
  ///
  /// In en, this message translates to:
  /// **'LOGS ARE EMPTY'**
  String get notification_no_logs;

  /// No description provided for @notification_empty_desc.
  ///
  /// In en, this message translates to:
  /// **'All system events will be stored here.'**
  String get notification_empty_desc;

  /// No description provided for @finance_add_transaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get finance_add_transaction;

  /// No description provided for @finance_add_type.
  ///
  /// In en, this message translates to:
  /// **'Add {type}'**
  String finance_add_type(String type);

  /// No description provided for @finance_label_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get finance_label_save;

  /// No description provided for @finance_label_spend.
  ///
  /// In en, this message translates to:
  /// **'Spend'**
  String get finance_label_spend;

  /// No description provided for @finance_label_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get finance_label_income;

  /// No description provided for @finance_tooltip_add_savings.
  ///
  /// In en, this message translates to:
  /// **'Add Savings'**
  String get finance_tooltip_add_savings;

  /// No description provided for @finance_tooltip_add_expense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get finance_tooltip_add_expense;

  /// No description provided for @finance_tooltip_add_income.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get finance_tooltip_add_income;

  /// No description provided for @finance_type_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get finance_type_expense;

  /// No description provided for @finance_type_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get finance_type_income;

  /// No description provided for @finance_type_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get finance_type_savings;

  /// No description provided for @finance_label_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get finance_label_amount;

  /// No description provided for @finance_label_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get finance_label_category;

  /// No description provided for @finance_label_description_optional.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get finance_label_description_optional;

  /// No description provided for @finance_btn_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get finance_btn_add;

  /// No description provided for @finance_total_net_worth.
  ///
  /// In en, this message translates to:
  /// **'TOTAL NET WORTH'**
  String get finance_total_net_worth;

  /// No description provided for @finance_monthly_breakdown.
  ///
  /// In en, this message translates to:
  /// **'{month} Breakdown'**
  String finance_monthly_breakdown(String month);

  /// No description provided for @finance_recent_transactions.
  ///
  /// In en, this message translates to:
  /// **'Recent Transactions'**
  String get finance_recent_transactions;

  /// No description provided for @finance_no_transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get finance_no_transactions;

  /// No description provided for @finance_tap_to_add.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first transaction'**
  String get finance_tap_to_add;

  /// No description provided for @finance_total_savings.
  ///
  /// In en, this message translates to:
  /// **'Total Savings'**
  String get finance_total_savings;

  /// No description provided for @finance_month_spending.
  ///
  /// In en, this message translates to:
  /// **'{month} Spending'**
  String finance_month_spending(String month);

  /// No description provided for @finance_month_income.
  ///
  /// In en, this message translates to:
  /// **'{month} Income'**
  String finance_month_income(String month);

  /// No description provided for @finance_see_all.
  ///
  /// In en, this message translates to:
  /// **'SEE ALL'**
  String get finance_see_all;

  /// No description provided for @finance_cat_food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get finance_cat_food;

  /// No description provided for @finance_cat_coffee.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get finance_cat_coffee;

  /// No description provided for @finance_cat_transport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get finance_cat_transport;

  /// No description provided for @finance_cat_software.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get finance_cat_software;

  /// No description provided for @finance_cat_shopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get finance_cat_shopping;

  /// No description provided for @finance_cat_bills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get finance_cat_bills;

  /// No description provided for @finance_cat_rent.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get finance_cat_rent;

  /// No description provided for @finance_cat_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'Subscriptions'**
  String get finance_cat_subscriptions;

  /// No description provided for @finance_cat_entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get finance_cat_entertainment;

  /// No description provided for @finance_cat_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get finance_cat_health;

  /// No description provided for @finance_cat_education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get finance_cat_education;

  /// No description provided for @finance_cat_investing.
  ///
  /// In en, this message translates to:
  /// **'Investing'**
  String get finance_cat_investing;

  /// No description provided for @finance_cat_general.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get finance_cat_general;

  /// No description provided for @finance_cat_salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get finance_cat_salary;

  /// No description provided for @finance_cat_freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get finance_cat_freelance;

  /// No description provided for @finance_cat_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get finance_cat_investment;

  /// No description provided for @finance_cat_gift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get finance_cat_gift;

  /// No description provided for @finance_cat_bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get finance_cat_bonus;

  /// No description provided for @finance_cat_emergency.
  ///
  /// In en, this message translates to:
  /// **'Emergency'**
  String get finance_cat_emergency;

  /// No description provided for @finance_cat_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get finance_cat_goal;

  /// No description provided for @finance_cat_retirement.
  ///
  /// In en, this message translates to:
  /// **'Retirement'**
  String get finance_cat_retirement;

  /// No description provided for @finance_cat_crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get finance_cat_crypto;

  /// No description provided for @finance_cat_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get finance_cat_stock;

  /// No description provided for @finance_cat_real_estate.
  ///
  /// In en, this message translates to:
  /// **'Real Estate'**
  String get finance_cat_real_estate;

  /// No description provided for @finance_power_points.
  ///
  /// In en, this message translates to:
  /// **'FINANCE POWER'**
  String get finance_power_points;

  /// No description provided for @finance_goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get finance_goal;

  /// No description provided for @finance_efficiency.
  ///
  /// In en, this message translates to:
  /// **'Efficiency'**
  String get finance_efficiency;

  /// No description provided for @finance_savings_rate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get finance_savings_rate;

  /// No description provided for @finance_points_desc.
  ///
  /// In en, this message translates to:
  /// **'Points earned from net worth'**
  String get finance_points_desc;

  /// No description provided for @ssh_new_session.
  ///
  /// In en, this message translates to:
  /// **'New SSH Session'**
  String get ssh_new_session;

  /// No description provided for @ssh_host_label.
  ///
  /// In en, this message translates to:
  /// **'Host IP or Domain'**
  String get ssh_host_label;

  /// No description provided for @ssh_port_label.
  ///
  /// In en, this message translates to:
  /// **'Port'**
  String get ssh_port_label;

  /// No description provided for @ssh_user_label.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get ssh_user_label;

  /// No description provided for @ssh_pass_label.
  ///
  /// In en, this message translates to:
  /// **'Password or Key'**
  String get ssh_pass_label;

  /// No description provided for @ssh_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get ssh_connect;

  /// No description provided for @ssh_ask_ai.
  ///
  /// In en, this message translates to:
  /// **'Ask AI'**
  String get ssh_ask_ai;

  /// No description provided for @ssh_ask_ai_desc.
  ///
  /// In en, this message translates to:
  /// **'Describe what you want to achieve...'**
  String get ssh_ask_ai_desc;

  /// No description provided for @ssh_generate.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get ssh_generate;

  /// No description provided for @ssh_type_command.
  ///
  /// In en, this message translates to:
  /// **'Type a command...'**
  String get ssh_type_command;

  /// No description provided for @ssh_disconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get ssh_disconnect;

  /// No description provided for @ssh_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get ssh_search_hint;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @social_notes.
  ///
  /// In en, this message translates to:
  /// **'Social Notes'**
  String get social_notes;

  /// No description provided for @btn_send_feedback.
  ///
  /// In en, this message translates to:
  /// **'Send Feedback'**
  String get btn_send_feedback;

  /// No description provided for @feedback_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Report issues or suggest features'**
  String get feedback_subtitle;
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
