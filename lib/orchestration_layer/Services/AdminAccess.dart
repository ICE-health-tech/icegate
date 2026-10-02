import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';

/// Shared admin gate for system tools (local account role + Supabase account role).
abstract final class AdminAccess {
  static bool roleIsAdmin({UserRole? localRole, String? remoteRole}) {
    if (localRole == UserRole.admin) return true;
    return isAdminString(remoteRole);
  }

  static bool isAdminString(String? role) {
    final normalized = role?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized == 'admin' || normalized == 'administrator';
  }

  /// Reads role from JWT metadata (fallback only — prefer [user_accounts.role]).
  static String? roleFromAuthMetadata(Map<String, dynamic>? appMetadata,
      Map<String, dynamic>? userMetadata) {
    final appRole = appMetadata?['role'];
    if (appRole is String && appRole.trim().isNotEmpty) return appRole;
    final userRole = userMetadata?['role'];
    if (userRole is String && userRole.trim().isNotEmpty) return userRole;
    return null;
  }
}
