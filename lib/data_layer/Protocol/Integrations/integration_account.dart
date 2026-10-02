import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/Integrations/integration_domain.dart';

/// Domain model for a connected integration account (maps to [IntegrationAccountData]).
class IntegrationAccount {
  final String id;
  final String personId;
  final IntegrationDomain domain;
  final IntegrationProviderId provider;
  final IntegrationConnectionStatus status;
  final String displayName;
  final String? externalAccountId;
  final String? configJson;
  final DateTime? lastSyncAt;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const IntegrationAccount({
    required this.id,
    required this.personId,
    required this.domain,
    required this.provider,
    required this.status,
    required this.displayName,
    this.externalAccountId,
    this.configJson,
    this.lastSyncAt,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IntegrationAccount.fromRow(IntegrationAccountData row) {
    return IntegrationAccount(
      id: row.id,
      personId: row.personId,
      domain: IntegrationDomain.values.firstWhere(
        (d) => d.name == row.domain,
        orElse: () => IntegrationDomain.calendar,
      ),
      provider: IntegrationProviderId.values.firstWhere(
        (p) => p.storageKey == row.provider,
        orElse: () => IntegrationProviderId.googleCalendar,
      ),
      status: IntegrationConnectionStatus.values.firstWhere(
        (s) => s.name == row.status,
        orElse: () => IntegrationConnectionStatus.disconnected,
      ),
      displayName: row.displayName,
      externalAccountId: row.externalAccountId,
      configJson: row.configJson,
      lastSyncAt: row.lastSyncAt,
      lastError: row.lastError,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
