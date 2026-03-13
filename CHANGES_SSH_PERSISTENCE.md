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
