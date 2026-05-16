import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'EnvironmentalService.dart';

class EnvironmentalBlock {
  // Signals for reactive state
  final currentData = signal<EnvironmentalData?>(null);
  final isLoading = signal<bool>(false);
  final error = signal<String?>(null);
  final lastUpdated = signal<DateTime?>(null);

  Timer? _refreshTimer;

  EnvironmentalBlock() {
    // Initial fetch
    refresh();
    
    // Auto-refresh every 30 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 30), (_) => refresh());
  }

  Future<void> refresh() async {
    if (isLoading.value) return;
    
    isLoading.value = true;
    error.value = null;
    debugPrint('EnvironmentalBlock: refresh() started');

    try {
      // Default coordinates (Hanoi) — device GPS not used.
      const double lat = 21.0285;
      const double lon = 105.8542;

      final data = await EnvironmentalService.fetchEnvironmentalData(lat, lon);
      
      if (data != null) {
        currentData.value = data;
        lastUpdated.value = DateTime.now();
        debugPrint('EnvironmentalBlock: Successfully updated data for $lat, $lon');
      } else {
        error.value = 'Failed to fetch environmental data';
      }
    } catch (e) {
      error.value = 'Error: $e';
      debugPrint('EnvironmentalBlock error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void dispose() {
    _refreshTimer?.cancel();
  }
}
