import 'package:flutter/material.dart';
import 'package:ice_shield/ui_layer/ReusableWidget/DepartmentCard.dart';
import 'package:ice_shield/ui_layer/canvas_page/DragCanvasGridPage.dart';
import 'package:provider/provider.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';

// --- MOCK DATA MODEL ---
// --- DASHBOARD WIDGET ---

// --- DASHBOARD WIDGET ---
class UserInformationPage extends StatefulWidget {
  const UserInformationPage({super.key});

  @override
  State<UserInformationPage> createState() => _UserInformationPageState();
}

class _UserInformationPageState extends State<UserInformationPage> {
  // bool _isInteractingWithCard = false; // Unused

  void _setCardInteraction(bool isInteracting) {
    // setState(() {
    //   _isInteractingWithCard = isInteracting;
    // });
  }
  

  @override
  Widget build(BuildContext context) {
    // Watch PersonBlock
    final personBlock = context.watch<PersonBlock>();
    final info = personBlock.information.watch(context);
    final userProfile = info.profiles;
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 600;

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // Technical Grid Background
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.1 : 0.05,
              child: Image.asset(
                'assets/system_hud.png',
                fit: BoxFit.cover,
                color: isDark ? null : colorScheme.primary.withOpacity(0.3),
                colorBlendMode: isDark ? BlendMode.dst : BlendMode.srcATop,
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Modern App Bar with gradient
              SliverAppBar(
                expandedHeight: 140,
                floating: false,
                pinned: true,
                backgroundColor: Colors.transparent,
                flexibleSpace: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.surfaceContainerHighest,
                        colorScheme.surface.withOpacity(0.8),
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.primary.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    title: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'SYSTEM INTERFACE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4.0,
                            color: Color(0xFF00E5FF),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Hunter Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                            letterSpacing: -0.5,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    titlePadding: const EdgeInsets.only(left: 20, bottom: 20),
                  ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),

                    // Enhanced Profile Header
                    _buildEnhancedProfileHeader(context, userProfile),

                    const SizedBox(height: 24),

                    // Status Cards
                    _buildStatsCard(context),

                    const SizedBox(height: 32),

                    // Metrics Section Header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Row(
                        children: [
                          const Text(
                            'OPERATIONAL METRICS',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00E5FF),
                              letterSpacing: 2.0,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: const Color(0xFF00E5FF).withOpacity(0.2),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Enhanced Metrics Grid
                    _buildEnhancedMetricsGrid(context, isLargeScreen),

                    const SizedBox(height: 32),

                    // Department Canvas Section
                    _buildCanvasHeader(context),

                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Interactive Canvas
              SliverToBoxAdapter(child: _buildInteractiveCanvas()),
              SliverToBoxAdapter(child: DragCanvasGrid()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced Profile Header with System style
  Widget _buildEnhancedProfileHeader(BuildContext context, UserProfile user) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withOpacity(0.5),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF00E5FF).withOpacity(0.2),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Tech Accents
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 80,
                  height: 30,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E5FF).withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'ID: ALPHA-01',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    // Avatar with Hexagon Border
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF00E5FF),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E5FF).withOpacity(0.2),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 40,
                        backgroundColor: const Color(0xFF0F172A),
                        backgroundImage: user.profileImageUrl.isNotEmpty
                            ? NetworkImage(user.profileImageUrl)
                            : null,
                        child: user.profileImageUrl.isEmpty
                            ? const Icon(
                                Icons.person_rounded,
                                size: 40,
                                color: Color(0xFF00E5FF),
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                user.firstName.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.verified_user_rounded,
                                color: Color(0xFF00E5FF),
                                size: 16,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user.username.isNotEmpty
                                ? "@${user.username.toLowerCase()}"
                                : "Awaiting Credentials...",
                            style: TextStyle(
                              color: const Color(0xFF00E5FF).withOpacity(0.6),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Premium S-RANK Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                              ),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orange.withOpacity(0.4),
                                  blurRadius: 12,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.bolt_rounded,
                                  color: Colors.black,
                                  size: 16,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'S-RANK HUNTER',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Enhanced Stats Card with Status Window style
  Widget _buildStatsCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(
            isDark ? 0.3 : 0.6,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.onSurface.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.03),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withOpacity(0.05),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.dashboard_customize_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'STATUS WINDOW',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v4.12.0',
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurface.withOpacity(0.2),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _buildEnhancedStatBar(
                    context,
                    'STRENGTH',
                    142,
                    const Color(0xFFFF3D00).withOpacity(isDark ? 1.0 : 0.7),
                    Icons.bolt_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildEnhancedStatBar(
                    context,
                    'INTELLIGENCE',
                    188,
                    const Color(0xFF2979FF).withOpacity(isDark ? 1.0 : 0.7),
                    Icons.auto_awesome_motion_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildEnhancedStatBar(
                    context,
                    'AGILITY',
                    156,
                    const Color(0xFF00E676).withOpacity(isDark ? 1.0 : 0.7),
                    Icons.speed_rounded,
                  ),
                  const SizedBox(height: 20),
                  _buildEnhancedStatBar(
                    context,
                    'SENSORY',
                    110,
                    const Color(0xFFFFEA00).withOpacity(isDark ? 1.0 : 0.7),
                    Icons.visibility_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tactical stat bar
  Widget _buildEnhancedStatBar(
    BuildContext context,
    String label,
    int value,
    Color color,
    IconData icon,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final double progress = (value / 200).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: colorScheme.onSurface.withOpacity(0.7),
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Text(
              '$value',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 14,
                color: color,
                fontFamily: 'Monospace',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Enhanced Metrics Grid with modern cards
  Widget _buildEnhancedMetricsGrid(BuildContext context, bool isLargeScreen) {
    List<Map<String, dynamic>> metrics = [
      {
        'title': 'Total Logins',
        'value': 0, // Placeholder
        'icon': Icons.login,
        'gradient': [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
      },
      {
        'title': 'Active Projects',
        'value': 0, // Placeholder
        'icon': Icons.work_outline,
        'gradient': [const Color(0xFFF59E0B), const Color(0xFFD97706)],
      },
      {
        'title': 'Tasks Completed',
        'value': 0, // Placeholder
        'icon': Icons.task_alt,
        'gradient': [const Color(0xFF10B981), const Color(0xFF059669)],
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isLargeScreen ? 3 : 1,
          childAspectRatio: isLargeScreen ? 1.5 : 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: metrics.length,
        itemBuilder: (context, index) {
          final metric = metrics[index];
          return _buildEnhancedMetricCard(
            title: metric['title'],
            value: metric['value'].toString(),
            icon: metric['icon'],
            gradient: metric['gradient'],
          );
        },
      ),
    );
  }

  // Enhanced metric card with gradient and animation potential
  Widget _buildEnhancedMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.white.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: gradient[0].withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // Canvas section header
  Widget _buildCanvasHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 24,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Department Canvas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.touch_app,
                  color: Colors.white.withOpacity(0.8),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  'Double tap to toggle',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Interactive Canvas with enhanced styling
  Widget _buildInteractiveCanvas() {
    return Container(
      height: 600,
      width: 2000,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1F3A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          // panEnabled: false, // Disable panning
          // scaleEnabled: false, // Disable scaling/zooming
          // boundaryMargin: EdgeInsets.zero, // No boundary margin
          // minScale: 4.0, // Fixed scale
          // maxScale: 4.0, // Fixed scale
          // constrained: true, // Constrain to container size
          child: Stack(
            children: [
              DraggableCard(
                initialLeft: 10,
                initialTop: 50,
                title: "Health",
                onInteractionChanged: _setCardInteraction,
              ),
              DraggableCard(
                initialLeft: 200,
                initialTop: 100,
                title: "Mana",
                onInteractionChanged: _setCardInteraction,
              ),
              DraggableCard(
                initialLeft: 100,
                initialTop: 250,
                title: "Stamina",
                onInteractionChanged: _setCardInteraction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Enhanced DraggableCard Widget ---
class DraggableCard extends StatefulWidget {
  final double initialLeft;
  final double initialTop;
  final String title;
  final Function(bool) onInteractionChanged;

  const DraggableCard({
    super.key,
    required this.initialLeft,
    required this.initialTop,
    required this.title,
    required this.onInteractionChanged,
  });

  @override
  State<DraggableCard> createState() => _DraggableCardState();
}

class _DraggableCardState extends State<DraggableCard> {
  late double currentLeft;
  late double currentTop;
  double currentWidthPercent = 0.5;
  double currentHeightPercent = 0.5;
  bool onDragMode = true;
  double cardWidth = 200.0;
  double cardHeight = 200.0;
  @override
  void initState() {
    super.initState();
    currentLeft = widget.initialLeft;
    currentTop = widget.initialTop;
  }

  @override
  Widget build(BuildContext context) {
    final canvasWidth = MediaQuery.of(context).size.width;
    final canvasHeight = MediaQuery.of(context).size.height;

    return Positioned(
      left: currentLeft,
      top: currentTop,
      child: Listener(
        onPointerDown: (event) => widget.onInteractionChanged(true),
        onPointerUp: (event) => widget.onInteractionChanged(false),
        onPointerCancel: (event) => widget.onInteractionChanged(false),
        onPointerMove: (event) {
          setState(() {
            if (onDragMode) {
              currentLeft += event.delta.dx;
              currentTop += event.delta.dy;
              currentLeft = currentLeft.clamp(0.0, canvasWidth - cardWidth);
              currentTop = currentTop.clamp(0.0, canvasHeight - cardHeight);
            } else {
              if (cardHeight > 100 && cardWidth > 100) {
                cardWidth = cardWidth + event.delta.dx;
                cardHeight = cardHeight + event.delta.dy;
              } else {
                cardHeight = 200;
                cardWidth = 200;
              }

              currentWidthPercent = (cardWidth / canvasWidth).clamp(0.5, 1);
              currentHeightPercent = (cardHeight / canvasHeight).clamp(0.5, 1);
              // print("Hi hi hi");
            }
          });
        },
        child: GestureDetector(
          onDoubleTap: () {
            setState(() {
              onDragMode = !onDragMode;
            });
          },
          child: SizedBox(
            width: cardWidth,
            height: cardHeight,
            child: Stack(
              children: [
                DepartmentCard(
                  title: widget.title,
                  cardWidth: cardWidth,
                  cardHeight: cardHeight,
                ),
                Positioned(
                  bottom: 10,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: onDragMode
                              ? [
                                  const Color(0xFF8B5CF6),
                                  const Color(0xFF7C3AED),
                                ]
                              : [
                                  const Color(0xFFF59E0B),
                                  const Color(0xFFD97706),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                (onDragMode
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFFF59E0B))
                                    .withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            onDragMode ? Icons.open_with : Icons.aspect_ratio,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            onDragMode ? 'DRAG MODE' : 'RESIZE MODE',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
