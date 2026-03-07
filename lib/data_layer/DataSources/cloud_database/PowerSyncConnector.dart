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
    // 1. Get the next batch of local changes
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      for (var crud in transaction.crud) {
        final table = crud.table;
        final id = crud.id;
        final opData = _transformOpData(table, crud.opData);

        // --- Skip Guest Data ---
        // We do not sync data associated with the hardcoded guest ID to Supabase.
        // This avoids foreign key violations for local-only seeded data.
        const guestId = DataSeeder.guestPersonId;
        final isGuestData =
            id.toString() == guestId ||
            opData['person_id']?.toString() == guestId ||
            opData['author_id']?.toString() == guestId ||
            opData['user_id']?.toString() == guestId ||
            opData['owner_id']?.toString() == guestId;

        if (isGuestData) {
          print(
            "⏭️ [PowerSync] Skipping guest data sync for $table (id: $id) - person_id matches $guestId",
          );
          continue;
        }

        print(
          "📤 [PowerSync] Syncing $table (op: ${crud.op}, id: $id): $opData",
        );

        // 2. Perform the specific Supabase operation
        switch (crud.op) {
          case UpdateType.put:
            if (table == 'health_metrics') {
              // health_metrics has a unique constraint on (person_id, date).
              // Use onConflict to merge into existing rows regardless of ID.
              await Supabase.instance.client.from(table).upsert({
                'id': id,
                ...opData,
              }, onConflict: 'person_id,date');
            } else {
              // Use upsert to handle both inserts and full updates
              await Supabase.instance.client.from(table).upsert({
                'id': id,
                ...opData,
              });
            }
            break;
          case UpdateType.patch:
            if (table == 'health_metrics' &&
                opData.containsKey('person_id') &&
                opData.containsKey('date')) {
              // Only use onConflict upsert when both fields are present.
              await Supabase.instance.client.from(table).upsert({
                'id': id,
                ...opData,
              }, onConflict: 'person_id,date');
            } else {
              await Supabase.instance.client
                  .from(table)
                  .update(opData)
                  .eq('id', id);
            }
            break;
          case UpdateType.delete:
            await Supabase.instance.client.from(table).delete().eq('id', id);
            break;
        }
      }

      // 3. IMPORTANT: Tell PowerSync this batch is done
      await transaction.complete();
      print('✅ PowerSync: Batch of ${transaction.crud.length} uploaded.');
    } on PostgrestException catch (e) {
      final errorCode = e.code?.toString();
      print(
        '❌ PowerSync: Sync error for table ${transaction.crud[0].table}: Code $errorCode - $e',
      );
      // PGRST204 = "column not found in schema cache"
      // 42703 = "column does not exist"
      // 22008 = "date/time field value out of range" (stale integer timestamp)
      // 23505 = "duplicate key violation" (stale data conflicts)
      // 23503 = "foreign key violation" (missing parent data like guest ID)
      // 23502 = "not-null constraint" (missing required fields in partial sync)
      // 22P02 = "invalid text representation" (e.g. UUID/empty string for integer column)
      // These are unrecoverable stale data — skip to unblock the queue.
      if (errorCode == 'PGRST204' ||
          errorCode == '42703' ||
          errorCode == '22008' ||
          errorCode == '23505' ||
          errorCode == '23503' ||
          errorCode == '23502' ||
          errorCode == '22P02') {
        print(
          '⚠️ PowerSync: Skipping unrecoverable error ($errorCode). Completing transaction to clear queue.',
        );
        await transaction.complete();
      } else {
        rethrow;
      }
    } catch (e) {
      print(
        '❌ PowerSync: Sync error for table ${transaction.crud[0].table}: $e',
      );
      rethrow;
    }
  }
}
