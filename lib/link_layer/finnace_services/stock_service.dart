import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ice_gate/sensor_layer/ui_layer/stock_page/models/stock_data.dart';

class StockService {
  static const String baseUrl = 'https://vnstock.finance.duylong.art';

  Future<StockPrice?> fetchStockPrice(String symbol, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/stock/price?symbol=$symbol')).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          if (json.containsKey('symbol')) return StockPrice.fromJson(json);
          if (json.containsKey('price') && json['price'] is Map<String, dynamic>) return StockPrice.fromJson(json['price']);
          if (json.containsKey('data')) return StockPrice.fromJson(json['data']);
        }
      } catch (e, stack) {
        if (i == retries - 1) {
          print("StockService Error after $retries retries for $symbol: $e");
          print(stack);
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
  }) async {
    try {
      var url = '$baseUrl/stock/historical?symbol=$symbol&start_date=$startDate&resolution=$resolution';
      if (endDate != null) url += '&end_date=$endDate';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return StockHistoricalData.fromJson(json);
      }
    } catch (e) {
      print("StockService Error: $e");
    }
    return null;
  }

  Future<StockFullInfo?> fetchAllStockInfo(String symbol, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        final response = await http.get(Uri.parse('$baseUrl/stock/all?symbol=$symbol')).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body);
          return StockFullInfo.fromJson(json);
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
