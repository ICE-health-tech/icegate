import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/subscription_manager.dart';

class FinanceSubscriptionsPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceSubscriptionsPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          SubscriptionManager(financeBlock: financeBlock),
          const SizedBox(height: 120), // Bottom space
        ],
      ),
    );
  }
}
