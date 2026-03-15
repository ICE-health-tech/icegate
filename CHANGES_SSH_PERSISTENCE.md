# CHANGES: SSH Session Persistence & Management

This update introduces local SQLite persistence for SSH sessions, allowing users to track recent connections and manage both live tmux sessions and historical connection records.

## Key Features

### 1. SQLite Persistence Layer
- Created `ssh_sessions` table in SQLite via Drift.
- Stores: IP address, remote path, project ID, session name, AI model, and activity status.
- Automatically saves connection metadata when an SSH uplink is established.
- Automatically clears session records when a manual disconnect is performed.

### 2. Dual-Layer SSH Manager
- Refined `SSHManagerPage` to show two distinct sections:
    - **Live Tmux Sessions**: Active sessions on the current remote host.
    - **Persisted Sessions**: Historical connection records stored in the local database.
- Integrated "Quick Connect" from persisted records, restoring previous settings (host, path, AI mode).
- Added "Delete Record" functionality to manually prune the local session history.

### 3. Integrated Lifecycle
- `TalkSSHPage` now handles the database sync during the `_connect` and `disconnect` cycles.
- Improved error handling and debug logging for session persistence operations.

## Files Modified
- `lib/data_layer/DataSources/local_database/Database.dart`: Schema version 46, new table, and DAO.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: Logic to save/clear sessions.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/SSHManagerPage.dart`: UI to display and manage persisted records.

## Verification
- Verified session saving on successful connection.
- Verified session record deletion on manual disconnect.
- Verified manager UI correctly displays both live streams and local database records.
- Verified "Connect" button on persisted records correctly forwards parameters to the terminal.
