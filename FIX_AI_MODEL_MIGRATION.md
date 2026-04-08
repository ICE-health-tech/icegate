# FIX: AI Model Column Migration & PowerSync Schema

## Problem
The `SqliteException: no such column: ai_model` occurred because the `projects` table is managed by **PowerSync** as a local SQLite view. Drift's standard migration tool (`m.addColumn`) cannot be used on views, and adding it only to Drift's `Table` class does not automatically update the local PowerSync view.

## Solution Applied
1.  **Updated PowerSync Schema**: Added `Column.text('ai_model')` to the `projects` table in `lib/data_layer/DataSources/cloud_database/powersync_schema.dart`. This ensures that PowerSync will automatically recreate the local SQLite view with the new column upon app restart.
2.  **Fixed Drift Migration**: Removed the illegal `addColumn` call from `lib/data_layer/DataSources/local_database/Database.dart`. PowerSync-managed tables must NOT be migrated via Drift's `Migrator`.
3.  **Supabase Migration**: Created a new migration file `supabase/migrations/20260315000000_add_ai_model_to_projects.sql` to add the `ai_model`, `ssh_host_id`, and `remote_path` columns to the remote PostgreSQL database.
4.  **Documentation**: Updated `DATABASE.md` to include the new project-level settings.

## Instructions for User
To apply these changes and fix the error:
1.  **Supabase**: Run the newly created migration in your Supabase SQL Editor:
    ```sql
    ALTER TABLE projects ADD COLUMN IF NOT EXISTS ai_model text;
    ALTER TABLE projects ADD COLUMN IF NOT EXISTS ssh_host_id text;
    ALTER TABLE projects ADD COLUMN IF NOT EXISTS remote_path text;
    ```
2.  **Flutter**: Rebuild and restart the app.
    ```bash
    flutter pub get
    dart run build_runner build --delete-conflicting-outputs
    flutter run
    ```
    *Note: When the app restarts, PowerSync will notice the schema change in `powersync_schema.dart` and automatically recreate the local database views. This will resolve the "no such column" error.*
