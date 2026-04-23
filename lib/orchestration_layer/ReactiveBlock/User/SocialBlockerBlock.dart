import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/Protocol/Social/SocialBlockProtocol.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FocusBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ChallengeBlock.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';

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
  final _currentTime = signal<DateTime>(DateTime.now());
  
  static const _appSelectionKey = 'ice_gate_social_app_selection';

  FocusBlock? _focusBlock;
  late final void Function() _disposeEvaluation;
  dynamic _timerSubscription;

  SocialBlockerBlock();

  Future<void> init(FocusBlock focusBlock) async {
    _focusBlock = focusBlock;
    await _load();
    await checkAuthStatus();

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
              return currentTotalMinutes >= startTotalMinutes && currentTotalMinutes < endTotalMinutes;
            } else {
              // Overnight schedule
              return currentTotalMinutes >= startTotalMinutes || currentTotalMinutes < endTotalMinutes;
            }
          }
          return false;
        });

        // 2. Check focus linkage
        final focusActive = focusRunning && currentRules.any((r) => r.isEnabled && r.blockDuringFocus);
        
        shouldBeActive = scheduleActive || focusActive;
      }
      
      // Update the active state signal and trigger native sync ONLY on state change
      if (shouldBeActive != isAnyBlockActive.value) {
        untracked(() {
          isAnyBlockActive.value = shouldBeActive;
          _toggleSystemShield(shouldBeActive);
        });
      }
    });

    _currentTime.value = DateTime.now();

    // Tick current time every 30 seconds to evaluate schedules precisely
    _timerSubscription = Stream.periodic(const Duration(seconds: 30)).listen((_) {
      _currentTime.value = DateTime.now();
    });
  }

  void dispose() {
    _disposeEvaluation();
    _timerSubscription?.cancel();
  }

  // --- Actions ---

  Future<void> addRule(SocialBlockRule rule) async {
    rules.value = [...rules.value, rule];
    await _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  Future<void> removeRule(String id) async {
    rules.value = rules.value.where((r) => r.id != id).toList();
    await _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  Future<void> updateRule(SocialBlockRule rule) async {
    final index = rules.value.indexWhere((r) => r.id == rule.id);
    if (index != -1) {
      final newList = [...rules.value];
      newList[index] = rule;
      rules.value = newList;
      await _persist();
      _toggleSystemShield(isAnyBlockActive.value);
    }
  }

  Future<void> toggleRule(String id, bool enabled) async {
    final index = rules.value.indexWhere((r) => r.id == id);
    if (index != -1) {
      final newList = [...rules.value];
      newList[index] = newList[index].copyWith(isEnabled: enabled);
      rules.value = newList;
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
    try {
      final bool granted = await _channel.invokeMethod('checkAuthorization');
      isSystemAuthGranted.value = granted;
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error checking auth: $e");
    }
  }

  Future<void> requestAuth() async {
    try {
      final bool granted = await _channel.invokeMethod('requestAuthorization');
      isSystemAuthGranted.value = granted;
    } on PlatformException catch (e) {
      if (e.code == 'AUTH_DENIED') {
        debugPrint("SocialBlockerBlock: Auth denied. User needs to enable in Settings.");
        // We can throw here to be caught by the UI or handle it with a signal
      }
      debugPrint("SocialBlockerBlock: Error requesting auth: ${e.message}");
    } catch (e) {
      debugPrint("SocialBlockerBlock: Unexpected error requesting auth: $e");
    }
  }

  Future<void> openAppPicker() async {
    try {
      final String? result = await _channel.invokeMethod('showAppPicker', {
        'initialSelection': appSelectionJson.value,
      });
      
      if (result != null) {
        debugPrint("SocialBlockerBlock: App selection updated");
        appSelectionJson.value = result;
        await _persist();
        
        _toggleSystemShield(isAnyBlockActive.value);
      }
    } catch (e) {
      debugPrint("SocialBlockerBlock: Error opening app picker: $e");
    }
  }

  void toggleBlacklist(bool enabled) {
    isAppBlacklistEnabled.value = enabled;
    _persist();
    _toggleSystemShield(isAnyBlockActive.value);
  }

  void disableAllRules() {
    final newList = rules.value.map((r) => r.copyWith(isEnabled: false)).toList();
    rules.value = newList;
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
    
    final rulesJson = rules.value
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    await prefs.setStringList(_storageKey, rulesJson);

    if (appSelectionJson.value != null) {
      await prefs.setString(_appSelectionKey, appSelectionJson.value!);
    } else {
      await prefs.remove(_appSelectionKey);
    }
  }

  // --- Native Communication ---

  Future<void> _toggleSystemShield(bool active) async {
    // If auth not granted, try to refresh first
    if (!isSystemAuthGranted.value) {
      await checkAuthStatus();
    }
    
    if (!isSystemAuthGranted.value) return;

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
  }
}
