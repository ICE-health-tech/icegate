# Change Report: Architecture Documentation

## Date: 2026-03-12

## Description
Created a comprehensive `ARCHITECTURE.md` file in the project root to document the high-level design, layered architecture, state management patterns, and initialization flow of the ICE Gate project.

## Changes
- **New File**: `ARCHITECTURE.md`
    - Detailed documentation of the five architectural layers: Data, Orchestration, Initial, Security & Routing, and UI.
    - Explanation of the **Signals + Provider** state management pattern.
    - Description of the **PowerSync + Supabase** offline-first sync strategy.
    - Breakdown of the app's initialization sequence in `DataLayer.dart`.

## Impact
- Improves developer onboarding by providing a clear architectural map.
- Standardizes the understanding of component roles and responsibilities.
- Documents core design principles like offline-first and reactive integrity.

## Verification
- Verified directory structures against the documented layers.
- Validated the initialization flow by analyzing `lib/main.dart` and `lib/initial_layer/DataLayer.dart`.
- Confirmed state management patterns by reviewing `ReactiveBlock` usage in the codebase.
# Quest System Upgrade Report - March 13, 2026

## Objective
Enhance the Quest system to align with real-life activities and implement automated daily generation with multiple quest types (Daily and Secret).

## Implemented Changes

### 1. Database Schema Enhancements (`Database.dart`)
- **QuestsTable**:
    - Added `questType` column to identify specific real-life activities (e.g., 'walking', 'running', 'swimming', 'pushups').
    - Refined `type` column documentation to include 'daily', 'weekly', 'secret', and 'system'.
- **ProfilesTable**:
    - Added `lastQuestGeneratedAt` column to track when the last batch of daily quests was generated for a user, preventing multiple generations in a single day.
- **PersonManagementDAO**:
    - Added `updateLastQuestGeneratedAt` method to update the generation timestamp.
    - Added `deleteAllQuestsByPerson` (helper for potential future resets).

### 2. Quest Generation Logic (`QuestService.dart`)
- Created a new `QuestService` class to handle business logic for quests.
- **Daily Generation**: Checks if quests have been generated today. If not, it picks 2 random health-related quests from a real-life template pool.
- **Real-life Templates**:
    - **Morning Run**: 30 minutes.
    - **Walking Master**: 10,000 steps.
    - **Swimming Session**: 45 minutes.
    - **Pushup Challenge**: 50 pushups.
- **Secret Quests**: Implemented a 30% chance each day to generate a "Secret Quest" with high rewards (150 XP) and hidden descriptions.

### 3. Reactive Integration (`QuestBlock.dart` & `DataLayer.dart`)
- **QuestBlock**: Updated `init` to accept the full `AppDatabase`. It now triggers the `QuestService.generateDailyQuestsIfNeeded` during initialization.
- **DataLayer**: Updated the block initialization sequence to pass the database instance to `QuestBlock`.

## Real-life Mapping
- The `questType` field now allows the app to map specific incoming data (Health, Pedometer) to quest progress based on activity type.
- **Finance Integration**: Added a specific "Virtual Office Budget" quest template to help users manage recurring business expenses (e.g., Green Office at 650,000 VND).
- **Project Notes**: Seeded a permanent information note for "Văn phòng ảo" in the finance category for quick reference to pricing and service links.

## Next Steps
- Implement UI indicators to distinguish between "Daily" and "Secret" quests.
- Add specific data listeners for "Swimming" and "Pushups" (manual entry or AR-based detection).
# CHANGES: SSH Background Persistence & Session Recovery

This update addresses the requirement for SSH connections to remain active when the phone is locked or the app is moved to the background. It combines client-side lifecycle management with server-side session persistence.

## Key Improvements

### 1. Server-Side Persistence (`tmux`)
- Added a **Persistent Session (tmux)** toggle to the SSH connection sheet (enabled by default).
- Upon connection, the app automatically executes `tmux attach -t ice_gate || tmux new-session -s ice_gate`.
- This ensures that your work on the server survives even if the app process is killed or the network is interrupted.

### 2. App Lifecycle Integration
- `SSHService` now implements `WidgetsBindingObserver` to track the app's state.
- **Background Mode**: When the app is paused or inactive (e.g., phone locked), the service maintains a robust heartbeat with optimized intervals.
- **Auto-Resumption**: Upon returning to the app, it triggers an immediate health check and initiates auto-recovery if the connection was dropped.

### 3. Enhanced Auto-Recovery
- Increased `maxReconnectAttempts` to **20** to provide a longer window for recovery during extended backgrounding.
- Optimized the exponential backoff algorithm with jitter and a 64-second cap to balance battery usage and responsiveness.

