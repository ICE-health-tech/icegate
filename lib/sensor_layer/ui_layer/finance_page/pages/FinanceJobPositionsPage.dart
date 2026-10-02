import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/animation_page/components/EntryConstants.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FinanceSurface.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/FixedIncomeManager.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/JobPositionManager.dart';
import 'package:intl/intl.dart';
import 'package:signals_flutter/signals_flutter.dart';

class FinanceJobPositionsPage extends StatefulWidget {
  final FinanceBlock financeBlock;

  const FinanceJobPositionsPage({super.key, required this.financeBlock});

  @override
  State<FinanceJobPositionsPage> createState() =>
      _FinanceJobPositionsPageState();
}

class _FinanceJobPositionsPageState extends State<FinanceJobPositionsPage> {
  @override
  void initState() {
    super.initState();
    widget.financeBlock.sync().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final financeBlock = widget.financeBlock;
    final wide = MediaQuery.sizeOf(context).width >= 900;

    final mainColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JobPositionManager(financeBlock: financeBlock),
        const SizedBox(height: 24),
        Watch((context) {
          return FixedIncomeManager(financeBlock: financeBlock);
        }),
        const SizedBox(height: 24),
        _BonusSection(financeBlock: financeBlock),
      ],
    );

    final dashboard = _TotalIncomeCard(financeBlock: financeBlock);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // LAYOUT: desktop = content left, income dashboard right;
          // phone = dashboard below the sections.
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainColumn),
                const SizedBox(width: 24),
                SizedBox(width: 340, child: dashboard),
              ],
            )
          else ...[
            mainColumn,
            const SizedBox(height: 24),
            dashboard,
          ],
          const SizedBox(height: 120),
        ],
      ),
    );
  }
}

class _BonusSection extends StatelessWidget {
  final FinanceBlock financeBlock;
  const _BonusSection({required this.financeBlock});

