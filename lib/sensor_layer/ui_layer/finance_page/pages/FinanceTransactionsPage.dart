import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/transaction_card.dart';

class FinanceTransactionsPage extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FinanceTransactionsPage({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final transactions = financeBlock.transactions.value;
      
      if (transactions.isEmpty) {
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_rounded, size: 48, color: Colors.white12),
              SizedBox(height: 16),
              Text(
                "No transactions found",
                style: TextStyle(color: Colors.white24, fontSize: 14),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final txn = transactions[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TransactionCard(txn: txn, block: financeBlock),
          );
        },
      );
    });
  }
}

