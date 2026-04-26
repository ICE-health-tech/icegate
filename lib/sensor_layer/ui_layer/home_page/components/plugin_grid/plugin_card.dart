import 'package:flutter/material.dart';

class PluginCard extends StatelessWidget {
  final String label;
  final String? imageUrl;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isEditMode;
  final VoidCallback? onDelete;

  const PluginCard({
    super.key,
    required this.label,
    this.imageUrl,
    required this.onTap,
    this.onLongPress,
    this.isEditMode = false,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedScale(
      scale: isEditMode ? 0.95 : 1.0,
      duration: const Duration(milliseconds: 200),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
              side: BorderSide(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 1,
              ),
            ),
            color: colorScheme.surfaceContainerLow,
            child: InkWell(
              onTap: isEditMode ? null : onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Center(
                        child: _buildImage(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      flex: 1,
                      child: Text(
                        label,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isEditMode && onDelete != null)
            Positioned(
              top: -4,
              right: -4,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colorScheme.error,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.startsWith('assets/')) {
      return Image.asset(
        imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.extension_rounded, size: 28),
      );
    } else if (imageUrl != null && imageUrl!.startsWith('http')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.public_rounded, size: 28),
        ),
      );
    }
    return const Icon(Icons.extension_rounded, size: 28);
  }
}
