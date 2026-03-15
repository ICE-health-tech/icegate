# Implementation Report: iOS Privacy Purpose Strings Fix

**Date:** March 15, 2026
**Branch:** `widget_app`

## Overview
Resolved the `ITMS-90683: Missing purpose string` error reported by App Store Connect for the key `NSLocationAlwaysAndWhenInUseUsageDescription`. This key is required for iOS 11+ when an app or its dependencies (like `geolocator`) reference background location APIs.

## Changes Made

### 1. iOS Info.plist Updates (`ios/Runner/Info.plist`)
- **Added `NSLocationAlwaysAndWhenInUseUsageDescription`**: Provided a clear, user-facing explanation of why the app needs location access both when active and in the background.
- **Updated `NSLocationAlwaysUsageDescription`**: Made it more descriptive and consistent with macOS.
- **Updated `NSLocationWhenInUseUsageDescription`**: Made it more descriptive and consistent with macOS.
- **Added `NSBluetoothPeripheralUsageDescription`**: Added for compatibility with iOS 12 and earlier, as `NSBluetoothAlwaysUsageDescription` only covers iOS 13+.
- **Updated `NSBluetoothAlwaysUsageDescription`**: Made it more descriptive and consistent with macOS.

### 2. Consistency & Compliance
- Ensured all location and Bluetooth-related purpose strings are clear, complete, and provide a user-facing reason as mandated by Apple's privacy guidelines.
- Aligned iOS descriptions with existing macOS descriptions for better cross-platform consistency.

## Files Modified
- `ios/Runner/Info.plist`

## Verification
- Verified that all mandatory keys for used plugins (`geolocator`, `flutter_blue_plus`, `health`, etc.) are now present in `Info.plist`.
- Confirmed that the error key `NSLocationAlwaysAndWhenInUseUsageDescription` is correctly implemented.
