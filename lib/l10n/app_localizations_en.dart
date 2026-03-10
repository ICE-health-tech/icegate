// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get helloWorld => 'Hello World!';

  @override
  String get homepage_four_life_elements => '4 Life Elements';

  @override
  String get homepage_plugin => 'Plugin';

  @override
  String get record_achievement => 'RECORD ACHIEVEMENT';

  @override
  String get update_achievement => 'UPDATE ACHIEVEMENT';

  @override
  String get achievement_title_label =>
      'Achievement Title (e.g. Swinging in 2h)';

  @override
  String get system_exp_reward => 'System EXP Reward';

  @override
  String get image_url => 'Image URL';

  @override
  String get cancel => 'CANCEL';

  @override
  String get achievement_recorded => 'ACHIEVEMENT RECORDED IN SYSTEM';

  @override
  String get achievement_updated => 'ACHIEVEMENT UPDATED';

  @override
  String system_error(String error) {
    return 'SYSTEM ERROR: $error';
  }

  @override
  String get record_feat => 'RECORD FEAT';

  @override
  String get update_feat => 'UPDATE FEAT';

  @override
  String get import_from_contacts => 'Import from Contacts';

  @override
  String get add_manually => 'Add Manually';

  @override
  String get register_agent => 'REGISTER AGENT';

  @override
  String get first_name => 'First Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get relationship_type => 'RELATIONSHIP TYPE';

  @override
  String get create_link => 'CREATE LINK';

  @override
  String get ranking => 'RANKING';

  @override
  String get relationships => 'RELATIONSHIPS';

  @override
  String get achievements => 'ACHIEVEMENTS';

  @override
  String get current_rankings => 'Current Rankings';

  @override
  String updated_time_ago(String time) {
    return 'UPDATED $time AGO';
  }

  @override
  String get no_data_global_board => 'No data in the Global Supremacy Board.';

  @override
  String get calorie_tracker => 'Calorie Tracker';

  @override
  String get nutrition_dashboard => 'Nutrition Dashboard';

  @override
  String get net_calories => 'Net Calories';

  @override
  String goal_kcal(int goal) {
    return 'Goal: $goal kcal';
  }

  @override
  String get under_goal => 'Under Goal';

  @override
  String get on_track => 'On Track';

  @override
  String get over_goal => 'Over Goal';

  @override
  String percent_of_daily_goal(String percent) {
    return '$percent% of daily goal';
  }

  @override
  String get consumed => 'Consumed';

  @override
  String get burned => 'Burned';

  @override
  String get remaining => 'Remaining';

  @override
  String get total_burn => 'Total Burn';

  @override
  String get add_food => 'Add Food';

  @override
  String get lidar_scan => 'LiDAR Scan';

  @override
  String get log_exercise => 'Log Exercise';

  @override
  String get calories_burned_label => 'Calories burned';

  @override
  String get quick_add_exercise => 'Quick Add Exercise';

  @override
  String added_food_msg(String name, int cal) {
    return 'Added $name ($cal kcal)';
  }

  @override
  String get lidar_ios_only =>
      'LiDAR scanning is only available on iOS devices.';

  @override
  String get lidar_completed =>
      'LiDAR scan completed! Processing volume data...';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String progress_to_level(int level) {
    return 'Progress to Level $level';
  }

  @override
  String get analysis => 'Analysis';

  @override
  String get health => 'Health';

  @override
  String get finance => 'Finance';

  @override
  String get social => 'Social';

  @override
  String get projects => 'Projects';

  @override
  String get steps => 'Steps';

  @override
  String get kcal_consume => 'Kcal Consume';

  @override
  String get sleep => 'Sleep';

  @override
  String get hr => 'HR';

  @override
  String get balance => 'Balance';

  @override
  String get spent => 'Spent';

  @override
  String get income => 'Income';

  @override
  String get savings => 'Savings';

  @override
  String get total_users => 'Total Users';

  @override
  String get friends => 'Friends';

  @override
  String get mutual => 'Mutual';

  @override
  String get username => 'Username';

  @override
  String get done => 'Done';

  @override
  String get active => 'Active';

  @override
  String get projs => 'Projs';

  @override
  String get tasks => 'Tasks';

  @override
  String get edit => 'Edit';

  @override
  String get add_app_plugin => 'Add App Plugin';

  @override
  String get plugin_desc => 'Choose a plugin to extend your dashboard';

  @override
  String get add => 'Add';

  @override
  String get canvas_add_custom_widget => 'Add Custom Widget';

  @override
  String get canvas_add_widget_desc =>
      'Enter the name and URL of the website you want to add.';

  @override
  String get canvas_notification_center => 'Notification Center';

  @override
  String get canvas_notification_desc => 'Manage your alerts and focus history';

  @override
  String get canvas_goal_center => 'Goal Center';

  @override
  String get canvas_goal_desc => 'Track your daily health evolution';

  @override
  String get goal_target_evolution => 'TARGET EVOLUTION';

  @override
  String get goal_mission => 'MISSION';

  @override
  String get goal_mission_desc =>
      'Configure your physical parameters to ensure optimal AI synchronization and field performance.';

  @override
  String get goal_step_target => 'STEP TARGET';

  @override
  String get goal_calorie_limit => 'CALORIE LIMIT';

  @override
  String get goal_water_target => 'WATER TARGET';

  @override
  String get goal_focus_target => 'FOCUS TARGET';

  @override
  String get goal_exercise_target => 'EXERCISE TARGET';

  @override
  String get goal_sleep_target => 'SLEEP TARGET';

  @override
  String get unit_kcal => 'kcal';

  @override
  String get unit_ml => 'ml';

  @override
  String get unit_min => 'min';

  @override
  String get unit_hours => 'hours';

  @override
  String get scoring_rules_title => 'Scoring Rules';

  @override
  String get scoring_health => '🏃 Health';

  @override
  String get scoring_career => '💼 Career (Projects)';

  @override
  String get scoring_finance => '💰 Finance';

  @override
  String get scoring_social => '❤️ Social';

  @override
  String rule_health_steps(int steps) {
    return '1 Point per $steps steps walked';
  }

  @override
  String rule_health_calories(int points, int limit) {
    return '$points Points for staying under $limit kcal/day';
  }

  @override
  String get rule_health_auto =>
      'Points automatically update when health metrics are recorded';

  @override
  String rule_career_project(int points) {
    return '$points Base Points for completing a project';
  }

  @override
  String rule_career_task(int points) {
    return '$points Points for each task completed';
  }

  @override
  String rule_career_bonus_5(int points) {
    return '$points Bonus Points for projects with 5+ tasks';
  }

  @override
  String rule_career_bonus_10(int points) {
    return '$points Bonus Points for projects with 10+ tasks';
  }

  @override
  String rule_career_bonus_doc(int points) {
    return '$points Bonus Points for having 3+ research notes';
  }

  @override
  String rule_career_bonus_week(int points) {
    return '$points Bonus Points for projects active for 7+ days';
  }

  @override
  String rule_finance_savings(int points, int milestone) {
    return '$points Points for every \$$milestone saved (Net Worth)';
  }

  @override
  String rule_finance_investment(int points, int threshold) {
    return '$points Points for every $threshold% investment return';
  }

  @override
  String get rule_finance_auto =>
      'Points update as account balances and asset values change';

  @override
  String rule_social_contact(int points) {
    return '$points Points for each unique contact added';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points Points for every $unit affection points earned';
  }

  @override
  String get rule_social_maintain =>
      'Maintain relationships to keep your social score high';

  @override
  String get how_it_works => 'How it works';

  @override
  String get scoring_intro =>
      'The Ice Gate scoring system measures your growth across four key life elements. Your Global Level is calculated from the sum of these scores. Maintain a high score to unlock legendary status.';

  @override
  String get scoring_footer =>
      'Balance your physical, social, financial, and workspace growth to become a Legend.';

  @override
  String get personal_info_title => 'Personal Information';

  @override
  String get personal_info_identification => 'Identification';

  @override
  String get personal_info_professional_matrix => 'Professional Matrix';

  @override
  String get personal_info_education_node => 'Education Node';

  @override
  String get personal_info_location => 'Location';

  @override
  String get personal_info_digital => 'Digital';

  @override
  String get logout => 'Logout';

  @override
  String get save => 'Save';

  @override
  String get bio => 'Bio';

  @override
  String get first_name_label => 'First Name';

  @override
  String get last_name_label => 'Last Name';

  @override
  String get email_label => 'eMail';

  @override
  String get phone_number_label => 'Phone Number';

  @override
  String get role_label => 'Role';

  @override
  String get organization_label => 'Organization';

  @override
  String get institution_label => 'Institution';

  @override
  String get education_level_label => 'Education Level';

  @override
  String get country_label => 'Country';

  @override
  String get city_label => 'City';

  @override
  String get github_label => 'GitHub';

  @override
  String get linkedin_label => 'LinkedIn';

  @override
  String get personal_web_label => 'Personal Web';

  @override
  String get msg_personal_info_saved =>
      'Personal information saved successfully';

  @override
  String msg_err_save_failed(String error) {
    return 'Failed to save changes: $error';
  }

  @override
  String get msg_avatar_updated => 'Avatar updated!';

  @override
  String get msg_avatar_cancelled => 'Avatar upload cancelled';

  @override
  String get msg_cover_updated => 'Cover updated!';

  @override
  String get msg_cover_cancelled => 'Cover upload cancelled';

  @override
  String msg_err_upload_failed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get msg_err_not_authenticated => 'Error: Not authenticated';

  @override
  String get change_cover => 'Change Cover';

  @override
  String get change_avatar => 'Change Avatar';

  @override
  String analysis_user_title(String name) {
    return '$name\'s Analysis';
  }

  @override
  String get tagline => 'LIFE GATEWAY';

  @override
  String get username_email_hint => 'USERNAME / eMAIL';

  @override
  String get password_hint => 'PASSWORD';

  @override
  String get go_to_gate => 'GO TO GATE';

  @override
  String get secure_login => 'SECURE LOGIN';

  @override
  String get google_login => 'GOOGLE';

  @override
  String get guest_access => 'GUEST ACCESS';

  @override
  String get enroll_hub => 'ENROLL HUB';

  @override
  String get msg_enter_credentials => 'Please enter username and password';

  @override
  String msg_secure_login_failed(String error) {
    return 'Secure Login failed: $error';
  }

  @override
  String get performance => 'Performance';

  @override
  String get overview => 'Overview';

  @override
  String get guest_mode => 'Guest Mode';

  @override
  String get sync_desc => 'Synchronize to save your progress.';

  @override
  String get sync => 'Sync';

  @override
  String get score_balance => 'SCORE BALANCE';

  @override
  String percent_to_level(int percent, int level) {
    return '$percent% to level $level';
  }

  @override
  String total_xp(int xp) {
    return 'Total XP: $xp';
  }

  @override
  String get breakdown_steps => 'STEPS';

  @override
  String get breakdown_diet => 'DIET';

  @override
  String get breakdown_exercise => 'EXERCISE';

  @override
  String get breakdown_focus => 'FOCUS';

  @override
  String get breakdown_water => 'WATER';

  @override
  String get breakdown_sleep => 'SLEEP';

  @override
  String get breakdown_contacts => 'CONTACTS';

  @override
  String get breakdown_affection => 'AFFECTION';

  @override
  String get breakdown_quests => 'QUESTS';

  @override
  String get breakdown_accounts => 'ACCOUNTS';

  @override
  String get breakdown_assets => 'ASSETS';

  @override
  String get breakdown_tasks => 'TASKS';

  @override
  String get breakdown_projects => 'PROJECTS';

  @override
  String get breakdown_system => 'SYSTEM';

  @override
  String get app_settings_title => 'App Settings';

  @override
  String get guest_user => 'Guest';

  @override
  String get msg_sign_in_to_sync => 'Sign in to sync your data';

  @override
  String get member_status => 'Member';

  @override
  String get account_section => 'Account';

  @override
  String get edit_profile => 'Edit Profile';

  @override
  String get edit_profile_subtitle => 'Update your name and photo';

  @override
  String get change_password => 'Change Password';

  @override
  String get change_username => 'Change Username';

  @override
  String get preferences_section => 'Preferences';

  @override
  String get change_theme => 'Change Theme';

  @override
  String get system_notifications => 'System Notifications';

  @override
  String get notifications_active => 'Notifications are active';

  @override
  String get notifications_paused => 'Notifications are paused';

  @override
  String get about_support_section => 'About & Support';

  @override
  String get manual => 'Manual';

  @override
  String get version => 'Version';

  @override
  String get reset_database_title => 'Reset Database?';

  @override
  String get reset_database_msg =>
      'This will permanently delete all your local data including focus sessions, health logs, and settings. This action cannot be undone.';

  @override
  String get msg_database_reset_success => 'Database reset successful.';

  @override
  String get btn_reset_all_data => 'RESET ALL DATA';

  @override
  String get security_title => 'Security';

  @override
  String get set_password => 'Set Password';

  @override
  String get msg_password_requirement =>
      'Your new password must be at least 6 characters long and different from previous ones.';

  @override
  String get msg_no_local_password =>
      'You haven\'t set a local password yet. Create one to enable email/password login.';

  @override
  String get current_password_label => 'Current Password';

  @override
  String get enter_current_password_hint => 'Enter current password';

  @override
  String get err_enter_current_password => 'Please enter current password';

  @override
  String get new_password_label => 'New Password';

  @override
  String get enter_new_password_hint => 'Enter new password';

  @override
  String get err_enter_password => 'Please enter a password';

  @override
  String get err_password_length => 'Password must be at least 6 characters';

  @override
  String get confirm_password_label => 'Confirm Password';

  @override
  String get confirm_new_password_hint => 'Confirm new password';

  @override
  String get err_confirm_password => 'Please confirm your password';

  @override
  String get err_passwords_not_match => 'Passwords do not match';

  @override
  String get btn_update_password => 'Update Password';

  @override
  String get msg_password_success => 'Password set successfully!';

  @override
  String err_unexpected(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get err_verification_failed =>
      'Current password verification failed. Please check your credentials.';

  @override
  String get change_username_title => 'Change Username';

  @override
  String get unique_username_header => 'Your Unique Username';

  @override
  String get username_description =>
      'Your username is used to log in and identify you within the application. It must be at least 3 characters long.';

  @override
  String get username_label => 'Username';

  @override
  String get enter_new_username_hint => 'Enter new username';

  @override
  String get err_enter_username => 'Please enter a username';

  @override
  String get err_username_length => 'Username must be at least 3 characters';

  @override
  String get err_username_invalid_char => 'Username cannot contain \"@\"';

  @override
  String get btn_update_username => 'UPDATE USERNAME';

  @override
  String get msg_username_success => 'Username updated successfully!';

  @override
  String err_username_failed(String error) {
    return 'Failed to update username: $error';
  }

  @override
  String added_calories_burned(int cal) {
    return 'Added $cal kcal burned';
  }

  @override
  String get change_language => 'Change Language';

  @override
  String get health_insights => 'Insights';

  @override
  String get health_log_water => 'Log Water';

  @override
  String get health_log_food => 'Log Food';

  @override
  String get health_exercise => 'Exercise';

  @override
  String get health_focus => 'Focus';

  @override
  String get health_log_exercise => 'Log Exercise';

  @override
  String get health_calories_burned_label => 'Calories burned';

  @override
  String get health_quick_add_exercise => 'Quick Add Exercise';

  @override
  String get health_walking_30min => 'Walking 30min';

  @override
  String get health_running_30min => 'Running 30min';

  @override
  String get health_cycling_30min => 'Cycling 30min';

  @override
  String get health_swimming_30min => 'Swimming 30min';

  @override
  String get health_yoga_30min => 'Yoga 30min';

  @override
  String get health_water_log => 'Water Log';

  @override
  String get health_water_goal => 'GOAL';

  @override
  String get health_water_points => 'POINTS';

  @override
  String get health_water_left => 'LEFT';

  @override
  String health_water_of_ml(int goal) {
    return 'OF $goal ML';
  }

  @override
  String get health_stay_hydrated => 'STAY HYDRATED';

  @override
  String get health_custom_intake => 'CUSTOM INTAKE';

  @override
  String get health_unit_ml => 'ML';

  @override
  String get health_sleep_tracker => 'Sleep Tracker';

  @override
  String get health_healthkit_sleep => 'HealthKit Sleep';

  @override
  String get health_last_24h_apple => 'Last 24h from Apple Health';

  @override
  String get health_last_session => 'Last Session';

  @override
  String get health_no_sleep_records => 'No sleep sessions recorded yet.';

  @override
  String get health_log_sleep => 'Log Sleep';

  @override
  String get health_bedtime => 'Bedtime';

  @override
  String get health_wake_up => 'Wake up';

  @override
  String get health_quality => 'Quality';

  @override
  String get health_save_session => 'Save Session';

  @override
  String get health_history => 'History';

  @override
  String get health_sleep_saved => 'Sleep session saved!';

  @override
  String health_hrs(String hours) {
    return '$hours hrs';
  }

  @override
  String health_quality_stars(String stars) {
    return 'Quality: $stars';
  }

  @override
  String get health_activity_tracker => 'Activity Tracker';

  @override
  String get health_syncing_data => 'Syncing health data...';

  @override
  String get health_refresh_steps => 'Refresh Steps';

  @override
  String get health_steps_dashboard => 'Steps Dashboard';

  @override
  String get health_steps_taken => 'Steps Taken';

  @override
  String health_percent_completed(String percent) {
    return '$percent% Completed';
  }

  @override
  String get health_daily_statistics => 'Daily Statistics';

  @override
  String get health_lifetime_total => 'Lifetime Total';

  @override
  String get health_remaining => 'Remaining';

  @override
  String get health_distance => 'Distance';

  @override
  String get health_calories => 'Calories';

  @override
  String get health_active_time => 'Active Time';

  @override
  String get health_metrics_water => 'Water';

  @override
  String get health_metrics_exercise => 'Exercise';

  @override
  String get health_metrics_focus => 'Focus';

  @override
  String get health_metrics_distance => 'Distance';

  @override
  String get health_metrics_calories => 'Calories';

  @override
  String get health_metrics_active_time => 'Active Time';

  @override
  String get health_metrics_steps => 'Steps';

  @override
  String get health_metrics_heart_rate => 'Heart Rate';

  @override
  String get health_metrics_sleep => 'Sleep';

  @override
  String get health_metrics_calories_consumed => 'Calories Consumed';

  @override
  String get health_metrics_calories_burned => 'Calories Burned';

  @override
  String get health_metrics_net_calories => 'Net Calories';

  @override
  String get health_metrics_weight => 'Weight';

  @override
  String health_metrics_detail_coming_soon(String name) {
    return 'Detail page for $name coming soon!';
  }

  @override
  String get health_subtitle_todays_intake => 'Today\'s intake';

  @override
  String health_subtitle_goal_steps(int goal) {
    return 'Goal: $goal';
  }

  @override
  String get health_subtitle_current_weight => 'Current weight';

  @override
  String health_subtitle_goal_ml(int goal) {
    return 'Goal: $goal ml';
  }

  @override
  String health_subtitle_goal_min(int goal) {
    return 'Goal: $goal min';
  }

  @override
  String health_subtitle_goal_hours(String goal) {
    return 'Goal: $goal hours';
  }

  @override
  String get health_subtitle_study_time => 'Study Time';

  @override
  String get health_subtitle_health_first => 'Health first';

  @override
  String get health_heart_resting => 'Resting';

  @override
  String get health_heart_normal => 'Normal';

  @override
  String get health_heart_elevated => 'Elevated';

  @override
  String get health_heart_high => 'High';
}
