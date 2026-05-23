import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_domain.dart';
import 'package:ice_gate/data_layer/Services/cloud/DeviceCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleCalendarService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleDriveService.dart';
import 'package:ice_gate/data_layer/Services/cloud/GoogleSignInHub.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/AppleHealthServices.dart';
import 'package:ice_gate/sensor_layer/phone_sensor/HuaweiCloudService.dart';

/// Connects integration providers and persists status in [integration_accounts].
class IntegrationSyncCoordinator {
  IntegrationSyncCoordinator({
    required IntegrationAccountDAO accountDao,
    required GoogleCalendarService calendarService,
    required GoogleDriveService driveService,
    required DeviceCalendarService deviceCalendarService,
  })  : _accountDao = accountDao,
        _calendarService = calendarService,
        _driveService = driveService,
        _deviceCalendarService = deviceCalendarService;

  final IntegrationAccountDAO _accountDao;
  final GoogleCalendarService _calendarService;
  final GoogleDriveService _driveService;
  final DeviceCalendarService _deviceCalendarService;

  static String accountId(String personId, IntegrationProviderId provider) {
    return IDGen.generateDeterministicUuid(
      personId,
      '${provider.domain.name}:${provider.storageKey}',
    );
  }

  /// Calendar + Drive via shared [GoogleSignInHub] after app login with Google.
  Future<bool> connectGoogleEcosystem({
    required String personId,
    bool interactive = true,
  }) async {
    if (personId.isEmpty) return false;

    final calendarOk = await _calendarService.signIn(interactive: interactive);
    await _driveService.signIn(interactive: false);

    final account = GoogleSignInHub.signIn.currentUser;
    final now = DateTime.now();

    if (calendarOk && account != null) {
      await _upsert(
        personId: personId,
        provider: IntegrationProviderId.googleCalendar,
        status: IntegrationConnectionStatus.connected,
        displayName: account.email,
        externalAccountId: account.id,
        lastSyncAt: now,
      );
      await _upsert(
        personId: personId,
        provider: IntegrationProviderId.googleFit,
        status: IntegrationConnectionStatus.connected,
        displayName: account.email,
        externalAccountId: account.id,
        lastSyncAt: now,
      );
    } else {
      await _upsert(
        personId: personId,
        provider: IntegrationProviderId.googleCalendar,
        status: IntegrationConnectionStatus.needsReauth,
        displayName: account?.email ?? 'Google Calendar',
        externalAccountId: account?.id,
        lastError: _calendarService.lastSignInError,
      );
    }

    return calendarOk;
  }

  /// Silent restore for returning users (no OAuth UI unless scopes missing).
  Future<void> restoreGoogleEcosystem({required String personId}) async {
    if (personId.isEmpty) return;
    final account = await GoogleSignInHub.silentAccount();
    if (account == null) return;
    await connectGoogleEcosystem(personId: personId, interactive: false);
  }

  Future<bool> connect(
    IntegrationProviderId provider, {
    required String personId,
    bool interactive = true,
  }) async {
    if (personId.isEmpty) return false;

    switch (provider) {
      case IntegrationProviderId.googleCalendar:
        return connectGoogleEcosystem(
          personId: personId,
          interactive: interactive,
        );
      case IntegrationProviderId.appleDeviceCalendar:
      case IntegrationProviderId.androidDeviceCalendar:
        final ok = await _deviceCalendarService.requestAccess();
        final providerId = defaultTargetPlatform == TargetPlatform.iOS
            ? IntegrationProviderId.appleDeviceCalendar
            : IntegrationProviderId.androidDeviceCalendar;
        await _upsert(
          personId: personId,
          provider: providerId,
          status: ok
              ? IntegrationConnectionStatus.connected
              : IntegrationConnectionStatus.disconnected,
          displayName: providerId == IntegrationProviderId.appleDeviceCalendar
              ? 'Apple Calendar'
              : 'Device calendar',
          lastSyncAt: ok ? DateTime.now() : null,
          lastError: _deviceCalendarService.lastAccessError,
        );
        return ok;
      case IntegrationProviderId.googleFit:
        return connectGoogleEcosystem(
          personId: personId,
          interactive: interactive,
        );
      case IntegrationProviderId.appleHealth:
        if (defaultTargetPlatform != TargetPlatform.iOS) return false;
        final healthOk = await HealthService.requestPermissions();
        await _upsert(
          personId: personId,
          provider: provider,
          status: healthOk
              ? IntegrationConnectionStatus.connected
              : IntegrationConnectionStatus.disconnected,
          displayName: 'Apple Health',
          lastSyncAt: healthOk ? DateTime.now() : null,
        );
        return healthOk;
      case IntegrationProviderId.huaweiHealth:
        final huaweiOk = await HuaweiCloudService.isConnected();
        await _upsert(
          personId: personId,
          provider: provider,
          status: huaweiOk
              ? IntegrationConnectionStatus.connected
              : IntegrationConnectionStatus.disconnected,
          displayName: 'Huawei Health',
          lastSyncAt: await HuaweiCloudService.getLastSync(),
          lastError: huaweiOk ? null : 'Configure credentials in Sensor Hub',
        );
        return huaweiOk;
    }
  }

