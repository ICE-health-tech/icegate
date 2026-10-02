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
import 'package:ice_gate/utils/app_log.dart';

class SocialBlockerBlock {
  static const _channel = MethodChannel('duylong.art/screentime');
  static const _storageKey = 'ice_gate_social_block_rules';
  static const _blacklistEnabledKey = 'ice_gate_blacklist_enabled';
  /// True after the user completed Screen Time setup (auth + app selection).
  static const _screentimeSetupCompleteKey = 'ice_gate_screentime_setup_complete';

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
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  /// Marker stored in [SocialBlockRule.appSelectionJson] on iOS; native tokens live in app-group UserDefaults.
  static String iosSelectionMarker(String ruleId) => jsonEncode({
    'iosSelection': true,
    'ruleId': ruleId,
    'updatedAt': DateTime.now().millisecondsSinceEpoch,
  });

  static bool ruleHasAppSelection(SocialBlockRule rule) {
    final json = rule.appSelectionJson;
    if (json == null || json.isEmpty) return false;
    if (json.contains('has_selection') ||
        json.contains('iosSelection') ||
        json.contains('macos_has_selection')) {
      return true;
    }
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      final apps = List<String>.from(map['applicationTokens'] ?? []);
      return apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool get hasAnyRuleWithAppSelection =>
      rules.value.any(ruleHasAppSelection);

  late final hasAnyRuleWithAppSelectionSignal = computed(
    () => rules.value.any(ruleHasAppSelection),
  );

  FocusBlock? _focusBlock;
  String? _personId;
  void Function()? _disposeEvaluation;
  dynamic _timerSubscription;
  String _lastShieldSignature = '';
  Future<void> _shieldApplyChain = Future.value();
  bool _alive = false;
  int _initGeneration = 0;
  bool _isInitialized = false;

  SocialBlockerBlock();

  Future<void> init(FocusBlock focusBlock) async {
    await initWithSync(focusBlock, '');
  }

  Future<void> initWithSync(FocusBlock focusBlock, String personId) async {
    final generation = ++_initGeneration;
    _disposeEvaluation?.call();
    _disposeEvaluation = null;
    _timerSubscription?.cancel();
    _timerSubscription = null;
    _lastShieldSignature = '';

    _alive = true;
    _focusBlock = focusBlock;
    _personId = personId.isEmpty ? null : personId;

    await _load();
    if (!_alive || generation != _initGeneration) return;

    await checkAuthStatus();
    if (!_alive || generation != _initGeneration) return;

    if (_personId != null) {
      await _pullSelectionFromCloud();
      if (!_alive || generation != _initGeneration) return;
    }

    _setupEvaluation();
    await _syncNativeShieldIfNeeded();
    _isInitialized = true;
  }

  bool get isInitialized => _isInitialized;

  Future<void> _syncNativeShieldIfNeeded() async {
    if (!_nativeScreenTimeEnabled) return;
    await _applyShieldFromActiveRules();
  }

  /// Call after app resume or opening App Blocker — reapplies ManagedSettings shield from saved rules.
  Future<void> reconcileShieldAfterLifecycle() async {
    if (!_nativeScreenTimeEnabled) return;
    await checkAuthStatus();
    _lastShieldSignature = '';
    await _applyShieldFromActiveRules();
  }

  bool _isRuleScheduleActive(SocialBlockRule rule, DateTime now) {
    if (!rule.isEnabled) return false;
    if (!rule.blockedDays.contains(now.weekday)) return false;
    if (rule.scheduleStart == null || rule.scheduleEnd == null) return false;

    final start = rule.scheduleStart!;
    final end = rule.scheduleEnd!;
    final currentTotalMinutes = now.hour * 60 + now.minute;
    final startTotalMinutes = start.hour * 60 + start.minute;
    final endTotalMinutes = end.hour * 60 + end.minute;

    if (startTotalMinutes <= endTotalMinutes) {
      return currentTotalMinutes >= startTotalMinutes &&
          currentTotalMinutes < endTotalMinutes;
    }
    return currentTotalMinutes >= startTotalMinutes ||
        currentTotalMinutes < endTotalMinutes;
  }

  /// Rules that should contribute apps to the shield right now.
  List<SocialBlockRule> _currentlyActiveRules({
    required DateTime now,
    required bool focusRunning,
    required bool blacklistEnabled,
  }) {
    if (!blacklistEnabled) return [];

    return rules.value.where((rule) {
      if (!rule.isEnabled) return false;
      final scheduleActive = _isRuleScheduleActive(rule, now);
      final focusActive = focusRunning && rule.blockDuringFocus;
      return scheduleActive || focusActive;
    }).toList();
  }

  Future<void> _applyShieldFromActiveRules() {
    _shieldApplyChain =
        _shieldApplyChain.then((_) => _applyShieldFromActiveRulesImpl());
    return _shieldApplyChain;
  }

  Future<void> _applyShieldFromActiveRulesImpl() async {
    if (!_nativeScreenTimeEnabled) return;

    final now = _currentTime.value;
    final focusRunning = _focusBlock?.isRunning.value ?? false;
    final blacklistEnabled = isAppBlacklistEnabled.value;
    final activeRules = _currentlyActiveRules(
      now: now,
      focusRunning: focusRunning,
      blacklistEnabled: blacklistEnabled,
    );
    final rulesWithApps =
        activeRules.where(ruleHasAppSelection).toList(growable: false);
    final shouldBlock = blacklistEnabled && rulesWithApps.isNotEmpty;

    untracked(() {
      isAnyBlockActive.value = shouldBlock;
    });

    if (!shouldBlock) {
      await _toggleSystemShield(active: false, ruleIds: [], selections: []);
      return;
    }

    final ruleIds = rulesWithApps.map((r) => r.id).toList();
    final selections = rulesWithApps
        .map((r) => r.appSelectionJson)
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toList();

    await _toggleSystemShield(
      active: true,
      ruleIds: ruleIds,
      selections: selections,
    );
  }

  void _setupEvaluation() {
    untracked(() => _currentTime.value = DateTime.now());

    // Hot reload / re-init safe: clear previous reactive effect + timer.
    _disposeEvaluation?.call();
    _disposeEvaluation = null;
    _timerSubscription?.cancel();

    // Evaluation Logic
    _disposeEvaluation = effect(() {
      if (!_alive) return;

      final focusRunning = _focusBlock?.isRunning.value ?? false;
      final blacklistEnabled = isAppBlacklistEnabled.value;
      final now = _currentTime.value;
      rules.value;

      final activeRules = _currentlyActiveRules(
        now: now,
        focusRunning: focusRunning,
        blacklistEnabled: blacklistEnabled,
      );
      final rulesWithApps =
          activeRules.where(ruleHasAppSelection).toList(growable: false);
      final shouldBeActive = rulesWithApps.isNotEmpty;

      final signature =
          '$blacklistEnabled|$shouldBeActive|${rulesWithApps.map((r) => '${r.id}:${r.appSelectionJson}').join(';')}';
      if (signature == _lastShieldSignature) return;
      _lastShieldSignature = signature;

      untracked(() {
        isAnyBlockActive.value = blacklistEnabled && shouldBeActive;
        unawaited(_applyShieldFromActiveRules());
      });
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
    _alive = false;
    _initGeneration++;
    _isInitialized = false;
    _disposeEvaluation?.call();
    _disposeEvaluation = null;
    _timerSubscription?.cancel();
    _timerSubscription = null;
    _lastShieldSignature = '';
    unawaited(
      _toggleSystemShield(active: false, ruleIds: [], selections: []),
    );
  }

  // --- Actions ---

  Future<void> addRule(SocialBlockRule rule) async {
    untracked(() {
      rules.value = [...rules.value, rule];
    });
    await _persist();
    _lastShieldSignature = '';
    await _applyShieldFromActiveRules();
  }

  Future<void> removeRule(String id) async {
    untracked(() {
      rules.value = rules.value.where((r) => r.id != id).toList();
    });
    await _persist();
    _lastShieldSignature = '';
    await _applyShieldFromActiveRules();
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
      _lastShieldSignature = '';
      await _applyShieldFromActiveRules();
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
      _lastShieldSignature = '';
      await _applyShieldFromActiveRules();
    }
  }

  Future<void> recordChallengeAttempt(String ruleId) async {
    final index = rules.value.indexWhere((r) => r.id == ruleId);
    if (index == -1) return;
    untracked(() {
      final newList = [...rules.value];
      newList[index] = newList[index].copyWith(
        totalChallenges: newList[index].totalChallenges + 1,
      );
      rules.value = newList;
    });
    await _persist();
  }

  Future<void> recordChallengeSuccess(String ruleId) async {
    final index = rules.value.indexWhere((r) => r.id == ruleId);
    if (index == -1) return;
    untracked(() {
      final newList = [...rules.value];
      newList[index] = newList[index].copyWith(
        challengesPassed: newList[index].challengesPassed + 1,
      );
      rules.value = newList;
    });
    await _persist();
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
    if (!_nativeScreenTimeEnabled) {
      isSystemAuthGranted.value = false;
      return;
    }
    try {
      final bool granted = await _channel.invokeMethod('checkAuthorization');
      isSystemAuthGranted.value = granted;
    } catch (e) {
      appLog('SocialBlockerBlock: Error checking auth: $e');
      isSystemAuthGranted.value = false;
    }
  }

  /// Requests Screen Time permission only when the user explicitly asks (UI).
  /// Does not open the app picker — call [openAppPicker] after success if needed.
  Future<bool> requestAuth() async {
    if (!_nativeScreenTimeEnabled) return false;
    try {
      final bool granted = await _channel.invokeMethod('requestAuthorization');
      isSystemAuthGranted.value = granted;
      if (granted) {
        await _markSetupCompleteIfReady();
      }
      return granted;
    } on PlatformException catch (e) {
      if (e.code == 'AUTH_DENIED') {
        appLog(
          'SocialBlockerBlock: Auth denied. User needs to enable in Settings.',
        );
      }
      appLog('SocialBlockerBlock: Error requesting auth: ${e.message}');
    } catch (e) {
      appLog('SocialBlockerBlock: Unexpected error requesting auth: $e');
    }
    return false;
  }

  Future<bool> isSetupComplete() async {
    if (!_nativeScreenTimeEnabled) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_screentimeSetupCompleteKey) ?? false;
  }

  Future<void> _markSetupCompleteIfReady() async {
    if (!isSystemAuthGranted.value || !hasAnyRuleWithAppSelection) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_screentimeSetupCompleteKey, true);
  }

