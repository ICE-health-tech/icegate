# CHANGES: SSH TMUX Manager Integration

This update introduces a dedicated management layer for SSH `tmux` sessions, allowing users to view, attach to, or terminate persistent sessions directly from the UI.

## Key Features

### 1. SSH TMUX Manager Page
- New dedicated page at `/widget/ssh_manager`.
- Lists all active tmux sessions on the currently connected host.
- Provides "Quick Attach" functionality to jump into a specific session.
- Provides "Terminate" functionality to kill sessions from the UI.

### 2. Enhanced SSH Service
- Added `execute(command)` capability to `SSHService` to retrieve structured command output.
- Added `listTmuxSessions()` to parse and return active session names.
- Improved session lifecycle management with `autoStartCommand` support.

### 3. TalkSSHPage Upgrades
- Added support for `autoStartCommand` via router `extra` data.
- Automatically handles reconnection and command execution when switching between sessions.

## Files Modified
- `lib/initial_layer/CoreLogics/SSHService.dart`: Interface update.
- `lib/initial_layer/CoreLogics/SSHServiceNative.dart`: Implementation of `execute` and `listTmuxSessions`.
- `lib/initial_layer/CoreLogics/SSHServiceStub.dart`: Platform stub update.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/SSHManagerPage.dart`: New Management UI.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: Support for session attaching.
- `lib/security_routing_layer/Routing/url_route/InternalRoute.dart`: Route configuration.

## Verification
- Verified routing from the Drag Canvas Grid.
- Verified tmux listing logic using `tmux list-sessions -F "#S"`.
- Verified session attaching via `tmux attach -t <name>`.
