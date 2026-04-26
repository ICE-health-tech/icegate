import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:intl/intl.dart';
import 'AchievementBuilderDialog.dart';

class AchievementTimeline extends StatefulWidget {
  final List<AchievementData> achievements;

  const AchievementTimeline({super.key, required this.achievements});

  @override
  State<AchievementTimeline> createState() => _AchievementTimelineState();
}

class _AchievementTimelineState extends State<AchievementTimeline> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<List<AchievementData>> _chunkAchievements(List<AchievementData> list, int size) {
    List<List<AchievementData>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.achievements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 48, color: Theme.of(context).colorScheme.outline),
              const SizedBox(height: 16),
              Text("No Feats yet.",
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      );
    }

    final chunks = _chunkAchievements(widget.achievements, 2);

    return Column(
      children: [
        SizedBox(
          height: 480, // Estimated height for 2 cards + spacing
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Disable swipe gesture
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: chunks.length,
                itemBuilder: (context, pageIndex) {
                  final pageItems = chunks[pageIndex];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: pageItems.map((a) => _buildAchievementCard(context, a)).toList(),
                    ),
                  );
                },
              ),
              if (_currentPage > 0)
                Positioned(
                  left: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavArrow(
                      icon: Icons.chevron_left_rounded,
                      onTap: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
              if (_currentPage < chunks.length - 1)
                Positioned(
                  right: 4,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _buildNavArrow(
                      icon: Icons.chevron_right_rounded,
                      onTap: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (chunks.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              chunks.length,
              (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ],
    );
  }

  Widget _buildAchievementCard(BuildContext context, AchievementData a) {
    final dateStr = DateFormat('MMM d, yyyy').format(a.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => AchievementBuilderDialog.show(context, initialData: a),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      a.domain.toUpperCase(),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer),
                    ),
                  ),
                  Text(dateStr,
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 12),
              Text(a.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (a.description != null && a.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  a.description!,
                  style: TextStyle(
                      fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.psychology,
                      size: 16, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(width: 4),
                  Text("Meaning: ${a.meaningScore}/10",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  Icon(Icons.public,
                      size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 4),
                  Text("Impact: ${a.impactScore}/10",
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
              if (a.impactDescWho.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Helped: ${a.impactDescWho}",
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavArrow({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                ),
              ),
              child: Icon(
                icon,
                color: colorScheme.primary.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
