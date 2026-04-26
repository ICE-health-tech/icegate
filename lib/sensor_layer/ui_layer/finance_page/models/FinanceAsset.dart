import 'package:flutter/material.dart';

enum AssetType { stock, crypto }

class FinanceAsset {
  final String id;
  final String name;
  final String symbol;
  final double price;
  final double change24h;
  final IconData icon;
  final Color color;
  final AssetType type;
  final List<double> sparkline;

  const FinanceAsset({
    required this.id,
    required this.name,
    required this.symbol,
    required this.price,
    required this.change24h,
    required this.icon,
    required this.color,
    required this.type,
    this.sparkline = const [],
  });
}
