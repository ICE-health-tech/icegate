import 'package:flutter/material.dart';
import 'package:powersync/powersync.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';
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

  /// PowerSync calls this to upload local changes to your backend.
  /// In this branch, we handle all pushes manually via supabase_flutter in the DAOs
  /// so we simply drain the PowerSync outbox without manual uploading.
  @override
  Future<void> uploadData(PowerSyncDatabase database) async {
    final transaction = await database.getNextCrudTransaction();
    if (transaction == null) return;

    try {
      debugPrint("⏭️ [PowerSync] Branch skip: Clearing outbox transaction (${transaction.crud.length} ops) without uploading.");
      await transaction.complete();
    } catch (e) {
      debugPrint("❌ [PowerSync] Outbox clearance failed: $e");
      rethrow;
    }
  }
}
