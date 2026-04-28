import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class MarketCachedData<T> {
  final T data;
  final DateTime timestamp;
  MarketCachedData(this.data, this.timestamp);
  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}

class MarketService {
  static final MarketService _instance = MarketService._internal();
  factory MarketService() => _instance;
  MarketService._internal();

  static String get baseUrl => dotenv.env['VNSTOCK_BASE_URL'] ?? 'https://vnstock.finance.duylong.art';

  static final Map<String, MarketCachedData<List<Map<String, dynamic>>>> _cache = {};
  static const Duration _cacheTTL = Duration(minutes: 5);

  /// Fetches real-time gold prices
  static Future<List<Map<String, dynamic>>> fetchGoldPrices({bool forceRefresh = false}) async {
    const cacheKey = 'gold';
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired(_cacheTTL)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/market/gold'));
      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);
        List<dynamic> data;
        if (decoded is Map && decoded.containsKey('data')) {
          final dynamic rawData = decoded['data'];
          data = rawData is List ? rawData : [rawData];
        } else if (decoded is List) {
          data = decoded;
        } else {
          data = [decoded];
        }
        final result = data.whereType<Map<String, dynamic>>().toList();
        _cache[cacheKey] = MarketCachedData(result, DateTime.now());
        return result;
      }
    } catch (e) {
      debugPrint('MarketService Error (Gold): $e');
    }
    return _cache[cacheKey]?.data ?? [];
  }

  /// Fetches historical data for indices (e.g., VNINDEX, VN30, DJI)
  static Future<List<Map<String, dynamic>>> fetchIndexHistorical(String symbol, {bool forceRefresh = false}) async {
    final cacheKey = 'index_$symbol';
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired(_cacheTTL)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/market/index/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data.cast<Map<String, dynamic>>();
        _cache[cacheKey] = MarketCachedData(result, DateTime.now());
        return result;
      }
    } catch (e) {
      debugPrint('MarketService Error (Index): $e');
    }
    return _cache[cacheKey]?.data ?? [];
  }

  /// Fetches forex historical data
  static Future<List<Map<String, dynamic>>> fetchForexHistorical({String symbol = 'EURUSD', bool forceRefresh = false}) async {
    final cacheKey = 'forex_$symbol';
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired(_cacheTTL)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/forex/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data.cast<Map<String, dynamic>>();
        _cache[cacheKey] = MarketCachedData(result, DateTime.now());
        return result;
      }
    } catch (e) {
      debugPrint('MarketService Error (Forex): $e');
    }
    return _cache[cacheKey]?.data ?? [];
  }

  /// Fetches crypto historical data
  static Future<List<Map<String, dynamic>>> fetchCryptoHistorical({String symbol = 'BTC', bool forceRefresh = false}) async {
    final cacheKey = 'crypto_$symbol';
    if (!forceRefresh && _cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired(_cacheTTL)) {
      return _cache[cacheKey]!.data;
    }

    try {
      final response = await http.get(Uri.parse('$baseUrl/crypto/historical?symbol=$symbol'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final result = data.cast<Map<String, dynamic>>();
        _cache[cacheKey] = MarketCachedData(result, DateTime.now());
        return result;
      }
    } catch (e) {
      debugPrint('MarketService Error (Crypto): $e');
    }
    return _cache[cacheKey]?.data ?? [];
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