  /// Refreshes blocked-app list from native storage (legacy global key only).
  Future<void> refreshAppSelection() async {
    if (!_nativeScreenTimeEnabled) return;
    try {
      final selection = await _channel.invokeMethod('getSelection');
      if (selection is! Map) return;

      final apps = List<String>.from(selection['appTokens'] ?? []);
      final cats = List<String>.from(selection['categoryTokens'] ?? []);
      if (apps.isEmpty && cats.isEmpty) return;

      final legacyJson = jsonEncode({
        'applicationTokens': apps,
        'categoryTokens': cats,
      });

      var updated = false;
      untracked(() {
        final migrated = rules.value
            .map(
              (r) =>
                  (r.appSelectionJson == null || r.appSelectionJson!.isEmpty)
                  ? r.copyWith(appSelectionJson: legacyJson)
                  : r,
            )
            .toList();
        if (migrated.toString() != rules.value.toString()) {
          rules.value = migrated;
          updated = true;
        }
      });
      if (updated) {
        _lastShieldSignature = '';
        await _persist();
        await _applyShieldFromActiveRules();
      }
    } catch (_) {}
  }

  bool get hasBlockedAppsSelected => hasAnyRuleWithAppSelectionSignal.value;
  Future<bool> ensureBlockedAppsSelected() async {
    if (!_nativeScreenTimeEnabled) return false;

    if (!isSystemAuthGranted.value) {
      final granted = await requestAuth();
      if (!granted) return false;
    }

    if (hasAnyRuleWithAppSelection) return true;

    if (rules.value.isEmpty) return false;

    final firstRule = rules.value.first;
    final json = await openAppPickerForRule(firstRule.id);
    return json != null && ruleHasAppSelection(
          firstRule.copyWith(appSelectionJson: json),
        );
  }

