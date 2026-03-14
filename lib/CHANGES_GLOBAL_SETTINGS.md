# Change Report: Global App Settings Implementation

## Overview
Implemented a centralized, reactive global settings framework to manage application-wide preferences across different modalities (Health, Social, Finance, Projects).

## Key Features
- **Centralized Configuration Database**: Added `configs` table to Drift database for structured settings persistence.
- **Reactive Orchestration**: Introduced `ConfigBlock` using Signals for app-wide reactivity without unnecessary rebuilds.
- **Categorized Settings UI**: Redesigned the Settings page to include dedicated sections for each major life hub.
- **Global Currency Sync**: Refactored the Finance modality to synchronize its currency unit (VND/USD) with the global app settings.

## Modified Files
- `lib/data_layer/DataSources/local_database/Database.dart`: Added `ConfigsTable` and `ConfigsDAO`.
- `lib/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart`: [NEW] Reactive settings manager.
- `lib/initial_layer/DataLayer.dart`: Integrated `ConfigBlock` into the provider tree.
- `lib/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart`: Refactored to use global currency setting.
- `lib/ui_layer/ReusableWidget/SettingWidget.dart`: Updated UI with new sections and currency toggle.

## Verification
- Verified database persistence after app restart.
- Confirmed reactive UI updates in Finance section when toggling currency in Global Settings.
