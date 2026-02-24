import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_shield/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:ice_shield/data_layer/Protocol/User/RegistrationProtocol.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

enum AuthStatus {
  init,
  checkingSession,
  unauthenticated,
  authenticating,
  registering,
  authenticated,
  failed,
  logout,
}

class AuthBlock {
  final CustomAuthService _authService;
  final SessionDAO _sessionDao;
  final PasskeyAuthService _passkeyService;
  final PersonManagementDAO _personDao;

  // --- Signals (State) ---
  final status = signal<AuthStatus>(AuthStatus.init);
  final jwt = signal<String?>(null);
  final error = signal<String?>(null);
  final username = signal<String?>(null);
  final user = signal<Map<String, dynamic>?>(null);
  final showWelcomeBack = signal<bool>(false);

  AuthBlock({
    required CustomAuthService authService,
    required SessionDAO sessionDao,
    required PasskeyAuthService passkeyService,
    required PersonManagementDAO personDao,
  }) : _authService = authService,
       _sessionDao = sessionDao,
       _passkeyService = passkeyService,
       _personDao = personDao;

  /// Helper to persist session locally (e.g. after Google OAuth)
  Future<void> persistSession(String token, String name) async {
    print("💾 [AuthBlock] Persisting session locally for $name...");
    await _sessionDao.saveSession(token, name);
  }

  /// Synchronize Supabase Auth user with public profile table
  /// This ensures that the mandatory 'persons' row exists for PowerSync.
  Future<void> syncUserWithSupabase(User user) async {
    print("🔄 [AuthBlock] Synchronizing user ${user.id} with Supabase...");

    try {
      final client = Supabase.instance.client;
      final userId = user.id;

      // 1. Ensure persons row exists
      final fullName =
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          'IceUser';
      final firstName =
          user.userMetadata?['first_name'] ?? fullName.split(' ')[0];
      final lastName =
          user.userMetadata?['last_name'] ??
          (fullName.contains(' ')
              ? fullName.split(' ').sublist(1).join(' ')
              : '');

      print("   - Upserting into 'persons'...");
      await client.from('persons').upsert({
        'id': userId,
        'first_name': firstName,
        'last_name': lastName,
        'profile_image_url': user.userMetadata?['avatar_url'],
        'is_active': true, // Use boolean true
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Ensure initial profile exists
      print("   - Ensuring 'profiles' row exists...");
      await client.from('profiles').upsert({
        'id': userId, // Primary key
        'person_id': userId, // Linked person
        'bio': 'Securing the digital frontier.',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'person_id'); // Ensure uniqueness per person

      // 3. Ensure email address exists
      if (user.email != null) {
        print("   - Ensuring 'email_addresses' row exists...");
        await client.from('email_addresses').upsert({
          'id':
              userId, // Using user ID as initial ID for simplicity or generate uuid
          'person_id': userId,
          'email_address': user.email,
          'is_primary': true,
          'status': 'verified',
        }, onConflict: 'person_id, email_address');
      }

      // 4. Ensure user_account exists
      final usernameStr =
          user.email ??
          user.userMetadata?['user_name'] ??
          'user_${userId.substring(0, 8)}';

      print("   - Ensuring 'user_accounts' row exists...");
      await client.from('user_accounts').upsert({
        'id': userId,
        'person_id': userId,
        'username': usernameStr,
        'password_hash': 'EXTERNAL_AUTH',
        'role': 'user',
        'is_locked': false,
      }, onConflict: 'username');

      // 5. Ensure detail_information exists
      print("   - Ensuring 'detail_information' row exists...");
      await client.from('detail_information').upsert({
        'id': userId,
        'person_id': userId,
        'bio': 'Securing the digital frontier.',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'person_id');

      print(
        "✅ [AuthBlock] Identity synchronization successfully completed in Flutter.",
      );
    } catch (e) {
      print(
        "❌ [AuthBlock] Identity synchronization failed in Flutter logic: $e",
      );
    }
  }

  /// Mock/Guest Login logic
  Future<void> loginAsGuest() async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    print("👤 Logging in as Guest...");

    try {
      // Provide a mock JWT and fallback username
      jwt.value = "mock_guest_jwt_token";
      username.value = "Guest";

      // We still save it to the session DAO to allow the app to "remember" this guest session
      await _sessionDao.saveSession(jwt.value!, username.value);

      status.value = AuthStatus.authenticated;

      // fetchUser will attempt to call API, fail (since token is mock),
      // and then fall back to local DB user ID 1, which acts as our mock data.
      await fetchUser();

      print("✅ Guest login successful with mock data.");
    } catch (e) {
      print("❌ Guest login failed: $e");
      error.value = "Guest Access Error: ${e.toString()}";
      status.value = AuthStatus.unauthenticated;
    }
  }

  /// Passkey Login Flow
  Future<void> loginWithPasskey(BuildContext context) async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    print("🔑 Authenticating with Passkey...");

    try {
      // 1. Get Challenge
      final challenge = await _authService.getPasskeyChallenge();
      // print("🔑 Challenge received: $challenge");

      // 2. Perform Passkey Assertion
      // Call the platform passkey service to sign the challenge
      final credential = await _passkeyService.loginRequest(
        challenge: challenge,
      );

      if (credential == null) {
        throw Exception("Passkey assertion canceled or failed");
      }

      // 3. Verify Assertion
      final data = await _authService.verifyPasskeyLogin(credential);

      final token = data['token'] ?? data['jwt'];
      if (token != null && token.toString().isNotEmpty) {
        jwt.value = token.toString();
        // Assume username returned or fetched next
        username.value = data['userName'] ?? "PasskeyUser";

        await _sessionDao.saveSession(jwt.value!, username.value);

        status.value = AuthStatus.authenticated;
        print("✅ Passkey Login successful.");

        await fetchUser();
      } else {
        throw Exception("Server returned no token for passkey");
      }
    } catch (e) {
      print("❌ Passkey Authentication failed: $e");
      error.value = "Passkey Error: ${e.toString()}";
      status.value = AuthStatus.unauthenticated;
    }
  }
  // --- Actions ---

  /// Step 1: Check for existing session (e.g. from cookies/local storage)
  /// In this Flutter app, we'll simulate cookie check or just go to auto-auth
  Future<void> checkSession(BuildContext context) async {
    status.value = AuthStatus.checkingSession;
    print("🔍 [AuthBlock] Checking for Supabase session...");

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        print("✅ [AuthBlock] Supabase session found.");
        jwt.value = session.accessToken;

        // You might want to get the username from the JWT or Supabase user metadata
        username.value = session.user.email ?? "SupabaseUser";

        status.value = AuthStatus.authenticated;
        await fetchUser();
      } else {
        print("⚠️ [AuthBlock] No Supabase session found. Checking fallback...");
        await fetchAutoJWT();
      }
    } catch (e) {
      print("❌ [AuthBlock] Error checking Supabase session: $e");
      await fetchAutoJWT();
    }
  }

