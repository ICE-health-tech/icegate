import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DomainData/Plugin/GPSTracker/BluetoothDeviceInfo.dart';

/// Widget for displaying a list of Bluetooth devices
class BluetoothDeviceList extends StatelessWidget {
  final List<BluetoothDeviceInfo> devices;
  final bool isScanning;
  final Function(String deviceId) onDeviceSelected;
  final VoidCallback onScanPressed;

  const BluetoothDeviceList({
    super.key,
    required this.devices,
    required this.isScanning,
    required this.onDeviceSelected,
    required this.onScanPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Scan button
        ElevatedButton.icon(
          onPressed: isScanning ? null : onScanPressed,
          icon: isScanning
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.bluetooth_searching),
          label: Text(isScanning ? 'Scanning...' : 'Scan for Devices'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            foregroundColor: colorScheme.primary,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Device list
        if (devices.isEmpty && !isScanning)
          _buildEmptyState(context)
        else if (devices.isEmpty && isScanning)
          _buildScanningState(context)
        else
          _buildDeviceList(context),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.bluetooth_disabled,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No devices found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Scan for Devices" to search for Bluetooth GPS receivers',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningState(BuildContext context) {
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
            'Searching for devices...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: devices.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final device = devices[index];
        return _buildDeviceCard(context, device);
      },
    );
  }

  Widget _buildDeviceCard(BuildContext context, BluetoothDeviceInfo device) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: InkWell(
        onTap: () => onDeviceSelected(device.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Bluetooth icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.bluetooth,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),

              const SizedBox(width: 16),

              // Device info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      device.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      device.signalStrength,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Signal strength indicator
              Column(
                children: [
                  Icon(
                    _getSignalIcon(device.rssi),
                    color: _getSignalColor(device.rssi, colorScheme),
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${device.rssi} dBm',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getSignalIcon(int rssi) {
    if (rssi >= -50) return Icons.signal_cellular_alt;
    if (rssi >= -60) return Icons.signal_cellular_alt_2_bar;
    if (rssi >= -70) return Icons.signal_cellular_alt_1_bar;
    return Icons.signal_cellular_0_bar;
  }

  Color _getSignalColor(int rssi, ColorScheme colorScheme) {
    if (rssi >= -50) return Colors.green;
    if (rssi >= -60) return Colors.lightGreen;
    if (rssi >= -70) return Colors.orange;
    return Colors.red;
  }
}
