import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// A connector that bridges the local PowerSync database with your cloud backend.
class MyPowerSyncConnector extends PowerSyncBackendConnector {
  final AuthBlock authBlock;
  final String powerSyncUrl;
  final String baseUrl;

  MyPowerSyncConnector({
    required this.authBlock,
    required this.powerSyncUrl,
    required this.baseUrl,
  });

  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final client = Supabase.instance.client;
    var session = client.auth.currentSession;

    if (session == null || session.isExpired) {
      try {
        final response = await client.auth.refreshSession();
        session = response.session;
      } catch (e) {
        debugPrint("❌ [PowerSync] Refresh session failed: $e");
        return null;
      }
    }

    // Đảm bảo có cả Token và User ID
    final userId = session?.user.id;
    final token = session?.accessToken;

    if (token == null || userId == null) {
      debugPrint(
        "⚠️ [PowerSync] Missing credentials: token=$token, userId=$userId",
      );
      return null;
    }

    debugPrint("🔑 [PowerSync] Connecting with UserID: $userId");
    // You can also add session parameters here if needed by your sync rules
    // return PowerSyncCredentials(endpoint: powerSyncUrl, token: token, userId: userId, parameters: {'tenant_id': ...});

    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: token,
      userId: userId,
    );
  }

  /// Columns that exist only in the local Drift DB and must NOT be sent to Supabase.
  /// These cause PGRST204: "column not found in schema cache" errors when uploaded.
  ///
  /// Structure:
  ///   _globalLocalOnlyColumns  → stripped from every table
  ///   _tableLocalOnlyColumns   → stripped only from the specified table
  ///
  /// Why per-table? `person_id` is valid in dozens of tables — we only need to
  /// suppress it on `persons`, where Supabase uses `id` as the primary key and
  /// has no separate `person_id` column.
  static const _globalLocalOnlyColumns = {
    'avatar_local_path', // Local path to downloaded profile image
    'cover_local_path', // Local path to downloaded cover image
  };

  static const _tableLocalOnlyColumns = <String, Set<String>>{
    // Supabase `persons` PK is `id` — there is no separate `person_id` column
    'persons': {'person_id'},

    // `quest_type` is a local Drift field; Supabase `quests` does not have it
    'quests': {'quest_type'},

    // `last_quest_generated_at` is stored locally on the profile record but
    // the remote Supabase `profiles` table does not expose this column
    'profiles': {'last_quest_generated_at'},

    // These tables have `created_at` and `updated_at` added locally in PowerSync
    // schema (so Drift views don't crash with null check operator errors),
    // but the remote Supabase schema does not have these columns.
    'health_metrics': {'created_at', 'updated_at'},
    'water_logs': {'created_at', 'updated_at'},
    'weight_logs': {'created_at', 'updated_at'},
    'sleep_logs': {'created_at', 'updated_at'},
    'exercise_logs': {'created_at', 'updated_at'},
    'focus_sessions': {'created_at', 'updated_at'},
  };

  /// Strip local-only fields before uploading to Supabase.
  Map<String, dynamic> _transformOpData(
    String table,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};
    final result = Map<String, dynamic>.from(data);
    // Remove globally-suppressed columns (device-local paths, etc.)
    result.removeWhere((key, _) => _globalLocalOnlyColumns.contains(key));
    // Remove table-specific columns that don't exist in the remote schema
    final tableSpecific = _tableLocalOnlyColumns[table];
    if (tableSpecific != null) {
      result.removeWhere((key, _) => tableSpecific.contains(key));
    }
    return result;
  }

  /// PowerSync calls this to upload local changes to your backend.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    // Group data by table to perform bulk operations
    final Map<String, List<Map<String, dynamic>>> upsertBatches = {};
    final Map<String, List<String>> deleteBatches = {};

    try {
      for (var crud in transaction.crud) {
        final table = crud.table;
        final id = crud.id;
        final opData = _transformOpData(table, crud.opData);

        // --- 1. Skip Guest Data ---
        if (_isGuest(id, opData)) {
          debugPrint(
            "⏭️ [PowerSync] Skipping guest data sync for $table (id: $id)",
          );
          continue;
        }

        if (crud.op == UpdateType.put || crud.op == UpdateType.patch) {
          // --- 2. Build Full Payload with Context (Strongest Data Wins) ---
          final localData = await database.getOptional(
            'SELECT * FROM $table WHERE id = ?',
            [id],
          );
          Map<String, dynamic> fullPayload = {'id': id, ...opData};
          debugPrint('🔍 [PowerSync] Preparing $table: $fullPayload');

          if (localData != null) {
            // Compare completeness (number of non-null fields)
            int localSize = localData.values.where((v) => v != null).length;
            int incomingSize = opData.values.where((v) => v != null).length;

            if (incomingSize < localSize) {
              // If incoming change is "smaller" than existing local state,
              // merge them to prevent field loss.
              debugPrint(
                "🛰️ [PowerSync] Merging incomplete patch for $table (id: $id)",
              );
              fullPayload = {...localData, ...opData};
              // Re-apply the full transform to strip local-only fields from the merged payload
              fullPayload = _transformOpData(table, fullPayload);
            } else {
              // Preserve identifying keys from localData only if not already in opData.
              // NOTE: 'person_id' is intentionally excluded here — for the `persons` table
              // Supabase uses `id` as PK and has no `person_id` column. Other tables that
              // do have person_id in Supabase get it from opData directly.
              const identifyingKeys = ['date', 'category', 'tenant_id'];
              for (var key in identifyingKeys) {
                if (localData.containsKey(key))
                  fullPayload[key] ??= localData[key];
              }
            }
          }

          // Final guard: re-apply the full transform so no local-only field can
          // slip through via the localData merge or identifyingKeys paths above.
          fullPayload = _transformOpData(table, fullPayload);
          upsertBatches.putIfAbsent(table, () => []).add(fullPayload);
        } else if (crud.op == UpdateType.delete) {
          deleteBatches.putIfAbsent(table, () => []).add(id);
        }
      }

      // --- 3. Execute Bulk Upserts ---
      for (var entry in upsertBatches.entries) {
        final table = entry.key;
        final data = entry.value;

        debugPrint(
          "📤 [PowerSync] Bulk Upserting ${data.length} records to $table",
        );

        // Use composite keys for metrics tables to prevent duplicate conflicts
        final isMetricsTable = [
          'health_metrics',
          'financial_metrics',
          'project_metrics',
          'social_metrics',
        ].contains(table);

        try {
          if (isMetricsTable) {
            await Supabase.instance.client
                .from(table)
                .upsert(data, onConflict: 'person_id,date,category');
          } else {
            await Supabase.instance.client.from(table).upsert(data);
          }
        } catch (e) {
          debugPrint('❌ [PowerSync] Failed to upsert $table batch of ${data.length} records');
          // Log each record in the failed batch to find the specific problematic one
          for (var i = 0; i < data.length; i++) {
            debugPrint('   Record [$i]: ID=${data[i]['id']}, tenant_id=${data[i]['tenant_id']}, person_id=${data[i]['person_id']}');
          }
          rethrow;
        }
      }

      // --- 4. Execute Bulk Deletes ---
      for (var entry in deleteBatches.entries) {
        debugPrint(
          "🗑️ [PowerSync] Bulk Deleting ${entry.value.length} records from ${entry.key}",
        );
        await Supabase.instance.client
            .from(entry.key)
            .delete()
            .inFilter('id', entry.value);
      }

      await transaction.complete();
    } on PostgrestException catch (e) {
      final errorCode = e.code?.toString();
      debugPrint('❌ [PowerSync] Sync error: Code $errorCode | $e');

      // Unrecoverable errors skip logic
      if (errorCode == 'PGRST204' ||
          errorCode == '42703' ||
          errorCode == '22008' ||
          errorCode == '23505' ||
          errorCode == '23503' ||
          errorCode == '23502' ||
          errorCode == '42501' ||
          errorCode == '22P02') {
        debugPrint(
          '⚠️ PowerSync: Skipping unrecoverable/RLS error. Completing transaction.',
        );
        await transaction.complete();
      } else {
        rethrow;
      }
    } catch (e) {
      debugPrint('❌ PowerSync: Sync fatal error: $e');
      rethrow;
    }
  }

  /// Helper to identify if the given ID or payload belongs to the Guest user.
  bool _isGuest(String id, Map<String, dynamic> opData) {
    const guestId = DataSeeder.guestPersonId;
    return id.toString() == guestId ||
        opData['person_id']?.toString() == guestId ||
        opData['author_id']?.toString() == guestId ||
        opData['user_id']?.toString() == guestId ||
        opData['owner_id']?.toString() == guestId;
  }
}