  /// Step 2: Attempt to fetch JWT from API automatically (if possible/needed)
  /// Corresponds to onAuthen in XState
  Future<void> fetchAutoJWT() async {
    status.value = AuthStatus.authenticating;
    print("🔍 Step 2: Attempting to fetch JWT from API automatically...");

    try {
      // The machine logic says GET /backend/auth/login
      // We'll implement this in CustomAuthService if it doesn't exist
      // Since it's a mock/example in many cases, we'll try it
      // final data = await _authService.fetchSessionJWT(); // hypothetical

      // For now, let's assume it fails or returns unauthenticated to force manual login
      // unless we want to simulate success
      status.value = AuthStatus.unauthenticated;
      print(
        "⚠️ Auto-auth returned unauthenticated. Waiting for user credentials.",
      );
      // Fallback to Guest Mode automatically if offline/unauthenticated
      await loginAsGuest();
    } catch (e) {
      print("❌ Auto-auth fetch failed: $e");
      // Fallback to Guest Mode automatically if offline
      await loginAsGuest();
    }
  }

  /// Step 5: Authenticate with user credentials
  Future<void> login(
    String ident,
    String password,
    BuildContext context,
  ) async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    print("🔐 [AuthBlock] Authenticating with Supabase: $ident");

    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(
            email: ident.contains('@') ? ident : '$ident@example.com',
            password: password,
          );

