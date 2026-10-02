// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'StockData.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StockPriceImpl _$$StockPriceImplFromJson(Map<String, dynamic> json) =>
    _$StockPriceImpl(
      symbol: json['symbol'] as String,
      price: (json['price'] as num).toDouble(),
      change: (json['change'] as num).toDouble(),
      changePercent: (json['change_percent'] as num).toDouble(),
      volume: (json['volume'] as num).toInt(),
      high: (json['high'] as num?)?.toDouble(),
      low: (json['low'] as num?)?.toDouble(),
      time: json['time'],
    );

Map<String, dynamic> _$$StockPriceImplToJson(_$StockPriceImpl instance) =>
    <String, dynamic>{
      'symbol': instance.symbol,
      'price': instance.price,
      'change': instance.change,
      'change_percent': instance.changePercent,
      'volume': instance.volume,
      'high': instance.high,
      'low': instance.low,
      'time': instance.time,
    };

_$CompanyOverviewImpl _$$CompanyOverviewImplFromJson(
  Map<String, dynamic> json,
) => _$CompanyOverviewImpl(
  businessModel: json['business_model'] as String?,
  ceoName: json['ceo_name'] as String?,
  website: json['website'] as String?,
  foundedDate: json['founded_date'] as String?,
  address: json['address'] as String?,
  history: json['history'] as String?,
);

Map<String, dynamic> _$$CompanyOverviewImplToJson(
  _$CompanyOverviewImpl instance,
) => <String, dynamic>{
  'business_model': instance.businessModel,
  'ceo_name': instance.ceoName,
  'website': instance.website,
  'founded_date': instance.foundedDate,
  'address': instance.address,
  'history': instance.history,
};

_$StockOverviewImpl _$$StockOverviewImplFromJson(Map<String, dynamic> json) =>
    _$StockOverviewImpl(
      symbol: json['symbol'] as String,
      overview:
          (json['overview'] as List<dynamic>?)
              ?.map((e) => CompanyOverview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$StockOverviewImplToJson(_$StockOverviewImpl instance) =>
    <String, dynamic>{'symbol': instance.symbol, 'overview': instance.overview};

_$StockHistoricalEntryImpl _$$StockHistoricalEntryImplFromJson(
  Map<String, dynamic> json,
) => _$StockHistoricalEntryImpl(
  time: json['time'] as String,
  open: (json['open'] as num?)?.toDouble(),
  high: (json['high'] as num?)?.toDouble(),
  low: (json['low'] as num?)?.toDouble(),
  close: (json['close'] as num?)?.toDouble(),
  volume: (json['volume'] as num?)?.toInt(),
  ticker: json['ticker'] as String?,
);

Map<String, dynamic> _$$StockHistoricalEntryImplToJson(
  _$StockHistoricalEntryImpl instance,
) => <String, dynamic>{
  'time': instance.time,
  'open': instance.open,
  'high': instance.high,
  'low': instance.low,
  'close': instance.close,
  'volume': instance.volume,
  'ticker': instance.ticker,
};

_$StockHistoricalDataImpl _$$StockHistoricalDataImplFromJson(
  Map<String, dynamic> json,
) => _$StockHistoricalDataImpl(
  symbol: json['symbol'] as String,
  source: json['source'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => StockHistoricalEntry.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$$StockHistoricalDataImplToJson(
  _$StockHistoricalDataImpl instance,
) => <String, dynamic>{
  'symbol': instance.symbol,
  'source': instance.source,
  'data': instance.data,
};

_$StockFullInfoImpl _$$StockFullInfoImplFromJson(Map<String, dynamic> json) =>
    _$StockFullInfoImpl(
      price: StockPrice.fromJson(json['price'] as Map<String, dynamic>),
      company: StockOverview.fromJson(json['company'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$StockFullInfoImplToJson(_$StockFullInfoImpl instance) =>
    <String, dynamic>{'price': instance.price, 'company': instance.company};
