import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Widgets/ScoreBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/AuthBlock.dart';

class ActivityTrackerService with WidgetsBindingObserver {
  static final ActivityTrackerService _instance =
      ActivityTrackerService._internal();
  factory ActivityTrackerService() => _instance;
  ActivityTrackerService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Timer? _timer;
  ScoreBlock? _scoreBlock;
  AuthBlock? _authBlock;
  String? _currentPath;
  DateTime? _startTime;

  void init(ScoreBlock scoreBlock, AuthBlock authBlock) {
    _scoreBlock = scoreBlock;
    _authBlock = authBlock;
    _startTime = DateTime.now();
    _startTracking();
  }

  void updatePath(String path) {
    if (_currentPath == path) return;
    _processAccumulatedTime();
    _currentPath = path;
    _startTime = DateTime.now();
  }

  void _startTracking() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _processAccumulatedTime();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _processAccumulatedTime();
      _timer?.cancel();
    } else if (state == AppLifecycleState.resumed) {
      _startTime = DateTime.now();
      _startTracking();
    }
  }

  void _processAccumulatedTime() {
    if (_startTime == null || _scoreBlock == null || _authBlock == null) return;

    // We don't reward Guest users to encourage login
    if (_authBlock!.username.value == 'Guest') return;

    final now = DateTime.now();
    final diff = now.difference(_startTime!);

    // Logic: 1 point per minute of active engagement
    final minutes = diff.inSeconds / 60.0;

    if (minutes >= 0.1) {
      final sector = _getSectorFromPath(_currentPath);
      debugPrint(
        "🕒 [ActivityTracker] Sector: $sector | Minutes: $minutes in $_currentPath",
      );

      // Track detailed history for the new table
      _scoreBlock!.trackAppUsage(
        minutes,
        sector: sector,
        pagePath: _currentPath,
        startTime: _startTime,
        endTime: now,
      );

      _startTime = now;
    }
  }

  String _getSectorFromPath(String? path) {
    if (path == null) return 'social';
    final p = path.toLowerCase();
    if (p.contains('health')) return 'health';
    if (p.contains('finance')) return 'finance';
    if (p.contains('project') || p.contains('focus') || p.contains('task')) {
      return 'projects';
    }
    return 'social';
  }

  void dispose() {
    _processAccumulatedTime();
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
  }
}
