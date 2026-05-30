import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/ConfigBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceCurrencyToggle.dart';

int _clampBillingDay(int billingDay, int year, int month) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return billingDay.clamp(1, lastDay);
}

/// Next charge date on or after today (monthly roll-forward; yearly once per year).
DateTime subscriptionNextBillingDate(SubscriptionData sub, [DateTime? reference]) {
  final now = reference ?? DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  if (sub.billingCycle == 'yearly') {
    final anchorMonth = sub.createdAt.toLocal().month;
    final day = _clampBillingDay(sub.billingDay, now.year, anchorMonth);
    var due = DateTime(now.year, anchorMonth, day);
    if (!due.isAfter(today)) {
      due = DateTime(now.year + 1, anchorMonth, day);
    }
    return due;
  }

  final day = _clampBillingDay(sub.billingDay, now.year, now.month);
  var due = DateTime(now.year, now.month, day);
  if (due.isBefore(today)) {
    final nextMonth = now.month == 12 ? 1 : now.month + 1;
    final nextYear = now.month == 12 ? now.year + 1 : now.year;
    due = DateTime(
      nextYear,
      nextMonth,
      _clampBillingDay(sub.billingDay, nextYear, nextMonth),
    );
  }
  return due;
}

List<({SubscriptionData sub, DateTime due})> subscriptionsDueInMonth(
  List<SubscriptionData> subs,
  int year,
  int month, {
  Set<String> planSkips = const {},
}) {
  final items = <({SubscriptionData sub, DateTime due})>[];
  for (final sub in subs.where((s) => s.isActive)) {
    final skipToken = ConfigBlock.subscriptionPlanSkipToken(sub.id, year, month);
    if (planSkips.contains(skipToken)) continue;
    final due = subscriptionNextBillingDate(sub);
    if (due.year == year && due.month == month) {
      items.add((sub: sub, due: due));
    }
  }
  items.sort((a, b) => a.due.compareTo(b.due));
  return items;
}

/// Opens the subscription editor (create or edit). Used from the Billing tab MainButton.
void showSubscriptionEditor(
  BuildContext context,
  FinanceBlock financeBlock, {
  SubscriptionData? subscription,
  int? planYear,
  int? planMonth,
}) {
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
  String selectedCycle = subscription?.billingCycle ?? 'monthly';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Watch((context) {
      final useVnd = financeBlock.useVnd.value;
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
              left: 24,
              right: 24,
              top: 24,
            ),
            decoration: const BoxDecoration(
              color: EntryColors.deepGlacier,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  isEdit ? "MODIFY SUBSCRIPTION" : "NEW SUBSCRIPTION",
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FinanceInlineCurrencyToggle(
                    financeBlock: financeBlock,
                    onTap: () => toggleFinanceCurrencyWithAmountField(
                      financeBlock: financeBlock,
                      amountController: amountController,
                      setState: setState,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _subscriptionSheetField(nameController, "SERVICE NAME", Icons.api_rounded),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _subscriptionSheetField(
                        amountController,
                        "AMOUNT",
                        Icons.payments_rounded,
                        isNumeric: true,
                        prefixText: !useVnd ? '\$ ' : null,
                        suffixText: useVnd ? ' ₫' : null,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _subscriptionSheetDayPicker(
                      billingDay,
                      (val) => setState(() => billingDay = val),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _subscriptionSheetCycleSelector(
                selectedCycle,
                (val) => setState(() => selectedCycle = val),
              ),
              const SizedBox(height: 24),
              _subscriptionSheetCategorySelector(
                selectedCategory,
                (val) => setState(() => selectedCategory = val),
              ),
              const SizedBox(height: 32),
                _subscriptionSheetActionButtons(
                  context,
                  financeBlock,
                  isEdit,
                  subscription,
                  nameController,
                  amountController,
                  billingDay,
                  selectedCategory,
                  selectedCycle,
                  planYear: planYear,
                  planMonth: planMonth,
                ),
            ],
          ),
        );
        },
      );
    }),
  );
}

Widget _subscriptionSheetField(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool isNumeric = false,
  String? prefixText,
  String? suffixText,
}) {
  return TextField(
    controller: controller,
    keyboardType: isNumeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Colors.white24,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
      prefixIcon: Icon(icon, color: Colors.white24, size: 18),
      prefixText: prefixText,
      suffixText: suffixText,
      prefixStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
      suffixStyle: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _subscriptionSheetDayPicker(int current, void Function(int) onChanged) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: current,
        dropdownColor: const Color(0xFF16161E),
        items: List.generate(31, (i) => i + 1)
            .map(
              (d) => DropdownMenuItem(
                value: d,
                child: Text(
                  "Day $d",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            )
            .toList(),
        onChanged: (v) => onChanged(v ?? 1),
      ),
    ),
  );
}

