import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';
import 'package:ice_gate/initial_layer/FireAPI/GPSTracker/MapFetch.dart';

/// Compact OpenStreetMap widget for embedding in canvas widgets
///
/// This is a simplified version of OSMMapWidget optimized for small spaces
/// in the draggable widget canvas.
class CompactOSMMapWidget extends StatefulWidget {
  final GpsLocation? initialLocation;
  final double initialZoom;
  final bool showControls;

  const CompactOSMMapWidget({
    super.key,
    this.initialLocation,
    this.initialZoom = 13.0,
    this.showControls = false,
  });

  @override
  State<CompactOSMMapWidget> createState() => _CompactOSMMapWidgetState();
}

class _CompactOSMMapWidgetState extends State<CompactOSMMapWidget> {
  late MapController _mapController;

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
    if (widget.initialLocation == null) return [];

    return [
      Marker(
        point: LatLng(
          widget.initialLocation!.latitude,
          widget.initialLocation!.longitude,
        ),
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 30),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initialZoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              // Tile layer
              TileLayer(
                urlTemplate: OSMTileServer.standard,
                subdomains: OSMTileServer.subdomains,
                userAgentPackageName: 'com.example.ice_gate',
              ),

              // Marker
              MarkerLayer(markers: _markers),
            ],
          ),

          // Minimal controls overlay
          if (widget.showControls)
            Positioned(
              top: 8,
              right: 8,
              child: Column(
                children: [
                  _buildCompactZoomControls(),
                  if (widget.initialLocation != null) ...[
                    const SizedBox(height: 4),
                    _buildCompactCenterButton(),
                  ],
                ],
              ),
            ),

          // Location badge
          if (widget.initialLocation != null)
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: _buildLocationBadge(),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactZoomControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom + 1,
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.add, size: 16),
            ),
          ),
          Container(height: 1, color: Colors.grey[300]),
          InkWell(
            onTap: () {
              _mapController.move(
                _mapController.camera.center,
                _mapController.camera.zoom - 1,
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(4),
              child: Icon(Icons.remove, size: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactCenterButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _mapController.move(
            LatLng(
              widget.initialLocation!.latitude,
              widget.initialLocation!.longitude,
            ),
            widget.initialZoom,
          );
        },
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.my_location, size: 16),
        ),
      ),
    );
  }

  Widget _buildLocationBadge() {
    final loc = widget.initialLocation!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '${loc.formattedLatitude}, ${loc.formattedLongitude}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
