import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/initial_layer/CoreLogics/CustomAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/PasskeyAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/BiometricAuthService.dart';
import 'package:ice_gate/initial_layer/CoreLogics/SecureStorageService.dart';
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
  final BiometricAuthService _biometricService;
  final SecureStorageService _secureStorage;
  final PersonManagementDAO _personDao;

  // --- Signals (State) ---
  final status = signal<AuthStatus>(AuthStatus.init);
  final jwt = signal<String?>(null);
  final error = signal<String?>(null);
  final username = signal<String?>(null);
  final user = signal<Map<String, dynamic>?>(null);
  final showWelcomeBack = signal<bool>(false);
  
  // Security Identity State
  final hasLocalPassword = signal<bool>(true); // Default true to avoid flash
  final isPasskeyEnrolled = signal<bool>(false);
  
  // Remembered user for "Identity Glance" on entry page
  final rememberedUser = signal<Map<String, String?>?> (null);

  /// Resolved Person ID from current session or user signal
  String? get personId => Supabase.instance.client.auth.currentUser?.id ?? user.value?['id'];

  AuthBlock({
    required CustomAuthService authService,
    required SessionDAO sessionDao,
    required PasskeyAuthService passkeyService,
    required BiometricAuthService biometricService,
    required SecureStorageService secureStorage,
    required PersonManagementDAO personDao,
  }) : _authService = authService,
       _sessionDao = sessionDao,
       _passkeyService = passkeyService,
       _biometricService = biometricService,
       _secureStorage = secureStorage,
       _personDao = personDao;

  StreamSubscription? _accountSubscription;
  bool _isLocked = false; // Reentrancy lock to prevent double-login race conditions

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

      // 🛠️ PROACTIVE REPAIR: Force-correct the tenant_id for this user
      // We do this for EVERY session sync to ensure consistency across devices/legacy accounts.
      const forcedTenantId = "00000000-0000-0000-0000-000000000001";
      
      try {
        // 1. Update Supabase
        await client
            .from('persons')
            .update({'tenant_id': forcedTenantId})
            .eq('id', userId);
        print('✅ [Auth] Super-correcting Supabase tenant_id to ...0001');
        
        // 2. Update Local Database via DAO
        await _personDao.updateTenantId(userId, forcedTenantId);
        print('✅ [Auth] Super-correcting Local tenant_id to ...0001');

        // 3. Migrate any existing Guest data to this new identity
        // This promotes offline progress to the cloud.
        await _personDao.migrateGuestData(userId, forcedTenantId);
        print('✅ [Auth] Migrated orphaned guest data to user $userId');
      } catch (e) {
        print('⚠️ [Auth] Minor error during tenant repair (expected for offline/guest): $e');
      }

      if (existingPerson != null) {
        // RETURNING USER: Skip full field overwrite to keep local edits
        print("   - Existing user found. Identity verified.");
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

        print("   - New user. Inserting metadata defaults...");

        await client.from('persons').insert({
          'id': userId,
          'tenant_id': forcedTenantId,
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

  /// Biometric Login Flow (Returns true if successful)
  Future<bool> loginWithBiometrics(BuildContext context) async {
    if (_isLocked) return false;
    _isLocked = true;

    try {
      print("🔐 [AuthBlock] Biometric Login Guard: Locked");
      status.value = AuthStatus.authenticating;
      error.value = null;
      print("🧬 [AuthBlock] Authenticating with biometrics...");
      final isSupported = await _biometricService.canAuthenticate();
      if (!isSupported) {
        throw Exception(
          "Biometric authentication is not supported on this device.",
        );
      }

      final isEnabled = await _secureStorage.isBiometricEnabled();
      if (!isEnabled) {
        throw Exception("Biometric login is not enabled for this account.");
      }

      final authenticated = await _biometricService.authenticate(
        reason: "Please authenticate to log in to ICE Gate",
      );

      if (authenticated) {
        // HARDENING: Check if we should use the Passkey Hub instead of legacy passwords
        final isPasskeyRegistered = await _secureStorage.isBiometricEnabled(); // Re-using this flag for passkey context
        final credentials = await _secureStorage.getCredentials();
        final email = credentials['username'];

        if (isPasskeyRegistered && email != null) {
          print("🛡️ [AuthBlock] Hardened Flow: Using Passkey Hub for biometric login...");
          return await loginWithPasskey(context, email: email);
        }

        // Fallback for users who haven't migrated to Passkey yet
        final password = credentials['password'];
        if (email != null && password != null) {
          print("⚠️ [AuthBlock] Legacy Flow: Using stored password...");
          await login(email, password, context);
          return status.value == AuthStatus.authenticated;
        } else {
          throw Exception(
            "No stored credentials found. Please log in with password first.",
          );
        }
      } else {
        throw Exception("Biometric authentication failed or canceled.");
      }
    } catch (e) {
      print("❌ [AuthBlock] Biometric Login failed: $e");
      error.value = e.toString();
      status.value = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLocked = false;
      print("🔐 [AuthBlock] Biometric Login Guard: Released");
    }
  }

  /// Passkey Login Flow (Returns true if successful)
  Future<bool> loginWithPasskey(BuildContext context, {String? email}) async {
    // Note: If called from authenticateWithBiometric, the outer lock is already active
    status.value = AuthStatus.authenticating;
    error.value = null;
    
    // Use provided email, fallback to remembered, or default test
    final targetEmail = email ?? rememberedUser.value?['username'] ?? "duylong.art@gmail.com";
    print("--------------------------------------------------");
    print("🔑 PASSKEY AUTHENTICATION INITIATED");
    print("📧 Target Identity: $targetEmail");
    print("--------------------------------------------------");

    try {
      // 1. Get Challenge / Options - pass the identifier (email/username)
      // CustomAuthService now returns the full publicKey JSON options string
      final optionsJson = await _authService.getPasskeyChallenge(email: targetEmail);
      // print("🔑 Challenge received: $challenge");

      // 2. Perform Passkey Assertion
      // Call the platform passkey service with the full options
      final credential = await _passkeyService.loginRequest(
        challenge: "", // Not used as challenge is inside optionsJson now
        optionsJson: optionsJson,
      );

      if (credential == null) {
        throw Exception("Passkey assertion canceled or failed");
      }

      // 3. Verify Assertion - pass the credential and email
      final data = await _authService.verifyPasskeyLogin(
        credential: credential,
        email: targetEmail,
      );

      final token = data['token'] ?? data['jwt'];
      if (token != null && token.toString().isNotEmpty) {
        jwt.value = token.toString();
        // Assume username returned or fetched next
        username.value = data['userName'] ?? "PasskeyUser";

        await _sessionDao.saveSession(jwt.value!, username.value);

        status.value = AuthStatus.authenticated;
        print("✅ Passkey Login successful.");

        // Save username for possible biometric/re-auth if passkey is tied to user
        await _secureStorage.saveCredentials(username.value!, "PASSKEY_AUTH");
        await _secureStorage.setBiometricEnabled(true);

        await fetchUser();
        return true;
      } else {
        throw Exception("Server returned no token for passkey");
      }
    } catch (e) {
      final errorStr = e.toString();
      print("❌ Passkey Authentication failed: $errorStr");
      
      // Don't show scary error if user simply canceled or dismissed the prompt
      if (!errorStr.contains('1001') && !errorStr.contains('canceled') && !errorStr.contains('dismissed')) {
        error.value = "Auth Error: $errorStr";
      }
      
      status.value = AuthStatus.unauthenticated;
      return false;
    }
  }

  /// Passkey Enrollment Flow (Registers this device as an authenticator)
  /// Returns 'success', 'canceled', or an error message.
  Future<String> enrollPasskey(BuildContext context) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return "User session not found";

    print("🔑 [AuthBlock] Initiating Passkey Enrollment for ${authUser.email}...");
    try {
      // 1. Get Registration Options from Backend
      final registrationOptionsJson = await _authService.getPasskeyRegistrationOptions(authUser.email!, authUser.id);
      
      // 2. Perform Passkey Registration on device
      // Pass the JSON directly as the plugin expects standard creation options
      final credential = await _passkeyService.registerRequest(
        userId: authUser.id,
        username: authUser.email ?? "Ice_User",
        challenge: "", // Not used as challenge is inside registrationOptionsJson now
        optionsJson: registrationOptionsJson,
      );

      if (credential == null) {
        throw Exception("Passkey registration canceled or failed");
      }

      // 3. Verify and Save Credential on server
      await _authService.verifyPasskeyRegistration(
        credential: credential,
        email: authUser.email!,
        userId: authUser.id,
      );

      print("✅ [AuthBlock] Passkey Enrollment successful.");
      isPasskeyEnrolled.value = true;
      
      // Save info that we have a passkey for this user
      await _secureStorage.setBiometricEnabled(true);
      
      return "success";
    } catch (e) {
      final errorStr = e.toString();
      print("❌ [AuthBlock] Passkey Enrollment failed: $errorStr");
      
      if (errorStr.contains('1001') || errorStr.contains('canceled')) {
        return "canceled";
      }
      
      error.value = "Enrollment Error: $errorStr";
      return errorStr;
    }
  }
  // --- Actions ---

  /// Step 1: Check for existing session (e.g. from cookies/local storage)
  /// In this Flutter app, we'll simulate cookie check or just go to auto-auth
  Future<void> checkSession(BuildContext context) async {
    status.value = AuthStatus.checkingSession;
    print("🔍 [AuthBlock] Checking for Supabase session...");
    
    // Load remembered identity for UI preview
    await _loadRememberedUser();

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

        // Securely store credentials if biometric login is not yet confirmed
        // For production, you might want to ask the user before enabling this.
        await _secureStorage.saveCredentials(
          email, 
          password,
          displayName: session.user.userMetadata?['full_name'] ?? session.user.userMetadata?['name'],
          avatarUrl: session.user.userMetadata?['avatar_url'],
        );
        await _secureStorage.setBiometricEnabled(true);
        await _loadRememberedUser();

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

        // Save metadata for credential persistence
        final email = user.email ?? "GoogleUser";
        await _secureStorage.saveCredentials(
          email, 
          "GOOGLE_AUTH",
          displayName: user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
          avatarUrl: user.userMetadata?['avatar_url'],
        );
        await _secureStorage.setBiometricEnabled(true);
        await _loadRememberedUser();
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

          // Save credentials after registration
          await _secureStorage.saveCredentials(
            payload.email, 
            payload.password,
            displayName: payload.userName,
          );
          await _secureStorage.setBiometricEnabled(true);
          await _loadRememberedUser();

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
          .select('username, password_hash')
          .eq('person_id', personId)
          .maybeSingle();

      if (profileResponse != null) {
        user.value = Map<String, dynamic>.from(profileResponse);
        username.value =
            accountResponse?['username'] ??
            session.user.email ??
            "SupabaseUser";
        user.value!['email'] = session.user.email;
        
        final hash = accountResponse?['password_hash'];
        hasLocalPassword.value = hash != null && hash != 'EXTERNAL_AUTH' && hash.isNotEmpty;
        
        // Check for passkey enrollment on this device/account
        final passkeyEnrolled = await _secureStorage.isBiometricEnabled();
        isPasskeyEnrolled.value = passkeyEnrolled;
        hasLocalPassword.value = true;
        
        // isPasskeyEnrolled.value = passkeyEnrolled; // Already set above
        
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

  /// Explicitly triggers a data migration check to ensure all local records
  /// are correctly associated with the authenticated user and tenant bucket.
  Future<void> repairTenantBucket() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      print("⚠️ [Auth] Cannot repair bucket without an active session.");
      return;
    }

    try {
      final String personId = session.user.id;
      const String tenantId = "00000000-0000-0000-0000-000000000001";
      
      print("🛰️ [Auth] Manual repair triggered for $personId");
      // Use the internal DAO reference
      await _personDao.migrateGuestData(personId, tenantId);
      print("✅ [Auth] Manual repair successful.");
    } catch (e) {
      print("❌ [Auth] Manual repair failed: $e");
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

  Future<void> _loadRememberedUser() async {
    final data = await _secureStorage.getRememberedUser();
    if (data['username'] != null) {
      rememberedUser.value = data;
      print("🧊 [AuthBlock] Remembered user loaded: ${data['displayName'] ?? data['username']}");
    } else {
      rememberedUser.value = null;
    }
  }
}
