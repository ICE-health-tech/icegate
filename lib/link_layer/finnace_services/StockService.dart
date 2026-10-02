import 'package:ice_gate/sensor_layer/ui_layer/stock_page/models/StockData.dart';

/// Remote stock price / history fetching is disabled — UI uses local labels and transaction data only.
class StockService {
  static final StockService _instance = StockService._internal();
  factory StockService() => _instance;
  StockService._internal();

  Future<StockPrice?> fetchStockPrice(String symbol,
      {int retries = 3, bool forceRefresh = false}) async {
    return null;
  }

  Future<StockOverview?> fetchStockOverview(String symbol) async {
    return null;
  }

  Future<StockHistoricalData?> fetchHistoricalData(
    String symbol, {
    String startDate = '2024-01-01',
    String? endDate,
    String resolution = '1D',
    bool forceRefresh = false,
  }) async {
    return null;
  }

  Future<StockFullInfo?> fetchAllStockInfo(String symbol,
      {int retries = 3, bool forceRefresh = false}) async {
    return null;
  }

  Future<List<StockFullInfo>> fetchMultipleStocks(List<String> symbols) async {
    return [];
  }

  void clearCache() {}

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
