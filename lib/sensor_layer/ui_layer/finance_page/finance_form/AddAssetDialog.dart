import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceAssetPillars.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key, this.initialCategory});

  final String? initialCategory;

  static Future<void> show(
    BuildContext context, {
    String? initialCategory,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddAssetDialog(initialCategory: initialCategory),
    );
  }

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _nameController = TextEditingController();
  final _valueController = TextEditingController();
  late String _selectedCategory;

  static const _allCategories = [
    FinanceAssetCategories.stock,
    FinanceAssetCategories.crypto,
    FinanceAssetCategories.bond,
    FinanceAssetCategories.deposit,
    FinanceAssetCategories.realEstate,
    FinanceAssetCategories.cashflow,
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory =
        widget.initialCategory ?? FinanceAssetCategories.stock;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _saveAsset() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final value = double.tryParse(_valueController.text.replaceAll(',', '.')) ?? 0.0;
    final personID = context.read<PersonBlock>().currentPersonID.value;
    if (personID == null) return;

    await context.read<AppDatabase>().financeDAO.createAsset(
      AssetsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: drift.Value(personID),
        assetName: name,
        assetCategory: _selectedCategory,
        currentEstimatedValue: drift.Value(value),
        currency: drift.Value(CurrencyType.USD),
      ),
    );
    await context.read<FinanceBlock>().refreshFromLocalDatabase();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final pillar = FinanceAssetPillar.pillarForAssetCategory(_selectedCategory);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      pillar != null
                          ? FinanceAssetPillar.icon(pillar)
                          : Icons.inventory_2_rounded,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      l10n.finance_add_asset_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.finance_add_asset_category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final cat in _allCategories)
                          _categoryChip(context, cat, l10n),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: l10n.finance_add_asset_name,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _valueController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: l10n.finance_add_asset_value,
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.attach_money_rounded),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saveAsset,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          l10n.finance_add_asset_save,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryChip(
    BuildContext context,
    String category,
    AppLocalizations l10n,
  ) {
    final cs = Theme.of(context).colorScheme;
    final selected = _selectedCategory == category;
    return FilterChip(
      selected: selected,
      label: Text(FinanceAssetCategories.label(l10n, category)),
      avatar: Icon(
        FinanceAssetCategories.icon(category),
        size: 16,
        color: selected ? cs.onPrimaryContainer : cs.onSurfaceVariant,
      ),
      onSelected: (_) => setState(() => _selectedCategory = category),
    );
  }
}
