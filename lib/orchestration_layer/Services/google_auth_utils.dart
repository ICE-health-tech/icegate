import 'package:supabase_flutter/supabase_flutter.dart';

/// True when the Supabase session was created with Google OAuth.
bool sessionUsedGoogleProvider(Session? session) {
  final user = session?.user;
  if (user == null) return false;

  final provider = user.appMetadata['provider'];
  if (provider == 'google') return true;

  final identities = user.identities;
  if (identities != null) {
    return identities.any((i) => i.provider == 'google');
  }
  return false;
}
