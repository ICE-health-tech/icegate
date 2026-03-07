import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:ice_gate/data_layer/Protocol/User/RegistrationProtocol.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
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

  StreamSubscription? _accountSubscription;

  /// Helper to persist session locally (e.g. after Google OAuth)
  Future<void> persistSession(String token, String name) async {
    print("💾 [AuthBlock] Persisting session locally for $name...");
    await _sessionDao.saveSession(token, name);
  }

  /// Synchronize Supabase Auth user with public profile table
  /// This ensures that the mandatory 'persons' row exists for PowerSync.
  /// For RETURNING users, we do NOT overwrite first_name/last_name/profile_image
  /// because the user may have edited them in the profile page.
  Future<void> syncUserWithSupabase(User user) async {
    print("🔄 [AuthBlock] Synchronizing user ${user.id} with Supabase...");

    try {
      final client = Supabase.instance.client;
      final userId = user.id;

      // Check if user already exists in 'persons' table
      final existingPerson = await client
          .from('persons')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingPerson != null) {
        // RETURNING USER: DO NOT touch the 'persons' table!
        // Touching it (even just updated_at) can cause PowerSync to sync down
        // stale remote data and overwrite local user edits (name/images).
        print(
          "   - Existing user found. Skipping 'persons' sync to prevent rollback.",
        );
      } else {
        // NEW USER: insert with Google OAuth metadata as defaults
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

        print("   - New user. Inserting into 'persons' with OAuth metadata...");
        await client.from('persons').insert({
          'id': userId,
          'first_name': firstName,
          'last_name': lastName,
          'profile_image_url': user.userMetadata?['avatar_url'],
          'is_active': true,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }

      await client.from('profiles').upsert({
        'id': userId, // Dùng ID của User làm PK
        'person_id': userId, // Khớp với bảng persons
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id'); // LUÔN LUÔN dùng 'id' làm conflict target cho PK

      // 3. Ensure email address exists
      if (user.email != null) {
        print("   - Ensuring 'email_addresses' row exists...");
        await client.from('email_addresses').upsert({
          'id': userId, // Using user ID as primary key
          'person_id': userId,
          'email_address': user.email,
          'is_primary': true,
          'status': 'verified',
        }, onConflict: 'id'); // Standard conflict for emails
      }

      // 4. Ensure user_account exists
      final usernameStr =
          user.userMetadata?['user_name'] ??
          user.email?.split('@')[0] ??
          'user_${userId.substring(0, 8)}';

      print("   - Ensuring 'user_accounts' row exists...");
      await client.from('user_accounts').upsert({
        'id': userId,
        'person_id': userId,
        'username': usernameStr,
        'password_hash': 'EXTERNAL_AUTH',
        'role': 'user',
        'is_locked': 0,
      }, onConflict: 'id'); // Match person_id to existing account

      // 5. Ensure detail_information exists

      print(
        "✅ [AuthBlock] Identity sync complete for User: $userId, Username: $usernameStr",
      );
    } catch (e) {
      print("❌ [AuthBlock] Identity synchronization failed: $e");
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
        unawaited(_authService.appSync(session.accessToken));
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

  /// Step 5: Authenticate with user credentials (ident can be email or username)
  Future<void> login(
    String ident,
    String password,
    BuildContext context,
  ) async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    print("🔐 [AuthBlock] Authenticating: $ident");

    try {
      String email = ident;

      // 1. Resolve username to email if identifier doesn't look like an email
      if (!ident.contains('@')) {
        print("🔍 [AuthBlock] Resolving username '$ident' to email...");
        try {
          // Attempt to find the user in the public user_accounts table first.
          final response = await Supabase.instance.client
              .from('user_accounts')
              .select('person_id')
              .eq('username', ident)
              .maybeSingle();

          if (response != null && response['person_id'] != null) {
            final personId = response['person_id'];
            // Now get the primary email for this person
            final emailResponse = await Supabase.instance.client
                .from('email_addresses')
                .select('email_address')
                .eq('person_id', personId)
                .eq('is_primary', true)
                .maybeSingle();

            if (emailResponse != null &&
                emailResponse['email_address'] != null) {
              email = emailResponse['email_address'];
              print("✅ [AuthBlock] Username '$ident' resolved to '$email'");
            }
          }
        } catch (resolveErr) {
          print(
            "⚠️ [AuthBlock] Username resolution failed: $resolveErr. Falling back...",
          );
        }

        if (email == ident) {
          print(
            "⚠️ [AuthBlock] Username resolution failed for: $ident. Attempting direct login.",
          );
        }
      }

      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithPassword(email: email, password: password);

      final session = response.session;
      if (session != null) {
        jwt.value = session.accessToken;
        username.value = session.user.email ?? ident;

        final token = jwt.value;
        final user = username.value;
        if (token != null && user != null) {
          await persistSession(token, user);
        }
        await syncUserWithSupabase(session.user);
        unawaited(_authService.appSync(session.accessToken));

        status.value = AuthStatus.authenticated;
        print("✅ [AuthBlock] Authentication successful.");
        await fetchUser();
      } else {
        throw Exception("Supabase returned no session");
      }
    } catch (e) {
      print("❌ [AuthBlock] Authentication failed: $e");
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

      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        print(
          "👤 [AuthBlock] User already present, syncing identity... with ${user.id}",
        );
        await syncUserWithSupabase(user);
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          unawaited(_authService.appSync(session.accessToken));
        }
      }

      print("✅ [AuthBlock] User account synced to database.");

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
          unawaited(_authService.appSync(response.session!.accessToken));
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
    await _accountSubscription?.cancel();
    _accountSubscription = null;

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
        "🔍 [AuthBlock] Fetching user profile from Supabase profiles & user_accounts...",
      );

      // 1. Fetch profile first
      final profileResponse = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', session.user.id)
          .maybeSingle();

      // 2. Fetch username from user_accounts specifically
      final personId =
          session.user.userMetadata?['person_id'] ?? session.user.id;
      final accountResponse = await Supabase.instance.client
          .from('user_accounts')
          .select('username')
          .eq('person_id', personId)
          .maybeSingle();

      if (profileResponse != null) {
        user.value = Map<String, dynamic>.from(profileResponse);
        username.value =
            accountResponse?['username'] ??
            session.user.email ??
            "SupabaseUser";
        user.value!['email'] = session.user.email;

        status.value = AuthStatus.authenticated;
        print(
          "✅ [AuthBlock] Profile fetched for ${username.value} with email ${session.user.email}",
        );

        _startWatchingAccount(personId);
        return; // THOÁT HÀM THÀNH CÔNG
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

        // BẮT BUỘC THÊM 3 DÒNG NÀY ĐỂ CHẶN FALLBACK
        status.value = AuthStatus.authenticated;
        _startWatchingAccount(session.user.id);
        return; // THOÁT HÀM, NGĂN KHÔNG CHO CHẠY XUỐNG DƯỚI
      }
    } catch (e) {
      print(
        "⚠️ [AuthBlock] Remote fetch failed: $e. Falling back to local/guest.",
      );
      // Chỉ chạy fallback nếu thực sự có lỗi mạng (catch error)
      await _fetchLocalFallback();
    }
  }

  Future<void> _fetchLocalFallback() async {
    print("🔄 [AuthBlock] Attempting local fallback for User ID...");
    try {
      PersonData? localPerson = await _personDao.getPersonById(
        DataSeeder.guestPersonId,
      );

      if (localPerson == null) {
        print("⚠️ [AuthBlock] Local guest fallback failed. No persons record.");
        return;
      }

      // Start watching the account reactively
      _startWatchingAccount(localPerson.id);

      print(
        "✅ [AuthBlock] Falling back to local user ID ${localPerson.id}: ${localPerson.firstName}",
      );

      user.value = {
        'id': localPerson.id,
        'userName': localPerson.firstName,
        'firstName': localPerson.firstName,
        'lastName': localPerson.lastName,
        'email': 'offline@local',
        'role': 'admin',
      };
    } catch (dbError) {
      print("❌ [AuthBlock] Local DB fallback failed: $dbError");
    }
  }

  /// Step 22: Update username
  Future<void> changeUsername(String newUsername) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) throw Exception("Not authenticated");

    print("👤 [AuthBlock] Changing username to: $newUsername");

    try {
      final client = Supabase.instance.client;
      final userId = authUser.id;
      final personId = authUser.userMetadata?['person_id'] ?? userId;

      // 1. Update Supabase Auth metadata
      await client.auth.updateUser(
        UserAttributes(data: {'user_name': newUsername}),
      );

      // 2. Update public user_accounts table (remote)
      await client
          .from('user_accounts')
          .update({'username': newUsername})
          .eq('person_id', personId);

      // 3. Update local database
      final personAccount = await _personDao.getAccountByPersonId(personId);
      if (personAccount != null) {
        await _personDao.updateAccount(
          personAccount.copyWith(username: Value<String?>(newUsername)),
        );
      }

      // 4. Update UI signal
      username.value = newUsername;
      print("✅ [AuthBlock] Username updated successfully.");
    } catch (e) {
      print("❌ [AuthBlock] Failed to change username: $e");
      rethrow;
    }
  }

  void _startWatchingAccount(String personId) {
    _accountSubscription?.cancel();
    print("👀 [AuthBlock] Starting reactive watch for account: $personId");
    _accountSubscription = _personDao.watchAccountByPersonId(personId).listen((
      account,
    ) {
      if (account != null && account.username != null) {
        if (username.value != account.username) {
          print(
            "🔄 [AuthBlock] Username synced from local DB: ${account.username}",
          );
          batch(() {
            username.value = account.username;
          });
        }
      }
    });
  }
}