Widget _subscriptionSheetCycleSelector(
  String current,
  void Function(String) onChanged,
) {
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
              color: isSel
                  ? EntryColors.financeSilverAccent.withValues(alpha: 0.1)
                  : Colors.white.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSel
                    ? EntryColors.financeSilverAccent.withValues(alpha: 0.3)
                    : Colors.white10,
              ),
            ),
            child: Center(
              child: Text(
                cycle.toUpperCase(),
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ),
      );
    }).toList(),
  );
}

Widget _subscriptionSheetCategorySelector(
  String current,
  void Function(String) onChanged,
) {
  final cats = ['software', 'entertainment', 'music', 'health', 'bills', 'rent'];
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "CATEGORY",
        style: TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: cats.map((cat) {
          final isSel = current == cat;
          return GestureDetector(
            onTap: () => onChanged(cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.white.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSel
                      ? Colors.white24
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Text(
                cat.toUpperCase(),
                style: TextStyle(
                  color: isSel ? Colors.white : Colors.white24,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ],
  );
}

Widget _subscriptionSheetActionButtons(
  BuildContext context,
  FinanceBlock financeBlock,
  bool isEdit,
  SubscriptionData? sub,
  TextEditingController n,
  TextEditingController a,
  int d,
  String c,
  String cy, {
  int? planYear,
  int? planMonth,
}) {
  final inPlanContext = planYear != null && planMonth != null;
  final l10n = AppLocalizations.of(context)!;
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
              await financeBlock.updateSubscription(
                id: sub!.id,
                name: n.text,
                amount: amount,
                billingDay: d,
                category: c,
                billingCycle: cy,
              );
            } else {
              await financeBlock.addSubscription(
                name: n.text,
                amount: amount,
                billingDay: d,
                category: c,
                billingCycle: cy,
              );
            }
            if (context.mounted) Navigator.pop(context);
          },
          style: FilledButton.styleFrom(
            backgroundColor: EntryColors.financeSilverAccent,
            padding: const EdgeInsets.symmetric(vertical: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text(
            isEdit ? "UPDATE SUBSCRIPTION" : "ESTABLISH SUBSCRIPTION",
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w900,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
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
                  title: Text(
                    inPlanContext
                        ? l10n.finance_subscriptions_next_month_remove_title
                        : "DELETE SUBSCRIPTION",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  content: Text(
                    inPlanContext
                        ? l10n.finance_subscriptions_next_month_remove_message
                        : "Are you sure you want to remove this recurring bill?",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text(
                        "CANCEL",
                        style: TextStyle(color: Colors.white24),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text(
                        inPlanContext ? l10n.finance_subscriptions_next_month_remove_confirm : "DELETE",
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                if (inPlanContext) {
                  await financeBlock.skipSubscriptionInPlanMonth(
                    sub!.id,
                    planYear,
                    planMonth,
                  );
                } else {
                  await financeBlock.deleteSubscription(sub!.id);
                }
                if (context.mounted) Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              inPlanContext
                  ? l10n.finance_subscriptions_next_month_remove_action
                  : "DELETE RECURRING BILL",
              style: const TextStyle(
                color: Colors.redAccent,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ],
  );
}

class SubscriptionManager extends StatelessWidget {
  final FinanceBlock financeBlock;

  const SubscriptionManager({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Watch((context) {
      final subs = financeBlock.subscriptions.value;
      final useVnd = financeBlock.useVnd.value;
      final monthlyTotal = financeBlock.monthlyBurnRate.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.finance_subscriptions_active_header,
                        style: TextStyle(
                          color: FinanceSurface.mutedInk(isDark: isDark),
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.finance_cat_subscriptions,
                        style: TextStyle(
                          color: FinanceSurface.ink(isDark: isDark),
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                if (subs.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l10n.finance_subscriptions_monthly_total,
                        style: TextStyle(
                          color: FinanceSurface.mutedInk(isDark: isDark),
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        financeBlock.formatCurrency(monthlyTotal),
                        style: TextStyle(
                          color: FinanceSurface.ink(isDark: isDark),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'JetBrainsMono',
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          if (subs.isEmpty)
            _buildEmptyState(context, isDark: isDark, cs: cs)
          else
            _SubscriptionCarousel(
              key: ValueKey(useVnd),
              subs: subs,
              cardBuilder: (ctx, sub) =>
                  _buildSubscriptionCard(ctx, sub, isDark: isDark, cs: cs),
            ),
          const SizedBox(height: 8),
          _NextMonthPlanSection(
            financeBlock: financeBlock,
            subs: subs,
            isDark: isDark,
            cs: cs,
          ),
        ],
      );
    });
  }

  Widget _buildEmptyState(
    BuildContext context, {
    required bool isDark,
    required ColorScheme cs,
  }) {
    return Container(
      width: double.infinity,
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 28),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.layers_clear_rounded,
              color: FinanceSurface.mutedInk(isDark: isDark),
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              "NO RECURRING BILLS",
              style: TextStyle(
                color: FinanceSurface.mutedInk(isDark: isDark),
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

  Widget _buildSubscriptionCard(
    BuildContext context,
    SubscriptionData sub, {
    required bool isDark,
    required ColorScheme cs,
  }) {
    final daysLeft = _calculateDaysLeft(sub);
    final isYearly = sub.billingCycle == 'yearly';

    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 16, bottom: 10, top: 10),
      decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 28),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: () =>
              showSubscriptionEditor(context, financeBlock, subscription: sub),
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
                        color: FinanceSurface.silverAccent()
                            .withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: FinanceSurface.border(isDark: isDark),
                        ),
                      ),
                      child: Icon(
                        _getCategoryIcon(sub.category ?? 'software'),
                        color: FinanceSurface.silverAccent(),
                        size: 16,
                      ),
                    ),
                    _buildCycleBadge(isYearly, isDark: isDark),
                  ],
                ),
                const Spacer(),
                Text(
                  sub.name.toUpperCase(),
                  style: TextStyle(
                    color: FinanceSurface.mutedInk(isDark: isDark),
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
                  style: TextStyle(
                    color: FinanceSurface.ink(isDark: isDark),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(height: 12),
                _buildCountdownBadge(context, daysLeft, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCycleBadge(bool isYearly, {required bool isDark}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: FinanceSurface.mutedInk(isDark: isDark).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: FinanceSurface.border(isDark: isDark)),
      ),
      child: Text(
        isYearly ? "Y" : "M",
        style: TextStyle(
          color: FinanceSurface.mutedInk(isDark: isDark),
          fontSize: 8,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCountdownBadge(
    BuildContext context,
    int days, {
    required bool isDark,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final bool isSoon = days <= 3;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isSoon
            ? Colors.red.withValues(alpha: 0.1)
            : FinanceSurface.mutedInk(isDark: isDark).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSoon
              ? Colors.red.withValues(alpha: 0.25)
              : FinanceSurface.border(isDark: isDark),
        ),
      ),
      child: Text(
        days == 0
            ? l10n.finance_subscription_due_today
            : l10n.finance_subscription_days_left(days),
        style: TextStyle(
          color: isSoon
              ? Colors.redAccent
              : FinanceSurface.mutedInk(isDark: isDark),
          fontSize: 8,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  int _calculateDaysLeft(SubscriptionData sub) {
    final today = DateTime.now();
    final due = subscriptionNextBillingDate(sub);
    return due.difference(DateTime(today.year, today.month, today.day)).inDays;
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
}

/// Upcoming charges in the next calendar month (planning view).
class _NextMonthPlanSection extends StatelessWidget {
  const _NextMonthPlanSection({
    required this.financeBlock,
    required this.subs,
    required this.isDark,
    required this.cs,
  });

  final FinanceBlock financeBlock;
  final List<SubscriptionData> subs;
  final bool isDark;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final planYear = now.month == 12 ? now.year + 1 : now.year;
    final planMonth = now.month == 12 ? 1 : now.month + 1;
    final planSkips = financeBlock.subscriptionPlanSkips.value;
    final items = subscriptionsDueInMonth(
      subs,
      planYear,
      planMonth,
      planSkips: planSkips,
    );
    final monthLabel = DateFormat.yMMMM().format(DateTime(planYear, planMonth));
    final planTotal = items.fold<double>(0, (sum, e) => sum + e.sub.amount);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.finance_subscriptions_next_month_header,
                      style: TextStyle(
                        color: FinanceSurface.mutedInk(isDark: isDark),
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      monthLabel,
                      style: TextStyle(
                        color: FinanceSurface.ink(isDark: isDark),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.finance_subscriptions_next_month_total,
                      style: TextStyle(
                        color: FinanceSurface.mutedInk(isDark: isDark),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      financeBlock.formatCurrency(planTotal),
                      style: TextStyle(
                        color: FinanceSurface.ink(isDark: isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'JetBrainsMono',
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Text(
              l10n.finance_subscriptions_next_month_empty,
              style: TextStyle(
                color: FinanceSurface.mutedInk(isDark: isDark),
                fontSize: 12,
                height: 1.35,
              ),
            )
          else
            Container(
              decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 20),
              padding: const EdgeInsets.all(8),
              child: Column(
                children: items
                    .map(
                      (entry) => _NextMonthPlanRow(
                        financeBlock: financeBlock,
                        sub: entry.sub,
                        due: entry.due,
                        planYear: planYear,
                        planMonth: planMonth,
                        isDark: isDark,
                        cs: cs,
                      ),
                    )
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextMonthPlanRow extends StatelessWidget {
  const _NextMonthPlanRow({
    required this.financeBlock,
    required this.sub,
    required this.due,
    required this.planYear,
    required this.planMonth,
    required this.isDark,
    required this.cs,
  });

  final FinanceBlock financeBlock;
  final SubscriptionData sub;
  final DateTime due;
  final int planYear;
  final int planMonth;
  final bool isDark;
  final ColorScheme cs;

  Future<void> _confirmRemoveFromPlan(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16161E),
        title: Text(
          l10n.finance_subscriptions_next_month_remove_title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
        content: Text(
          l10n.finance_subscriptions_next_month_remove_message,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              "CANCEL",
              style: TextStyle(color: Colors.white24),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              l10n.finance_subscriptions_next_month_remove_confirm,
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await financeBlock.skipSubscriptionInPlanMonth(sub.id, planYear, planMonth);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final dueLabel = DateFormat.MMMd(locale).format(due);

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => showSubscriptionEditor(
            context,
            financeBlock,
            subscription: sub,
            planYear: planYear,
            planMonth: planMonth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sub.name,
                        style: TextStyle(
                          color: FinanceSurface.ink(isDark: isDark),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dueLabel,
                        style: TextStyle(
                          color: FinanceSurface.mutedInk(isDark: isDark),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  financeBlock.formatCurrency(sub.amount),
                  style: TextStyle(
                    color: FinanceSurface.ink(isDark: isDark),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    fontFamily: 'JetBrainsMono',
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: l10n.finance_subscriptions_next_month_remove_tooltip,
                  onPressed: () => _confirmRemoveFromPlan(context),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: FinanceSurface.mutedInk(isDark: isDark),
                  ),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal subscription strip with a right-edge "›" when more cards are off-screen.
class _SubscriptionCarousel extends StatefulWidget {
  final List<SubscriptionData> subs;
  final Widget Function(BuildContext context, SubscriptionData sub) cardBuilder;

  const _SubscriptionCarousel({
    super.key,
    required this.subs,
    required this.cardBuilder,
  });

  @override
  State<_SubscriptionCarousel> createState() => _SubscriptionCarouselState();
}

class _SubscriptionCarouselState extends State<_SubscriptionCarousel> {
  final ScrollController _controller = ScrollController();
  bool _moreOnRight = false;

  static const _bg = EntryColors.deepGlacier;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_syncMoreHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncMoreHint());
  }

  @override
  void didUpdateWidget(_SubscriptionCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subs.length != widget.subs.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncMoreHint());
    }
  }

  void _syncMoreHint() {
    if (!mounted) return;
    if (!_controller.hasClients) return;
    final p = _controller.position;
    final maxExtent = p.maxScrollExtent;
    final show = maxExtent > 8 && p.pixels < maxExtent - 8;
    if (show != _moreOnRight) {
      setState(() => _moreOnRight = show);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_syncMoreHint);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ListView.builder(
            controller: _controller,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.subs.length,
            itemBuilder: (context, index) {
              return widget.cardBuilder(context, widget.subs[index]);
            },
          ),
          if (_moreOnRight)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: IgnorePointer(
                child: Container(
                  width: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0x000D0D12),
                        _bg,
                      ],
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      '›',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 22,
                        fontWeight: FontWeight.w200,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
