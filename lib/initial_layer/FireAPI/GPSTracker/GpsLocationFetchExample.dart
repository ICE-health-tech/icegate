import 'package:dio/dio.dart';
import 'package:ice_shield/initial_layer/FireAPI/GPSTracker/GpsLocationFetch.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';

/// Example usage of the GPS Location API
///
/// This file demonstrates how to use the GpsLocationApi service
/// to fetch and manage GPS location data.
void main() async {
  // Example 1: Basic setup with API client
  await example1BasicSetup();

  // Example 2: Fetch current location
  await example2FetchCurrentLocation();

  // Example 3: Fetch location history
  await example3FetchLocationHistory();

  // Example 4: Upload new location
  await example4UploadLocation();

  // Example 5: Search nearby locations
  await example5SearchNearbyLocations();

  // Example 6: With authentication
  await example6WithAuthentication();
}

/// Example 1: Basic setup with API client
Future<void> example1BasicSetup() async {
  print('\n=== Example 1: Basic Setup ===');

  // Create API client with base URL
  final apiClient = GpsLocationApiClient(
    baseUrl: 'https://api.example.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
  );

  // API client ready to use
  apiClient.api;

  // print('API client created successfully');
  // print('Base URL: https://api.example.com');
}

/// Example 2: Fetch current location
Future<void> example2FetchCurrentLocation() async {
  // print('\n=== Example 2: Fetch Current Location ===');

  try {
    final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

    // Fetch current location
    await apiClient.api.getCurrentLocation();

    
  } on DioException catch (e) {
    print('Error fetching location: ${e.message}');
    if (e.response != null) {
      print('Status code: ${e.response?.statusCode}');
    
    }
  }
}

/// Example 3: Fetch location history
Future<void> example3FetchLocationHistory() async {
  print('\n=== Example 3: Fetch Location History ===');

  try {
    final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

    // Fetch last 10 locations
    final history = await apiClient.api.getLocationHistory(
      limit: 10,
      offset: 0,
    );

    print('Location History (${history.length} records):');
    for (var i = 0; i < history.length; i++) {
      final loc = history[i];
      print(
        '  ${i + 1}. ${loc.formattedLatitude}, ${loc.formattedLongitude} at ${loc.timestamp}',
      );
    }

    // Fetch locations with date filter
    final startDate = DateTime.now().subtract(const Duration(days: 7));
    final endDate = DateTime.now();

    final recentHistory = await apiClient.api.getLocationHistory(
      limit: 20,
      startDate: startDate.toIso8601String(),
      endDate: endDate.toIso8601String(),
    );

    print('\nRecent History (last 7 days): ${recentHistory.length} records');
  } on DioException catch (e) {
    print('Error fetching history: ${e.message}');
  }
}

/// Example 4: Upload new location
Future<void> example4UploadLocation() async {
  print('\n=== Example 4: Upload New Location ===');

  try {
    final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

    // Create a new location
    final newLocation = GpsLocation(
      latitude: 37.7749,
      longitude: -122.4194,
      timestamp: DateTime.now(),
      altitude: 15.5,
      speed: 5.2,
      heading: 180.0,
      accuracy: 10.0,
    );

    print('Uploading location:');
    print(
      '  ${newLocation.formattedLatitude}, ${newLocation.formattedLongitude}',
    );

    // Upload to server
    final uploadedLocation = await apiClient.api.uploadLocation(newLocation);

    print('Location uploaded successfully!');
    print('  Server timestamp: ${uploadedLocation.timestamp}');
  } on DioException catch (e) {
    print('Error uploading location: ${e.message}');
  }
}

/// Example 5: Search nearby locations
Future<void> example5SearchNearbyLocations() async {
  print('\n=== Example 5: Search Nearby Locations ===');

  try {
    final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

    // Search for locations within 1km radius
    final nearbyLocations = await apiClient.api.getNearbyLocations(
      latitude: 37.7749,
      longitude: -122.4194,
      radius: 1000, // 1km in meters
    );

    print('Nearby Locations (within 1km):');
    for (var loc in nearbyLocations) {
      print('  - ${loc.formattedLatitude}, ${loc.formattedLongitude}');
    }
  } on DioException catch (e) {
    print('Error searching nearby: ${e.message}');
  }
}

/// Example 6: With authentication
Future<void> example6WithAuthentication() async {
  print('\n=== Example 6: With Authentication ===');

  try {
    final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

    // Set authentication token
    apiClient.setAuthToken('your-jwt-token-here');

    print('Authentication token set');

    // Now all requests will include the auth header
    final location = await apiClient.api.getCurrentLocation();

    print('Authenticated request successful');
    print(
      '  Location: ${location.formattedLatitude}, ${location.formattedLongitude}',
    );

    // Clear token when done
    apiClient.clearAuthToken();
    print('Authentication token cleared');
  } on DioException catch (e) {
    print('Error with authenticated request: ${e.message}');
  }
}

/// Example 7: Custom error handling with interceptor
class ErrorHandlingInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
   

    if (err.response != null) {
      switch (err.response?.statusCode) {
        case 401:
          print('  Unauthorized - Please login');
          break;
        case 404:
          print('  Not Found - Resource does not exist');
          break;
        case 500:
          print('  Server Error - Please try again later');
          break;
      }
    }

    super.onError(err, handler);
  }
}

/// Example 8: Using custom interceptor
Future<void> example8CustomInterceptor() async {
  print('\n=== Example 8: Custom Error Handling ===');

  final apiClient = GpsLocationApiClient(baseUrl: 'https://api.example.com');

  // Add custom error handling interceptor
  apiClient.addInterceptor(ErrorHandlingInterceptor());

  try {
    await apiClient.api.getCurrentLocation();
  } on DioException {
    // Error will be handled by the interceptor
    print('Request failed');
  }
}
