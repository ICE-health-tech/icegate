import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:signals/signals_flutter.dart';
import 'package:intl/intl.dart';

class TransactionCalendar extends StatelessWidget {
  final FinanceBlock financeBlock;

  const TransactionCalendar({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1);
    final lastDayOfMonth = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final startWeekday = firstDayOfMonth.weekday; // 1 (Mon) to 7 (Sun)
    
    // Adjust startWeekday to 0 (Sun) to 6 (Sat) if needed, 
    // but we'll assume Monday start for simplicity or adjust to Dart weekday
    
    return Watch((context) {
      final transactions = financeBlock.transactions.value;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF101014),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.04)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.MMMM().format(now).toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    fontSize: 14,
                  ),
                ),
                Text(
                  now.year.toString(),
                  style: TextStyle(color: Colors.white.withOpacity(0.3), fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: daysInMonth + (startWeekday - 1),
              itemBuilder: (context, index) {
                if (index < startWeekday - 1) return const SizedBox();
                
                final day = index - (startWeekday - 2);
                final hasTx = transactions.any((t) => t.transactionDate.day == day && t.transactionDate.month == now.month);
                final isToday = day == now.day;
                
                return Container(
                  decoration: BoxDecoration(
                    color: isToday ? Colors.blueAccent : (hasTx ? Colors.white.withOpacity(0.05) : Colors.transparent),
                    borderRadius: BorderRadius.circular(12),
                    border: isToday ? null : Border.all(color: Colors.white.withOpacity(0.05)),
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        color: isToday ? Colors.white : (hasTx ? Colors.white : Colors.white.withOpacity(0.2)),
                        fontSize: 12,
                        fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    });
  }
}