  /// Pick blocked apps for a specific rule (each rule owns its own list).
  /// Returns the saved selection JSON, or null if cancelled / failed.
  Future<String?> openAppPickerForRule(
    String ruleId, {
    String? initialSelection,
  }) async {
    if (!_nativeScreenTimeEnabled) return null;

    if (!isSystemAuthGranted.value) {
      final granted = await requestAuth();
      if (!granted) return null;
    }

    final index = rules.value.indexWhere((r) => r.id == ruleId);
    final existing = index == -1 ? null : rules.value[index];
    final initial = initialSelection ?? existing?.appSelectionJson;

    try {
      final dynamic result = await _channel.invokeMethod('showAppPicker', {
        'ruleId': ruleId,
        'initialSelection': initial,
      });

      if (result == null) return null;

      String? selectionJson;
      if (result is String) {
        selectionJson = result;
      } else if (result == true) {
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          final hasNative = await _nativeRuleHasSelection(ruleId);
          if (!hasNative) {
            appLog(
              'SocialBlockerBlock: Picker finished but no native selection for $ruleId',
            );
            return null;
          }
          selectionJson = iosSelectionMarker(ruleId);
        } else if (defaultTargetPlatform == TargetPlatform.macOS) {
          selectionJson = '{"macos_has_selection":true}';
        }
      }

      if (selectionJson == null) return null;

      if (index != -1 && existing != null) {
        untracked(() {
          final newList = [...rules.value];
          newList[index] = existing.copyWith(appSelectionJson: selectionJson);
          rules.value = newList;
        });
        await _persist();
        _lastShieldSignature = '';
        await _markSetupCompleteIfReady();
        await _applyShieldFromActiveRules();
      }

      return selectionJson;
    } catch (e) {
      appLog('SocialBlockerBlock: Error opening app picker for rule: $e');
      return null;
    }
  }

  @Deprecated('Use openAppPickerForRule')
  Future<void> openAppPicker() async {
    if (rules.value.isEmpty) return;
    await openAppPickerForRule(rules.value.first.id);
  }

  static bool draftRuleHasApps(String? appSelectionJson) =>
      ruleHasAppSelection(
        SocialBlockRule(
          id: 'draft',
          platform: SocialPlatform.custom,
          appSelectionJson: appSelectionJson,
        ),
      );

  // --- Cloud Sync ---

  Future<void> appSync(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null || token == "mock_guest_jwt_token") return;

    untracked(() => isSyncing.value = true);
    try {
      appLog("🌐 [SocialBlockerBlock] Syncing rules from cloud...");
      await _pullSelectionFromCloud();
      appLog("✅ [SocialBlockerBlock] Cloud sync completed.");
    } catch (e) {
      appLog("⚠️ [SocialBlockerBlock] Cloud sync failed: $e");
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

        if (_nativeScreenTimeEnabled &&
            appTokens.isNotEmpty &&
            rules.value.isNotEmpty) {
          final legacyJson = jsonEncode({
            'applicationTokens': appTokens,
            'categoryTokens': categoryTokens,
          });
          untracked(() {
            final first = rules.value.first;
            if (first.appSelectionJson == null ||
                first.appSelectionJson!.isEmpty) {
              final newList = [...rules.value];
              newList[0] = first.copyWith(appSelectionJson: legacyJson);
              rules.value = newList;
            }
          });
          await _persist();
          _lastShieldSignature = '';
        }
      }
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error pulling from cloud: $e");
    }
  }

  Future<void> _pushSelectionToCloud() async {
    if (!_nativeScreenTimeEnabled ||
        defaultTargetPlatform != TargetPlatform.macOS) {
      return;
    }
    if (_personId == null ||
        _personId!.isEmpty ||
        _personId == '00000000-0000-0000-0000-000000000000') {
      return;
    }

    try {
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
        appLog('SocialBlockerBlock: Pushed selection to cloud');
      }
    } catch (e) {
      appLog('SocialBlockerBlock: Error pushing to cloud: $e');
    }
  }

  /// Master switch: enables/disables rule evaluation only (no direct Family API call).
  Future<void> toggleBlacklist(bool enabled) async {
    untracked(() {
      isAppBlacklistEnabled.value = enabled;
    });
    await _persist();
    _lastShieldSignature = '';
    await _applyShieldFromActiveRules();
  }

  Future<void> disableAllRules() async {
    untracked(() {
      final newList = rules.value
          .map((r) => r.copyWith(isEnabled: false))
          .toList();
      rules.value = newList;
    });
    await _persist();
    _lastShieldSignature = '';
    await _applyShieldFromActiveRules();
  }

  // --- Persistence ---

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    isAppBlacklistEnabled.value = prefs.getBool(_blacklistEnabledKey) ?? false;

    final legacyGlobal = prefs.getString(_appSelectionKey);

    final rulesJson = prefs.getStringList(_storageKey);
    if (rulesJson != null) {
      var loaded = rulesJson
          .map((j) => SocialBlockRule.fromJson(jsonDecode(j)))
          .toList();

      if (legacyGlobal != null && legacyGlobal.isNotEmpty) {
        loaded = loaded
            .map(
              (r) => (r.appSelectionJson == null || r.appSelectionJson!.isEmpty)
                  ? r.copyWith(appSelectionJson: legacyGlobal)
                  : r,
            )
            .toList();
      }
      untracked(() => rules.value = loaded);
    }
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blacklistEnabledKey, isAppBlacklistEnabled.value);

    final rulesJson = rules.value.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_storageKey, rulesJson);
  }

  // --- Native Communication ---

  Future<bool> _nativeRuleHasSelection(String ruleId) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('hasRuleSelection', {
        'ruleId': ruleId,
      });
      return ok == true;
    } catch (e) {
      appLog('SocialBlockerBlock: hasRuleSelection failed: $e');
      return false;
    }
  }

  Future<void> _toggleSystemShield({
    required bool active,
    required List<String> ruleIds,
    required List<String> selections,
  }) async {
    if (!_nativeScreenTimeEnabled) return;

    if (!isSystemAuthGranted.value) {
      if (active) {
        appLog(
          'SocialBlockerBlock: Shield skipped — Screen Time not authorized. '
          'Open App Blocker to set up once.',
        );
      }
      return;
    }

    try {
      await _channel.invokeMethod('toggleShield', {
        'active': active,
        'ruleIds': ruleIds,
        'selections': selections,
      });
    } catch (e) {
      appLog('SocialBlockerBlock: Error toggling shield: $e');
    }
  }
}