      final session = response.session;
      if (session != null) {
        jwt.value = session.accessToken;
        username.value = session.user.email ?? ident;

        await persistSession(jwt.value!, username.value!);
        await syncUserWithSupabase(session.user);

        status.value = AuthStatus.authenticated;
        print("✅ [AuthBlock] Supabase Login successful.");
        await fetchUser();
      } else {
        throw Exception("Supabase returned no session");
      }
    } catch (e) {
      print("❌ [AuthBlock] Supabase Authentication failed: $e");
      error.value = e.toString();
      status.value = AuthStatus.unauthenticated;
    }
  }

  /// Google Sign-In with Supabase
  Future<void> signInWithGoogle() async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    print("🌐 [AuthBlock] Initiating Google Sign-In via Supabase...");

    try {
      const redirectTo = 'io.supabase.icegate://login-callback';
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectTo,
        authScreenLaunchMode: LaunchMode.externalApplication,
      );
      print(
        "✅ [AuthBlock] Google OAuth command sent. State change will be handled in DataLayer.",
      );
    } catch (e) {
      print("❌ [AuthBlock] Google Sign-In initiation failed: $e");
      error.value = e.toString();
      status.value = AuthStatus.unauthenticated;
    }
  }

  /// Registration logic using Supabase
  Future<void> register(RegistrationPayload payload) async {
    status.value = AuthStatus.registering;
    error.value = null;
    print("📝 [AuthBlock] Registering user with Supabase: ${payload.userName}");

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: payload.email,
        password: payload.password,
        data: {
          'user_name': payload.userName,
          'first_name': payload.firstName,
          'last_name': payload.lastName,
        },
      );

      if (response.user != null) {
        print("✅ [AuthBlock] Registration successful for ${payload.email}");
        // If auto-logged in or confirmation not required:
        if (response.session != null) {
          jwt.value = response.session!.accessToken;
          username.value = payload.userName;
          await persistSession(jwt.value!, username.value!);
          await syncUserWithSupabase(response.user!);
          status.value = AuthStatus.authenticated;
          await fetchUser();
        } else {
          status.value = AuthStatus.unauthenticated;
          print("📬 [AuthBlock] Please check your email for confirmation.");
        }
      }
    } catch (e) {
      print("❌ [AuthBlock] Registration failed: $e");
      error.value = e.toString();
      status.value = AuthStatus.unauthenticated;
    }
  }

  /// Step 7 & Logout
  Future<void> logout() async {
    print("👋 Logging out...");
    final currentToken = jwt.value;

    // context.go("/login");
    // 1. Clear Local State
    jwt.value = null;
    username.value = null;
    error.value = null;
    status.value = AuthStatus.logout;

    // 2. Clear Database
    await _sessionDao.clearSession();

    // 3. Notify Backend (Fire and forget)
    if (currentToken != null) {
      unawaited(_authService.logout(currentToken));
    }

    // Auto-reinit after short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      status.value = AuthStatus.unauthenticated;
    });
  }

  /// Fetch full user profile from Supabase Postgrest
  Future<void> fetchUser() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      print(
        "⚠️ [AuthBlock] No Supabase session found for fetchUser. Falling back...",
      );
      await _fetchLocalFallback();
      return;
    }

    try {
      print(
        "🔍 [AuthBlock] Fetching user profile from Supabase public.profiles...",
      );
      final response = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      if (response != null) {
        user.value = Map<String, dynamic>.from(response);
        // Map common fields to signals
        username.value =
            response['alias'] ?? session.user.email ?? "SupabaseUser";

        // Ensure email is present in the user map for UI
        user.value!['email'] = session.user.email;

        status.value = AuthStatus.authenticated;
        print(
          "✅ [AuthBlock] Profile fetched for ${username.value} with email ${session.user.email}",
        );
        return;
      } else {
        print(
          "⚠️ [AuthBlock] Profile record not found. Syncing existing user...",
        );
        await syncUserWithSupabase(session.user);
        user.value = {
          'id': session.user.id,
          'email': session.user.email,
          'userName': session.user.userMetadata?['user_name'] ?? 'User',
        };
      }
    } catch (e) {
      print(
        "⚠️ [AuthBlock] Remote fetch failed: $e. Falling back to local/guest.",
      );
    }
    await _fetchLocalFallback();
  }

  Future<void> _fetchLocalFallback() async {
    print("🔄 [AuthBlock] Attempting local fallback for User ID...");
    try {
      PersonData? localPerson = await _personDao.getPersonById(
        DataSeeder.guestPersonId,
      );

      if (localPerson == null) {
        print("✅ [AuthBlock] Using IN-MEMORY Guest User (Database Empty)");
        user.value = {
          'id': 'guest-id',
          'userName': 'Guest',
          'firstName': 'Guest',
          'lastName': 'User',
          'email': 'guest@offline',
          'role': 'guest',
        };
        username.value = 'Guest';
        status.value = AuthStatus.authenticated;
        return;
      }

      print(
        "✅ [AuthBlock] Falling back to local user ID ${localPerson.personID}: ${localPerson.firstName}",
      );

      user.value = {
        'id': localPerson.personID.toString(),
        'userName': localPerson.firstName,
        'firstName': localPerson.firstName,
        'lastName': localPerson.lastName,
        'email': 'offline@local',
        'role': 'admin',
      };
      username.value = localPerson.firstName;
      status.value = AuthStatus.authenticated;
    } catch (dbError) {
      print("❌ [AuthBlock] Local DB fallback failed: $dbError");
    }
  }
}
