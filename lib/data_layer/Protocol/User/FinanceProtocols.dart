class FinancialAccountProtocol {
  final String financialAccountID;
  final String personID;
  final String accountName;
  final String accountType;
  final double balance;
  final String currency;
  final bool isPrimary;
  final bool isActive;

  FinancialAccountProtocol({
    required this.financialAccountID,
    required this.personID,
    required this.accountName,
    this.accountType = 'checking',
    this.balance = 0.0,
    this.currency = 'USD',
    this.isPrimary = false,
    this.isActive = true,
  });
}

class AssetProtocol {
  final String id;
  final String personId;
  final String assetName;
  final String assetCategory;
  final DateTime? purchaseDate;
  final double? purchasePrice;
  final double? currentEstimatedValue;
  final String currency;
  final String condition;
  final String? location;
  final String? notes;
  final bool isInsured;

  AssetProtocol({
    required this.id,
    required this.personId,
    required this.assetName,
    required this.assetCategory,
    this.purchaseDate,
    this.purchasePrice,
    this.currentEstimatedValue,
    this.currency = 'USD',
    this.condition = 'good',
    this.location,
    this.notes,
    this.isInsured = false,
  });
}
