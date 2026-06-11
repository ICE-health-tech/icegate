import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ice_gate/sensor_layer/ui_layer/health_page/HealthMetricColors.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Visual layout for Projects quick-action shortcuts.
enum ProjectsQuickActionsLayout {
  /// Responsive ice chip grid (default).
  dotGrid,

  /// Full-width list rows.
  compactStrip,
}

/// One quick-action cell.
class QuickActionTileSpec {
  const QuickActionTileSpec({
    required this.label,
    required this.icon,
    required this.accent,
    required this.onTap,
    this.onLongPress,
    this.isAddSlot = false,
  });

  final String label;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool isAddSlot;
}

class ProjectsQuickActionsHub extends StatefulWidget {
  const ProjectsQuickActionsHub({
    super.key,
    required this.tiles,
    required this.layout,
    required this.onLayoutChanged,
  });

  final List<QuickActionTileSpec> tiles;
  final ProjectsQuickActionsLayout layout;
  final ValueChanged<ProjectsQuickActionsLayout> onLayoutChanged;

  static const _prefKey = 'projects_quick_hub_layout';

  static Future<ProjectsQuickActionsLayout> loadSavedLayout() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefKey) == 'strip'
        ? ProjectsQuickActionsLayout.compactStrip
        : ProjectsQuickActionsLayout.dotGrid;
  }

  static Future<void> saveLayout(ProjectsQuickActionsLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      layout == ProjectsQuickActionsLayout.compactStrip ? 'strip' : 'grid',
    );
  }

  @override
  State<ProjectsQuickActionsHub> createState() => _ProjectsQuickActionsHubState();
}

class _ProjectsQuickActionsHubState extends State<ProjectsQuickActionsHub> {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final body = widget.layout == ProjectsQuickActionsLayout.compactStrip
            ? _buildStrip(context, widget.tiles)
            : _buildChipGrid(context, widget.tiles, maxW);

        return Container(
          decoration: _iceHubPanel(cs, isDark: isDark),
          child: Stack(
            children: [
              // Positioned(
              //   top: 10,
              //   left: 10,
              //   right: 10,
              //   child: Container(
              //     height: 1,
              //     decoration: BoxDecoration(
              //       gradient: LinearGradient(
              //         colors: [
              //           Colors.white.withValues(alpha: isDark ? 0.16 : 0.35),
              //           Colors.white.withValues(alpha: isDark ? 0.03 : 0.08),
              //         ],
              //       ),
              //     ),
              //   ),
              // ),
              Padding(
              padding: const EdgeInsets.fromLTRB(0,20,5,20),child:
              Center(
                // padding: const EdgeInsets.fromLTRB(40, 10, 12, 12),
                
                child: body,
              ),)
            ],
          ),
        );
      },
    );
  }

  BoxDecoration _iceHubPanel(ColorScheme cs, {required bool isDark}) {
    final base = HealthMetricColors.shellPanel(cs, isDark: isDark, radius: 20);
    if (!isDark) return base;
    return base.copyWith(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.alphaBlend(
            HealthMetricColors.iceBgMid.withValues(alpha: 0.22),
            HealthMetricColors.shellIslandFill,
          ),
          HealthMetricColors.shellIslandFill,
        ],
      ),
    );
  }

  Widget _buildChipGrid(
    BuildContext context,
    List<QuickActionTileSpec> tiles,
    double maxWidth,
  ) {
    const spacing = 6.0;
    const minTileWidth = 80.0;
    const tileHeight = 78.0;
    final cols =
        ((maxWidth + spacing) / (minTileWidth + spacing)).floor().clamp(2, 5);
    final tileWidth = (maxWidth - spacing * (cols - 1)) / cols;

    return Wrap(
      spacing: spacing,
      runSpacing: spacing,
      children: [
        for (var i = 0; i < tiles.length; i++)
          SizedBox(
            width: tileWidth,
            height: tileHeight,
            child: _IceQuickActionTile(
              spec: tiles[i],
              compact: false,
              staggerIndex: i,
            ),
          ),
      ],
    );
  }

  Widget _buildStrip(BuildContext context, List<QuickActionTileSpec> tiles) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          if (i > 0) const SizedBox(height: 3),
          SizedBox(
            height: 48,
            child: _IceQuickActionTile(
              spec: tiles[i],
              compact: true,
              staggerIndex: i,
            ),
          ),
        ],
      ],
    );
  }
}

class _IceQuickActionTile extends StatefulWidget {
  const _IceQuickActionTile({
    required this.spec,
    required this.compact,
    this.staggerIndex = 0,
  });

  final QuickActionTileSpec spec;
  final bool compact;
  final int staggerIndex;

  @override
  State<_IceQuickActionTile> createState() => _IceQuickActionTileState();
}

