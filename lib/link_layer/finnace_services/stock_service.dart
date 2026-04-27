import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ice_gate/sensor_layer/ui_layer/stock_page/models/stock_data.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class CachedData<T> {
  final T data;
  final DateTime timestamp;
  CachedData(this.data, this.timestamp);
  bool isExpired(Duration ttl) => DateTime.now().difference(timestamp) > ttl;
}

class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  static String get baseUrl => dotenv.env['VNSTOCK_BASE_URL'] ?? 'https://vnstock.finance.duylong.art';

  // Caches
  final Map<String, CachedData<StockPrice>> _priceCache = {};
  final Map<String, CachedData<StockFullInfo>> _fullInfoCache = {};
  final Map<String, CachedData<StockHistoricalData>> _historicalCache = {};

  final Duration _cacheTTL = const Duration(minutes: 5);

  Future<StockPrice?> fetchStockPrice(String symbol, {int retries = 3, bool forceRefresh = false}) async {
    if (!forceRefresh && _priceCache.containsKey(symbol) && !_priceCache[symbol]!.isExpired(_cacheTTL)) {
      return _priceCache[symbol]!.data;
    }

    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/stock/price?symbol=$symbol')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          StockPrice price;
          if (json.containsKey('data')) {
            price = StockPrice.fromJson(json['data']);
          } else if (json.containsKey('price')) {
            price = StockPrice.fromJson(json['price']);
          } else {
            price = StockPrice.fromJson(json);
          }
          
          _priceCache[symbol] = CachedData(price, DateTime.now());
          return price;
        } else if (response.statusCode == 404 || response.statusCode == 500) {
          final errorJson = jsonDecode(response.body);
          print("StockService API Error for $symbol: ${errorJson['detail']}");
          return null;
        }
      } catch (e) {
        if (i == retries - 1) {
          print("StockService Network Error after $retries retries for $symbol: $e");
        }
        await Future.delayed(Duration(seconds: 1 * (i + 1))); // Exponential backoff
      }
    }
    return null;
  }

  Future<StockOverview?> fetchStockOverview(String symbol) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/stock/overview?symbol=$symbol'));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return StockOverview.fromJson(json);
      }
    } catch (e) {
      print("StockService Error: $e");
    }
    return null;
  }

  Future<StockHistoricalData?> fetchHistoricalData(
    String symbol, {
    String startDate = '2024-01-01',
    String? endDate,
    String resolution = '1D',
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$symbol-$startDate-$endDate-$resolution';
    if (!forceRefresh && _historicalCache.containsKey(cacheKey) && !_historicalCache[cacheKey]!.isExpired(const Duration(hours: 1))) {
      return _historicalCache[cacheKey]!.data;
    }

    try {
      var url = '$baseUrl/stock/historical?symbol=$symbol&start_date=$startDate&resolution=$resolution';
      if (endDate != null) url += '&end_date=$endDate';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final data = StockHistoricalData.fromJson(json);
        _historicalCache[cacheKey] = CachedData(data, DateTime.now());
        return data;
      }
    } catch (e) {
      print("StockService Error: $e");
    }
    return null;
  }

  Future<StockFullInfo?> fetchAllStockInfo(String symbol, {int retries = 3, bool forceRefresh = false}) async {
    if (!forceRefresh && _fullInfoCache.containsKey(symbol) && !_fullInfoCache[symbol]!.isExpired(_cacheTTL)) {
      return _fullInfoCache[symbol]!.data;
    }

    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/stock/all?symbol=$symbol')).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          final info = StockFullInfo.fromJson(json);
          _fullInfoCache[symbol] = CachedData(info, DateTime.now());
          
          // Also update price cache as it's included in full info
          _priceCache[symbol] = CachedData(info.price, DateTime.now());
          
          return info;
        }
      } catch (e, stack) {
        if (i == retries - 1) {
          print("StockService Error after $retries retries for all info $symbol: $e");
          print(stack);
        }
        await Future.delayed(Duration(seconds: 1 * (i + 1))); // Exponential backoff
      }
    }
    return null;
  }

  Future<List<StockFullInfo>> fetchMultipleStocks(List<String> symbols) async {
    final futures = symbols.map((s) => fetchAllStockInfo(s));
    final results = await Future.wait(futures);
    return results.whereType<StockFullInfo>().toList();
  }

  void clearCache() {
    _priceCache.clear();
    _fullInfoCache.clear();
    _historicalCache.clear();
  }

  String getStockName(String ticker) {
    const names = {
      'VNM': 'Vinamilk',
      'FPT': 'FPT Corporation',
      'VCB': 'Vietcombank',
      'VIC': 'Vingroup',
      'VHM': 'Vinhomes',
      'HPG': 'Hoa Phat Group',
      'GAS': 'PetroVietnam Gas',
      'MSN': 'Masan Group',
      'MWG': 'Mobile World',
      'SSI': 'SSI Securities',
      'TCB': 'Techcombank',
      'MBB': 'MB Bank',
      'ACB': 'ACB Bank',
      'VPB': 'VPBank',
      'STB': 'Sacombank',
      'HDB': 'HDBank',
      'CTG': 'VietinBank',
      'POW': 'PV Power',
      'PLX': 'Petrolimex',
      'BVH': 'Bao Viet',
      'VRE': 'Vincom Retail',
      'TPB': 'TPBank',
      'GVR': 'Vietnam Rubber',
      'SAB': 'Sabeco',
      'BCM': 'Becamex',
      'VJC': 'Vietjet Air',
    };
    return names[ticker.toUpperCase()] ?? '';
  }
}
