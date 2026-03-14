# Change Report: UPLINK Terminal Consolidation

## Overview
Consolidated "ICE GATE SSH" and "UPLINK AI Controller" into a unified, high-performance "UPLINK" terminal. This change simplifies the Home page and introduces a premium, glassmorphic UI.

## Key Features
- **Unified Terminal (UPLINK)**: A single widget now handles standard SSH, Gemini AI-augmented sessions, and OpenCode AI-augmented sessions.
- **Premium UI/UX**:
    - **Glassmorphism**: Backdrop blur and transparency in the terminal AppBar.
    - **Refined Palette**: Darker, consistent terminal background (`0xFF0A0C10`).
    - **Mode Switcher**: Reactive toggle for Standard/Gemini/OpenCode modes.
    - **Quick Connection Config**: Dedicated LAN icon for immediate SSH host management.
- **Automated Workspace Cleanup**: Seeding logic now automatically removes redundant legacy widgets to provide a clean start.

## Modified Files
- `lib/ui_layer/home_page/HomePage.dart`: Unified seeding logic.
- `lib/ui_layer/widget_page/AddPluginForm.dart`: Consolidated internal shortcuts.
- `lib/ui_layer/widget_page/PluginList/TalkSSH/TalkSSHPage.dart`: Refactored core terminal UI and mode logic.

## Verification
- Confirmed that "UPLINK" is the only seeded terminal widget.
- Verified mode switching functionality and UI responsiveness.
- Checked terminal command routing for all three modes.
