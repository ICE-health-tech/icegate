import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';

part 'GpsLocationFetch.g.dart';

/// Retrofit API service for fetching GPS location data
///
/// This service provides methods to fetch GPS location data from a remote API.
/// It uses Dio for HTTP requests and Retrofit for type-safe API definitions.
///
/// Example usage:
/// ```dart
/// final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'));
/// final api = GpsLocationApi(dio);
///
/// // Fetch current location
/// final location = await api.getCurrentLocation();
///
/// // Fetch location history
/// final history = await api.getLocationHistory(limit: 10);
/// ```
@RestApi()
abstract class GpsLocationAPI {
  factory GpsLocationAPI(Dio dio, {String baseUrl}) = _GpsLocationAPI;

  /// Get current GPS location
  ///
  /// Returns the most recent GPS location data from the server.
  @GET('/gps/current')
  Future<GpsLocation> getCurrentLocation();

  /// Get GPS location by ID
  ///
  /// Fetches a specific GPS location record by its unique identifier.
  ///
  /// [id] - The unique identifier of the location record
  @GET('/gps/location/{id}')
  Future<GpsLocation> getLocationById(@Path('id') String id);

  /// Get GPS location history
  ///
  /// Retrieves a list of historical GPS location records.
  ///
  /// [limit] - Maximum number of records to return (default: 50)
  /// [offset] - Number of records to skip for pagination (default: 0)
  /// [startDate] - Filter locations after this date (ISO 8601 format)
  /// [endDate] - Filter locations before this date (ISO 8601 format)
  @GET('/gps/history')
  Future<List<GpsLocation>> getLocationHistory({
    @Query('limit') int limit = 50,
    @Query('offset') int offset = 0,
    @Query('start_date') String? startDate,
    @Query('end_date') String? endDate,
  });

  /// Upload new GPS location
  ///
  /// Sends a new GPS location record to the server.
  ///
  /// [location] - The GPS location data to upload
  @POST('/gps/location')
  Future<GpsLocation> uploadLocation(@Body() GpsLocation location);

  /// Update existing GPS location
  ///
  /// Updates an existing GPS location record.
  ///
  /// [id] - The unique identifier of the location to update
  /// [location] - The updated GPS location data
  @PUT('/gps/location/{id}')
  Future<GpsLocation> updateLocation(
    @Path('id') String id,
    @Body() GpsLocation location,
  );

  /// Delete GPS location
  ///
  /// Removes a GPS location record from the server.
  ///
  /// [id] - The unique identifier of the location to delete
  @DELETE('/gps/location/{id}')
  Future<void> deleteLocation(@Path('id') String id);

  /// Get locations within a radius
  ///
  /// Fetches all GPS locations within a specified radius from a center point.
  ///
  /// [latitude] - Center point latitude
  /// [longitude] - Center point longitude
  /// [radius] - Search radius in meters
  @GET('/gps/nearby')
  Future<List<GpsLocation>> getNearbyLocations({
    @Query('lat') required double latitude,
    @Query('lng') required double longitude,
    @Query('radius') required double radius,
  });

  /// Stream GPS locations (for real-time tracking)
  ///
  /// Note: This would typically use WebSocket or Server-Sent Events
  /// For demonstration, this returns a list of recent locations
  ///
  /// [deviceId] - The device identifier to track
  @GET('/gps/stream/{deviceId}')
  Future<List<GpsLocation>> streamLocations(@Path('deviceId') String deviceId);
}

/// Helper class to create and configure the GPS Location API client
class GpsLocationApiClient {
  late final Dio _dio;
  late final GpsLocationAPI _api;

  GpsLocationApiClient({
    required String baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Map<String, dynamic>? headers,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout ?? const Duration(seconds: 30),
        receiveTimeout: receiveTimeout ?? const Duration(seconds: 30),
        headers:
            headers ??
            {'Content-Type': 'application/json', 'Accept': 'application/json'},
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
        error: true,
        logPrint: (obj) => print('[GPS API] $obj'),
      ),
    );

    _api = GpsLocationAPI(_dio);
  }

  /// Get the API instance
  GpsLocationAPI get api => _api;

  /// Get the Dio instance for custom configuration
  Dio get dio => _dio;

  /// Add authentication token to all requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  /// Remove authentication token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }

  /// Add custom interceptor
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }
}
