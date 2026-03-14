# CHANGES: AI Prompt Database Persistence - 2026-03-14

## Overview
Migrated AI prompt storage from `SharedPreferences` to a dedicated `ai_prompts` table in the Drift database. This ensures more robust persistence and better alignment with the application's data architecture.

## Key Features
- **Database Backed**: Prompts are now stored in `ai_prompts` table, supporting multiple users (`person_id`) and multiple models (`ai_model`).
- **High Performance**: Uses `AiPromptsDAO` for efficient retrieval and updates.
- **Improved Consistency**: AI prompts are now part of the core database lifecycle, allowing for future sync or backup capabilities.
- **UI Integration**: `TalkSSHPage` now loads and saves prompts directly via the database DAO.

## Files Modified
- `lib/data_layer/DataSources/local_database/Database.dart`: Added `AiPromptsTable` and `AiPromptsDAO`.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: Switched from `SharedPreferences` to `AiPromptsDAO`.

## Verification
- Code analysis completed with `flutter analyze`.
- `build_runner` successfully generated updated database adapters.
