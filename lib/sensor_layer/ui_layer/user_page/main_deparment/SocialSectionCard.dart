import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';

class SocialSectionCard extends StatelessWidget {
  final SocialMetrics metrics;
  final VoidCallback onTap;

  const SocialSectionCard({
    super.key,
    required this.metrics,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon and Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people,
                      color: Colors.purple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 8),

                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Metrics
              _buildMetric(Icons.group, '${metrics.friendsCount}', 'friends'),
              const SizedBox(height: 8),
              _buildMetric(
                Icons.message,
                '${metrics.unreadMessages}',
                'messages',
              ),
              const SizedBox(height: 8),
              _buildMetric(Icons.event, '${metrics.upcomingEvents}', 'events'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetric(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.purple),
        const SizedBox(width: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
