import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/Protocol/Social/SocialBlockProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ChallengeBlock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SocialBlockerBlock {
  static const _channel = MethodChannel('duylong.art/screentime');
  static const _storageKey = 'ice_gate_social_block_rules';
  static const _blacklistEnabledKey = 'ice_gate_blacklist_enabled';

  // Signals
  final rules = listSignal<SocialBlockRule>([]);
  final isAppBlacklistEnabled = signal<bool>(false);
  final isAnyBlockActive = signal<bool>(false);
  final isSystemAuthGranted = signal<bool>(false);
  final appSelectionJson = signal<String?>(null);
  final isSyncing = signal<bool>(false);
  final _currentTime = signal<DateTime>(DateTime.now());

  static const _appSelectionKey = 'ice_gate_social_app_selection';

  static bool get _nativeScreenTimeEnabled =>
      !kIsWeb && defaultTargetPlatform != TargetPlatform.iOS;

  FocusBlock? _focusBlock;
  String? _personId;
  late final void Function() _disposeEvaluation;
  dynamic _timerSubscription;

  SocialBlockerBlock();

  Future<void> init(FocusBlock focusBlock) async {
    _focusBlock = focusBlock;
    await _load();
    await checkAuthStatus();
    _setupEvaluation();
  }

  Future<void> initWithSync(FocusBlock focusBlock, String personId) async {
    _focusBlock = focusBlock;
    _personId = personId;
    await _load();
    print('SocialBlockerBlock: Initializing for person $personId');
    print('SocialBlockerBlock: Initializing for person $_focusBlock');
    await checkAuthStatus();

    // Pull from cloud on start
    await _pullSelectionFromCloud();

    _setupEvaluation();
  }

  void _setupEvaluation() {
    untracked(() => _currentTime.value = DateTime.now());

    // Evaluation Logic
    _disposeEvaluation = effect(() {
      final focusRunning = _focusBlock?.isRunning.value ?? false;
      final blacklistEnabled = isAppBlacklistEnabled.value;
      final now = _currentTime.value;
      final currentRules = rules.value;
      appSelectionJson.value; // Track selection changes for reactive updates

      // Evaluation logic:
      // Block is active IF (Blacklist is ON) AND ( (Focus is Running and rule allows it) OR (Schedule is Active) )
      bool shouldBeActive = false;

      if (blacklistEnabled) {
        // 1. Check if any rule matches current schedule
        final scheduleActive = currentRules.any((rule) {
          if (!rule.isEnabled) return false;

          // Check day match
          if (!rule.blockedDays.contains(now.weekday)) return false;

          // Check time match if schedule exists
          if (rule.scheduleStart != null && rule.scheduleEnd != null) {
            final start = rule.scheduleStart!;
            final end = rule.scheduleEnd!;
            final currentTotalMinutes = now.hour * 60 + now.minute;
            final startTotalMinutes = start.hour * 60 + start.minute;
            final endTotalMinutes = end.hour * 60 + end.minute;

            if (startTotalMinutes <= endTotalMinutes) {
              return currentTotalMinutes >= startTotalMinutes &&
                  currentTotalMinutes < endTotalMinutes;
            } else {
              // Overnight schedule
              return currentTotalMinutes >= startTotalMinutes ||
                  currentTotalMinutes < endTotalMinutes;
            }
          }
          return false;
        });

        // 2. Check focus linkage
        final focusActive =
            focusRunning &&
            currentRules.any((r) => r.isEnabled && r.blockDuringFocus);

        shouldBeActive = scheduleActive || focusActive;
      }

      // Update the active state signal and trigger native sync ONLY on state change
      if (shouldBeActive != untracked(() => isAnyBlockActive.value)) {
        Timer(Duration.zero, () {
          untracked(() {
            isAnyBlockActive.value = shouldBeActive;
            _toggleSystemShield(shouldBeActive);
          });
        });
      }
    });

    untracked(() => _currentTime.value = DateTime.now());

    // Tick current time every 30 seconds to evaluate schedules precisely
    _timerSubscription = Stream.periodic(const Duration(seconds: 30)).listen((
      _,
    ) {
      untracked(() => _currentTime.value = DateTime.now());
    });
  }

  void dispose() {
    _disposeEvaluation();
    _timerSubscription?.cancel();
  }

  // --- Actions ---

  Future<void> addRule(SocialBlockRule rule) async {
    untracked(() {
      rules.value = [...rules.value, rule];
    });
    await _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  Future<void> removeRule(String id) async {
    untracked(() {
      rules.value = rules.value.where((r) => r.id != id).toList();
    });
    await _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  Future<void> updateRule(SocialBlockRule rule) async {
    final index = rules.value.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      untracked(() {
        final newList = [...rules.value];
        newList[index] = rule;
        rules.value = newList;
      });
      await _persist();
      _toggleSystemShield(isAnyBlockActive.value);
    }
  }

  Future<void> toggleRule(String id, bool enabled) async {
    final index = rules.value.indexWhere((r) => r.id == id);
    if (index != -1) {
      untracked(() {
        final newList = [...rules.value];
        newList[index] = newList[index].copyWith(isEnabled: enabled);
        rules.value = newList;
      });
      await _persist();
      _toggleSystemShield(isAnyBlockActive.value);
    }
  }

  Future<void> recordChallengeAttempt(String ruleId) async {
    final index = rules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      rules[index] = rules[index].copyWith(
        totalChallenges: rules[index].totalChallenges + 1,
      );
      await _persist();
    }
  }

  Future<void> recordChallengeSuccess(String ruleId) async {
    final index = rules.indexWhere((r) => r.id == ruleId);
    if (index != -1) {
      rules[index] = rules[index].copyWith(
        challengesPassed: rules[index].challengesPassed + 1,
      );
      await _persist();
    }
  }

  /// Returns the challenge type/level if a challenge is required to disable the shield.
  /// This happens if turning OFF and there are active rules requiring challenges.
  ChallengeState? getRequiredChallengeForMaster(bool targetEnabled) {
    if (targetEnabled) return null; // Turning ON never requires challenge
    if (!isAppBlacklistEnabled.value) return null; // Already OFF

    // If turning OFF the master switch, check if any active rule has a challenge
    for (var rule in rules.value) {
      if (rule.isEnabled && rule.challengeType != ChallengeType.none) {
        return ChallengeState(
          question: "Unlock Master Shield",
          type: rule.challengeType,
          level: rule.challengeLevel,
        );
      }
    }
    return null;
  }

  Future<void> checkAuthStatus() async {
    // Temporarily disabled for distribution
    isSystemAuthGranted.value = true;
    /*
    try {
      final bool granted = await _channel.invokeMethod('checkAuthorization');
      isSystemAuthGranted.value = granted;
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error checking auth: $e");
    }
    */
  }

  Future<void> requestAuth() async {
    // Temporarily disabled for distribution
    isSystemAuthGranted.value = true;
    /*
    try {
      final bool granted = await _channel.invokeMethod('requestAuthorization');
      isSystemAuthGranted.value = granted;

      // UX improvement: if we just got granted, open the picker immediately
      if (granted) {
        await openAppPicker();
      }
    } on PlatformException catch (e) {
      if (e.code == 'AUTH_DENIED') {
        debugPrint(
          "SocialBlockerBlock: Auth denied. User needs to enable in Settings.",
        );
      }
      debugPrint("SocialBlockerBlock: Error requesting auth: ${e.message}");
    } catch (e) {
      debugPrint("SocialBlockerBlock: Unexpected error requesting auth: $e");
    }
    */
  }

  Future<void> openAppPicker() async {
    // Temporarily disabled for distribution
    debugPrint("SocialBlockerBlock: App picker disabled for distribution");
    /*
    try {
      // For iOS, the picker now handles persistence internally via tokens,
      // but we still want to trigger a sync to cloud after it closes.
      final String? result = await _channel.invokeMethod('showAppPicker', {
        'initialSelection': appSelectionJson.value,
      });

      if (result != null) {
        debugPrint("SocialBlockerBlock: App selection updated");
        appSelectionJson.value = result;
        await _persist();

        // Push to cloud after change
        await _pushSelectionToCloud();

        _toggleSystemShield(isAnyBlockActive.value);
      }
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error opening app picker: $e");
    }
    */
  }

  // --- Cloud Sync ---

  Future<void> appSync(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") return;

    untracked(() => isSyncing.value = true);
    try {
      print("🌐 [SocialBlockerBlock] Syncing rules from cloud...");
      await _pullSelectionFromCloud();
      print("✅ [SocialBlockerBlock] Cloud sync completed.");
    } catch (e) {
      print("⚠️ [SocialBlockerBlock] Cloud sync failed: $e");
    } finally {
      untracked(() => isSyncing.value = false);
    }
  }

  Future<void> _pullSelectionFromCloud() async {
    if (_personId == null ||
        _personId!.isEmpty ||
        _personId == '00000000-0000-0000-0000-000000000000') {
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('screen_time_settings')
          .select()
          .eq('person_id', _personId!)
          .maybeSingle();

      if (response != null) {
        final List<String> appTokens = List<String>.from(
          response['app_tokens'] ?? [],
        );
        final List<String> categoryTokens = List<String>.from(
          response['category_tokens'] ?? [],
        );

        debugPrint(
          "SocialBlockerBlock: Pulled ${appTokens.length} apps and ${categoryTokens.length} categories from cloud",
        );

        // iOS App Store builds do not ship Screen Time APIs.
        if (_nativeScreenTimeEnabled) {
          await _channel.invokeMethod('setSelection', {
            'appTokens': appTokens,
            'categoryTokens': categoryTokens,
          });
        }

        // Trigger UI update if needed (though appSelectionJson is mostly for macOS legacy)
        // For iOS, the tokens are the source of truth now.
      }
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error pulling from cloud: $e");
    }
  }

  Future<void> _pushSelectionToCloud() async {
    // Temporarily disabled for distribution
    /*
    if (_personId == null ||
        _personId!.isEmpty ||
        _personId == '00000000-0000-0000-0000-000000000000')
      return;

    try {
      // Get current selection from native side
      final Map<dynamic, dynamic>? selection = await _channel.invokeMethod(
        'getSelection',
      );
      if (selection != null) {
        final appTokens = List<String>.from(selection['appTokens'] ?? []);
        final categoryTokens = List<String>.from(
          selection['categoryTokens'] ?? [],
        );

        await Supabase.instance.client.from('screen_time_settings').upsert({
          'person_id': _personId!,
          'app_tokens': appTokens,
          'category_tokens': categoryTokens,
          'updated_at': DateTime.now().toIso8601String(),
        }, onConflict: 'person_id');
        debugPrint("SocialBlockerBlock: Pushed selection to cloud");
      }
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error pushing to cloud: $e");
    }
    */
  }

  void toggleBlacklist(bool enabled) {
    untracked(() {
      isAppBlacklistEnabled.value = enabled;
    });
    _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  void disableAllRules() {
    untracked(() {
      final newList = rules.value
          .map((r) => r.copyWith(isEnabled: false))
          .toList();
      rules.value = newList;
    });
    _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  // --- Persistence ---

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    isAppBlacklistEnabled.value = prefs.getBool(_blacklistEnabledKey) ?? false;

    final rulesJson = prefs.getStringList(_storageKey);
    if (rulesJson != null) {
      rules.value = rulesJson
          .map((j) => SocialBlockRule.fromJson(jsonDecode(j)))
          .toList();
    }

    appSelectionJson.value = prefs.getString(_appSelectionKey);
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blacklistEnabledKey, isAppBlacklistEnabled.value);

    final rulesJson = rules.value.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, rulesJson);

    if (appSelectionJson.value != null) {
      await prefs.setString(_appSelectionKey, appSelectionJson.value!);
    } else {
      await prefs.remove(_appSelectionKey);
    }
  }

  // --- Native Communication ---

  Future<void> _toggleSystemShield(bool active) async {
    // Temporarily disabled for distribution
    debugPrint(
      "SocialBlockerBlock: System shield toggle ($active) disabled for distribution",
    );
    /*
    // If auth not granted, attempt to request it
    if (!isSystemAuthGranted.value) {
      debugPrint("SocialBlockerBlock: Shield toggle requested but auth missing. Requesting...");
      await requestAuth();
    }

    // If still not granted (user denied), we cannot proceed
    if (!isSystemAuthGranted.value) {
      debugPrint("SocialBlockerBlock: Cannot toggle shield without system authorization.");
      return;
    }

    try {
      final selections = <String>[];
      if (appSelectionJson.value != null) {
        selections.add(appSelectionJson.value!);
      }

      await _channel.invokeMethod('toggleShield', {
        'active': active,
        'selections': selections,
      });
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error toggling shield: $e");
    }
    */
  }
}
