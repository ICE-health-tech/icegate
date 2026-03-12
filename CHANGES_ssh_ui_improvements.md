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
This update is ready for deployment and user review.