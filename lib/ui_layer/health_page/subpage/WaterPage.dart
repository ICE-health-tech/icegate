import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:intl/intl.dart';
import 'package:ice_shield/initial_layer/CoreLogics/PowerPoint/GameConst.dart';

class WaterPage extends StatefulWidget {
  const WaterPage({super.key});

  @override
  State<WaterPage> createState() => _WaterPageState();
}

class _WaterPageState extends State<WaterPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  final int _goalWater = WATER_GOAL;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dao = context.watch<HealthLogsDAO>();
    final textTheme = Theme.of(context).textTheme;

    final personId = Supabase.instance.client.auth.currentUser?.id ?? "";
    return StreamBuilder<List<WaterLogData>>(
      stream: dao.watchDailyWaterLogs(personId, DateTime.now()),
      builder: (context, snapshot) {
        final logs = snapshot.data ?? [];
        final totalWater = logs.fold<int>(0, (sum, log) => sum + log.amount);
        double progress = (totalWater / _goalWater).clamp(0.0, 1.0);

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: const Text(
              'Water Intensity',
              style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: Stack(
            children: [
              // Aquatic Gradient Background
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2),
                      Color(0xFF42A5F5),
                    ],
                  ),
                ),
              ),

              // Animated Wave Liquid Effect
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, child) {
                    return CustomPaint(
                      painter: LiquidPainter(
                        progress: progress,
                        waveValue: _waveController.value,
                      ),
                    );
                  },
                ),
              ),

              // Content Overlay
              SafeArea(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    // Centered Counter
                    Column(
                      children: [
                        Text(
                          '$totalWater',
                          style: textTheme.displayLarge?.copyWith(
                            fontSize: 80,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ),
                        Text(
                          'OF $_goalWater ML',
                          style: const TextStyle(
                            color: Colors.white70,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const Spacer(),

                    // Statistics Card
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(25),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withAlpha(40)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _statItem(
                              "GOAL",
                              "$_goalWater ml",
                              Icons.flag_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _statItem(
                              "POINTS",
                              "+$WATER_BONUS_POINTS XP",
                              Icons.stars_rounded,
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: Colors.white24,
                            ),
                            _statItem(
                              "LEFT",
                              "${math.max(0, _goalWater - totalWater)} ml",
                              Icons.opacity_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Quick Add Tactile Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: Colors.white.withAlpha(50)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _tactileButton(context, dao, 200, "200"),
                            _tactileButton(context, dao, 300, "300"),
                            _tactileButton(context, dao, 500, "500"),
                            _customButton(context, dao),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Glassmorphic History List
                    Container(
                      height: 250,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(15),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        border: Border.all(color: Colors.white.withAlpha(30)),
                      ),
                      child: logs.isEmpty
                          ? const Center(
                              child: Text(
                                "STAY HYDRATED",
                                style: TextStyle(
                                  color: Colors.white38,
                                  letterSpacing: 2,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(24),
                              itemCount: logs.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final log = logs[logs.length - 1 - index];
                                return _historyItem(log, context);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tactileButton(
    BuildContext context,
    HealthLogsDAO dao,
    int amount,
    String label,
  ) {
    return GestureDetector(
      onTap: () async {
        Feedback.forTap(context);
        await dao.insertWaterLog(
          WaterLogsTableCompanion.insert(
            id: IDGen.UUIDV7(),
            personID: drift.Value(
              Supabase.instance.client.auth.currentUser?.id ?? "",
            ),
            amount: drift.Value(amount),
            timestamp: drift.Value(DateTime.now()),
          ),
        );
      },
      child: Container(
        height: 60,
        width: 60,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: Color(0xFF1976D2),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customButton(BuildContext context, HealthLogsDAO dao) {
    return GestureDetector(
      onTap: () => _showCustomInputDialog(context, dao),
      child: Container(
        height: 60,
        width: 60,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 30),
      ),
    );
  }

  void _showCustomInputDialog(BuildContext context, HealthLogsDAO dao) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("CUSTOM INTAKE"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: "ML"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL"),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = int.tryParse(controller.text) ?? 0;
              if (amount > 0) {
                await dao.insertWaterLog(
                  WaterLogsTableCompanion.insert(
                    id: IDGen.UUIDV7(),
                    personID: drift.Value(
                      Supabase.instance.client.auth.currentUser?.id ?? "",
                    ),
                    amount: drift.Value(amount),
                    timestamp: drift.Value(DateTime.now()),
                  ),
                );
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("ADD"),
          ),
        ],
      ),
    );
  }

  Widget _historyItem(WaterLogData log, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.water_drop, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 15),
          Text(
            "${log.amount} ML",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Spacer(),
          Text(
            DateFormat('HH:mm').format(log.timestamp),
            style: const TextStyle(color: Colors.white38, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white38,
            fontSize: 10,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class LiquidPainter extends CustomPainter {
  final double progress;
  final double waveValue;

  LiquidPainter({required this.progress, required this.waveValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..color = Colors.white.withAlpha(40)
      ..style = PaintingStyle.fill;

    final path = Path();
    double yOffset = size.height * (1 - progress);

    path.moveTo(0, yOffset);

    // Wave Animation
    for (double i = 0; i <= size.width; i++) {
      path.lineTo(
        i,
        yOffset +
            math.sin(
                  (i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi),
                ) *
                10,
      );
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);

    // Forefront wave (slightly different phase/color)
    final paint2 = Paint()
      ..color = Colors.white.withAlpha(30)
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, yOffset);
    for (double i = 0; i <= size.width; i++) {
      path2.lineTo(
        i,
        yOffset +
            math.cos(
                  (i / size.width * 2 * math.pi) + (waveValue * 2 * math.pi),
                ) *
                15,
      );
    }
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(LiquidPainter oldDelegate) => true;
}
