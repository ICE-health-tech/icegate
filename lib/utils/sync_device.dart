import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Device label stored in Supabase for cross-device media sync.
abstract final class SyncDevice {
  static String current() {
    if (kIsWeb) return 'other';
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.macOS:
        return 'mac';
      case TargetPlatform.android:
        return 'android';
      default:
        return 'other';
    }
  }
}
