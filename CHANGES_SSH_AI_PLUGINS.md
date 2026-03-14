# CHANGES: Consolidated UPLINK AI Plugin - 2026-03-14

## Overview
Consolidated "Gemini SSH" and "OpenCode SSH" into a single, intelligent "**UPLINK AI Controller**". Users can now toggle between AI providers directly within the SSH page, with their preference persisting across sessions.

## Key Features
- **Consolidated Plugin**: Single entry in the Canvas store named "UPLINK AI Controller".
- **AI Mode Switcher**: Integrated toggle in the `TalkSSHPage` AppBar to switch between Gemini and OpenCode.
- **Database Persistence**: Selection is saved to the `internal_widgets` table in the Drift database, ensuring it's remembered after restarts.
- **Provider-Specific CLI**:
  - **Gemini**: Sends `gemini prompt "..."`
  - **OpenCode**: Sends `opencode run "..."`
- **Branding**: Unique icons for modes (Auto-Awesome for Gemini, Code for OpenCode).

## Files Modified
- `lib/data_layer/DataSources/local_database/Database.dart`: Added `updateInternalWidgetUrl` and `getInternalWidgetByAlias`.
- `lib/ui_layer/home_page/HomePage.dart`: Consolidated seeder and cleanup of legacy plugins.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: Implemented the switcher UI, database persistence, and specialized CLI logic.

## Verification
- Verified with `flutter analyze`.
- Logic confirms persistence via `InternalWidgetsDAO` update calls.
