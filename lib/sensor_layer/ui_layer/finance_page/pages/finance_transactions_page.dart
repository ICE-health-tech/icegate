import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/transaction_card.dart';
import 'package:signals_flutter/signals_flutter.dart';

class FinanceTransactionsPage extends StatefulWidget {
  final FinanceBlock financeBlock;

  const FinanceTransactionsPage({super.key, required this.financeBlock});

  @override
  State<FinanceTransactionsPage> createState() => _FinanceTransactionsPageState();
}

class _FinanceTransactionsPageState extends State<FinanceTransactionsPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<List<TransactionData>> _chunkTransactions(List<TransactionData> list, int size) {
    List<List<TransactionData>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(list.sublist(i, i + size > list.length ? list.length : i + size));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return Watch((context) {
      final transactions = widget.financeBlock.transactions.value;
      
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

      final chunks = _chunkTransactions(transactions, 2);

      return Column(
        children: [
          const SizedBox(height: 16),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: chunks.length,
              itemBuilder: (context, pageIndex) {
                final pageItems = chunks[pageIndex];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: pageItems.map((txn) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: TransactionCard(txn: txn, block: widget.financeBlock),
                    )).toList(),
                  ),
                );
              },
            ),
          ),
          if (chunks.length > 1) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                chunks.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.1),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ],
      );
    });
  }
}
