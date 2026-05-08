import 'package:flutter/material.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:signals_flutter/signals_flutter.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/widgets/finance_currency_toggle.dart';

class TransactionBuilderDialog extends StatefulWidget {
  final TransactionData? initialData;
  final String? preferredType;
  final FinanceBlock financeBlock;

  const TransactionBuilderDialog({
    super.key,
    this.initialData,
    this.preferredType,
    required this.financeBlock,
  });

  static Future<void> show(
    BuildContext context, {
    TransactionData? initialData,
    String? preferredType,
    required FinanceBlock financeBlock,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TransactionBuilderDialog(
        initialData: initialData,
        preferredType: preferredType,
        financeBlock: financeBlock,
      ),
    );
  }

  @override
  State<TransactionBuilderDialog> createState() =>
      _TransactionBuilderDialogState();
}

class _TransactionBuilderDialogState extends State<TransactionBuilderDialog> {
  final amountController = TextEditingController();
  final descController = TextEditingController();
  late String selectedType;
  late String selectedCategory;

  final categories = {
    'expense': [
      'food',
      'coffee',
      'transport',
      'software',
      'shopping',
      'bills',
      'rent',
      'subscriptions',
      'entertainment',
      'health',
      'education',
      'investing',
      'general',
    ],
    'income': ['salary', 'freelance', 'investment', 'gift', 'bonus', 'general'],
    'savings': [
      'emergency',
      'goal',
      'retirement',
      'investment',
      'impulse',
      'general',
    ],
  };

  @override
  void initState() {
    super.initState();
    final fb = widget.financeBlock;
    if (widget.initialData != null) {
      final displayAmount =
          fb.convertToDisplay(widget.initialData!.amount);
      amountController.text = fb.useVnd.peek()
          ? displayAmount.toStringAsFixed(0)
          : displayAmount.toStringAsFixed(2);
      descController.text = widget.initialData!.description ?? '';
      selectedType = widget.initialData!.type;
      selectedCategory = widget.initialData!.category;
    } else {
      selectedType = widget.preferredType ?? 'expense';
      selectedCategory = 'general';
    }
  }

  @override
  void dispose() {
    amountController.dispose();
    descController.dispose();
    super.dispose();
  }

  String _getCategoryName(AppLocalizations l10n, String category) {
    switch (category) {
      case 'food':
        return l10n.finance_cat_food;
      case 'coffee':
        return l10n.finance_cat_coffee;
      case 'transport':
        return l10n.finance_cat_transport;
      case 'software':
        return l10n.finance_cat_software;
      case 'shopping':
        return l10n.finance_cat_shopping;
      case 'bills':
        return l10n.finance_cat_bills;
      case 'rent':
        return l10n.finance_cat_rent;
      case 'subscriptions':
        return l10n.finance_cat_subscriptions;
      case 'entertainment':
        return l10n.finance_cat_entertainment;
      case 'health':
        return l10n.finance_cat_health;
      case 'education':
        return l10n.finance_cat_education;
      case 'investing':
        return l10n.finance_cat_investing;
      case 'general':
        return l10n.finance_cat_general;
      case 'salary':
        return l10n.finance_cat_salary;
      case 'freelance':
        return l10n.finance_cat_freelance;
      case 'investment':
        return l10n.finance_cat_investment;
      case 'gift':
        return l10n.finance_cat_gift;
      case 'bonus':
        return l10n.finance_cat_bonus;
      case 'emergency':
        return l10n.finance_cat_emergency;
      case 'goal':
        return l10n.finance_cat_goal;
      case 'retirement':
        return l10n.finance_cat_retirement;
      case 'impulse':
        return l10n.finance_cat_impulse;
      default:
        return category.isNotEmpty
            ? category[0].toUpperCase() + category.substring(1)
            : category;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEdit = widget.initialData != null;

    return AlertDialog(
      title: Text(
        isEdit ? l10n.edit : l10n.finance_add_transaction,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isEdit)
              FittedBox(
                child: SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'expense',
                      label: Text(l10n.finance_type_expense,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 'income',
                      label: Text(l10n.finance_type_income,
                          style: const TextStyle(fontSize: 12)),
                    ),
                    ButtonSegment(
                      value: 'savings',
                      label: Text(l10n.finance_type_savings,
                          style: const TextStyle(fontSize: 12)),
                    ),
                  ],
                  selected: {selectedType},
                  onSelectionChanged: (val) {
                    setState(() {
                      selectedType = val.first;
                      selectedCategory = 'general';
                    });
                  },
                ),
              ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FinanceInlineCurrencyToggle(
                financeBlock: widget.financeBlock,
                onTap: () => toggleFinanceCurrencyWithAmountField(
                  financeBlock: widget.financeBlock,
                  amountController: amountController,
                  setState: setState,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Watch((context) {
              final useVnd = widget.financeBlock.useVnd.value;
              return TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  labelText: l10n.finance_label_amount,
                  labelStyle: const TextStyle(fontSize: 12),
                  prefixText: !useVnd ? '\$ ' : null,
                  suffixText: useVnd ? ' ₫' : null,
                  border: const OutlineInputBorder(),
                ),
              );
            }),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: InputDecoration(
                labelText: l10n.finance_label_category,
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
              ),
              items: (categories[selectedType] ?? ['general'])
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(_getCategoryName(l10n, c),
                          style: const TextStyle(fontSize: 14)),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setState(
                () => selectedCategory = val ?? 'general',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: l10n.finance_label_description_optional,
                labelStyle: const TextStyle(fontSize: 12),
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (isEdit)
          IconButton(
            onPressed: () async {
              await widget.financeBlock.deleteTransaction(widget.initialData!.id);
              if (context.mounted) Navigator.pop(context);
            },
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel, style: const TextStyle(fontSize: 14)),
        ),
        FilledButton(
          onPressed: () async {
            final rawAmount =
                double.tryParse(amountController.text.replaceFirst(',', '.'));
            if (rawAmount == null || rawAmount <= 0) return;
            final amount =
                widget.financeBlock.convertToBase(rawAmount);

            if (isEdit) {
              await widget.financeBlock.updateTransaction(
                id: widget.initialData!.id,
                category: selectedCategory,
                type: selectedType,
                amount: amount,
                description: descController.text,
                date: widget.initialData!.transactionDate,
                projectID: widget.initialData!.projectID,
                moodScore: widget.initialData!.moodScore,
              );
            } else {
              await widget.financeBlock.addTransaction(
                category: selectedCategory,
                type: selectedType,
                amount: amount,
                description:
                    descController.text.isEmpty ? null : descController.text,
              );
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: Text(isEdit ? l10n.edit : l10n.add,
              style: const TextStyle(fontSize: 14)),
        ),
      ],
    );
  }
}
