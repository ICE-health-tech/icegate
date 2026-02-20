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
    if (token == null) return null;

    // In a real production setup, you might need to fetch a specific PowerSync JWT
    // from your backend. If your backend is Supabase or similar, the user's JWT
    // can often be used directly or converted.

    // For now, we return the user's existing JWT.
    return PowerSyncCredentials(endpoint: powerSyncUrl, token: token);
  }

  /// PowerSync calls this to upload local changes to your backend.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    final token = authBlock.jwt.value;
    if (token == null) return;

    try {
      for (var crud in transaction.crud) {
        final table = crud.table;
        final opData = crud.opData;
        final id = crud.id;

        // Perform the operation on Supabase
        switch (crud.op) {
          case UpdateType.put:
            // Upsert on Supabase
            // Note: PowerSync uses 'id' usually, make sure it matches your Supabase PK
            final data = {'id': id, ...?opData};
            await Supabase.instance.client.from(table).upsert(data);
            break;
          case UpdateType.patch:
            // Update on Supabase
            await Supabase.instance.client
                .from(table)
                .update(opData!)
                .eq('id', id);
            break;
          case UpdateType.delete:
            // Delete on Supabase
            await Supabase.instance.client.from(table).delete().eq('id', id);
            break;
        }
      }

      // Mark the transaction as complete locally
      await transaction.complete();
    } catch (e) {
      print('PowerSync Upload Error: $e');
      rethrow;
    }
  }
}
