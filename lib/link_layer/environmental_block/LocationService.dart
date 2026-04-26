import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  /// Get the current position of the device.
  static Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint('Location services are disabled.');
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint('Location permissions are denied');
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint('Location permissions are permanently denied, we cannot request permissions.');
      return null;
    } 

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      return null;
    }
  }
}
