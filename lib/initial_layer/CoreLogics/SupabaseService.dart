import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';

/// SupabaseService handles data synchronization between the local Drift database
/// and the Supabase cloud backend. It replaces direct database-to-cloud calls
/// and provides a structured way to pull and push data.
class SupabaseService {
  final SupabaseClient client;
  final AppDatabase database;

  SupabaseService({required this.client, required this.database});

  // Columns that exist in local DB but should not be sent to Supabase
  final Set<String> _globalLocalOnlyColumns = {
    'local_id',
    'id_sync',
    'sync_status',
    'last_synced_at',
  };

  // Table-specific local-only columns
  final Map<String, Set<String>> _tableLocalOnlyColumns = {
    'person_contacts': {'id'},
    'weight_logs': {'created_at', 'updated_at'},
    'sleep_logs': {'created_at', 'updated_at'},
    'exercise_logs': {'created_at', 'updated_at'},
    'focus_sessions': {'created_at', 'updated_at'},
    'mind_logs': {'created_at', 'updated_at'},
    'feedbacks': {'status'},
  };

  /// Pushes local changes to Supabase.
  /// Used by DAOs after a local write operation.
  Future<void> pushData({
    required String table,
    required Map<String, dynamic> payload,
    bool isDelete = false,
  }) async {
    debugPrint(
      "📡 [SupabaseService] pushData for $table (isDelete: $isDelete)",
    );
    try {
      final idValue = payload['id']?.toString() ?? "";
      if (_isGuest(idValue, payload)) {
        debugPrint(
          "⏭️ [SupabaseService] Skipping push for guest data in $table (ID: $idValue)",
        );
        return;
      }

      final transformed = _transformOpData(table, payload);
      final Map<String, dynamic> encodablePayload = Map.from(transformed).map((
        key,
        value,
      ) {
        if (value is DateTime) {
          return MapEntry(key, value.toUtc().toIso8601String());
        }
        return MapEntry(key, value);
      });

      if (isDelete) {
        debugPrint(
          "🗑️ [SupabaseService] Deleting ${payload['id']} from $table",
        );
        await client.from(table).delete().eq('id', payload['id']);
      } else {
        debugPrint(
          "📤 [SupabaseService] Pushing to $table: ${transformed['id']}",
        );

        // Use upsert to handle both insert and update scenarios
        await client.from(table).upsert(encodablePayload);
      }
    } catch (e) {
      debugPrint("❌ [SupabaseService] Error pushing to $table: $e");
    }
  }

  /// Pulls all data for a specific user from Supabase and updates local database.
  Future<void> syncFullDown(String personId) async {
    if (personId.isEmpty || personId == DataSeeder.guestPersonId) return;

    debugPrint("🔄 [SupabaseService] Starting full sync down for $personId...");

    final tablesToSync = [
      'mind_logs',
      'projects',
      'focus_sessions',
      'health_metrics',
      'hourly_activity_log',
      'scores',
      'financial_accounts',
      'assets',
      'transactions',
    ];

    for (final table in tablesToSync) {
      await syncTableDown(table, personId);
    }

    debugPrint("✅ [SupabaseService] Full sync down completed.");
  }

  /// Syncs a single table from Supabase to local DB.
  Future<void> syncTableDown(String table, String personId) async {
    try {
      debugPrint("📥 [SupabaseService] Syncing $table down...");

      final response = await client
          .from(table)
          .select()
          .eq('person_id', personId);

      debugPrint(
        "📦 [SupabaseSync] Received ${response.length} records for $table",
      );
      if (response.isNotEmpty) {
        // Delegate to specific DAO upserts based on table name
        await _upsertToLocal(
          table,
          List<Map<String, dynamic>>.from(response),
        );
      }
        } catch (e) {
      debugPrint("❌ [SupabaseService] Failed to sync $table: $e");
    }
  }

  /// Map Supabase records back to Drift companions and upsert.
  Future<void> _upsertToLocal(
    String table,
    List<Map<String, dynamic>> records,
  ) async {
    switch (table) {
      case 'mind_logs':
        for (final r in records) {
          await database.mindLogsDAO.upsertFromSupabase(r);
        }
        break;
      case 'projects':
        for (final r in records) {
          await database.projectsDAO.upsertFromSupabase(r);
        }
        break;
      case 'focus_sessions':
        for (final r in records) {
          await database.focusSessionsDAO.upsertFromSupabase(r);
        }
        break;
      case 'health_metrics':
        for (final r in records) {
          await database.healthMetricsDAO.upsertFromSupabase(r);
        }
        break;
      case 'hourly_activity_log':
        for (final r in records) {
          await database.hourlyActivityLogDAO.upsertFromSupabase(r);
        }
        break;
      // Add more cases as needed
      default:
        debugPrint(
          "⚠️ [SupabaseService] No local upsert logic defined for table: $table",
        );
    }
  }

  Map<String, dynamic> _transformOpData(
    String table,
    Map<String, dynamic> data,
  ) {
    final result = Map<String, dynamic>.from(data);
    result.removeWhere((key, _) => _globalLocalOnlyColumns.contains(key));
    final tableSpecific = _tableLocalOnlyColumns[table];
    if (tableSpecific != null) {
      result.removeWhere((key, _) => tableSpecific.contains(key));
    }
    return result;
  }

  bool _isGuest(String id, Map<String, dynamic> opData) {
    const guestId = DataSeeder.guestPersonId;
    return id == guestId ||
        opData['person_id']?.toString() == guestId ||
        opData['author_id']?.toString() == guestId ||
        opData['user_id']?.toString() == guestId ||
        opData['owner_id']?.toString() == guestId;
  }
}
