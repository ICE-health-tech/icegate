import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/ui_layer/ReusableWidget/SwipeablePage.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/HealthBlock.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:drift/drift.dart' hide Column;

class WeightPage extends StatefulWidget {
  const WeightPage({super.key});

  @override
  State<WeightPage> createState() => _WeightPageState();
}

class _WeightPageState extends State<WeightPage> {
  final TextEditingController _weightController = TextEditingController();

  Future<void> _showAddWeightDialog() async {
    final personBlock = context.read<PersonBlock>();
    final healthBlock = context.read<HealthBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Log Weight"),
        content: TextField(
          controller: _weightController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: "Weight (kg)",
            suffixText: "kg",
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              final weight = double.tryParse(_weightController.text);
              if (weight != null && personId.isNotEmpty) {
                healthBlock.updateWeight(weight);
                _weightController.clear();
                if (mounted) Navigator.pop(dialogContext);
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.watch<AppDatabase>();
    final personBlock = context.watch<PersonBlock>();
    final personId = personBlock.information.value.profiles.id ?? "";
    final colorScheme = Theme.of(context).colorScheme;

    return SwipeablePage(
      onSwipe: () => Navigator.maybePop(context),
      direction: SwipeablePageDirection.leftToRight,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: const Text(
            "Weight Tracker",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddWeightDialog,
          child: const Icon(Icons.add_rounded),
        ),
        body: StreamBuilder<List<HealthMetricsLocal>>(
          stream: db.healthMetricsDAO.watchAllMetrics(personId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final data =
                snapshot.data!.where((m) => (m.weightKg ?? 0) > 0).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

            if (data.isEmpty) {
              return const Center(child: Text("No weight data logged yet."));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: data.length,
              itemBuilder: (context, index) {
                final metric = data[index];
                return _WeightListItem(metric: metric);
              },
            );
          },
        ),
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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('MMMM d, yyyy').format(metric.date),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                "${(metric.weightKg ?? 0.0).toStringAsFixed(1)} kg",
                style: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const Icon(Icons.monitor_weight_rounded, color: Colors.blueAccent),
        ],
      ),
    );
  }
}
