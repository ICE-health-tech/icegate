import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';
import 'package:ice_shield/initial_layer/FireAPI/GPSTracker/MapFetch.dart';

/// OpenStreetMap widget for displaying GPS locations
///
/// This widget provides a full-featured map interface using OpenStreetMap tiles
/// with support for markers, polylines, and interactive controls.
class OSMMapWidget extends StatefulWidget {
  final GpsLocation? initialLocation;
  final List<GpsLocation>? locationHistory;
  final double initialZoom;
  final bool showUserLocation;
  final bool showLocationHistory;
  final Function(LatLng)? onMapTap;
  final Function(GpsLocation)? onMarkerTap;

  const OSMMapWidget({
    super.key,
    this.initialLocation,
    this.locationHistory,
    this.initialZoom = 13.0,
    this.showUserLocation = true,
    this.showLocationHistory = true,
    this.onMapTap,
    this.onMarkerTap,
  });

  @override
  State<OSMMapWidget> createState() => _OSMMapWidgetState();
}

class _OSMMapWidgetState extends State<OSMMapWidget> {
  late MapController _mapController;
  String _selectedTileServer = OSMTileServer.standard;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  LatLng get _center {
    if (widget.initialLocation != null) {
      return LatLng(
        widget.initialLocation!.latitude,
        widget.initialLocation!.longitude,
      );
    }
    return const LatLng(37.7749, -122.4194); // Default: San Francisco
  }

  List<Marker> get _markers {
    final markers = <Marker>[];

    // Add current location marker
    if (widget.showUserLocation && widget.initialLocation != null) {
      markers.add(
        Marker(
          point: LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          ),
          width: 80,
          height: 80,
          child: GestureDetector(
            onTap: () => widget.onMarkerTap?.call(widget.initialLocation!),
            child: const Icon(Icons.location_on, color: Colors.red, size: 40),
          ),
        ),
      );
    }

    // Add location history markers
    if (widget.showLocationHistory && widget.locationHistory != null) {
      for (var i = 0; i < widget.locationHistory!.length; i++) {
        final loc = widget.locationHistory![i];
        markers.add(
          Marker(
            point: LatLng(loc.latitude, loc.longitude),
            width: 60,
            height: 60,
            child: GestureDetector(
              onTap: () => widget.onMarkerTap?.call(loc),
              child: Icon(
                Icons.circle,
                color: Colors.blue.withOpacity(0.6),
                size: 20,
              ),
            ),
          ),
        );
      }
    }

    return markers;
  }

  List<LatLng> get _polylinePoints {
    if (!widget.showLocationHistory || widget.locationHistory == null) {
      return [];
    }

    return widget.locationHistory!
        .map((loc) => LatLng(loc.latitude, loc.longitude))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _center,
            initialZoom: widget.initialZoom,
            onTap: (tapPosition, point) => widget.onMapTap?.call(point),
          ),
          children: [
            // Tile layer
            TileLayer(
              urlTemplate: _selectedTileServer,
              subdomains: OSMTileServer.subdomains,
              userAgentPackageName: 'com.example.ice_shield',
            ),

            // Polyline for location history
            if (_polylinePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _polylinePoints,
                    strokeWidth: 4.0,
                    color: Colors.blue,
                  ),
                ],
              ),

            // Markers
            MarkerLayer(markers: _markers),

            // Attribution
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(
                  OSMTileServer.attribution,
                  onTap: () {}, // Could open OSM website
                ),
              ],
            ),
          ],
        ),

        // Map controls
        Positioned(
          top: 16,
          right: 16,
          child: Column(
            children: [
              // Tile server selector
              _buildMapStyleButton(),
              const SizedBox(height: 8),

              // Zoom controls
              _buildZoomControls(),
              const SizedBox(height: 8),

              // Center on user location
              if (widget.initialLocation != null) _buildCenterButton(),
            ],
          ),
        ),

        // Location info overlay
        if (widget.initialLocation != null)
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildLocationInfoCard(),
          ),
      ],
    );
  }

  Widget _buildMapStyleButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.layers),
        onSelected: (value) {
          setState(() {
            _selectedTileServer = value;
          });
        },
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: OSMTileServer.standard,
            child: Text('Standard'),
          ),
          const PopupMenuItem(
            value: OSMTileServer.humanitarian,
            child: Text('Humanitarian'),
          ),
          const PopupMenuItem(
            value: OSMTileServer.topo,
            child: Text('Topographic'),
          ),
          const PopupMenuItem(
            value: OSMTileServer.cycle,
            child: Text('Cycling'),
          ),
          const PopupMenuItem(
            value: OSMTileServer.satellite,
            child: Text('Satellite'),
          ),
          const PopupMenuItem(
            value: OSMTileServer.dark,
            child: Text('Dark Mode'),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove),
            onPressed: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.my_location),
        onPressed: () {
          _mapController.move(
            LatLng(
              widget.initialLocation!.latitude,
              widget.initialLocation!.longitude,
            ),
            widget.initialZoom,
          );
        },
      ),
    );
  }

  Widget _buildLocationInfoCard() {
    final loc = widget.initialLocation!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${loc.formattedLatitude}, ${loc.formattedLongitude}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(Icons.speed, loc.formattedSpeed),
                _buildInfoItem(Icons.navigation, loc.cardinalDirection),
                _buildInfoItem(Icons.terrain, loc.formattedAltitude),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }
}
