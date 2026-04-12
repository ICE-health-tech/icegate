import 'package:freezed_annotation/freezed_annotation.dart';

part 'BluetoothDeviceInfo.freezed.dart';
part 'BluetoothDeviceInfo.g.dart';

/// Bluetooth device information model
@freezed
class BluetoothDeviceInfo with _$BluetoothDeviceInfo {
  const factory BluetoothDeviceInfo({
    required String id,
    required String name,
    @Default(false) bool isConnected,
    @Default(0) int rssi, // Signal strength
    @Default('Unknown') String deviceType,
  }) = _BluetoothDeviceInfo;

  factory BluetoothDeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$BluetoothDeviceInfoFromJson(json);
}

/// Extension methods for BluetoothDeviceInfo
extension BluetoothDeviceInfoExtension on BluetoothDeviceInfo {
  /// Get signal strength description
  String get signalStrength {
    if (rssi >= -50) return 'Excellent';
    if (rssi >= -60) return 'Good';
    if (rssi >= -70) return 'Fair';
    if (rssi >= -80) return 'Weak';
    return 'Very Weak';
  }

  /// Get signal strength percentage (0-100)
  int get signalPercentage {
    // RSSI typically ranges from -100 (worst) to -50 (best)
    final normalized = ((rssi + 100) / 50 * 100).clamp(0, 100);
    return normalized.round();
  }
}
