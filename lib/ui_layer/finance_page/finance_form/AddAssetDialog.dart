import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_shield/ui_layer/finance_page/models/FinanceAsset.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:drift/drift.dart' as drift;

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _priceController = TextEditingController();
  AssetType _selectedType = AssetType.stock;

  @override
  void dispose() {
    _symbolController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _saveAsset() {
    final symbol = _symbolController.text.trim().toUpperCase();
    if (symbol.isEmpty) return;

    final quantity = double.tryParse(_quantityController.text) ?? 0.0;
    final price = double.tryParse(_priceController.text) ?? 0.0;
    final personID = context.read<PersonBlock>().currentPersonID.value;

    if (personID == null) return;

    context.read<AppDatabase>().financeDAO.createAsset(
      AssetsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: personID,
        assetName: symbol,
        assetCategory: _selectedType.name,
        currentEstimatedValue: drift.Value(quantity * price),
        currency: drift.Value(CurrencyType.USD), // Default to USD for now
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
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
                      Icons.show_chart_rounded,
                      color: colorScheme.tertiary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Add Investment",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                  const Spacer(),
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
                    // Type Selection
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withOpacity(
                          0.5,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          _buildTypeTab(
                            AssetType.stock,
                            "Stock",
                            Icons.business,
                          ),
                          _buildTypeTab(
                            AssetType.crypto,
                            "Crypto",
                            Icons.currency_bitcoin,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextField(
                      controller: _symbolController,
                      textCapitalization: TextCapitalization.characters,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Symbol / Ticker",
                        hintText: _selectedType == AssetType.stock
                            ? "e.g. AAPL, VNM"
                            : "e.g. BTC, ETH",
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              hintText: "0.0",
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Avg Price",
                              hintText: "0.0",
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.attach_money_rounded,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saveAsset,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.tertiary,
                          foregroundColor: colorScheme.onTertiary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Add Holding",
                          style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildTypeTab(AssetType type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
