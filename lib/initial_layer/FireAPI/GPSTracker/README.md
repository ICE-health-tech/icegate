# GPS Tracking with OpenStreetMap Integration

## Overview

Successfully implemented comprehensive GPS tracking features with OpenStreetMap integration using Retrofit, Dio, and flutter_map.

---

## What Was Implemented

### 1. GPS Location API (Retrofit + Dio)

**File:** [`GpsLocationFetch.dart`](file:///Users/duylong/Code/Flutter/ice_gate/lib/data_layer/FireAPI/GPSTracker/GpsLocationFetch.dart)

Retrofit-based API service for GPS location data with full CRUD operations:

- ✅ Get current location
- ✅ Get location by ID
- ✅ Get location history with pagination and date filtering
- ✅ Upload new location
- ✅ Update existing location
- ✅ Delete location
- ✅ Search nearby locations (radius-based)
- ✅ Stream locations for real-time tracking

**Helper Client:**
- Auto-configured Dio instance
- Request/response logging
- Authentication token management
- Custom interceptor support

---

### 2. OpenStreetMap API (Nominatim Geocoding)

**File:** [`MapFetch.dart`](file:///Users/duylong/Code/Flutter/ice_gate/lib/data_layer/FireAPI/GPSTracker/MapFetch.dart)

Retrofit service for OpenStreetMap Nominatim API:

- ✅ **Forward Geocoding**: Search locations by name/address
- ✅ **Reverse Geocoding**: Get address from coordinates
- ✅ **Place Details**: Fetch OSM place information

**Tile Server Configurations:**
- Standard OpenStreetMap
- Humanitarian style
- Topographic (OpenTopoMap)
- Cycling-focused (CyclOSM)
- Transport map
- Satellite imagery
- Dark mode

---

### 3. Interactive Map Widget

**File:** [`OSMMapWidget.dart`](file:///Users/duylong/Code/Flutter/ice_gate/lib/ui_layer/widget_page/PluginList/IOTTracker/OSMMapWidget.dart)

Full-featured Flutter map widget with:

**Map Features:**
- Multiple tile server styles (switchable)
- Current location marker
- Location history markers
- Polyline path visualization
- Interactive tap handling
- Zoom controls (+/-)
- Center on user location button

**UI Components:**
- Map style selector (popup menu)
- Zoom in/out buttons
- Location info card overlay
- Attribution widget

**Data Display:**
- Coordinates (formatted)
- Speed (km/h)
- Heading (cardinal direction)
- Altitude (meters)

---

## Dependencies Added

```yaml
# OpenStreetMap
flutter_map: ^7.0.2      # Map rendering
latlong2: ^0.9.0         # Coordinate handling

# Updated for compatibility
http: ^1.2.1             # HTTP client
pocketbase: ^0.23.0+1    # Backend SDK
```

---

## Usage Examples

### Example 1: GPS Location API

```dart
// Create API client
final apiClient = GpsLocationApiClient(
  baseUrl: 'https://api.example.com',
);

// Fetch current location
final location = await apiClient.api.getCurrentLocation();
print('${location.formattedLatitude}, ${location.formattedLongitude}');

// Get location history
final history = await apiClient.api.getLocationHistory(
  limit: 10,
  startDate: DateTime.now().subtract(Duration(days: 7)).toIso8601String(),
);

// Upload new location
final newLoc = GpsLocation(
  latitude: 37.7749,
  longitude: -122.4194,
  timestamp: DateTime.now(),
);
await apiClient.api.uploadLocation(newLoc);
```

### Example 2: OpenStreetMap Geocoding

```dart
// Create OSM client
final osmClient = OpenStreetMapClient();

// Search for a location
final results = await osmClient.searchLocation('Eiffel Tower, Paris');
print(results.first.formattedAddress);

// Reverse geocode
final address = await osmClient.reverseGeocode(48.8584, 2.2945);
print('City: ${address.city}');
print('Country: ${address.country}');
```

### Example 3: Map Widget

```dart
OSMMapWidget(
  initialLocation: currentGpsLocation,
  locationHistory: historyList,
  initialZoom: 15.0,
  showUserLocation: true,
  showLocationHistory: true,
  onMapTap: (latLng) {
    print('Tapped: ${latLng.latitude}, ${latLng.longitude}');
  },
  onMarkerTap: (location) {
    print('Marker tapped: ${location.formattedLatitude}');
  },
)
```

---

## Key Features

### GPS Location Service
- RESTful API with type-safe Retrofit definitions
- Automatic JSON serialization/deserialization
- Pagination support for history
- Date range filtering
- Radius-based location search
- Authentication support

### OpenStreetMap Integration
- Multiple map styles (6+ options)
- Nominatim geocoding (forward & reverse)
- Place search and details
- OSM attribution compliance
- Customizable tile servers

### Map Widget
- Interactive markers and polylines
- Real-time location tracking
- Smooth zoom and pan
- Location info overlay
- Multiple map style switching
- Responsive design

---

## File Structure

```
lib/
├── data_layer/
│   ├── DomainData/Plugin/GPSTracker/
│   │   └── GpsLocation.dart              # GPS data model
│   └── FireAPI/GPSTracker/
│       ├── GpsLocationFetch.dart          # GPS API service
│       ├── GpsLocationFetch.g.dart        # Generated code
│       ├── GpsLocationFetchExample.dart   # Usage examples
│       ├── MapFetch.dart                  # OSM API service
│       └── MapFetch.g.dart                # Generated code
└── ui_layer/widget_page/PluginList/IOTTracker/
    └── OSMMapWidget.dart                  # Map widget
```

---

## Next Steps

To use in your GPS Tracking Page:

1. **Import the map widget:**
```dart
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/OSMMapWidget.dart';
```

2. **Add to your GPS tracking UI:**
```dart
OSMMapWidget(
  initialLocation: _currentLocation,
  locationHistory: _locationHistory,
  showUserLocation: true,
  showLocationHistory: true,
)
```

3. **Integrate with Bluetooth GPS:**
```dart
// In your GPS tracking page
StreamBuilder<GpsLocation>(
  stream: bluetoothGPSService.locationStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return OSMMapWidget(
        initialLocation: snapshot.data,
        // ...
      );
    }
    return CircularProgressIndicator();
  },
)
```

---

## Notes

- **Generated Files**: Run `flutter pub run build_runner build` to generate `.g.dart` files
- **API Keys**: Some tile servers (satellite, transport) may require API keys
- **Rate Limiting**: Nominatim has usage limits - consider caching results
- **Attribution**: OSM attribution is automatically displayed on the map
- **Offline Support**: Consider adding tile caching for offline use

---

## Summary

✅ **GPS Location API** - Full CRUD with Retrofit/Dio  
✅ **OpenStreetMap Integration** - Nominatim geocoding  
✅ **Interactive Map Widget** - 6+ map styles, markers, polylines  
✅ **Type-Safe** - Retrofit annotations with code generation  
✅ **Production-Ready** - Error handling, logging, authentication support
