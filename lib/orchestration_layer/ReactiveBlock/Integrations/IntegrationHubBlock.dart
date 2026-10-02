import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_account.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_domain.dart';
import 'package:ice_gate/orchestration_layer/Services/IntegrationSyncCoordinator.dart';
import 'package:signals/signals.dart';

/// Orchestration state for the Integration Hub (calendar + health sources).
class IntegrationHubBlock {
  IntegrationHubBlock({
    required String personId,
    required IntegrationAccountDAO dao,
    required IntegrationSyncCoordinator coordinator,
  })  : personId = personId,
        _dao = dao,
        _coordinator = coordinator;

  String personId;
  final IntegrationAccountDAO _dao;
  final IntegrationSyncCoordinator _coordinator;

  final accounts = signal<List<IntegrationAccount>>([]);

  void updatePersonId(String id) {
    personId = id;
  }

  Future<void> refresh() async {
    if (personId.isEmpty) {
      accounts.value = [];
      return;
    }
    await _coordinator.migrateLegacyConnectionState(personId);
    final rows = await _dao.listForPerson(personId);
    accounts.value = rows.map(IntegrationAccount.fromRow).toList();
  }

  IntegrationAccount? accountFor(IntegrationProviderId provider) {
    for (final a in accounts.value) {
      if (a.provider == provider) return a;
    }
    return null;
  }

  /// After Supabase Google login: link Calendar/Drive and record integration rows.
  Future<bool> connectGoogleEcosystem({bool interactive = true}) async {
    final ok = await _coordinator.connectGoogleEcosystem(
      personId: personId,
      interactive: interactive,
    );
    await refresh();
    return ok;
  }

  Future<void> restoreGoogleEcosystem() async {
    await _coordinator.restoreGoogleEcosystem(personId: personId);
    await refresh();
  }

  Future<bool> connect(IntegrationProviderId provider) async {
    final ok = await _coordinator.connect(
      provider,
      personId: personId,
      interactive: true,
    );
    await refresh();
    return ok;
  }

  Future<void> disconnect(IntegrationProviderId provider) async {
    await _coordinator.disconnect(provider, personId: personId);
    await refresh();
  }

  Future<bool> syncNow(IntegrationProviderId provider) async {
    final ok = await _coordinator.syncNow(provider, personId: personId);
    await refresh();
    return ok;
  }

  Future<void> recordStatus({
    required IntegrationProviderId provider,
    required IntegrationConnectionStatus status,
    required String displayName,
    String? externalAccountId,
    String? configJson,
    DateTime? lastSyncAt,
    String? lastError,
  }) async {
    await _coordinator.recordStatus(
      personId: personId,
      provider: provider,
      status: status,
      displayName: displayName,
      externalAccountId: externalAccountId,
      configJson: configJson,
      lastSyncAt: lastSyncAt,
      lastError: lastError,
    );
    await refresh();
  }
}
