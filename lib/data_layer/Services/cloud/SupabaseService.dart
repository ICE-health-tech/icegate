import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
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
    'oxygen_saturation_logs': {'id'},
    'feedbacks': {'status'},
    'project_notes': {'extension'},
  };

  /// Pushes local changes to Supabase.
  /// Used by DAOs after a local write operation.
  Future<void> pushData({
    required String table,
    required Map<String, dynamic> payload,
    bool isDelete = false,
  }) async {
    try {
      if (isDelete) {
        await client.from(table).delete().eq('id', payload['id']);
        return;
      }

      final idValue = payload['id']?.toString() ?? "";
      if (_isGuest(idValue, payload)) {
        debugPrint(
          "⏭️ [SupabaseService] Skipping push for guest data in $table (ID: $idValue)",
        );
        return;
      }

      // 1. Clean the data (remove local-only columns)
      final transformed = _transformOpData(table, payload);

      // 2. Prepare the payload for Supabase
      final Map<String, dynamic> encodablePayload = {};

      transformed.forEach((key, value) {
        transformed.forEach((key, value) {
          // 1. Handle "persons" table specific null-safety
          if (table == 'persons') {
            if ((key == 'first_name' || key == 'last_name') &&
                (value == null || value.toString().isEmpty)) {
              encodablePayload[key] = ''; // Sends empty string instead of null
              return;
            }
          }

          // 2. Handle 'oxygen_saturation_logs' timestamp logic
          if (table == 'oxygen_saturation_logs' && key == 'timestamp') {
            if (value is String && value.contains('T') && value.endsWith('Z')) {
              final parsed = DateTime.tryParse(value);
              if (parsed != null) {
                encodablePayload[key] = parsed.millisecondsSinceEpoch;
                return;
              }
            } else if (value is DateTime) {
              encodablePayload[key] = value.millisecondsSinceEpoch;
              return;
            }
          }

          // 3. Standard conversion for everything else
          if (value is DateTime) {
            encodablePayload[key] = value.toUtc().toIso8601String();
          } else {
            encodablePayload[key] = value;
          }
        });
        // --- THE FIX: Only convert 'timestamp' to BigInt for Oxygen (to match your int8 schema) ---
        // For heart_rate_logs, we use standard strings to avoid the "out of range" error.
        if (table == 'oxygen_saturation_logs' && key == 'timestamp') {
          if (value is String && value.contains('T') && value.endsWith('Z')) {
            final parsed = DateTime.tryParse(value);
            if (parsed != null) {
              encodablePayload[key] = parsed.millisecondsSinceEpoch;
              return;
            }
          } else if (value is DateTime) {
            encodablePayload[key] = value.millisecondsSinceEpoch;
            return;
          }

          // else if ()
        }

        // Standard DateTime conversion for all other columns (including created_at)
        if (value is DateTime) {
          encodablePayload[key] = value.toUtc().toIso8601String();
        } else {
          encodablePayload[key] = value;
        }
      });

      // DEBUG: Log exactly what we are sending
      if (kDebugMode) {
        debugPrint(
          "📡 [Supabase] Pushing to $table (ID: $idValue). Keys: ${encodablePayload.keys.toList()}",
        );
      }

      await client.from(table).upsert(encodablePayload);
    } catch (e) {
      debugPrint("❌ [SupabaseService] Error pushing to $table: $e");
      if (e is PostgrestException) {
        debugPrint(
          "   Code: ${e.code}, Message: ${e.message}, Hint: ${e.hint}",
        );
      }
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
      'subscriptions',
      'quests',
      'ai_prompts',
      'project_notes',
      'water_logs',
      'sleep_logs',
      'exercise_logs',
      'weight_logs',
      'internal_widgets',
      'external_widgets',
      'person_widgets',
      'achievements',
      'heart_rate_logs',
      'oxygen_saturation_logs',
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
        await _upsertToLocal(table, List<Map<String, dynamic>>.from(response));
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
      // Iterate records and call individual upsert methods on each DAO.
      // This avoids needing separate batch wrappers.
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
      case 'scores':
        for (final r in records) {
          await database.scoreDAO.upsertFromSupabase(r);
        }
        break;
      case 'financial_accounts':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseAccount(r);
        }
        break;
      case 'assets':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseAsset(r);
        }
        break;
      case 'transactions':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseTransaction(r);
        }
        break;
      case 'subscriptions':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseSubscription(r);
        }
        break;
      case 'quests':
        for (final r in records) {
          await database.questDAO.upsertFromSupabase(r);
        }
        break;
      case 'ai_prompts':
        for (final r in records) {
          await database.aiPromptsDAO.upsertFromSupabase(r);
        }
        break;
      case 'project_notes':
        for (final r in records) {
          await database.projectNoteDAO.upsertFromSupabase(r);
        }
        break;
      case 'water_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseWater(r);
        }
        break;
      case 'sleep_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseSleep(r);
        }
        break;
      case 'exercise_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseExercise(r);
        }
        break;
      case 'weight_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseWeight(r);
        }
        break;
      case 'heart_rate_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseHeartRate(r);
        }
        break;
      case 'oxygen_saturation_logs':
        for (final r in records) {
          await database.healthLogsDAO.upsertFromSupabaseOxygen(r);
        }
        break;
      case 'internal_widgets':
        for (final r in records) {
          await database.internalWidgetsDAO.upsertFromSupabase(r);
        }
        break;
      case 'external_widgets':
        for (final r in records) {
          await database.externalWidgetsDAO.upsertFromSupabase(r);
        }
        break;
      case 'person_widgets':
        for (final r in records) {
          await database.widgetDAO.upsertFromSupabase(r);
        }
        break;
      case 'achievements':
        for (final r in records) {
          await database.achievementsDAO.upsertFromSupabase(r);
        }
        break;
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
