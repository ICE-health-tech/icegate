import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/AchievementStoryImage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/achievement_story_utils.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/widgets/DomainAnalysisChart.dart';
import 'package:intl/intl.dart';

/// Full-screen offline story viewer (tap sides to navigate).
class AchievementStoryViewer extends StatefulWidget {
  final List<AchievementData> stories;
  final int initialIndex;

  const AchievementStoryViewer({
    super.key,
    required this.stories,
    this.initialIndex = 0,
  });

  @override
  State<AchievementStoryViewer> createState() => _AchievementStoryViewerState();
}

class _AchievementStoryViewerState extends State<AchievementStoryViewer> {
  late PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.stories.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = _index + delta;
    if (next < 0) {
      Navigator.maybePop(context);
      return;
    }
    if (next >= widget.stories.length) {
      Navigator.maybePop(context);
      return;
    }
    HapticFeedback.selectionClick();
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: widget.stories.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) {
              final story = widget.stories[i];
              final ring = achievementDomainRingColor(story.domain);
              return Stack(
                fit: StackFit.expand,
                children: [
                  AchievementStoryImage(
                    relativePath: story.localImagePath,
                    fit: BoxFit.contain,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0, 0.4, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: padding.bottom + 28,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: ring.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ring.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Text(
                            (kAchievementDomainLabels[story.domain.toLowerCase()] ??
                                    story.domain)
                                .toUpperCase(),
                            style: TextStyle(
                              color: ring,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          story.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if (story.description != null &&
                            story.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            story.description!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 15,
                              height: 1.35,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Text(
                          DateFormat.yMMMd().format(story.createdAt.toLocal()),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: List.generate(widget.stories.length, (i) {
                            final active = i == _index;
                            return Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 3,
                                margin: EdgeInsets.only(
                                  right: i < widget.stories.length - 1 ? 4 : 0,
                                ),
                                decoration: BoxDecoration(
                                  color: active
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.12),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _go(-1),
                  ),
                ),
                const Expanded(flex: 2, child: SizedBox.shrink()),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => _go(1),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
