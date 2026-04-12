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

    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: token,
      userId: userId,
    );
  }

  /// No global transformation needed.
  /// Drift schema `.named()` values are now aligned directly with Supabase column names:
  /// - Tables use UUIDs (via IDGen.UUIDV7()) for IDs.
  /// - Column names use snake_case in both Drift and Supabase to match PowerSync schema.
  Map<String, dynamic> _transformOpData(
    String table,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};
    return Map<String, dynamic>.from(data);
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
          debugPrint("⏭️ [PowerSync] Skipping guest data sync for $table (id: $id)");
          continue;
        }

        if (crud.op == UpdateType.put || crud.op == UpdateType.patch) {
          // --- 2. Build Full Payload with Context ---
          // Fetch full row to ensure mandatory columns are present (person_id, date, etc.)
          final ctx = await database.get('SELECT * FROM $table WHERE id = ?', [id]);
          Map<String, dynamic> fullPayload = {'id': id, ...opData};

          const identifyingKeys = ['person_id', 'date', 'category', 'tenant_id'];
          for (var key in identifyingKeys) {
            if (ctx.containsKey(key)) fullPayload[key] ??= ctx[key];
          }
        
          upsertBatches.putIfAbsent(table, () => []).add(fullPayload);
        } else if (crud.op == UpdateType.delete) {
          deleteBatches.putIfAbsent(table, () => []).add(id);
        }
      }

      // --- 3. Execute Bulk Upserts ---
      for (var entry in upsertBatches.entries) {
        debugPrint("📤 [PowerSync] Bulk Upserting ${entry.value.length} records to ${entry.key}");
        await Supabase.instance.client.from(entry.key).upsert(entry.value);
      }

      // --- 4. Execute Bulk Deletes ---
      for (var entry in deleteBatches.entries) {
        debugPrint("🗑️ [PowerSync] Bulk Deleting ${entry.value.length} records from ${entry.key}");
        await Supabase.instance.client.from(entry.key).delete().inFilter('id', entry.value);
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
          errorCode == '22P02') {
        debugPrint('⚠️ PowerSync: Skipping unrecoverable error. Completing transaction.');
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