### 4. Protocol Stability
- Set `keepAliveInterval` to 30 seconds at the protocol level.
- Improved terminal responsiveness during recovery cycles.

## Technical Details

- **Files Modified**:
    - `lib/initial_layer/CoreLogics/SSHServiceNative.dart`: Core logic for lifecycle and tmux.
    - `lib/initial_layer/CoreLogics/SSHService.dart`: Wrapper update.
    - `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: UI state management.
    - `lib/ui_layer/widget_page/PluginList/TalkSSH/widgets/SSHConnectionSheet.dart`: User interface for the tmux toggle.

## Usage
When establishing a new uplink, ensure "PERSISTENT SESSION (TMUX)" is active. If your connection drops while the phone is closed, simply reopening the app will trigger the auto-recovery which will re-attach to your existing tmux session seamlessly.
# CHANGELOG: SSH Module Refactor & Dynamic Island Integration (v2.6.0+4)

## Overview
Successfully refactored the SSH module from a monolithic implementation to a strictly modular, widget-centric architecture. Integrated real-time telemetry into the global Dynamic Island and reclaimed 100% of terminal screen real estate.

## Key Changes
### 🧱 Architectural Refactor
- **Extracted Widgets**:
    - `SSHHostDrawer`: Manages host selection and saved historical uplinks.
    - `SSHConnectionSheet`: Dedicated modal for server configuration and handshakes.
- **Controller Optimization**: `TalkSSHPage.dart` reduced by ~300 lines; now functions as a clean orchestrator.
- **State Cleanup**: Removed redundant local state variables (`_isConnecting`, `_currentServerName`, etc.) in favor of global service state.

### 🏝️ Dynamic Island Integration
- **Real-time Telemetry**: Latency (ms), Download (RX), and Upload (TX) metrics are streamed directly into `CanvasDynamicIsland`.
- **Context-Aware UI**: Dynamic Island automatically expands and switches to "SSH TERMINAL" mode with live status indicators upon entering the terminal screen.
- **Layout Reset**: Removed `SSHHeader` widget from the page level to maximize the terminal font area.

### 🧹 Code Quality & Performance
- **Unused Code Removal**: Deleted `SSHAIGenerator.dart` and removed all AI-related experimental logic.
- **Dependency Optimization**: Cleaned up unused imports and refined the `StreamBuilder` logic to be efficient and reactive.

## Design Doc: Future Maintenance
- **Adding Metrics**: To add more telemetry, update `SSHService.statsStream` and the `_buildSSHMetrics` method in `CanvasDynamicIsland.dart`.
- **New Widgets**: Keep the "Everything is a Widget" pattern by placing new sub-components in the `widgets/` directory and passing callbacks to the main controller.

---
*Verified on macOS/iOS. Dynamic Island tested for reactive state transitions.*
# CHANGES: SSH Uplink Hub Consolidation & Dynamic Island Telemetry

## Overview
This update revolutionizes the SSH connection management experience by consolidating all uplink controls into a single, gesture-driven `MainButton` and migrating real-time metrics to the global **Dynamic Island**. This architecture maximizes terminal workspace and aligns the SSH module with the app's premium design language.

## Key Changes

### 🕹️ Consolidated Uplink Hub (`MainButton`)
- **Exclusive Entry Point**: Replaced all standalone connection buttons and side-drawers with the `MainButton`.
- **Gesture Support**:
    - **Tap**: Launches the "New Session" dialog for manual entry or editing.
    - **Long Press**: Dynamically populates a radial menu (sub-buttons) with the 5 most recent saved connections.
- **Workflow**: Users can now switch between servers with a single hold-and-drag gesture without leaving the terminal view.

### 📡 Global Telemetry (`Dynamic Island`)
- **Real-time Monitoring**: Integrated `SSHService.statsStream` into the `CanvasDynamicIsland`.
- **Metrics Displayed**:
    - Hostname
    - RX/TX Rates (KB/s)
    - Latency (ms)
- **Space Optimization**: Removed the `SSHHeader` widget, reclaiming significant vertical space for the terminal.

### 🧹 Component Retirement & Cleanup
- **Deleted `SSHHostDrawer.dart`**: Redundant due to the `MainButton` radial dial.
- **Deleted `SSHHeader.dart`**: Redundant due to Dynamic Island integration.
- **Refactored `TalkSSHPage.dart`**: Streamlined state management and removed unused private UI methods.

## Technical Details
- **State Management**: Uses `FutureBuilder` with `SSHStorageService.loadHosts()` for radial menu population.
- **Reactivity**: `CanvasDynamicIsland` uses `StreamBuilder` for zero-lag telemetry updates.
- **Gesture Logic**: Leverages `CompositedTransformTarget` and `OverlayEntry` within `MainButton` for the radial sub-button system.

## Version
**2.6.0+9**
# Finance Power Points Update

## Overview
Added the "Finance Power" feature to the Finance dashboard to calculate and display user points based on their total net worth. This aligns the Finance pillar with the Gamification Service scoring logic.

## Changes Made
1. **Business Logic (`FinanceBlock.dart`)**:
   - Added a new `financePoints` computed signal to calculate points using the formula: `(totalBalance.value / FINANCE_SAVINGS_MILESTONE) * FINANCE_SAVINGS_POINTS`.

2. **Localization (`app_en.arb`, `app_vi.arb`)**:
   - Added localization keys for "FINANCE POWER" (`finance_power_points`) and its description (`finance_points_desc`).

3. **UI/UX (`FinancePage.dart`)**:
   - Integrated the `financePoints` value directly into the portfolio header using an animated visual chip.
   - Added a progress bar to visually represent progress towards the next $1,000 milestone unit.
   - Replaced deprecated `.withOpacity` methods with `.withValues(alpha: ...)` to align with newer Flutter standards and maintain precision.

## Impact
Users can now visually track their financial points and how they progress towards the next milestone, boosting gamification engagement within the Finance app pillar.
# Fix: TalkSSH Localization Import and Missing Keys

## Issue Description
Running `flutter analyze` reported multiple errors indicating `AppLocalizations` was undefined or the URI could not be found within the `TalkSSH` plugin widget files:
- `TalkSSHPage.dart`
- `SSHSearchBar.dart`
- `SSHAIGenerator.dart`
- `SSHHeader.dart`
- `SSHCommandInput.dart`

The localization configuration (`l10n.yaml`) defines `output-dir: lib/l10n`, which means localization files should be imported via `package:ice_gate/l10n/app_localizations.dart` rather than the default `package:flutter_gen/gen_l10n/app_localizations.dart`. Additionally, several SSH-specific string keys were missing in `app_en.arb` and `app_vi.arb`.

## Changes Made
1. **Updated Imports:** 
   - Replaced `import 'package:flutter_gen/gen_l10n/app_localizations.dart';` with `import 'package:ice_gate/l10n/app_localizations.dart';` in all the affected `TalkSSH` sub-widget files.
   - Added the correct import in `TalkSSHPage.dart`.

2. **Added Missing ARB Keys:**
   Added the following keys and their translations to `lib/l10n/app_en.arb` and `lib/l10n/app_vi.arb`:
   - `ssh_new_session`
   - `ssh_host_label`
   - `ssh_port_label`
   - `ssh_user_label`
   - `ssh_pass_label`
   - `ssh_connect`
   - `ssh_ask_ai`
   - `ssh_ask_ai_desc`
   - `ssh_generate`
   - `ssh_type_command`
   - `ssh_disconnect`
   - `ssh_search_hint`

3. **Regenerated Localizations:** 
   - Ran `flutter gen-l10n` to successfully build the `.dart` localization class files. `flutter analyze` no longer produces compile errors.
# SSH UI Improvements & Continuous Session Support

## Overview
Enhanced the SSH terminal feature in Ice Gate to support continuous sessions, allowing users to navigate away from the terminal without losing their connection. Also introduced several UI/UX improvements to make the terminal more robust and user-friendly.

## Key Changes
1. **Continuous Sessions (`SSHService`):**
   - Converted `SSHService` into a singleton pattern.
   - Removed the automatic disconnection on `dispose()` inside `TalkSSHPage`.
   - Added session state tracking (`currentHost` and `connectedAt`) in `SSHServiceNative`.

2. **UX & Convenience:**
   - **Real-Time Uptime Tracking:** The SSH header now displays a live counter of how long the session has been active.
   - **Saved Sessions Drawer:** Added a drawer accessible from the AppBar to quickly view and reconnect to recent SSH hosts, retrieved via `SSHStorageService`.
   - **Improved Shortcut Keys:** Updated the `SSHShortcutKeyRow` to include arrow keys (↑, ↓, ←, →) and critical terminal control shortcuts (C-c, C-d, C-z, Tab, Esc).
   - **Dynamic Terminal Resizing:** Wrapped the terminal view in a `LayoutBuilder` to auto-resize the terminal's columns and rows based on the available screen dimensions.

3. **Modernized UI:**
   - Improved the header to show connection status dynamically and added a Reconnect button.
   - Refined the terminal styling with padding and consistent font usage.

## Next Steps
This update is ready for deployment and user review.# TestFlight Auto Deploy Setup

## What was created

### 1. `scripts/deploy_testflight.sh`
- **Purpose**: One-command script to build and upload to TestFlight
- **Features**:
  - `--bump-build` — Auto-increment build number in `pubspec.yaml`
  - `--skip-clean` — Skip `flutter clean` for faster rebuilds
  - Runs `flutter build ipa` with correct export options
  - Uploads IPA via `xcrun altool`

### 2. `ios/ExportOptions.plist`
- **Purpose**: Tells Xcode how to export the IPA for App Store distribution
- **Config**: Team ID `JJ5CR7B87P`, automatic signing, App Store method

### 3. `.agent/workflows/deploy-testflight.md`
- **Purpose**: Reusable workflow (use `/deploy-testflight` slash command)
- **Contains**: Full step-by-step guide + troubleshooting

## Before First Use

You need to do **one** of these authentication setups:

### Option A: App-Specific Password (simpler)
```bash
# 1. Go to https://appleid.apple.com → App-Specific Passwords → Generate
# 2. Store in Keychain:
xcrun altool --store-password-in-keychain-item "AC_PASSWORD" \
  -u "YOUR_APPLE_ID@email.com" \
  -p "xxxx-xxxx-xxxx-xxxx"
