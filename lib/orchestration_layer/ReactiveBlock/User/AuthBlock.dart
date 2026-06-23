import 'package:flutter/material.dart';
import 'package:drift/drift.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/DataSeeder.dart';
import 'package:ice_gate/orchestration_layer/Services/CustomAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/PasskeyAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/BiometricAuthService.dart';
import 'package:ice_gate/orchestration_layer/Services/SecureStorageService.dart';
import 'package:ice_gate/data_layer/Protocol/User/RegistrationProtocol.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:ice_gate/utils/app_log.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

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
  final rememberedUser = signal<Map<String, String?>?>(null);

  /// Set after [signUp] when Supabase returns no session (email confirmation required).
  final registerPendingEmail = signal<String?>(null);

  /// Resolved Person ID from current session or user signal
  String? get personId =>
      Supabase.instance.client.auth.currentUser?.id ?? user.value?['id'];

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
  bool _isLocked =
      false; // Reentrancy lock to prevent double-login race conditions

  Timer? _authInteractionTimer;
  /// Wall-clock end for auth watchdog — [Timer] may not run while the app is
  /// backgrounded (OAuth in Safari); [checkAuthInteractionDeadline] uses this on resume.
  DateTime? _authInteractionDeadline;

  /// Browser OAuth (Google/Apple) often takes >10s; short timeouts falsely show
  /// `err_auth_timeout` before the deep-link callback arrives.
  static const Duration _oauthBrowserTimeout = Duration(minutes: 3);

  /// Clears the OAuth / login spinner watchdog (call when session is ready).
  void cancelAuthInteractionTimeout() {
    _authInteractionTimer?.cancel();
    _authInteractionTimer = null;
    _authInteractionDeadline = null;
  }

  /// Call from [WidgetsBindingObserver.didChangeAppLifecycleState] when the app
  /// resumes. Applies timeout if the user spent longer than the armed duration
  /// in the browser while timers were throttled.
  void checkAuthInteractionDeadline() {
    if (_authInteractionDeadline == null) return;
    if (DateTime.now().isBefore(_authInteractionDeadline!)) return;
    _applyAuthInteractionTimeoutIfNeeded();
  }

  void _applyAuthInteractionTimeoutIfNeeded() {
    if (status.value != AuthStatus.authenticating &&
        status.value != AuthStatus.registering) {
      cancelAuthInteractionTimeout();
      return;
    }
    status.value = AuthStatus.unauthenticated;
    error.value = 'err_auth_timeout';
    authLog('⏱️ interaction timed out (watchdog) → err_auth_timeout');
    cancelAuthInteractionTimeout();
  }

  /// [signInWithOAuth] returns after opening Safari / system browser; session
  /// usually arrives later via deep link. Keep [AuthStatus.authenticating] until
  /// the session arrives or [_oauthBrowserTimeout] elapses.
  void _idleLoginUiWhileOAuthContinuesInBrowser() {
    if (Supabase.instance.client.auth.currentSession == null) {
      armAuthInteractionTimeout(_oauthBrowserTimeout);
    }
  }

  /// Called when the app resumes from Safari during OAuth — extend the watchdog
  /// and complete login if Supabase already has a session from the deep link.
  void extendAuthInteractionTimeoutOnResume() {
    if (status.value != AuthStatus.authenticating &&
        status.value != AuthStatus.registering) {
      return;
    }
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      authLog('✅ resume: session ready (${session.user.email ?? session.user.id})');
      cancelAuthInteractionTimeout();
      error.value = null;
      status.value = AuthStatus.authenticated;
      return;
    }
    authLog('⏳ resume: still waiting for OAuth deep link; extending timeout');
    armAuthInteractionTimeout(_oauthBrowserTimeout);
  }

  /// Watchdog: if still [AuthStatus.authenticating] or [AuthStatus.registering]
  /// after [duration], reset to unauthenticated so the user can try again
  /// (covers stuck OAuth / hung API). Default 10s stops the login button spinner
  /// when the network or Supabase does not return.
  void armAuthInteractionTimeout([
    Duration duration = const Duration(seconds: 10),
  ]) {
    cancelAuthInteractionTimeout();
    _authInteractionDeadline = DateTime.now().add(duration);
    _authInteractionTimer = Timer(duration, _applyAuthInteractionTimeoutIfNeeded);
  }

  /// Helper to persist session locally (e.g. after Google OAuth)
  Future<void> persistSession(String token, String name) async {
    appLog("💾 [AuthBlock] Persisting session locally for $name...");
    await _sessionDao.saveSession(token, name);
  }

  /// Synchronize Supabase Auth user with public profile table
  /// This ensures that the mandatory 'persons' row exists for PowerSync.
  /// For RETURNING users, we do NOT overwrite first_name/last_name/profile_image
  /// because the user may have edited them in the profile page.
  Future<void> syncUserWithSupabase(User user) async {
    appLog("🔄 [AuthBlock] Synchronizing user ${user.id} with Supabase...");

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
        appLog('✅ [Auth] Super-correcting Supabase tenant_id to ...0001');

        // 2. Update Local Database via DAO
        await _personDao.updateTenantId(userId, forcedTenantId);
        appLog('✅ [Auth] Super-correcting Local tenant_id to ...0001');

        // 3. Migrate any existing Guest data to this new identity
        // This promotes offline progress to the cloud.
        await _personDao.migrateGuestData(userId, forcedTenantId);
        appLog('✅ [Auth] Migrated orphaned guest data to user $userId');
      } catch (e) {
        appLog(
          '⚠️ [Auth] Minor error during tenant repair (expected for offline/guest): $e',
        );
      }

      if (existingPerson != null) {
        // RETURNING USER: Skip full field overwrite to keep local edits
        appLog("   - Existing user found. Identity verified.");
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

        appLog("   - New user. Inserting metadata defaults...");

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
        appLog("   - Ensuring 'email_addresses' row exists...");
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

      appLog("   - Ensuring 'user_accounts' row exists...");
      await client.from('user_accounts').upsert({
        'id': userId,
        'person_id': userId,
        'username': usernameStr,
        'password_hash': 'EXTERNAL_AUTH',
        'role': 'user',
        'is_locked': 0,
      }, onConflict: 'id'); // Match person_id to existing account

      // 5. Ensure detail_information exists

      appLog(
        "✅ [AuthBlock] Identity sync complete for User: $userId, Username: $usernameStr",
      );
    } catch (e) {
      appLog("❌ [AuthBlock] Identity synchronization failed: $e");
    }
  }

  /// Mock/Guest Login logic
  Future<void> loginAsGuest() async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    appLog("👤 Logging in as Guest...");

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

      appLog("✅ Guest login successful with mock data.");
    } catch (e) {
      appLog("❌ Guest login failed: $e");
      error.value = "err_unexpected";
      status.value = AuthStatus.unauthenticated;
    }
  }

  String _mapError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains("invalid login credentials")) {
      return "err_invalid_credentials";
    }
    if (str.contains("email not confirmed")) return "err_email_not_confirmed";
    if (str.contains("user not found")) return "err_user_not_found";
    if (str.contains("network") || str.contains("connection")) {
      return "err_network_fail";
    }
    if (str.contains("too many requests") || str.contains("rate limit")) {
      return "err_too_many_attempts";
    }
    if (str.contains("biometric") &&
        (str.contains("not supported") || str.contains("available"))) {
      return "err_biometric_unsupported";
    }
    if (str.contains("biometric") && str.contains("not enabled")) {
      return "err_biometric_disabled";
    }
    if (str.contains("google") &&
        (str.contains("canceled") ||
            str.contains("cancelled") ||
            str.contains("sign_in_canceled"))) {
      return "err_google_canceled";
    }
    // Preserve detailed Google/Supabase errors for debugging.
    // The UI will show raw text for unknown keys (see LoginPage._getLocalizedError).
    if (str.contains("id token missing")) return "err_google_failed";
    if (str.contains("google")) return e.toString();
    if (str.contains("passkey") &&
        (str.contains("canceled") ||
            str.contains("dismissed") ||
            str.contains("1001"))) {
      return "err_passkey_canceled";
    }
    if (str.contains("passkey") || str.contains("assertion")) {
      return "err_passkey_failed";
    }

    // Preserve the original exception text so the UI can show something more
    // useful than a generic "System Error". UI helpers treat this as
    // `err_unexpected` with details after the delimiter.
    //
    // NOTE: This is still safe because:
    // - on release builds, the UI can choose to display a generic message, and
    // - the log still has the raw exception for debugging.
    final raw = e.toString().trim();
    if (raw.isEmpty) return "err_unexpected";
    // Avoid extremely long banners.
    final compact = raw.length > 200 ? '${raw.substring(0, 200)}…' : raw;
    return 'err_unexpected|$compact';
  }

  /// Face ID / passkey button on login — one path only (no double prompts).
  Future<bool> loginWithQuickAccess(
    BuildContext context, {
    String? emailHint,
  }) async {
    await _migrateLegacyPasskeyFlag();
    final passkeyOn = await _secureStorage.isPasskeyEnabled();
    if (passkeyOn) {
      return loginWithPasskey(
        context,
        email: emailHint ?? rememberedUser.value?['username'],
      );
    }
    final biometricOn = await _secureStorage.isBiometricEnabled();
    if (biometricOn) {
      return loginWithBiometrics(context);
    }
    error.value = 'err_biometric_disabled';
    status.value = AuthStatus.unauthenticated;
    return false;
  }

  /// Biometric Login Flow (Returns true if successful)
  Future<bool> loginWithBiometrics(BuildContext context) async {
    if (_isLocked) return false;
    _isLocked = true;

    try {
      appLog("🔐 [AuthBlock] Biometric Login Guard: Locked");
      status.value = AuthStatus.authenticating;
      error.value = null;
      appLog("🧬 [AuthBlock] Authenticating with biometrics...");
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

      if (!authenticated) {
        error.value = 'err_passkey_canceled';
        status.value = AuthStatus.unauthenticated;
        return false;
      }

      final credentials = await _secureStorage.getCredentials();
      final email = credentials['username'];
      final password = credentials['password'];

      if (email == null || password == null || password.isEmpty) {
        throw Exception(
          "No stored credentials found. Please log in with password first.",
        );
      }

      // Passkey accounts use WebAuthn only — do not chain a second system prompt.
      if (password == 'PASSKEY_AUTH' || password == 'APPLE_AUTH') {
        throw Exception(
          "Passkey login required. Use the passkey button, not quick biometric.",
        );
      }

      appLog("🔐 [AuthBlock] Quick access: signing in with stored password...");
      await login(email, password, context);
      return status.value == AuthStatus.authenticated;
    } catch (e) {
      appLog("❌ [AuthBlock] Biometric Login failed: $e");
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLocked = false;
      appLog("🔐 [AuthBlock] Biometric Login Guard: Released");
    }
  }

  /// Passkey Login Flow (Returns true if successful)
  Future<bool> loginWithPasskey(
    BuildContext context, {
    String? email,
    bool isInternal = false,
  }) async {
    // Only apply lock if not an internal redirect (e.g. from Biometrics)
    if (!isInternal) {
      if (_isLocked) {
        appLog(
          "🔐 [AuthBlock] Passkey Login blocked: Another auth process in progress.",
        );
        return false;
      }
      _isLocked = true;
    }

    try {
      // Small 'Native Reset' delay to allow previous UI/Dialog context to fully clear
      if (isInternal) {
        await Future.delayed(const Duration(milliseconds: 500));
      } else {
        await Future.delayed(const Duration(milliseconds: 300));
      }

      status.value = AuthStatus.authenticating;
      error.value = null;

      // Use provided email, fallback to remembered, or default test
      final targetEmail =
          email ?? rememberedUser.value?['username'] ?? "duylong.art@gmail.com";
      appLog("--------------------------------------------------");
      appLog("🔑 PASSKEY AUTHENTICATION INITIATED");
      appLog("📧 Target Identity: $targetEmail");
      appLog("--------------------------------------------------");

      // 1. Get Challenge / Options - pass the identifier (email/username)
      // CustomAuthService now returns the full publicKey JSON options string
      final optionsJson = await _authService.getPasskeyChallenge(
        email: targetEmail,
      );
      // appLog("🔑 Challenge received: $challenge");

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
        appLog("✅ Passkey Login successful.");

        // Save username for possible biometric/re-auth if passkey is tied to user
        await _secureStorage.saveCredentials(username.value!, "PASSKEY_AUTH");
        await _secureStorage.setPasskeyEnabled(true);

        await fetchUser();
        return true;
      } else {
        throw Exception("Server returned no token for passkey");
      }
    } catch (e) {
      final errorStr = e.toString();
      appLog("❌ Passkey Authentication failed: $errorStr");
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
      return false;
    } finally {
      _isLocked = false;
      appLog("🔐 [AuthBlock] Passkey Login Guard: Released");
    }
  }

  /// Passkey Enrollment Flow (Registers this device as an authenticator)
  /// Returns 'success', 'canceled', or an error message.
  Future<String> enrollPasskey(BuildContext context) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return "User session not found";

    appLog(
      "🔑 [AuthBlock] Initiating Passkey Enrollment for ${authUser.email}...",
    );
    try {
      // 1. Get Registration Options from Backend
      final registrationOptionsJson = await _authService
          .getPasskeyRegistrationOptions(authUser.email!, authUser.id);

      // 2. Perform Passkey Registration on device
      // Pass the JSON directly as the plugin expects standard creation options
      final credential = await _passkeyService.registerRequest(
        userId: authUser.id,
        username: authUser.email ?? "Ice_User",
        challenge:
            "", // Not used as challenge is inside registrationOptionsJson now
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

      appLog("✅ [AuthBlock] Passkey Enrollment successful.");
      isPasskeyEnrolled.value = true;

      await _secureStorage.setPasskeyEnabled(true);
      await _secureStorage.setBiometricEnabled(true);

      return "success";
    } catch (e) {
      final errorStr = e.toString();
      appLog("❌ [AuthBlock] Passkey Enrollment failed: $errorStr");

      if (errorStr.contains('1001') ||
          errorStr.contains('canceled') ||
          errorStr.contains('cancelled')) {
        return "canceled";
      }

      if (errorStr.contains('1004')) {
        const msg =
            'Passkey domain not verified (1004). Use a physical iPhone/iPad '
            '(not Simulator), then reinstall the app so Associated Domains apply.';
        error.value = 'err_unexpected|$msg';
        return error.value!;
      }

      final mappedError = _mapEnrollmentError(e);
      error.value = mappedError;
      return mappedError;
    }
  }

  /// Enrollment errors — keep hub/server text instead of generic passkey_failed.
  String _mapEnrollmentError(Object e) {
    final str = e.toString().toLowerCase();
    if (str.contains('not supported')) return 'err_biometric_unsupported';
    if (str.contains('network') || str.contains('connection refused')) {
      return 'err_network_fail';
    }
    if (str.contains('hub returned')) {
      return 'err_unexpected|${e.toString().trim()}';
    }
    return _mapError(e);
  }
  // --- Actions ---

  /// Step 1: Check for existing session (e.g. from cookies/local storage)
  /// In this Flutter app, we'll simulate cookie check or just go to auto-auth
  Future<void> checkSession(BuildContext context) async {
    status.value = AuthStatus.checkingSession;
    appLog("🔍 [AuthBlock] Checking for Supabase session...");

    // Load remembered identity for UI preview
    await _loadRememberedUser();

    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        appLog("✅ [AuthBlock] Supabase session found.");
        jwt.value = session.accessToken;

        // You might want to get the username from the JWT or Supabase user metadata
        username.value = session.user.email ?? "SupabaseUser";

        status.value = AuthStatus.authenticated;
        // unawaited(_authService.appSync(session.accessToken));
        await fetchUser();
      } else {
        appLog("⚠️ [AuthBlock] No Supabase session found. Checking fallback...");
        await fetchAutoJWT();
      }
    } catch (e) {
      appLog("❌ [AuthBlock] Error checking Supabase session: $e");
      await fetchAutoJWT();
    }
  }

  /// Step 2: No Supabase session — leave user unauthenticated so [GoRouter]
  /// can open `/login`. Guest mode is optional via [loginAsGuest] on the login UI.
  Future<void> fetchAutoJWT() async {
    appLog(
      "🔍 Step 2: No Supabase session — sign-in required (guest not auto-selected).",
    );

    try {
      jwt.value = null;
      username.value = null;
      status.value = AuthStatus.unauthenticated;
      appLog(
        "⚠️ Auto-auth returned unauthenticated. Waiting for user credentials.",
      );
    } catch (e) {
      appLog("❌ Auto-auth fetch failed: $e");
      jwt.value = null;
      username.value = null;
      status.value = AuthStatus.unauthenticated;
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
    armAuthInteractionTimeout();
    appLog("🔐 [AuthBlock] Authenticating: $ident");

    try {
      String email = ident;

      // 1. Resolve username to email if identifier doesn't look like an email
      if (!ident.contains('@')) {
        appLog("🔍 [AuthBlock] Resolving username '$ident' to email...");
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
              appLog("✅ [AuthBlock] Username '$ident' resolved to '$email'");
            }
          }
        } catch (resolveErr) {
          appLog(
            "⚠️ [AuthBlock] Username resolution failed: $resolveErr. Falling back...",
          );
        }

        if (email == ident) {
          appLog(
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
        // unawaited(_authService.appSync(session.accessToken));

        status.value = AuthStatus.authenticated;
        appLog("✅ [AuthBlock] Authentication successful.");

        // Securely store credentials if biometric login is not yet confirmed
        // For production, you might want to ask the user before enabling this.
        await _secureStorage.saveCredentials(
          email,
          password,
          displayName:
              session.user.userMetadata?['full_name'] ??
              session.user.userMetadata?['name'],
          avatarUrl: session.user.userMetadata?['avatar_url'],
        );
        await _secureStorage.setBiometricEnabled(true);
        await _loadRememberedUser();

        await fetchUser();
      } else {
        throw Exception("Supabase returned no session");
      }
    } catch (e) {
      appLog("❌ [AuthBlock] Authentication failed: $e");
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
    } finally {
      cancelAuthInteractionTimeout();
    }
  }

  /// Apple Sign-In with Supabase
  Future<void> signInWithApple() async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    appLog("🍎 [AuthBlock] Initiating Apple Sign-In via Supabase...");

    try {
      if (Platform.isIOS || Platform.isMacOS) {
        // Apple nonce: pass SHA256(raw) to Apple, raw nonce to Supabase.
        final nonces = _createAppleNoncePair();
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          nonce: nonces.hashed,
        );

        final idToken = credential.identityToken;
        if (idToken == null) {
          throw Exception('Could not fetch Apple ID token.');
        }

        await Supabase.instance.client.auth.signInWithIdToken(
          provider: OAuthProvider.apple,
          idToken: idToken,
          nonce: nonces.raw,
        );
      } else {
        // Fallback to OAuth for other platforms
        const redirectTo = 'io.supabase.icegate://login-callback';
        authLog('🍎 opening Apple OAuth in browser → $redirectTo');
        await Supabase.instance.client.auth.signInWithOAuth(
          OAuthProvider.apple,
          redirectTo: redirectTo,
          authScreenLaunchMode: LaunchMode.externalApplication,
        );
        _idleLoginUiWhileOAuthContinuesInBrowser();
      }

      final user = Supabase.instance.client.auth.currentUser;

      if (user != null) {
        appLog(
          "👤 [AuthBlock] User already present, syncing identity... with ${user.id}",
        );
        await syncUserWithSupabase(user);
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          // unawaited(_authService.appSync(session.accessToken));
        }

        // Save metadata for credential persistence
        final email = user.email ?? "AppleUser";
        await _secureStorage.saveCredentials(
          email,
          "APPLE_AUTH",
          displayName:
              user.userMetadata?['full_name'] ?? user.userMetadata?['name'],
          avatarUrl: user.userMetadata?['avatar_url'],
        );
        await _secureStorage.setBiometricEnabled(true);
        await _loadRememberedUser();
      }

      appLog("✅ [AuthBlock] User account synced to database.");

      appLog(
        "✅ [AuthBlock] Apple OAuth command sent. State change will be handled in DataLayer.",
      );

      if (Supabase.instance.client.auth.currentSession != null) {
        cancelAuthInteractionTimeout();
      }
    } catch (e) {
      appLog("❌ [AuthBlock] Apple Sign-In initiation failed: $e");
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
      cancelAuthInteractionTimeout();
    }
  }

  /// Raw nonce for Supabase + SHA256 hash for Apple's credential request.
  ({String raw, String hashed}) _createAppleNoncePair() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final raw = base64Url.encode(bytes).replaceAll('=', '');
    final hashed = sha256.convert(utf8.encode(raw)).toString();
    return (raw: raw, hashed: hashed);
  }

  /// Google Sign-In with Supabase
  Future<void> signInWithGoogle() async {
    status.value = AuthStatus.authenticating;
    error.value = null;
    authLog('🌐 Google sign-in started');

    try {
      // Single-path OAuth flow (external browser) on all platforms.
      await _signInWithGoogleOAuth();
      return; // Browser flow completes via deep link + onAuthStateChange.
    } catch (e) {
      authLog('❌ Google sign-in failed to start: $e');
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
      cancelAuthInteractionTimeout();
    }
  }

  Future<void> _signInWithGoogleOAuth() async {
    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
      throw Exception(
        'SUPABASE_URL is missing or invalid. Add it to .env and rebuild.',
      );
    }
    const redirectTo = 'io.supabase.icegate://login-callback';
    authLog('redirectTo="$redirectTo" (len=${redirectTo.length})');
    authLog('supabaseUrl=$supabaseUrl');
    // User preference: go directly to external browser (Safari).
    final launched = await Supabase.instance.client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectTo,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
    authLog('browser launched=$launched — waiting for io.supabase.icegate://login-callback');
    _idleLoginUiWhileOAuthContinuesInBrowser();
  }

  /// Deep link for confirmation / OAuth / recovery — allowlist in Supabase Dashboard → Auth → URL config.
  static const String authEmailRedirect = 'io.supabase.icegate://login-callback';

  /// Registration logic using Supabase (sends confirmation email when enabled in project settings).
  Future<void> register(RegistrationPayload payload) async {
    status.value = AuthStatus.registering;
    error.value = null;
    registerPendingEmail.value = null;
    armAuthInteractionTimeout();
    appLog("📝 [AuthBlock] Registering user with Supabase: ${payload.userName}");

    try {
      final AuthResponse response = await Supabase.instance.client.auth.signUp(
        email: payload.email,
        password: payload.password,
        emailRedirectTo: authEmailRedirect,
        data: {
          'user_name': payload.userName,
          'first_name': payload.firstName,
          'last_name': payload.lastName,
        },
      );

      if (response.user != null) {
        appLog("✅ [AuthBlock] Registration successful for ${payload.email}");
        // If auto-logged in or confirmation not required:
        if (response.session != null) {
          jwt.value = response.session!.accessToken;
          username.value = payload.userName;
          await persistSession(jwt.value!, username.value!);
          await syncUserWithSupabase(response.user!);
          // unawaited(_authService.appSync(response.session!.accessToken));
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
          registerPendingEmail.value = payload.email.trim();
          appLog("📬 [AuthBlock] Confirmation email sent; awaiting verification.");
        }
      }
    } catch (e) {
      appLog("❌ [AuthBlock] Registration failed: $e");
      error.value = _mapError(e);
      status.value = AuthStatus.unauthenticated;
    } finally {
      cancelAuthInteractionTimeout();
    }
  }

  /// Resend signup confirmation (same redirect as [register]).
  Future<String?> resendSignupConfirmation(String email) async {
    final t = email.trim();
    if (t.isEmpty) return 'err_forgot_password_empty_email';
    if (!t.contains('@') || t.length < 5) {
      return 'err_forgot_password_invalid_email';
    }
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: t,
        emailRedirectTo: authEmailRedirect,
      );
      return null;
    } catch (e) {
      appLog('❌ [AuthBlock] resend signup: $e');
      return _mapError(e);
    }
  }

  void clearRegisterPending() {
    registerPendingEmail.value = null;
  }

  /// Step 7 & Logout
  Future<void> logout() async {
    appLog("👋 Logging out...");
    final currentToken = jwt.value;

    // context.go("/login");
    // 1. Clear Local State
    jwt.value = null;
    username.value = null;
    error.value = null;
    registerPendingEmail.value = null;
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
      appLog(
        "⚠️ [AuthBlock] No Supabase session found for fetchUser. Falling back...",
      );
      await _fetchLocalFallback();
      return;
    }

    try {
      appLog(
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
        hasLocalPassword.value =
            hash != null && hash != 'EXTERNAL_AUTH' && hash.isNotEmpty;

        isPasskeyEnrolled.value = await _secureStorage.isPasskeyEnabled();
        hasLocalPassword.value =
            hash != null && hash != 'EXTERNAL_AUTH' && hash.isNotEmpty;

        // isPasskeyEnrolled.value = passkeyEnrolled; // Already set above

        status.value = AuthStatus.authenticated;
        appLog(
          "✅ [AuthBlock] Profile fetched for ${username.value} with email ${session.user.email}",
        );

        _startWatchingAccount(personId);
        return; // THOÁT HÀM THÀNH CÔNG
      } else {
        appLog(
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
      appLog(
        "⚠️ [AuthBlock] Remote fetch failed: $e. Falling back to local/guest.",
      );
      // Chỉ chạy fallback nếu thực sự có lỗi mạng (catch error)
      await _fetchLocalFallback();
    }
  }

  Future<void> _fetchLocalFallback() async {
    appLog("🔄 [AuthBlock] Attempting local fallback for User ID...");
    try {
      PersonData? localPerson = await _personDao.getPersonById(
        DataSeeder.guestPersonId,
      );

      if (localPerson == null) {
        appLog("⚠️ [AuthBlock] Local guest fallback failed. No persons record.");
        return;
      }

      // Start watching the account reactively
      _startWatchingAccount(localPerson.id);

      appLog(
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
      appLog("❌ [AuthBlock] Local DB fallback failed: $dbError");
    }
  }

  /// Step 22: Update username
  Future<void> changeUsername(String newUsername) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) throw Exception("Not authenticated");

    appLog("👤 [AuthBlock] Changing username to: $newUsername");

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
      appLog("✅ [AuthBlock] Username updated successfully.");
    } catch (e) {
      appLog("❌ [AuthBlock] Failed to change username: $e");
      rethrow;
    }
  }

  /// Explicitly triggers a data migration check to ensure all local records
  /// are correctly associated with the authenticated user and tenant bucket.
  Future<void> repairTenantBucket() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      appLog("⚠️ [Auth] Cannot repair bucket without an active session.");
      return;
    }

    try {
      final String personId = session.user.id;
      const String tenantId = "00000000-0000-0000-0000-000000000001";

      appLog("🛰️ [Auth] Manual repair triggered for $personId");
      // Use the internal DAO reference
      await _personDao.migrateGuestData(personId, tenantId);
      appLog("✅ [Auth] Manual repair successful.");
    } catch (e) {
      appLog("❌ [Auth] Manual repair failed: $e");
    }
  }

  void _startWatchingAccount(String personId) {
    _accountSubscription?.cancel();
    appLog("👀 [AuthBlock] Starting reactive watch for account: $personId");
    _accountSubscription = _personDao.watchAccountByPersonId(personId).listen((
      account,
    ) {
      if (account != null && account.username != null) {
        if (username.value != account.username) {
          appLog(
            "🔄 [AuthBlock] Username synced from local DB: ${account.username}",
          );
          batch(() {
            username.value = account.username;
          });
        }
      }
    });
  }

  /// Sends Supabase password recovery email ([resetPasswordForEmail]).
  /// Returns `null` on success, or an error key from [_mapError].
  Future<String?> requestPasswordReset(String email) async {
    final t = email.trim();
    if (t.isEmpty) return 'err_forgot_password_empty_email';
    if (!t.contains('@') || t.length < 5) {
      return 'err_forgot_password_invalid_email';
    }
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        t,
        redirectTo: authEmailRedirect,
      );
      return null;
    } catch (e) {
      appLog('❌ [AuthBlock] resetPasswordForEmail: $e');
      return _mapError(e);
    }
  }

  /// Signs out, clears secure credentials, and optionally invokes Edge Function
  /// `delete-account` when deployed (server-side user + row deletion).
  Future<String?> deleteAccount() async {
    final client = Supabase.instance.client;
    if (client.auth.currentUser == null) {
      return 'delete_account_err_not_signed_in';
    }
    try {
      await client.functions.invoke('delete-account');
    } catch (e) {
      appLog('⚠️ [AuthBlock] delete-account Edge Function: $e');
    }
    try {
      await client.auth.signOut();
    } catch (e) {
      appLog('⚠️ [AuthBlock] Supabase signOut: $e');
    }
    await _secureStorage.clearCredentials();
    await logout();
    return null;
  }

  /// Users enrolled before passkey_enabled existed used biometric_enabled only.
  Future<void> _migrateLegacyPasskeyFlag() async {
    if (await _secureStorage.isPasskeyEnabled()) return;
    final creds = await _secureStorage.getCredentials();
    if (creds['password'] == 'PASSKEY_AUTH') {
      await _secureStorage.setPasskeyEnabled(true);
    }
  }

  Future<void> _loadRememberedUser() async {
    final data = await _secureStorage.getRememberedUser();
    if (data['username'] != null) {
      rememberedUser.value = data;
      appLog(
        "🧊 [AuthBlock] Remembered user loaded: ${data['displayName'] ?? data['username']}",
      );
    } else {
      rememberedUser.value = null;
    }
  }
}