  Future<void> disconnect(
    IntegrationProviderId provider, {
    required String personId,
  }) async {
    if (personId.isEmpty) return;

    switch (provider) {
      case IntegrationProviderId.googleCalendar:
        await _calendarService.signOut();
        await _driveService.signOut();
        await _upsert(
          personId: personId,
          provider: provider,
          status: IntegrationConnectionStatus.disconnected,
          displayName: 'Google Calendar',
        );
      case IntegrationProviderId.appleDeviceCalendar:
      case IntegrationProviderId.androidDeviceCalendar:
        _deviceCalendarService.disconnect();
        final providerId = defaultTargetPlatform == TargetPlatform.iOS
            ? IntegrationProviderId.appleDeviceCalendar
            : IntegrationProviderId.androidDeviceCalendar;
        await _upsert(
          personId: personId,
          provider: providerId,
          status: IntegrationConnectionStatus.disconnected,
          displayName: providerId == IntegrationProviderId.appleDeviceCalendar
              ? 'Apple Calendar'
              : 'Device calendar',
        );
      case IntegrationProviderId.appleHealth:
      case IntegrationProviderId.huaweiHealth:
      case IntegrationProviderId.googleFit:
        break;
    }
  }

  Future<bool> syncNow(
    IntegrationProviderId provider, {
    required String personId,
  }) async {
    if (personId.isEmpty) return false;

    switch (provider) {
      case IntegrationProviderId.googleCalendar:
        if (!_calendarService.isSignedIn) {
          final ok = await connectGoogleEcosystem(
            personId: personId,
            interactive: true,
          );
          if (!ok) return false;
        }
        final now = DateTime.now();
        final start = DateTime(now.year, now.month, 1);
        final end = DateTime(now.year, now.month + 1, 0);
        try {
          await _calendarService.fetchEvents(
            rangeStart: start,
            rangeEnd: end,
          );
          await _upsert(
            personId: personId,
            provider: provider,
            status: IntegrationConnectionStatus.connected,
            displayName:
                GoogleSignInHub.signIn.currentUser?.email ?? 'Google Calendar',
            externalAccountId: GoogleSignInHub.signIn.currentUser?.id,
            lastSyncAt: now,
          );
          return true;
        } catch (e) {
          await _upsert(
            personId: personId,
            provider: provider,
            status: IntegrationConnectionStatus.error,
            displayName: 'Google Calendar',
            lastError: e.toString(),
          );
          return false;
        }
      case IntegrationProviderId.appleDeviceCalendar:
      case IntegrationProviderId.androidDeviceCalendar:
        return _deviceCalendarService.hasAccess;
      case IntegrationProviderId.appleHealth:
      case IntegrationProviderId.huaweiHealth:
      case IntegrationProviderId.googleFit:
        return false;
    }
  }

  Future<void> _upsert({
    required String personId,
    required IntegrationProviderId provider,
    required IntegrationConnectionStatus status,
    required String displayName,
    String? externalAccountId,
    DateTime? lastSyncAt,
    String? lastError,
  }) async {
    final now = DateTime.now();
    await _accountDao.upsert(
      IntegrationAccountsTableCompanion(
        id: Value(accountId(personId, provider)),
        personId: Value(personId),
        domain: Value(provider.domain.name),
        provider: Value(provider.storageKey),
        status: Value(status.name),
        displayName: Value(displayName),
        externalAccountId: Value(externalAccountId),
        lastSyncAt: Value(lastSyncAt),
        lastError: Value(lastError),
        updatedAt: Value(now),
      ),
    );
  }
}
