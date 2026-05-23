import 'package:flutter/foundation.dart';

/// Set via `--dart-define=APP_LOGS=true` when debugging boot/sync/router.
const bool kAppLogsEnabled = bool.fromEnvironment('APP_LOGS', defaultValue: false);

/// Call once from [main] before other initialization.
void configureAppLogging() {
  if (!kAppLogsEnabled) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }
}

void appLog(Object? message) {
  if (kAppLogsEnabled && kDebugMode) {
    debugPrint(message?.toString());
  }
}
