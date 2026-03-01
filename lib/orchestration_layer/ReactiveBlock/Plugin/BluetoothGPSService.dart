import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:signals/signals.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/GpsLocation.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/BluetoothDeviceInfo.dart';

/// Service for managing Bluetooth GPS device connection and location data
class BluetoothGPSService {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _connectedDevice;

  final availableDevices = listSignal<BluetoothDeviceInfo>([]);
  final connectedDevice = signal<BluetoothDeviceInfo?>(null);
  final currentLocation = signal<GpsLocation?>(null);
  final locationHistory = listSignal<GpsLocation>([]);
  final isScanning = signal<bool>(false);
  final isConnecting = signal<bool>(false);
  final errorMessage = signal<String?>(null);
  final hasBluetoothPermission = signal<bool>(false);
  final hasLocationPermission = signal<bool>(false);

  /// Check and request necessary permissions
  Future<bool> checkPermissions() async {
    try {
      // Check Bluetooth permissions
      final bluetoothStatus = await Permission.bluetoothScan.status;
      final bluetoothConnectStatus = await Permission.bluetoothConnect.status;

      if (!bluetoothStatus.isGranted || !bluetoothConnectStatus.isGranted) {
        final results = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ].request();

        hasBluetoothPermission.value = results.values.every(
          (status) => status.isGranted,
        );
      } else {
        hasBluetoothPermission.value = true;
      }

      // Check location permissions
      final locationStatus = await Permission.locationWhenInUse.status;
      if (!locationStatus.isGranted) {
        final result = await Permission.locationWhenInUse.request();
        hasLocationPermission.value = result.isGranted;
      } else {
        hasLocationPermission.value = true;
      }

      return hasBluetoothPermission.value && hasLocationPermission.value;
    } catch (e) {
      errorMessage.value = 'Permission error: $e';
      return false;
    }
  }

  /// Start scanning for Bluetooth devices
  Future<void> startScan() async {
    try {
      errorMessage.value = null;

      // Check if Bluetooth is available
      if (!await FlutterBluePlus.isAvailable) {
        errorMessage.value = 'Bluetooth is not available on this device';
        return;
      }

      // Check if Bluetooth is turned on
      if (await FlutterBluePlus.adapterState.first !=
          BluetoothAdapterState.on) {
        errorMessage.value = 'Please turn on Bluetooth';
        return;
      }

      isScanning.value = true;
      availableDevices.clear();

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (ScanResult result in results) {
          final deviceInfo = BluetoothDeviceInfo(
            id: result.device.remoteId.toString(),
            name: result.device.platformName.isNotEmpty
                ? result.device.platformName
                : 'Unknown Device',
            isConnected: false,
            rssi: result.rssi,
            deviceType: 'GPS Receiver',
          );

          // Update or add device
          final index = availableDevices.indexWhere(
            (d) => d.id == deviceInfo.id,
          );
          if (index >= 0) {
            availableDevices[index] = deviceInfo;
          } else {
            availableDevices.add(deviceInfo);
          }
        }
      });

      // Auto-stop scanning after timeout
      Future.delayed(const Duration(seconds: 15), () {
        if (isScanning.value) {
          stopScan();
        }
      });
    } catch (e) {
      errorMessage.value = 'Scan error: $e';
      isScanning.value = false;
    }
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await _scanSubscription?.cancel();
      _scanSubscription = null;
      isScanning.value = false;
    } catch (e) {
      errorMessage.value = 'Error stopping scan: $e';
    }
  }

  /// Connect to a Bluetooth device
  Future<void> connectToDevice(String deviceId) async {
    try {
      errorMessage.value = null;
      isConnecting.value = true;

      // Find the device
      final device = availableDevices.firstWhere((d) => d.id == deviceId);
      final bluetoothDevice = BluetoothDevice.fromId(deviceId);

      // Connect to device
      await bluetoothDevice.connect(timeout: const Duration(seconds: 15));
      _connectedDevice = bluetoothDevice;

      // Update connection status
      connectedDevice.value = device.copyWith(isConnected: true);

      // Listen to connection state
      _connectionSubscription = bluetoothDevice.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDisconnection();
        }
      });

      // Start receiving GPS data (simulated for now)
      _startGPSDataStream();

      isConnecting.value = false;
    } catch (e) {
      errorMessage.value = 'Connection error: $e';
      isConnecting.value = false;
      connectedDevice.value = null;
    }
  }

  /// Disconnect from current device
  Future<void> disconnect() async {
    try {
      await _connectedDevice?.disconnect();
      await _connectionSubscription?.cancel();
      _connectionSubscription = null;
      _connectedDevice = null;
      connectedDevice.value = null;
      currentLocation.value = null;
    } catch (e) {
      errorMessage.value = 'Disconnect error: $e';
    }
  }

  /// Handle disconnection
  void _handleDisconnection() {
    connectedDevice.value = null;
    currentLocation.value = null;
    errorMessage.value = 'Device disconnected';
  }

  /// Start receiving GPS data stream
  /// In a real implementation, this would parse NMEA sentences from the Bluetooth device
  /// For now, we'll use the phone's GPS as a demonstration
  void _startGPSDataStream() {
    // Use phone's GPS for demonstration
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(
      (Position position) {
        final location = GpsLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          speed: position.speed,
          heading: position.heading,
          accuracy: position.accuracy,
          speedAccuracy: position.speedAccuracy,
          headingAccuracy: position.headingAccuracy,
          timestamp: position.timestamp,
        );

        _updateLocation(location);
      },
      onError: (error) {
        Future.microtask(() {
          errorMessage.value = 'GPS error: $error';
        });
      },
    );
  }

  /// Update current location and add to history
  void _updateLocation(GpsLocation location) {
    // Run in microtask and batch to avoid SignalEffectException if stream
    // fires synchronously during an active effect/computed context.
    Future.microtask(() {
      batch(() {
        currentLocation.value = location;

        // Add to history (keep last 100 locations)
        locationHistory.insert(0, location);
        if (locationHistory.length > 100) {
          locationHistory.removeLast();
        }
      });
    });
  }

  /// Parse NMEA sentence (for future use with real Bluetooth GPS)
  /// NMEA format example: $GPGGA,123519,4807.038,N,01131.000,E,1,08,0.9,545.4,M,46.9,M,,*47

  /// Clean up resources
  void dispose() {
    _scanSubscription?.cancel();
    _connectionSubscription?.cancel();
    _connectedDevice?.disconnect();
  }
}
