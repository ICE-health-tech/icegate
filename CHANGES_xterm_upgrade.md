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