```

### Option B: API Key (better for CI/automation)
```bash
# 1. Go to App Store Connect → Users → Keys → Generate API Key
# 2. Download the .p8 file
# 3. Update deploy_testflight.sh with your Key ID and Issuer ID
```

## Quick Deploy
```bash
./scripts/deploy_testflight.sh --bump-build
```

This will: bump build `2.5.0+6` → `2.5.0+7` → clean → build IPA → upload to TestFlight ✈️
# Changes: TestFlight Deployment (Version 2.6.0+10)

Successfully deployed **Ice Gate** version `2.6.0+10` to Apple TestFlight on **2026-03-12**.

## Summary of Actions
- **Build Number Increment:** Automatically bumped from `9` to `10` in `pubspec.yaml`.
- **Project Cleaning:** Performed `flutter clean` and `flutter pub get` to ensure a fresh build state.
- **IPA Generation:** Built the App Store IPA using `flutter build ipa --release`.
- **TestFlight Upload:** Successfully uploaded the generated IPA (`ice_gate.ipa`) to App Store Connect using `xcrun altool`.

## Deployment Details
- **Version:** `2.6.0`
- **Build Number:** `10`
- **Bundle ID:** `duylong.art.icegate`
- **Upload Status:** Succeeded (No errors)
- **Delivery UUID:** `b8ece3f7-39cc-4577-9179-3553face0eda`

## Next Steps
- Verify the build in **App Store Connect**.
- Wait for Apple's processing (typically 5-30 minutes).
- Once processed, notify beta testers via TestFlight.
# Fix: xterm Package Build Error

## Problem
Build failed with:
```
The argument type 'RawKeyEvent' can't be assigned to the parameter type 'KeyEvent'.
```
- The `xterm` package v3.5.0 uses the deprecated `RawKeyEvent` API
- Flutter 3.41.4 has fully migrated to the new `KeyEvent`/`HardwareKeyboard` system
- This made `xterm` 3.5.0 incompatible

## Solution
Upgraded `xterm` from **3.5.0 → 4.0.0** in `pubspec.yaml`.

### Changes in `pubspec.yaml`
```diff
# dependencies section
- xterm: ^3.5.0
+ xterm: ^4.0.0

# dependency_overrides section
- xterm: 3.5.0
+ xterm: 4.0.0
```

## Explanation
- `xterm` v4.0.0 updates internal key event handling to use the new `KeyEvent` API instead of the deprecated `RawKeyEvent`
- The two files using `xterm` (`TerminalViewNative.dart` and `SSHServiceNative.dart`) use basic APIs (`Terminal`, `TerminalView`, `TerminalController`) that remain compatible across v3→v4
- No code changes were needed in the project files — only the dependency version bump

## Additional Fixes Applied
- **Localization**: Regenerated `flutter gen-l10n` with new finance keys added by user
- **Vietnamese typos**: Fixed "NHẬT ĐỊNH" → "NHẬN ĐỊNH", "cân nhận" → "cân nhắc", "4 phía cạnh" → "4 khía cạnh"
- **Lint cleanups**: Removed duplicate `intl` import in `FoodInputPage.dart`, removed unused `colorScheme` variable in `FoodDashboardPage.dart`

## Build Result
✓ `flutter build macos --debug` succeeded after the upgrade
