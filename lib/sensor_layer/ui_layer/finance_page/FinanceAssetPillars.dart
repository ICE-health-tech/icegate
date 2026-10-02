import 'package:flutter/material.dart';
import 'package:ice_gate/data_layer/Protocol/User/FinanceProtocols.dart';
import 'package:ice_gate/l10n/app_localizations.dart';

/// Asset-side layers (liquidity → cashflow). Human capital is inflow-only, not net worth.
abstract final class FinanceAssetPillar {
  static const liquidity = 'liquidity';
  static const fixedIncome = 'fixed_income';
  static const investment = 'investment';
  static const cashflow = 'cashflow';

  static const ordered = [liquidity, fixedIncome, investment, cashflow];

  static String? pillarForAssetCategory(String? category) {
    if (category == null || category.isEmpty) return null;
    switch (category.toLowerCase()) {
      case 'bond':
      case 'deposit':
      case 'savings':
        return fixedIncome;
      case 'stock':
      case 'crypto':
      case 'real_estate':
      case 'real estate':
        return investment;
      case 'saas':
      case 'cashflow':
      case 'business':
        return cashflow;
      default:
        return investment;
    }
  }

  static String? pillarForAccountType(String? accountType) {
    if (accountType == null || accountType.isEmpty) return liquidity;
    switch (accountType.toLowerCase()) {
      case 'savings':
      case 'deposit':
        return fixedIncome;
      case 'investment':
        return investment;
      case 'cash':
      case 'checking':
      case 'credit_card':
      default:
        return liquidity;
    }
  }

  static String label(AppLocalizations l10n, String pillar) {
    switch (pillar) {
      case liquidity:
        return l10n.finance_asset_pillar_liquidity;
      case fixedIncome:
        return l10n.finance_asset_pillar_fixed_income;
      case investment:
        return l10n.finance_asset_pillar_investment;
      case cashflow:
        return l10n.finance_asset_pillar_cashflow;
      default:
        return pillar;
    }
  }

  static IconData icon(String pillar) {
    switch (pillar) {
      case liquidity:
        return Icons.account_balance_wallet_rounded;
      case fixedIncome:
        return Icons.savings_rounded;
      case investment:
        return Icons.candlestick_chart_rounded;
      case cashflow:
        return Icons.loop_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  static Map<String, double> sumByPillar({
    required List<FinancialAccountProtocol> accounts,
    required List<AssetProtocol> assets,
  }) {
    final totals = {for (final p in ordered) p: 0.0};
    for (final acc in accounts) {
      if (!acc.isActive) continue;
      final pillar = pillarForAccountType(acc.accountType) ?? liquidity;
      totals[pillar] = (totals[pillar] ?? 0) + acc.balance;
    }
    for (final asset in assets) {
      final value = asset.currentEstimatedValue ?? 0.0;
      if (value <= 0) continue;
      final pillar = pillarForAssetCategory(asset.assetCategory) ?? investment;
      totals[pillar] = (totals[pillar] ?? 0) + value;
    }
    return totals;
  }
}

/// Asset categories stored in [AssetsTableCompanion.assetCategory].
abstract final class FinanceAssetCategories {
  static const stock = 'stock';
  static const crypto = 'crypto';
  static const bond = 'bond';
  static const deposit = 'deposit';
  static const realEstate = 'real_estate';
  static const cashflow = 'cashflow';

  static const investment = [stock, crypto, realEstate];
  static const fixedIncome = [bond, deposit];
  static const cashflowAssets = [cashflow];

  static String label(AppLocalizations l10n, String key) {
    switch (key) {
      case stock:
        return l10n.finance_asset_cat_stock;
      case crypto:
        return l10n.finance_asset_cat_crypto;
      case bond:
        return l10n.finance_asset_cat_bond;
      case deposit:
        return l10n.finance_asset_cat_deposit;
      case realEstate:
        return l10n.finance_asset_cat_real_estate;
      case cashflow:
        return l10n.finance_asset_cat_cashflow;
      default:
        return key;
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case stock:
        return Icons.show_chart_rounded;
      case crypto:
        return Icons.currency_bitcoin_rounded;
      case bond:
        return Icons.account_balance_rounded;
      case deposit:
        return Icons.savings_rounded;
      case realEstate:
        return Icons.home_work_rounded;
      case cashflow:
        return Icons.hub_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }
}
