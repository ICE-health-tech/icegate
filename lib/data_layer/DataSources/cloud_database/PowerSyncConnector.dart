import 'package:powersync/powersync.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
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

  /// PowerSync calls this to get a JWT for authentication with the PowerSync service.
  @override
  Future<PowerSyncCredentials?> fetchCredentials() async {
    final session = Supabase.instance.client.auth.currentSession;
    final token = session?.accessToken;
    if (session == null || session.isExpired) {
      try {
        // If this fails with 500, we must catch it and force a login
        final response = await Supabase.instance.client.auth.refreshSession();
        if (response.session == null) return null;
        return PowerSyncCredentials(
          endpoint: powerSyncUrl,
          token: response.session!.accessToken,
        );
      } catch (e) {
        // debugPrint("Auth Refresh Failed: $e. Redirecting to login...");
        // Logic to trigger UI logout here
        return null;
      }
    }
    return PowerSyncCredentials(
      endpoint: powerSyncUrl,
      token: session.accessToken,
    );
  }

  /// No global transformation needed.
  /// Drift schema `.named()` values are now aligned directly with Supabase column names:
  /// - Tables we migrated (projects, goals, scores, skills, person_widgets) use camelCase in both Drift and Supabase.
  /// - Tables we didn't migrate (persons, habits, etc.) use snake_case in both Drift and Supabase.
  Map<String, dynamic> _transformOpData(Map<String, dynamic>? data) {
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
        final opData = _transformOpData(crud.opData);

        print(
          "📤 [PowerSync] Syncing $table (op: ${crud.op}, id: $id): $opData",
        );

        // 2. Perform the specific Supabase operation
        switch (crud.op) {
          case UpdateType.put:
            // Use upsert to handle both inserts and full updates
            await Supabase.instance.client.from(table).upsert({
              'id': id,
              ...opData,
            });
            break;
          case UpdateType.patch:
            await Supabase.instance.client
                .from(table)
                .update(opData)
                .eq('id', id);
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
      print(
        '❌ PowerSync: Sync error for table ${transaction.crud[0].table}: $e',
      );
      // PGRST204 = "column not found in schema cache"
      // 42703 = "column does not exist"
      // 22008 = "date/time field value out of range" (stale integer timestamp)
      // 23505 = "duplicate key violation" (stale data conflicts)
      // These are unrecoverable stale data — skip to unblock the queue.
      if (e.code == 'PGRST204' ||
          e.code == '42703' ||
          e.code == '22008' ||
          e.code == '23505') {
        print(
          '⚠️ PowerSync: Skipping unrecoverable schema mismatch. Completing transaction to clear queue.',
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
