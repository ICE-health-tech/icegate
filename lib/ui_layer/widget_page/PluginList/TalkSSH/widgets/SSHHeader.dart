import 'package:flutter/material.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

class SSHHeader extends StatelessWidget {
  final String serverName;
  final String ipAddress;
  final String uptime;
  final int bytesIn;
  final int bytesOut;
  final double latencyMs;
  final VoidCallback onDisconnect;
  final VoidCallback? onConnect;
  final bool isConnected;

  const SSHHeader({
    super.key,
    required this.serverName,
    required this.ipAddress,
    required this.uptime,
    this.bytesIn = 0,
    this.bytesOut = 0,
    this.latencyMs = 0,
    required this.onDisconnect,
    this.onConnect,
    this.isConnected = true,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatusIcon(colorScheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      serverName.toUpperCase(),
                      style: TextStyle(
                        color: isConnected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.4),
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                        fontFamily: 'Courier',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildStatusDot(isConnected),
                        const SizedBox(width: 8),
                        Text(
                          ipAddress,
                          style: TextStyle(
                            color: colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 10,
                            fontFamily: 'Courier',
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        _buildStatItem(Icons.access_time, uptime, colorScheme),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildActionButton(context, colorScheme, l10n),
            ],
          ),
          if (isConnected) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, thickness: 0.5, color: Colors.white10),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('RX', _formatBytes(bytesIn), colorScheme),
                _buildMetric('TX', _formatBytes(bytesOut), colorScheme),
                _buildMetric('LATENCY', '${latencyMs.toInt()}ms', colorScheme),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, ColorScheme colorScheme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: colorScheme.onSurface.withOpacity(0.3)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.5),
            fontSize: 10,
            fontFamily: 'Courier',
          ),
        ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.3),
            fontSize: 8,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: colorScheme.primary.withOpacity(0.8),
            fontSize: 12,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIcon(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isConnected 
          ? colorScheme.primary.withOpacity(0.1) 
          : colorScheme.onSurface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isConnected ? colorScheme.primary.withOpacity(0.3) : Colors.transparent
        ),
      ),
      child: Icon(
        isConnected ? Icons.terminal : Icons.terminal_outlined, 
        color: isConnected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3), 
        size: 20
      ),
    );
  }

  Widget _buildStatusDot(bool connected) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: connected ? const Color(0xFF00E676) : Colors.redAccent,
        shape: BoxShape.circle,
        boxShadow: [
          if (connected) BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.5),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, ColorScheme colorScheme, AppLocalizations l10n) {
    return TextButton(
      onPressed: isConnected ? onDisconnect : onConnect,
      style: TextButton.styleFrom(
        backgroundColor: isConnected ? Colors.redAccent.withOpacity(0.1) : colorScheme.primary.withOpacity(0.1),
        foregroundColor: isConnected ? Colors.redAccent : colorScheme.primary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isConnected ? Colors.redAccent.withOpacity(0.3) : colorScheme.primary.withOpacity(0.3)
          ),
        ),
      ),
      child: Text(
        isConnected ? l10n.ssh_disconnect.toUpperCase() : l10n.ssh_connect.toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1),
      ),
    );
  }
}
