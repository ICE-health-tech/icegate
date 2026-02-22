import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ice_shield/ui_layer/finance_page/models/FinanceAsset.dart';

class FinanceService {
  static const empty = FinanceAsset(
    id: '',
    name: 'Unknown',
    symbol: '---',
    price: 0.0,
    change24h: 0.0,
    icon: Icons.error_outline,
    color: Colors.grey,
    type: AssetType.stock,
    sparkline: [0, 0],
  );
  static List<FinanceAsset> getStocks() {
    return [
      const FinanceAsset(
        id: 'aapl',
        name: 'Apple Inc.',
        symbol: 'AAPL',
        price: 185.92,
        change24h: 1.25,
        icon: Icons.apple,
        color: Colors.grey,
        type: AssetType.stock,
        sparkline: [180, 182, 181, 184, 186, 185, 185.92],
      ),
      const FinanceAsset(
        id: 'tsla',
        name: 'Tesla, Inc.',
        symbol: 'TSLA',
        price: 238.45,
        change24h: -2.41,
        icon: Icons.electric_car,
        color: Colors.red,
        type: AssetType.stock,
        sparkline: [250, 245, 248, 240, 235, 237, 238.45],
      ),
      const FinanceAsset(
        id: 'nvda',
        name: 'NVIDIA Corp.',
        symbol: 'NVDA',
        price: 547.10,
        change24h: 3.12,
        icon: Icons.memory,
        color: Colors.green,
        type: AssetType.stock,
        sparkline: [520, 525, 530, 540, 535, 545, 547.10],
      ),
      const FinanceAsset(
        id: 'googl',
        name: 'Alphabet Inc.',
        symbol: 'GOOGL',
        price: 142.65,
        change24h: 0.85,
        icon: Icons.search,
        color: Colors.blue,
        type: AssetType.stock,
        sparkline: [140, 141, 139, 142, 143, 142, 142.65],
      ),
    ];
  }

  static List<FinanceAsset> getCoins() {
    return [
      const FinanceAsset(
        id: 'btc',
        name: 'Bitcoin',
        symbol: 'BTC',
        price: 43250.00,
        change24h: 2.15,
        icon: Icons.currency_bitcoin,
        color: Colors.orange,
        type: AssetType.crypto,
        sparkline: [42000, 42500, 42200, 43000, 42800, 43100, 43250],
      ),
      const FinanceAsset(
        id: 'eth',
        name: 'Ethereum',
        symbol: 'ETH',
        price: 2580.45,
        change24h: 1.84,
        icon: Icons.currency_bitcoin,
        color: Colors.indigo,
        type: AssetType.crypto,
        sparkline: [2500, 2520, 2510, 2550, 2540, 2570, 2580.45],
      ),
      const FinanceAsset(
        id: 'sol',
        name: 'Solana',
        symbol: 'SOL',
        price: 98.12,
        change24h: -4.20,
        icon: Icons.waves,
        color: Colors.teal,
        type: AssetType.crypto,
        sparkline: [105, 102, 100, 95, 96, 97, 98.12],
      ),
    ];
  }

  static double getTotalBalance() {
    return 124500.52;
  }

  static double getTotalChange() {
    return 1850.25;
  }

  static double getTotalChangePercentage() {
    return 1.48;
  }

  static Future<FinanceAsset> fetchVnStock(String ticker) async {
    final url = Uri.parse(
      'https://tcinvest.tcbs.com.vn/v1/stock/stats/$ticker',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        if (response.body.trim().startsWith('<!doctype html>')) {
          debugPrint('Error fetching $ticker: Received HTML instead of JSON');
          return empty;
        }
        final data = json.decode(response.body);

        // Mapping TCBS data to your FinanceAsset model
        return FinanceAsset(
          id: ticker.toLowerCase(),
          name: ticker, // You can fetch company names from a separate mapping
          symbol: ticker.toUpperCase(),
          price: (data['lastPrice'] as num).toDouble(),
          change24h: (data['pcp'] as num).toDouble(),
          icon: Icons.show_chart,
          color: (data['pcp'] >= 0) ? Colors.green : Colors.red,
          type: AssetType.stock,
          // TCBS provides recent price history in other endpoints for the sparkline
          sparkline: [data['referencePrice'], data['lastPrice']],
        );
      }
    } catch (e) {
      debugPrint('Error fetching $ticker: $e');
    }
    return empty;
  }
}
