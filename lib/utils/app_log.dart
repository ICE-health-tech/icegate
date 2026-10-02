import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Set via `--dart-define=APP_LOGS=true` when debugging boot/sync/router.
const bool kAppLogsEnabled = bool.fromEnvironment('APP_LOGS', defaultValue: false);

/// Always on in debug builds — use for login / OAuth / session tracing.
/// Uses [developer.log] so it still prints when [configureAppLogging] silences
/// [debugPrint]. Disable with `--dart-define=AUTH_LOGS=false`.
const bool kAuthLogsEnabled = bool.fromEnvironment(
  'AUTH_LOGS',
  defaultValue: true,
);

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

void authLog(Object? message) {
  if (!kAuthLogsEnabled || !kDebugMode) return;
  developer.log(message?.toString() ?? '', name: 'Auth');
}
