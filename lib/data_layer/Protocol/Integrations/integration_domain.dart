/// Calendar, health, documents, and automation integration domains.
enum IntegrationDomain {
  calendar,
  health,
  documents,
  automation,
}

/// Stable provider ids stored in [integration_accounts].provider.
enum IntegrationProviderId {
  googleCalendar('google_calendar'),
  appleDeviceCalendar('apple_device_calendar'),
  androidDeviceCalendar('android_device_calendar'),
  appleHealth('apple_health'),
  huaweiHealth('huawei_health'),
  googleFit('google_fit'),
  googleDrive('google_drive'),
  notion('notion'),
  cursor('cursor');

  const IntegrationProviderId(this.storageKey);
  final String storageKey;

  IntegrationDomain get domain => switch (this) {
        IntegrationProviderId.googleCalendar ||
        IntegrationProviderId.appleDeviceCalendar ||
        IntegrationProviderId.androidDeviceCalendar =>
          IntegrationDomain.calendar,
        IntegrationProviderId.googleDrive ||
        IntegrationProviderId.notion =>
          IntegrationDomain.documents,
        IntegrationProviderId.cursor => IntegrationDomain.automation,
        _ => IntegrationDomain.health,
      };
}

enum IntegrationConnectionStatus {
  connected,
  disconnected,
  error,
  needsReauth,
}
