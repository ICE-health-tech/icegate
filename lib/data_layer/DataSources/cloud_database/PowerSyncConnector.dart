import 'package:powersync/powersync.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/DataSeeder.dart';
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
  /// - Tables use UUIDs (via IDGen.generateUuid()) for IDs.
  /// - Column names use snake_case in both Drift and Supabase to match PowerSync schema.
  Map<String, dynamic> _transformOpData(
    String table,
    Map<String, dynamic>? data,
  ) {
    if (data == null) return {};
    final map = Map<String, dynamic>.from(data);

    // Many legacy tables have a SERIAL column that Drift defaults to 0 locally.
    // We must NOT send 0 to Supabase, or we'll get a 23505 Duplicate Key violation
    // and PowerSync will silently drop the record.
    final serialKeys = {
      'custom_notifications': 'notification_id',
      'blog_posts': 'post_id',
      'focus_sessions': 'session_id',
      // widget_id is SERIAL (integer) in Supabase — strip UUID/empty values before upload
      'external_widgets': 'widget_id',
      // internal_widgets has no widget_id column in Supabase — strip to avoid 42703
      'internal_widgets': 'widget_id',
    };

    final serialKey = serialKeys[table];
    if (serialKey != null) {
      // Supabase is missing quote_id and other serials on newly created tables,
      // or they are 0 locally. We should strip them entirely during upload.
      map.remove(serialKey);
    }

    return map;
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
      final errorCode = e.code?.toString();
      print(
        '❌ PowerSync: Sync error for table ${transaction.crud[0].table}: Code $errorCode - $e',
      );
      // PGRST204 = "column not found in schema cache"
      // 42703 = "column does not exist"
      // 22008 = "date/time field value out of range" (stale integer timestamp)
      // 23505 = "duplicate key violation" (stale data conflicts)
      // 23503 = "foreign key violation" (missing parent data like guest ID)
      // 22P02 = "invalid text representation" (e.g. UUID/empty string for integer column)
      // These are unrecoverable stale data — skip to unblock the queue.
      if (errorCode == 'PGRST204' ||
          errorCode == '42703' ||
          errorCode == '22008' ||
          errorCode == '23505' ||
          errorCode == '23503' ||
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
