import 'package:freezed_annotation/freezed_annotation.dart';

part 'stock_data.freezed.dart';
part 'stock_data.g.dart';

@freezed
class StockPrice with _$StockPrice {
  const factory StockPrice({
    required String symbol,
    required double price,
    required double change,
    @JsonKey(name: 'change_percent') required double changePercent,
    required int volume,
    double? high,
    double? low,
    dynamic time,
  }) = _StockPrice;

  factory StockPrice.fromJson(Map<String, dynamic> json) => _$StockPriceFromJson(json);
}

@freezed
class CompanyOverview with _$CompanyOverview {
  const factory CompanyOverview({
    @JsonKey(name: 'business_model') String? businessModel,
    @JsonKey(name: 'ceo_name') String? ceoName,
    String? website,
    @JsonKey(name: 'founded_date') String? foundedDate,
    String? address,
    String? history,
  }) = _CompanyOverview;

  factory CompanyOverview.fromJson(Map<String, dynamic> json) => _$CompanyOverviewFromJson(json);
}

@freezed
class StockOverview with _$StockOverview {
  const factory StockOverview({
    required String symbol,
    @Default([]) List<CompanyOverview> overview,
  }) = _StockOverview;

  factory StockOverview.fromJson(Map<String, dynamic> json) => _$StockOverviewFromJson(json);
}

@freezed
class StockHistoricalEntry with _$StockHistoricalEntry {
  const factory StockHistoricalEntry({
    required String time,
    double? open,
    double? high,
    double? low,
    double? close,
    int? volume,
    String? ticker,
  }) = _StockHistoricalEntry;

  factory StockHistoricalEntry.fromJson(Map<String, dynamic> json) => _$StockHistoricalEntryFromJson(json);
}

@freezed
class StockHistoricalData with _$StockHistoricalData {
  const factory StockHistoricalData({
    required String symbol,
    required String source,
    required List<StockHistoricalEntry> data,
  }) = _StockHistoricalData;

  factory StockHistoricalData.fromJson(Map<String, dynamic> json) => _$StockHistoricalDataFromJson(json);
}

@freezed
class StockFullInfo with _$StockFullInfo {
  const factory StockFullInfo({
    required StockPrice price,
    required StockOverview company,
  }) = _StockFullInfo;

  factory StockFullInfo.fromJson(Map<String, dynamic> json) => _$StockFullInfoFromJson(json);
}
