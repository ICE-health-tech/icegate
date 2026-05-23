/// Calendar vs health integration domains.
enum IntegrationDomain {
  calendar,
  health,
}

/// Stable provider ids stored in [integration_accounts].provider.
enum IntegrationProviderId {
  googleCalendar('google_calendar'),
  appleDeviceCalendar('apple_device_calendar'),
  androidDeviceCalendar('android_device_calendar'),
  appleHealth('apple_health'),
  huaweiHealth('huawei_health'),
  googleFit('google_fit');

  const IntegrationProviderId(this.storageKey);
  final String storageKey;

  IntegrationDomain get domain => switch (this) {
        IntegrationProviderId.googleCalendar ||
        IntegrationProviderId.appleDeviceCalendar ||
        IntegrationProviderId.androidDeviceCalendar =>
          IntegrationDomain.calendar,
        _ => IntegrationDomain.health,
      };
}

enum IntegrationConnectionStatus {
  connected,
  disconnected,
  error,
  needsReauth,
}
