import 'package:flutter/material.dart';

class RollingScoreText extends StatelessWidget {
  final num value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final int decimalPlaces;

  const RollingScoreText({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 1000),
    this.prefix = '',
    this.decimalPlaces = 0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: duration,
      curve: Curves.easeOutExpo,
      builder: (context, animatedValue, child) {
        return Text(
          "$prefix${animatedValue.toStringAsFixed(decimalPlaces)}",
          style: style,
        );
      },
    );
  }
}

class ScorePulseWrapper extends StatefulWidget {
  final Widget child;
  final num value;

  const ScorePulseWrapper({
    super.key,
    required this.child,
    required this.value,
  });

  @override
  State<ScorePulseWrapper> createState() => _ScorePulseWrapperState();
}

class _ScorePulseWrapperState extends State<ScorePulseWrapper>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  num? _previousValue;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.2,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.2,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.elasticIn)),
        weight: 70,
      ),
    ]).animate(_controller);

    _glowAnimation = Tween<double>(begin: 0.0, end: 10.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _previousValue = widget.value;
  }

  @override
  void didUpdateWidget(ScorePulseWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value > (_previousValue ?? 0)) {
      _controller.forward(from: 0.0);
    }
    _previousValue = widget.value;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                if (_controller.isAnimating)
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(
                      0.5 * (1.0 - _controller.value),
                    ),
                    blurRadius: _glowAnimation.value,
                    spreadRadius: _glowAnimation.value / 2,
                  ),
              ],
            ),
            child: widget.child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class LevelUpCelebration extends StatefulWidget {
  final int level;
  final VoidCallback onFinished;

  const LevelUpCelebration({
    super.key,
    required this.level,
    required this.onFinished,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;
  late Animation<double> _glitch;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.0,
          end: 1.05,
        ).chain(CurveTween(curve: Curves.easeOutQuart)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.05,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 15,
      ),
    ]).animate(_controller);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 80),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);

    _glitch = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 5),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 5),
      TweenSequenceItem(tween: ConstantTween(0.0), weight: 90),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary; // Tactical Blue
    final accentColor = const Color(0xFFFF00FF); // Magenta accent

    return Material(
      color: Colors.transparent,
      child: Center(
        child: FadeTransition(
          opacity: _opacity,
          child: ScaleTransition(
            scale: _scale,
            child: AnimatedBuilder(
              animation: _glitch,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_glitch.value * 5, 0),
                  child: child,
                );
              },
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A0A0A),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: primaryColor,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "SYSTEM NOTICE",
                            style: TextStyle(
                              color: primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            "LV.${widget.level}",
                            style: TextStyle(
                              color: primaryColor.withOpacity(0.5),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 1,
                        color: primaryColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 24),

                      // Main Content
                      ShaderMask(
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [Colors.white, primaryColor, accentColor],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds),
                        child: const Text(
                          "LEVEL UP",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Text(
                        "You have reached a new stage of growth.",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Level Indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: primaryColor.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "CURRENT LEVEL: ",
                              style: TextStyle(
                                color: primaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${widget.level}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                        "REWARD: [ ENHANCED ATTRIBUTES ]",
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
