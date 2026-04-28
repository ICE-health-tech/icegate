import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/database.dart';
import 'package:provider/provider.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:drift/drift.dart' as drift;

extension CurrencyTypeExtension on CurrencyType {
  String get symbol {
    switch (this) {
      case CurrencyType.USD: return '\$';
      case CurrencyType.EUR: return '€';
      case CurrencyType.VND: return '₫';
      case CurrencyType.JPY: return '¥';
      case CurrencyType.GBP: return '£';
      case CurrencyType.CNY: return '¥';
    }
  }

  String get displayName => name;
}

class AddAccountDialog extends StatefulWidget {
  const AddAccountDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => const AddAccountDialog(),
    );
  }

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
    if (name.isEmpty) {
      _showSnackBar("Please enter an account name", isError: true);
      return;
    }

    final balanceText = _balanceController.text.trim();
    final balance = double.tryParse(balanceText) ?? 0.0;
    
    if (balanceText.isNotEmpty && double.tryParse(balanceText) == null) {
      _showSnackBar("Please enter a valid balance", isError: true);
      return;
    }

    final personID = context.read<PersonBlock>().currentPersonID.value;

    if (personID == null) {
      _showSnackBar("Authentication error. Please try again.", isError: true);
      return;
    }

    try {
      context.read<AppDatabase>().financeDAO.createAccount(
        FinancialAccountsTableCompanion.insert(
          id: IDGen.UUIDV7(),
          personID: drift.Value(personID),
          accountName: name,
          accountType: drift.Value(_selectedType),
          balance: drift.Value(balance),
          currency: drift.Value(_selectedCurrency),
        ),
      );

      _showSnackBar("Account '$name' created successfully");
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar("Failed to save account: $e", isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            color: isError ? colorScheme.onError : colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: isError ? colorScheme.error : colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
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
              color: Colors.black.withValues(alpha: 0.2),
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
                            .withValues(alpha: 0.3),
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
                                  .withValues(alpha: 0.3),
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
                                .withValues(alpha: 0.3),
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
                                    "${type.symbol} ${type.name}",
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
                        _buildTypeChip("checking", "Checking", Icons.account_balance_rounded),
                        _buildTypeChip("savings", "Savings", Icons.savings_rounded),
                        _buildTypeChip("cash", "Cash", Icons.payments_rounded),
                        _buildTypeChip("credit_card", "Credit", Icons.credit_card_rounded),
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

  Widget _buildTypeChip(String value, String label, IconData icon) {
    final isSelected = _selectedType == value;
    final colorScheme = Theme.of(context).colorScheme;

    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? colorScheme.onPrimary : colorScheme.primary,
      ),
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
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
