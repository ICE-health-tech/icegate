import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DomainData/Plugin/GPSTracker/PersonProfile.dart';
import 'package:go_router/go_router.dart';
import 'package:auto_size_text/auto_size_text.dart';

class ProfileHeader extends StatelessWidget {
  final PersonProfile profile;

  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          // Navigate to PersonalInformationPage
          context.push('/personal-info');
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundImage: profile.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                backgroundColor: colorScheme.primary,
                child: profile.avatarUrl == null
                    ? AutoSizeText(
                        profile.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimary,
                        ),
                        maxLines: 1,
                      )
                    : null,
              ),

              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      profile.name,
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      minFontSize: 14,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    AutoSizeText(
                      profile.email,
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      maxLines: 1,
                      minFontSize: 10,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AutoSizeText(
                        'Active',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        minFontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow indicator
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
