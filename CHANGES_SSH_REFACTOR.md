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
