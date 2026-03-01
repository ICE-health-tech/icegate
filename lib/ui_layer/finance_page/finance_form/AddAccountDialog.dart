import 'package:flutter/material.dart';
import 'package:ice_shield/data_layer/DataSources/local_database/Database.dart';
import 'package:provider/provider.dart';
import 'package:ice_shield/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_shield/orchestration_layer/IDGen.dart';
import 'package:drift/drift.dart' as drift;

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'checking'; // checking, savings, cash, credit_card
  CurrencyType _selectedCurrency = CurrencyType.USD;

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _saveAccount() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final personID = context.read<PersonBlock>().currentPersonID.value;

    if (personID == null) return;

    context.read<AppDatabase>().financeDAO.createAccount(
      FinancialAccountsTableCompanion.insert(
        id: IDGen.UUIDV7(),
        personID: personID,
        accountName: name,
        accountType: drift.Value(_selectedType),
        balance: drift.Value(balance),
        currency: drift.Value(_selectedCurrency),
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
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Add Account",
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
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Account Name",
                        hintText: "e.g. Main Wallet",
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest
                            .withOpacity(0.3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        prefixIcon: const Icon(Icons.edit_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _balanceController,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Initial Balance",
                              hintText: "0.00",
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest
                                  .withOpacity(0.3),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              prefixIcon: const Icon(
                                Icons.attach_money_rounded,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest
                                .withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<CurrencyType>(
                              value: _selectedCurrency,
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _selectedCurrency = val);
                                }
                              },
                              items: CurrencyType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      "Account Type",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeChip("checking", "Checking"),
                        _buildTypeChip("savings", "Savings"),
                        _buildTypeChip("cash", "Cash"),
                        _buildTypeChip("credit_card", "Credit"),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      height: 52,
                      child: FilledButton(
                        onPressed: _saveAccount,
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          "Save Account",
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

  Widget _buildTypeChip(String value, String label) {
    final isSelected = _selectedType == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedType = value);
        }
      },
      labelStyle: TextStyle(
        fontWeight: FontWeight.bold,
        color: isSelected
            ? colorScheme.onPrimary
            : colorScheme.onSurfaceVariant,
      ),
      selectedColor: colorScheme.primary,
      backgroundColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
