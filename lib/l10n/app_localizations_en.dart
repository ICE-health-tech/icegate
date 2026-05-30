// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get quick_actions => 'Quick Actions';

  @override
  String get new_label => 'New';

  @override
  String get my_projects_label => 'My Projects';

  @override
  String get completed_projects_label => 'Completed Projects';

  @override
  String get active_tasks_label => 'Active Tasks';

  @override
  String get recent_notes_label => 'Recent Notes';

  @override
  String get projects_tile_reminders => 'Reminders';

  @override
  String get projects_tile_calendar => 'Calendar';

  @override
  String get projects_calendar_projects_created => 'Projects created';

  @override
  String get projects_calendar_day_empty =>
      'No tasks or project starts on this day.';

  @override
  String get projects_calendar_day_empty_not_connected =>
      'No calendar connected. Use “Connect calendar” above, then sync.';

  @override
  String projects_calendar_day_empty_other_days(int count) {
    return 'No events on this day. $count events elsewhere this month — try dates highlighted on the grid.';
  }

  @override
  String get projects_calendar_google_events => 'Google Calendar';

  @override
  String get projects_calendar_reminders => 'Reminders';

  @override
  String get projects_calendar_connect_google => 'Connect Google Calendar';

  @override
  String get projects_calendar_disconnect_google =>
      'Disconnect Google Calendar';

  @override
  String get projects_calendar_google_connected => 'Google Calendar connected';

  @override
  String get projects_calendar_sign_in_failed =>
      'Could not connect Google Calendar';

  @override
  String get projects_calendar_sign_in_cancelled =>
      'Google sign-in was cancelled';

  @override
  String get projects_calendar_scope_denied =>
      'Calendar permission was not granted. Allow access in your Google account settings.';

  @override
  String projects_calendar_api_not_enabled(String projectId) {
    return 'Google Calendar API is disabled for the macOS app (GCP project $projectId). In Google Cloud Console, enable \"Google Calendar API\" for that project, wait a few minutes, then retry.';
  }

  @override
  String get projects_calendar_insufficient_scopes =>
      'Calendar access was not granted. Disconnect Google, connect again, and accept all permissions.';

  @override
  String get projects_calendar_connect_hint =>
      'Sign in with Google to sync all your Google calendars to the Calendar screen.';

  @override
  String get projects_calendar_add_reminder => 'Add reminder';

  @override
  String get projects_calendar_reminder_title => 'Reminder title';

  @override
  String get projects_calendar_sync_google => 'Sync events';

  @override
  String get projects_calendar_all_day => 'All day';

  @override
  String get projects_calendar_integrations => 'Calendar connections';

  @override
  String get projects_calendar_connect_device => 'Connect device calendar';

  @override
  String get projects_calendar_connect_apple => 'Connect Apple Calendar';

  @override
  String get projects_calendar_disconnect_device =>
      'Disconnect device calendar';

  @override
  String get projects_calendar_disconnect_apple => 'Disconnect Apple Calendar';

  @override
  String get projects_calendar_device_connected => 'Device calendar connected';

  @override
  String get projects_calendar_apple_connected => 'Apple Calendar connected';

  @override
  String get projects_calendar_device_events => 'Device calendar';

  @override
  String get projects_calendar_apple_events => 'Apple Calendar';

  @override
  String get projects_calendar_device_hint =>
      'Allow calendar access to show events from calendars on this device.';

  @override
  String get projects_calendar_sync_device => 'Sync device events';

  @override
  String get projects_calendar_device_denied =>
      'Calendar access was denied. Enable it in Settings.';

  @override
  String get integration_hub_title => 'Integration Hub';

  @override
  String get integration_hub_subtitle =>
      'Calendars, health platforms, and device sensors — one connection center.';

  @override
  String get integration_hub_google_fit => 'Google Fit';

  @override
  String get integration_hub_google_fit_hint =>
      'Uses the same Google sign-in as Calendar and Drive.';

  @override
  String get integration_hub_sensors_section => 'Devices & sensors';

  @override
  String get integration_hub_open_sensor_hub => 'Open Sensor Hub';

  @override
  String get integration_hub_sensor_hub_hint =>
      'Wearables, IoT pipelines, SSH streams, and Huawei setup.';

  @override
  String get integration_hub_huawei_sensor_hint =>
      'Set up Huawei credentials in Sensor Hub first.';

  @override
  String get projects_calendar_all_calendars_events => 'All calendars';

  @override
  String projects_calendar_synced_count(int count) {
    return 'Loaded $count events this month';
  }

  @override
  String get projects_calendar_sync_empty_month =>
      'Connected — no events this month. Try another month or check Google Calendar.';

  @override
  String get integration_hub_calendars_section => 'Calendars';

  @override
  String get integration_hub_health_section => 'Health';

  @override
  String get integration_hub_connect => 'Connect';

  @override
  String get integration_hub_status_connected => 'Connected';

  @override
  String get integration_hub_apple_health => 'Apple Health';

  @override
  String get integration_hub_apple_health_hint =>
      'Steps, sleep, heart rate, and more from HealthKit.';

  @override
  String get integration_hub_huawei_health => 'Huawei Health';

  @override
  String get integration_hub_huawei_health_hint =>
      'Sync from Huawei cloud credentials.';

  @override
  String get integration_hub_phase2_notice =>
      'Calendar and Google sign-in work here. Huawei credentials: use Sensor Hub below.';

  @override
  String get integration_hub_sign_in_required =>
      'Sign in to your icegate account first, then connect integrations.';

  @override
  String get integration_hub_health_coming_soon =>
      'This health source is not available yet.';

  @override
  String get integration_hub_open => 'Open Integration Hub';

  @override
  String get projects_tile_focus => 'Focus';

  @override
  String get projects_tile_pomodoro => 'Pomodoro';

  @override
  String get projects_tile_social_blocker => 'Social Blocker';

  @override
  String get social_shield_turn_on => 'Turn on Shield';

  @override
  String get social_shield_subtitle_no_auth =>
      'Tap row to grant Screen Time (for rules)';

  @override
  String get social_shield_subtitle_pick_apps =>
      'Tap row to choose apps — blocking follows rules';

  @override
  String get social_shield_subtitle_ready =>
      'On — blocking runs when your rules are active';

  @override
  String get social_shield_subtitle_off =>
      'Off — schedules and focus rules are paused';

  @override
  String get social_shield_choose_apps => 'Choose apps to block';

  @override
  String get social_shield_choose_apps_done => 'Tap to change blocked apps';

  @override
  String get social_shield_pick_apps_required =>
      'Choose at least one app to block (or turn Shield off).';

  @override
  String get social_shield_apps_saved => 'Blocked apps updated.';

  @override
  String get social_shield_unsupported_platform =>
      'App blocking is only on iOS and macOS.';

  @override
  String get projects_plugin_open => 'Open';

  @override
  String get projects_plugin_location_tracker => 'Location Tracker';

  @override
  String get projects_plugin_live_map => 'Live Map';

  @override
  String get projects_remove_plugin_title => 'Remove shortcut?';

  @override
  String projects_remove_plugin_body(String name) {
    return 'Remove \"$name\" from quick actions?';
  }

  @override
  String get projects_remove_plugin_confirm => 'Remove';

  @override
  String get integrations_title => 'Integrations';

  @override
  String get integrations_subtitle => 'Manage your document sources';

  @override
  String get integrations_active_services => 'Active Services';

  @override
  String get integrations_total_notes => 'Total Notes';

  @override
  String get integrations_search_hint => 'Search sources...';

  @override
  String get integrations_enabled_connections => 'ENABLED CONNECTIONS';

  @override
  String get integrations_filters => 'Filters';

  @override
  String get integrations_internal_notes => 'Internal Notes';

  @override
  String get integrations_primary_vault => 'Primary Vault (Local)';

  @override
  String get integrations_explore => 'Explore';

  @override
  String get integrations_google_drive => 'Google Drive';

  @override
  String get integrations_synced_cloud => 'Synced with Cloud';

  @override
  String get integrations_cloud_storage => 'Cloud Storage';

  @override
  String get integrations_sync_now => 'Sync Now';

  @override
  String get integrations_connect => 'Connect';

  @override
  String get integrations_notion_sync => 'Notion Sync';

  @override
  String get integrations_database_pipeline => 'Database Pipeline';

  @override
  String get integrations_fetch => 'Fetch';

  @override
  String get integrations_setup => 'Setup';

  @override
  String get integrations_slack_docs => 'Slack Docs';

  @override
  String get integrations_shared_channels => 'Shared Channels';

  @override
  String get integrations_notify_me => 'Notify Me';

  @override
  String get integrations_notion_config_title => 'Notion Configuration';

  @override
  String get integrations_notion_secret_label => 'Internal Integration Secret';

  @override
  String get integrations_save_fetch => 'Save & Fetch';

  @override
  String get integrations_marketplace_soon => 'Source Marketplace coming soon!';

  @override
  String get projects_workspace_empty => 'No workspace has been set up yet.';

  @override
  String get projects_workspace_start => 'Get started';

  @override
  String get project_drive_sync => 'Cloud Sync';

  @override
  String get project_drive_sync_tooltip => 'Sync with Google Drive';

  @override
  String get project_sync_success => 'Sync completed successfully!';

  @override
  String project_sync_failed(String error) {
    return 'Sync failed: $error';
  }

  @override
  String get project_created_msg => 'Project created with all components!';

  @override
  String project_create_failed(String error) {
    return 'Error creating project: $error';
  }

  @override
  String get create_project_title => 'Create Project Widget';

  @override
  String get project_name_label => 'Project Name';

  @override
  String get project_name_required => 'Please enter a name';

  @override
  String get description => 'Description';

  @override
  String get project_initial_investment_label => 'Initial Investment';

  @override
  String get project_internal_path_label => 'Internal Path (Optional)';

  @override
  String get create => 'CREATE';

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
  String get health_motivation_engine_title => 'Motivation Engine';

  @override
  String get health_notification_engine_title => 'Notification Engine';

  @override
  String health_notification_engine_desc(int count) {
    return '$count active reminders';
  }

  @override
  String get health_motivation_all_done =>
      'All daily targets hit—momentum is yours today.';

  @override
  String get health_motivation_strong => 'Strong day—keep your streak alive.';

  @override
  String get health_motivation_mid =>
      'Steady progress—stack one more small win.';

  @override
  String get health_motivation_low =>
      'Start with water or a short walk—small steps count.';

  @override
  String get health_motivation_empty =>
      'Set your goals and we\'ll coach you through the day.';

  @override
  String get health_update_weight => 'Update Weight';

  @override
  String get health_smart_scale_title => 'Smart scale';

  @override
  String get health_smart_scale_desc =>
      'Sync from Apple Health or Health Connect (Withings, Eufy, Xiaomi, etc.)';

  @override
  String get health_smart_scale_sync => 'Sync smart scale';

  @override
  String get health_smart_scale_syncing => 'Syncing…';

  @override
  String get health_smart_scale_sync_ok => 'Weight synced from smart scale';

  @override
  String get health_smart_scale_sync_empty =>
      'No weight found. Weigh in on your scale first, then sync.';

  @override
  String get health_smart_scale_sync_denied =>
      'Health access denied. Enable in Settings.';

  @override
  String get health_smart_scale_desktop =>
      'Smart scale sync is available on iPhone and Android only.';

  @override
  String get health_smart_scale_import => 'Import from smart scale';

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
  String get health_insights => 'Health';

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
  String get notification_category_social => 'Mind';

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
  String get nutri_add_meal => 'Add Meal';

  @override
  String get nutri_analyzing => 'Analyzing...';

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
  String get nutri_what_eat => 'What did you eat?';

  @override
  String get nutri_save_record => 'SAVE RECORD';

  @override
  String get nutri_info_title => 'NUTRITION INFO';

  @override
  String get nutri_camera => 'Camera';

  @override
  String get nutri_gallery => 'Gallery';

  @override
  String get nutri_delete_meal => 'Delete Meal';

  @override
  String get nutri_delete_confirm =>
      'Are you sure you want to delete this meal?';

  @override
  String get nutri_meal_deleted => 'Meal deleted';

  @override
  String get nutri_yesterday => 'Yesterday';

  @override
  String get nutri_ai_saved_retry_later =>
      'Meal saved locally. AI server unavailable — use Retry on the dashboard when it is back.';

  @override
  String get nutri_ai_retry => 'Retry AI analysis';

  @override
  String get nutri_calories_pending => 'Calories pending';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_delete => 'Delete';

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
  String get health_metrics_oxygen_saturation => 'Oxygen';

  @override
  String get health_spo2_page_title => 'Blood oxygen (SpO₂)';

  @override
  String get health_spo2_today => 'Today';

  @override
  String get health_spo2_chart_section => 'Today\'s chart';

  @override
  String get health_spo2_percent_unit => '% SpO₂';

  @override
  String health_spo2_latest(String time) {
    return 'Latest: $time';
  }

  @override
  String health_spo2_target_line(int n) {
    return 'Target $n%';
  }

  @override
  String health_spo2_target_row(int n) {
    return 'Target: $n%';
  }

  @override
  String get health_spo2_edit_target => 'Change target';

  @override
  String get health_spo2_target_dialog_title => 'SpO₂ target';

  @override
  String get health_spo2_save => 'Save';

  @override
  String health_spo2_day_avg(String n) {
    return 'Day average: $n%';
  }

  @override
  String get health_spo2_summary_min => 'Lowest';

  @override
  String get health_spo2_summary_max => 'Highest';

  @override
  String get health_spo2_educational_title => 'About SpO₂';

  @override
  String get health_spo2_educational_body =>
      'Normal blood oxygen saturation is often around 95–100%. These readings are for reference only and are not a substitute for professional medical advice.';

  @override
  String get health_spo2_motivation_peak =>
      'Outstanding oxygenation—when SpO₂ stays high, focus feels sharper and breathing steadier.';

  @override
  String get health_spo2_motivation_high =>
      'Strong SpO₂—great fuel for focus and a steadier mind.';

  @override
  String get health_spo2_motivation_on_target =>
      'You\'re meeting your target—keep breathing easy.';

  @override
  String get health_spo2_motivation_near =>
      'Close to your goal—a few slow breaths can bring you into range.';

  @override
  String get health_spo2_motivation_low =>
      'Below your target today—rest, hydrate, and breathe gently.';

  @override
  String get health_spo2_motivation_empty =>
      'Wear your device and check back—your next reading can guide your calm and clarity.';

  @override
  String get health_metrics_air_quality => 'Air Quality';

  @override
  String get health_metrics_weather => 'Weather';

  @override
  String get health_air_quality => 'Air Quality';

  @override
  String get health_weather => 'Weather';

  @override
  String get health_temperature_subtitle => 'Current Temperature';

  @override
  String get health_temperature_env_title => 'Weather & air';

  @override
  String get health_env_condition => 'Conditions';

  @override
  String get health_env_particles => 'Particles';

  @override
  String get health_env_pm25 => 'PM2.5';

  @override
  String get health_env_pm10 => 'PM10';

  @override
  String get health_env_sources => 'Open-Meteo · WAQI';

  @override
  String health_env_updated(String time) {
    return 'Updated $time';
  }

  @override
  String get health_aqi_unit => 'AQI';

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
  String get health_at_a_glance => 'Your health at a glance.';

  @override
  String get health_analyzing_meal => 'Analyzing meal…';

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
  String get apple_login => 'APPLE';

  @override
  String get enroll_hub => 'ENROLL';

  @override
  String msg_secure_login_failed(String error) {
    return 'Secure login failed: $error';
  }

  @override
  String get err_invalid_credentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get err_email_not_confirmed =>
      'Please check your inbox to verify your email.';

  @override
  String get err_user_not_found =>
      'We couldn\'t find an account with that email.';

  @override
  String get err_network_fail =>
      'Unable to connect to the server. Check your internet.';

  @override
  String get err_auth_timeout => 'Sign-in took too long. Please try again.';

  @override
  String get err_passkey_canceled => 'Passkey login was canceled.';

  @override
  String get err_google_canceled => 'Google sign-in was canceled.';

  @override
  String get err_google_failed =>
      'Google sign-in failed. Enable Google in Supabase and add the web client ID.';

  @override
  String get err_passkey_failed => 'Security check failed. Please try again.';

  @override
  String get err_biometric_unsupported =>
      'Biometric login is not available on this device.';

  @override
  String get err_biometric_disabled =>
      'Biometric login is not enabled for this account.';

  @override
  String get err_too_many_attempts =>
      'Too many failed attempts. Please try again later.';

  @override
  String get msg_enter_credentials => 'Please enter your credentials';

  @override
  String get forgot_password => 'Forgot password?';

  @override
  String get forgot_password_title => 'Reset password';

  @override
  String get forgot_password_body =>
      'Enter your account email. We will send you a link to set a new password.';

  @override
  String get forgot_password_send => 'Send reset link';

  @override
  String get forgot_password_success =>
      'If an account exists for this email, you will receive a reset link shortly.';

  @override
  String get err_forgot_password_empty_email =>
      'Please enter your email address.';

  @override
  String get err_forgot_password_invalid_email =>
      'Please enter a valid email address.';

  @override
  String get register_page_title => 'Create account';

  @override
  String get register_username_hint => 'Username';

  @override
  String get register_first_name => 'First name';

  @override
  String get register_last_name => 'Last name';

  @override
  String get register_password_confirm => 'Confirm password';

  @override
  String get btn_create_account => 'Create account';

  @override
  String msg_register_check_email(String email) {
    return 'We sent a confirmation link to $email. Open it in this app to finish signing up.';
  }

  @override
  String get msg_resend_confirm_sent =>
      'If that address is valid, a new confirmation email was sent.';

  @override
  String get register_resend_email => 'Resend email';

  @override
  String get register_back_to_login => 'Back to sign in';

  @override
  String get err_register_password_mismatch => 'Passwords do not match.';

  @override
  String get title_set_new_password => 'Set new password';

  @override
  String get msg_password_recovery_body =>
      'Choose a new password for your account.';

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
  String get scoring_social => 'Mind';

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
  String get breakdown_screentime => 'Screen Time';

  @override
  String get date_today => 'Today';

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
  String get btn_enter => 'ENTER';

  @override
  String apple_signin_error(String error) {
    return 'Apple Sign-In Error: $error';
  }

  @override
  String google_signin_error(String error) {
    return 'Google Sign-In Error: $error';
  }

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
  String get identity_evolution => 'IDENTITY EVOLUTION';

  @override
  String get identity_evolution_desc =>
      'Level 1: Google. Set a local password to upgrade your security tier.';

  @override
  String get btn_set => 'SET';

  @override
  String get security_accuracy => 'Security & Accuracy';

  @override
  String get passkey_settings => 'Passkey Settings';

  @override
  String get fast_track_active => 'Fast-Track Active (Secure)';

  @override
  String get upgrade_biometric => 'Upgrade to Biometric Fast-Track';

  @override
  String get hint_enter_your => 'Enter your...';

  @override
  String get user_default => 'User';

  @override
  String get tooltip_save => 'Save';

  @override
  String get tooltip_edit => 'Edit';

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
  String get social_dashboard => 'Mind Dashboard';

  @override
  String get social => 'Mind';

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
  String get social_options => 'Mind Options';

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
  String get social_no_achievements_msg => 'No achievements logged yet.';

  @override
  String get achievement_story_section => 'Photo stories';

  @override
  String get achievement_story_empty_hint =>
      'Tap + to save a photo win — shown here like stories.';

  @override
  String get achievement_story_add => 'Add';

  @override
  String get achievement_feats_section => 'Logged feats';

  @override
  String get achievement_insights_title => 'Insights Dashboard';

  @override
  String achievement_insights_summary(
    int count,
    String meaning,
    String impact,
  ) {
    return 'Monthly Reflection: $count feats recorded. Average Meaningfulness: $meaning, Average Impact: $impact';
  }

  @override
  String get achievement_story_title_dialog => 'Name this win';

  @override
  String get achievement_story_title_hint => 'What did you achieve?';

  @override
  String get achievement_story_added => 'Story saved to your achievements.';

  @override
  String get achievement_story_save_failed => 'Could not save photo.';

  @override
  String get social_delete_feat_title => 'Delete feat';

  @override
  String get social_delete_feat_body =>
      'Remove this achievement? This cannot be undone.';

  @override
  String get social_feat => 'Feat';

  @override
  String get mind_how_feeling => 'How are you feeling?';

  @override
  String get mind_what_up_to => 'What have you been up to?';

  @override
  String get mind_add_note_hint => 'Add a note (optional)';

  @override
  String get mind_save_entry => 'Save Entry';

  @override
  String get mind_log_saved => 'Mind log saved! Reflection updated.';

  @override
  String get mind_error_login =>
      'Error: User session not found. Please log in again.';

  @override
  String mind_error_save(String error) {
    return 'Failed to save log: $error';
  }

  @override
  String get mood_awful => 'Awful';

  @override
  String get mood_bad => 'Bad';

  @override
  String get mood_meh => 'Meh';

  @override
  String get mood_good => 'Good';

  @override
  String get mood_rad => 'Rad';

  @override
  String get mood_no_data => 'No data';

  @override
  String get mind_current_mood => 'Current Mood';

  @override
  String get mind_day_average => 'Day Average';

  @override
  String get mind_latest_log => 'Latest Log';

  @override
  String get mind_never => 'Never';

  @override
  String get mind_status => 'Status';

  @override
  String get mind_stable => 'Stable';

  @override
  String get mind_needs_care => 'Needs Care';

  @override
  String get mind_focus_current => 'Focus';

  @override
  String get mind_focus_none => 'Not set';

  @override
  String get mind_quick_entry_hint => 'What\'s on your mind?';

  @override
  String get mind_focus_title => 'Focus areas';

  @override
  String get mind_focus_subtitle =>
      'Define weekly trends so you know where to put your energy.';

  @override
  String get mind_focus_empty =>
      'No focus areas yet. Start from a template or create your own.';

  @override
  String get mind_focus_add => 'New focus area';

  @override
  String get mind_focus_edit => 'Edit focus area';

  @override
  String get mind_focus_weekly_goal => 'Logs per week (goal)';

  @override
  String get mind_focus_this_week => 'This week';

  @override
  String get mind_focus_select_hint =>
      'Tap to focus on this area. Recent matching journal entries:';

  @override
  String get mind_focus_template_gym => 'Gym week';

  @override
  String get mind_focus_template_learn => 'Learn week';

  @override
  String get mind_focus_template_invest => 'Invest week';

  @override
  String get mind_focus_name_hint => 'Name (e.g. Gym week)';

  @override
  String get mind_focus_activities_label => 'Linked activities';

  @override
  String get mind_focus_name_required => 'Enter a name for this focus area';

  @override
  String get mind_focus_activities_required => 'Pick at least one activity';

  @override
  String get mind_focus_icon_label => 'Icon';

  @override
  String get mind_focus_color_label => 'Color';

  @override
  String get mind_focus_no_logs_yet =>
      'No journal entries match this area yet.';

  @override
  String get mind_focus_log_now => 'Log for this area';

  @override
  String get mind_focus_todos => 'To-do';

  @override
  String get mind_focus_open_projects => 'Projects';

  @override
  String get mind_focus_no_todos =>
      'No active project tasks. Add tasks in Projects.';

  @override
  String mind_focus_more_todos(int count) {
    return '+$count more in Projects';
  }

  @override
  String mind_focus_avg_mood(String score) {
    return 'Avg mood this week: $score';
  }

  @override
  String get mind_skills_session_title => 'Skill session';

  @override
  String get mind_skills_session_subtitle =>
      'Pick skills, run a focus block, log what you learned.';

  @override
  String get mind_skills_session_start => 'Start session';

  @override
  String mind_skills_session_empty(int days) {
    return 'No skill sessions in the last $days days.';
  }

  @override
  String mind_skills_session_stats(int sessions, int minutes, String skill) {
    return '$sessions sessions · $minutes min · top: $skill';
  }

  @override
  String get mind_skills_session_live => 'SESSION LIVE';

  @override
  String get mind_skills_session_tap_start => 'TAP CENTER TO START';

  @override
  String get mind_skills_session_tap_finish => 'TAP CENTER TO STOP EARLY';

  @override
  String get mind_skills_session_listening =>
      'SESSION LIVE · AUTO-LOG WHEN MUSIC ENDS';

  @override
  String get mind_skills_session_pick_skills =>
      'Pick at least one skill before starting.';

  @override
  String get mind_skills_my_list => 'My skills';

  @override
  String get mind_skills_add_skill => 'Add skill';

  @override
  String get mind_skills_tap_list => 'Tap skills in the list to select';

  @override
  String get mind_skills_tap_list_project =>
      'Select skills · project XP on log';

  @override
  String get mind_skills_status_in_session => 'In session';

  @override
  String get mind_skills_status_selected => 'Selected';

  @override
  String mind_skills_level_short(int level) {
    return 'Lv $level';
  }

  @override
  String mind_skills_session_logged(int minutes, int xp) {
    return 'Session logged · $minutes min · +$xp XP';
  }

  @override
  String get mood_trends_title => 'Mood Trends';

  @override
  String get social_notes_title => 'Social Notes';

  @override
  String get social_empty_state_title => 'Your story begins here';

  @override
  String get social_empty_state_subtitle =>
      'Capture moments, thoughts, and ideas.';

  @override
  String get btn_new_reflection => 'New Reflection';

  @override
  String get mind_insights_title => 'Mind Insights';

  @override
  String get mind_insights_subtitle => 'Analysis of your journal entries';

  @override
  String get mind_question => 'How are you feeling?';

  @override
  String get mind_activities_question => 'What have you been up to?';

  @override
  String get mind_note_hint => 'Add a note (optional)';

  @override
  String get mind_save_btn => 'Save Entry';

  @override
  String get mind_activity_custom_chip => 'Custom';

  @override
  String get mind_activity_custom_dialog_title => 'New activity';

  @override
  String get mind_activity_custom_hint => 'Name this activity';

  @override
  String get mind_activity_custom_add => 'Add';

  @override
  String get mind_activity_custom_invalid_char =>
      'This character is not allowed';

  @override
  String get mind_save_success => 'Mind log saved! Reflection updated.';

  @override
  String mind_feeling_format(String mood) {
    return 'I\'m feeling $mood today.';
  }

  @override
  String get mind_logged_mood => 'Logged mood';

  @override
  String get todays_reflections => 'Today\'s Reflections';

  @override
  String get daily_step_distribution => 'Daily Step Distribution';

  @override
  String get stat_entries => 'Entries';

  @override
  String get stat_images => 'Images';

  @override
  String get stat_sentiment => 'Sentiment';

  @override
  String get weekly_mood_trend => 'Weekly Mood Trend';

  @override
  String get no_records_last_7_days => 'No records for the last 7 days';

  @override
  String get frequent_activities => 'Frequent Activities';

  @override
  String get track_patterns_msg => 'Track more logs to see patterns';

  @override
  String get monthly_reflection => 'Monthly Reflection';

  @override
  String get cat_productivity => 'Productivity';

  @override
  String get cat_health => 'Health';

  @override
  String get cat_social => 'Social';

  @override
  String get cat_rest => 'Rest';

  @override
  String get act_deep_work => 'Deep Work';

  @override
  String get act_learning => 'Learning';

  @override
  String get act_finance => 'Finance';

  @override
  String get act_planning => 'Planning';

  @override
  String get act_exercise => 'Exercise';

  @override
  String get act_meditation => 'Meditation';

  @override
  String get act_healthy_meal => 'Healthy Meal';

  @override
  String get act_great_sleep => 'Great Sleep';

  @override
  String get act_family => 'Family';

  @override
  String get act_friends => 'Friends';

  @override
  String get act_dating => 'Dating';

  @override
  String get act_kindness => 'Kindness';

  @override
  String get act_gaming => 'Gaming';

  @override
  String get act_reading => 'Reading';

  @override
  String get act_cinema => 'Cinema';

  @override
  String get act_walking => 'Walking';

  @override
  String get act_logging => 'Logging';

  @override
  String get act_productivity => 'Productivity';

  @override
  String get add_app_plugin => 'Add App Plugin';

  @override
  String get plugin_desc => 'Add new features to your dashboard';

  @override
  String get plugin_ssh => 'SSH Session';

  @override
  String get plugin_ssh_opencode => 'OpenCode AI SSH';

  @override
  String get plugin_ssh_desc => 'AI-powered terminal for remote orchestration';

  @override
  String get config_ai_prompt => 'Configure AI Prompt';

  @override
  String get homepage_four_life_elements => 'Main Elements';

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
  String get auth_error_session_not_found =>
      'Error: User session not found. Please log in again.';

  @override
  String get projects => 'Projects';

  @override
  String get projects_page_tagline =>
      'Sessions, tasks, and notes in one place.';

  @override
  String get projects_summary_workspaces => 'Workspaces';

  @override
  String get projects_summary_plugins => 'Plugins';

  @override
  String get projects_quick_more => 'More shortcuts';

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
  String get home_indices_title => 'Quick Indices';

  @override
  String get home_index_steps => 'Steps';

  @override
  String get home_index_calories => 'Calories';

  @override
  String get home_index_balance => 'Balance';

  @override
  String get home_index_spending => 'Spending';

  @override
  String get home_index_mood => 'Mood';

  @override
  String get home_index_projects => 'Growth';

  @override
  String get home_index_weight => 'Weight';

  @override
  String get home_index_water => 'Water';

  @override
  String get home_index_daily => 'Daily';

  @override
  String get home_index_usage => 'Usage';

  @override
  String get home_index_focus => 'Focus';

  @override
  String get home_index_xp => 'XP Today';

  @override
  String get home_index_total => 'Total';

  @override
  String get home_projects_done => 'Done Projs';

  @override
  String get home_projects_active => 'Active Projs';

  @override
  String get home_tasks_done => 'Done Tasks';

  @override
  String get home_tasks_active => 'Active Tasks';

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
    return '$points points for each new meaningful support session or connection.';
  }

  @override
  String rule_social_affection(int points, int unit) {
    return '$points points per $unit stability level reached.';
  }

  @override
  String get rule_social_maintain =>
      'Practice mindfulness and maintain connections to prevent stability decay.';

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
  String get canvas_finance_reports_title => 'Finance reports';

  @override
  String get canvas_finance_reports_desc =>
      'Daily summary, local reminders, and shortcuts';

  @override
  String get canvas_finance_n8n_title => 'Email report';

  @override
  String get canvas_finance_n8n_desc =>
      'Finance and health snapshot delivered through n8n';

  @override
  String get canvas_finance_n8n_send_success => 'Report sent to n8n.';

  @override
  String get canvas_finance_n8n_send_failed =>
      'Could not send report. Try again later.';

  @override
  String get canvas_finance_n8n_not_configured =>
      'n8n webhook is not configured in the app environment.';

  @override
  String get canvas_finance_n8n_no_email =>
      'Add an email to your profile before sending a report.';

  @override
  String get canvas_finance_n8n_confirm_title => 'Send email report?';

  @override
  String canvas_finance_n8n_confirm_message(String email) {
    return 'Today\'s finance and health summary will be sent to n8n for delivery to $email.';
  }

  @override
  String get canvas_mail_summary_recipient => 'Recipient';

  @override
  String get canvas_mail_summary_finance => 'Finance today';

  @override
  String get canvas_mail_summary_health => 'Health today';

  @override
  String get canvas_mail_summary_send => 'Send email report';

  @override
  String get canvas_mail_summary_auto_title => 'Automatic daily email';

  @override
  String get canvas_mail_summary_auto_subtitle =>
      'After this time, send once per day while the app is open';

  @override
  String get mail_suggestion_title => 'Report tips';

  @override
  String get mail_suggestion_ai_loading => 'AI is analyzing your day…';

  @override
  String get mail_suggestion_ai_fallback =>
      'Offline tips — connect MAIL_SUGGESTIONS_AGENT_URL for AI.';

  @override
  String get mail_suggestion_negative_net =>
      'Today\'s spending exceeded income — review recent transactions.';

  @override
  String get mail_suggestion_no_transactions =>
      'No transactions logged today — add expenses to keep reports accurate.';

  @override
  String mail_suggestion_budget_high(String percent) {
    return 'You\'ve used $percent% of your monthly budget — pace spending.';
  }

  @override
  String get mail_suggestion_monthly_deficit =>
      'Monthly spending exceeds income — consider trimming fixed costs.';

  @override
  String mail_suggestion_steps_low(String percent) {
    return 'Steps at $percent% of goal — a short walk helps hit your target.';
  }

  @override
  String get mail_suggestion_water_low =>
      'Water intake is below half your goal — hydrate through the day.';

  @override
  String get mail_suggestion_sleep_low =>
      'Sleep below your goal — try an earlier wind-down tonight.';

  @override
  String get mail_suggestion_log_mood =>
      'No mood logged today — a quick check-in improves your trends.';

  @override
  String get mail_suggestion_focus_low =>
      'Focus time is low — schedule a short deep-work block.';

  @override
  String mail_suggestion_tasks_many(String count) {
    return '$count active tasks open — pick one priority for tomorrow.';
  }

  @override
  String get reports_hub_title => 'Report via mail';

  @override
  String get reports_hub_subtitle =>
      'Daily finance on device, email delivery through n8n';

  @override
  String get reports_mail_section_title => 'Email via n8n';

  @override
  String get reports_mail_section_subtitle =>
      'Finance and health snapshot delivered by email';

  @override
  String get reports_finance_section => 'On-device finance report';

  @override
  String get reports_recipient_hint => 'recipient@example.com';

  @override
  String get reports_recipient_save => 'Save recipient';

  @override
  String get reports_recipient_saved => 'Report recipient saved.';

  @override
  String reports_recipient_profile_fallback(String email) {
    return 'Profile email default: $email';
  }

  @override
  String get canvas_finance_n8n_confirm_send => 'Send';

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
  String get project_choose_document_type => 'Choose document type';

  @override
  String get project_doc_blank_note => 'Blank note';

  @override
  String get project_doc_blank_note_desc => 'Start with a clean slate';

  @override
  String get project_doc_tech => 'Technical doc';

  @override
  String get project_doc_tech_desc =>
      'Architecture and implementation template';

  @override
  String get project_doc_api => 'API specification';

  @override
  String get project_doc_api_desc => 'Endpoints and schema template';

  @override
  String get project_doc_tech_title => 'Technical Documentation';

  @override
  String get project_doc_api_title => 'API Specification';

  @override
  String get project_finance_label => 'Finance';

  @override
  String get project_no_finance =>
      'No financial records linked to this project.';

  @override
  String get project_skills_label => 'Skills';

  @override
  String get project_no_skills =>
      'No skills yet. Tap + to track what you improve on this project.';

  @override
  String get project_add_skill_title => 'Add skill';

  @override
  String get project_skill_name_hint =>
      'e.g. Flutter, debugging, system design';

  @override
  String project_skill_streak_days(int count) {
    return '$count day streak';
  }

  @override
  String get project_skill_streak_none => 'No streak yet';

  @override
  String project_skill_xp_hint(int total, int remaining) {
    return '$total XP · $remaining XP to next level';
  }

  @override
  String get project_skill_xp_on_complete =>
      'Complete tasks to earn +15 XP per skill';

  @override
  String get project_skill_log_session =>
      'Log a Skill Boost session to level these skills.';

  @override
  String get project_skill_practice => 'Open Skill Boost';

  @override
  String get project_skill_tap_to_start =>
      'Select one or more skills, then start the session';

  @override
  String project_skill_start_session(int count) {
    return 'Start session ($count)';
  }

  @override
  String get project_skill_catalog_hint =>
      'Pick from the same skills as Mind → Skills tiles.';

  @override
  String get project_auto_add_all_skills => 'Add all automatically';

  @override
  String get project_auto_add_all_skills_subtitle =>
      'Link every skill from your Mind library to this project';

  @override
  String get project_skills_all_on_project =>
      'All library skills are already on this project';

  @override
  String project_skills_added_count(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count skills added',
      one: '1 skill added',
    );
    return '$_temp0';
  }

  @override
  String project_skill_delete_confirm(String name) {
    return 'Remove \"$name\" from this project?';
  }

  @override
  String get project_skill_added => 'Skill added';

  @override
  String project_skill_xp_granted(int xp) {
    return 'Skills gained +$xp XP';
  }

  @override
  String get project_sub_projects_label => 'Sub-projects';

  @override
  String get project_no_sub_projects =>
      'No sub-projects yet. Tap + to add a child project.';

  @override
  String get project_add_sub_project_title => 'New sub-project';

  @override
  String get project_sub_project_name_hint => 'Sub-project name';

  @override
  String get project_add_task_title => 'New Task';

  @override
  String get project_task_assign_to => 'Assign to project';

  @override
  String get project_task_title_hint => 'Task title';

  @override
  String get task_delete_tooltip => 'Delete task';

  @override
  String get task_delete_confirm_title => 'Delete task';

  @override
  String task_delete_confirm_msg(String name) {
    return 'Are you sure you want to delete \"$name\"? This cannot be undone.';
  }

  @override
  String get task_deleted_msg => 'Task deleted';

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
  String get recent_updates => 'Recent Updates';

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
  String get note_editor_write_hint => 'Start writing your note…';

  @override
  String note_editor_saved_label(String when) {
    return 'Saved $when';
  }

  @override
  String get note_editor_saved_just_now => 'just now';

  @override
  String note_editor_saved_minutes(int count) {
    return '${count}m ago';
  }

  @override
  String note_editor_saved_hours(int count) {
    return '${count}h ago';
  }

  @override
  String get note_editor_unsaved => 'Unsaved';

  @override
  String get note_editor_saving => 'Saving…';

  @override
  String get focus_select_project => 'TAP TO SELECT PROJECT';

  @override
  String get focus_select_task => 'SELECT TASK';

  @override
  String focus_active_exercise(String type) {
    return 'ACTIVE EXERCISE: $type';
  }

  @override
  String get focus_flow_active => 'FLOW STATE ACTIVE';

  @override
  String get focus_breathing => 'BREATHING';

  @override
  String get focus_fetching_audio => 'FETCHING AUDIO...';

  @override
  String get entry_scanning => 'SCANNING';

  @override
  String get entry_assembling => 'ASSEMBLING';

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
  String get delete_account => 'Delete account';

  @override
  String get delete_account_subtitle =>
      'Sign out and remove your cloud profile when supported';

  @override
  String get delete_account_plan_title => 'Suggested plan before you delete';

  @override
  String get delete_account_plan_intro =>
      'Review what happens when you continue:';

  @override
  String get delete_account_plan_step1 =>
      'You will be signed out on this device and saved login data cleared from secure storage.';

  @override
  String get delete_account_plan_step2 =>
      'If your project deploys the Supabase Edge Function \"delete-account\", your auth user and linked rows can be removed server-side.';

  @override
  String get delete_account_plan_step3 =>
      'Until that endpoint exists, cloud data may remain — contact support or use the dashboard to request full erasure under applicable privacy laws.';

  @override
  String get delete_account_acknowledge =>
      'I understand my account may not be fully erased from the server until backend deletion is enabled.';

  @override
  String get delete_account_confirm => 'Delete and sign out';

  @override
  String get delete_account_cancel => 'Cancel';

  @override
  String get delete_account_success =>
      'You have been signed out. Complete cloud deletion may take up to 48 hours once enabled.';

  @override
  String get delete_account_err_not_signed_in => 'No active session.';

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
  String get notification_no_active_quests =>
      'No active quests right now. Complete tasks in Projects to earn daily quests.';

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
  String get notification_system_preferences => 'SYSTEM PREFERENCES';

  @override
  String get notification_pomodoro_reminder_title => 'Pomodoros Reminder';

  @override
  String get notification_pomodoro_reminder_subtitle =>
      'Receive notification after you finish a pomodoro or end a break.';

  @override
  String get notification_live_activities_title => 'Live Activities';

  @override
  String get notification_live_activities_subtitle =>
      'Track focus timer and information on your Lock Screen.';

  @override
  String get notification_morning_briefing_subtitle =>
      'Show the morning summary the first time you open Home each day.';

  @override
  String get notification_status_on => 'on';

  @override
  String get notification_status_off => 'off';

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
  String get notification_task_success => 'TASK SUCCESS';

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
  String get finance_recurring_income => 'Recurring income';

  @override
  String get finance_recurring_interval => 'Repeat every';

  @override
  String get finance_fixed_income_title => 'Fixed income';

  @override
  String get finance_fixed_income_subtitle =>
      'Salary, rent received, and other steady income';

  @override
  String get finance_fixed_income_monthly_total => 'Monthly total';

  @override
  String get finance_fixed_income_empty => 'No fixed income yet';

  @override
  String get finance_fixed_income_add => 'Add fixed income';

  @override
  String get finance_fixed_income_new => 'New fixed income';

  @override
  String get finance_fixed_income_edit => 'Edit fixed income';

  @override
  String get finance_fixed_income_name => 'Income name';

  @override
  String get finance_fixed_income_next => 'Next payout';

  @override
  String get finance_fixed_income_delete_confirm =>
      'Remove this fixed income schedule?';

  @override
  String get finance_insight_title => 'Analysis';

  @override
  String get finance_insight_suggestions => 'Suggestions';

  @override
  String get finance_insight_enter_amount =>
      'Enter an amount to preview how this affects your month.';

  @override
  String finance_insight_fixed_after(String amount) {
    return 'After saving: about $amount/month in fixed income.';
  }

  @override
  String finance_insight_covers_spending(String percent, String spent) {
    return 'Covers about $percent% of spending logged this month ($spent).';
  }

  @override
  String finance_insight_shortfall(String amount) {
    return 'Still about $amount short vs monthly spending.';
  }

  @override
  String finance_insight_surplus(String amount) {
    return 'Roughly $amount/month left after typical spending.';
  }

  @override
  String finance_insight_duplicate_fixed(String name) {
    return 'You already have fixed income in “$name” — avoid double counting.';
  }

  @override
  String finance_insight_expense_share(String percent) {
    return 'This would be about $percent% of spending this month.';
  }

  @override
  String get finance_insight_expense_large =>
      'Large one-off expense — double-check the category.';

  @override
  String finance_insight_income_share(String percent) {
    return 'Adds about $percent% to income logged this month.';
  }

  @override
  String finance_insight_recurring_equiv(String amount) {
    return 'As recurring: about $amount/month on top of fixed income.';
  }

  @override
  String finance_insight_savings_total(String amount) {
    return 'Savings balance would reach about $amount.';
  }

  @override
  String get finance_interval_weekly => 'Week';

  @override
  String get finance_interval_monthly => 'Month';

  @override
  String get finance_interval_yearly => 'Year';

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
  String get finance_daily_report_title => 'Daily report';

  @override
  String get finance_daily_report_reminder => 'Daily reminder';

  @override
  String get finance_daily_report_reminder_subtitle =>
      'Local notification that opens this report';

  @override
  String get finance_daily_report_open => 'Open daily report';

  @override
  String get finance_daily_report_income => 'Income';

  @override
  String get finance_daily_report_expense => 'Expenses';

  @override
  String get finance_daily_report_net => 'Net';

  @override
  String get finance_daily_report_spending_by_category =>
      'Spending by category';

  @override
  String get finance_daily_report_today_transactions => 'Today\'s activity';

  @override
  String get finance_daily_report_empty_day =>
      'No transactions for this day yet.';

  @override
  String get finance_daily_report_notifications_off =>
      'Enable system notifications in Settings to use daily reminders.';

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
  String get finance_subscriptions_active_header => 'ACTIVE SUBSCRIPTIONS';

  @override
  String get finance_subscriptions_monthly_total => 'MONTHLY TOTAL';

  @override
  String get finance_subscriptions_next_month_header => 'PLAN NEXT MONTH';

  @override
  String get finance_subscriptions_next_month_total => 'PLANNED TOTAL';

  @override
  String get finance_subscriptions_next_month_empty =>
      'No subscription charges scheduled for next month.';

  @override
  String get finance_subscriptions_next_month_remove_tooltip =>
      'Remove from this month\'s plan';

  @override
  String get finance_subscriptions_next_month_remove_title =>
      'REMOVE FROM PLAN';

  @override
  String get finance_subscriptions_next_month_remove_message =>
      'This only removes the charge from next month\'s plan. Your subscription stays active and will show again when that billing month arrives.';

  @override
  String get finance_subscriptions_next_month_remove_confirm => 'REMOVE';

  @override
  String get finance_subscriptions_next_month_remove_action =>
      'REMOVE FROM PLAN';

  @override
  String get finance_subscription_due_today => 'DUE TODAY';

  @override
  String finance_subscription_days_left(int days) {
    return '$days DAYS LEFT';
  }

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
  String get finance_cat_impulse => 'Impulse win';

  @override
  String get finance_quick_save_title => 'Log savings';

  @override
  String get finance_quick_save_subtitle =>
      'Money you set aside—often because you said no to spending.';

  @override
  String get finance_quick_note_label => 'What you didn’t buy (optional)';

  @override
  String get finance_quick_full_form => 'All fields';

  @override
  String get finance_quick_log => 'Save';

  @override
  String get finance_quick_chip_impulse => 'Resisted urge';

  @override
  String get finance_quick_chip_coffee => 'Skipped treat';

  @override
  String get finance_quick_chip_shopping => 'Walked away';

  @override
  String get finance_quick_chip_sale => 'Passed on sale';

  @override
  String get finance_quick_chip_goal => 'To a goal';

  @override
  String get finance_quick_chip_emergency => 'Safety net';

  @override
  String get finance_quick_desc_impulse => 'Resisted an impulse buy';

  @override
  String get finance_quick_desc_coffee => 'Skipped a coffee or snack run';

  @override
  String get finance_quick_desc_shopping => 'Walked away from a purchase';

  @override
  String get finance_quick_desc_sale => 'Didn’t chase a sale';

  @override
  String get finance_quick_desc_goal => 'Stashed toward a goal';

  @override
  String get finance_quick_desc_emergency => 'Added to emergency fund';

  @override
  String get finance_quick_affirm_impulse => 'You just paid your future self.';

  @override
  String get finance_quick_affirm_coffee => 'Small skip, big discipline.';

  @override
  String get finance_quick_affirm_shopping => 'You chose calm over cart.';

  @override
  String get finance_quick_affirm_sale =>
      'You didn’t let a discount decide for you.';

  @override
  String get finance_quick_affirm_goal => 'One step closer.';

  @override
  String get finance_quick_affirm_emergency => 'Your safety net got stronger.';

  @override
  String get finance_quick_affirm_default => 'Saved. Consistency compounds.';

  @override
  String get finance_quick_chip_custom => 'Custom';

  @override
  String get finance_award_unlocked => 'AWARD UNLOCKED';

  @override
  String get finance_award_first_save_title => 'First Brick Laid';

  @override
  String get finance_award_first_save_desc =>
      'You logged your first savings entry.';

  @override
  String get finance_award_three_streak_title => 'Three in a Row';

  @override
  String get finance_award_three_streak_desc =>
      'Three days in a row choosing to save.';

  @override
  String get finance_award_seven_streak_title => 'Iron Will Week';

  @override
  String get finance_award_seven_streak_desc =>
      'Seven consecutive days of saving.';

  @override
  String get finance_award_thirty_streak_title => 'Compounding Mind';

  @override
  String get finance_award_thirty_streak_desc =>
      'Thirty days of showing up for yourself.';

  @override
  String get finance_award_hundred_title => 'First Hundred';

  @override
  String get finance_award_hundred_desc =>
      'Your lifetime savings log crossed a hundred.';

  @override
  String get finance_award_thousand_title => 'Four Figures';

  @override
  String get finance_award_thousand_desc =>
      'Over a thousand set aside. That’s momentum.';

  @override
  String get finance_award_impulse_ten_title => 'Master of Urges';

  @override
  String get finance_award_impulse_ten_desc =>
      'Ten impulse wins logged. Your wiring is changing.';

  @override
  String finance_streak_best(int count) {
    return 'Best: $count days';
  }

  @override
  String get finance_streak_day_one => 'Start the chain';

  @override
  String get finance_streak_keep => 'Don’t break it';

  @override
  String get finance_streak_strong => 'You’re building something real.';

  @override
  String get finance_overview_streak_accessibility => 'Open savings streak';

  @override
  String get finance_streak_label => 'STREAK';

  @override
  String finance_streak_days(int count) {
    return '$count day streak';
  }

  @override
  String get finance_quick_mood_prompt => 'How do you feel right now?';

  @override
  String get finance_quick_why_label => 'Why this save?';

  @override
  String get finance_cat_crypto => 'Crypto';

  @override
  String get finance_cat_stock => 'Saving';

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
  String get ssh_connect_host_first =>
      'Connect to a host first to manage live sessions.';

  @override
  String get ssh_cursor_api_title => 'Cursor API';

  @override
  String get ssh_cursor_api_subtitle =>
      'Save your API key to drive cursor-agent on the remote host.';

  @override
  String get ssh_cursor_api_key_hint => 'cursor_…';

  @override
  String get ssh_cursor_api_key_stored => 'API key saved on this device.';

  @override
  String get ssh_cursor_api_save => 'Save key';

  @override
  String get ssh_cursor_api_test => 'Test connection';

  @override
  String get ssh_cursor_api_open_terminal => 'Open SSH (Cursor mode)';

  @override
  String get ssh_cursor_api_saved => 'Cursor API key saved.';

  @override
  String get ssh_cursor_api_test_ok => 'Cursor API key is valid.';

  @override
  String get ssh_cursor_api_missing_key =>
      'Enter or save a Cursor API key first.';

  @override
  String get cursor_hub_title => 'Cursor';

  @override
  String get cursor_hub_page_subtitle =>
      'Control Cursor on your Mac via My Machines and Cloud Agents — no SSH required.';

  @override
  String get cursor_hub_canvas_subtitle =>
      'My Machines worker, API tasks, and agents dashboard';

  @override
  String get cursor_hub_integration_subtitle =>
      'API key, worker setup, send tasks from your phone';

  @override
  String get cursor_hub_section_title => 'AI & automation';

  @override
  String get cursor_hub_key_ready => 'API key verified';

  @override
  String get cursor_hub_open_full => 'Open Cursor Hub';

  @override
  String get cursor_hub_open_agents => 'Open Agents';

  @override
  String get cursor_hub_worker_title => 'My Machine worker';

  @override
  String get cursor_hub_worker_body =>
      'On your Mac, run this in Terminal and keep it open. Your machine then appears at cursor.com/agents.';

  @override
  String get cursor_hub_copy_worker_cmd => 'Copy command';

  @override
  String get cursor_hub_worker_copied => 'Copied: agent worker start';

  @override
  String get cursor_hub_send_title => 'Send a task';

  @override
  String get cursor_hub_target_machine => 'My Mac';

  @override
  String get cursor_hub_target_cloud => 'Cloud repo';

  @override
  String get cursor_hub_machine_name => 'Machine name (optional)';

  @override
  String get cursor_hub_machine_name_hint =>
      'As shown in Agents environment dropdown';

  @override
  String get cursor_hub_pick_repo => 'Your repositories';

  @override
  String get cursor_hub_refresh_repos => 'Refresh repo list';

  @override
  String get cursor_hub_repos_empty =>
      'No repos found. Enter a URL below or run on Mac to scan ~/Code.';

  @override
  String get cursor_hub_usage_limit =>
      'Cloud agent blocked: enable usage-based pricing on cursor.com (need ~\$2 spend limit). Use My Mac mode instead.';

  @override
  String get cursor_hub_repo_url => 'GitHub repo URL';

  @override
  String get cursor_hub_prompt_label => 'What should the agent do?';

  @override
  String get cursor_hub_send_task => 'Send to Cursor';

  @override
  String get cursor_hub_task_sent => 'Task sent — opening agent…';

  @override
  String cursor_hub_task_failed(String reason) {
    return 'Could not start agent: $reason';
  }

  @override
  String get cursor_hub_recent_title => 'Recent agents';

  @override
  String get island_cursor_ssh_standby => 'Awaiting SSH link';

  @override
  String get island_cursor_no_api_key => 'No API key';

  @override
  String ssh_cursor_api_test_fail(String reason) {
    return 'Connection failed: $reason';
  }

  @override
  String get ssh_go_to_terminal => 'GO TO TERMINAL';

  @override
  String get ssh_no_tmux_sessions => 'No active tmux sessions found.';

  @override
  String get journal => 'Journal';

  @override
  String get social_notes => 'Mind Notes';

  @override
  String get btn_send_feedback => 'Send Feedback';

  @override
  String get feedback_subtitle => 'Report issues or suggest features';

  @override
  String get sync_engine_title => 'Sync Engine';

  @override
  String get system_health => 'SYSTEM HEALTH';

  @override
  String get uptime => 'UPTIME';

  @override
  String get sync_method => 'SYNC METHOD';

  @override
  String get refresh_rate => 'REFRESH RATE';

  @override
  String get initialize_drive => 'INITIALIZE DRIVE';

  @override
  String get test_connection => 'TEST CONNECTION';

  @override
  String get recent_activity => 'RECENT ACTIVITY';

  @override
  String get live_logs => 'LIVE LOGS';

  @override
  String get select_folder => 'SELECT FOLDER';

  @override
  String get my_drive => 'My Drive';

  @override
  String get breadcrumb_separator => '>';

  @override
  String get drive_notion_complete => 'Drive → Notion Complete';

  @override
  String get scheduled_sweep => 'Scheduled Sweep';

  @override
  String get standby => 'STANDBY';

  @override
  String get target_folder_id => 'TARGET FOLDER ID';

  @override
  String get internal_integration_token => 'INTERNAL INTEGRATION TOKEN';

  @override
  String get database_schema_id => 'DATABASE SCHEMA ID';

  @override
  String get add_widget => 'Add Widget';

  @override
  String get app_shortcut => 'App Shortcut';

  @override
  String get web_widget => 'Web Widget';

  @override
  String get please_select_app_page => 'Please select an app page';

  @override
  String get widget_added_success => 'Widget added successfully';

  @override
  String error_adding_widget(String error) {
    return 'Error adding widget: $error';
  }

  @override
  String get please_select_plugin => 'Please select a plugin';

  @override
  String get please_fill_all_fields => 'Please fill in all fields';

  @override
  String get widget_name_hint => 'Widget Name (e.g. Facebook)';

  @override
  String get url_hint => 'URL (e.g. facebook.com)';

  @override
  String get plugins => 'Plugins';

  @override
  String get custom_url => 'Custom URL';

  @override
  String get settings_title => 'Settings';

  @override
  String get mind_latest_note => 'Latest Note';

  @override
  String get common_done => 'Done';

  @override
  String get island_app_name => 'ICE GATE';

  @override
  String get island_app_blocker => 'APP BLOCKER';

  @override
  String get island_initializing => 'INITIALIZING…';

  @override
  String get island_notifications => 'NOTIFICATIONS';

  @override
  String get island_inbox => 'INBOX';

  @override
  String get island_documentation => 'DOCUMENTATION';

  @override
  String get island_canvas => 'CANVAS';

  @override
  String get island_mind => 'MIND';

  @override
  String get island_health_data => 'DATA';

  @override
  String get island_nutrition => 'NUTRITION';

  @override
  String get island_activity => 'ACTIVITY';

  @override
  String get island_hydration => 'HYDRATION';

  @override
  String get island_focus => 'FOCUS';

  @override
  String get island_steps => 'STEPS';

  @override
  String get island_vitals => 'VITALS';

  @override
  String get island_sleep => 'SLEEP';

  @override
  String get island_calories => 'CALORIES';

  @override
  String get island_spo2 => 'SpO₂';

  @override
  String get island_biometrics => 'BIOMETRICS';

  @override
  String get finance_tab_overview => 'OVERVIEW';

  @override
  String get finance_tab_history => 'HISTORY';

  @override
  String get finance_tab_daily => 'DAILY';

  @override
  String get finance_tab_daily_subtitle =>
      'Daily fun spending and income — pick a day on the calendar.';

  @override
  String get finance_tab_achievements => 'ACHIEVEMENTS';

  @override
  String get finance_achievements_subtitle =>
      'Major financial wins by month and year.';

  @override
  String get finance_period_month => 'Month';

  @override
  String get finance_period_year => 'Year';

  @override
  String get finance_daily_in => 'Money in';

  @override
  String get finance_daily_out => 'Money out';

  @override
  String get finance_daily_empty => 'Nothing logged this day';

  @override
  String get finance_achievements_empty =>
      'No major achievements in this period yet';

  @override
  String get finance_achievements_add => 'Record achievement';

  @override
  String get finance_milestone_month_income => 'Monthly income recorded';

  @override
  String get finance_milestone_month_savings => 'Monthly savings added';

  @override
  String get finance_milestone_year_total => 'Year total income';

  @override
  String get finance_tab_billing => 'BILLING';

  @override
  String get finance_tab_saving => 'SAVINGS';

  @override
  String get island_documents => 'DOCUMENTS';

  @override
  String get island_editor => 'EDITOR';

  @override
  String get island_identity => 'IDENTITY';

  @override
  String get island_id_update => 'ID UPDATE';

  @override
  String get island_protocols => 'PROTOCOLS';

  @override
  String get island_sync_core => 'SYNC CORE';

  @override
  String get island_settings => 'SETTINGS';

  @override
  String get island_remote_ssh => 'REMOTE SSH';

  @override
  String get island_connected => 'CONNECTED';

  @override
  String get island_not_active => 'NOT ACTIVE';

  @override
  String get island_connect => 'CONNECT';

  @override
  String get island_tmux_active => 'TMUX ACTIVE';

  @override
  String get daily_loop_title => 'Today\'s loop';

  @override
  String get daily_loop_subtitle =>
      'Complete all 4 pillars to extend your streak';

  @override
  String get daily_loop_complete => 'Loop complete — you\'re on fire!';

  @override
  String daily_loop_streak(int count) {
    return '${count}d';
  }

  @override
  String daily_loop_progress(int done, int total) {
    return '$done / $total done';
  }

  @override
  String get daily_loop_health => 'Health pulse';

  @override
  String get daily_loop_finance => 'Money check';

  @override
  String get daily_loop_mind => 'Mood log';

  @override
  String get daily_loop_projects => 'Project touch';

  @override
  String get morning_loop_reminder_title => 'Morning summary';

  @override
  String get morning_loop_reminder_subtitle =>
      'Yesterday recap & today\'s motivation — open Ice Gate first each morning';

  @override
  String get morning_briefing_toggle => 'Morning summary on Home';

  @override
  String get morning_briefing_title => 'Good morning';

  @override
  String morning_briefing_title_name(String name) {
    return 'Good morning, $name';
  }

  @override
  String get morning_briefing_subtitle =>
      'Care for body and mind — then finish your 4-pillar loop today.';

  @override
  String get morning_briefing_yesterday_title => 'Yesterday';

  @override
  String get morning_briefing_yesterday_empty =>
      'A quiet day — today is a fresh start.';

  @override
  String morning_briefing_yesterday_steps(int steps) {
    return '$steps steps';
  }

  @override
  String morning_briefing_yesterday_water(int ml) {
    return '$ml ml water';
  }

  @override
  String morning_briefing_yesterday_sleep(String hours) {
    return '$hours h sleep';
  }

  @override
  String morning_briefing_yesterday_loop(int done, int total) {
    return '$done/$total pillars completed';
  }

  @override
  String get morning_briefing_motivation_title => 'Today\'s motivation';

  @override
  String get morning_briefing_motivation_empty =>
      'Yesterday was light — one small win today resets your rhythm.';

  @override
  String get morning_briefing_motivation_all_done =>
      'You closed yesterday strong — ride that momentum into today.';

  @override
  String get morning_briefing_motivation_strong =>
      'Solid progress yesterday — one more pillar today keeps the streak alive.';

  @override
  String get morning_briefing_motivation_mid =>
      'You moved forward yesterday — stack another small win this morning.';

  @override
  String get morning_briefing_motivation_low =>
      'Yesterday was a rest day — water, a walk, or a mood log is enough to begin.';

  @override
  String morning_briefing_progress(int done, int total) {
    return '$done of $total pillars done today';
  }

  @override
  String get morning_briefing_start => 'Start my day';

  @override
  String get morning_briefing_log_mood => 'Log mood first';
}
