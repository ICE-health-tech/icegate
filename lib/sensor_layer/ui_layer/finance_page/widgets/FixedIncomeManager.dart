import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceInflowPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinancePage.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceCurrencyToggle.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceEntryInsightPanel.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

void showFixedIncomeEditor(
  BuildContext context,
  FinanceBlock financeBlock, {
  RecurringIncomeData? income,
  String? initialCategory,
}) {
  final l10n = AppLocalizations.of(context)!;
  final isEdit = income != null;
  final nameController = TextEditingController(
    text: income?.description ?? income?.category ?? '',
  );

  String initialAmount = '';
  if (income != null) {
    initialAmount = financeBlock
        .convertToDisplay(income.amount)
        .toStringAsFixed(financeBlock.useVnd.value ? 0 : 2);
  }
  final amountController = TextEditingController(text: initialAmount);
  String selectedCategory =
      income?.category ?? initialCategory ?? 'human_capital';
  String selectedInterval = income?.interval ?? 'monthly';

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Watch((context) {
      final useVnd = financeBlock.useVnd.value;
      return StatefulBuilder(
        builder: (ctx, setState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              decoration: const BoxDecoration(
                color: EntryColors.deepGlacier,
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
              ),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  const SizedBox(height: 20),
                  Text(
                    isEdit
                        ? l10n.finance_fixed_income_edit.toUpperCase()
                        : l10n.finance_fixed_income_new.toUpperCase(),
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
                  const SizedBox(height: 12),
                  _field(
                    nameController,
                    l10n.finance_fixed_income_name,
                    Icons.payments_rounded,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    amountController,
                    l10n.amount,
                    Icons.attach_money_rounded,
                    numeric: true,
                    prefix: !useVnd ? '\$ ' : null,
                    suffix: useVnd ? ' ₫' : null,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _intervalPicker(
                    selectedInterval,
                    l10n,
                    (v) => setState(() => selectedInterval = v),
                  ),
                  const SizedBox(height: 12),
                  _categoryPicker(
                    selectedCategory,
                    l10n,
                    (v) => setState(() => selectedCategory = v),
                  ),
                  const SizedBox(height: 16),
                  FinanceEntryInsightPanel(
                    insight: buildFixedIncomeInsight(
                      l10n: l10n,
                      block: financeBlock,
                      draftAmountBase: _parseDraftAmount(
                        financeBlock,
                        amountController.text,
                      ),
                      interval: selectedInterval,
                      category: selectedCategory,
                      editing: income,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () async {
                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;
                      final stored = financeBlock.convertToBase(amount);
                      final label = nameController.text.trim().isEmpty
                          ? FinancePage.getCategoryName(
                              l10n,
                              selectedCategory,
                            )
                          : nameController.text.trim();

                      if (isEdit) {
                        await financeBlock.deleteRecurringIncome(income.id);
                      }
                      await financeBlock.addRecurringIncome(
                        category: selectedCategory,
                        amount: stored,
                        description: label,
                        interval: selectedInterval,
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      isEdit ? l10n.done : l10n.add.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              ),
            ),
          );
        },
      );
    }),
  );
}

double? _parseDraftAmount(FinanceBlock block, String text) {
  final raw = double.tryParse(text.replaceAll(',', '.').trim());
  if (raw == null || raw <= 0) return null;
  return block.convertToBase(raw);
}

Widget _field(
  TextEditingController controller,
  String label,
  IconData icon, {
  bool numeric = false,
  String? prefix,
  String? suffix,
  ValueChanged<String>? onChanged,
}) {
  return TextField(
    controller: controller,
    onChanged: onChanged,
    keyboardType: numeric
        ? const TextInputType.numberWithOptions(decimal: true)
        : TextInputType.text,
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    decoration: InputDecoration(
      labelText: label.toUpperCase(),
      labelStyle: const TextStyle(
        color: Colors.white24,
        fontSize: 10,
        fontWeight: FontWeight.w900,
      ),
      prefixIcon: Icon(icon, color: Colors.white24, size: 18),
      prefixText: prefix,
      suffixText: suffix,
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.03),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    ),
  );
}

Widget _intervalPicker(
  String value,
  AppLocalizations l10n,
  ValueChanged<String> onChanged,
) {
  return _dropdown<String>(
    value: value,
    label: l10n.finance_recurring_interval,
    items: {
      'weekly': l10n.finance_interval_weekly,
      'monthly': l10n.finance_interval_monthly,
      'yearly': l10n.finance_interval_yearly,
    },
    onChanged: onChanged,
  );
}

Widget _categoryPicker(
  String value,
  AppLocalizations l10n,
  ValueChanged<String> onChanged,
) {
  return _dropdown<String>(
    value: financeIncomeCategoryKeys.contains(value)
        ? value
        : 'human_capital',
    label: l10n.finance_label_category,
    items: {
      for (final k in financeIncomeCategoryKeys)
        k: financeIncomeCategoryLabel(l10n, k),
    },
    onChanged: onChanged,
  );
}

Widget _dropdown<T>(
  {required T value,
  required String label,
  required Map<T, String> items,
  required ValueChanged<T> onChanged}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.03),
      borderRadius: BorderRadius.circular(16),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        dropdownColor: EntryColors.deepGlacier,
        items: items.entries
            .map(
              (e) => DropdownMenuItem(
                value: e.key,
                child: Text(
                  e.value,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            )
            .toList(),
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
      ),
    ),
  );
}

