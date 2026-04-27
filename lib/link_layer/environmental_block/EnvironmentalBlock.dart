import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:signals/signals.dart';
import 'EnvironmentalService.dart';
import 'LocationService.dart';

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
      var position = await LocationService.getCurrentLocation();
      
      double lat = position?.latitude ?? 21.0285; // Fallback to Hanoi
      double lon = position?.longitude ?? 105.8542;
      
      if (position == null) {
        debugPrint('EnvironmentalBlock: Location null, using fallback (Hanoi)');
      }

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
