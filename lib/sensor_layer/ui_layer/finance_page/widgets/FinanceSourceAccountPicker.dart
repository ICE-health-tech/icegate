import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';
import 'package:ice_gate/orchestration_layer/ReactiveBlock/User/FinanceBlock.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/FinanceAssetPillars.dart';
import 'package:ice_gate/sensor_layer/ui_layer/finance_page/finance_form/AddAccountDialog.dart';
import 'package:signals_flutter/signals_flutter.dart';

String _accountTypeLabel(AppLocalizations l10n, String type) {
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

/// Pick which wallet/account cash leaves when logging an expense or savings move.
class FinanceSourceAccountPicker extends StatelessWidget {
  final FinanceBlock financeBlock;
  final String? selectedAccountId;
  final ValueChanged<String?> onChanged;

  const FinanceSourceAccountPicker({
    super.key,
    required this.financeBlock,
    required this.selectedAccountId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Watch((context) {
      final active = financeBlock.accounts.value
          .where((a) => a.isActive)
          .toList()
        ..sort((a, b) => a.accountName.compareTo(b.accountName));

      if (active.isEmpty) {
        return InputDecorator(
          decoration: InputDecoration(
            labelText: l10n.finance_txn_source_account,
            labelStyle: const TextStyle(fontSize: 12),
            border: const OutlineInputBorder(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.finance_txn_source_account_empty,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.35,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => AddAccountDialog.show(context),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(l10n.finance_txn_source_account_add),
                ),
              ),
            ],
          ),
        );
      }

      final byPillar = <String, List<FinancialAccountProtocol>>{};
      for (final pillar in FinanceAssetPillar.ordered) {
        byPillar[pillar] = [];
      }
      for (final acc in active) {
        final pillar =
            FinanceAssetPillar.pillarForAccountType(acc.accountType) ??
                FinanceAssetPillar.liquidity;
        byPillar.putIfAbsent(pillar, () => []).add(acc);
      }

      final items = <DropdownMenuItem<String?>>[
        DropdownMenuItem<String?>(
          value: null,
          child: Text(
            l10n.finance_txn_source_account_none,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ];

      for (final pillar in FinanceAssetPillar.ordered) {
        final group = byPillar[pillar];
        if (group == null || group.isEmpty) continue;
        items.add(
          DropdownMenuItem<String?>(
            enabled: false,
            child: Text(
              FinanceAssetPillar.label(l10n, pillar).toUpperCase(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white.withValues(alpha: 0.35),
                letterSpacing: 0.8,
              ),
            ),
          ),
        );
        for (final acc in group) {
          final typeLabel = _accountTypeLabel(l10n, acc.accountType);
          items.add(
            DropdownMenuItem<String?>(
              value: acc.financialAccountID,
              child: Text(
                '${acc.accountName} · $typeLabel',
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        }
      }

      return DropdownButtonFormField<String?>(
        key: ValueKey(selectedAccountId),
        initialValue: selectedAccountId != null &&
                active.any((a) => a.financialAccountID == selectedAccountId)
            ? selectedAccountId
            : null,
        decoration: InputDecoration(
          labelText: l10n.finance_txn_source_account,
          labelStyle: const TextStyle(fontSize: 12),
          border: const OutlineInputBorder(),
        ),
        items: items,
        onChanged: onChanged,
      );
    });
  }
}