class FixedIncomeManager extends StatelessWidget {
  final FinanceBlock financeBlock;

  const FixedIncomeManager({super.key, required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat.MMMd(l10n.localeName);

    return Watch((context) {
      final items = financeBlock.recurringIncomes.value;
      final monthlyTotal = financeBlock.monthlyFixedIncome.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.finance_fixed_income_title.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.finance_fixed_income_subtitle,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.finance_fixed_income_monthly_total.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      financeBlock.formatCurrency(monthlyTotal, compact: true),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showFixedIncomeEditor(context, financeBlock),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: FinanceSurface.panel(
                    colorScheme,
                    isDark: isDark,
                    radius: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_rounded,
                        color: FinanceSurface.ink(isDark: isDark),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.finance_fixed_income_add.toUpperCase(),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (items.isEmpty)
            GestureDetector(
              onTap: () => showFixedIncomeEditor(context, financeBlock),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 28),
                decoration: FinanceSurface.panel(
                  colorScheme,
                  isDark: isDark,
                  radius: 24,
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      color: colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.finance_fixed_income_empty.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 118,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _IncomeCard(
                    item: item,
                    financeBlock: financeBlock,
                    dateFmt: dateFmt,
                    l10n: l10n,
                    colorScheme: colorScheme,
                    isDark: isDark,
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

class _IncomeCard extends StatelessWidget {
  final RecurringIncomeData item;
  final FinanceBlock financeBlock;
  final DateFormat dateFmt;
  final AppLocalizations l10n;
  final ColorScheme colorScheme;
  final bool isDark;

  const _IncomeCard({
    required this.item,
    required this.financeBlock,
    required this.dateFmt,
    required this.l10n,
    required this.colorScheme,
    required this.isDark,
  });

  String _intervalLabel(String interval) {
    switch (interval) {
      case 'weekly':
        return l10n.finance_interval_weekly;
      case 'yearly':
        return l10n.finance_interval_yearly;
      default:
        return l10n.finance_interval_monthly;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = (item.description?.trim().isNotEmpty ?? false)
        ? item.description!.trim()
        : FinancePage.getCategoryName(l10n, item.category);

    return Container(
      width: 168,
      decoration: FinanceSurface.panel(
        colorScheme,
        isDark: isDark,
        radius: 24,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => showFixedIncomeEditor(
            context,
            financeBlock,
            income: item,
          ),
          onLongPress: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(l10n.delete),
                    content: Text(l10n.finance_fixed_income_delete_confirm),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(l10n.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          l10n.delete,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await financeBlock.deleteRecurringIncome(item.id);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: FinanceSurface.silverAccent()
                                .withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.south_west_rounded,
                            color: FinanceSurface.silverAccent(),
                            size: 16,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _intervalLabel(item.interval).toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 8,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      title.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      financeBlock.formatCurrency(item.amount, compact: true),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.finance_fixed_income_next}: ${dateFmt.format(item.nextDueAt.toLocal())}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}
