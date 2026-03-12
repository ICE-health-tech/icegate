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