class _IceQuickActionTileState extends State<_IceQuickActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseScale;
  bool _pressed = false;

  QuickActionTileSpec get spec => widget.spec;
  bool get compact => widget.compact;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 2200 + (widget.staggerIndex % 4) * 180),
    );
    _pulseScale = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    _pulse.value = (widget.staggerIndex * 0.17) % 1.0;
    _pulse.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    spec.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = spec.isAddSlot ? cs.outline : spec.accent;
    final radius = BorderRadius.circular(compact ? 14 : 16);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _handleTap,
        onLongPress: spec.onLongPress,
        onHighlightChanged: _setPressed,
        borderRadius: radius,
        splashColor: accent.withValues(alpha: 0.16),
        highlightColor: accent.withValues(alpha: 0.06),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            color: isDark
                ? Color.alphaBlend(
                    accent.withValues(alpha: spec.isAddSlot ? 0.04 : 0.1),
                    Colors.white.withValues(alpha: 0.04),
                  )
                : cs.surface.withValues(alpha: 0.88),
            border: Border.all(
              color: spec.isAddSlot
                  ? HealthMetricColors.borderBright.withValues(alpha: 0.35)
                  : accent.withValues(alpha: isDark ? 0.42 : 0.38),
            ),
          ),
          child: compact ? _buildStripContent(cs, accent) : _buildGridContent(cs, accent),
        ),
      ),
    );
  }

  Widget _buildAnimatedIconBadge(
    ColorScheme cs,
    Color accent, {
    required double size,
    required double iconSize,
  }) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = _pulseScale.value * (_pressed ? 0.86 : 1.0);
        return Transform.scale(
          scale: scale,
          child: child,
        );
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: accent.withValues(alpha: 0.12),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Icon(
          spec.icon,
          size: iconSize,
          color: spec.isAddSlot
              ? cs.onSurface.withValues(alpha: 0.7)
              : accent,
        ),
      ),
    );
  }

  Widget _buildGridContent(ColorScheme cs, Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedIconBadge(cs, accent, size: 32, iconSize: 16),
          const SizedBox(height: 5),
          Flexible(
            child: Text(
              spec.label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 9,
                height: 1.1,
                letterSpacing: -0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStripContent(ColorScheme cs, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildAnimatedIconBadge(cs, accent, size: 32, iconSize: 16),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              spec.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: cs.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: cs.onSurface.withValues(alpha: 0.35),
          ),
        ],
      ),
    );
  }
}

class ProjectsQuickActionsBlock extends StatefulWidget {
  const ProjectsQuickActionsBlock({
    super.key,
    required this.title,
    required this.tiles,
  });

  final String title;
  final List<QuickActionTileSpec> tiles;

  @override
  State<ProjectsQuickActionsBlock> createState() =>
      _ProjectsQuickActionsBlockState();
}

class _ProjectsQuickActionsBlockState extends State<ProjectsQuickActionsBlock> {
  ProjectsQuickActionsLayout _layout = ProjectsQuickActionsLayout.dotGrid;

  @override
  void initState() {
    super.initState();
    ProjectsQuickActionsHub.loadSavedLayout().then((layout) {
      if (mounted) setState(() => _layout = layout);
    });
  }

  Future<void> _toggleLayout() async {
    final next = _layout == ProjectsQuickActionsLayout.dotGrid
        ? ProjectsQuickActionsLayout.compactStrip
        : ProjectsQuickActionsLayout.dotGrid;
    setState(() => _layout = next);
    await ProjectsQuickActionsHub.saveLayout(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProjectsQuickActionsHeader(
          title: widget.title,
          layout: _layout,
          onToggleLayout: _toggleLayout,
        ),
        const SizedBox(height: 10),
        ProjectsQuickActionsHub(
          tiles: widget.tiles,
          layout: _layout,
          onLayoutChanged: (layout) async {
            setState(() => _layout = layout);
            await ProjectsQuickActionsHub.saveLayout(layout);
          },
        ),
      ],
    );
  }
}

class ProjectsQuickActionsHeader extends StatelessWidget {
  const ProjectsQuickActionsHeader({
    super.key,
    required this.title,
    required this.layout,
    required this.onToggleLayout,
  });

  final String title;
  final ProjectsQuickActionsLayout layout;
  final VoidCallback onToggleLayout;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isStrip = layout == ProjectsQuickActionsLayout.compactStrip;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 10,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                HealthMetricColors.pillarBlue,
                HealthMetricColors.pillarBlue.withValues(alpha: 0.35),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: HealthMetricColors.ink(cs, isDark: isDark),
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                isStrip ? 'List view' : 'Grid view',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: HealthMetricColors.mutedInk(cs, isDark: isDark),
                ),
              ),
            ],
          ),
        ),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onToggleLayout,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : cs.surfaceContainerHighest.withValues(alpha: 0.7),
                border: Border.all(
                  color: HealthMetricColors.borderBright.withValues(
                    alpha: isDark ? 0.35 : 0.25,
                  ),
                ),
              ),
              child: Icon(
                isStrip ? Icons.grid_view_rounded : Icons.view_list_rounded,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
