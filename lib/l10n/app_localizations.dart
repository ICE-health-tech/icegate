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

  /// No description provided for @quick_actions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @new_label.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get new_label;

  /// No description provided for @my_projects_label.
  ///
  /// In en, this message translates to:
  /// **'My Projects'**
  String get my_projects_label;

  /// No description provided for @completed_projects_label.
  ///
  /// In en, this message translates to:
  /// **'Completed Projects'**
  String get completed_projects_label;

  /// No description provided for @active_tasks_label.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get active_tasks_label;

  /// No description provided for @recent_notes_label.
  ///
  /// In en, this message translates to:
  /// **'Recent Notes'**
  String get recent_notes_label;

  /// No description provided for @projects_tile_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get projects_tile_reminders;

  /// No description provided for @projects_tile_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get projects_tile_calendar;

  /// No description provided for @projects_tile_sdlc.
  ///
  /// In en, this message translates to:
  /// **'SDLC'**
  String get projects_tile_sdlc;

  /// No description provided for @projects_calendar_projects_created.
  ///
  /// In en, this message translates to:
  /// **'Projects created'**
  String get projects_calendar_projects_created;

  /// No description provided for @projects_calendar_day_empty.
  ///
  /// In en, this message translates to:
  /// **'No tasks or project starts on this day.'**
  String get projects_calendar_day_empty;

  /// No description provided for @projects_calendar_day_empty_not_connected.
  ///
  /// In en, this message translates to:
  /// **'No calendar connected. Use “Connect calendar” above, then sync.'**
  String get projects_calendar_day_empty_not_connected;

  /// No description provided for @projects_calendar_day_empty_other_days.
  ///
  /// In en, this message translates to:
  /// **'No events on this day. {count} events elsewhere this month — try dates highlighted on the grid.'**
  String projects_calendar_day_empty_other_days(int count);

  /// No description provided for @projects_calendar_google_events.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar'**
  String get projects_calendar_google_events;

  /// No description provided for @projects_calendar_reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get projects_calendar_reminders;

  /// No description provided for @projects_calendar_connect_google.
  ///
  /// In en, this message translates to:
  /// **'Connect Google Calendar'**
  String get projects_calendar_connect_google;

  /// No description provided for @projects_calendar_disconnect_google.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Google Calendar'**
  String get projects_calendar_disconnect_google;

  /// No description provided for @projects_calendar_google_connected.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar connected'**
  String get projects_calendar_google_connected;

  /// No description provided for @projects_calendar_sign_in_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not connect Google Calendar'**
  String get projects_calendar_sign_in_failed;

  /// No description provided for @projects_calendar_sign_in_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was cancelled'**
  String get projects_calendar_sign_in_cancelled;

  /// No description provided for @projects_calendar_scope_denied.
  ///
  /// In en, this message translates to:
  /// **'Calendar permission was not granted. Allow access in your Google account settings.'**
  String get projects_calendar_scope_denied;

  /// No description provided for @projects_calendar_api_not_enabled.
  ///
  /// In en, this message translates to:
  /// **'Google Calendar API is disabled for the macOS app (GCP project {projectId}). In Google Cloud Console, enable \"Google Calendar API\" for that project, wait a few minutes, then retry.'**
  String projects_calendar_api_not_enabled(String projectId);

  /// No description provided for @projects_calendar_insufficient_scopes.
  ///
  /// In en, this message translates to:
  /// **'Calendar access was not granted. Disconnect Google, connect again, and accept all permissions.'**
  String get projects_calendar_insufficient_scopes;

  /// No description provided for @projects_calendar_connect_hint.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google to sync all your Google calendars to the Calendar screen.'**
  String get projects_calendar_connect_hint;

  /// No description provided for @projects_calendar_add_reminder.
  ///
  /// In en, this message translates to:
  /// **'Add reminder'**
  String get projects_calendar_add_reminder;

  /// No description provided for @projects_calendar_add_event.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get projects_calendar_add_event;

  /// No description provided for @projects_calendar_event_title.
  ///
  /// In en, this message translates to:
  /// **'Event title'**
  String get projects_calendar_event_title;

  /// No description provided for @projects_calendar_event_title_required.
  ///
  /// In en, this message translates to:
  /// **'Enter an event title'**
  String get projects_calendar_event_title_required;

  /// No description provided for @projects_calendar_event_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get projects_calendar_event_start;

  /// No description provided for @projects_calendar_event_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get projects_calendar_event_end;

  /// No description provided for @projects_calendar_event_saved.
  ///
  /// In en, this message translates to:
  /// **'Event saved to calendar'**
  String get projects_calendar_event_saved;

  /// No description provided for @projects_calendar_event_moved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {time}'**
  String projects_calendar_event_moved(String time);

  /// No description provided for @projects_calendar_event_deleted.
  ///
  /// In en, this message translates to:
  /// **'Event removed'**
  String get projects_calendar_event_deleted;

  /// No description provided for @projects_calendar_event_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save event'**
  String get projects_calendar_event_failed;

  /// No description provided for @projects_calendar_edit_event.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get projects_calendar_edit_event;

  /// No description provided for @projects_calendar_delete_event.
  ///
  /// In en, this message translates to:
  /// **'Delete event'**
  String get projects_calendar_delete_event;

  /// No description provided for @projects_calendar_env_title.
  ///
  /// In en, this message translates to:
  /// **'Environment check'**
  String get projects_calendar_env_title;

  /// No description provided for @projects_calendar_env_ready.
  ///
  /// In en, this message translates to:
  /// **'Good fit — you can likely complete this now.'**
  String get projects_calendar_env_ready;

  /// No description provided for @projects_calendar_env_caution.
  ///
  /// In en, this message translates to:
  /// **'Possible, but a few factors may get in the way.'**
  String get projects_calendar_env_caution;

  /// No description provided for @projects_calendar_env_not_ready.
  ///
  /// In en, this message translates to:
  /// **'Tough right now — consider rescheduling.'**
  String get projects_calendar_env_not_ready;

  /// No description provided for @projects_calendar_env_score.
  ///
  /// In en, this message translates to:
  /// **'{score}% ready'**
  String projects_calendar_env_score(int score);

  /// No description provided for @projects_calendar_env_start_focus.
  ///
  /// In en, this message translates to:
  /// **'Start focus session'**
  String get projects_calendar_env_start_focus;

  /// No description provided for @projects_calendar_env_past.
  ///
  /// In en, this message translates to:
  /// **'This block is already over'**
  String get projects_calendar_env_past;

  /// No description provided for @projects_calendar_env_too_early.
  ///
  /// In en, this message translates to:
  /// **'Still more than 2 hours away'**
  String get projects_calendar_env_too_early;

  /// No description provided for @projects_calendar_env_starting_soon.
  ///
  /// In en, this message translates to:
  /// **'Starting within 15 minutes'**
  String get projects_calendar_env_starting_soon;

  /// No description provided for @projects_calendar_env_low_mood.
  ///
  /// In en, this message translates to:
  /// **'Recent mood is low'**
  String get projects_calendar_env_low_mood;

  /// No description provided for @projects_calendar_env_neutral_mood.
  ///
  /// In en, this message translates to:
  /// **'Mood is neutral'**
  String get projects_calendar_env_neutral_mood;

  /// No description provided for @projects_calendar_env_good_mood.
  ///
  /// In en, this message translates to:
  /// **'Mood supports focus'**
  String get projects_calendar_env_good_mood;

  /// No description provided for @projects_calendar_env_no_mood.
  ///
  /// In en, this message translates to:
  /// **'No mood logged today'**
  String get projects_calendar_env_no_mood;

  /// No description provided for @projects_calendar_env_heavy_overlap.
  ///
  /// In en, this message translates to:
  /// **'Heavy schedule overlap'**
  String get projects_calendar_env_heavy_overlap;

  /// No description provided for @projects_calendar_env_some_overlap.
  ///
  /// In en, this message translates to:
  /// **'Another event overlaps'**
  String get projects_calendar_env_some_overlap;

  /// No description provided for @projects_calendar_env_focus_fatigue.
  ///
  /// In en, this message translates to:
  /// **'Already focused 2+ hours today'**
  String get projects_calendar_env_focus_fatigue;

  /// No description provided for @projects_calendar_env_low_sleep.
  ///
  /// In en, this message translates to:
  /// **'Low sleep last night'**
  String get projects_calendar_env_low_sleep;

  /// No description provided for @projects_calendar_env_good_sleep.
  ///
  /// In en, this message translates to:
  /// **'Well rested'**
  String get projects_calendar_env_good_sleep;

  /// No description provided for @projects_calendar_edit_reminder.
  ///
  /// In en, this message translates to:
  /// **'Edit reminder'**
  String get projects_calendar_edit_reminder;

  /// No description provided for @projects_calendar_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get projects_calendar_save;

  /// No description provided for @projects_calendar_select_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get projects_calendar_select_calendar;

  /// No description provided for @projects_calendar_tap_day_add_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap the selected day again to add an event'**
  String get projects_calendar_tap_day_add_hint;

  /// No description provided for @projects_calendar_hold_day_add_hint.
  ///
  /// In en, this message translates to:
  /// **'Hold a day to add an event'**
  String get projects_calendar_hold_day_add_hint;

  /// No description provided for @projects_calendar_timeline_empty.
  ///
  /// In en, this message translates to:
  /// **'No timed events this day'**
  String get projects_calendar_timeline_empty;

  /// No description provided for @projects_calendar_timeline_tap_slot.
  ///
  /// In en, this message translates to:
  /// **'Tap hour to add · tap event to edit · drag to move (↑↓ + Enter on desktop, hold on mobile)'**
  String get projects_calendar_timeline_tap_slot;

  /// No description provided for @projects_calendar_scroll_for_more.
  ///
  /// In en, this message translates to:
  /// **'Scroll for tasks'**
  String get projects_calendar_scroll_for_more;

  /// No description provided for @projects_calendar_drag_hint_desktop.
  ///
  /// In en, this message translates to:
  /// **'Drag to reschedule. Arrow keys adjust time, Enter confirms, Escape cancels.'**
  String get projects_calendar_drag_hint_desktop;

  /// No description provided for @projects_calendar_drag_hint_mobile.
  ///
  /// In en, this message translates to:
  /// **'Long press, then drag to another time slot.'**
  String get projects_calendar_drag_hint_mobile;

  /// No description provided for @projects_calendar_drag_move_to.
  ///
  /// In en, this message translates to:
  /// **'Move to {time}'**
  String projects_calendar_drag_move_to(String time);

  /// No description provided for @projects_calendar_timeline_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove from timeline'**
  String get projects_calendar_timeline_remove;

  /// No description provided for @projects_calendar_timeline_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from this day\'s timeline?'**
  String projects_calendar_timeline_remove_confirm(String title);

  /// No description provided for @projects_calendar_day_timeline.
  ///
  /// In en, this message translates to:
  /// **'Daily timeline'**
  String get projects_calendar_day_timeline;

  /// No description provided for @projects_calendar_reminder_title.
  ///
  /// In en, this message translates to:
  /// **'Reminder title'**
  String get projects_calendar_reminder_title;

  /// No description provided for @projects_calendar_sync_google.
  ///
  /// In en, this message translates to:
  /// **'Sync events'**
  String get projects_calendar_sync_google;

  /// No description provided for @projects_calendar_all_day.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get projects_calendar_all_day;

  /// No description provided for @projects_calendar_integrations.
  ///
  /// In en, this message translates to:
  /// **'Calendar connections'**
  String get projects_calendar_integrations;

  /// No description provided for @projects_calendar_connect_device.
  ///
  /// In en, this message translates to:
  /// **'Connect device calendar'**
  String get projects_calendar_connect_device;

  /// No description provided for @projects_calendar_connect_apple.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Calendar'**
  String get projects_calendar_connect_apple;

  /// No description provided for @projects_calendar_disconnect_device.
  ///
  /// In en, this message translates to:
  /// **'Disconnect device calendar'**
  String get projects_calendar_disconnect_device;

  /// No description provided for @projects_calendar_disconnect_apple.
  ///
  /// In en, this message translates to:
  /// **'Disconnect Apple Calendar'**
  String get projects_calendar_disconnect_apple;

  /// No description provided for @projects_calendar_device_connected.
  ///
  /// In en, this message translates to:
  /// **'Device calendar connected'**
  String get projects_calendar_device_connected;

  /// No description provided for @projects_calendar_apple_connected.
  ///
  /// In en, this message translates to:
  /// **'Apple Calendar connected'**
  String get projects_calendar_apple_connected;

  /// No description provided for @projects_calendar_device_events.
  ///
  /// In en, this message translates to:
  /// **'Device calendar'**
  String get projects_calendar_device_events;

  /// No description provided for @projects_calendar_apple_events.
  ///
  /// In en, this message translates to:
  /// **'Apple Calendar'**
  String get projects_calendar_apple_events;

  /// No description provided for @projects_calendar_device_hint.
  ///
  /// In en, this message translates to:
  /// **'Allow calendar access to show events from calendars on this device.'**
  String get projects_calendar_device_hint;

  /// No description provided for @projects_calendar_sync_device.
  ///
  /// In en, this message translates to:
  /// **'Sync device events'**
  String get projects_calendar_sync_device;

  /// No description provided for @projects_calendar_device_denied.
  ///
  /// In en, this message translates to:
  /// **'Calendar access was denied. Enable it in Settings.'**
  String get projects_calendar_device_denied;

  /// No description provided for @integration_hub_title.
  ///
  /// In en, this message translates to:
  /// **'Integration Hub'**
  String get integration_hub_title;

  /// No description provided for @integration_hub_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Calendars, health platforms, and device sensors — one connection center.'**
  String get integration_hub_subtitle;

  /// No description provided for @integration_hub_google_fit.
  ///
  /// In en, this message translates to:
  /// **'Google Fit'**
  String get integration_hub_google_fit;

  /// No description provided for @integration_hub_google_fit_hint.
  ///
  /// In en, this message translates to:
  /// **'Uses the same Google sign-in as Calendar and Drive.'**
  String get integration_hub_google_fit_hint;

  /// No description provided for @integration_hub_sensors_section.
  ///
  /// In en, this message translates to:
  /// **'Devices & sensors'**
  String get integration_hub_sensors_section;

  /// No description provided for @integration_hub_open_sensor_hub.
  ///
  /// In en, this message translates to:
  /// **'Open Sensor Hub'**
  String get integration_hub_open_sensor_hub;

  /// No description provided for @integration_hub_sensor_hub_hint.
  ///
  /// In en, this message translates to:
  /// **'Wearables, IoT pipelines, SSH streams, and Huawei setup.'**
  String get integration_hub_sensor_hub_hint;

  /// No description provided for @integration_hub_huawei_sensor_hint.
  ///
  /// In en, this message translates to:
  /// **'Set up Huawei credentials in Sensor Hub first.'**
  String get integration_hub_huawei_sensor_hint;

  /// No description provided for @projects_calendar_all_calendars_events.
  ///
  /// In en, this message translates to:
  /// **'All calendars'**
  String get projects_calendar_all_calendars_events;

  /// No description provided for @projects_calendar_synced_count.
  ///
  /// In en, this message translates to:
  /// **'Loaded {count} events this month'**
  String projects_calendar_synced_count(int count);

  /// No description provided for @projects_calendar_sync_empty_month.
  ///
  /// In en, this message translates to:
  /// **'Connected — no events this month. Try another month or check Google Calendar.'**
  String get projects_calendar_sync_empty_month;

  /// No description provided for @integration_hub_calendars_section.
  ///
  /// In en, this message translates to:
  /// **'Calendars'**
  String get integration_hub_calendars_section;

  /// No description provided for @integration_hub_health_section.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get integration_hub_health_section;

  /// No description provided for @integration_hub_notes_section.
  ///
  /// In en, this message translates to:
  /// **'Notes & documents'**
  String get integration_hub_notes_section;

  /// No description provided for @integration_hub_google_drive_hint.
  ///
  /// In en, this message translates to:
  /// **'Sync project notes and vault files from Google Drive.'**
  String get integration_hub_google_drive_hint;

  /// No description provided for @integration_hub_notion_hint.
  ///
  /// In en, this message translates to:
  /// **'Import shared Notion pages and databases into your vault.'**
  String get integration_hub_notion_hint;

  /// No description provided for @integration_hub_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get integration_hub_connect;

  /// No description provided for @integration_hub_status_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get integration_hub_status_connected;

  /// No description provided for @integration_hub_apple_health.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get integration_hub_apple_health;

  /// No description provided for @integration_hub_apple_health_hint.
  ///
  /// In en, this message translates to:
  /// **'Steps, sleep, heart rate, and more from HealthKit.'**
  String get integration_hub_apple_health_hint;

  /// No description provided for @integration_hub_huawei_health.
  ///
  /// In en, this message translates to:
  /// **'Huawei Health'**
  String get integration_hub_huawei_health;

  /// No description provided for @integration_hub_huawei_health_hint.
  ///
  /// In en, this message translates to:
  /// **'Sync from Huawei cloud credentials.'**
  String get integration_hub_huawei_health_hint;

  /// No description provided for @integration_hub_phase2_notice.
  ///
  /// In en, this message translates to:
  /// **'Calendar and Google sign-in work here. Huawei credentials: use Sensor Hub below.'**
  String get integration_hub_phase2_notice;

  /// No description provided for @integration_hub_sign_in_required.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your icegate account first, then connect integrations.'**
  String get integration_hub_sign_in_required;

  /// No description provided for @integration_hub_health_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'This health source is not available yet.'**
  String get integration_hub_health_coming_soon;

  /// No description provided for @integration_hub_open.
  ///
  /// In en, this message translates to:
  /// **'Open Integration Hub'**
  String get integration_hub_open;

  /// No description provided for @projects_tile_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get projects_tile_focus;

  /// No description provided for @projects_tile_pomodoro.
  ///
  /// In en, this message translates to:
  /// **'Pomodoro'**
  String get projects_tile_pomodoro;

  /// No description provided for @projects_tile_canvas.
  ///
  /// In en, this message translates to:
  /// **'Canvas'**
  String get projects_tile_canvas;

  /// No description provided for @projects_tile_whiteboard.
  ///
  /// In en, this message translates to:
  /// **'Whiteboard'**
  String get projects_tile_whiteboard;

  /// No description provided for @projects_whiteboard_clear_title.
  ///
  /// In en, this message translates to:
  /// **'Clear whiteboard?'**
  String get projects_whiteboard_clear_title;

  /// No description provided for @projects_whiteboard_clear_message.
  ///
  /// In en, this message translates to:
  /// **'All strokes will be removed. This cannot be undone.'**
  String get projects_whiteboard_clear_message;

  /// No description provided for @projects_whiteboard_clear_confirm.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get projects_whiteboard_clear_confirm;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @projects_plan_section_title.
  ///
  /// In en, this message translates to:
  /// **'Schedule planner'**
  String get projects_plan_section_title;

  /// No description provided for @projects_diagrams_title.
  ///
  /// In en, this message translates to:
  /// **'Project diagrams'**
  String get projects_diagrams_title;

  /// No description provided for @projects_diagrams_empty.
  ///
  /// In en, this message translates to:
  /// **'No flowcharts yet. Tap + to pick a project and start drawing.'**
  String get projects_diagrams_empty;

  /// No description provided for @projects_diagrams_new.
  ///
  /// In en, this message translates to:
  /// **'New diagram'**
  String get projects_diagrams_new;

  /// No description provided for @projects_diagrams_pick_project.
  ///
  /// In en, this message translates to:
  /// **'Choose a project'**
  String get projects_diagrams_pick_project;

  /// No description provided for @projects_diagrams_no_projects.
  ///
  /// In en, this message translates to:
  /// **'Create a project first.'**
  String get projects_diagrams_no_projects;

  /// No description provided for @projects_diagrams_steps.
  ///
  /// In en, this message translates to:
  /// **'steps'**
  String get projects_diagrams_steps;

  /// No description provided for @plan_workspace_breadcrumb.
  ///
  /// In en, this message translates to:
  /// **'WORKSPACE • PROJECTS'**
  String get plan_workspace_breadcrumb;

  /// No description provided for @plan_schedule_card_title.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get plan_schedule_card_title;

  /// No description provided for @plan_schedule_empty.
  ///
  /// In en, this message translates to:
  /// **'No steps yet.'**
  String get plan_schedule_empty;

  /// No description provided for @plan_focus_notes_title.
  ///
  /// In en, this message translates to:
  /// **'Focus Notes'**
  String get plan_focus_notes_title;

  /// No description provided for @plan_notes_hint.
  ///
  /// In en, this message translates to:
  /// **'Type notes here…'**
  String get plan_notes_hint;

  /// No description provided for @plan_add_step.
  ///
  /// In en, this message translates to:
  /// **'Add step'**
  String get plan_add_step;

  /// No description provided for @plan_drop_steps.
  ///
  /// In en, this message translates to:
  /// **'Drop steps here'**
  String get plan_drop_steps;

  /// No description provided for @plan_add_first_step.
  ///
  /// In en, this message translates to:
  /// **'Add first step'**
  String get plan_add_first_step;

  /// No description provided for @plan_add_block_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule block'**
  String get plan_add_block_schedule;

  /// No description provided for @plan_add_block_notes.
  ///
  /// In en, this message translates to:
  /// **'Focus notes block'**
  String get plan_add_block_notes;

  /// No description provided for @plan_add_block_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals block'**
  String get plan_add_block_goals;

  /// No description provided for @plan_add_block_flow.
  ///
  /// In en, this message translates to:
  /// **'Process block'**
  String get plan_add_block_flow;

  /// No description provided for @plan_connect_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap a source block, then tap a target block to connect.'**
  String get plan_connect_hint;

  /// No description provided for @plan_link_added.
  ///
  /// In en, this message translates to:
  /// **'Blocks connected'**
  String get plan_link_added;

  /// No description provided for @plan_goals_empty.
  ///
  /// In en, this message translates to:
  /// **'No goals yet.'**
  String get plan_goals_empty;

  /// No description provided for @plan_add_goal.
  ///
  /// In en, this message translates to:
  /// **'Add goal'**
  String get plan_add_goal;

  /// No description provided for @plan_manage_blocks.
  ///
  /// In en, this message translates to:
  /// **'Manage blocks'**
  String get plan_manage_blocks;

  /// No description provided for @projects_tile_social_blocker.
  ///
  /// In en, this message translates to:
  /// **'Social Blocker'**
  String get projects_tile_social_blocker;

  /// No description provided for @social_shield_turn_on.
  ///
  /// In en, this message translates to:
  /// **'Turn on Shield'**
  String get social_shield_turn_on;

  /// No description provided for @social_shield_subtitle_no_auth.
  ///
  /// In en, this message translates to:
  /// **'Tap row to grant Screen Time (for rules)'**
  String get social_shield_subtitle_no_auth;

  /// No description provided for @social_shield_subtitle_pick_apps.
  ///
  /// In en, this message translates to:
  /// **'Tap row to choose apps — blocking follows rules'**
  String get social_shield_subtitle_pick_apps;

  /// No description provided for @social_shield_subtitle_ready.
  ///
  /// In en, this message translates to:
  /// **'On — blocking runs when your rules are active'**
  String get social_shield_subtitle_ready;

  /// No description provided for @social_shield_subtitle_off.
  ///
  /// In en, this message translates to:
  /// **'Off — schedules and focus rules are paused'**
  String get social_shield_subtitle_off;

  /// No description provided for @social_shield_choose_apps.
  ///
  /// In en, this message translates to:
  /// **'Choose apps to block'**
  String get social_shield_choose_apps;

  /// No description provided for @social_shield_choose_apps_done.
  ///
  /// In en, this message translates to:
  /// **'Tap to change blocked apps'**
  String get social_shield_choose_apps_done;

  /// No description provided for @social_shield_pick_apps_required.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one app to block (or turn Shield off).'**
  String get social_shield_pick_apps_required;

  /// No description provided for @social_shield_apps_saved.
  ///
  /// In en, this message translates to:
  /// **'Blocked apps updated.'**
  String get social_shield_apps_saved;

  /// No description provided for @social_shield_unsupported_platform.
  ///
  /// In en, this message translates to:
  /// **'App blocking is only on iOS and macOS.'**
  String get social_shield_unsupported_platform;

  /// No description provided for @projects_plugin_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get projects_plugin_open;

  /// No description provided for @projects_plugin_location_tracker.
  ///
  /// In en, this message translates to:
  /// **'Location Tracker'**
  String get projects_plugin_location_tracker;

  /// No description provided for @projects_plugin_live_map.
  ///
  /// In en, this message translates to:
  /// **'Live Map'**
  String get projects_plugin_live_map;

  /// No description provided for @projects_remove_plugin_title.
  ///
  /// In en, this message translates to:
  /// **'Remove shortcut?'**
  String get projects_remove_plugin_title;

  /// No description provided for @projects_remove_plugin_body.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from quick actions?'**
  String projects_remove_plugin_body(String name);

  /// No description provided for @projects_remove_plugin_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get projects_remove_plugin_confirm;

  /// No description provided for @integrations_title.
  ///
  /// In en, this message translates to:
  /// **'Integrations'**
  String get integrations_title;

  /// No description provided for @integrations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your document sources'**
  String get integrations_subtitle;

  /// No description provided for @integrations_active_services.
  ///
  /// In en, this message translates to:
  /// **'Active Services'**
  String get integrations_active_services;

  /// No description provided for @integrations_total_notes.
  ///
  /// In en, this message translates to:
  /// **'Total Notes'**
  String get integrations_total_notes;

  /// No description provided for @integrations_search_hint.
  ///
  /// In en, this message translates to:
  /// **'Search sources...'**
  String get integrations_search_hint;

  /// No description provided for @integrations_enabled_connections.
  ///
  /// In en, this message translates to:
  /// **'ENABLED CONNECTIONS'**
  String get integrations_enabled_connections;

  /// No description provided for @integrations_filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get integrations_filters;

  /// No description provided for @integrations_internal_notes.
  ///
  /// In en, this message translates to:
  /// **'Internal Notes'**
  String get integrations_internal_notes;

  /// No description provided for @integrations_primary_vault.
  ///
  /// In en, this message translates to:
  /// **'Primary Vault (Local)'**
  String get integrations_primary_vault;

  /// No description provided for @integrations_explore.
  ///
  /// In en, this message translates to:
  /// **'Explore'**
  String get integrations_explore;

  /// No description provided for @integrations_google_drive.
  ///
  /// In en, this message translates to:
  /// **'Google Drive'**
  String get integrations_google_drive;

  /// No description provided for @integrations_synced_cloud.
  ///
  /// In en, this message translates to:
  /// **'Synced with Cloud'**
  String get integrations_synced_cloud;

  /// No description provided for @integrations_cloud_storage.
  ///
  /// In en, this message translates to:
  /// **'Cloud Storage'**
  String get integrations_cloud_storage;

  /// No description provided for @integrations_sync_now.
  ///
  /// In en, this message translates to:
  /// **'Sync Now'**
  String get integrations_sync_now;

  /// No description provided for @integrations_connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get integrations_connect;

  /// No description provided for @integrations_notion_sync.
  ///
  /// In en, this message translates to:
  /// **'Notion Sync'**
  String get integrations_notion_sync;

  /// No description provided for @integrations_database_pipeline.
  ///
  /// In en, this message translates to:
  /// **'Database Pipeline'**
  String get integrations_database_pipeline;

  /// No description provided for @integrations_fetch.
  ///
  /// In en, this message translates to:
  /// **'Fetch'**
  String get integrations_fetch;

  /// No description provided for @integrations_setup.
  ///
  /// In en, this message translates to:
  /// **'Setup'**
  String get integrations_setup;

  /// No description provided for @integrations_slack_docs.
  ///
  /// In en, this message translates to:
  /// **'Slack Docs'**
  String get integrations_slack_docs;

  /// No description provided for @integrations_shared_channels.
  ///
  /// In en, this message translates to:
  /// **'Shared Channels'**
  String get integrations_shared_channels;

  /// No description provided for @integrations_notify_me.
  ///
  /// In en, this message translates to:
  /// **'Notify Me'**
  String get integrations_notify_me;

  /// No description provided for @integrations_notion_config_title.
  ///
  /// In en, this message translates to:
  /// **'Notion Configuration'**
  String get integrations_notion_config_title;

  /// No description provided for @integrations_notion_secret_label.
  ///
  /// In en, this message translates to:
  /// **'Internal Integration Secret'**
  String get integrations_notion_secret_label;

  /// No description provided for @integrations_save_fetch.
  ///
  /// In en, this message translates to:
  /// **'Save & Fetch'**
  String get integrations_save_fetch;

  /// No description provided for @integrations_marketplace_soon.
  ///
  /// In en, this message translates to:
  /// **'Source Marketplace coming soon!'**
  String get integrations_marketplace_soon;

  /// No description provided for @vault_breadcrumb_root.
  ///
  /// In en, this message translates to:
  /// **'Vault'**
  String get vault_breadcrumb_root;

  /// No description provided for @vault_section_folders.
  ///
  /// In en, this message translates to:
  /// **'Folders'**
  String get vault_section_folders;

  /// No description provided for @vault_section_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get vault_section_notes;

  /// No description provided for @vault_section_media.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get vault_section_media;

  /// No description provided for @vault_section_other.
  ///
  /// In en, this message translates to:
  /// **'Other files'**
  String get vault_section_other;

  /// No description provided for @vault_search_files.
  ///
  /// In en, this message translates to:
  /// **'Search in this folder…'**
  String get vault_search_files;

  /// No description provided for @vault_empty_folder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get vault_empty_folder;

  /// No description provided for @vault_stats_folders.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 folder} other{{count} folders}}'**
  String vault_stats_folders(int count);

  /// No description provided for @vault_stats_notes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 note} other{{count} notes}}'**
  String vault_stats_notes(int count);

  /// No description provided for @vault_stats_media.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file} other{{count} files}}'**
  String vault_stats_media(int count);

  /// No description provided for @projects_workspace_empty.
  ///
  /// In en, this message translates to:
  /// **'No workspace has been set up yet.'**
  String get projects_workspace_empty;

  /// No description provided for @projects_workspace_start.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get projects_workspace_start;

  /// No description provided for @project_drive_sync.
  ///
  /// In en, this message translates to:
  /// **'Cloud Sync'**
  String get project_drive_sync;

  /// No description provided for @project_drive_sync_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Sync with Google Drive'**
  String get project_drive_sync_tooltip;

  /// No description provided for @project_sync_success.
  ///
  /// In en, this message translates to:
  /// **'Sync completed successfully!'**
  String get project_sync_success;

  /// No description provided for @project_sync_failed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed: {error}'**
  String project_sync_failed(String error);

  /// No description provided for @project_created_msg.
  ///
  /// In en, this message translates to:
  /// **'Project created with all components!'**
  String get project_created_msg;

  /// No description provided for @project_create_failed.
  ///
  /// In en, this message translates to:
  /// **'Error creating project: {error}'**
  String project_create_failed(String error);

  /// No description provided for @create_project_title.
  ///
  /// In en, this message translates to:
  /// **'Create Project Widget'**
  String get create_project_title;

  /// No description provided for @project_name_label.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get project_name_label;

  /// No description provided for @project_name_required.
  ///
  /// In en, this message translates to:
  /// **'Please enter a name'**
  String get project_name_required;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @project_initial_investment_label.
  ///
  /// In en, this message translates to:
  /// **'Initial Investment'**
  String get project_initial_investment_label;

  /// No description provided for @project_internal_path_label.
  ///
  /// In en, this message translates to:
  /// **'Internal Path (Optional)'**
  String get project_internal_path_label;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'CREATE'**
  String get create;

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

  /// No description provided for @health_motivation_engine_title.
  ///
  /// In en, this message translates to:
  /// **'Motivation Engine'**
  String get health_motivation_engine_title;

  /// No description provided for @health_notification_engine_title.
  ///
  /// In en, this message translates to:
  /// **'Notification Engine'**
  String get health_notification_engine_title;

  /// No description provided for @health_notification_engine_desc.
  ///
  /// In en, this message translates to:
  /// **'{count} active reminders'**
  String health_notification_engine_desc(int count);

  /// No description provided for @health_motivation_all_done.
  ///
  /// In en, this message translates to:
  /// **'All daily targets hit—momentum is yours today.'**
  String get health_motivation_all_done;

  /// No description provided for @health_motivation_strong.
  ///
  /// In en, this message translates to:
  /// **'Strong day—keep your streak alive.'**
  String get health_motivation_strong;

  /// No description provided for @health_motivation_mid.
  ///
  /// In en, this message translates to:
  /// **'Steady progress—stack one more small win.'**
  String get health_motivation_mid;

  /// No description provided for @health_motivation_low.
  ///
  /// In en, this message translates to:
  /// **'Start with water or a short walk—small steps count.'**
  String get health_motivation_low;

  /// No description provided for @health_motivation_empty.
  ///
  /// In en, this message translates to:
  /// **'Set your goals and we\'ll coach you through the day.'**
  String get health_motivation_empty;

  /// No description provided for @health_update_weight.
  ///
  /// In en, this message translates to:
  /// **'Update Weight'**
  String get health_update_weight;

  /// No description provided for @health_smart_scale_title.
  ///
  /// In en, this message translates to:
  /// **'Smart scale'**
  String get health_smart_scale_title;

  /// No description provided for @health_smart_scale_desc.
  ///
  /// In en, this message translates to:
  /// **'Sync from Apple Health or Health Connect (Withings, Eufy, Xiaomi, etc.)'**
  String get health_smart_scale_desc;

  /// No description provided for @health_smart_scale_sync.
  ///
  /// In en, this message translates to:
  /// **'Sync smart scale'**
  String get health_smart_scale_sync;

  /// No description provided for @health_smart_scale_syncing.
  ///
  /// In en, this message translates to:
  /// **'Syncing…'**
  String get health_smart_scale_syncing;

  /// No description provided for @health_smart_scale_sync_ok.
  ///
  /// In en, this message translates to:
  /// **'Weight synced from smart scale'**
  String get health_smart_scale_sync_ok;

  /// No description provided for @health_smart_scale_sync_empty.
  ///
  /// In en, this message translates to:
  /// **'No weight found. Weigh in on your scale first, then sync.'**
  String get health_smart_scale_sync_empty;

  /// No description provided for @health_smart_scale_sync_denied.
  ///
  /// In en, this message translates to:
  /// **'Health access denied. Enable in Settings.'**
  String get health_smart_scale_sync_denied;

  /// No description provided for @health_smart_scale_desktop.
  ///
  /// In en, this message translates to:
  /// **'Smart scale sync is available on iPhone and Android only.'**
  String get health_smart_scale_desktop;

  /// No description provided for @health_smart_scale_import.
  ///
  /// In en, this message translates to:
  /// **'Import from smart scale'**
  String get health_smart_scale_import;

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
  /// **'Health'**
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
  /// **'Mind'**
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

  /// No description provided for @nutri_add_meal.
  ///
  /// In en, this message translates to:
  /// **'Add Meal'**
  String get nutri_add_meal;

  /// No description provided for @nutri_analyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing...'**
  String get nutri_analyzing;

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

  /// No description provided for @nutri_what_eat.
  ///
  /// In en, this message translates to:
  /// **'What did you eat?'**
  String get nutri_what_eat;

  /// No description provided for @nutri_save_record.
  ///
  /// In en, this message translates to:
  /// **'SAVE RECORD'**
  String get nutri_save_record;

  /// No description provided for @nutri_info_title.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION INFO'**
  String get nutri_info_title;

  /// No description provided for @nutri_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get nutri_camera;

  /// No description provided for @nutri_gallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get nutri_gallery;

  /// No description provided for @nutri_delete_meal.
  ///
  /// In en, this message translates to:
  /// **'Delete Meal'**
  String get nutri_delete_meal;

  /// No description provided for @nutri_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this meal?'**
  String get nutri_delete_confirm;

  /// No description provided for @nutri_meal_deleted.
  ///
  /// In en, this message translates to:
  /// **'Meal deleted'**
  String get nutri_meal_deleted;

  /// No description provided for @nutri_yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get nutri_yesterday;

  /// No description provided for @nutri_ai_saved_retry_later.
  ///
  /// In en, this message translates to:
  /// **'Meal saved locally. AI server unavailable — use Retry on the dashboard when it is back.'**
  String get nutri_ai_saved_retry_later;

  /// No description provided for @nutri_ai_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry AI analysis'**
  String get nutri_ai_retry;

  /// No description provided for @nutri_calories_pending.
  ///
  /// In en, this message translates to:
  /// **'Calories pending'**
  String get nutri_calories_pending;

  /// No description provided for @common_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get common_cancel;

  /// No description provided for @common_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get common_delete;

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

  /// No description provided for @health_metrics_oxygen_saturation.
  ///
  /// In en, this message translates to:
  /// **'Oxygen'**
  String get health_metrics_oxygen_saturation;

  /// No description provided for @health_spo2_page_title.
  ///
  /// In en, this message translates to:
  /// **'Blood oxygen (SpO₂)'**
  String get health_spo2_page_title;

  /// No description provided for @health_spo2_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get health_spo2_today;

  /// No description provided for @health_spo2_chart_section.
  ///
  /// In en, this message translates to:
  /// **'Today\'s chart'**
  String get health_spo2_chart_section;

  /// No description provided for @health_spo2_percent_unit.
  ///
  /// In en, this message translates to:
  /// **'% SpO₂'**
  String get health_spo2_percent_unit;

  /// No description provided for @health_spo2_latest.
  ///
  /// In en, this message translates to:
  /// **'Latest: {time}'**
  String health_spo2_latest(String time);

  /// No description provided for @health_spo2_target_line.
  ///
  /// In en, this message translates to:
  /// **'Target {n}%'**
  String health_spo2_target_line(int n);

  /// No description provided for @health_spo2_target_row.
  ///
  /// In en, this message translates to:
  /// **'Target: {n}%'**
  String health_spo2_target_row(int n);

  /// No description provided for @health_spo2_edit_target.
  ///
  /// In en, this message translates to:
  /// **'Change target'**
  String get health_spo2_edit_target;

  /// No description provided for @health_spo2_target_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'SpO₂ target'**
  String get health_spo2_target_dialog_title;

  /// No description provided for @health_spo2_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get health_spo2_save;

  /// No description provided for @health_spo2_day_avg.
  ///
  /// In en, this message translates to:
  /// **'Day average: {n}%'**
  String health_spo2_day_avg(String n);

  /// No description provided for @health_spo2_summary_min.
  ///
  /// In en, this message translates to:
  /// **'Lowest'**
  String get health_spo2_summary_min;

  /// No description provided for @health_spo2_summary_max.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get health_spo2_summary_max;

  /// No description provided for @health_spo2_educational_title.
  ///
  /// In en, this message translates to:
  /// **'About SpO₂'**
  String get health_spo2_educational_title;

  /// No description provided for @health_spo2_educational_body.
  ///
  /// In en, this message translates to:
  /// **'Normal blood oxygen saturation is often around 95–100%. These readings are for reference only and are not a substitute for professional medical advice.'**
  String get health_spo2_educational_body;

  /// No description provided for @health_spo2_motivation_peak.
  ///
  /// In en, this message translates to:
  /// **'Outstanding oxygenation—when SpO₂ stays high, focus feels sharper and breathing steadier.'**
  String get health_spo2_motivation_peak;

  /// No description provided for @health_spo2_motivation_high.
  ///
  /// In en, this message translates to:
  /// **'Strong SpO₂—great fuel for focus and a steadier mind.'**
  String get health_spo2_motivation_high;

  /// No description provided for @health_spo2_motivation_on_target.
  ///
  /// In en, this message translates to:
  /// **'You\'re meeting your target—keep breathing easy.'**
  String get health_spo2_motivation_on_target;

  /// No description provided for @health_spo2_motivation_near.
  ///
  /// In en, this message translates to:
  /// **'Close to your goal—a few slow breaths can bring you into range.'**
  String get health_spo2_motivation_near;

  /// No description provided for @health_spo2_motivation_low.
  ///
  /// In en, this message translates to:
  /// **'Below your target today—rest, hydrate, and breathe gently.'**
  String get health_spo2_motivation_low;

  /// No description provided for @health_spo2_motivation_empty.
  ///
  /// In en, this message translates to:
  /// **'Wear your device and check back—your next reading can guide your calm and clarity.'**
  String get health_spo2_motivation_empty;

  /// No description provided for @health_metrics_air_quality.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get health_metrics_air_quality;

  /// No description provided for @health_metrics_weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get health_metrics_weather;

  /// No description provided for @health_air_quality.
  ///
  /// In en, this message translates to:
  /// **'Air Quality'**
  String get health_air_quality;

  /// No description provided for @health_weather.
  ///
  /// In en, this message translates to:
  /// **'Weather'**
  String get health_weather;

  /// No description provided for @health_temperature_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Current Temperature'**
  String get health_temperature_subtitle;

  /// No description provided for @health_temperature_env_title.
  ///
  /// In en, this message translates to:
  /// **'Weather & air'**
  String get health_temperature_env_title;

  /// No description provided for @health_env_condition.
  ///
  /// In en, this message translates to:
  /// **'Conditions'**
  String get health_env_condition;

  /// No description provided for @health_env_particles.
  ///
  /// In en, this message translates to:
  /// **'Particles'**
  String get health_env_particles;

  /// No description provided for @health_env_pm25.
  ///
  /// In en, this message translates to:
  /// **'PM2.5'**
  String get health_env_pm25;

  /// No description provided for @health_env_pm10.
  ///
  /// In en, this message translates to:
  /// **'PM10'**
  String get health_env_pm10;

  /// No description provided for @health_env_sources.
  ///
  /// In en, this message translates to:
  /// **'Open-Meteo · WAQI'**
  String get health_env_sources;

  /// No description provided for @health_env_updated.
  ///
  /// In en, this message translates to:
  /// **'Updated {time}'**
  String health_env_updated(String time);

  /// No description provided for @health_aqi_unit.
  ///
  /// In en, this message translates to:
  /// **'AQI'**
  String get health_aqi_unit;

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

  /// No description provided for @health_at_a_glance.
  ///
  /// In en, this message translates to:
  /// **'Your health at a glance.'**
  String get health_at_a_glance;

  /// No description provided for @health_analyzing_meal.
  ///
  /// In en, this message translates to:
  /// **'Analyzing meal…'**
  String get health_analyzing_meal;

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

  /// No description provided for @apple_login.
  ///
  /// In en, this message translates to:
  /// **'APPLE'**
  String get apple_login;

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

  /// No description provided for @err_invalid_credentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get err_invalid_credentials;

  /// No description provided for @err_email_not_confirmed.
  ///
  /// In en, this message translates to:
  /// **'Please check your inbox to verify your email.'**
  String get err_email_not_confirmed;

  /// No description provided for @err_user_not_found.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t find an account with that email.'**
  String get err_user_not_found;

  /// No description provided for @err_network_fail.
  ///
  /// In en, this message translates to:
  /// **'Unable to connect to the server. Check your internet.'**
  String get err_network_fail;

  /// No description provided for @err_auth_timeout.
  ///
  /// In en, this message translates to:
  /// **'Sign-in took too long. Please try again.'**
  String get err_auth_timeout;

  /// No description provided for @err_passkey_canceled.
  ///
  /// In en, this message translates to:
  /// **'Passkey login was canceled.'**
  String get err_passkey_canceled;

  /// No description provided for @err_google_canceled.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in was canceled.'**
  String get err_google_canceled;

  /// No description provided for @err_google_failed.
  ///
  /// In en, this message translates to:
  /// **'Google sign-in failed. Enable Google in Supabase and add the web client ID.'**
  String get err_google_failed;

  /// No description provided for @err_passkey_failed.
  ///
  /// In en, this message translates to:
  /// **'Security check failed. Please try again.'**
  String get err_passkey_failed;

  /// No description provided for @err_biometric_unsupported.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is not available on this device.'**
  String get err_biometric_unsupported;

  /// No description provided for @err_biometric_disabled.
  ///
  /// In en, this message translates to:
  /// **'Biometric login is not enabled for this account.'**
  String get err_biometric_disabled;

  /// No description provided for @err_too_many_attempts.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please try again later.'**
  String get err_too_many_attempts;

  /// No description provided for @msg_enter_credentials.
  ///
  /// In en, this message translates to:
  /// **'Please enter your credentials'**
  String get msg_enter_credentials;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgot_password;

  /// No description provided for @forgot_password_title.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get forgot_password_title;

  /// No description provided for @forgot_password_body.
  ///
  /// In en, this message translates to:
  /// **'Enter your account email. We will send you a link to set a new password.'**
  String get forgot_password_body;

  /// No description provided for @forgot_password_send.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get forgot_password_send;

  /// No description provided for @forgot_password_success.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for this email, you will receive a reset link shortly.'**
  String get forgot_password_success;

  /// No description provided for @err_forgot_password_empty_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email address.'**
  String get err_forgot_password_empty_email;

  /// No description provided for @err_forgot_password_invalid_email.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address.'**
  String get err_forgot_password_invalid_email;

  /// No description provided for @register_page_title.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get register_page_title;

  /// No description provided for @register_username_hint.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get register_username_hint;

  /// No description provided for @register_first_name.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get register_first_name;

  /// No description provided for @register_last_name.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get register_last_name;

  /// No description provided for @register_password_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get register_password_confirm;

  /// No description provided for @btn_create_account.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get btn_create_account;

  /// No description provided for @msg_register_check_email.
  ///
  /// In en, this message translates to:
  /// **'We sent a confirmation link to {email}. Open it in this app to finish signing up.'**
  String msg_register_check_email(String email);

  /// No description provided for @msg_resend_confirm_sent.
  ///
  /// In en, this message translates to:
  /// **'If that address is valid, a new confirmation email was sent.'**
  String get msg_resend_confirm_sent;

  /// No description provided for @register_resend_email.
  ///
  /// In en, this message translates to:
  /// **'Resend email'**
  String get register_resend_email;

  /// No description provided for @register_back_to_login.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get register_back_to_login;

  /// No description provided for @err_register_password_mismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get err_register_password_mismatch;

  /// No description provided for @title_set_new_password.
  ///
  /// In en, this message translates to:
  /// **'Set new password'**
  String get title_set_new_password;

  /// No description provided for @msg_password_recovery_body.
  ///
  /// In en, this message translates to:
  /// **'Choose a new password for your account.'**
  String get msg_password_recovery_body;

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
  /// **'Mind'**
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

  /// No description provided for @breakdown_screentime.
  ///
  /// In en, this message translates to:
  /// **'Screen Time'**
  String get breakdown_screentime;

  /// No description provided for @date_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get date_today;

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

  /// No description provided for @btn_enter.
  ///
  /// In en, this message translates to:
  /// **'ENTER'**
  String get btn_enter;

  /// No description provided for @apple_signin_error.
  ///
  /// In en, this message translates to:
  /// **'Apple Sign-In Error: {error}'**
  String apple_signin_error(String error);

  /// No description provided for @google_signin_error.
  ///
  /// In en, this message translates to:
  /// **'Google Sign-In Error: {error}'**
  String google_signin_error(String error);

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

  /// No description provided for @identity_evolution.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY EVOLUTION'**
  String get identity_evolution;

  /// No description provided for @identity_evolution_desc.
  ///
  /// In en, this message translates to:
  /// **'Level 1: Google. Set a local password to upgrade your security tier.'**
  String get identity_evolution_desc;

  /// No description provided for @btn_set.
  ///
  /// In en, this message translates to:
  /// **'SET'**
  String get btn_set;

  /// No description provided for @security_accuracy.
  ///
  /// In en, this message translates to:
  /// **'Security & Accuracy'**
  String get security_accuracy;

  /// No description provided for @passkey_settings.
  ///
  /// In en, this message translates to:
  /// **'Passkey Settings'**
  String get passkey_settings;

  /// No description provided for @fast_track_active.
  ///
  /// In en, this message translates to:
  /// **'Fast-Track Active (Secure)'**
  String get fast_track_active;

  /// No description provided for @upgrade_biometric.
  ///
  /// In en, this message translates to:
  /// **'Upgrade to Biometric Fast-Track'**
  String get upgrade_biometric;

  /// No description provided for @hint_enter_your.
  ///
  /// In en, this message translates to:
  /// **'Enter your...'**
  String get hint_enter_your;

  /// No description provided for @user_default.
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user_default;

  /// No description provided for @tooltip_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get tooltip_save;

  /// No description provided for @tooltip_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get tooltip_edit;

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
  /// **'Mind Dashboard'**
  String get social_dashboard;

  /// No description provided for @social.
  ///
  /// In en, this message translates to:
  /// **'Mind'**
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
  /// **'Mind Options'**
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

  /// No description provided for @social_no_achievements_msg.
  ///
  /// In en, this message translates to:
  /// **'No achievements logged yet.'**
  String get social_no_achievements_msg;

  /// No description provided for @achievement_story_section.
  ///
  /// In en, this message translates to:
  /// **'Snapshots'**
  String get achievement_story_section;

  /// No description provided for @achievement_story_empty_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to freeze a moment in time.'**
  String get achievement_story_empty_hint;

  /// No description provided for @achievement_story_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get achievement_story_add;

  /// No description provided for @achievement_feats_section.
  ///
  /// In en, this message translates to:
  /// **'Memory lane'**
  String get achievement_feats_section;

  /// No description provided for @achievement_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Looking back'**
  String get achievement_insights_title;

  /// No description provided for @achievement_insights_summary.
  ///
  /// In en, this message translates to:
  /// **'Monthly Reflection: {count} feats recorded. Average Meaningfulness: {meaning}, Average Impact: {impact}'**
  String achievement_insights_summary(int count, String meaning, String impact);

  /// No description provided for @achievement_story_title_dialog.
  ///
  /// In en, this message translates to:
  /// **'Name this win'**
  String get achievement_story_title_dialog;

  /// No description provided for @achievement_story_title_hint.
  ///
  /// In en, this message translates to:
  /// **'What did you achieve?'**
  String get achievement_story_title_hint;

  /// No description provided for @achievement_story_added.
  ///
  /// In en, this message translates to:
  /// **'Story saved to your achievements.'**
  String get achievement_story_added;

  /// No description provided for @achievement_story_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save photo.'**
  String get achievement_story_save_failed;

  /// No description provided for @achievement_filter_label.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get achievement_filter_label;

  /// No description provided for @achievement_filter_all_months.
  ///
  /// In en, this message translates to:
  /// **'All months'**
  String get achievement_filter_all_months;

  /// No description provided for @achievement_filter_all_projects.
  ///
  /// In en, this message translates to:
  /// **'All projects'**
  String get achievement_filter_all_projects;

  /// No description provided for @plan_action_tab.
  ///
  /// In en, this message translates to:
  /// **'PLAN'**
  String get plan_action_tab;

  /// No description provided for @plan_action_empty.
  ///
  /// In en, this message translates to:
  /// **'Plan an action with expected points, then log real points after you do it.'**
  String get plan_action_empty;

  /// No description provided for @plan_action_timeline.
  ///
  /// In en, this message translates to:
  /// **'Timeline'**
  String get plan_action_timeline;

  /// No description provided for @plan_action_scoreboard.
  ///
  /// In en, this message translates to:
  /// **'Scoreboard'**
  String get plan_action_scoreboard;

  /// No description provided for @plan_action_pending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get plan_action_pending;

  /// No description provided for @plan_action_no_pending.
  ///
  /// In en, this message translates to:
  /// **'All actions logged for this view.'**
  String get plan_action_no_pending;

  /// No description provided for @plan_action_add.
  ///
  /// In en, this message translates to:
  /// **'Plan action'**
  String get plan_action_add;

  /// No description provided for @plan_action_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit action'**
  String get plan_action_edit;

  /// No description provided for @plan_action_log_real.
  ///
  /// In en, this message translates to:
  /// **'Log real'**
  String get plan_action_log_real;

  /// No description provided for @plan_action_title_label.
  ///
  /// In en, this message translates to:
  /// **'What will you do?'**
  String get plan_action_title_label;

  /// No description provided for @plan_action_title_required.
  ///
  /// In en, this message translates to:
  /// **'Add a title for this action.'**
  String get plan_action_title_required;

  /// No description provided for @plan_action_expected_label.
  ///
  /// In en, this message translates to:
  /// **'Expected points (0–100)'**
  String get plan_action_expected_label;

  /// No description provided for @plan_action_real_label.
  ///
  /// In en, this message translates to:
  /// **'Real points (0–100)'**
  String get plan_action_real_label;

  /// No description provided for @plan_action_real_hint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty until done'**
  String get plan_action_real_hint;

  /// No description provided for @plan_action_points_invalid.
  ///
  /// In en, this message translates to:
  /// **'Points must be 0–100.'**
  String get plan_action_points_invalid;

  /// No description provided for @plan_action_expected_short.
  ///
  /// In en, this message translates to:
  /// **'Exp'**
  String get plan_action_expected_short;

  /// No description provided for @plan_action_real_short.
  ///
  /// In en, this message translates to:
  /// **'Real'**
  String get plan_action_real_short;

  /// No description provided for @plan_action_expected_value.
  ///
  /// In en, this message translates to:
  /// **'Expected: {points} pts'**
  String plan_action_expected_value(int points);

  /// No description provided for @plan_action_delta_value.
  ///
  /// In en, this message translates to:
  /// **'{delta, plural, =0{even} other{{delta}}}'**
  String plan_action_delta_value(int delta);

  /// No description provided for @plan_action_month_summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 action in this view} other{{count} actions in this view}}'**
  String plan_action_month_summary(int count);

  /// No description provided for @plan_action_total_expected.
  ///
  /// In en, this message translates to:
  /// **'Total expected'**
  String get plan_action_total_expected;

  /// No description provided for @plan_action_total_real.
  ///
  /// In en, this message translates to:
  /// **'Total real'**
  String get plan_action_total_real;

  /// No description provided for @plan_action_delta.
  ///
  /// In en, this message translates to:
  /// **'Net delta'**
  String get plan_action_delta;

  /// No description provided for @achievement_on_this_day_title.
  ///
  /// In en, this message translates to:
  /// **'On this day'**
  String get achievement_on_this_day_title;

  /// No description provided for @achievement_on_this_day_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Memories from {date}'**
  String achievement_on_this_day_subtitle(String date);

  /// No description provided for @achievement_years_ago.
  ///
  /// In en, this message translates to:
  /// **'{years, plural, =1{1 year ago} other{{years} years ago}}'**
  String achievement_years_ago(int years);

  /// No description provided for @achievement_archive_empty.
  ///
  /// In en, this message translates to:
  /// **'No memories yet. Journal entries and notes will appear here.'**
  String get achievement_archive_empty;

  /// No description provided for @achievement_archive_month_summary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 memory in this view} other{{count} memories in this view}}'**
  String achievement_archive_month_summary(int count);

  /// No description provided for @achievement_open_project.
  ///
  /// In en, this message translates to:
  /// **'Open project'**
  String get achievement_open_project;

  /// No description provided for @social_delete_feat_title.
  ///
  /// In en, this message translates to:
  /// **'Delete feat'**
  String get social_delete_feat_title;

  /// No description provided for @social_delete_feat_body.
  ///
  /// In en, this message translates to:
  /// **'Remove this achievement? This cannot be undone.'**
  String get social_delete_feat_body;

  /// No description provided for @social_feat.
  ///
  /// In en, this message translates to:
  /// **'Feat'**
  String get social_feat;

  /// No description provided for @mind_how_feeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get mind_how_feeling;

  /// No description provided for @mind_what_up_to.
  ///
  /// In en, this message translates to:
  /// **'What have you been up to?'**
  String get mind_what_up_to;

  /// No description provided for @mind_add_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get mind_add_note_hint;

  /// No description provided for @mind_save_entry.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get mind_save_entry;

  /// No description provided for @mind_log_saved.
  ///
  /// In en, this message translates to:
  /// **'Mind log saved! Reflection updated.'**
  String get mind_log_saved;

  /// No description provided for @mind_error_login.
  ///
  /// In en, this message translates to:
  /// **'Error: User session not found. Please log in again.'**
  String get mind_error_login;

  /// No description provided for @mind_error_save.
  ///
  /// In en, this message translates to:
  /// **'Failed to save log: {error}'**
  String mind_error_save(String error);

  /// No description provided for @mood_awful.
  ///
  /// In en, this message translates to:
  /// **'Awful'**
  String get mood_awful;

  /// No description provided for @mood_bad.
  ///
  /// In en, this message translates to:
  /// **'Bad'**
  String get mood_bad;

  /// No description provided for @mood_meh.
  ///
  /// In en, this message translates to:
  /// **'Meh'**
  String get mood_meh;

  /// No description provided for @mood_good.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get mood_good;

  /// No description provided for @mood_rad.
  ///
  /// In en, this message translates to:
  /// **'Rad'**
  String get mood_rad;

  /// No description provided for @mood_no_data.
  ///
  /// In en, this message translates to:
  /// **'No data'**
  String get mood_no_data;

  /// No description provided for @mind_current_mood.
  ///
  /// In en, this message translates to:
  /// **'Current Mood'**
  String get mind_current_mood;

  /// No description provided for @mind_day_average.
  ///
  /// In en, this message translates to:
  /// **'Day Average'**
  String get mind_day_average;

  /// No description provided for @mind_latest_log.
  ///
  /// In en, this message translates to:
  /// **'Latest Log'**
  String get mind_latest_log;

  /// No description provided for @mind_never.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get mind_never;

  /// No description provided for @mind_status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get mind_status;

  /// No description provided for @mind_stable.
  ///
  /// In en, this message translates to:
  /// **'Stable'**
  String get mind_stable;

  /// No description provided for @mind_needs_care.
  ///
  /// In en, this message translates to:
  /// **'Needs Care'**
  String get mind_needs_care;

  /// No description provided for @mind_focus_current.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get mind_focus_current;

  /// No description provided for @mind_focus_none.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get mind_focus_none;

  /// No description provided for @mind_quick_entry_hint.
  ///
  /// In en, this message translates to:
  /// **'What\'s on your mind?'**
  String get mind_quick_entry_hint;

  /// No description provided for @mindset_learn_title.
  ///
  /// In en, this message translates to:
  /// **'Mindset log'**
  String get mindset_learn_title;

  /// No description provided for @mindset_learn_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture principles and lessons you\'re internalizing.'**
  String get mindset_learn_subtitle;

  /// No description provided for @mindset_learn_topic.
  ///
  /// In en, this message translates to:
  /// **'Topic / principle'**
  String get mindset_learn_topic;

  /// No description provided for @mindset_learn_topic_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Patience, ship small, growth mindset'**
  String get mindset_learn_topic_hint;

  /// No description provided for @mindset_learn_lesson.
  ///
  /// In en, this message translates to:
  /// **'What I learned'**
  String get mindset_learn_lesson;

  /// No description provided for @mindset_learn_feeling.
  ///
  /// In en, this message translates to:
  /// **'Score (0–5)'**
  String get mindset_learn_feeling;

  /// No description provided for @mindset_learn_save.
  ///
  /// In en, this message translates to:
  /// **'Save insight'**
  String get mindset_learn_save;

  /// No description provided for @mindset_learn_saved.
  ///
  /// In en, this message translates to:
  /// **'Mindset insight saved'**
  String get mindset_learn_saved;

  /// No description provided for @mindset_learn_validation.
  ///
  /// In en, this message translates to:
  /// **'Add a topic and what you learned.'**
  String get mindset_learn_validation;

  /// No description provided for @mindset_learn_history.
  ///
  /// In en, this message translates to:
  /// **'Past insights'**
  String get mindset_learn_history;

  /// No description provided for @mindset_learn_empty.
  ///
  /// In en, this message translates to:
  /// **'No mindset notes yet. Log your first lesson above.'**
  String get mindset_learn_empty;

  /// No description provided for @mindset_learn_open.
  ///
  /// In en, this message translates to:
  /// **'Mindset'**
  String get mindset_learn_open;

  /// No description provided for @mind_focus_title.
  ///
  /// In en, this message translates to:
  /// **'Focus areas'**
  String get mind_focus_title;

  /// No description provided for @mind_focus_weekly_title.
  ///
  /// In en, this message translates to:
  /// **'Weekly focus'**
  String get mind_focus_weekly_title;

  /// No description provided for @mind_focus_monthly_title.
  ///
  /// In en, this message translates to:
  /// **'Monthly focus'**
  String get mind_focus_monthly_title;

  /// No description provided for @mind_focus_goal_level.
  ///
  /// In en, this message translates to:
  /// **'Goal: Lv. {level}'**
  String mind_focus_goal_level(int level);

  /// No description provided for @mind_focus_xp_progress.
  ///
  /// In en, this message translates to:
  /// **'{current} / {cap} XP'**
  String mind_focus_xp_progress(int current, int cap);

  /// No description provided for @mind_focus_badge.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get mind_focus_badge;

  /// No description provided for @mind_total_level.
  ///
  /// In en, this message translates to:
  /// **'Total level'**
  String get mind_total_level;

  /// No description provided for @mind_streak_label.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get mind_streak_label;

  /// No description provided for @mind_streak_days.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String mind_streak_days(int days);

  /// No description provided for @mind_streak_bonus.
  ///
  /// In en, this message translates to:
  /// **'+15% EXP bonus'**
  String get mind_streak_bonus;

  /// No description provided for @mind_skill_tree_title.
  ///
  /// In en, this message translates to:
  /// **'Skill tree'**
  String get mind_skill_tree_title;

  /// No description provided for @mind_skill_certificates_title.
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get mind_skill_certificates_title;

  /// No description provided for @mind_focus_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Define weekly trends so you know where to put your energy.'**
  String get mind_focus_subtitle;

  /// No description provided for @mind_focus_empty.
  ///
  /// In en, this message translates to:
  /// **'No focus areas yet. Start from a template or create your own.'**
  String get mind_focus_empty;

  /// No description provided for @mind_focus_add.
  ///
  /// In en, this message translates to:
  /// **'New focus area'**
  String get mind_focus_add;

  /// No description provided for @mind_focus_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit focus area'**
  String get mind_focus_edit;

  /// No description provided for @mind_focus_save.
  ///
  /// In en, this message translates to:
  /// **'Save focus area'**
  String get mind_focus_save;

  /// No description provided for @mind_focus_weekly_goal.
  ///
  /// In en, this message translates to:
  /// **'Logs per week (goal)'**
  String get mind_focus_weekly_goal;

  /// No description provided for @mind_focus_this_week.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get mind_focus_this_week;

  /// No description provided for @mind_focus_select_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to focus on this area. Recent matching journal entries:'**
  String get mind_focus_select_hint;

  /// No description provided for @mind_focus_template_gym.
  ///
  /// In en, this message translates to:
  /// **'Gym week'**
  String get mind_focus_template_gym;

  /// No description provided for @mind_focus_template_learn.
  ///
  /// In en, this message translates to:
  /// **'Learn week'**
  String get mind_focus_template_learn;

  /// No description provided for @mind_focus_template_invest.
  ///
  /// In en, this message translates to:
  /// **'Invest week'**
  String get mind_focus_template_invest;

  /// No description provided for @mind_focus_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Name (e.g. Gym week)'**
  String get mind_focus_name_hint;

  /// No description provided for @mind_focus_activities_label.
  ///
  /// In en, this message translates to:
  /// **'Linked activities'**
  String get mind_focus_activities_label;

  /// No description provided for @mind_focus_name_required.
  ///
  /// In en, this message translates to:
  /// **'Enter a name for this focus area'**
  String get mind_focus_name_required;

  /// No description provided for @mind_focus_activities_required.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one activity'**
  String get mind_focus_activities_required;

  /// No description provided for @mind_focus_icon_label.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get mind_focus_icon_label;

  /// No description provided for @mind_focus_color_label.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get mind_focus_color_label;

  /// No description provided for @mind_focus_no_logs_yet.
  ///
  /// In en, this message translates to:
  /// **'No journal entries match this area yet.'**
  String get mind_focus_no_logs_yet;

  /// No description provided for @mind_focus_log_now.
  ///
  /// In en, this message translates to:
  /// **'Log for this area'**
  String get mind_focus_log_now;

  /// No description provided for @mind_focus_log_for_area.
  ///
  /// In en, this message translates to:
  /// **'Focus area: {name}'**
  String mind_focus_log_for_area(String name);

  /// No description provided for @mind_focus_todos.
  ///
  /// In en, this message translates to:
  /// **'To-do'**
  String get mind_focus_todos;

  /// No description provided for @mind_focus_open_projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get mind_focus_open_projects;

  /// No description provided for @mind_focus_no_todos.
  ///
  /// In en, this message translates to:
  /// **'No active project tasks. Add tasks in Projects.'**
  String get mind_focus_no_todos;

  /// No description provided for @mind_focus_more_todos.
  ///
  /// In en, this message translates to:
  /// **'+{count} more in Projects'**
  String mind_focus_more_todos(int count);

  /// No description provided for @mind_dashboard_today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get mind_dashboard_today;

  /// No description provided for @mind_dashboard_title.
  ///
  /// In en, this message translates to:
  /// **'My skills'**
  String get mind_dashboard_title;

  /// No description provided for @mind_dashboard_weekly_topic.
  ///
  /// In en, this message translates to:
  /// **'Topic this week'**
  String get mind_dashboard_weekly_topic;

  /// No description provided for @mind_dashboard_edit_topic.
  ///
  /// In en, this message translates to:
  /// **'Edit topic this week'**
  String get mind_dashboard_edit_topic;

  /// No description provided for @mind_dashboard_topic_title.
  ///
  /// In en, this message translates to:
  /// **'Topic title'**
  String get mind_dashboard_topic_title;

  /// No description provided for @mind_dashboard_topic_title_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Presentation week'**
  String get mind_dashboard_topic_title_hint;

  /// No description provided for @mind_dashboard_topic_quote_hint.
  ///
  /// In en, this message translates to:
  /// **'Your weekly focus quote or note'**
  String get mind_dashboard_topic_quote_hint;

  /// No description provided for @mind_dashboard_topic_saved.
  ///
  /// In en, this message translates to:
  /// **'Weekly topic saved to quotes'**
  String get mind_dashboard_topic_saved;

  /// No description provided for @mind_dashboard_target_skills.
  ///
  /// In en, this message translates to:
  /// **'Target skills'**
  String get mind_dashboard_target_skills;

  /// No description provided for @mind_dashboard_in_progress.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get mind_dashboard_in_progress;

  /// No description provided for @mind_dashboard_focus_week.
  ///
  /// In en, this message translates to:
  /// **'Focus this week'**
  String get mind_dashboard_focus_week;

  /// No description provided for @mind_dashboard_add_task.
  ///
  /// In en, this message translates to:
  /// **'+ Add task'**
  String get mind_dashboard_add_task;

  /// No description provided for @mind_dashboard_no_linked_projects.
  ///
  /// In en, this message translates to:
  /// **'Link target skills to projects to see tasks here.'**
  String get mind_dashboard_no_linked_projects;

  /// No description provided for @mind_dashboard_status_done.
  ///
  /// In en, this message translates to:
  /// **'DONE'**
  String get mind_dashboard_status_done;

  /// No description provided for @mind_dashboard_status_waiting.
  ///
  /// In en, this message translates to:
  /// **'WAITING'**
  String get mind_dashboard_status_waiting;

  /// No description provided for @mind_dashboard_certificates.
  ///
  /// In en, this message translates to:
  /// **'Skill certificates'**
  String get mind_dashboard_certificates;

  /// No description provided for @mind_dashboard_see_all.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get mind_dashboard_see_all;

  /// No description provided for @mind_dashboard_verified.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get mind_dashboard_verified;

  /// No description provided for @mind_focus_avg_mood.
  ///
  /// In en, this message translates to:
  /// **'Avg mood this week: {score}'**
  String mind_focus_avg_mood(String score);

  /// No description provided for @mind_focus_history.
  ///
  /// In en, this message translates to:
  /// **'Weekly history'**
  String get mind_focus_history;

  /// No description provided for @mind_focus_history_title.
  ///
  /// In en, this message translates to:
  /// **'Focus area history'**
  String get mind_focus_history_title;

  /// No description provided for @mind_focus_history_week_range.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String mind_focus_history_week_range(String start, String end);

  /// No description provided for @mind_focus_history_logs.
  ///
  /// In en, this message translates to:
  /// **'{count} / {goal} logs'**
  String mind_focus_history_logs(int count, int goal);

  /// No description provided for @mind_focus_history_no_logs.
  ///
  /// In en, this message translates to:
  /// **'No logs'**
  String get mind_focus_history_no_logs;

  /// No description provided for @mind_focus_linked_project.
  ///
  /// In en, this message translates to:
  /// **'Linked project'**
  String get mind_focus_linked_project;

  /// No description provided for @mind_focus_linked_project_none.
  ///
  /// In en, this message translates to:
  /// **'None (all projects)'**
  String get mind_focus_linked_project_none;

  /// No description provided for @mind_focus_linked_project_label.
  ///
  /// In en, this message translates to:
  /// **'Project: {name}'**
  String mind_focus_linked_project_label(String name);

  /// No description provided for @mind_focus_add_task_title.
  ///
  /// In en, this message translates to:
  /// **'Add task'**
  String get mind_focus_add_task_title;

  /// No description provided for @mind_focus_add_task_name.
  ///
  /// In en, this message translates to:
  /// **'Task name'**
  String get mind_focus_add_task_name;

  /// No description provided for @mind_focus_add_task_desc.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get mind_focus_add_task_desc;

  /// No description provided for @mind_focus_add_task_confirm.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mind_focus_add_task_confirm;

  /// No description provided for @mind_focus_add_task_need_project.
  ///
  /// In en, this message translates to:
  /// **'Create a project first, then add tasks here.'**
  String get mind_focus_add_task_need_project;

  /// No description provided for @mind_focus_assign_project.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get mind_focus_assign_project;

  /// No description provided for @mind_focus_all_tasks_mood.
  ///
  /// In en, this message translates to:
  /// **'All tasks done — mood +6 logged.'**
  String get mind_focus_all_tasks_mood;

  /// No description provided for @mind_focus_daily_cap.
  ///
  /// In en, this message translates to:
  /// **'Daily limit: {max} tasks per focus area.'**
  String mind_focus_daily_cap(int max);

  /// No description provided for @mind_focus_daily_progress.
  ///
  /// In en, this message translates to:
  /// **'{added}/{max} today · {done} done'**
  String mind_focus_daily_progress(int added, int max, int done);

  /// No description provided for @mind_focus_daily_hint.
  ///
  /// In en, this message translates to:
  /// **'Add 2–5 tasks today. Finish more than 3 for mood +6.'**
  String get mind_focus_daily_hint;

  /// No description provided for @mind_focus_weekly_hint.
  ///
  /// In en, this message translates to:
  /// **'Add 2–5 tasks this week. Finish more than 3 for mood +6.'**
  String get mind_focus_weekly_hint;

  /// No description provided for @mind_focus_monthly_hint.
  ///
  /// In en, this message translates to:
  /// **'Add 2–5 tasks this month. Finish more than 3 for mood +6.'**
  String get mind_focus_monthly_hint;

  /// No description provided for @mind_focus_special_mood.
  ///
  /// In en, this message translates to:
  /// **'More than 3 tasks done — mood +6 logged!'**
  String get mind_focus_special_mood;

  /// No description provided for @mind_skills_session_title.
  ///
  /// In en, this message translates to:
  /// **'Skill session'**
  String get mind_skills_session_title;

  /// No description provided for @mind_skills_session_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick skills, run a focus block, log what you learned.'**
  String get mind_skills_session_subtitle;

  /// No description provided for @mind_skills_session_start.
  ///
  /// In en, this message translates to:
  /// **'Start session'**
  String get mind_skills_session_start;

  /// No description provided for @mind_skills_session_empty_month.
  ///
  /// In en, this message translates to:
  /// **'No skill sessions this month yet.'**
  String get mind_skills_session_empty_month;

  /// No description provided for @mind_skills_session_skill_meta.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {minutes}m'**
  String mind_skills_session_skill_meta(int sessions, int minutes);

  /// No description provided for @mind_skills_session_empty.
  ///
  /// In en, this message translates to:
  /// **'No skill sessions in the last {days} days.'**
  String mind_skills_session_empty(int days);

  /// No description provided for @mind_skills_session_stats.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {minutes} min · top: {skill}'**
  String mind_skills_session_stats(int sessions, int minutes, String skill);

  /// No description provided for @mind_skills_session_live.
  ///
  /// In en, this message translates to:
  /// **'SESSION LIVE'**
  String get mind_skills_session_live;

  /// No description provided for @mind_skills_session_tap_start.
  ///
  /// In en, this message translates to:
  /// **'TAP CENTER TO START'**
  String get mind_skills_session_tap_start;

  /// No description provided for @mind_skills_session_tap_finish.
  ///
  /// In en, this message translates to:
  /// **'TAP CENTER TO STOP EARLY'**
  String get mind_skills_session_tap_finish;

  /// No description provided for @mind_skills_session_listening.
  ///
  /// In en, this message translates to:
  /// **'SESSION LIVE · AUTO-LOG WHEN MUSIC ENDS'**
  String get mind_skills_session_listening;

  /// No description provided for @mind_skills_session_pick_skills.
  ///
  /// In en, this message translates to:
  /// **'Pick at least one skill before starting.'**
  String get mind_skills_session_pick_skills;

  /// No description provided for @mind_skills_my_list.
  ///
  /// In en, this message translates to:
  /// **'My skills'**
  String get mind_skills_my_list;

  /// No description provided for @mind_skills_add_skill.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get mind_skills_add_skill;

  /// No description provided for @mind_skills_tap_list.
  ///
  /// In en, this message translates to:
  /// **'Tap skills in the list to select'**
  String get mind_skills_tap_list;

  /// No description provided for @mind_skills_tap_list_project.
  ///
  /// In en, this message translates to:
  /// **'Select skills · project XP on log'**
  String get mind_skills_tap_list_project;

  /// No description provided for @mind_skills_status_in_session.
  ///
  /// In en, this message translates to:
  /// **'In session'**
  String get mind_skills_status_in_session;

  /// No description provided for @mind_skills_status_selected.
  ///
  /// In en, this message translates to:
  /// **'Selected'**
  String get mind_skills_status_selected;

  /// No description provided for @mind_skills_level_short.
  ///
  /// In en, this message translates to:
  /// **'Lv {level}'**
  String mind_skills_level_short(int level);

  /// No description provided for @mind_skills_session_logged.
  ///
  /// In en, this message translates to:
  /// **'Session logged · {minutes} min · +{xp} XP'**
  String mind_skills_session_logged(int minutes, int xp);

  /// No description provided for @mind_skills_celebration_title.
  ///
  /// In en, this message translates to:
  /// **'Skill proof saved'**
  String get mind_skills_celebration_title;

  /// No description provided for @mind_skills_celebration_proof.
  ///
  /// In en, this message translates to:
  /// **'You focused {minutes} min and earned +{xp} XP — real practice on your record.'**
  String mind_skills_celebration_proof(int minutes, int xp);

  /// No description provided for @mind_skills_celebration_level_up.
  ///
  /// In en, this message translates to:
  /// **'Level up: {skills}'**
  String mind_skills_celebration_level_up(String skills);

  /// No description provided for @mind_skills_celebration_streak.
  ///
  /// In en, this message translates to:
  /// **'{days}-day streak — keep the chain alive.'**
  String mind_skills_celebration_streak(int days);

  /// No description provided for @mind_skills_celebration_goal.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow’s you is built from sessions like this.'**
  String get mind_skills_celebration_goal;

  /// No description provided for @mind_skill_name_invalid.
  ///
  /// In en, this message translates to:
  /// **'Name must be 1–24 characters.'**
  String get mind_skill_name_invalid;

  /// No description provided for @mind_skill_name_duplicate.
  ///
  /// In en, this message translates to:
  /// **'That skill already exists.'**
  String get mind_skill_name_duplicate;

  /// No description provided for @mind_skill_add_title.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get mind_skill_add_title;

  /// No description provided for @mind_skill_edit_title.
  ///
  /// In en, this message translates to:
  /// **'Edit skill'**
  String get mind_skill_edit_title;

  /// No description provided for @mind_skill_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete skill?'**
  String get mind_skill_delete_title;

  /// No description provided for @mind_skill_delete_body.
  ///
  /// In en, this message translates to:
  /// **'Remove “{name}” from your library?'**
  String mind_skill_delete_body(String name);

  /// No description provided for @mind_skill_certificate_header.
  ///
  /// In en, this message translates to:
  /// **'CERTIFICATE OF PRACTICE'**
  String get mind_skill_certificate_header;

  /// No description provided for @mind_skill_certificate_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Human capital · verified progress'**
  String get mind_skill_certificate_subtitle;

  /// No description provided for @mind_skill_certificate_awarded_to.
  ///
  /// In en, this message translates to:
  /// **'Awarded for sustained skill practice'**
  String get mind_skill_certificate_awarded_to;

  /// No description provided for @mind_skill_certificate_level.
  ///
  /// In en, this message translates to:
  /// **'Rank'**
  String get mind_skill_certificate_level;

  /// No description provided for @mind_skill_certificate_xp.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get mind_skill_certificate_xp;

  /// No description provided for @mind_skill_certificate_streak.
  ///
  /// In en, this message translates to:
  /// **'Streak'**
  String get mind_skill_certificate_streak;

  /// No description provided for @mind_skill_certificate_proof.
  ///
  /// In en, this message translates to:
  /// **'This record reflects real sessions logged in ice_gate — your proof of growth.'**
  String get mind_skill_certificate_proof;

  /// No description provided for @mind_skill_certificate_seal.
  ///
  /// In en, this message translates to:
  /// **'ICEGATE SEAL'**
  String get mind_skill_certificate_seal;

  /// No description provided for @mind_skill_certificate_select_session.
  ///
  /// In en, this message translates to:
  /// **'Select for session'**
  String get mind_skill_certificate_select_session;

  /// No description provided for @mind_skill_certificate_close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get mind_skill_certificate_close;

  /// No description provided for @mind_skill_certificate_created.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get mind_skill_certificate_created;

  /// No description provided for @mind_skill_certificate_updated.
  ///
  /// In en, this message translates to:
  /// **'Last updated'**
  String get mind_skill_certificate_updated;

  /// No description provided for @mind_skill_certificate_description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get mind_skill_certificate_description;

  /// No description provided for @mind_skill_certificate_description_hint.
  ///
  /// In en, this message translates to:
  /// **'What this skill means to you, or how you earned it…'**
  String get mind_skill_certificate_description_hint;

  /// No description provided for @mind_skill_certificate_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit certificate'**
  String get mind_skill_certificate_edit;

  /// No description provided for @mind_skill_certificate_save.
  ///
  /// In en, this message translates to:
  /// **'Save certificate'**
  String get mind_skill_certificate_save;

  /// No description provided for @mind_skill_certificates_table_title.
  ///
  /// In en, this message translates to:
  /// **'Practice certificates'**
  String get mind_skill_certificates_table_title;

  /// No description provided for @mind_skill_certificates_table_empty.
  ///
  /// In en, this message translates to:
  /// **'No skills in your library yet. Open Skills to start earning certificates.'**
  String get mind_skill_certificates_table_empty;

  /// No description provided for @mind_skill_certificates_col_skill.
  ///
  /// In en, this message translates to:
  /// **'Skill'**
  String get mind_skill_certificates_col_skill;

  /// No description provided for @mood_trends_title.
  ///
  /// In en, this message translates to:
  /// **'Mood Trends'**
  String get mood_trends_title;

  /// No description provided for @social_notes_title.
  ///
  /// In en, this message translates to:
  /// **'Social Notes'**
  String get social_notes_title;

  /// No description provided for @social_empty_state_title.
  ///
  /// In en, this message translates to:
  /// **'Your story begins here'**
  String get social_empty_state_title;

  /// No description provided for @social_empty_state_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Capture moments, thoughts, and ideas.'**
  String get social_empty_state_subtitle;

  /// No description provided for @btn_new_reflection.
  ///
  /// In en, this message translates to:
  /// **'New Reflection'**
  String get btn_new_reflection;

  /// No description provided for @mind_insights_title.
  ///
  /// In en, this message translates to:
  /// **'Mind Insights'**
  String get mind_insights_title;

  /// No description provided for @mind_insights_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis of your journal entries'**
  String get mind_insights_subtitle;

  /// No description provided for @mind_question.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling?'**
  String get mind_question;

  /// No description provided for @mind_activities_question.
  ///
  /// In en, this message translates to:
  /// **'What have you been up to?'**
  String get mind_activities_question;

  /// No description provided for @mind_note_hint.
  ///
  /// In en, this message translates to:
  /// **'Add a note (optional)'**
  String get mind_note_hint;

  /// No description provided for @mind_save_btn.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get mind_save_btn;

  /// No description provided for @mind_activity_custom_chip.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get mind_activity_custom_chip;

  /// No description provided for @mind_activity_custom_dialog_title.
  ///
  /// In en, this message translates to:
  /// **'New activity'**
  String get mind_activity_custom_dialog_title;

  /// No description provided for @mind_activity_custom_hint.
  ///
  /// In en, this message translates to:
  /// **'Name this activity'**
  String get mind_activity_custom_hint;

  /// No description provided for @mind_activity_custom_add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mind_activity_custom_add;

  /// No description provided for @mind_activity_custom_invalid_char.
  ///
  /// In en, this message translates to:
  /// **'This character is not allowed'**
  String get mind_activity_custom_invalid_char;

  /// No description provided for @mind_save_success.
  ///
  /// In en, this message translates to:
  /// **'Mind log saved! Reflection updated.'**
  String get mind_save_success;

  /// No description provided for @mind_feeling_format.
  ///
  /// In en, this message translates to:
  /// **'I\'m feeling {mood} today.'**
  String mind_feeling_format(String mood);

  /// No description provided for @mind_logged_mood.
  ///
  /// In en, this message translates to:
  /// **'Logged mood'**
  String get mind_logged_mood;

  /// No description provided for @todays_reflections.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Reflections'**
  String get todays_reflections;

  /// No description provided for @daily_step_distribution.
  ///
  /// In en, this message translates to:
  /// **'Daily Step Distribution'**
  String get daily_step_distribution;

  /// No description provided for @stat_entries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get stat_entries;

  /// No description provided for @stat_images.
  ///
  /// In en, this message translates to:
  /// **'Images'**
  String get stat_images;

  /// No description provided for @stat_sentiment.
  ///
  /// In en, this message translates to:
  /// **'Sentiment'**
  String get stat_sentiment;

  /// No description provided for @stat_mind_logs.
  ///
  /// In en, this message translates to:
  /// **'Logs (30d)'**
  String get stat_mind_logs;

  /// No description provided for @stat_active_days.
  ///
  /// In en, this message translates to:
  /// **'Active days'**
  String get stat_active_days;

  /// No description provided for @stat_avg_mood.
  ///
  /// In en, this message translates to:
  /// **'Avg mood'**
  String get stat_avg_mood;

  /// No description provided for @journal_hourly_logs.
  ///
  /// In en, this message translates to:
  /// **'Logs by hour (today)'**
  String get journal_hourly_logs;

  /// No description provided for @mind_insights_skill_title.
  ///
  /// In en, this message translates to:
  /// **'Skill practice (30d)'**
  String get mind_insights_skill_title;

  /// No description provided for @mind_insights_skill_summary.
  ///
  /// In en, this message translates to:
  /// **'{sessions} sessions · {minutes} min'**
  String mind_insights_skill_summary(int sessions, int minutes);

  /// No description provided for @mind_insights_top_skill_streak.
  ///
  /// In en, this message translates to:
  /// **'Top streak · {skill} · {days}d'**
  String mind_insights_top_skill_streak(String skill, int days);

  /// No description provided for @mind_insights_open_notes.
  ///
  /// In en, this message translates to:
  /// **'Mind notes'**
  String get mind_insights_open_notes;

  /// No description provided for @mind_insights_open_skills.
  ///
  /// In en, this message translates to:
  /// **'Skill certificates'**
  String get mind_insights_open_skills;

  /// No description provided for @weekly_mood_trend.
  ///
  /// In en, this message translates to:
  /// **'Weekly Mood Trend'**
  String get weekly_mood_trend;

  /// No description provided for @no_records_last_7_days.
  ///
  /// In en, this message translates to:
  /// **'No records for the last 7 days'**
  String get no_records_last_7_days;

  /// No description provided for @frequent_activities.
  ///
  /// In en, this message translates to:
  /// **'Frequent Activities'**
  String get frequent_activities;

  /// No description provided for @track_patterns_msg.
  ///
  /// In en, this message translates to:
  /// **'Track more logs to see patterns'**
  String get track_patterns_msg;

  /// No description provided for @monthly_reflection.
  ///
  /// In en, this message translates to:
  /// **'Monthly Reflection'**
  String get monthly_reflection;

  /// No description provided for @cat_productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get cat_productivity;

  /// No description provided for @cat_health.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get cat_health;

  /// No description provided for @cat_social.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get cat_social;

  /// No description provided for @cat_rest.
  ///
  /// In en, this message translates to:
  /// **'Rest'**
  String get cat_rest;

  /// No description provided for @act_deep_work.
  ///
  /// In en, this message translates to:
  /// **'Deep Work'**
  String get act_deep_work;

  /// No description provided for @act_learning.
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get act_learning;

  /// No description provided for @act_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get act_finance;

  /// No description provided for @act_planning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get act_planning;

  /// No description provided for @act_exercise.
  ///
  /// In en, this message translates to:
  /// **'Exercise'**
  String get act_exercise;

  /// No description provided for @act_meditation.
  ///
  /// In en, this message translates to:
  /// **'Meditation'**
  String get act_meditation;

  /// No description provided for @act_healthy_meal.
  ///
  /// In en, this message translates to:
  /// **'Healthy Meal'**
  String get act_healthy_meal;

  /// No description provided for @act_great_sleep.
  ///
  /// In en, this message translates to:
  /// **'Great Sleep'**
  String get act_great_sleep;

  /// No description provided for @act_family.
  ///
  /// In en, this message translates to:
  /// **'Family'**
  String get act_family;

  /// No description provided for @act_friends.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get act_friends;

  /// No description provided for @act_dating.
  ///
  /// In en, this message translates to:
  /// **'Dating'**
  String get act_dating;

  /// No description provided for @act_kindness.
  ///
  /// In en, this message translates to:
  /// **'Kindness'**
  String get act_kindness;

  /// No description provided for @act_gaming.
  ///
  /// In en, this message translates to:
  /// **'Gaming'**
  String get act_gaming;

  /// No description provided for @act_reading.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get act_reading;

  /// No description provided for @act_cinema.
  ///
  /// In en, this message translates to:
  /// **'Cinema'**
  String get act_cinema;

  /// No description provided for @act_walking.
  ///
  /// In en, this message translates to:
  /// **'Walking'**
  String get act_walking;

  /// No description provided for @act_focus_todos_streak.
  ///
  /// In en, this message translates to:
  /// **'4+ focus tasks done'**
  String get act_focus_todos_streak;

  /// No description provided for @act_focus_todos_complete.
  ///
  /// In en, this message translates to:
  /// **'Focus tasks complete'**
  String get act_focus_todos_complete;

  /// No description provided for @act_logging.
  ///
  /// In en, this message translates to:
  /// **'Logging'**
  String get act_logging;

  /// No description provided for @act_productivity.
  ///
  /// In en, this message translates to:
  /// **'Productivity'**
  String get act_productivity;

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

  /// No description provided for @plugin_ssh.
  ///
  /// In en, this message translates to:
  /// **'SSH Session'**
  String get plugin_ssh;

  /// No description provided for @plugin_ssh_opencode.
  ///
  /// In en, this message translates to:
  /// **'OpenCode AI SSH'**
  String get plugin_ssh_opencode;

  /// No description provided for @plugin_ssh_desc.
  ///
  /// In en, this message translates to:
  /// **'AI-powered terminal for remote orchestration'**
  String get plugin_ssh_desc;

  /// No description provided for @config_ai_prompt.
  ///
  /// In en, this message translates to:
  /// **'Configure AI Prompt'**
  String get config_ai_prompt;

  /// No description provided for @homepage_four_life_elements.
  ///
  /// In en, this message translates to:
  /// **'Main Elements'**
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

  /// No description provided for @auth_error_session_not_found.
  ///
  /// In en, this message translates to:
  /// **'Error: User session not found. Please log in again.'**
  String get auth_error_session_not_found;

  /// No description provided for @projects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get projects;

  /// No description provided for @projects_page_tagline.
  ///
  /// In en, this message translates to:
  /// **'Sessions, tasks, and notes in one place.'**
  String get projects_page_tagline;

  /// No description provided for @projects_summary_workspaces.
  ///
  /// In en, this message translates to:
  /// **'Workspaces'**
  String get projects_summary_workspaces;

  /// No description provided for @projects_summary_plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get projects_summary_plugins;

  /// No description provided for @projects_quick_more.
  ///
  /// In en, this message translates to:
  /// **'More shortcuts'**
  String get projects_quick_more;

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

  /// No description provided for @home_indices_title.
  ///
  /// In en, this message translates to:
  /// **'Quick Indices'**
  String get home_indices_title;

  /// No description provided for @home_index_steps.
  ///
  /// In en, this message translates to:
  /// **'Steps'**
  String get home_index_steps;

  /// No description provided for @home_index_calories.
  ///
  /// In en, this message translates to:
  /// **'Calories'**
  String get home_index_calories;

  /// No description provided for @home_index_balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get home_index_balance;

  /// No description provided for @home_index_spending.
  ///
  /// In en, this message translates to:
  /// **'Spending'**
  String get home_index_spending;

  /// No description provided for @home_index_mood.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get home_index_mood;

  /// No description provided for @home_index_projects.
  ///
  /// In en, this message translates to:
  /// **'Growth'**
  String get home_index_projects;

  /// No description provided for @home_index_weight.
  ///
  /// In en, this message translates to:
  /// **'Weight'**
  String get home_index_weight;

  /// No description provided for @home_index_water.
  ///
  /// In en, this message translates to:
  /// **'Water'**
  String get home_index_water;

  /// No description provided for @home_index_daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get home_index_daily;

  /// No description provided for @home_index_usage.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get home_index_usage;

  /// No description provided for @home_index_focus.
  ///
  /// In en, this message translates to:
  /// **'Focus'**
  String get home_index_focus;

  /// No description provided for @home_index_xp.
  ///
  /// In en, this message translates to:
  /// **'XP Today'**
  String get home_index_xp;

  /// No description provided for @home_index_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get home_index_total;

  /// No description provided for @home_projects_done.
  ///
  /// In en, this message translates to:
  /// **'Done Projs'**
  String get home_projects_done;

  /// No description provided for @home_projects_active.
  ///
  /// In en, this message translates to:
  /// **'Active Projs'**
  String get home_projects_active;

  /// No description provided for @home_tasks_done.
  ///
  /// In en, this message translates to:
  /// **'Done Tasks'**
  String get home_tasks_done;

  /// No description provided for @home_tasks_active.
  ///
  /// In en, this message translates to:
  /// **'Active Tasks'**
  String get home_tasks_active;

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
  /// **'{points} points for each new meaningful support session or connection.'**
  String rule_social_contact(int points);

  /// No description provided for @rule_social_affection.
  ///
  /// In en, this message translates to:
  /// **'{points} points per {unit} stability level reached.'**
  String rule_social_affection(int points, int unit);

  /// No description provided for @rule_social_maintain.
  ///
  /// In en, this message translates to:
  /// **'Practice mindfulness and maintain connections to prevent stability decay.'**
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

  /// No description provided for @dev_quick_tabs_title.
  ///
  /// In en, this message translates to:
  /// **'Software Dev'**
  String get dev_quick_tabs_title;

  /// No description provided for @dev_quick_tabs_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Saved browser tabs — Northflank, Supabase, n8n, and more.'**
  String get dev_quick_tabs_subtitle;

  /// No description provided for @dev_quick_tabs_empty.
  ///
  /// In en, this message translates to:
  /// **'No tabs yet. Tap + to add one.'**
  String get dev_quick_tabs_empty;

  /// No description provided for @dev_quick_tabs_add.
  ///
  /// In en, this message translates to:
  /// **'Add tab'**
  String get dev_quick_tabs_add;

  /// No description provided for @dev_quick_tabs_open.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get dev_quick_tabs_open;

  /// No description provided for @dev_quick_tabs_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit tab'**
  String get dev_quick_tabs_edit;

  /// No description provided for @dev_quick_tabs_label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get dev_quick_tabs_label;

  /// No description provided for @dev_quick_tabs_url.
  ///
  /// In en, this message translates to:
  /// **'Local URL (LAN)'**
  String get dev_quick_tabs_url;

  /// No description provided for @dev_quick_tabs_remote_url.
  ///
  /// In en, this message translates to:
  /// **'Remote URL'**
  String get dev_quick_tabs_remote_url;

  /// No description provided for @dev_quick_tabs_remote_url_hint.
  ///
  /// In en, this message translates to:
  /// **'Used when the LAN address is unreachable (VPN, Tailscale, public host).'**
  String get dev_quick_tabs_remote_url_hint;

  /// No description provided for @dev_quick_tabs_validation_error.
  ///
  /// In en, this message translates to:
  /// **'Title and at least one URL are required'**
  String get dev_quick_tabs_validation_error;

  /// No description provided for @dev_quick_tabs_delete_title.
  ///
  /// In en, this message translates to:
  /// **'Delete tab?'**
  String get dev_quick_tabs_delete_title;

  /// No description provided for @dev_quick_tabs_delete_message.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{title}\" from quick access.'**
  String dev_quick_tabs_delete_message(String title);

  /// No description provided for @dev_quick_tabs_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dev_quick_tabs_delete_confirm;

  /// No description provided for @dev_quick_tabs_credentials.
  ///
  /// In en, this message translates to:
  /// **'Saved logins'**
  String get dev_quick_tabs_credentials;

  /// No description provided for @dev_quick_tabs_credentials_subtitle.
  ///
  /// In en, this message translates to:
  /// **'HTTP login and SSL trust per host.'**
  String get dev_quick_tabs_credentials_subtitle;

  /// No description provided for @dev_quick_tabs_credentials_login.
  ///
  /// In en, this message translates to:
  /// **'Login saved'**
  String get dev_quick_tabs_credentials_login;

  /// No description provided for @dev_quick_tabs_credentials_ssl.
  ///
  /// In en, this message translates to:
  /// **'SSL trusted'**
  String get dev_quick_tabs_credentials_ssl;

  /// No description provided for @dev_quick_tabs_credentials_none.
  ///
  /// In en, this message translates to:
  /// **'No saved data'**
  String get dev_quick_tabs_credentials_none;

  /// No description provided for @dev_quick_tabs_credentials_set_login.
  ///
  /// In en, this message translates to:
  /// **'Set login'**
  String get dev_quick_tabs_credentials_set_login;

  /// No description provided for @dev_quick_tabs_credentials_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get dev_quick_tabs_credentials_username;

  /// No description provided for @dev_quick_tabs_credentials_password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get dev_quick_tabs_credentials_password;

  /// No description provided for @dev_quick_tabs_credentials_passkey.
  ///
  /// In en, this message translates to:
  /// **'Passkey / API key'**
  String get dev_quick_tabs_credentials_passkey;

  /// No description provided for @dev_quick_tabs_credentials_saved.
  ///
  /// In en, this message translates to:
  /// **'Credentials saved'**
  String get dev_quick_tabs_credentials_saved;

  /// No description provided for @dev_quick_tabs_credentials_ssl_hint.
  ///
  /// In en, this message translates to:
  /// **'For self-signed homelab HTTPS (e.g. OPNsense).'**
  String get dev_quick_tabs_credentials_ssl_hint;

  /// No description provided for @dev_quick_tabs_credentials_clear.
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get dev_quick_tabs_credentials_clear;

  /// No description provided for @dev_quick_tabs_credentials_clear_title.
  ///
  /// In en, this message translates to:
  /// **'Clear saved data?'**
  String get dev_quick_tabs_credentials_clear_title;

  /// No description provided for @dev_quick_tabs_credentials_clear_message.
  ///
  /// In en, this message translates to:
  /// **'Remove login and SSL trust for {host}.'**
  String dev_quick_tabs_credentials_clear_message(String host);

  /// No description provided for @dev_quick_tabs_credentials_revoke_ssl.
  ///
  /// In en, this message translates to:
  /// **'Revoke SSL trust'**
  String get dev_quick_tabs_credentials_revoke_ssl;

  /// No description provided for @dev_quick_tabs_login_type.
  ///
  /// In en, this message translates to:
  /// **'Login type'**
  String get dev_quick_tabs_login_type;

  /// No description provided for @dev_quick_tabs_login_type_html_form.
  ///
  /// In en, this message translates to:
  /// **'HTML form (OPNsense, homelab)'**
  String get dev_quick_tabs_login_type_html_form;

  /// No description provided for @dev_quick_tabs_login_type_email_password.
  ///
  /// In en, this message translates to:
  /// **'Email + password (SPA)'**
  String get dev_quick_tabs_login_type_email_password;

  /// No description provided for @dev_quick_tabs_login_type_http_basic.
  ///
  /// In en, this message translates to:
  /// **'HTTP Basic only'**
  String get dev_quick_tabs_login_type_http_basic;

  /// No description provided for @dev_quick_tabs_login_type_api_key.
  ///
  /// In en, this message translates to:
  /// **'API key / token'**
  String get dev_quick_tabs_login_type_api_key;

  /// No description provided for @dev_quick_tabs_login_type_bearer_token.
  ///
  /// In en, this message translates to:
  /// **'Bearer token (K8s Dashboard)'**
  String get dev_quick_tabs_login_type_bearer_token;

  /// No description provided for @dev_quick_tabs_login_type_external_browser.
  ///
  /// In en, this message translates to:
  /// **'Open in Safari / Chrome'**
  String get dev_quick_tabs_login_type_external_browser;

  /// No description provided for @dev_quick_tabs_login_type_oauth.
  ///
  /// In en, this message translates to:
  /// **'OAuth / SSO (manual in WebView)'**
  String get dev_quick_tabs_login_type_oauth;

  /// No description provided for @dev_quick_tabs_login_type_none.
  ///
  /// In en, this message translates to:
  /// **'No autofill'**
  String get dev_quick_tabs_login_type_none;

  /// No description provided for @dev_quick_tabs_credentials_email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get dev_quick_tabs_credentials_email;

  /// No description provided for @dev_quick_tabs_credentials_bearer_token.
  ///
  /// In en, this message translates to:
  /// **'Bearer token'**
  String get dev_quick_tabs_credentials_bearer_token;

  /// No description provided for @dev_quick_tabs_login_type_external_browser_hint.
  ///
  /// In en, this message translates to:
  /// **'Opens this site in your system browser — best for GitHub, Google SSO, and passkeys.'**
  String get dev_quick_tabs_login_type_external_browser_hint;

  /// No description provided for @dev_quick_tabs_login_type_oauth_hint.
  ///
  /// In en, this message translates to:
  /// **'GitHub or Google sign-in cannot be auto-filled. Use manual login.'**
  String get dev_quick_tabs_login_type_oauth_hint;

  /// No description provided for @webview_connection_error.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get webview_connection_error;

  /// No description provided for @webview_retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get webview_retry;

  /// No description provided for @webview_ssl_trust_title.
  ///
  /// In en, this message translates to:
  /// **'Trust homelab certificate?'**
  String get webview_ssl_trust_title;

  /// No description provided for @webview_ssl_trust_message.
  ///
  /// In en, this message translates to:
  /// **'The certificate for {host} is not trusted (common for OPNsense and LAN devices). Only continue on networks you trust.'**
  String webview_ssl_trust_message(String host);

  /// No description provided for @webview_ssl_trust_continue.
  ///
  /// In en, this message translates to:
  /// **'Trust and continue'**
  String get webview_ssl_trust_continue;

  /// No description provided for @webview_choose_url.
  ///
  /// In en, this message translates to:
  /// **'Choose URL'**
  String get webview_choose_url;

  /// No description provided for @webview_ssl_protocol_hint.
  ///
  /// In en, this message translates to:
  /// **'This often means the server uses plain HTTP, not HTTPS. Edit the tab URL to http:// or tap Try HTTP below.'**
  String get webview_ssl_protocol_hint;

  /// No description provided for @webview_ssl_protocol_tailscale_hint.
  ///
  /// In en, this message translates to:
  /// **'Tailscale HTTPS is usually on your machine name (https://name.tailnet.ts.net on port 443 via Serve), not https://100.x.x.x:9001. Port 9001 is often HTTP-only behind the proxy — put the Serve URL in Remote URL.'**
  String get webview_ssl_protocol_tailscale_hint;

  /// No description provided for @webview_try_http.
  ///
  /// In en, this message translates to:
  /// **'Try HTTP'**
  String get webview_try_http;

  /// No description provided for @canvas_goal_desc.
  ///
  /// In en, this message translates to:
  /// **'Adjust tactical goal parameters'**
  String get canvas_goal_desc;

  /// No description provided for @canvas_finance_reports_title.
  ///
  /// In en, this message translates to:
  /// **'Finance reports'**
  String get canvas_finance_reports_title;

  /// No description provided for @canvas_finance_reports_desc.
  ///
  /// In en, this message translates to:
  /// **'Daily summary, local reminders, and shortcuts'**
  String get canvas_finance_reports_desc;

  /// No description provided for @canvas_finance_n8n_title.
  ///
  /// In en, this message translates to:
  /// **'Email report'**
  String get canvas_finance_n8n_title;

  /// No description provided for @canvas_finance_n8n_desc.
  ///
  /// In en, this message translates to:
  /// **'Finance and health snapshot delivered through n8n'**
  String get canvas_finance_n8n_desc;

  /// No description provided for @canvas_finance_n8n_send_success.
  ///
  /// In en, this message translates to:
  /// **'Report sent to n8n.'**
  String get canvas_finance_n8n_send_success;

  /// No description provided for @canvas_finance_n8n_send_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send report. Try again later.'**
  String get canvas_finance_n8n_send_failed;

  /// No description provided for @canvas_finance_n8n_not_configured.
  ///
  /// In en, this message translates to:
  /// **'n8n webhook is not configured in the app environment.'**
  String get canvas_finance_n8n_not_configured;

  /// No description provided for @canvas_finance_n8n_no_email.
  ///
  /// In en, this message translates to:
  /// **'Add an email to your profile before sending a report.'**
  String get canvas_finance_n8n_no_email;

  /// No description provided for @canvas_finance_n8n_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Send email report?'**
  String get canvas_finance_n8n_confirm_title;

  /// No description provided for @canvas_finance_n8n_confirm_message.
  ///
  /// In en, this message translates to:
  /// **'Today\'s finance and health summary will be sent to n8n for delivery to {email}.'**
  String canvas_finance_n8n_confirm_message(String email);

  /// No description provided for @canvas_mail_summary_recipient.
  ///
  /// In en, this message translates to:
  /// **'Recipient'**
  String get canvas_mail_summary_recipient;

  /// No description provided for @canvas_mail_summary_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance today'**
  String get canvas_mail_summary_finance;

  /// No description provided for @canvas_mail_summary_health.
  ///
  /// In en, this message translates to:
  /// **'Health today'**
  String get canvas_mail_summary_health;

  /// No description provided for @canvas_mail_summary_send.
  ///
  /// In en, this message translates to:
  /// **'Send email report'**
  String get canvas_mail_summary_send;

  /// No description provided for @canvas_mail_summary_auto_title.
  ///
  /// In en, this message translates to:
  /// **'Automatic daily email'**
  String get canvas_mail_summary_auto_title;

  /// No description provided for @canvas_mail_summary_auto_subtitle.
  ///
  /// In en, this message translates to:
  /// **'After this time, send once per day while the app is open'**
  String get canvas_mail_summary_auto_subtitle;

  /// No description provided for @mail_suggestion_title.
  ///
  /// In en, this message translates to:
  /// **'Report tips'**
  String get mail_suggestion_title;

  /// No description provided for @mail_suggestion_ai_loading.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your day…'**
  String get mail_suggestion_ai_loading;

  /// No description provided for @mail_suggestion_ai_fallback.
  ///
  /// In en, this message translates to:
  /// **'Offline tips — connect MAIL_SUGGESTIONS_AGENT_URL for AI.'**
  String get mail_suggestion_ai_fallback;

  /// No description provided for @mail_suggestion_negative_net.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spending exceeded income — review recent transactions.'**
  String get mail_suggestion_negative_net;

  /// No description provided for @mail_suggestion_no_transactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions logged today — add expenses to keep reports accurate.'**
  String get mail_suggestion_no_transactions;

  /// No description provided for @mail_suggestion_budget_high.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used {percent}% of your monthly budget — pace spending.'**
  String mail_suggestion_budget_high(String percent);

  /// No description provided for @mail_suggestion_monthly_deficit.
  ///
  /// In en, this message translates to:
  /// **'Monthly spending exceeds income — consider trimming fixed costs.'**
  String get mail_suggestion_monthly_deficit;

  /// No description provided for @mail_suggestion_steps_low.
  ///
  /// In en, this message translates to:
  /// **'Steps at {percent}% of goal — a short walk helps hit your target.'**
  String mail_suggestion_steps_low(String percent);

  /// No description provided for @mail_suggestion_water_low.
  ///
  /// In en, this message translates to:
  /// **'Water intake is below half your goal — hydrate through the day.'**
  String get mail_suggestion_water_low;

  /// No description provided for @mail_suggestion_sleep_low.
  ///
  /// In en, this message translates to:
  /// **'Sleep below your goal — try an earlier wind-down tonight.'**
  String get mail_suggestion_sleep_low;

  /// No description provided for @mail_suggestion_log_mood.
  ///
  /// In en, this message translates to:
  /// **'No mood logged today — a quick check-in improves your trends.'**
  String get mail_suggestion_log_mood;

  /// No description provided for @mail_suggestion_focus_low.
  ///
  /// In en, this message translates to:
  /// **'Focus time is low — schedule a short deep-work block.'**
  String get mail_suggestion_focus_low;

  /// No description provided for @mail_suggestion_tasks_many.
  ///
  /// In en, this message translates to:
  /// **'{count} active tasks open — pick one priority for tomorrow.'**
  String mail_suggestion_tasks_many(String count);

  /// No description provided for @reports_hub_title.
  ///
  /// In en, this message translates to:
  /// **'Report via mail'**
  String get reports_hub_title;

  /// No description provided for @reports_hub_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily finance on device, email delivery through n8n'**
  String get reports_hub_subtitle;

  /// No description provided for @system_monitor_title.
  ///
  /// In en, this message translates to:
  /// **'System Monitor'**
  String get system_monitor_title;

  /// No description provided for @system_monitor_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Homelab launcher, dev accounts, DB & sync telemetry — admin only.'**
  String get system_monitor_subtitle;

  /// No description provided for @system_monitor_denied_title.
  ///
  /// In en, this message translates to:
  /// **'Admin access required'**
  String get system_monitor_denied_title;

  /// No description provided for @system_monitor_denied_body.
  ///
  /// In en, this message translates to:
  /// **'This page is restricted to accounts with the admin role.'**
  String get system_monitor_denied_body;

  /// No description provided for @system_monitor_denied_roles.
  ///
  /// In en, this message translates to:
  /// **'Local: {local} · Remote: {remote}'**
  String system_monitor_denied_roles(String local, String remote);

  /// No description provided for @system_monitor_denied_hint.
  ///
  /// In en, this message translates to:
  /// **'Set role to admin in Supabase → Table Editor → user_accounts (not Auth metadata). Then tap Refresh role.'**
  String get system_monitor_denied_hint;

  /// No description provided for @system_monitor_retry.
  ///
  /// In en, this message translates to:
  /// **'Refresh role'**
  String get system_monitor_retry;

  /// No description provided for @system_monitor_overview_section.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get system_monitor_overview_section;

  /// No description provided for @system_monitor_db_section.
  ///
  /// In en, this message translates to:
  /// **'Local database'**
  String get system_monitor_db_section;

  /// No description provided for @system_monitor_sync_section.
  ///
  /// In en, this message translates to:
  /// **'Sync engine'**
  String get system_monitor_sync_section;

  /// No description provided for @system_monitor_app_version.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get system_monitor_app_version;

  /// No description provided for @system_monitor_platform.
  ///
  /// In en, this message translates to:
  /// **'Platform'**
  String get system_monitor_platform;

  /// No description provided for @system_monitor_role.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get system_monitor_role;

  /// No description provided for @system_monitor_auth_status.
  ///
  /// In en, this message translates to:
  /// **'Auth status'**
  String get system_monitor_auth_status;

  /// No description provided for @system_monitor_supabase_user.
  ///
  /// In en, this message translates to:
  /// **'Supabase user'**
  String get system_monitor_supabase_user;

  /// No description provided for @system_monitor_running_checks.
  ///
  /// In en, this message translates to:
  /// **'Running diagnostics…'**
  String get system_monitor_running_checks;

  /// No description provided for @system_monitor_healthy.
  ///
  /// In en, this message translates to:
  /// **'Database healthy'**
  String get system_monitor_healthy;

  /// No description provided for @system_monitor_issues.
  ///
  /// In en, this message translates to:
  /// **'Issues detected'**
  String get system_monitor_issues;

  /// No description provided for @system_monitor_smoke_test.
  ///
  /// In en, this message translates to:
  /// **'Smoke test'**
  String get system_monitor_smoke_test;

  /// No description provided for @system_monitor_sync_active.
  ///
  /// In en, this message translates to:
  /// **'Sync active'**
  String get system_monitor_sync_active;

  /// No description provided for @system_monitor_sync_status.
  ///
  /// In en, this message translates to:
  /// **'Last status'**
  String get system_monitor_sync_status;

  /// No description provided for @system_monitor_uptime.
  ///
  /// In en, this message translates to:
  /// **'Session uptime'**
  String get system_monitor_uptime;

  /// No description provided for @system_monitor_open_sync_engine.
  ///
  /// In en, this message translates to:
  /// **'Open Sync Engine'**
  String get system_monitor_open_sync_engine;

  /// No description provided for @dev_launcher_web_title.
  ///
  /// In en, this message translates to:
  /// **'Web apps (homelab)'**
  String get dev_launcher_web_title;

  /// No description provided for @dev_launcher_accounts_title.
  ///
  /// In en, this message translates to:
  /// **'Dev & cloud accounts'**
  String get dev_launcher_accounts_title;

  /// No description provided for @dev_launcher_accounts_empty.
  ///
  /// In en, this message translates to:
  /// **'Save OPNsense, Supabase, Northflank, n8n logins here. Secrets stay on device.'**
  String get dev_launcher_accounts_empty;

  /// No description provided for @dev_launcher_add_web.
  ///
  /// In en, this message translates to:
  /// **'Add web app'**
  String get dev_launcher_add_web;

  /// No description provided for @dev_launcher_add_account.
  ///
  /// In en, this message translates to:
  /// **'Add dev account'**
  String get dev_launcher_add_account;

  /// No description provided for @dev_launcher_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get dev_launcher_name;

  /// No description provided for @dev_launcher_url.
  ///
  /// In en, this message translates to:
  /// **'URL'**
  String get dev_launcher_url;

  /// No description provided for @dev_launcher_service.
  ///
  /// In en, this message translates to:
  /// **'Service'**
  String get dev_launcher_service;

  /// No description provided for @dev_launcher_username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get dev_launcher_username;

  /// No description provided for @dev_launcher_password.
  ///
  /// In en, this message translates to:
  /// **'Password / API key'**
  String get dev_launcher_password;

  /// No description provided for @dev_launcher_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get dev_launcher_copied;

  /// No description provided for @dev_launcher_pin_canvas.
  ///
  /// In en, this message translates to:
  /// **'Pin to Canvas'**
  String get dev_launcher_pin_canvas;

  /// No description provided for @dev_launcher_pinned.
  ///
  /// In en, this message translates to:
  /// **'Added to Canvas widgets'**
  String get dev_launcher_pinned;

  /// No description provided for @dev_launcher_add_from_catalog.
  ///
  /// In en, this message translates to:
  /// **'From plugin catalog'**
  String get dev_launcher_add_from_catalog;

  /// No description provided for @dev_launcher_pick_plugin.
  ///
  /// In en, this message translates to:
  /// **'Homelab web plugins'**
  String get dev_launcher_pick_plugin;

  /// No description provided for @infra_api_section_title.
  ///
  /// In en, this message translates to:
  /// **'Infra API'**
  String get infra_api_section_title;

  /// No description provided for @infra_api_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Cloudflare, Tailscale, Northflank. API tokens stay on this device.'**
  String get infra_api_section_subtitle;

  /// No description provided for @infra_api_configure.
  ///
  /// In en, this message translates to:
  /// **'Configure {provider}'**
  String infra_api_configure(String provider);

  /// No description provided for @infra_api_token_label.
  ///
  /// In en, this message translates to:
  /// **'API token / key'**
  String get infra_api_token_label;

  /// No description provided for @infra_api_tailnet_label.
  ///
  /// In en, this message translates to:
  /// **'Tailnet name'**
  String get infra_api_tailnet_label;

  /// No description provided for @infra_api_tailnet_hint.
  ///
  /// In en, this message translates to:
  /// **'Use - for default tailnet'**
  String get infra_api_tailnet_hint;

  /// No description provided for @infra_api_clear.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get infra_api_clear;

  /// No description provided for @infra_api_test.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get infra_api_test;

  /// No description provided for @infra_api_not_configured.
  ///
  /// In en, this message translates to:
  /// **'Not configured'**
  String get infra_api_not_configured;

  /// No description provided for @infra_api_connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get infra_api_connected;

  /// No description provided for @infra_api_token_saved.
  ///
  /// In en, this message translates to:
  /// **'Token saved — tap Test'**
  String get infra_api_token_saved;

  /// No description provided for @infra_api_test_ok.
  ///
  /// In en, this message translates to:
  /// **'OK · {summary}'**
  String infra_api_test_ok(String summary);

  /// No description provided for @infra_api_test_fail.
  ///
  /// In en, this message translates to:
  /// **'Failed · {message}'**
  String infra_api_test_fail(String message);

  /// No description provided for @island_system_monitor.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM MONITOR'**
  String get island_system_monitor;

  /// No description provided for @reports_mail_section_title.
  ///
  /// In en, this message translates to:
  /// **'Email via n8n'**
  String get reports_mail_section_title;

  /// No description provided for @reports_mail_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Finance and health snapshot delivered by email'**
  String get reports_mail_section_subtitle;

  /// No description provided for @reports_finance_section.
  ///
  /// In en, this message translates to:
  /// **'On-device finance report'**
  String get reports_finance_section;

  /// No description provided for @reports_recipient_hint.
  ///
  /// In en, this message translates to:
  /// **'recipient@example.com'**
  String get reports_recipient_hint;

  /// No description provided for @reports_recipient_save.
  ///
  /// In en, this message translates to:
  /// **'Save recipient'**
  String get reports_recipient_save;

  /// No description provided for @reports_recipient_saved.
  ///
  /// In en, this message translates to:
  /// **'Report recipient saved.'**
  String get reports_recipient_saved;

  /// No description provided for @reports_recipient_profile_fallback.
  ///
  /// In en, this message translates to:
  /// **'Profile email default: {email}'**
  String reports_recipient_profile_fallback(String email);

  /// No description provided for @canvas_finance_n8n_confirm_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get canvas_finance_n8n_confirm_send;

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

  /// No description provided for @note_type_picker_title.
  ///
  /// In en, this message translates to:
  /// **'Choose note type'**
  String get note_type_picker_title;

  /// No description provided for @note_type_markdown.
  ///
  /// In en, this message translates to:
  /// **'Markdown (.md)'**
  String get note_type_markdown;

  /// No description provided for @note_type_plain_text.
  ///
  /// In en, this message translates to:
  /// **'Plain text (.txt)'**
  String get note_type_plain_text;

  /// No description provided for @note_type_word.
  ///
  /// In en, this message translates to:
  /// **'Word (.docx)'**
  String get note_type_word;

  /// No description provided for @project_journal_label.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get project_journal_label;

  /// No description provided for @project_no_journal.
  ///
  /// In en, this message translates to:
  /// **'No journal entries yet. Tap + to log mood and progress.'**
  String get project_no_journal;

  /// No description provided for @project_journal_entry.
  ///
  /// In en, this message translates to:
  /// **'Project log'**
  String get project_journal_entry;

  /// No description provided for @project_log_context.
  ///
  /// In en, this message translates to:
  /// **'Project: {name}'**
  String project_log_context(String name);

  /// No description provided for @project_journal_mood_label.
  ///
  /// In en, this message translates to:
  /// **'Mood'**
  String get project_journal_mood_label;

  /// No description provided for @project_journal_desc_label.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get project_journal_desc_label;

  /// No description provided for @project_journal_save.
  ///
  /// In en, this message translates to:
  /// **'Save log'**
  String get project_journal_save;

  /// No description provided for @project_journal_composer_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap to record how this project session felt.'**
  String get project_journal_composer_hint;

  /// No description provided for @project_journal_count.
  ///
  /// In en, this message translates to:
  /// **'{count}'**
  String project_journal_count(int count);

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

  /// No description provided for @project_choose_document_type.
  ///
  /// In en, this message translates to:
  /// **'Choose document type'**
  String get project_choose_document_type;

  /// No description provided for @project_doc_blank_note.
  ///
  /// In en, this message translates to:
  /// **'Blank note'**
  String get project_doc_blank_note;

  /// No description provided for @project_doc_blank_note_desc.
  ///
  /// In en, this message translates to:
  /// **'Start with a clean slate'**
  String get project_doc_blank_note_desc;

  /// No description provided for @project_doc_tech.
  ///
  /// In en, this message translates to:
  /// **'Technical doc'**
  String get project_doc_tech;

  /// No description provided for @project_doc_tech_desc.
  ///
  /// In en, this message translates to:
  /// **'Architecture and implementation template'**
  String get project_doc_tech_desc;

  /// No description provided for @project_doc_api.
  ///
  /// In en, this message translates to:
  /// **'API specification'**
  String get project_doc_api;

  /// No description provided for @project_doc_api_desc.
  ///
  /// In en, this message translates to:
  /// **'Endpoints and schema template'**
  String get project_doc_api_desc;

  /// No description provided for @project_doc_tech_title.
  ///
  /// In en, this message translates to:
  /// **'Technical Documentation'**
  String get project_doc_tech_title;

  /// No description provided for @project_doc_api_title.
  ///
  /// In en, this message translates to:
  /// **'API Specification'**
  String get project_doc_api_title;

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

  /// No description provided for @project_skills_label.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get project_skills_label;

  /// No description provided for @project_no_skills.
  ///
  /// In en, this message translates to:
  /// **'No skills yet. Tap + to track what you improve on this project.'**
  String get project_no_skills;

  /// No description provided for @project_add_skill_title.
  ///
  /// In en, this message translates to:
  /// **'Add skill'**
  String get project_add_skill_title;

  /// No description provided for @project_skill_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Flutter, debugging, system design'**
  String get project_skill_name_hint;

  /// No description provided for @project_skill_streak_days.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String project_skill_streak_days(int count);

  /// No description provided for @project_skill_streak_none.
  ///
  /// In en, this message translates to:
  /// **'No streak yet'**
  String get project_skill_streak_none;

  /// No description provided for @project_skill_xp_hint.
  ///
  /// In en, this message translates to:
  /// **'{total} XP · {remaining} XP to next level'**
  String project_skill_xp_hint(int total, int remaining);

  /// No description provided for @project_skill_xp_on_complete.
  ///
  /// In en, this message translates to:
  /// **'Complete tasks to earn +15 XP per skill'**
  String get project_skill_xp_on_complete;

  /// No description provided for @project_skill_log_session.
  ///
  /// In en, this message translates to:
  /// **'Log a Skill Boost session to level these skills.'**
  String get project_skill_log_session;

  /// No description provided for @project_skill_practice.
  ///
  /// In en, this message translates to:
  /// **'Open Skill Boost'**
  String get project_skill_practice;

  /// No description provided for @project_skill_tap_to_start.
  ///
  /// In en, this message translates to:
  /// **'Select one or more skills, then start the session'**
  String get project_skill_tap_to_start;

  /// No description provided for @project_skill_start_session.
  ///
  /// In en, this message translates to:
  /// **'Start session ({count})'**
  String project_skill_start_session(int count);

  /// No description provided for @project_skill_catalog_hint.
  ///
  /// In en, this message translates to:
  /// **'Pick from the same skills as Mind → Skills tiles.'**
  String get project_skill_catalog_hint;

  /// No description provided for @project_auto_add_all_skills.
  ///
  /// In en, this message translates to:
  /// **'Create new skill'**
  String get project_auto_add_all_skills;

  /// No description provided for @project_auto_add_all_skills_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add a brand-new skill to Mind and this project'**
  String get project_auto_add_all_skills_subtitle;

  /// No description provided for @project_skill_already_exists.
  ///
  /// In en, this message translates to:
  /// **'That skill already exists'**
  String get project_skill_already_exists;

  /// No description provided for @project_skill_name_too_long.
  ///
  /// In en, this message translates to:
  /// **'Skill name too long (max 24 characters)'**
  String get project_skill_name_too_long;

  /// No description provided for @project_skills_all_on_project.
  ///
  /// In en, this message translates to:
  /// **'All Mind skills are already on this project'**
  String get project_skills_all_on_project;

  /// No description provided for @project_skills_added_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 skill added} other{{count} skills added}}'**
  String project_skills_added_count(int count);

  /// No description provided for @project_skill_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove \"{name}\" from this project?'**
  String project_skill_delete_confirm(String name);

  /// No description provided for @project_skill_added.
  ///
  /// In en, this message translates to:
  /// **'Skill added'**
  String get project_skill_added;

  /// No description provided for @project_skill_xp_granted.
  ///
  /// In en, this message translates to:
  /// **'Skills gained +{xp} XP'**
  String project_skill_xp_granted(int xp);

  /// No description provided for @project_sub_projects_label.
  ///
  /// In en, this message translates to:
  /// **'Sub-projects'**
  String get project_sub_projects_label;

  /// No description provided for @project_no_sub_projects.
  ///
  /// In en, this message translates to:
  /// **'No sub-projects yet. Tap + to add a child project.'**
  String get project_no_sub_projects;

  /// No description provided for @project_add_sub_project_title.
  ///
  /// In en, this message translates to:
  /// **'New sub-project'**
  String get project_add_sub_project_title;

  /// No description provided for @project_sub_project_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Sub-project name'**
  String get project_sub_project_name_hint;

  /// No description provided for @project_add_task_title.
  ///
  /// In en, this message translates to:
  /// **'New Task'**
  String get project_add_task_title;

  /// No description provided for @project_task_assign_to.
  ///
  /// In en, this message translates to:
  /// **'Assign to project'**
  String get project_task_assign_to;

  /// No description provided for @project_task_title_hint.
  ///
  /// In en, this message translates to:
  /// **'Task title'**
  String get project_task_title_hint;

  /// No description provided for @project_sdlc_board_title.
  ///
  /// In en, this message translates to:
  /// **'SDLC board'**
  String get project_sdlc_board_title;

  /// No description provided for @project_sdlc_open.
  ///
  /// In en, this message translates to:
  /// **'Open SDLC board'**
  String get project_sdlc_open;

  /// No description provided for @project_sdlc_add_task_title.
  ///
  /// In en, this message translates to:
  /// **'Add SDLC task'**
  String get project_sdlc_add_task_title;

  /// No description provided for @project_sdlc_move_phase.
  ///
  /// In en, this message translates to:
  /// **'SDLC phase'**
  String get project_sdlc_move_phase;

  /// No description provided for @project_sdlc_due_date.
  ///
  /// In en, this message translates to:
  /// **'Due date'**
  String get project_sdlc_due_date;

  /// No description provided for @project_sdlc_due_date_none.
  ///
  /// In en, this message translates to:
  /// **'No due date'**
  String get project_sdlc_due_date_none;

  /// No description provided for @project_sdlc_clear_due_date.
  ///
  /// In en, this message translates to:
  /// **'Clear due date'**
  String get project_sdlc_clear_due_date;

  /// No description provided for @project_sdlc_default_purpose.
  ///
  /// In en, this message translates to:
  /// **'Define what this project must deliver and why.'**
  String get project_sdlc_default_purpose;

  /// No description provided for @project_sdlc_empty.
  ///
  /// In en, this message translates to:
  /// **'No active tasks. Tap + to add one to a phase.'**
  String get project_sdlc_empty;

  /// No description provided for @project_sdlc_column_empty.
  ///
  /// In en, this message translates to:
  /// **'No tasks'**
  String get project_sdlc_column_empty;

  /// No description provided for @project_sdlc_add_to_phase.
  ///
  /// In en, this message translates to:
  /// **'Add task to this phase'**
  String get project_sdlc_add_to_phase;

  /// No description provided for @project_sdlc_drop_here.
  ///
  /// In en, this message translates to:
  /// **'Drop to move here'**
  String get project_sdlc_drop_here;

  /// No description provided for @project_sdlc_task_moved.
  ///
  /// In en, this message translates to:
  /// **'Moved to {phase}'**
  String project_sdlc_task_moved(String phase);

  /// No description provided for @project_sdlc_phase_stat.
  ///
  /// In en, this message translates to:
  /// **'P{phase}: {count}'**
  String project_sdlc_phase_stat(int phase, int count);

  /// No description provided for @project_sdlc_phase_planning_title.
  ///
  /// In en, this message translates to:
  /// **'Planning & requirements'**
  String get project_sdlc_phase_planning_title;

  /// No description provided for @project_sdlc_phase_planning_hint.
  ///
  /// In en, this message translates to:
  /// **'SRS, feasibility'**
  String get project_sdlc_phase_planning_hint;

  /// No description provided for @project_sdlc_phase_design_title.
  ///
  /// In en, this message translates to:
  /// **'Architecture & design'**
  String get project_sdlc_phase_design_title;

  /// No description provided for @project_sdlc_phase_design_hint.
  ///
  /// In en, this message translates to:
  /// **'Tech stack, UI'**
  String get project_sdlc_phase_design_hint;

  /// No description provided for @project_sdlc_phase_implementation_title.
  ///
  /// In en, this message translates to:
  /// **'Implementation'**
  String get project_sdlc_phase_implementation_title;

  /// No description provided for @project_sdlc_phase_implementation_hint.
  ///
  /// In en, this message translates to:
  /// **'Code, Git, reviews'**
  String get project_sdlc_phase_implementation_hint;

  /// No description provided for @project_sdlc_phase_testing_title.
  ///
  /// In en, this message translates to:
  /// **'Testing & QA'**
  String get project_sdlc_phase_testing_title;

  /// No description provided for @project_sdlc_phase_testing_hint.
  ///
  /// In en, this message translates to:
  /// **'Unit, integration, UAT'**
  String get project_sdlc_phase_testing_hint;

  /// No description provided for @project_sdlc_phase_deployment_title.
  ///
  /// In en, this message translates to:
  /// **'Deployment'**
  String get project_sdlc_phase_deployment_title;

  /// No description provided for @project_sdlc_phase_deployment_hint.
  ///
  /// In en, this message translates to:
  /// **'CI/CD, release'**
  String get project_sdlc_phase_deployment_hint;

  /// No description provided for @project_sdlc_phase_maintenance_title.
  ///
  /// In en, this message translates to:
  /// **'Operations & maintenance'**
  String get project_sdlc_phase_maintenance_title;

  /// No description provided for @project_sdlc_phase_maintenance_hint.
  ///
  /// In en, this message translates to:
  /// **'Monitor, patches, scale'**
  String get project_sdlc_phase_maintenance_hint;

  /// No description provided for @project_sdlc_no_project.
  ///
  /// In en, this message translates to:
  /// **'Create a project first to open the SDLC board.'**
  String get project_sdlc_no_project;

  /// No description provided for @project_sdlc_pick_project.
  ///
  /// In en, this message translates to:
  /// **'Choose project for SDLC board'**
  String get project_sdlc_pick_project;

  /// No description provided for @task_delete_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get task_delete_tooltip;

  /// No description provided for @task_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete task'**
  String get task_delete_confirm_title;

  /// No description provided for @task_delete_confirm_msg.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"? This cannot be undone.'**
  String task_delete_confirm_msg(String name);

  /// No description provided for @task_deleted_msg.
  ///
  /// In en, this message translates to:
  /// **'Task deleted'**
  String get task_deleted_msg;

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

  /// No description provided for @recent_updates.
  ///
  /// In en, this message translates to:
  /// **'Recent Updates'**
  String get recent_updates;

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

  /// No description provided for @note_editor_write_hint.
  ///
  /// In en, this message translates to:
  /// **'Start writing your note…'**
  String get note_editor_write_hint;

  /// No description provided for @note_editor_saved_label.
  ///
  /// In en, this message translates to:
  /// **'Saved {when}'**
  String note_editor_saved_label(String when);

  /// No description provided for @note_editor_saved_just_now.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get note_editor_saved_just_now;

  /// No description provided for @note_editor_saved_minutes.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String note_editor_saved_minutes(int count);

  /// No description provided for @note_editor_saved_hours.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String note_editor_saved_hours(int count);

  /// No description provided for @note_editor_unsaved.
  ///
  /// In en, this message translates to:
  /// **'Unsaved'**
  String get note_editor_unsaved;

  /// No description provided for @note_editor_saving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get note_editor_saving;

  /// No description provided for @focus_select_project.
  ///
  /// In en, this message translates to:
  /// **'TAP TO SELECT PROJECT'**
  String get focus_select_project;

  /// No description provided for @focus_select_task.
  ///
  /// In en, this message translates to:
  /// **'SELECT TASK'**
  String get focus_select_task;

  /// No description provided for @focus_active_exercise.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE EXERCISE: {type}'**
  String focus_active_exercise(String type);

  /// No description provided for @focus_flow_active.
  ///
  /// In en, this message translates to:
  /// **'FLOW STATE ACTIVE'**
  String get focus_flow_active;

  /// No description provided for @focus_breathing.
  ///
  /// In en, this message translates to:
  /// **'BREATHING'**
  String get focus_breathing;

  /// No description provided for @focus_fetching_audio.
  ///
  /// In en, this message translates to:
  /// **'FETCHING AUDIO...'**
  String get focus_fetching_audio;

  /// No description provided for @entry_scanning.
  ///
  /// In en, this message translates to:
  /// **'SCANNING'**
  String get entry_scanning;

  /// No description provided for @entry_assembling.
  ///
  /// In en, this message translates to:
  /// **'ASSEMBLING'**
  String get entry_assembling;

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

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get delete_account;

  /// No description provided for @delete_account_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign out and remove your cloud profile when supported'**
  String get delete_account_subtitle;

  /// No description provided for @delete_account_plan_title.
  ///
  /// In en, this message translates to:
  /// **'Suggested plan before you delete'**
  String get delete_account_plan_title;

  /// No description provided for @delete_account_plan_intro.
  ///
  /// In en, this message translates to:
  /// **'Review what happens when you continue:'**
  String get delete_account_plan_intro;

  /// No description provided for @delete_account_plan_step1.
  ///
  /// In en, this message translates to:
  /// **'You will be signed out on this device and saved login data cleared from secure storage.'**
  String get delete_account_plan_step1;

  /// No description provided for @delete_account_plan_step2.
  ///
  /// In en, this message translates to:
  /// **'If your project deploys the Supabase Edge Function \"delete-account\", your auth user and linked rows can be removed server-side.'**
  String get delete_account_plan_step2;

  /// No description provided for @delete_account_plan_step3.
  ///
  /// In en, this message translates to:
  /// **'Until that endpoint exists, cloud data may remain — contact support or use the dashboard to request full erasure under applicable privacy laws.'**
  String get delete_account_plan_step3;

  /// No description provided for @delete_account_acknowledge.
  ///
  /// In en, this message translates to:
  /// **'I understand my account may not be fully erased from the server until backend deletion is enabled.'**
  String get delete_account_acknowledge;

  /// No description provided for @delete_account_type_key_word.
  ///
  /// In en, this message translates to:
  /// **'DELETE-ACCOUNT'**
  String get delete_account_type_key_word;

  /// No description provided for @delete_account_type_key_prompt.
  ///
  /// In en, this message translates to:
  /// **'Type {word} to confirm:'**
  String delete_account_type_key_prompt(String word);

  /// No description provided for @delete_account_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete and sign out'**
  String get delete_account_confirm;

  /// No description provided for @delete_account_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get delete_account_cancel;

  /// No description provided for @delete_account_success.
  ///
  /// In en, this message translates to:
  /// **'You have been signed out. Complete cloud deletion may take up to 48 hours once enabled.'**
  String get delete_account_success;

  /// No description provided for @delete_account_err_not_signed_in.
  ///
  /// In en, this message translates to:
  /// **'No active session.'**
  String get delete_account_err_not_signed_in;

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

  /// No description provided for @notification_no_active_quests.
  ///
  /// In en, this message translates to:
  /// **'No active quests right now. Complete tasks in Projects to earn daily quests.'**
  String get notification_no_active_quests;

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

  /// No description provided for @notification_system_preferences.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM PREFERENCES'**
  String get notification_system_preferences;

  /// No description provided for @notification_pomodoro_reminder_title.
  ///
  /// In en, this message translates to:
  /// **'Pomodoros Reminder'**
  String get notification_pomodoro_reminder_title;

  /// No description provided for @notification_pomodoro_reminder_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Receive notification after you finish a pomodoro or end a break.'**
  String get notification_pomodoro_reminder_subtitle;

  /// No description provided for @notification_live_activities_title.
  ///
  /// In en, this message translates to:
  /// **'Live Activities'**
  String get notification_live_activities_title;

  /// No description provided for @notification_live_activities_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track focus timer and information on your Lock Screen.'**
  String get notification_live_activities_subtitle;

  /// No description provided for @notification_morning_briefing_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule, yesterday recap, and motivation when you first open Home (5:00–11:59).'**
  String get notification_morning_briefing_subtitle;

  /// No description provided for @notification_status_on.
  ///
  /// In en, this message translates to:
  /// **'on'**
  String get notification_status_on;

  /// No description provided for @notification_status_off.
  ///
  /// In en, this message translates to:
  /// **'off'**
  String get notification_status_off;

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

  /// No description provided for @notification_task_success.
  ///
  /// In en, this message translates to:
  /// **'TASK SUCCESS'**
  String get notification_task_success;

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

  /// No description provided for @finance_txn_source_account.
  ///
  /// In en, this message translates to:
  /// **'Paid from'**
  String get finance_txn_source_account;

  /// No description provided for @finance_txn_source_account_none.
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get finance_txn_source_account_none;

  /// No description provided for @finance_txn_source_account_empty.
  ///
  /// In en, this message translates to:
  /// **'Save a wallet or account first, then choose it when logging spend.'**
  String get finance_txn_source_account_empty;

  /// No description provided for @finance_txn_source_account_add.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get finance_txn_source_account_add;

  /// No description provided for @finance_txn_source_account_required.
  ///
  /// In en, this message translates to:
  /// **'Choose which account this money left.'**
  String get finance_txn_source_account_required;

  /// No description provided for @finance_recurring_income.
  ///
  /// In en, this message translates to:
  /// **'Recurring income'**
  String get finance_recurring_income;

  /// No description provided for @finance_recurring_interval.
  ///
  /// In en, this message translates to:
  /// **'Repeat every'**
  String get finance_recurring_interval;

  /// No description provided for @finance_fixed_income_title.
  ///
  /// In en, this message translates to:
  /// **'Fixed income'**
  String get finance_fixed_income_title;

  /// No description provided for @finance_fixed_income_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Human capital (skills), salary, rent received, and other steady inflows'**
  String get finance_fixed_income_subtitle;

  /// No description provided for @finance_fixed_income_monthly_total.
  ///
  /// In en, this message translates to:
  /// **'Monthly total'**
  String get finance_fixed_income_monthly_total;

  /// No description provided for @finance_fixed_income_empty.
  ///
  /// In en, this message translates to:
  /// **'No fixed income yet'**
  String get finance_fixed_income_empty;

  /// No description provided for @finance_shortcut_transaction.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get finance_shortcut_transaction;

  /// No description provided for @finance_shortcut_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get finance_shortcut_account;

  /// No description provided for @finance_shortcut_asset.
  ///
  /// In en, this message translates to:
  /// **'Asset'**
  String get finance_shortcut_asset;

  /// No description provided for @finance_shortcut_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get finance_shortcut_income;

  /// No description provided for @finance_fixed_income_add.
  ///
  /// In en, this message translates to:
  /// **'Add fixed income'**
  String get finance_fixed_income_add;

  /// No description provided for @finance_fixed_income_new.
  ///
  /// In en, this message translates to:
  /// **'New fixed income'**
  String get finance_fixed_income_new;

  /// No description provided for @finance_fixed_income_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit fixed income'**
  String get finance_fixed_income_edit;

  /// No description provided for @finance_fixed_income_name.
  ///
  /// In en, this message translates to:
  /// **'Income name'**
  String get finance_fixed_income_name;

  /// No description provided for @finance_fixed_income_next.
  ///
  /// In en, this message translates to:
  /// **'Next payout'**
  String get finance_fixed_income_next;

  /// No description provided for @finance_fixed_income_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Remove this fixed income schedule?'**
  String get finance_fixed_income_delete_confirm;

  /// No description provided for @finance_insight_title.
  ///
  /// In en, this message translates to:
  /// **'Analysis'**
  String get finance_insight_title;

  /// No description provided for @finance_insight_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Suggestions'**
  String get finance_insight_suggestions;

  /// No description provided for @finance_insight_enter_amount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount to preview how this affects your month.'**
  String get finance_insight_enter_amount;

  /// No description provided for @finance_insight_fixed_after.
  ///
  /// In en, this message translates to:
  /// **'After saving: about {amount}/month in fixed income.'**
  String finance_insight_fixed_after(String amount);

  /// No description provided for @finance_insight_covers_spending.
  ///
  /// In en, this message translates to:
  /// **'Covers about {percent}% of spending logged this month ({spent}).'**
  String finance_insight_covers_spending(String percent, String spent);

  /// No description provided for @finance_insight_shortfall.
  ///
  /// In en, this message translates to:
  /// **'Still about {amount} short vs monthly spending.'**
  String finance_insight_shortfall(String amount);

  /// No description provided for @finance_insight_surplus.
  ///
  /// In en, this message translates to:
  /// **'Roughly {amount}/month left after typical spending.'**
  String finance_insight_surplus(String amount);

  /// No description provided for @finance_insight_duplicate_fixed.
  ///
  /// In en, this message translates to:
  /// **'You already have fixed income in “{name}” — avoid double counting.'**
  String finance_insight_duplicate_fixed(String name);

  /// No description provided for @finance_insight_expense_share.
  ///
  /// In en, this message translates to:
  /// **'This would be about {percent}% of spending this month.'**
  String finance_insight_expense_share(String percent);

  /// No description provided for @finance_insight_expense_large.
  ///
  /// In en, this message translates to:
  /// **'Large one-off expense — double-check the category.'**
  String get finance_insight_expense_large;

  /// No description provided for @finance_insight_income_share.
  ///
  /// In en, this message translates to:
  /// **'Adds about {percent}% to income logged this month.'**
  String finance_insight_income_share(String percent);

  /// No description provided for @finance_insight_recurring_equiv.
  ///
  /// In en, this message translates to:
  /// **'As recurring: about {amount}/month on top of fixed income.'**
  String finance_insight_recurring_equiv(String amount);

  /// No description provided for @finance_insight_savings_total.
  ///
  /// In en, this message translates to:
  /// **'Savings balance would reach about {amount}.'**
  String finance_insight_savings_total(String amount);

  /// No description provided for @finance_interval_weekly.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get finance_interval_weekly;

  /// No description provided for @finance_interval_monthly.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get finance_interval_monthly;

  /// No description provided for @finance_interval_yearly.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get finance_interval_yearly;

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

  /// No description provided for @finance_daily_report_title.
  ///
  /// In en, this message translates to:
  /// **'Daily report'**
  String get finance_daily_report_title;

  /// No description provided for @finance_daily_report_reminder.
  ///
  /// In en, this message translates to:
  /// **'Daily reminder'**
  String get finance_daily_report_reminder;

  /// No description provided for @finance_daily_report_reminder_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Local notification that opens this report'**
  String get finance_daily_report_reminder_subtitle;

  /// No description provided for @finance_daily_report_open.
  ///
  /// In en, this message translates to:
  /// **'Open daily report'**
  String get finance_daily_report_open;

  /// No description provided for @finance_daily_report_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get finance_daily_report_income;

  /// No description provided for @finance_daily_report_expense.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get finance_daily_report_expense;

  /// No description provided for @finance_daily_report_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get finance_daily_report_net;

  /// No description provided for @finance_daily_report_spending_by_category.
  ///
  /// In en, this message translates to:
  /// **'Spending by category'**
  String get finance_daily_report_spending_by_category;

  /// No description provided for @finance_daily_report_today_transactions.
  ///
  /// In en, this message translates to:
  /// **'Today\'s activity'**
  String get finance_daily_report_today_transactions;

  /// No description provided for @finance_daily_report_empty_day.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this day yet.'**
  String get finance_daily_report_empty_day;

  /// No description provided for @finance_daily_report_notifications_off.
  ///
  /// In en, this message translates to:
  /// **'Enable system notifications in Settings to use daily reminders.'**
  String get finance_daily_report_notifications_off;

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

  /// No description provided for @finance_subscriptions_active_header.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE SUBSCRIPTIONS'**
  String get finance_subscriptions_active_header;

  /// No description provided for @finance_subscriptions_monthly_total.
  ///
  /// In en, this message translates to:
  /// **'MONTHLY TOTAL'**
  String get finance_subscriptions_monthly_total;

  /// No description provided for @finance_subscriptions_next_month_header.
  ///
  /// In en, this message translates to:
  /// **'PLAN NEXT MONTH'**
  String get finance_subscriptions_next_month_header;

  /// No description provided for @finance_subscriptions_next_month_total.
  ///
  /// In en, this message translates to:
  /// **'PLANNED TOTAL'**
  String get finance_subscriptions_next_month_total;

  /// No description provided for @finance_subscriptions_next_month_empty.
  ///
  /// In en, this message translates to:
  /// **'No subscription charges scheduled for next month.'**
  String get finance_subscriptions_next_month_empty;

  /// No description provided for @finance_subscriptions_next_month_remove_tooltip.
  ///
  /// In en, this message translates to:
  /// **'Remove from this month\'s plan'**
  String get finance_subscriptions_next_month_remove_tooltip;

  /// No description provided for @finance_subscriptions_next_month_remove_title.
  ///
  /// In en, this message translates to:
  /// **'REMOVE FROM PLAN'**
  String get finance_subscriptions_next_month_remove_title;

  /// No description provided for @finance_subscriptions_next_month_remove_message.
  ///
  /// In en, this message translates to:
  /// **'This only removes the charge from next month\'s plan. Your subscription stays active and will show again when that billing month arrives.'**
  String get finance_subscriptions_next_month_remove_message;

  /// No description provided for @finance_subscriptions_next_month_remove_confirm.
  ///
  /// In en, this message translates to:
  /// **'REMOVE'**
  String get finance_subscriptions_next_month_remove_confirm;

  /// No description provided for @finance_subscriptions_next_month_remove_action.
  ///
  /// In en, this message translates to:
  /// **'REMOVE FROM PLAN'**
  String get finance_subscriptions_next_month_remove_action;

  /// No description provided for @finance_subscription_due_today.
  ///
  /// In en, this message translates to:
  /// **'DUE TODAY'**
  String get finance_subscription_due_today;

  /// No description provided for @finance_subscription_days_left.
  ///
  /// In en, this message translates to:
  /// **'{days} DAYS LEFT'**
  String finance_subscription_days_left(int days);

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

  /// No description provided for @finance_cat_human_capital.
  ///
  /// In en, this message translates to:
  /// **'Human capital'**
  String get finance_cat_human_capital;

  /// No description provided for @finance_inflow_pillar_human_capital.
  ///
  /// In en, this message translates to:
  /// **'Human capital'**
  String get finance_inflow_pillar_human_capital;

  /// No description provided for @finance_inflow_pillar_liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get finance_inflow_pillar_liquidity;

  /// No description provided for @finance_inflow_pillar_fixed_income.
  ///
  /// In en, this message translates to:
  /// **'Fixed income'**
  String get finance_inflow_pillar_fixed_income;

  /// No description provided for @finance_inflow_pillar_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get finance_inflow_pillar_investment;

  /// No description provided for @finance_inflow_pillar_cashflow.
  ///
  /// In en, this message translates to:
  /// **'Cashflow'**
  String get finance_inflow_pillar_cashflow;

  /// No description provided for @finance_inflow_pillars_title.
  ///
  /// In en, this message translates to:
  /// **'Inflow layers'**
  String get finance_inflow_pillars_title;

  /// No description provided for @finance_inflow_pillars_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Skills & work, cash buffer, steady yield, growth assets, recurring systems'**
  String get finance_inflow_pillars_subtitle;

  /// No description provided for @finance_asset_pillars_title.
  ///
  /// In en, this message translates to:
  /// **'Asset layers'**
  String get finance_asset_pillars_title;

  /// No description provided for @finance_asset_pillars_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Liquidity, fixed income, investment, cashflow'**
  String get finance_asset_pillars_subtitle;

  /// No description provided for @finance_asset_pillar_liquidity.
  ///
  /// In en, this message translates to:
  /// **'Liquidity'**
  String get finance_asset_pillar_liquidity;

  /// No description provided for @finance_asset_pillar_fixed_income.
  ///
  /// In en, this message translates to:
  /// **'Fixed income'**
  String get finance_asset_pillar_fixed_income;

  /// No description provided for @finance_asset_pillar_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get finance_asset_pillar_investment;

  /// No description provided for @finance_asset_pillar_cashflow.
  ///
  /// In en, this message translates to:
  /// **'Cashflow'**
  String get finance_asset_pillar_cashflow;

  /// No description provided for @finance_record_section_title.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get finance_record_section_title;

  /// No description provided for @finance_record_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Add accounts, assets, human capital, and subscriptions'**
  String get finance_record_section_subtitle;

  /// No description provided for @finance_record_human_capital.
  ///
  /// In en, this message translates to:
  /// **'Human capital'**
  String get finance_record_human_capital;

  /// No description provided for @finance_record_human_capital_hint.
  ///
  /// In en, this message translates to:
  /// **'Capacity (imputed value)'**
  String get finance_record_human_capital_hint;

  /// No description provided for @finance_record_liquidity_account.
  ///
  /// In en, this message translates to:
  /// **'Liquidity account'**
  String get finance_record_liquidity_account;

  /// No description provided for @finance_record_liquidity_hint.
  ///
  /// In en, this message translates to:
  /// **'Cash, checking'**
  String get finance_record_liquidity_hint;

  /// No description provided for @finance_record_fixed_income_asset.
  ///
  /// In en, this message translates to:
  /// **'Fixed income asset'**
  String get finance_record_fixed_income_asset;

  /// No description provided for @finance_record_fixed_income_hint.
  ///
  /// In en, this message translates to:
  /// **'Bond, savings'**
  String get finance_record_fixed_income_hint;

  /// No description provided for @finance_record_investment_account.
  ///
  /// In en, this message translates to:
  /// **'Investment account'**
  String get finance_record_investment_account;

  /// No description provided for @finance_record_investment_account_hint.
  ///
  /// In en, this message translates to:
  /// **'Broker, crypto wallet'**
  String get finance_record_investment_account_hint;

  /// No description provided for @finance_record_investment_holding.
  ///
  /// In en, this message translates to:
  /// **'Investment holding'**
  String get finance_record_investment_holding;

  /// No description provided for @finance_record_investment_holding_hint.
  ///
  /// In en, this message translates to:
  /// **'Stock, crypto, real estate'**
  String get finance_record_investment_holding_hint;

  /// No description provided for @finance_account_type_checking.
  ///
  /// In en, this message translates to:
  /// **'Checking'**
  String get finance_account_type_checking;

  /// No description provided for @finance_account_type_savings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get finance_account_type_savings;

  /// No description provided for @finance_account_type_cash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get finance_account_type_cash;

  /// No description provided for @finance_account_type_credit_card.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get finance_account_type_credit_card;

  /// No description provided for @finance_account_type_deposit.
  ///
  /// In en, this message translates to:
  /// **'Term deposit'**
  String get finance_account_type_deposit;

  /// No description provided for @finance_account_type_investment.
  ///
  /// In en, this message translates to:
  /// **'Investment account'**
  String get finance_account_type_investment;

  /// No description provided for @finance_budget_limit_title.
  ///
  /// In en, this message translates to:
  /// **'Budget limit'**
  String get finance_budget_limit_title;

  /// No description provided for @finance_budget_limit_label.
  ///
  /// In en, this message translates to:
  /// **'Limit amount'**
  String get finance_budget_limit_label;

  /// No description provided for @finance_budget_limit_per_week.
  ///
  /// In en, this message translates to:
  /// **'Per week'**
  String get finance_budget_limit_per_week;

  /// No description provided for @finance_budget_limit_per_month.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get finance_budget_limit_per_month;

  /// No description provided for @finance_add_account_title.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get finance_add_account_title;

  /// No description provided for @finance_account_type_section.
  ///
  /// In en, this message translates to:
  /// **'Account type'**
  String get finance_account_type_section;

  /// No description provided for @finance_accounts_liquidity_title.
  ///
  /// In en, this message translates to:
  /// **'Liquidity accounts'**
  String get finance_accounts_liquidity_title;

  /// No description provided for @finance_accounts_investment_title.
  ///
  /// In en, this message translates to:
  /// **'Investment accounts'**
  String get finance_accounts_investment_title;

  /// No description provided for @finance_account_investment_name_hint.
  ///
  /// In en, this message translates to:
  /// **'e.g. VNDirect, SSI, Binance'**
  String get finance_account_investment_name_hint;

  /// No description provided for @finance_record_cashflow_asset.
  ///
  /// In en, this message translates to:
  /// **'Cashflow asset'**
  String get finance_record_cashflow_asset;

  /// No description provided for @finance_record_cashflow_hint.
  ///
  /// In en, this message translates to:
  /// **'SaaS, recurring system'**
  String get finance_record_cashflow_hint;

  /// No description provided for @finance_record_subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get finance_record_subscription;

  /// No description provided for @finance_record_subscription_hint.
  ///
  /// In en, this message translates to:
  /// **'Recurring expense'**
  String get finance_record_subscription_hint;

  /// No description provided for @finance_record_contract_hint.
  ///
  /// In en, this message translates to:
  /// **'One-time project or contract pay'**
  String get finance_record_contract_hint;

  /// No description provided for @finance_record_bonus_hint.
  ///
  /// In en, this message translates to:
  /// **'One-time bonus payment'**
  String get finance_record_bonus_hint;

  /// No description provided for @finance_bonus_section_title.
  ///
  /// In en, this message translates to:
  /// **'Bonus & Contract'**
  String get finance_bonus_section_title;

  /// No description provided for @finance_bonus_section_subtitle.
  ///
  /// In en, this message translates to:
  /// **'One-time income from bonuses and contracts'**
  String get finance_bonus_section_subtitle;

  /// No description provided for @finance_bonus_section_total.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get finance_bonus_section_total;

  /// No description provided for @finance_bonus_section_empty.
  ///
  /// In en, this message translates to:
  /// **'No bonus or contract income yet'**
  String get finance_bonus_section_empty;

  /// No description provided for @finance_total_income_title.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get finance_total_income_title;

  /// No description provided for @finance_total_income_recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring / month'**
  String get finance_total_income_recurring;

  /// No description provided for @finance_total_income_onetime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get finance_total_income_onetime;

  /// No description provided for @finance_hc_capacity_label.
  ///
  /// In en, this message translates to:
  /// **'Capacity'**
  String get finance_hc_capacity_label;

  /// No description provided for @finance_hc_realized_label.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get finance_hc_realized_label;

  /// No description provided for @finance_hc_gap_title.
  ///
  /// In en, this message translates to:
  /// **'Human capital'**
  String get finance_hc_gap_title;

  /// No description provided for @finance_hc_gap_message.
  ///
  /// In en, this message translates to:
  /// **'Capacity {capacity} · received {received} · gap {gap}'**
  String finance_hc_gap_message(String capacity, String received, String gap);

  /// No description provided for @finance_add_asset_title.
  ///
  /// In en, this message translates to:
  /// **'Add asset'**
  String get finance_add_asset_title;

  /// No description provided for @finance_add_asset_category.
  ///
  /// In en, this message translates to:
  /// **'Asset type'**
  String get finance_add_asset_category;

  /// No description provided for @finance_add_asset_name.
  ///
  /// In en, this message translates to:
  /// **'Name / symbol'**
  String get finance_add_asset_name;

  /// No description provided for @finance_add_asset_value.
  ///
  /// In en, this message translates to:
  /// **'Estimated value'**
  String get finance_add_asset_value;

  /// No description provided for @finance_add_asset_save.
  ///
  /// In en, this message translates to:
  /// **'Save asset'**
  String get finance_add_asset_save;

  /// No description provided for @finance_asset_cat_stock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get finance_asset_cat_stock;

  /// No description provided for @finance_asset_cat_crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get finance_asset_cat_crypto;

  /// No description provided for @finance_asset_cat_bond.
  ///
  /// In en, this message translates to:
  /// **'Bond'**
  String get finance_asset_cat_bond;

  /// No description provided for @finance_asset_cat_deposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get finance_asset_cat_deposit;

  /// No description provided for @finance_asset_cat_real_estate.
  ///
  /// In en, this message translates to:
  /// **'Real estate'**
  String get finance_asset_cat_real_estate;

  /// No description provided for @finance_asset_cat_cashflow.
  ///
  /// In en, this message translates to:
  /// **'Cashflow (SaaS)'**
  String get finance_asset_cat_cashflow;

  /// No description provided for @finance_cat_skills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get finance_cat_skills;

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

  /// No description provided for @finance_cat_impulse.
  ///
  /// In en, this message translates to:
  /// **'Impulse win'**
  String get finance_cat_impulse;

  /// No description provided for @finance_quick_save_title.
  ///
  /// In en, this message translates to:
  /// **'Log savings'**
  String get finance_quick_save_title;

  /// No description provided for @finance_quick_save_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Money you set aside—often because you said no to spending.'**
  String get finance_quick_save_subtitle;

  /// No description provided for @finance_quick_note_label.
  ///
  /// In en, this message translates to:
  /// **'What you didn’t buy (optional)'**
  String get finance_quick_note_label;

  /// No description provided for @finance_quick_full_form.
  ///
  /// In en, this message translates to:
  /// **'All fields'**
  String get finance_quick_full_form;

  /// No description provided for @finance_quick_log.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get finance_quick_log;

  /// No description provided for @finance_quick_chip_impulse.
  ///
  /// In en, this message translates to:
  /// **'Resisted urge'**
  String get finance_quick_chip_impulse;

  /// No description provided for @finance_quick_chip_coffee.
  ///
  /// In en, this message translates to:
  /// **'Skipped treat'**
  String get finance_quick_chip_coffee;

  /// No description provided for @finance_quick_chip_shopping.
  ///
  /// In en, this message translates to:
  /// **'Walked away'**
  String get finance_quick_chip_shopping;

  /// No description provided for @finance_quick_chip_sale.
  ///
  /// In en, this message translates to:
  /// **'Passed on sale'**
  String get finance_quick_chip_sale;

  /// No description provided for @finance_quick_chip_goal.
  ///
  /// In en, this message translates to:
  /// **'To a goal'**
  String get finance_quick_chip_goal;

  /// No description provided for @finance_quick_chip_emergency.
  ///
  /// In en, this message translates to:
  /// **'Safety net'**
  String get finance_quick_chip_emergency;

  /// No description provided for @finance_quick_desc_impulse.
  ///
  /// In en, this message translates to:
  /// **'Resisted an impulse buy'**
  String get finance_quick_desc_impulse;

  /// No description provided for @finance_quick_desc_coffee.
  ///
  /// In en, this message translates to:
  /// **'Skipped a coffee or snack run'**
  String get finance_quick_desc_coffee;

  /// No description provided for @finance_quick_desc_shopping.
  ///
  /// In en, this message translates to:
  /// **'Walked away from a purchase'**
  String get finance_quick_desc_shopping;

  /// No description provided for @finance_quick_desc_sale.
  ///
  /// In en, this message translates to:
  /// **'Didn’t chase a sale'**
  String get finance_quick_desc_sale;

  /// No description provided for @finance_quick_desc_goal.
  ///
  /// In en, this message translates to:
  /// **'Stashed toward a goal'**
  String get finance_quick_desc_goal;

  /// No description provided for @finance_quick_desc_emergency.
  ///
  /// In en, this message translates to:
  /// **'Added to emergency fund'**
  String get finance_quick_desc_emergency;

  /// No description provided for @finance_quick_affirm_impulse.
  ///
  /// In en, this message translates to:
  /// **'You just paid your future self.'**
  String get finance_quick_affirm_impulse;

  /// No description provided for @finance_quick_affirm_coffee.
  ///
  /// In en, this message translates to:
  /// **'Small skip, big discipline.'**
  String get finance_quick_affirm_coffee;

  /// No description provided for @finance_quick_affirm_shopping.
  ///
  /// In en, this message translates to:
  /// **'You chose calm over cart.'**
  String get finance_quick_affirm_shopping;

  /// No description provided for @finance_quick_affirm_sale.
  ///
  /// In en, this message translates to:
  /// **'You didn’t let a discount decide for you.'**
  String get finance_quick_affirm_sale;

  /// No description provided for @finance_quick_affirm_goal.
  ///
  /// In en, this message translates to:
  /// **'One step closer.'**
  String get finance_quick_affirm_goal;

  /// No description provided for @finance_quick_affirm_emergency.
  ///
  /// In en, this message translates to:
  /// **'Your safety net got stronger.'**
  String get finance_quick_affirm_emergency;

  /// No description provided for @finance_quick_affirm_default.
  ///
  /// In en, this message translates to:
  /// **'Saved. Consistency compounds.'**
  String get finance_quick_affirm_default;

  /// No description provided for @finance_quick_chip_custom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get finance_quick_chip_custom;

  /// No description provided for @finance_award_unlocked.
  ///
  /// In en, this message translates to:
  /// **'AWARD UNLOCKED'**
  String get finance_award_unlocked;

  /// No description provided for @finance_award_first_save_title.
  ///
  /// In en, this message translates to:
  /// **'First Brick Laid'**
  String get finance_award_first_save_title;

  /// No description provided for @finance_award_first_save_desc.
  ///
  /// In en, this message translates to:
  /// **'You logged your first savings entry.'**
  String get finance_award_first_save_desc;

  /// No description provided for @finance_award_three_streak_title.
  ///
  /// In en, this message translates to:
  /// **'Three in a Row'**
  String get finance_award_three_streak_title;

  /// No description provided for @finance_award_three_streak_desc.
  ///
  /// In en, this message translates to:
  /// **'Three days in a row choosing to save.'**
  String get finance_award_three_streak_desc;

  /// No description provided for @finance_award_seven_streak_title.
  ///
  /// In en, this message translates to:
  /// **'Iron Will Week'**
  String get finance_award_seven_streak_title;

  /// No description provided for @finance_award_seven_streak_desc.
  ///
  /// In en, this message translates to:
  /// **'Seven consecutive days of saving.'**
  String get finance_award_seven_streak_desc;

  /// No description provided for @finance_award_thirty_streak_title.
  ///
  /// In en, this message translates to:
  /// **'Compounding Mind'**
  String get finance_award_thirty_streak_title;

  /// No description provided for @finance_award_thirty_streak_desc.
  ///
  /// In en, this message translates to:
  /// **'Thirty days of showing up for yourself.'**
  String get finance_award_thirty_streak_desc;

  /// No description provided for @finance_award_hundred_title.
  ///
  /// In en, this message translates to:
  /// **'First Hundred'**
  String get finance_award_hundred_title;

  /// No description provided for @finance_award_hundred_desc.
  ///
  /// In en, this message translates to:
  /// **'Your lifetime savings log crossed a hundred.'**
  String get finance_award_hundred_desc;

  /// No description provided for @finance_award_thousand_title.
  ///
  /// In en, this message translates to:
  /// **'Four Figures'**
  String get finance_award_thousand_title;

  /// No description provided for @finance_award_thousand_desc.
  ///
  /// In en, this message translates to:
  /// **'Over a thousand set aside. That’s momentum.'**
  String get finance_award_thousand_desc;

  /// No description provided for @finance_award_impulse_ten_title.
  ///
  /// In en, this message translates to:
  /// **'Master of Urges'**
  String get finance_award_impulse_ten_title;

  /// No description provided for @finance_award_impulse_ten_desc.
  ///
  /// In en, this message translates to:
  /// **'Ten impulse wins logged. Your wiring is changing.'**
  String get finance_award_impulse_ten_desc;

  /// No description provided for @finance_streak_best.
  ///
  /// In en, this message translates to:
  /// **'Best: {count} days'**
  String finance_streak_best(int count);

  /// No description provided for @finance_streak_day_one.
  ///
  /// In en, this message translates to:
  /// **'Start the chain'**
  String get finance_streak_day_one;

  /// No description provided for @finance_streak_keep.
  ///
  /// In en, this message translates to:
  /// **'Don’t break it'**
  String get finance_streak_keep;

  /// No description provided for @finance_streak_strong.
  ///
  /// In en, this message translates to:
  /// **'You’re building something real.'**
  String get finance_streak_strong;

  /// No description provided for @finance_overview_streak_accessibility.
  ///
  /// In en, this message translates to:
  /// **'Open savings streak'**
  String get finance_overview_streak_accessibility;

  /// No description provided for @finance_streak_label.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get finance_streak_label;

  /// No description provided for @finance_streak_days.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String finance_streak_days(int count);

  /// No description provided for @finance_quick_mood_prompt.
  ///
  /// In en, this message translates to:
  /// **'How do you feel right now?'**
  String get finance_quick_mood_prompt;

  /// No description provided for @finance_quick_why_label.
  ///
  /// In en, this message translates to:
  /// **'Why this save?'**
  String get finance_quick_why_label;

  /// No description provided for @finance_cat_crypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get finance_cat_crypto;

  /// No description provided for @finance_cat_stock.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
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

  /// No description provided for @ssh_connect_host_first.
  ///
  /// In en, this message translates to:
  /// **'Connect to a host first to manage live sessions.'**
  String get ssh_connect_host_first;

  /// No description provided for @ssh_cursor_api_title.
  ///
  /// In en, this message translates to:
  /// **'Cursor API'**
  String get ssh_cursor_api_title;

  /// No description provided for @ssh_cursor_api_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Save your API key to drive cursor-agent on the remote host.'**
  String get ssh_cursor_api_subtitle;

  /// No description provided for @ssh_cursor_api_key_hint.
  ///
  /// In en, this message translates to:
  /// **'cursor_…'**
  String get ssh_cursor_api_key_hint;

  /// No description provided for @ssh_cursor_api_key_stored.
  ///
  /// In en, this message translates to:
  /// **'API key saved on this device.'**
  String get ssh_cursor_api_key_stored;

  /// No description provided for @ssh_cursor_api_save.
  ///
  /// In en, this message translates to:
  /// **'Save key'**
  String get ssh_cursor_api_save;

  /// No description provided for @ssh_cursor_api_test.
  ///
  /// In en, this message translates to:
  /// **'Test connection'**
  String get ssh_cursor_api_test;

  /// No description provided for @ssh_cursor_api_open_terminal.
  ///
  /// In en, this message translates to:
  /// **'Open SSH (Cursor mode)'**
  String get ssh_cursor_api_open_terminal;

  /// No description provided for @ssh_cursor_api_saved.
  ///
  /// In en, this message translates to:
  /// **'Cursor API key saved.'**
  String get ssh_cursor_api_saved;

  /// No description provided for @ssh_cursor_api_test_ok.
  ///
  /// In en, this message translates to:
  /// **'Cursor API key is valid.'**
  String get ssh_cursor_api_test_ok;

  /// No description provided for @ssh_cursor_api_missing_key.
  ///
  /// In en, this message translates to:
  /// **'Enter or save a Cursor API key first.'**
  String get ssh_cursor_api_missing_key;

  /// No description provided for @cursor_hub_title.
  ///
  /// In en, this message translates to:
  /// **'Cursor'**
  String get cursor_hub_title;

  /// No description provided for @cursor_hub_page_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Control Cursor on your Mac via My Machines and Cloud Agents — no SSH required.'**
  String get cursor_hub_page_subtitle;

  /// No description provided for @cursor_hub_canvas_subtitle.
  ///
  /// In en, this message translates to:
  /// **'My Machines worker, API tasks, and agents dashboard'**
  String get cursor_hub_canvas_subtitle;

  /// No description provided for @cursor_hub_integration_subtitle.
  ///
  /// In en, this message translates to:
  /// **'API key, worker setup, send tasks from your phone'**
  String get cursor_hub_integration_subtitle;

  /// No description provided for @cursor_hub_section_title.
  ///
  /// In en, this message translates to:
  /// **'AI & automation'**
  String get cursor_hub_section_title;

  /// No description provided for @cursor_hub_key_ready.
  ///
  /// In en, this message translates to:
  /// **'API key verified'**
  String get cursor_hub_key_ready;

  /// No description provided for @cursor_hub_open_full.
  ///
  /// In en, this message translates to:
  /// **'Open Cursor Hub'**
  String get cursor_hub_open_full;

  /// No description provided for @cursor_hub_open_agents.
  ///
  /// In en, this message translates to:
  /// **'Open Agents'**
  String get cursor_hub_open_agents;

  /// No description provided for @cursor_hub_worker_title.
  ///
  /// In en, this message translates to:
  /// **'My Machine worker'**
  String get cursor_hub_worker_title;

  /// No description provided for @cursor_hub_worker_body.
  ///
  /// In en, this message translates to:
  /// **'On your Mac, run this in Terminal and keep it open. Your machine then appears at cursor.com/agents.'**
  String get cursor_hub_worker_body;

  /// No description provided for @cursor_hub_copy_worker_cmd.
  ///
  /// In en, this message translates to:
  /// **'Copy command'**
  String get cursor_hub_copy_worker_cmd;

  /// No description provided for @cursor_hub_worker_copied.
  ///
  /// In en, this message translates to:
  /// **'Copied: agent worker start'**
  String get cursor_hub_worker_copied;

  /// No description provided for @cursor_hub_send_title.
  ///
  /// In en, this message translates to:
  /// **'Send a task'**
  String get cursor_hub_send_title;

  /// No description provided for @cursor_hub_target_machine.
  ///
  /// In en, this message translates to:
  /// **'My Mac'**
  String get cursor_hub_target_machine;

  /// No description provided for @cursor_hub_target_cloud.
  ///
  /// In en, this message translates to:
  /// **'Cloud repo'**
  String get cursor_hub_target_cloud;

  /// No description provided for @cursor_hub_machine_name.
  ///
  /// In en, this message translates to:
  /// **'Machine name (optional)'**
  String get cursor_hub_machine_name;

  /// No description provided for @cursor_hub_machine_name_hint.
  ///
  /// In en, this message translates to:
  /// **'As shown in Agents environment dropdown'**
  String get cursor_hub_machine_name_hint;

  /// No description provided for @cursor_hub_pick_repo.
  ///
  /// In en, this message translates to:
  /// **'Your repositories'**
  String get cursor_hub_pick_repo;

  /// No description provided for @cursor_hub_refresh_repos.
  ///
  /// In en, this message translates to:
  /// **'Refresh repo list'**
  String get cursor_hub_refresh_repos;

  /// No description provided for @cursor_hub_repos_empty.
  ///
  /// In en, this message translates to:
  /// **'No repos found. Enter a URL below or run on Mac to scan ~/Code.'**
  String get cursor_hub_repos_empty;

  /// No description provided for @cursor_hub_usage_limit.
  ///
  /// In en, this message translates to:
  /// **'Cloud agent blocked: enable usage-based pricing on cursor.com (need ~\$2 spend limit). Use My Mac mode instead.'**
  String get cursor_hub_usage_limit;

  /// No description provided for @cursor_hub_repo_url.
  ///
  /// In en, this message translates to:
  /// **'GitHub repo URL'**
  String get cursor_hub_repo_url;

  /// No description provided for @cursor_hub_prompt_label.
  ///
  /// In en, this message translates to:
  /// **'What should the agent do?'**
  String get cursor_hub_prompt_label;

  /// No description provided for @cursor_hub_send_task.
  ///
  /// In en, this message translates to:
  /// **'Send to Cursor'**
  String get cursor_hub_send_task;

  /// No description provided for @cursor_hub_task_sent.
  ///
  /// In en, this message translates to:
  /// **'Task sent — opening agent…'**
  String get cursor_hub_task_sent;

  /// No description provided for @cursor_hub_task_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not start agent: {reason}'**
  String cursor_hub_task_failed(String reason);

  /// No description provided for @cursor_hub_recent_title.
  ///
  /// In en, this message translates to:
  /// **'Recent agents'**
  String get cursor_hub_recent_title;

  /// No description provided for @island_cursor_ssh_standby.
  ///
  /// In en, this message translates to:
  /// **'Awaiting SSH link'**
  String get island_cursor_ssh_standby;

  /// No description provided for @island_cursor_no_api_key.
  ///
  /// In en, this message translates to:
  /// **'No API key'**
  String get island_cursor_no_api_key;

  /// No description provided for @ssh_cursor_api_test_fail.
  ///
  /// In en, this message translates to:
  /// **'Connection failed: {reason}'**
  String ssh_cursor_api_test_fail(String reason);

  /// No description provided for @ssh_go_to_terminal.
  ///
  /// In en, this message translates to:
  /// **'GO TO TERMINAL'**
  String get ssh_go_to_terminal;

  /// No description provided for @ssh_no_tmux_sessions.
  ///
  /// In en, this message translates to:
  /// **'No active tmux sessions found.'**
  String get ssh_no_tmux_sessions;

  /// No description provided for @journal.
  ///
  /// In en, this message translates to:
  /// **'Journal'**
  String get journal;

  /// No description provided for @social_notes.
  ///
  /// In en, this message translates to:
  /// **'Mind Notes'**
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

  /// No description provided for @sync_engine_title.
  ///
  /// In en, this message translates to:
  /// **'Sync Engine'**
  String get sync_engine_title;

  /// No description provided for @system_health.
  ///
  /// In en, this message translates to:
  /// **'SYSTEM HEALTH'**
  String get system_health;

  /// No description provided for @uptime.
  ///
  /// In en, this message translates to:
  /// **'UPTIME'**
  String get uptime;

  /// No description provided for @sync_method.
  ///
  /// In en, this message translates to:
  /// **'SYNC METHOD'**
  String get sync_method;

  /// No description provided for @refresh_rate.
  ///
  /// In en, this message translates to:
  /// **'REFRESH RATE'**
  String get refresh_rate;

  /// No description provided for @initialize_drive.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZE DRIVE'**
  String get initialize_drive;

  /// No description provided for @test_connection.
  ///
  /// In en, this message translates to:
  /// **'TEST CONNECTION'**
  String get test_connection;

  /// No description provided for @recent_activity.
  ///
  /// In en, this message translates to:
  /// **'RECENT ACTIVITY'**
  String get recent_activity;

  /// No description provided for @live_logs.
  ///
  /// In en, this message translates to:
  /// **'LIVE LOGS'**
  String get live_logs;

  /// No description provided for @select_folder.
  ///
  /// In en, this message translates to:
  /// **'SELECT FOLDER'**
  String get select_folder;

  /// No description provided for @my_drive.
  ///
  /// In en, this message translates to:
  /// **'My Drive'**
  String get my_drive;

  /// No description provided for @breadcrumb_separator.
  ///
  /// In en, this message translates to:
  /// **'>'**
  String get breadcrumb_separator;

  /// No description provided for @drive_notion_complete.
  ///
  /// In en, this message translates to:
  /// **'Drive → Notion Complete'**
  String get drive_notion_complete;

  /// No description provided for @scheduled_sweep.
  ///
  /// In en, this message translates to:
  /// **'Scheduled Sweep'**
  String get scheduled_sweep;

  /// No description provided for @standby.
  ///
  /// In en, this message translates to:
  /// **'STANDBY'**
  String get standby;

  /// No description provided for @target_folder_id.
  ///
  /// In en, this message translates to:
  /// **'TARGET FOLDER ID'**
  String get target_folder_id;

  /// No description provided for @internal_integration_token.
  ///
  /// In en, this message translates to:
  /// **'INTERNAL INTEGRATION TOKEN'**
  String get internal_integration_token;

  /// No description provided for @database_schema_id.
  ///
  /// In en, this message translates to:
  /// **'DATABASE SCHEMA ID'**
  String get database_schema_id;

  /// No description provided for @add_widget.
  ///
  /// In en, this message translates to:
  /// **'Add Widget'**
  String get add_widget;

  /// No description provided for @app_shortcut.
  ///
  /// In en, this message translates to:
  /// **'App Shortcut'**
  String get app_shortcut;

  /// No description provided for @web_widget.
  ///
  /// In en, this message translates to:
  /// **'Web Widget'**
  String get web_widget;

  /// No description provided for @please_select_app_page.
  ///
  /// In en, this message translates to:
  /// **'Please select an app page'**
  String get please_select_app_page;

  /// No description provided for @widget_added_success.
  ///
  /// In en, this message translates to:
  /// **'Widget added successfully'**
  String get widget_added_success;

  /// No description provided for @error_adding_widget.
  ///
  /// In en, this message translates to:
  /// **'Error adding widget: {error}'**
  String error_adding_widget(String error);

  /// No description provided for @please_select_plugin.
  ///
  /// In en, this message translates to:
  /// **'Please select a plugin'**
  String get please_select_plugin;

  /// No description provided for @please_fill_all_fields.
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get please_fill_all_fields;

  /// No description provided for @widget_name_hint.
  ///
  /// In en, this message translates to:
  /// **'Widget Name (e.g. Facebook)'**
  String get widget_name_hint;

  /// No description provided for @url_hint.
  ///
  /// In en, this message translates to:
  /// **'URL (e.g. facebook.com)'**
  String get url_hint;

  /// No description provided for @plugins.
  ///
  /// In en, this message translates to:
  /// **'Plugins'**
  String get plugins;

  /// No description provided for @custom_url.
  ///
  /// In en, this message translates to:
  /// **'Custom URL'**
  String get custom_url;

  /// No description provided for @settings_title.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings_title;

  /// No description provided for @mind_latest_note.
  ///
  /// In en, this message translates to:
  /// **'Latest Note'**
  String get mind_latest_note;

  /// No description provided for @common_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get common_done;

  /// No description provided for @island_app_name.
  ///
  /// In en, this message translates to:
  /// **'ICE GATE'**
  String get island_app_name;

  /// No description provided for @island_app_blocker.
  ///
  /// In en, this message translates to:
  /// **'APP BLOCKER'**
  String get island_app_blocker;

  /// No description provided for @island_initializing.
  ///
  /// In en, this message translates to:
  /// **'INITIALIZING…'**
  String get island_initializing;

  /// No description provided for @island_notifications.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get island_notifications;

  /// No description provided for @island_inbox.
  ///
  /// In en, this message translates to:
  /// **'INBOX'**
  String get island_inbox;

  /// No description provided for @island_documentation.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTATION'**
  String get island_documentation;

  /// No description provided for @island_canvas.
  ///
  /// In en, this message translates to:
  /// **'CANVAS'**
  String get island_canvas;

  /// No description provided for @island_mind.
  ///
  /// In en, this message translates to:
  /// **'MIND'**
  String get island_mind;

  /// No description provided for @island_health_data.
  ///
  /// In en, this message translates to:
  /// **'DATA'**
  String get island_health_data;

  /// No description provided for @island_nutrition.
  ///
  /// In en, this message translates to:
  /// **'NUTRITION'**
  String get island_nutrition;

  /// No description provided for @island_activity.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY'**
  String get island_activity;

  /// No description provided for @island_hydration.
  ///
  /// In en, this message translates to:
  /// **'HYDRATION'**
  String get island_hydration;

  /// No description provided for @island_focus.
  ///
  /// In en, this message translates to:
  /// **'FOCUS'**
  String get island_focus;

  /// No description provided for @island_steps.
  ///
  /// In en, this message translates to:
  /// **'STEPS'**
  String get island_steps;

  /// No description provided for @island_vitals.
  ///
  /// In en, this message translates to:
  /// **'VITALS'**
  String get island_vitals;

  /// No description provided for @island_sleep.
  ///
  /// In en, this message translates to:
  /// **'SLEEP'**
  String get island_sleep;

  /// No description provided for @island_calories.
  ///
  /// In en, this message translates to:
  /// **'CALORIES'**
  String get island_calories;

  /// No description provided for @island_spo2.
  ///
  /// In en, this message translates to:
  /// **'SpO₂'**
  String get island_spo2;

  /// No description provided for @island_biometrics.
  ///
  /// In en, this message translates to:
  /// **'BIOMETRICS'**
  String get island_biometrics;

  /// No description provided for @finance_tab_overview.
  ///
  /// In en, this message translates to:
  /// **'OVERVIEW'**
  String get finance_tab_overview;

  /// No description provided for @finance_tab_history.
  ///
  /// In en, this message translates to:
  /// **'HISTORY'**
  String get finance_tab_history;

  /// No description provided for @finance_tab_daily.
  ///
  /// In en, this message translates to:
  /// **'DAILY'**
  String get finance_tab_daily;

  /// No description provided for @finance_tab_daily_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Daily fun spending and income — pick a day on the calendar.'**
  String get finance_tab_daily_subtitle;

  /// No description provided for @finance_tab_achievements.
  ///
  /// In en, this message translates to:
  /// **'ACHIEVEMENTS'**
  String get finance_tab_achievements;

  /// No description provided for @finance_tab_career.
  ///
  /// In en, this message translates to:
  /// **'CAREER'**
  String get finance_tab_career;

  /// No description provided for @finance_job_title.
  ///
  /// In en, this message translates to:
  /// **'Job positions'**
  String get finance_job_title;

  /// No description provided for @finance_job_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Track employers, contracts, and tenure'**
  String get finance_job_subtitle;

  /// No description provided for @finance_job_empty.
  ///
  /// In en, this message translates to:
  /// **'No job positions yet'**
  String get finance_job_empty;

  /// No description provided for @finance_job_current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get finance_job_current;

  /// No description provided for @finance_job_ended.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get finance_job_ended;

  /// No description provided for @finance_job_tenure.
  ///
  /// In en, this message translates to:
  /// **'{months} months'**
  String finance_job_tenure(int months);

  /// No description provided for @finance_job_add.
  ///
  /// In en, this message translates to:
  /// **'Add position'**
  String get finance_job_add;

  /// No description provided for @finance_job_new.
  ///
  /// In en, this message translates to:
  /// **'New position'**
  String get finance_job_new;

  /// No description provided for @finance_job_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit position'**
  String get finance_job_edit;

  /// No description provided for @finance_job_employer.
  ///
  /// In en, this message translates to:
  /// **'Employer / company'**
  String get finance_job_employer;

  /// No description provided for @finance_job_role.
  ///
  /// In en, this message translates to:
  /// **'Job title / role'**
  String get finance_job_role;

  /// No description provided for @finance_job_contract_type.
  ///
  /// In en, this message translates to:
  /// **'Contract type'**
  String get finance_job_contract_type;

  /// No description provided for @finance_job_contract_full_time.
  ///
  /// In en, this message translates to:
  /// **'Full-time'**
  String get finance_job_contract_full_time;

  /// No description provided for @finance_job_contract_part_time.
  ///
  /// In en, this message translates to:
  /// **'Part-time'**
  String get finance_job_contract_part_time;

  /// No description provided for @finance_job_contract_freelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get finance_job_contract_freelance;

  /// No description provided for @finance_job_contract_internship.
  ///
  /// In en, this message translates to:
  /// **'Internship'**
  String get finance_job_contract_internship;

  /// No description provided for @finance_job_contract_contract.
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get finance_job_contract_contract;

  /// No description provided for @finance_job_start_date.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get finance_job_start_date;

  /// No description provided for @finance_job_end_date.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get finance_job_end_date;

  /// No description provided for @finance_job_end_date_hint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if current'**
  String get finance_job_end_date_hint;

  /// No description provided for @finance_job_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get finance_job_notes;

  /// No description provided for @finance_job_salary.
  ///
  /// In en, this message translates to:
  /// **'Monthly income'**
  String get finance_job_salary;

  /// No description provided for @finance_job_salary_hint.
  ///
  /// In en, this message translates to:
  /// **'Creates a fixed income linked to this job'**
  String get finance_job_salary_hint;

  /// No description provided for @finance_job_income_type.
  ///
  /// In en, this message translates to:
  /// **'Income type'**
  String get finance_job_income_type;

  /// No description provided for @finance_job_income_salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get finance_job_income_salary;

  /// No description provided for @finance_job_income_contract.
  ///
  /// In en, this message translates to:
  /// **'Contract income'**
  String get finance_job_income_contract;

  /// No description provided for @finance_job_income_bonus.
  ///
  /// In en, this message translates to:
  /// **'Bonus'**
  String get finance_job_income_bonus;

  /// No description provided for @finance_job_salary_suffix.
  ///
  /// In en, this message translates to:
  /// **'{amount} / mo'**
  String finance_job_salary_suffix(String amount);

  /// No description provided for @finance_job_on_day.
  ///
  /// In en, this message translates to:
  /// **'Working that day'**
  String get finance_job_on_day;

  /// No description provided for @finance_job_delete_confirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this job position?'**
  String get finance_job_delete_confirm;

  /// No description provided for @finance_job_end_confirm.
  ///
  /// In en, this message translates to:
  /// **'Mark this position as ended today?'**
  String get finance_job_end_confirm;

  /// No description provided for @finance_job_work_days.
  ///
  /// In en, this message translates to:
  /// **'Work days'**
  String get finance_job_work_days;

  /// No description provided for @finance_job_log_today.
  ///
  /// In en, this message translates to:
  /// **'Log today'**
  String get finance_job_log_today;

  /// No description provided for @finance_job_work_streak.
  ///
  /// In en, this message translates to:
  /// **'{count} day streak'**
  String finance_job_work_streak(int count);

  /// No description provided for @finance_achievements_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Major financial wins by month and year.'**
  String get finance_achievements_subtitle;

  /// No description provided for @finance_period_month.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get finance_period_month;

  /// No description provided for @finance_period_year.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get finance_period_year;

  /// No description provided for @finance_daily_in.
  ///
  /// In en, this message translates to:
  /// **'Money in'**
  String get finance_daily_in;

  /// No description provided for @finance_daily_out.
  ///
  /// In en, this message translates to:
  /// **'Money out'**
  String get finance_daily_out;

  /// No description provided for @finance_daily_empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged this day'**
  String get finance_daily_empty;

  /// No description provided for @finance_achievements_empty.
  ///
  /// In en, this message translates to:
  /// **'No major achievements in this period yet'**
  String get finance_achievements_empty;

  /// No description provided for @finance_achievements_add.
  ///
  /// In en, this message translates to:
  /// **'Record achievement'**
  String get finance_achievements_add;

  /// No description provided for @finance_milestone_month_income.
  ///
  /// In en, this message translates to:
  /// **'Monthly income recorded'**
  String get finance_milestone_month_income;

  /// No description provided for @finance_milestone_month_savings.
  ///
  /// In en, this message translates to:
  /// **'Monthly savings added'**
  String get finance_milestone_month_savings;

  /// No description provided for @finance_milestone_year_total.
  ///
  /// In en, this message translates to:
  /// **'Year total income'**
  String get finance_milestone_year_total;

  /// No description provided for @finance_tab_billing.
  ///
  /// In en, this message translates to:
  /// **'BILLING'**
  String get finance_tab_billing;

  /// No description provided for @finance_tab_saving.
  ///
  /// In en, this message translates to:
  /// **'SAVINGS'**
  String get finance_tab_saving;

  /// No description provided for @island_documents.
  ///
  /// In en, this message translates to:
  /// **'DOCUMENTS'**
  String get island_documents;

  /// No description provided for @island_editor.
  ///
  /// In en, this message translates to:
  /// **'EDITOR'**
  String get island_editor;

  /// No description provided for @island_identity.
  ///
  /// In en, this message translates to:
  /// **'IDENTITY'**
  String get island_identity;

  /// No description provided for @island_id_update.
  ///
  /// In en, this message translates to:
  /// **'ID UPDATE'**
  String get island_id_update;

  /// No description provided for @island_protocols.
  ///
  /// In en, this message translates to:
  /// **'PROTOCOLS'**
  String get island_protocols;

  /// No description provided for @island_sync_core.
  ///
  /// In en, this message translates to:
  /// **'SYNC CORE'**
  String get island_sync_core;

  /// No description provided for @island_settings.
  ///
  /// In en, this message translates to:
  /// **'SETTINGS'**
  String get island_settings;

  /// No description provided for @island_remote_ssh.
  ///
  /// In en, this message translates to:
  /// **'REMOTE SSH'**
  String get island_remote_ssh;

  /// No description provided for @island_connected.
  ///
  /// In en, this message translates to:
  /// **'CONNECTED'**
  String get island_connected;

  /// No description provided for @island_not_active.
  ///
  /// In en, this message translates to:
  /// **'NOT ACTIVE'**
  String get island_not_active;

  /// No description provided for @island_connect.
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get island_connect;

  /// No description provided for @island_tmux_active.
  ///
  /// In en, this message translates to:
  /// **'TMUX ACTIVE'**
  String get island_tmux_active;

  /// No description provided for @daily_loop_title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s loop'**
  String get daily_loop_title;

  /// No description provided for @daily_loop_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Complete all 4 pillars to extend your streak'**
  String get daily_loop_subtitle;

  /// No description provided for @daily_loop_complete.
  ///
  /// In en, this message translates to:
  /// **'Loop complete — you\'re on fire!'**
  String get daily_loop_complete;

  /// No description provided for @daily_loop_streak.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String daily_loop_streak(int count);

  /// No description provided for @daily_loop_progress.
  ///
  /// In en, this message translates to:
  /// **'{done} / {total} done'**
  String daily_loop_progress(int done, int total);

  /// No description provided for @daily_loop_health.
  ///
  /// In en, this message translates to:
  /// **'Health pulse'**
  String get daily_loop_health;

  /// No description provided for @daily_loop_finance.
  ///
  /// In en, this message translates to:
  /// **'Money check'**
  String get daily_loop_finance;

  /// No description provided for @daily_loop_mind.
  ///
  /// In en, this message translates to:
  /// **'Mood log'**
  String get daily_loop_mind;

  /// No description provided for @daily_loop_projects.
  ///
  /// In en, this message translates to:
  /// **'Project touch'**
  String get daily_loop_projects;

  /// No description provided for @morning_loop_reminder_title.
  ///
  /// In en, this message translates to:
  /// **'Morning push reminder'**
  String get morning_loop_reminder_title;

  /// No description provided for @morning_loop_reminder_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional phone notification — your in-app summary on Home works without this'**
  String get morning_loop_reminder_subtitle;

  /// No description provided for @morning_briefing_toggle.
  ///
  /// In en, this message translates to:
  /// **'Morning summary on Home'**
  String get morning_briefing_toggle;

  /// No description provided for @morning_briefing_today_schedule.
  ///
  /// In en, this message translates to:
  /// **'Today\'s schedule'**
  String get morning_briefing_today_schedule;

  /// No description provided for @morning_briefing_today_empty.
  ///
  /// In en, this message translates to:
  /// **'No events today — a clear day to plan.'**
  String get morning_briefing_today_empty;

  /// No description provided for @morning_briefing_today_connect_hint.
  ///
  /// In en, this message translates to:
  /// **'Connect Google or device calendar to see today\'s events here.'**
  String get morning_briefing_today_connect_hint;

  /// No description provided for @morning_briefing_today_more.
  ///
  /// In en, this message translates to:
  /// **'+{count} more in calendar'**
  String morning_briefing_today_more(int count);

  /// No description provided for @morning_briefing_all_day.
  ///
  /// In en, this message translates to:
  /// **'All day'**
  String get morning_briefing_all_day;

  /// No description provided for @morning_briefing_open_calendar.
  ///
  /// In en, this message translates to:
  /// **'Open calendar'**
  String get morning_briefing_open_calendar;

  /// No description provided for @morning_briefing_title.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get morning_briefing_title;

  /// No description provided for @morning_briefing_title_name.
  ///
  /// In en, this message translates to:
  /// **'Good morning, {name}'**
  String morning_briefing_title_name(String name);

  /// No description provided for @morning_briefing_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Care for body and mind — then finish your 4-pillar loop today.'**
  String get morning_briefing_subtitle;

  /// No description provided for @morning_briefing_yesterday_title.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get morning_briefing_yesterday_title;

  /// No description provided for @morning_briefing_yesterday_empty.
  ///
  /// In en, this message translates to:
  /// **'A quiet day — today is a fresh start.'**
  String get morning_briefing_yesterday_empty;

  /// No description provided for @morning_briefing_yesterday_steps.
  ///
  /// In en, this message translates to:
  /// **'{steps} steps'**
  String morning_briefing_yesterday_steps(int steps);

  /// No description provided for @morning_briefing_yesterday_water.
  ///
  /// In en, this message translates to:
  /// **'{ml} ml water'**
  String morning_briefing_yesterday_water(int ml);

  /// No description provided for @morning_briefing_yesterday_sleep.
  ///
  /// In en, this message translates to:
  /// **'{hours} h sleep'**
  String morning_briefing_yesterday_sleep(String hours);

  /// No description provided for @morning_briefing_yesterday_loop.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} pillars completed'**
  String morning_briefing_yesterday_loop(int done, int total);

  /// No description provided for @morning_briefing_motivation_title.
  ///
  /// In en, this message translates to:
  /// **'Today\'s motivation'**
  String get morning_briefing_motivation_title;

  /// No description provided for @morning_briefing_motivation_empty.
  ///
  /// In en, this message translates to:
  /// **'Yesterday was light — one small win today resets your rhythm.'**
  String get morning_briefing_motivation_empty;

  /// No description provided for @morning_briefing_motivation_all_done.
  ///
  /// In en, this message translates to:
  /// **'You closed yesterday strong — ride that momentum into today.'**
  String get morning_briefing_motivation_all_done;

  /// No description provided for @morning_briefing_motivation_strong.
  ///
  /// In en, this message translates to:
  /// **'Solid progress yesterday — one more pillar today keeps the streak alive.'**
  String get morning_briefing_motivation_strong;

  /// No description provided for @morning_briefing_motivation_mid.
  ///
  /// In en, this message translates to:
  /// **'You moved forward yesterday — stack another small win this morning.'**
  String get morning_briefing_motivation_mid;

  /// No description provided for @morning_briefing_motivation_low.
  ///
  /// In en, this message translates to:
  /// **'Yesterday was a rest day — water, a walk, or a mood log is enough to begin.'**
  String get morning_briefing_motivation_low;

  /// No description provided for @morning_briefing_progress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} pillars done today'**
  String morning_briefing_progress(int done, int total);

  /// No description provided for @morning_briefing_start.
  ///
  /// In en, this message translates to:
  /// **'Start my day'**
  String get morning_briefing_start;

  /// No description provided for @morning_briefing_log_mood.
  ///
  /// In en, this message translates to:
  /// **'Log mood first'**
  String get morning_briefing_log_mood;
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
