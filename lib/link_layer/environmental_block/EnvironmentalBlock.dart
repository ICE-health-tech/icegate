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

    try {
      final position = await LocationService.getCurrentLocation();
      if (position != null) {
        final data = await EnvironmentalService.fetchEnvironmentalData(
          position.latitude, 
          position.longitude,
        );
        
        if (data != null) {
          currentData.value = data;
          lastUpdated.value = DateTime.now();
          debugPrint('EnvironmentalBlock: Successfully updated data for ${position.latitude}, ${position.longitude}');
        } else {
          error.value = 'Failed to fetch environmental data';
        }
      } else {
        error.value = 'Could not determine location';
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