  void _showEditor(
    BuildContext context, {
    RecurringIncomeData? item,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = item != null;
    final nameController = TextEditingController(
      text: item?.description ?? '',
    );
    final amountController = TextEditingController(
      text: isEdit
          ? financeBlock
              .convertToDisplay(item.amount)
              .toStringAsFixed(financeBlock.useVnd.value ? 0 : 2)
          : '',
    );
    var selectedCategory = item?.category ?? 'contract';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            decoration: BoxDecoration(
              color: Theme.of(ctx).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
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
                    (isEdit
                            ? l10n.finance_fixed_income_edit
                            : l10n.finance_fixed_income_new)
                        .toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: l10n.finance_fixed_income_name,
                      prefixIcon:
                          const Icon(Icons.description_outlined, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      prefixIcon:
                          const Icon(Icons.attach_money_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SegmentedButton<String>(
                    segments: [
                      ButtonSegment(
                        value: 'bonus',
                        label: Text(l10n.finance_cat_bonus),
                        icon: const Icon(Icons.card_giftcard_rounded, size: 16),
                      ),
                      const ButtonSegment(
                        value: 'contract',
                        label: Text('Contract'),
                        icon: Icon(Icons.description_outlined, size: 16),
                      ),
                    ],
                    selected: {selectedCategory},
                    onSelectionChanged: (v) =>
                        setState(() => selectedCategory = v.first),
                  ),
                  if (isEdit) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final ok = await showDialog<bool>(
                          context: ctx,
                          builder: (dlg) => AlertDialog(
                            title: Text(l10n.delete),
                            content: Text(
                              l10n.finance_fixed_income_delete_confirm,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dlg, false),
                                child: Text(l10n.cancel),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dlg, true),
                                child: Text(
                                  l10n.delete,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                        if (ok != true || !ctx.mounted) return;
                        await financeBlock.deleteRecurringIncome(item.id);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: Text(l10n.delete),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) return;
                      final stored = financeBlock.convertToBase(amount);
                      final label = nameController.text.trim().isEmpty
                          ? selectedCategory
                          : nameController.text.trim();

                      if (isEdit) {
                        await financeBlock.deleteRecurringIncome(item.id);
                      }
                      await financeBlock.addRecurringIncome(
                        category: selectedCategory,
                        amount: stored,
                        description: label,
                        interval: 'once',
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
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFmt = DateFormat.yMMMd(l10n.localeName);

    return Watch((context) {
      final oneTimeItems = financeBlock.recurringIncomes.value
          .where((i) => i.category == 'bonus' || i.category == 'contract')
          .toList();
      final total = oneTimeItems.fold(0.0, (sum, i) => sum + i.amount);

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
                      l10n.finance_bonus_section_title.toUpperCase(),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.finance_bonus_section_subtitle,
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              if (oneTimeItems.isNotEmpty) ...[
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      l10n.finance_bonus_section_total.toUpperCase(),
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      financeBlock.formatCurrency(total, compact: true),
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (oneTimeItems.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: FinanceSurface.panel(cs, isDark: isDark, radius: 24),
              child: Center(
                child: Text(
                  l10n.finance_bonus_section_empty.toUpperCase(),
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            )
          else
            ...oneTimeItems.map((item) {
              final label = (item.description?.trim().isNotEmpty ?? false)
                  ? item.description!.trim()
                  : item.category;
              final isBonus = item.category == 'bonus';
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GestureDetector(
                  onTap: () => _showEditor(context, item: item),
                  child: Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.delete_outline,
                        color: Colors.redAccent,
                      ),
                    ),
                    confirmDismiss: (_) async {
                      return await showDialog<bool>(
                        context: context,
                        builder: (dlg) => AlertDialog(
                          title: Text(l10n.delete),
                          content: Text(
                            l10n.finance_fixed_income_delete_confirm,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dlg, false),
                              child: Text(l10n.cancel),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(dlg, true),
                              child: Text(
                                l10n.delete,
                                style:
                                    const TextStyle(color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                    onDismissed: (_) {
                      financeBlock.deleteRecurringIncome(item.id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration:
                          FinanceSurface.panel(cs, isDark: isDark, radius: 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: (isBonus
                                      ? Colors.amberAccent
                                      : Colors.cyanAccent)
                                  .withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isBonus
                                  ? Icons.card_giftcard_rounded
                                  : Icons.description_outlined,
                              color: isBonus
                                  ? Colors.amberAccent
                                  : Colors.cyanAccent,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  label.toUpperCase(),
                                  style: TextStyle(
                                    color: cs.onSurface,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dateFmt.format(item.createdAt.toLocal()),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            financeBlock.formatCurrency(
                              item.amount,
                              compact: true,
                            ),
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: cs.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
        ],
      );
    });
  }
}

class _TotalIncomeCard extends StatelessWidget {
  final FinanceBlock financeBlock;
  const _TotalIncomeCard({required this.financeBlock});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Watch((context) {
      final allIncomes = financeBlock.recurringIncomes.value;
      // Same classification as the sections above (category or interval),
      // and recurring is the normalized monthly total — one source of truth.
      final recurringTotal = financeBlock.monthlyFixedIncome.value;
      final oneTimeTotal = allIncomes
          .where(FinanceBlock.isOneTimeIncome)
          .fold(0.0, (sum, i) => sum + i.amount);
      final grandTotal = recurringTotal + oneTimeTotal;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              EntryColors.financeSilverAccent.withValues(alpha: 0.15),
              EntryColors.financeSilverAccent.withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: EntryColors.financeSilverAccent.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.finance_total_income_title.toUpperCase(),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              financeBlock.formatCurrency(grandTotal, compact: true),
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 28,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _incomeStat(
                  label: l10n.finance_total_income_recurring,
                  value: financeBlock.formatCurrency(recurringTotal, compact: true),
                  icon: Icons.autorenew_rounded,
                  color: Colors.greenAccent,
                  cs: cs,
                ),
                const SizedBox(width: 24),
                _incomeStat(
                  label: l10n.finance_total_income_onetime,
                  value: financeBlock.formatCurrency(oneTimeTotal, compact: true),
                  icon: Icons.bolt_rounded,
                  color: Colors.amberAccent,
                  cs: cs,
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _incomeStat({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required ColorScheme cs,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 8,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: cs.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
