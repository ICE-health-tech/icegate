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

    // Identities for potential conflict resolution
    Map<String, Map<String, dynamic>> batchContexts = {};

    try {
      for (var crud in transaction.crud) {
        final table = crud.table;
        final id = crud.id;
        final opData = _transformOpData(table, crud.opData);

        // --- Skip Guest Data ---
        const guestId = DataSeeder.guestPersonId;
        final isGuestData =
            id.toString() == guestId ||
            opData['person_id']?.toString() == guestId ||
            opData['author_id']?.toString() == guestId ||
            opData['user_id']?.toString() == guestId ||
            opData['owner_id']?.toString() == guestId;

        if (isGuestData) {
          print(
            "⏭️ [PowerSync] Skipping guest data sync for $table (id: $id)",
          );
          continue;
        }

        // --- PRE-FETCH IDENTITY CONTEXT ---
        // We fetch the full row to get person_id, date, tenant_id etc.
        // This context is needed for:
        // 1. Solving 23502 (mandatory columns in patches)
        // 2. Solving 23505 (targeted cleanup of ghost records)
        Map<String, dynamic>? ctx;
        try {
          ctx = await database.get('SELECT * FROM $table WHERE id = ?', [id]);
          batchContexts[id] = ctx;
        } catch (e) {
          // Table might not exist or ID not found
        }

        print(
          "📤 [PowerSync] Syncing $table (op: ${crud.op}, id: $id): $opData",
        );

        switch (crud.op) {
          case UpdateType.put:
          case UpdateType.patch:
            // Prepare full payload for upsert
            Map<String, dynamic> fullPayload = {'id': id, ...opData};

            // Merge in identifying context if available (critical for Patch -> Insert scenarios)
            if (ctx != null) {
              const identifyingKeys = [
                'person_id',
                'date',
                'category',
                'tenant_id'
              ];
              for (var key in identifyingKeys) {
                if (ctx.containsKey(key)) {
                  fullPayload[key] ??= ctx[key];
                }
              }
            }

            await Supabase.instance.client.from(table).upsert(fullPayload);
            break;
          case UpdateType.delete:
            await Supabase.instance.client.from(table).delete().eq('id', id);
            break;
        }
      }

      await transaction.complete();
      print('✅ PowerSync: Batch of ${transaction.crud.length} uploaded.');
    } on PostgrestException catch (e) {
      final crud = transaction.crud[0];
      final table = crud.table;
      final id = crud.id;
      final errorCode = e.code?.toString();
      final ctx = batchContexts[id];

      // --- 23505 CONFLICT RESOLUTION (GHOST CLEANUP) ---
      // If a row with these identifiers exists but has a DIFFERENT ID (23505 on composite),
      // we remove the blocker in Supabase and retry.
      if (errorCode == '23505' && ctx != null) {
        final pId = ctx['person_id'];
        final date = ctx['date'];
        final cat = ctx['category'] ?? 'General';

        if (pId != null && date != null) {
          print(
            '⚠️ PowerSync: Conflict detected on composite key ($pId, $date, $cat). Cleaning up Supabase for retry...',
          );
          await Supabase.instance.client
              .from(table)
              .delete()
              .match({'person_id': pId, 'date': date, 'category': cat});

          // Let PowerSync retry this batch
          rethrow;
        }
      }

      print('❌ PowerSync: Sync error for table $table: Code $errorCode - $e');

      // PGRST204 = "column not found"
      // 42703 = "column does not exist"
      // 22008 = "date range out of bounds"
      // 23505 = "duplicate key" (that didn't match our resolver)
      // 23503 = "foreign key" (missing parent data)
      // 23502 = "not-null constraint"
      // These are unrecoverable stale data — skip to unblock.
      if (errorCode == 'PGRST204' ||
          errorCode == '42703' ||
          errorCode == '22008' ||
          errorCode == '23505' ||
          errorCode == '23503' ||
          errorCode == '23502' ||
          errorCode == '22P02') {
        print(
          '⚠️ PowerSync: Skipping unrecoverable error ($errorCode). Completing transaction.',
        );
        await transaction.complete();
      } else {
        rethrow;
      }
    } catch (e) {
      print('❌ PowerSync: Sync error for table ${transaction.crud[0].table}: $e');
      rethrow;
    }
  }
}
