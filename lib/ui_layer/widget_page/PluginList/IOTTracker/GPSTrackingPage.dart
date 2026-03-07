import 'package:flutter/material.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/Plugin/BluetoothGPSService.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/BluetoothDeviceList.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/LocationCard.dart';
import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/OSMMapWidget.dart';
import 'dart:ui';
// import 'package:ice_gate/ui_layer/widget_page/PluginList/IOTTracker/BluetoothDeviceList.dart';

/// Main GPS tracking page with Bluetooth device connection
class GPSTrackingPage extends StatefulWidget {
  const GPSTrackingPage({super.key});

  @override
  State<GPSTrackingPage> createState() => _GPSTrackingPageState();
}

class _GPSTrackingPageState extends State<GPSTrackingPage>
    with SingleTickerProviderStateMixin {
  late BluetoothGPSService _gpsService;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _gpsService = BluetoothGPSService();
    _tabController = TabController(length: 2, vsync: this);
    _initializeService();
  }

  Future<void> _initializeService() async {
    final hasPermissions = await _gpsService.checkPermissions();
    if (!hasPermissions && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bluetooth and Location permissions are required'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _gpsService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: AppBar(
              backgroundColor: colorScheme.surface.withOpacity(0.4),
              elevation: 0,
              centerTitle: true,
              title: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "LOCATION TRACKER",
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 4,
                    ),
                  ),
                ],
              ),
              actions: [
                Watch(
                  (context) => _gpsService.connectedDevice.value != null
                      ? IconButton(
                          icon: const Icon(Icons.bluetooth_connected),
                          onPressed: () => _showDisconnectDialog(),
                          tooltip: 'Disconnect',
                        )
                      : const SizedBox.shrink(),
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: Watch(
                  (context) =>
                      _gpsService.connectedDevice.value != null &&
                          _gpsService.currentLocation.value != null
                      ? TabBar(
                          controller: _tabController,
                          indicatorColor: colorScheme.primary,
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: colorScheme.onSurface
                              .withOpacity(0.5),
                          tabs: const [
                            Tab(icon: Icon(Icons.map), text: 'Map'),
                            Tab(icon: Icon(Icons.list), text: 'Data'),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: Theme.of(context).brightness == Brightness.dark
                  ? 0.15
                  : 0.08,
              child: Image.asset(
                'assets/tactical_bg.png',
                fit: BoxFit.cover,
                color: Theme.of(context).brightness == Brightness.dark
                    ? null
                    : colorScheme.primary.withOpacity(0.5),
                colorBlendMode: Theme.of(context).brightness == Brightness.dark
                    ? BlendMode.dst
                    : BlendMode.srcATop,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.primary.withOpacity(0.05),
                  colorScheme.surface,
                ],
              ),
            ),
            child: SafeArea(
              child: Watch((context) {
                // If connected and has location, show tab view
                if (_gpsService.connectedDevice.value != null &&
                    _gpsService.currentLocation.value != null) {
                  return TabBarView(
                    controller: _tabController,
                    children: [
                      // Map View
                      OSMMapWidget(
                        initialLocation: _gpsService.currentLocation.value,
                        locationHistory: _gpsService.locationHistory,
                        showUserLocation: true,
                        showLocationHistory: true,
                        onMarkerTap: (location) {
                          _showLocationDetails(location);
                        },
                      ),
                      // Data View
                      _buildDataView(),
                    ],
                  );
                }

                // Otherwise show connection/setup screen
                return RefreshIndicator(
                  onRefresh: () async {
                    if (_gpsService.connectedDevice.value == null) {
                      await _gpsService.startScan();
                    }
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Show device list if not connected
                        if (_gpsService.connectedDevice.value == null) ...[
                          Text(
                            'SYSTEM SCAN',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Connect to External Receiver',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 24),
                          BluetoothDeviceList(
                            devices: _gpsService.availableDevices,
                            isScanning: _gpsService.isScanning.value,
                            onDeviceSelected: (deviceId) async {
                              await _gpsService.connectToDevice(deviceId);
                              if (_gpsService.errorMessage.value != null &&
                                  mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _gpsService.errorMessage.value!,
                                    ),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            },
                            onScanPressed: () => _gpsService.startScan(),
                          ),
                        ],

                        if (_gpsService.connectedDevice.value != null) ...[
                          const SizedBox(height: 24),
                        ],

                        // Connection status
                        _buildConnectionStatus(),

                        // Show waiting for GPS if connected but no location yet
                        if (_gpsService.connectedDevice.value != null &&
                            _gpsService.currentLocation.value == null)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: _buildWaitingForGPS(),
                          ),

                        // Error message
                        if (_gpsService.errorMessage.value != null) ...[
                          const SizedBox(height: 24),
                          _buildErrorMessage(),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    final colorScheme = Theme.of(context).colorScheme;
    final isConnected = _gpsService.connectedDevice.value != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isConnected
              ? [Colors.green.withOpacity(0.1), Colors.green.withOpacity(0.05)]
              : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isConnected
              ? Colors.green.withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isConnected
                  ? Colors.green.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isConnected ? Icons.check_circle : Icons.bluetooth_disabled,
              color: isConnected ? Colors.green : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isConnected ? 'Connected' : 'Not Connected',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isConnected ? Colors.green : Colors.grey,
                  ),
                ),
                if (isConnected) ...[
                  const SizedBox(height: 4),
                  Text(
                    _gpsService.connectedDevice.value!.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_gpsService.isConnecting.value)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }

  Widget _buildDataView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLocationData(_gpsService.currentLocation.value!),

          // Location history
          if (_gpsService.locationHistory.isNotEmpty) ...[
            const SizedBox(height: 32),
            Text(
              'Location History',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLocationHistory(),
          ],
        ],
      ),
    );
  }

  void _showLocationDetails(GpsLocation location) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Latitude', location.formattedLatitude),
            _buildDetailRow('Longitude', location.formattedLongitude),
            _buildDetailRow('Altitude', location.formattedAltitude),
            _buildDetailRow('Speed', location.formattedSpeed),
            _buildDetailRow(
              'Heading',
              '${location.formattedHeading} ${location.cardinalDirection}',
            ),
            _buildDetailRow(
              'Accuracy',
              '${location.accuracy.toStringAsFixed(1)} m',
            ),
            _buildDetailRow(
              'Time',
              '${location.timestamp.hour}:${location.timestamp.minute.toString().padLeft(2, '0')}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildWaitingForGPS() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'Waiting for GPS signal...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Make sure you are in an open area with clear sky view',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationData(location) {
    return Column(
      children: [
        // Coordinates
        Row(
          children: [
            Expanded(
              child: LocationCard(
                icon: Icons.my_location,
                label: 'Latitude',
                value: location.formattedLatitude,
                color: Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LocationCard(
                icon: Icons.location_on,
                label: 'Longitude',
                value: location.formattedLongitude,
                color: Colors.purple,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Altitude and Speed
        Row(
          children: [
            Expanded(
              child: LocationCard(
                icon: Icons.terrain,
                label: 'Altitude',
                value: location.formattedAltitude,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LocationCard(
                icon: Icons.speed,
                label: 'Speed',
                value: location.formattedSpeed,
                color: Colors.orange,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Heading and Accuracy
        Row(
          children: [
            Expanded(
              child: LocationCard(
                icon: Icons.explore,
                label: 'Heading',
                value:
                    '${location.formattedHeading} ${location.cardinalDirection}',
                color: Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LocationCard(
                icon: Icons.gps_fixed,
                label: 'Accuracy',
                value: '${location.accuracy.toStringAsFixed(1)} m',
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationHistory() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.all(12),
        itemCount: _gpsService.locationHistory.length,
        separatorBuilder: (context, index) =>
            Divider(color: colorScheme.outline.withOpacity(0.1)),
        itemBuilder: (context, index) {
          final location = _gpsService.locationHistory[index];
          return ListTile(
            dense: true,
            leading: Icon(
              Icons.location_on,
              color: colorScheme.primary,
              size: 20,
            ),
            title: Text(
              '${location.latitude}, ${location.longitude}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            subtitle: Text(
              '${location.timestamp.hour}:${location.timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            trailing: Text(
              location.formattedSpeed,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _gpsService.errorMessage.value!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisconnectDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Disconnect Device'),
        content: const Text(
          'Are you sure you want to disconnect from the GPS device?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _gpsService.disconnect();
              Navigator.pop(context);
            },
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
