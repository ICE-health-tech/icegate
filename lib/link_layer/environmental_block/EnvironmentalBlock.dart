import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signals/signals.dart';
import 'EnvironmentalService.dart';

class EnvironmentalBlock {
  static const _cacheKey = 'environmental_data_cache_v1';
  static const _cacheTimeKey = 'environmental_data_cache_time_v1';

  final currentData = signal<EnvironmentalData?>(null);
  final isLoading = signal<bool>(false);
  final error = signal<String?>(null);
  final lastUpdated = signal<DateTime?>(null);

  Timer? _refreshTimer;

  EnvironmentalBlock() {
    unawaited(_loadCached());
    unawaited(refresh());

    _refreshTimer = Timer.periodic(
      const Duration(minutes: 30),
      (_) => refresh(),
    );
  }

  Future<void> _loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      final timeRaw = prefs.getString(_cacheTimeKey);
      if (raw == null) return;

      final data = EnvironmentalData.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      currentData.value = data;
      if (timeRaw != null) {
        lastUpdated.value = DateTime.tryParse(timeRaw);
      }
      debugPrint('EnvironmentalBlock: restored cached env data');
    } catch (e) {
      debugPrint('EnvironmentalBlock: cache read failed: $e');
    }
  }

  Future<void> _persistCache(EnvironmentalData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(data.toJson()));
      await prefs.setString(_cacheTimeKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('EnvironmentalBlock: cache write failed: $e');
    }
  }

  Future<void> refresh() async {
    if (isLoading.value) return;

    final hadData = currentData.value != null;
    if (!hadData) {
      isLoading.value = true;
    }
    error.value = null;

    try {
      const double lat = 21.0285;
      const double lon = 105.8542;

      final data = await EnvironmentalService.fetchEnvironmentalData(lat, lon);

      if (data != null) {
        currentData.value = data;
        lastUpdated.value = DateTime.now();
        await _persistCache(data);
      } else if (!hadData) {
        error.value = 'Failed to fetch environmental data';
      }
    } catch (e) {
      if (!hadData) {
        error.value = 'Error: $e';
      }
      debugPrint('EnvironmentalBlock error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
  }
}
