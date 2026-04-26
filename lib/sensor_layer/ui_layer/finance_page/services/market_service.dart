import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MarketService {
  static String get baseUrl => dotenv.env['VNSTOCK_BASE_URL'] ?? 'https://vnstock.finance.duylong.art';

  /// Fetches real-time gold prices
  static Future<List<Map<String, dynamic>>> fetchGoldPrices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/gold'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('MarketService Error (Gold): $e');
    }
    return [];
  }

  /// Fetches historical data for indices (e.g., VNINDEX, VN30, DJI)
  static Future<List<Map<String, dynamic>>> fetchIndexHistorical(String symbol) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/index/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('MarketService Error (Index): $e');
    }
    return [];
  }

  /// Fetches forex historical data
  static Future<List<Map<String, dynamic>>> fetchForexHistorical({String symbol = 'EURUSD'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/forex/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('MarketService Error (Forex): $e');
    }
    return [];
  }

  /// Fetches crypto historical data
  static Future<List<Map<String, dynamic>>> fetchCryptoHistorical({String symbol = 'BTC'}) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/crypto/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('MarketService Error (Crypto): $e');
    }
    return [];
  }

  /// Returns a list of all supported indices metadata
  static Future<List<Map<String, dynamic>>> fetchAllIndices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/market/indices'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      debugPrint('MarketService Error (Indices): $e');
    }
    return [];
  }
}
