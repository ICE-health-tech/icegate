# Changes Report - PowerSync Sync Rules Update
**Date:** 2026-04-17
**Task:** Update PowerSync sync rules to include weight_logs and stabilize sync buckets.

## Overview
Updated the `sync_rules.yaml` file to include the `weight_logs` table for synchronization and reorganized the `user_bucket` list for better clarity and stability.

## Specific Changes
### Sync Rules (`sync_rules.yaml`)
- Added `weight_logs` to `user_bucket`.
- Consolidated the `user_bucket` list to remove redundant entries for `exercise_logs` and `focus_sessions`.
- Maintained existing mappings for `tenant_bucket` and `global_bucket`.

## Table Sync List (Updated)
The following tables are now synced in the `user_bucket`:
- `persons`
- `profiles`
- `project_notes`
- `projects`
- `email_addresses`
- `user_accounts`
- `detail_information`
- `skills`
- `weight_logs` **(NEW)**
- `exercise_logs`
- `focus_sessions`
- `financial_accounts`
- `assets`
- `transactions`
- `goals`
- `scores`
- `habits`
- `person_widgets`
- `health_metrics`
- `hourly_activity_log`
- `water_logs`
- `sleep_logs`
- `quests`
- `meals`
- `sessions`

## Verification
- Verified `WeightLogsTable` exists in `lib/data_layer/DataSources/local_database/database.dart` (line 1412).
- YAML structure validated for correctness.
