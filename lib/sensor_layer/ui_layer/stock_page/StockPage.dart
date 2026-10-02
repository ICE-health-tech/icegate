import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/link_layer/finnace_services/StockService.dart';
import 'package:provider/provider.dart';

/// Detail screen for a ticker; live quotes / charts are not fetched remotely.
class StockPage extends StatelessWidget {
  final String symbol;

  const StockPage({super.key, required this.symbol});

  @override
  Widget build(BuildContext context) {
    final svc = StockService();
    final name = svc.getStockName(symbol);

    return Scaffold(
      backgroundColor: EntryColors.glacierBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(
              symbol.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                "($name)",
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_outlined, size: 48, color: Colors.white.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              "Live prices are turned off",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "This screen shows the ticker only. Add or review Saving-category transactions under Finance, or log savings on the Savings tab.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: EntryColors.financeYellow.withValues(alpha: 0.9),
                  foregroundColor: const Color(0xFF0D0D12),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  context.read<FinanceBlock>().activeTab.value = 3;
                  context.go('/finance');
                },
                icon: const Icon(Icons.savings_rounded),
                label: const Text(
                  'Open Finance · Savings',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
