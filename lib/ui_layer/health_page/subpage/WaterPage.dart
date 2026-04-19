import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart'
    show
        HealthLogsDAO,
        WaterLogData;

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage> with TickerProviderStateMixin {
  late final AnimationController _waveController;
  late final AnimationController _bubbleController;
  final List<_Bubble> _bubbles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize bubbles
    for (int i = 0; i < 15; i++) {
      _bubbles.add(_Bubble(_random));
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  void _addWater(int ml) {
    context.read<HealthBlock>().updateWaterLevel(ml);
    HapticFeedback.mediumImpact();
  }

  void _removeWater(String id) {
    context.read<HealthBlock>().deleteWaterLog(id);
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final healthBlock = context.watch<HealthBlock>();
    final todayWaterValue = healthBlock.todayWater.watch(context);
    final goal = 2500; // Target goal in ml
    final progress = (todayWaterValue / goal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black, // Immersive base
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -100,
            left: -50,
            child: _AmbientGlow(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          Positioned(
            bottom: 150,
            right: -100,
            child: _AmbientGlow(color: Colors.cyan.withValues(alpha: 0.1)),
          ),

          // Animated Bubbles
          AnimatedBuilder(
            animation: _bubbleController,
            builder: (context, child) {
              return Stack(
                children: _bubbles.map((bubble) {
                  bubble.update(_bubbleController.value);
                  return Positioned(
                    left: bubble.x * MediaQuery.of(context).size.width,
                    bottom: bubble.y * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: bubble.opacity,
                      child: Container(
                        width: bubble.size,
                        height: bubble.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.4),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 40),
                        _buildWaterProgress(todayWaterValue, goal, progress, colorScheme),
                        const SizedBox(height: 60),
                        _buildQuickAddActions(colorScheme),
                        const SizedBox(height: 40),
                        _buildHistorySection(context, colorScheme),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Text(
            'WATER INTAKE',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              letterSpacing: 4,
              fontSize: 14,
            ),
          ),
          IconButton(
            onPressed: () {}, // Settings
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterProgress(int current, int goal, double progress, ColorScheme colorScheme) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Ring
            SizedBox(
              width: 280,
              height: 280,
              child: CircularProgressIndicator(
                value: progress,
                strokeWidth: 16,
                backgroundColor: Colors.white.withValues(alpha: 0.05),
                strokeCap: StrokeCap.round,
                color: Colors.blueAccent,
              ),
            ),
            // Inner Content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.water_drop_rounded, size: 48, color: Colors.blueAccent),
                const SizedBox(height: 16),
                Text(
                  '$current',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1,
                    letterSpacing: -2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'ml / $goal ml'.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 48),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
          ),
          child: Text(
            '${(progress * 100).toInt()}% OF DAILY GOAL',
            style: const TextStyle(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAddActions(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ADD',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _addBtn(250, 'Glass', Icons.local_drink_rounded),
              _addBtn(500, 'Bottle', Icons.wine_bar_rounded),
              _addBtn(750, 'Large', Icons.liquor_rounded),
            ],
          ),
        ],
      ),
    );
  }

  Widget _addBtn(int ml, String label, IconData icon) {
    return GestureDetector(
      onTap: () => _addWater(ml),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 105,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Icon(icon, color: Colors.blueAccent, size: 36),
                const SizedBox(height: 16),
                Text(
                  '${ml}ML',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  label.toUpperCase(),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistorySection(BuildContext context, ColorScheme colorScheme) {
    final personId = context.read<PersonBlock>().information.value.profiles.id ?? "";
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LOG HISTORY',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 11, color: Colors.white38),
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<WaterLogData>>(
            stream: context.read<HealthLogsDAO>().watchDailyWaterLogs(personId, DateTime.now()),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48.0),
                    child: Column(
                      children: [
                        Icon(Icons.history, size: 48, color: Colors.white.withValues(alpha: 0.05)),
                        const SizedBox(height: 16),
                        const Text('NO RECORDS TODAY', style: TextStyle(color: Colors.white10, fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              }

              final logs = snapshot.data!;
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: logs.length,
                itemBuilder: (context, index) {
                  final log = logs[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(Icons.water_drop_rounded, color: Colors.blueAccent, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${log.amount} ML',
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16, letterSpacing: -0.5),
                                  ),
                                  Text(
                                    DateFormat('HH:mm').format(log.timestamp),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white38,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _removeWater(log.id),
                              icon: const Icon(Icons.delete_outline_rounded, size: 20),
                              color: Colors.redAccent.withValues(alpha: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AmbientGlow extends StatelessWidget {
  final Color color;
  const _AmbientGlow({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 100,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

class _Bubble {
  double x;
  double y;
  double size;
  double opacity;
  double speed;
  final math.Random random;

  _Bubble(this.random)
      : x = random.nextDouble(),
        y = random.nextDouble(),
        size = 10 + random.nextDouble() * 30,
        opacity = 0.1 + random.nextDouble() * 0.3,
        speed = 0.05 + random.nextDouble() * 0.1;

  void update(double value) {
    y += speed * 0.01;
    if (y > 1.1) {
      y = -0.1;
      x = random.nextDouble();
    }
  }
}
