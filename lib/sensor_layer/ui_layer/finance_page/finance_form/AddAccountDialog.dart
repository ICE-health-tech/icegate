import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/DataSources/local_database/Database.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/PersonBlock.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;

extension CurrencyTypeExtension on CurrencyType {
  String get symbol {
    switch (this) {
      case CurrencyType.USD:
        return '\$';
      case CurrencyType.EUR:
        return '€';
      case CurrencyType.VND:
        return '₫';
      case CurrencyType.JPY:
        return '¥';
      case CurrencyType.GBP:
        return '£';
      case CurrencyType.CNY:
        return '¥';
    }
  }

  String get displayName => name;
}

class AddAccountDialog extends StatefulWidget {
  final FinancialAccountProtocol? account;
  final String? initialAccountType;

  const AddAccountDialog({
    super.key,
    this.account,
    this.initialAccountType,
  });

  static Future<void> show(
    BuildContext context, {
    FinancialAccountProtocol? account,
    String? initialAccountType,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddAccountDialog(
        account: account,
        initialAccountType: initialAccountType,
      ),
    );
  }

  @override
  State<AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends State<AddAccountDialog> {
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  String _selectedType = 'checking';
  CurrencyType _selectedCurrency = CurrencyType.USD;

  bool get _isEdit => widget.account != null;

  String? _resolveAccountId(FinanceBlock financeBlock) {
    final a = widget.account;
    if (a == null) return null;
    if (a.financialAccountID.isNotEmpty) return a.financialAccountID;
    for (final row in financeBlock.accounts.value) {
      if (row.accountName == a.accountName && row.accountType == a.accountType) {
        if (row.financialAccountID.isNotEmpty) return row.financialAccountID;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      _nameController.text = a.accountName;
      _balanceController.text = a.balance.toString();
      _selectedType = a.accountType;
      _selectedCurrency = CurrencyType.values.firstWhere(
        (e) => e.name == a.currency,
        orElse: () => CurrencyType.USD,
      );
    } else if (widget.initialAccountType != null) {
      _selectedType = widget.initialAccountType!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  Future<void> _saveAccount() async {
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

    final financeBlock = context.read<FinanceBlock>();

    try {
      if (_isEdit) {
        final id = _resolveAccountId(financeBlock);
        if (id == null) {
          _showSnackBar(
            "Could not find this account. Pull to refresh and try again.",
            isError: true,
          );
          return;
        }
        await financeBlock.updateAccount(
          id: id,
          accountName: name,
          accountType: _selectedType,
          balance: balance,
          currency: _selectedCurrency,
        );
        if (!mounted) return;
        _showSnackBar("Account updated");
      } else {
        await context.read<AppDatabase>().financeDAO.createAccount(
          FinancialAccountsTableCompanion.insert(
            id: IDGen.UUIDV7(),
            personID: drift.Value(personID),
            accountName: name,
            accountType: drift.Value(_selectedType),
            balance: drift.Value(balance),
            currency: drift.Value(_selectedCurrency),
          ),
        );
        await financeBlock.refreshFromLocalDatabase();
        if (!mounted) return;
        _showSnackBar("Account '$name' created successfully");
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar("Failed to save account: $e", isError: true);
    }
  }

  Future<void> _confirmDelete() async {
    if (!_isEdit) return;
    final financeBlock = context.read<FinanceBlock>();
    final id = _resolveAccountId(financeBlock);
    if (id == null) {
      _showSnackBar("Could not find this account to delete.", isError: true);
      return;
    }
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: const Text(
          'Remove this account from your liquid assets?',
        ),
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
    if (ok != true || !mounted) return;

    try {
      await financeBlock.deleteAccount(id);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar("Failed to delete account: $e", isError: true);
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
        backgroundColor:
            isError ? colorScheme.error : colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  static String accountTypeLabel(AppLocalizations l10n, String type) {
    switch (type) {
      case 'checking':
        return l10n.finance_account_type_checking;
      case 'savings':
        return l10n.finance_account_type_savings;
      case 'cash':
        return l10n.finance_account_type_cash;
      case 'credit_card':
        return l10n.finance_account_type_credit_card;
      case 'deposit':
        return l10n.finance_account_type_deposit;
      case 'investment':
        return l10n.finance_account_type_investment;
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isInvestment = _selectedType == 'investment';

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
                      isInvestment
                          ? Icons.candlestick_chart_rounded
                          : Icons.account_balance_wallet_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _isEdit
                          ? l10n.finance_add_account_title
                          : l10n.finance_add_account_title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                      ),
                    ),
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
                        hintText: isInvestment
                            ? l10n.finance_account_investment_name_hint
                            : "e.g. Main Wallet",
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
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: "Balance",
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
                    Text(
                      l10n.finance_account_type_section,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTypeChip(
                          l10n,
                          "checking",
                          Icons.account_balance_rounded,
                        ),
                        _buildTypeChip(
                          l10n,
                          "savings",
                          Icons.savings_rounded,
                        ),
                        _buildTypeChip(
                          l10n,
                          "cash",
                          Icons.payments_rounded,
                        ),
                        _buildTypeChip(
                          l10n,
                          "credit_card",
                          Icons.credit_card_rounded,
                        ),
                        _buildTypeChip(
                          l10n,
                          "deposit",
                          Icons.lock_clock_rounded,
                        ),
                        _buildTypeChip(
                          l10n,
                          "investment",
                          Icons.candlestick_chart_rounded,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (_isEdit) ...[
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _confirmDelete,
                          icon: const Icon(Icons.delete_outline),
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
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _saveAccount,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _isEdit ? "Update" : "Save Account",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildTypeChip(
    AppLocalizations l10n,
    String value,
    IconData icon,
  ) {
    final isSelected = _selectedType == value;
    final colorScheme = Theme.of(context).colorScheme;
    final label = accountTypeLabel(l10n, value);

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
      backgroundColor:
          colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide.none,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
