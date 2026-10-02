import 'dart:async';
import 'dart:math' show min;
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/data_layer/Services/cloud/SupabasePayloadCodec.dart';

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
    'oxygen_saturation_logs': {'id'},
    'feedbacks': {'status'},
    'project_notes': {'extension'},
    // Local Drift has tenant_id; public.subscriptions on Supabase does not (see migrations).
    'subscriptions': {'tenant_id'},
    'gratitude_entries': {'avatar_local_path'},
  };

  Map<String, dynamic> _encodeTransformedRow(
    String table,
    Map<String, dynamic> transformed,
  ) {
    final encodablePayload = <String, dynamic>{};
    transformed.forEach((key, value) {
      if (table == 'persons') {
        if ((key == 'first_name' || key == 'last_name') &&
            (value == null || value.toString().isEmpty)) {
          encodablePayload[key] = '';
          return;
        }
      }
      encodablePayload[key] = encodeForSupabaseUpsert(
        table: table,
        key: key,
        value: value,
      );
    });
    return encodablePayload;
  }

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

      final transformed = _transformOpData(table, payload);
      final encodablePayload = _encodeTransformedRow(table, transformed);

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

  /// Batch upsert (e.g. high-frequency [heart_rate_logs]) to reduce HTTP round-trips.
  static const int _batchUpsertChunkSize = 150;

  Future<void> pushDataBatch({
    required String table,
    required List<Map<String, dynamic>> payloads,
  }) async {
    if (payloads.isEmpty) return;

    final rows = <Map<String, dynamic>>[];
    for (final payload in payloads) {
      final idValue = payload['id']?.toString() ?? '';
      if (_isGuest(idValue, payload)) continue;
      final transformed = _transformOpData(table, payload);
      rows.add(_encodeTransformedRow(table, transformed));
    }
    if (rows.isEmpty) return;

    try {
      for (var i = 0; i < rows.length; i += _batchUpsertChunkSize) {
        final end = min(i + _batchUpsertChunkSize, rows.length);
        final chunk = rows.sublist(i, end);
        if (kDebugMode) {
          debugPrint(
            "📡 [Supabase] Batch upsert $table rows ${chunk.length} "
            "(chunk ${i ~/ _batchUpsertChunkSize + 1})",
          );
        }
        await client.from(table).upsert(chunk);
      }
    } catch (e) {
      debugPrint("❌ [SupabaseService] Error batch pushing to $table: $e");
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
      'achievements',
      'journal_activity_options',
      'mind_logs',
      'projects',
      'goals',
      'skills',
      'focus_sessions',
      'health_metrics',
      'meals',
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
      'quotes',
      'heart_rate_logs',
      'oxygen_saturation_logs',
      'integration_accounts',
      'dev_quick_tabs',
      'recurring_incomes',
      'job_positions',
      'bonuses',
      'job_work_days',
      'job_work_day_plans',
      'job_time_logs',
      'job_sub_tasks',
      'gratitude_entries',
      'events',
      'project_notes'
    ];

    for (final table in tablesToSync) {
      await syncTableDown(table, personId);
    }

    debugPrint("✅ [SupabaseService] Full sync down completed.");
  }

  /// Syncs a single table from Supabase to local DB.
  Future<void> syncTableDown(
    String table,
    String personId, {
    DateTime? occurredAfter,
    DateTime? occurredBefore,
  }) async {
    try {
      debugPrint("📥 [SupabaseService] Syncing $table down...");

      var query = client.from(table).select().eq('person_id', personId);
      if (table == 'events' &&
          occurredAfter != null &&
          occurredBefore != null) {
        query = query
            .gte('occurred_at', occurredAfter.toUtc().toIso8601String())
            .lte('occurred_at', occurredBefore.toUtc().toIso8601String());
      }

      final response = await query;

      debugPrint(
        "📦 [SupabaseSync] Received ${response.length} records for $table",
      );
      final rows = List<Map<String, dynamic>>.from(response);
      if (table == 'subscriptions') {
        if (rows.isEmpty) {
          await database.financeDAO.deleteSubscriptionsForPerson(personId);
        } else {
          await _upsertToLocal(table, rows);
        }
      } else if (rows.isNotEmpty) {
        await _upsertToLocal(table, rows);
      }
    } catch (e) {
      if (e is PostgrestException &&
          e.code == 'PGRST205' &&
          table == 'ai_prompts') {
        debugPrint(
          "⚠️ [SupabaseService] Skipping $table: table not in "
          "PostgREST schema (apply supabase/migrations/20260502120000_ai_prompts.sql).",
        );
        return;
      }
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
      case 'journal_activity_options':
        for (final r in records) {
          await database.journalActivityOptionsDAO.upsertFromSupabase(r);
        }
        break;
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
      case 'goals':
        for (final r in records) {
          await database.growthDAO.upsertFromSupabaseGoal(r);
        }
        break;
      case 'skills':
        for (final r in records) {
          await database.growthDAO.upsertFromSupabaseSkill(r);
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
      case 'quotes':
        for (final r in records) {
          await database.quoteDAO.upsertFromSupabase(r);
        }
        break;
      case 'meals':
        for (final r in records) {
          await database.healthMealDAO.upsertFromSupabase(r);
        }
        break;
      case 'integration_accounts':
        for (final r in records) {
          await database.integrationAccountDAO.upsertFromSupabase(r);
        }
        break;
      case 'dev_quick_tabs':
        for (final r in records) {
          await database.devQuickTabsDAO.upsertFromSupabase(r);
        }
        break;
      case 'recurring_incomes':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseRecurringIncome(r);
        }
        await database.financeDAO.reconcileRecurringIncomes(
          records.map((r) => r['id'] as String).toSet(),
          records.isNotEmpty ? records.first['person_id'] as String : '',
        );
        break;
      case 'job_positions':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseJobPosition(r);
        }
        break;
      case 'bonuses':
        for (final r in records) {
          await database.financeDAO.upsertFromSupabaseBonus(r);
        }
        break;
      case 'job_work_days':
        for (final r in records) {
          await database.jobWorkTrackingDAO.upsertWorkDayFromSupabase(r);
        }
        break;
      case 'job_work_day_plans':
        for (final r in records) {
          await database.jobWorkTrackingDAO.upsertPlanFromSupabase(r);
        }
        break;
      case 'job_time_logs':
        for (final r in records) {
          await database.jobWorkTrackingDAO.upsertTimeLogFromSupabase(r);
        }
        break;
      case 'job_sub_tasks':
        for (final r in records) {
          await database.jobWorkTrackingDAO.upsertSubTaskFromSupabase(r);
        }
        break;
      case 'gratitude_entries':
        for (final r in records) {
          await database.gratitudeDAO.upsertFromSupabase(r);
        }
        break;
      case 'events':
        for (final r in records) {
          await database.eventsDAO.upsertFromSupabase(r);
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
    var result = Map<String, dynamic>.from(data);
    if (table == 'project_notes') {
      result = _projectNotesToRemoteColumns(result);
    } else if (table == 'projects') {
      result = _projectsToRemoteColumns(result);
    }
    result.removeWhere((key, _) => _globalLocalOnlyColumns.contains(key));
    final tableSpecific = _tableLocalOnlyColumns[table];
    if (tableSpecific != null) {
      result.removeWhere((key, _) => tableSpecific.contains(key));
    }
    return result;
  }

  /// PostgREST expects snake_case; Drift [toJson] / some maps use Dart names.
  Map<String, dynamic> _projectsToRemoteColumns(Map<String, dynamic> row) {
    const dartToSql = <String, String>{
      'tenantID': 'tenant_id',
      'projectID': 'project_id',
      'parentProjectId': 'parent_project_id',
      'personID': 'person_id',
      'sshHostId': 'ssh_host_id',
      'remotePath': 'remote_path',
      'aiModel': 'ai_model',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    final out = <String, dynamic>{};
    row.forEach((key, value) {
      out[dartToSql[key] ?? key] = value;
    });
    return out;
  }

  Map<String, dynamic> _projectNotesToRemoteColumns(Map<String, dynamic> row) {
    const dartToSql = <String, String>{
      'tenantID': 'tenant_id',
      'noteID': 'note_id',
      'personID': 'person_id',
      'projectID': 'project_id',
      'localPath': 'local_path',
      'remotePath': 'remote_path',
      'createdAt': 'created_at',
      'updatedAt': 'updated_at',
    };
    final out = <String, dynamic>{};
    row.forEach((key, value) {
      final remoteKey = dartToSql[key] ?? key;
      out[remoteKey] = value;
    });
    return out;
  }

  bool _isGuest(String id, Map<String, dynamic> opData) {
    const guestId = DataSeeder.guestPersonId;
    return id == guestId ||
        opData['person_id']?.toString() == guestId ||
        opData['personID']?.toString() == guestId ||
        opData['author_id']?.toString() == guestId ||
        opData['user_id']?.toString() == guestId ||
        opData['owner_id']?.toString() == guestId;
  }
}
