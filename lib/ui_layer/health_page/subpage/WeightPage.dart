import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/Action/WidgetNavigator.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/ui_layer/home_page/MainButton.dart';

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();

  static Widget icon(BuildContext context, {double? size}) {
    return MainButton(
      type: "weight",
            onSwipeUp: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeRight: () {
        WidgetNavigatorAction.smartPop(context);
      },
      onSwipeLeft: () => WidgetNavigatorAction.smartPop(context),
      destination: "/health/weight",
      size: size,
      icon: Icons.scale,
      mainFunction: () {

        context.go("/health/weight/log");
      },
    );
  }
}

class _WeightPageState extends State<WeightPage> {

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "WEIGHT JOURNEY",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 4,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      
      body: Stack(
        children: [
          Positioned(
            top: -100,
            left: -50,
            child: _AmbientGlow(color: Colors.purple.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: 100,
            right: -50,
            child: _AmbientGlow(color: Colors.blue.withValues(alpha: 0.1)),
          ),
          
          StreamBuilder<List<HealthMetricsLocal>>(
            stream: db.healthMetricsDAO.watchAllMetrics(personId),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final data =
                  snapshot.data!.where((m) => (m.weightKg ?? 0) > 0).toList()
                    ..sort((a, b) => b.date.compareTo(a.date));

              if (data.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.monitor_weight_outlined,
                        size: 80,
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "YOUR JOURNEY STARTS HERE",
                        style: TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final metric = data[index];
                  return _WeightListItem(metric: metric);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WeightListItem extends StatelessWidget {
  final HealthMetricsLocal metric;
  const _WeightListItem({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.purpleAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.monitor_weight_rounded,
                    color: Colors.purpleAccent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('MMMM d, yyyy').format(metric.date).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${(metric.weightKg ?? 0.0).toStringAsFixed(1)} kg",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white12,
                ),
              ],
            ),
          ),
        ),
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
