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
  String get app_title => 'Ice Gate';

  @override
  String get home_welcome => 'Welcome back';

  @override
  String get health_title => 'Health & Fitness';

  @override
  String get health_steps => 'Steps';

  @override
  String get health_sleep => 'Sleep';

  @override
  String get health_heart_rate => 'Heart Rate';

  @override
  String get health_water => 'Water';

  @override
  String get health_weight => 'Weight';

  @override
  String get health_calories => 'Calories';

  @override
  String get health_activity => 'Activity';

  @override
  String get health_goal => 'Goal';

  @override
  String get health_avg => 'Average';

  @override
  String get health_max => 'Max';

  @override
  String get health_min => 'Min';

  @override
  String get health_last_7_days => 'Last 7 Days';

  @override
  String get health_last_30_days => 'Last 30 Days';

  @override
  String get health_sync_title => 'Sync Data';

  @override
  String get health_sync_msg => 'Syncing health data...';

  @override
  String get health_sync_success => 'Health data synced!';

  @override
  String get health_sync_failed => 'Sync failed. Please try again.';

  @override
  String get health_update_weight => 'Update Weight';

  @override
  String get health_log_water => 'Log Water';

  @override
  String get health_daily_goal_reached => 'You\'ve reached your daily goal!';

  @override
  String get health_almost_there => 'Almost there! Just a little more.';

  @override
  String get health_keep_moving => 'Keep moving to reach your goal.';

  @override
  String get health_good_morning => 'Good Morning';

  @override
  String get health_good_afternoon => 'Good Afternoon';

  @override
  String get health_good_evening => 'Good Evening';

  @override
  String get health_good_night => 'Good Night';

  @override
  String get health_bpm => 'BPM';

  @override
  String get health_kcal => 'kcal';

  @override
  String get health_meters => 'm';

  @override
  String get health_kilometers => 'km';

  @override
  String get health_steps_unit => 'steps';

  @override
  String get health_hours => 'hours';

  @override
  String get health_minutes => 'minutes';

  @override
  String get health_ml => 'ml';

  @override
  String get health_kg => 'kg';

  @override
  String get health_lb => 'lb';

  @override
  String get health_exercise => 'Exercise';

  @override
  String get health_intensity_low => 'Low';

  @override
  String get health_intensity_moderate => 'Moderate';

  @override
  String get health_intensity_high => 'High';

  @override
  String get health_intensity_extreme => 'Extreme';

  @override
  String get health_activity_balance => 'ACTIVITY BALANCE';

  @override
  String get health_balance_moving_much =>
      'You\'re moving a lot! Great step count.';

  @override
  String get health_balance_optimal =>
      'Your exercise distribution looks optimal today.';

  @override
  String get health_weekly_trends => 'WEEKLY TRENDS';

  @override
  String get health_avg_steps => 'Avg Steps';

  @override
  String get health_avg_sleep => 'Avg Sleep';

  @override
  String get health_avg_hr => 'Avg HR';

  @override
  String get health_insights_title => 'INSIGHTS';

  @override
  String get health_insights => 'Insights';

  @override
  String get health_insight_above_avg => 'Above average';

  @override
  String get health_insight_keep_pushing => 'Keep pushing';

  @override
  String get health_insight_activity_higher =>
      'Your activity is higher than your 7-day average.';

  @override
  String health_insight_activity_lower(int steps) {
    return 'Try to take a walk to reach your daily average of $steps steps.';
  }

  @override
  String get health_insight_goal_reached =>
      'Goal reached! You\'re very active today.';

  @override
  String health_insight_goal_percent(String percent) {
    return 'You\'ve completed $percent% of your daily goal.';
  }

  @override
  String get health_hydration_title => 'Hydration';

  @override
  String get health_hydration_track_msg =>
      'You\'re on track with your water intake goals!';

  @override
  String get health_bpm_label => 'bpm';

  @override
  String get health_hours_label => 'hours';

  @override
  String get project_title_label => 'Title';

  @override
  String get notification_reminder_new => 'New Reminder';

  @override
  String get notification_reminder_edit => 'Edit Reminder';

  @override
  String get notification_repeat_label => 'Repeat';

  @override
  String get notification_date_label => 'Date';

  @override
  String get notification_time_label => 'Time';

  @override
  String get notification_save_reminder => 'Save Reminder';

  @override
  String get notification_update_reminder => 'Update';

  @override
  String get notification_category_general => 'General';

  @override
  String get notification_category_daily => 'Daily';

  @override
  String get notification_category_health => 'Health';

  @override
  String get notification_category_finance => 'Finance';

  @override
  String get notification_category_social => 'Social';

  @override
  String get notification_category_projects => 'Projects';

  @override
  String get notification_priority_low => 'Low';

  @override
  String get notification_priority_normal => 'Normal';

  @override
  String get notification_priority_high => 'High';

  @override
  String get notification_priority_urgent => 'Urgent';

  @override
  String get notification_freq_once => 'Once';

  @override
  String get notification_freq_daily => 'Daily';

  @override
  String get notification_freq_weekly => 'Weekly';

  @override
  String get notification_enter_title_snack => 'Please enter a title';

  @override
  String get nutri_trends_title => 'Nutrition Trends';

  @override
  String get nutri_weekly_avg => 'Weekly Avg';

  @override
  String get nutri_insights_title => 'Nutri Insights';

  @override
  String get nutri_advice_low_protein =>
      'Your protein intake is a bit low this week. Try adding eggs or lean meat.';

  @override
  String get nutri_advice_high_cal =>
      'You\'ve exceeded your calorie limit recently. Consider lighter meals tomorrow.';

  @override
  String get nutri_advice_good_job =>
      'Great job! You\'re maintaining a good balance and staying on track.';

  @override
  String get nutri_advice_more_water =>
      'Don\'t forget to drink water. Hydration helps with metabolism.';

  @override
  String get nutri_weekly_calories_chart => 'Weekly Calories';

  @override
  String get nutri_macro_distribution => 'Macro Distribution';

  @override
  String get nutrition_dashboard => 'Nutrition Dashboard';

  @override
  String get nutri_total => 'Total';

  @override
  String get nutri_protein => 'Protein';

  @override
  String get nutri_carbs => 'Carbs';

  @override
  String get nutri_fat => 'Fat';

  @override
  String get nutri_today => 'Today';

  @override
  String get nutri_no_meals => 'No meals logged yet';

  @override
  String get nutri_kcal => 'kcal';

  @override
  String get nutri_cal => 'cal';

  @override
  String get todays_gains => 'Today\'s Gains';

  @override
  String get health_metrics_steps => 'Steps';

  @override
  String get health_metrics_heart_rate => 'Heart Rate';

  @override
  String get health_metrics_sleep => 'Sleep';

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
  String get health_metrics_calories_burned => 'Burned';

  @override
  String get health_metrics_weight => 'Weight';

  @override
  String get health_metrics_net_calories => 'Net Cal';

  @override
  String get health_metrics_calories_consumed => 'Consumed';

  @override
  String health_metrics_detail_coming_soon(String name) {
    return 'Detail page for $name coming soon!';
  }

  @override
  String get widget_delete_title => 'Delete Widget';

  @override
  String widget_delete_msg(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get cancel => 'CANCEL';

  @override
  String get delete => 'DELETE';

  @override
  String get health_subtitle_current_weight => 'Current weight';

  @override
  String get health_ml_label => 'ml';

  @override
  String health_subtitle_goal_ml(int goal) {
    return 'Goal: $goal ml';
  }

  @override
  String get health_min_label => 'min';

  @override
  String health_subtitle_goal_min(int goal) {
    return 'Goal: $goal min';
  }

  @override
  String get health_heart_resting => 'Resting';

  @override
  String get health_heart_normal => 'Normal';

  @override
  String get health_heart_elevated => 'Elevated';

  @override
  String get health_heart_high => 'High';

  @override
  String health_subtitle_goal_hours(String goal) {
    return 'Goal: $goal h';
  }

  @override
  String get health_subtitle_study_time => 'Study Time';

  @override
  String get achievements => 'Achievements';

  @override
  String get health_log_food => 'Log Food';

  @override
  String get health_focus => 'Focus';

  @override
  String health_subtitle_goal_steps(int goal) {
    return 'Goal: $goal steps';
  }

  @override
  String get health_subtitle_health_first => 'Health First';

  @override
  String get health_kcal_label => 'kcal';

  @override
  String get health_subtitle_todays_intake => 'Today\'s intake';

  @override
  String get health_steps_label => 'steps';

  @override
  String get health_kg_label => 'kg';

  @override
  String get enter_new_username_hint => 'Enter new username';

  @override
  String get err_enter_username => 'Please enter a username';

  @override
  String get err_username_length => 'Username must be at least 3 characters';

  @override
  String get err_username_invalid_char =>
      'Username contains invalid characters';

  @override
  String get btn_update_username => 'Update Username';

  @override
  String get add => 'Add';

  @override
  String get canvas_add_custom_widget => 'Add Custom Widget';

  @override
  String get canvas_add_widget_desc => 'Create your own dynamic widget';

  @override
  String get ranking => 'Ranking';

  @override
  String get relationships => 'Relationships';

  @override
  String get err_confirm_password => 'Please confirm your password';

  @override
  String get err_passwords_not_match => 'Passwords do not match';

  @override
  String get btn_update_password => 'Update Password';

  @override
  String get set_password => 'Set Password';

  @override
  String get msg_username_success => 'Username updated successfully';

  @override
  String err_username_failed(String error) {
    return 'Username update failed: $error';
  }

  @override
  String get change_username_title => 'Change Username';

  @override
  String get unique_username_header => 'Unique Username';

  @override
  String get username_description =>
      'Choose a unique username so others can find you.';

  @override
  String get username_label => 'Username';

  @override
  String get msg_no_local_password => 'No local password set';

  @override
  String get current_password_label => 'Current Password';

  @override
  String get enter_current_password_hint => 'Enter current password';

  @override
  String get err_enter_current_password => 'Please enter your current password';

  @override
  String get new_password_label => 'New Password';

  @override
  String get enter_new_password_hint => 'Enter new password';

  @override
  String get err_enter_password => 'Please enter a new password';

  @override
  String get err_password_length => 'Password must be at least 6 characters';

  @override
  String get confirm_password_label => 'Confirm Password';

  @override
  String get confirm_new_password_hint => 'Confirm new password';

  @override
  String get tagline => 'Your life, orchestrated.';

  @override
  String get username_email_hint => 'Username or Email';

  @override
  String get password_hint => 'Password';

  @override
  String get go_to_gate => 'ENTER GATE';

  @override
  String get secure_login => 'SECURE';

  @override
  String get google_login => 'GMAIL';

  @override
  String get guest_access => 'GUEST ACCESS';

  @override
  String get enroll_hub => 'ENROLL';

  @override
  String msg_secure_login_failed(String error) {
    return 'Secure login failed: $error';
  }

  @override
  String get msg_enter_credentials => 'Please enter your credentials';

  @override
  String analysis_user_title(String name) {
    return '$name\'s Analysis';
  }

  @override
  String get performance => 'Performance';

  @override
  String get overview => 'Overview';

  @override
  String get guest_mode => 'Guest Mode';

  @override
  String get sync_desc => 'Your data is not synced yet.';

  @override
  String get sync => 'SYNC';

  @override
  String percent_to_level(int percent, int level) {
    return '$percent% to Level $level';
  }

  @override
  String progress_to_level(int level) {
    return 'Progress to Level $level';
  }

  @override
  String total_xp(int xp) {
    return 'Total XP: $xp';
  }

  @override
  String get scoring_health => 'Health';

  @override
  String get scoring_finance => 'Finance';

  @override
  String get scoring_social => 'Social';

  @override
  String get scoring_career => 'Career';

  @override
  String get breakdown_steps => 'Steps';

  @override
  String get breakdown_diet => 'Diet';

  @override
  String get breakdown_exercise => 'Exercise';

  @override
  String get breakdown_focus => 'Focus';

  @override
  String get breakdown_water => 'Water';

  @override
  String get breakdown_sleep => 'Sleep';

  @override
  String get breakdown_contacts => 'Contacts';

  @override
  String get breakdown_affection => 'Affection';

  @override
  String get breakdown_quests => 'Quests';

  @override
  String get breakdown_accounts => 'Accounts';

  @override
  String get breakdown_assets => 'Assets';

  @override
  String get breakdown_tasks => 'Tasks';

  @override
  String get breakdown_projects => 'Projects';

  @override
  String get breakdown_system => 'System';

  @override
  String get score_balance => 'SCORE BALANCE';

  @override
  String get err_verification_failed => 'Current password verification failed';

  @override
  String err_unexpected(String error) {
    return 'An unexpected error occurred: $error';
  }

  @override
  String get msg_password_success => 'Password updated successfully';

  @override
  String get msg_password_requirement =>
      'Please enter your current password to proceed.';

  @override
  String get security_title => 'Security';

  @override
  String get change_password => 'Change Password';

  @override
  String get personal_info_title => 'Personal Info';

  @override
  String get bio => 'Bio';

  @override
  String get personal_info_identification => 'Identification';

  @override
  String get first_name_label => 'First Name';

  @override
  String get last_name_label => 'Last Name';

  @override
  String get email_label => 'Email';

  @override
  String get phone_number_label => 'Phone Number';

  @override
  String get personal_info_professional_matrix => 'Professional Matrix';

  @override
  String get role_label => 'Role';

  @override
  String get organization_label => 'Organization';

  @override
  String get personal_info_education_node => 'Education Node';

  @override
  String get institution_label => 'Institution';

  @override
  String get education_level_label => 'Education Level';

  @override
  String get personal_info_location => 'Location';

  @override
  String get country_label => 'Country';

  @override
  String get city_label => 'City';

  @override
  String get personal_info_digital => 'Digital Accounts';

  @override
  String get github_label => 'GitHub';

  @override
  String get linkedin_label => 'LinkedIn';

  @override
  String get personal_web_label => 'Personal Web';

  @override
  String get logout => 'Logout';

  @override
  String get msg_err_not_authenticated => 'Not authenticated';

  @override
  String get msg_personal_info_saved => 'Personal info saved';

  @override
  String msg_err_save_failed(String error) {
    return 'Failed to save changes: $error';
  }

  @override
  String get msg_avatar_updated => 'Avatar updated successfully';

  @override
  String get msg_avatar_cancelled => 'Avatar update cancelled';

  @override
  String msg_err_upload_failed(String error) {
    return 'Upload failed: $error';
  }

  @override
  String get msg_cover_updated => 'Cover photo updated successfully';

  @override
  String get msg_cover_cancelled => 'Cover photo update cancelled';

  @override
  String get change_cover => 'Change Cover';

  @override
  String get social_share_msg => 'Check out my progress on Ice Gate!';

  @override
  String get record_achievement => 'Record Achievement';

  @override
  String get update_achievement => 'Update Achievement';

  @override
  String get achievement_title_label => 'Achievement Title';

  @override
  String get system_exp_reward => 'EXP Reward';

  @override
  String get image_url => 'Image URL';

  @override
  String get achievement_recorded => 'Achievement recorded!';

  @override
  String get achievement_updated => 'Achievement updated!';

  @override
  String system_error(String error) {
    return 'System Error: $error';
  }

  @override
  String get record_feat => 'Record Feat';

  @override
  String get update_feat => 'Update Feat';

  @override
  String get import_from_contacts => 'Import from Contacts';

  @override
  String get add_manually => 'Add Manually';

  @override
  String get register_agent => 'Register Agent';

  @override
  String get first_name => 'First Name';

  @override
  String get last_name => 'Last Name';

  @override
  String get relationship_type => 'Relationship Type';

  @override
  String get create_link => 'Create Link';

  @override
  String get social_dashboard => 'Social Dashboard';

  @override
  String get social => 'Social';

  @override
  String get social_rank_first => '1ST PLACE';

  @override
  String get social_rank_second => '2ND PLACE';

  @override
  String get social_rank_third => '3RD PLACE';

  @override
  String get no_data_global_board => 'No global rankings yet';

  @override
  String get current_rankings => 'CURRENT RANKINGS';

  @override
  String updated_time_ago(String time) {
    return 'Updated $time ago';
  }

  @override
  String get social_points_suffix => ' pts';

  @override
  String get social_tier_veteran => 'Veteran Tier';

  @override
  String get social_empty_network => 'Your network is empty';

  @override
  String get social_trust_level => 'Trust Level';

  @override
  String level(int level) {
    return 'Level $level';
  }

  @override
  String get social_bond_strengthened => 'Bond strengthened!';

  @override
  String get social_options => 'Social Options';

  @override
  String get social_manage_title => 'Manage Link';

  @override
  String get social_change_friend => 'Set as Friend';

  @override
  String get social_change_dating => 'Set as Dating';

  @override
  String get social_change_family => 'Set as Family';

  @override
  String get social_delete_bond => 'Delete Bond';

  @override
  String get social_no_achievements => 'No achievements yet';

  @override
  String get social_feat => 'Feat';

  @override
  String get add_app_plugin => 'Add App Plugin';

  @override
  String get plugin_desc => 'Add new features to your dashboard';

  @override
  String get homepage_four_life_elements => 'LIFE ELEMENTS';

  @override
  String get done => 'DONE';

  @override
  String get edit => 'EDIT';

  @override
  String get analysis => 'Analysis';

  @override
  String get total_users => 'Total Users';

  @override
  String get mutual => 'Mutual';

  @override
  String get friends => 'Friends';

  @override
  String get projs => 'Projs';

  @override
  String get active => 'Active';

  @override
  String get tasks => 'Tasks';

  @override
  String get homepage_plugin => 'PLUGINS';

  @override
  String get health => 'Health';

  @override
  String get finance => 'Finance';

  @override
  String get projects => 'Projects';

  @override
  String get kcal_consume => 'Kcal Consumed';

  @override
  String get hr => 'Heart Rate';

  @override
  String get spent => 'Spent';

  @override
  String get income => 'Income';

  @override
  String get savings => 'Savings';

  @override
  String get balance => 'Balance';

  @override
  String get steps => 'Steps';

  @override
  String get sleep => 'Sleep';

  @override
  String get username => 'Username';

  @override
  String get goal_target_evolution => 'Goal Evolution';

  @override
  String get goal_mission => 'MISSIONS';

  @override
  String get goal_mission_desc =>
      'Adjust daily targets to optimize life performance.';

  @override
  String get goal_step_target => 'Step Target';

  @override
  String get goal_calorie_limit => 'Calorie Limit';

  @override
  String get goal_water_target => 'Water Target';

  @override
  String get goal_focus_target => 'Focus Target';

  @override
  String get goal_exercise_target => 'Exercise Target';

  @override
  String get goal_sleep_target => 'Sleep Target';

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
  String rule_health_steps(int steps) {
    return 'Earn points for every $steps steps.';
  }

  @override
  String rule_health_calories(int calories, int limit) {
    return 'Earn $calories bonus points if you consume less than $limit kcal.';
  }

  @override
  String get rule_health_auto =>
      'Health points are calculated automatically based on synced data.';

  @override
  String rule_career_project(int points) {
    return '$points points per completed project.';
  }

  @override
  String rule_career_task(int points) {
    return '$points points per completed task.';
  }

  @override
  String rule_career_bonus_5(int bonus) {
    return 'Bonus $bonus points when 5 tasks in a project are completed.';
  }

  @override
  String rule_career_bonus_10(int bonus) {
    return 'Bonus $bonus points for over 10 completed tasks in a project.';
  }

  @override
  String rule_career_bonus_doc(int bonus) {
    return 'Bonus $bonus points for project with detailed documentation.';
  }

  @override
  String rule_career_bonus_week(int bonus) {
    return 'Bonus $bonus points for project completed within a week.';
  }

  @override
  String rule_finance_savings(int points, int milestone) {
    return 'Earn $points points for every \$$milestone saved.';
  }

  @override
  String rule_finance_investment(int points, int threshold) {
    return 'Earn $points points for investments yielding over $threshold% gain.';
  }

  @override
  String get rule_finance_auto =>
      'Finance points update every 24 hours based on balance changes.';

  @override
  String rule_social_contact(int points) {
    return '$points points for each new meaningful contact added.';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points points per $unit affection level reached.';
  }

  @override
  String get rule_social_maintain =>
      'Maintain bonds to prevent point decay over time.';

  @override
  String get how_it_works => 'How it works';

  @override
  String get scoring_intro =>
      'Our scoring system evaluates your daily performance across four key pillars. Points are rewarded based on consistency, milestones, and efficiency.';

  @override
  String get scoring_footer =>
      'Scores are processed by the Life Orchestration Engine (LOE) every midnight UTC.';

  @override
  String get canvas_notification_center => 'Notification Center';

  @override
  String get canvas_notification_desc =>
      'Control and oversee all system notifications';

  @override
  String get canvas_goal_center => 'Goal Evolution';

  @override
  String get canvas_goal_desc => 'Adjust tactical goal parameters';

  @override
  String get gps_permissions_required =>
      'GPS permissions required for tracking.';

  @override
  String get gps_title => 'GPS TRACKING';

  @override
  String get gps_disconnect_tooltip => 'Disconnect device';

  @override
  String get gps_map_tab => 'Map';

  @override
  String get gps_data_tab => 'Data';

  @override
  String get gps_system_scan => 'SYSTEM SCAN';

  @override
  String get gps_connect_receiver => 'Connect GPS Receiver';

  @override
  String get gps_connected => 'Connected';

  @override
  String get gps_not_connected => 'Not Connected';

  @override
  String get gps_history => 'Location History';

  @override
  String get gps_label_latitude => 'Latitude';

  @override
  String get gps_label_longitude => 'Longitude';

  @override
  String get gps_label_altitude => 'Altitude';

  @override
  String get gps_label_speed => 'Speed';

  @override
  String get gps_label_heading => 'Heading';

  @override
  String get gps_label_accuracy => 'Accuracy';

  @override
  String get gps_label_time => 'Time';

  @override
  String get gps_waiting_signal => 'Waiting for GPS Signal';

  @override
  String get gps_waiting_desc =>
      'Ensure the receiver has a clear view of the sky.';

  @override
  String get gps_disconnect_title => 'Disconnect GPS?';

  @override
  String get gps_disconnect_msg =>
      'Are you sure you want to disconnect from the GPS receiver?';

  @override
  String get gps_permissions_denied => 'GPS permissions denied.';

  @override
  String get gps_status_tracking => 'Tracking';

  @override
  String get gps_status_paused => 'Paused';

  @override
  String get gps_btn_start => 'Start';

  @override
  String get gps_btn_pause => 'Pause';

  @override
  String get gps_btn_stop => 'Stop';

  @override
  String get close => 'Close';

  @override
  String get health_analysis_title => 'Health Analysis';

  @override
  String get health_no_data => 'No health data available';

  @override
  String get health_metabolism_active => 'Active';

  @override
  String get health_metabolism_normal => 'Normal';

  @override
  String get health_intensity_optimal => 'Optimal';

  @override
  String get health_analysis_performance => 'PERFORMANCE ANALYSIS';

  @override
  String get health_efficiency => 'Efficiency';

  @override
  String get health_consistency => 'Consistency';

  @override
  String get health_consistency_high => 'High';

  @override
  String get health_consistency_medium => 'Medium';

  @override
  String get health_consistency_low => 'Low';

  @override
  String get health_metabolism => 'Metabolism';

  @override
  String get health_intensity => 'Intensity';

  @override
  String get health_water_log => 'Water Log';

  @override
  String get health_water_goal => 'Daily Goal';

  @override
  String get health_water_points => 'Points Earned';

  @override
  String get health_water_left => 'Remaining';

  @override
  String get health_stay_hydrated => 'Stay hydrated today!';

  @override
  String get health_custom_intake => 'Custom Intake';

  @override
  String get health_unit_ml => 'ml';

  @override
  String get health_sleep_tracker => 'Sleep Tracker';

  @override
  String get health_last_24h_apple => 'Last 24h via Apple Health';

  @override
  String get health_last_session => 'LAST SESSION';

  @override
  String health_hrs(String hours) {
    return '$hours hrs';
  }

  @override
  String health_quality_stars(String stars) {
    return 'Quality: $stars';
  }

  @override
  String get health_no_sleep_records => 'No sleep records yet';

  @override
  String get health_log_sleep => 'Log Sleep Session';

  @override
  String get health_quality => 'Sleep Quality';

  @override
  String get health_save_session => 'Save Session';

  @override
  String get health_history => 'History';

  @override
  String get health_sleep_saved => 'Sleep session saved';

  @override
  String get health_activity_tracker => 'Activity Tracker';

  @override
  String get health_syncing_data => 'Syncing Health data...';

  @override
  String get health_refresh_steps => 'Refresh steps from HealthKit';

  @override
  String get health_steps_dashboard => 'Steps Dashboard';

  @override
  String get health_steps_taken => 'TOTAL STEPS TAKEN';

  @override
  String get health_daily_statistics => 'Daily Statistics';

  @override
  String get health_lifetime_total => 'Lifetime Total';

  @override
  String get health_remaining => 'Remaining Goal';

  @override
  String get health_distance => 'Distance';

  @override
  String get health_active_time => 'Active Time';

  @override
  String get health_latest_apple => 'LATEST FROM HEALTH';

  @override
  String get health_realtime_sync => 'Real-time sync from Watch';

  @override
  String get health_zone_resting => 'Resting';

  @override
  String get health_zone_normal => 'Normal';

  @override
  String get health_zone_elevated => 'Elevated';

  @override
  String get health_zone_high => 'High';

  @override
  String get health_zone_very_high => 'Very High';

  @override
  String get health_add_reading_desc => 'Add a reading below to get started';

  @override
  String get health_average => 'Average';

  @override
  String get health_peak => 'Peak';

  @override
  String get health_samples => 'Samples';

  @override
  String get health_manual_entry => 'Manual Entry';

  @override
  String get health_enter_bpm => 'Enter BPM';

  @override
  String get health_quick_entry => 'Quick Entry';

  @override
  String get health_exercise_analysis => 'Exercise Analysis';

  @override
  String get health_no_exercise_history => 'No exercise history found';

  @override
  String get health_weekly_minutes => 'WEEKLY MINUTES';

  @override
  String get health_intensity_distribution => 'Intensity Distribution';

  @override
  String get health_type_distribution => 'Type Distribution';

  @override
  String get health_exercise_history => 'Exercise History';

  @override
  String get project_mark_done_tooltip => 'Mark as completed';

  @override
  String project_completed_msg(int score) {
    return 'Project completed! +$score EXP';
  }

  @override
  String get project_delete_tooltip => 'Delete project';

  @override
  String get project_delete_confirm_title => 'Delete Project';

  @override
  String project_delete_confirm_msg(String name) {
    return 'Are you sure you want to delete \"$name\"? This action cannot be undone.';
  }

  @override
  String get project_deleted_msg => 'Project deleted';

  @override
  String get project_complete_label => 'COMPLETE';

  @override
  String get project_no_tasks => 'No tasks yet. Tap + to add one.';

  @override
  String get project_notes_label => 'Notes';

  @override
  String get project_no_notes => 'No notes yet. Tap + to create one.';

  @override
  String get project_no_notes_list => 'No notes found';

  @override
  String get project_finance_label => 'Finance';

  @override
  String get project_no_finance =>
      'No financial records linked to this project.';

  @override
  String get project_add_task_title => 'New Task';

  @override
  String get project_task_title_hint => 'Task title';

  @override
  String get project_add_investment_title => 'Add Investment';

  @override
  String get project_add_investment_desc =>
      'Record an expense or investment for this project.';

  @override
  String get amount => 'Amount';

  @override
  String get description_optional => 'Description (optional)';

  @override
  String get project_investment_default_desc => 'Project investment';

  @override
  String get project_add_investment_btn => 'Add Investment';

  @override
  String get project_new_note_title => 'New Note';

  @override
  String project_last_edited_msg(String date) {
    return 'Last edited $date';
  }

  @override
  String get project_note_untitled => 'Untitled';

  @override
  String get project_unknown_date => 'Unknown date';

  @override
  String get project_delete_note_title => 'Delete Note';

  @override
  String get project_delete_note_msg =>
      'Are you sure you want to delete this note?';

  @override
  String get project_note_no_content => 'No content';

  @override
  String get calorie_tracker => 'Calorie Tracker';

  @override
  String get net_calories => 'NET CALORIES';

  @override
  String get under_goal => 'Under Goal';

  @override
  String get on_track => 'On Track';

  @override
  String get over_goal => 'Over Goal';

  @override
  String goal_kcal(int goal) {
    return 'Goal: $goal kcal';
  }

  @override
  String percent_of_daily_goal(String percent) {
    return '$percent% of daily goal';
  }

  @override
  String get consumed => 'Consumed';

  @override
  String get burned => 'Burned';

  @override
  String get total_burn => 'Total Burn';

  @override
  String get add_food => 'Add Food';

  @override
  String get lidar_scan => 'LiDAR Scan';

  @override
  String get health_log_exercise => 'Log Exercise';

  @override
  String get health_calories_burned_label => 'Calories Burned';

  @override
  String added_food_msg(String name, int calories) {
    return 'Added $name ($calories kcal)';
  }

  @override
  String get lidar_ios_only =>
      'LiDAR scanning is only available on iOS Pro devices.';

  @override
  String get lidar_completed => 'LiDAR scan completed!';

  @override
  String get health_quick_add_exercise => 'Quick Add Exercise';

  @override
  String get health_walking_30min => 'Walking (30 min)';

  @override
  String get health_running_30min => 'Running (30 min)';

  @override
  String get health_cycling_30min => 'Cycling (30 min)';

  @override
  String get health_swimming_30min => 'Swimming (30 min)';

  @override
  String get health_yoga_30min => 'Yoga (30 min)';

  @override
  String added_calories_burned(int calories) {
    return 'Added $calories kcal burned';
  }

  @override
  String get exercise_tracker => 'Exercise Tracker';

  @override
  String get daily_routines => 'Daily Routines';

  @override
  String get activity_history => 'Activity History';

  @override
  String get no_activities_recorded => 'No activities recorded yet.';

  @override
  String get custom_activity_title => 'CUSTOM ACTIVITY';

  @override
  String get activity_type_label => 'Activity Type (e.g. Gym)';

  @override
  String get duration_min_label => 'Duration (min)';

  @override
  String get intensity_label => 'Intensity';

  @override
  String get log_activity_btn => 'LOG ACTIVITY';

  @override
  String get app_settings_title => 'Settings';

  @override
  String get account_section => 'Account';

  @override
  String get preferences_section => 'Preferences';

  @override
  String get about_support_section => 'About & Support';

  @override
  String get edit_profile => 'Edit Profile';

  @override
  String get edit_profile_subtitle => 'Profile details & identification';

  @override
  String get change_theme => 'Change Theme';

  @override
  String get system_notifications => 'System Notifications';

  @override
  String get notifications_active => 'Active';

  @override
  String get notifications_paused => 'Paused';

  @override
  String get change_language => 'Change Language';

  @override
  String get manual => 'User Manual';

  @override
  String get version => 'Version';

  @override
  String get reset_database_title => 'Reset Database';

  @override
  String get reset_database_msg =>
      'Warning: This will delete all your local data. This action cannot be undone.';

  @override
  String get btn_reset_all_data => 'RESET ALL DATA';

  @override
  String get msg_database_reset_success => 'Database reset successfully';

  @override
  String get guest_user => 'Guest';

  @override
  String get msg_sign_in_to_sync => 'Sign in to sync your data';

  @override
  String get member_status => 'Member';

  @override
  String get change_username => 'Change Username';

  @override
  String get remaining => 'Remaining';

  @override
  String get notification_manager_title => 'NOTIFICATION HUB';

  @override
  String get notification_hunter_hub => 'Hunter Hub';

  @override
  String get notification_tab_active => 'ACTIVE';

  @override
  String get notification_tab_reminders => 'REMINDERS';

  @override
  String get notification_tab_wisdom => 'WISDOM';

  @override
  String get notification_ai_no_data => 'No tactical data available.';

  @override
  String get notification_ai_advice => 'TACTICAL ADVICE';

  @override
  String get notification_ai_waiting => 'Gathering intelligence...';

  @override
  String get notification_ai_analysis => 'AI ANALYSIS';

  @override
  String get notification_daily_quest => 'DAILY QUEST';

  @override
  String notification_quest_completed_snack(String title, int exp) {
    return 'Quest completed: $title (+$exp EXP)';
  }

  @override
  String get notification_personal_reminders => 'Personal Reminders';

  @override
  String get notification_add_new => 'ADD NEW';

  @override
  String get notification_no_reminders => 'No reminders set.';

  @override
  String get notification_disabled_desc =>
      'System notifications are currently disabled.';

  @override
  String get notification_wisdom_board => 'Wisdom Board';

  @override
  String get notification_add_quote => 'ADD QUOTE';

  @override
  String get notification_quote_empty => 'The board of wisdom is empty.';

  @override
  String get notification_add_wisdom_title => 'Add Wisdom';

  @override
  String get notification_wisdom_content => 'Wisdom Content';

  @override
  String get notification_wisdom_author => 'Author';

  @override
  String get notification_inbox_title => 'NOTIFICATION CENTER';

  @override
  String get notification_mission_history => 'Mission History';

  @override
  String get notification_mission_success => 'MISSION SUCCESS';

  @override
  String get notification_focus_complete => 'FOCUS COMPLETE';

  @override
  String get notification_reminder => 'REMINDER';

  @override
  String get notification_no_logs => 'LOGS ARE EMPTY';

  @override
  String get notification_empty_desc =>
      'All system events will be stored here.';

  @override
  String get finance_add_transaction => 'Add Transaction';

  @override
  String finance_add_type(String type) {
    return 'Add $type';
  }

  @override
  String get finance_label_save => 'Save';

  @override
  String get finance_label_spend => 'Spend';

  @override
  String get finance_label_income => 'Income';

  @override
  String get finance_tooltip_add_savings => 'Add Savings';

  @override
  String get finance_tooltip_add_expense => 'Add Expense';

  @override
  String get finance_tooltip_add_income => 'Add Income';

  @override
  String get finance_type_expense => 'Expense';

  @override
  String get finance_type_income => 'Income';

  @override
  String get finance_type_savings => 'Savings';

  @override
  String get finance_label_amount => 'Amount';

  @override
  String get finance_label_category => 'Category';

  @override
  String get finance_label_description_optional => 'Description (optional)';

  @override
  String get finance_btn_add => 'Add';

  @override
  String get finance_total_net_worth => 'TOTAL NET WORTH';

  @override
  String finance_monthly_breakdown(String month) {
    return '$month Breakdown';
  }

  @override
  String get finance_recent_transactions => 'Recent Transactions';

  @override
  String get finance_no_transactions => 'No transactions yet';

  @override
  String get finance_tap_to_add => 'Tap + to add your first transaction';

  @override
  String get finance_total_savings => 'Total Savings';

  @override
  String finance_month_spending(String month) {
    return '$month Spending';
  }

  @override
  String finance_month_income(String month) {
    return '$month Income';
  }

  @override
  String get finance_see_all => 'SEE ALL';

  @override
  String get finance_cat_food => 'Food';

  @override
  String get finance_cat_coffee => 'Coffee';

  @override
  String get finance_cat_transport => 'Transport';

  @override
  String get finance_cat_software => 'Software';

  @override
  String get finance_cat_shopping => 'Shopping';

  @override
  String get finance_cat_bills => 'Bills';

  @override
  String get finance_cat_rent => 'Rent';

  @override
  String get finance_cat_subscriptions => 'Subscriptions';

  @override
  String get finance_cat_entertainment => 'Entertainment';

  @override
  String get finance_cat_health => 'Health';

  @override
  String get finance_cat_education => 'Education';

  @override
  String get finance_cat_investing => 'Investing';

  @override
  String get finance_cat_general => 'General';

  @override
  String get finance_cat_salary => 'Salary';

  @override
  String get finance_cat_freelance => 'Freelance';

  @override
  String get finance_cat_investment => 'Investment';

  @override
  String get finance_cat_gift => 'Gift';

  @override
  String get finance_cat_bonus => 'Bonus';

  @override
  String get finance_cat_emergency => 'Emergency';

  @override
  String get finance_cat_goal => 'Goal';

  @override
  String get finance_cat_retirement => 'Retirement';

  @override
  String get finance_cat_crypto => 'Crypto';

  @override
  String get finance_cat_stock => 'Stock';

  @override
  String get finance_cat_real_estate => 'Real Estate';

  @override
  String get finance_power_points => 'FINANCE POWER';

  @override
  String get finance_goal => 'Goal';

  @override
  String get finance_efficiency => 'Efficiency';

  @override
  String get finance_savings_rate => 'Savings Rate';

  @override
  String get finance_points_desc => 'Points earned from net worth';

  @override
  String get ssh_new_session => 'New SSH Session';

  @override
  String get ssh_host_label => 'Host IP or Domain';

  @override
  String get ssh_port_label => 'Port';

  @override
  String get ssh_user_label => 'Username';

  @override
  String get ssh_pass_label => 'Password or Key';

  @override
  String get ssh_connect => 'Connect';

  @override
  String get ssh_ask_ai => 'Ask AI';

  @override
  String get ssh_ask_ai_desc => 'Describe what you want to achieve...';

  @override
  String get ssh_generate => 'Generate';

  @override
  String get ssh_type_command => 'Type a command...';

  @override
  String get ssh_disconnect => 'Disconnect';

  @override
  String get ssh_search_hint => 'Search...';

  @override
  String get journal => 'Journal';

  @override
  String get social_notes => 'Social Notes';

  @override
  String get btn_send_feedback => 'Send Feedback';

  @override
  String get feedback_subtitle => 'Report issues or suggest features';
}
