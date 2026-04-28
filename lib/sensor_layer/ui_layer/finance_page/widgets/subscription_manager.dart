import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/entry_constants.dart';

class SubscriptionManager extends StatelessWidget {
  final FinanceBlock financeBlock;

  const SubscriptionManager({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Watch((context) {
      final subs = financeBlock.subscriptions.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "ACTIVE SUBSCRIPTIONS",
                      style: TextStyle(
                        color: EntryColors.financeYellow,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.finance_cat_subscriptions,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                _buildAddButton(context),
              ],
            ),
          ),
          if (subs.isEmpty)
            _buildEmptyState(context)
          else
            SizedBox(
              height: 180,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: subs.length,
                itemBuilder: (context, index) {
                  final sub = subs[index];
                  return _buildSubscriptionCard(context, sub);
                },
              ),
            ),
        ],
      );
    });
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showSubscriptionSheet(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: const Icon(Icons.add_rounded, color: EntryColors.financeYellow, size: 20),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.layers_clear_rounded, color: Colors.white.withValues(alpha: 0.1), size: 32),
            const SizedBox(height: 12),
            Text(
              "NO RECURRING BILLS",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.2),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, SubscriptionData sub) {
    final daysLeft = _calculateDaysLeft(sub.billingDay);
    final isYearly = (sub as dynamic).billingCycle == 'yearly';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16, bottom: 10, top: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161E),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: InkWell(
            onTap: () => _showSubscriptionSheet(context, subscription: sub),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: EntryColors.financeYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _getCategoryIcon(sub.category ?? 'software'),
                          color: EntryColors.financeYellow,
                          size: 16,
                        ),
                      ),
                      _buildCycleBadge(isYearly),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    sub.name.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                      letterSpacing: 1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    financeBlock.formatCurrency(sub.amount),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCountdownBadge(daysLeft),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleBadge(bool isYearly) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        isYearly ? "Y" : "M",
        style: const TextStyle(color: Colors.white30, fontSize: 8, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildCountdownBadge(int days) {
    final bool isSoon = days <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSoon ? Colors.red.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSoon ? Colors.red.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Text(
        days == 0 ? "DUE TODAY" : "$days DAYS LEFT",
        style: TextStyle(
          color: isSoon ? Colors.redAccent : Colors.white54,
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  int _calculateDaysLeft(int billingDay) {
    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYear = now.year;
    
    DateTime billingDate = DateTime(currentYear, currentMonth, billingDay);
    if (billingDate.isBefore(DateTime(now.year, now.month, now.day))) {
      billingDate = DateTime(currentYear, currentMonth + 1, billingDay);
    }
    
    return billingDate.difference(DateTime(now.year, now.month, now.day)).inDays;
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'software': return Icons.terminal_rounded;
      case 'entertainment': return Icons.play_circle_fill_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'health': return Icons.favorite_rounded;
      case 'bills': return Icons.bolt_rounded;
      case 'rent': return Icons.home_rounded;
      default: return Icons.layers_rounded;
    }
  }

  void _showSubscriptionSheet(BuildContext context, {SubscriptionData? subscription}) {
    final isEdit = subscription != null;
    final nameController = TextEditingController(text: subscription?.name ?? "");
    
    String initialAmount = "";
    if (subscription != null) {
      initialAmount = financeBlock.convertToDisplay(subscription.amount)
          .toStringAsFixed(financeBlock.useVnd.value ? 0 : 2);
    }
    final amountController = TextEditingController(text: initialAmount);
    int billingDay = subscription?.billingDay ?? DateTime.now().day;
    String selectedCategory = subscription?.category ?? 'software';
    String selectedCycle = (subscription as dynamic)?.billingCycle ?? 'monthly';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              left: 24, right: 24, top: 24,
            ),
            decoration: const BoxDecoration(
              color: Color(0xFF0D0D12),
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text(isEdit ? "MODIFY SUBSCRIPTION" : "NEW SUBSCRIPTION", style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 24),
                _buildField(nameController, "SERVICE NAME", Icons.api_rounded),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildField(amountController, "AMOUNT", Icons.payments_rounded, isNumeric: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _buildDayPicker(billingDay, (val) => setState(() => billingDay = val))),
                  ],
                ),
                const SizedBox(height: 24),
                _buildCycleSelector(selectedCycle, (val) => setState(() => selectedCycle = val)),
                const SizedBox(height: 24),
                _buildCategorySelector(selectedCategory, (val) => setState(() => selectedCategory = val)),
                const SizedBox(height: 32),
                _buildActionButtons(context, isEdit, subscription, nameController, amountController, billingDay, selectedCategory, selectedCycle),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {bool isNumeric = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900),
        prefixIcon: Icon(icon, color: Colors.white24, size: 18),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDayPicker(int current, Function(int) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.03), borderRadius: BorderRadius.circular(16)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: current,
          dropdownColor: const Color(0xFF16161E),
          items: List.generate(31, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text("Day $d", style: const TextStyle(color: Colors.white, fontSize: 12)))).toList(),
          onChanged: (v) => onChanged(v ?? 1),
        ),
      ),
    );
  }

  Widget _buildCycleSelector(String current, Function(String) onChanged) {
    return Row(
      children: ['monthly', 'yearly'].map((cycle) {
        final isSel = current == cycle;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(cycle),
            child: Container(
              margin: EdgeInsets.only(right: cycle == 'monthly' ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSel ? EntryColors.financeYellow.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSel ? EntryColors.financeYellow.withValues(alpha: 0.3) : Colors.white10),
              ),
              child: Center(child: Text(cycle.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : Colors.white24, fontSize: 10, fontWeight: FontWeight.w900))),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector(String current, Function(String) onChanged) {
    final cats = ['software', 'entertainment', 'music', 'health', 'bills', 'rent'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("CATEGORY", style: TextStyle(color: Colors.white24, fontSize: 10, fontWeight: FontWeight.w900)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8, runSpacing: 8,
          children: cats.map((cat) {
            final isSel = current == cat;
            return GestureDetector(
              onTap: () => onChanged(cat),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: isSel ? Colors.white24 : Colors.white.withValues(alpha: 0.05)),
                ),
                child: Text(cat.toUpperCase(), style: TextStyle(color: isSel ? Colors.white : Colors.white24, fontSize: 9, fontWeight: FontWeight.bold)),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isEdit, SubscriptionData? sub, TextEditingController n, TextEditingController a, int d, String c, String cy) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () async {
              final rawAmount = double.tryParse(a.text.replaceFirst(',', '.'));
              if (n.text.isEmpty || rawAmount == null) return;
              final amount = financeBlock.convertToBase(rawAmount);
              if (isEdit) {
                await financeBlock.updateSubscription(id: sub!.id, name: n.text, amount: amount, billingDay: d, category: c, billingCycle: cy);
              } else {
                await financeBlock.addSubscription(name: n.text, amount: amount, billingDay: d, category: c, billingCycle: cy);
              }
              if (context.mounted) Navigator.pop(context);
            },
            style: FilledButton.styleFrom(backgroundColor: EntryColors.financeYellow, padding: const EdgeInsets.symmetric(vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
            child: Text(isEdit ? "UPDATE SUBSCRIPTION" : "ESTABLISH SUBSCRIPTION", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
          ),
        ),
        if (isEdit) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF16161E),
                    title: const Text("DELETE SUBSCRIPTION", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900)),
                    content: const Text("Are you sure you want to remove this recurring bill?", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCEL", style: TextStyle(color: Colors.white24))),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("DELETE", style: TextStyle(color: Colors.redAccent))),
                    ],
                  ),
                );
                if (confirm == true) {
                  await financeBlock.deleteSubscription(sub!.id);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text("DELETE RECURRING BILL", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
            ),
          ),
        ],
      ],
    );
  }
}
