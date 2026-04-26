// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'stock_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

StockPrice _$StockPriceFromJson(Map<String, dynamic> json) {
  return _StockPrice.fromJson(json);
}

/// @nodoc
mixin _$StockPrice {
  String get symbol => throw _privateConstructorUsedError;
  double get price => throw _privateConstructorUsedError;
  double get change => throw _privateConstructorUsedError;
  @JsonKey(name: 'change_percent')
  double get changePercent => throw _privateConstructorUsedError;
  int get volume => throw _privateConstructorUsedError;
  double? get high => throw _privateConstructorUsedError;
  double? get low => throw _privateConstructorUsedError;
  dynamic get time => throw _privateConstructorUsedError;

  /// Serializes this StockPrice to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockPrice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockPriceCopyWith<StockPrice> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockPriceCopyWith<$Res> {
  factory $StockPriceCopyWith(
    StockPrice value,
    $Res Function(StockPrice) then,
  ) = _$StockPriceCopyWithImpl<$Res, StockPrice>;
  @useResult
  $Res call({
    String symbol,
    double price,
    double change,
    @JsonKey(name: 'change_percent') double changePercent,
    int volume,
    double? high,
    double? low,
    dynamic time,
  });
}

/// @nodoc
class _$StockPriceCopyWithImpl<$Res, $Val extends StockPrice>
    implements $StockPriceCopyWith<$Res> {
  _$StockPriceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockPrice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? price = null,
    Object? change = null,
    Object? changePercent = null,
    Object? volume = null,
    Object? high = freezed,
    Object? low = freezed,
    Object? time = freezed,
  }) {
    return _then(
      _value.copyWith(
            symbol: null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                      as String,
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as double,
            change: null == change
                ? _value.change
                : change // ignore: cast_nullable_to_non_nullable
                      as double,
            changePercent: null == changePercent
                ? _value.changePercent
                : changePercent // ignore: cast_nullable_to_non_nullable
                      as double,
            volume: null == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as int,
            high: freezed == high
                ? _value.high
                : high // ignore: cast_nullable_to_non_nullable
                      as double?,
            low: freezed == low
                ? _value.low
                : low // ignore: cast_nullable_to_non_nullable
                      as double?,
            time: freezed == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as dynamic,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockPriceImplCopyWith<$Res>
    implements $StockPriceCopyWith<$Res> {
  factory _$$StockPriceImplCopyWith(
    _$StockPriceImpl value,
    $Res Function(_$StockPriceImpl) then,
  ) = __$$StockPriceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String symbol,
    double price,
    double change,
    @JsonKey(name: 'change_percent') double changePercent,
    int volume,
    double? high,
    double? low,
    dynamic time,
  });
}

/// @nodoc
class __$$StockPriceImplCopyWithImpl<$Res>
    extends _$StockPriceCopyWithImpl<$Res, _$StockPriceImpl>
    implements _$$StockPriceImplCopyWith<$Res> {
  __$$StockPriceImplCopyWithImpl(
    _$StockPriceImpl _value,
    $Res Function(_$StockPriceImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockPrice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? price = null,
    Object? change = null,
    Object? changePercent = null,
    Object? volume = null,
    Object? high = freezed,
    Object? low = freezed,
    Object? time = freezed,
  }) {
    return _then(
      _$StockPriceImpl(
        symbol: null == symbol
            ? _value.symbol
            : symbol // ignore: cast_nullable_to_non_nullable
                  as String,
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as double,
        change: null == change
            ? _value.change
            : change // ignore: cast_nullable_to_non_nullable
                  as double,
        changePercent: null == changePercent
            ? _value.changePercent
            : changePercent // ignore: cast_nullable_to_non_nullable
                  as double,
        volume: null == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as int,
        high: freezed == high
            ? _value.high
            : high // ignore: cast_nullable_to_non_nullable
                  as double?,
        low: freezed == low
            ? _value.low
            : low // ignore: cast_nullable_to_non_nullable
                  as double?,
        time: freezed == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as dynamic,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockPriceImpl implements _StockPrice {
  const _$StockPriceImpl({
    required this.symbol,
    required this.price,
    required this.change,
    @JsonKey(name: 'change_percent') required this.changePercent,
    required this.volume,
    this.high,
    this.low,
    this.time,
  });

  factory _$StockPriceImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockPriceImplFromJson(json);

  @override
  final String symbol;
  @override
  final double price;
  @override
  final double change;
  @override
  @JsonKey(name: 'change_percent')
  final double changePercent;
  @override
  final int volume;
  @override
  final double? high;
  @override
  final double? low;
  @override
  final dynamic time;

  @override
  String toString() {
    return 'StockPrice(symbol: $symbol, price: $price, change: $change, changePercent: $changePercent, volume: $volume, high: $high, low: $low, time: $time)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockPriceImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.change, change) || other.change == change) &&
            (identical(other.changePercent, changePercent) ||
                other.changePercent == changePercent) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            const DeepCollectionEquality().equals(other.time, time));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    price,
    change,
    changePercent,
    volume,
    high,
    low,
    const DeepCollectionEquality().hash(time),
  );

  /// Create a copy of StockPrice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockPriceImplCopyWith<_$StockPriceImpl> get copyWith =>
      __$$StockPriceImplCopyWithImpl<_$StockPriceImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockPriceImplToJson(this);
  }
}

abstract class _StockPrice implements StockPrice {
  const factory _StockPrice({
    required final String symbol,
    required final double price,
    required final double change,
    @JsonKey(name: 'change_percent') required final double changePercent,
    required final int volume,
    final double? high,
    final double? low,
    final dynamic time,
  }) = _$StockPriceImpl;

  factory _StockPrice.fromJson(Map<String, dynamic> json) =
      _$StockPriceImpl.fromJson;

  @override
  String get symbol;
  @override
  double get price;
  @override
  double get change;
  @override
  @JsonKey(name: 'change_percent')
  double get changePercent;
  @override
  int get volume;
  @override
  double? get high;
  @override
  double? get low;
  @override
  dynamic get time;

  /// Create a copy of StockPrice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockPriceImplCopyWith<_$StockPriceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

CompanyOverview _$CompanyOverviewFromJson(Map<String, dynamic> json) {
  return _CompanyOverview.fromJson(json);
}

/// @nodoc
mixin _$CompanyOverview {
  @JsonKey(name: 'business_model')
  String? get businessModel => throw _privateConstructorUsedError;
  @JsonKey(name: 'ceo_name')
  String? get ceoName => throw _privateConstructorUsedError;
  String? get website => throw _privateConstructorUsedError;
  @JsonKey(name: 'founded_date')
  String? get foundedDate => throw _privateConstructorUsedError;
  String? get address => throw _privateConstructorUsedError;
  String? get history => throw _privateConstructorUsedError;

  /// Serializes this CompanyOverview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of CompanyOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CompanyOverviewCopyWith<CompanyOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CompanyOverviewCopyWith<$Res> {
  factory $CompanyOverviewCopyWith(
    CompanyOverview value,
    $Res Function(CompanyOverview) then,
  ) = _$CompanyOverviewCopyWithImpl<$Res, CompanyOverview>;
  @useResult
  $Res call({
    @JsonKey(name: 'business_model') String? businessModel,
    @JsonKey(name: 'ceo_name') String? ceoName,
    String? website,
    @JsonKey(name: 'founded_date') String? foundedDate,
    String? address,
    String? history,
  });
}

/// @nodoc
class _$CompanyOverviewCopyWithImpl<$Res, $Val extends CompanyOverview>
    implements $CompanyOverviewCopyWith<$Res> {
  _$CompanyOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CompanyOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessModel = freezed,
    Object? ceoName = freezed,
    Object? website = freezed,
    Object? foundedDate = freezed,
    Object? address = freezed,
    Object? history = freezed,
  }) {
    return _then(
      _value.copyWith(
            businessModel: freezed == businessModel
                ? _value.businessModel
                : businessModel // ignore: cast_nullable_to_non_nullable
                      as String?,
            ceoName: freezed == ceoName
                ? _value.ceoName
                : ceoName // ignore: cast_nullable_to_non_nullable
                      as String?,
            website: freezed == website
                ? _value.website
                : website // ignore: cast_nullable_to_non_nullable
                      as String?,
            foundedDate: freezed == foundedDate
                ? _value.foundedDate
                : foundedDate // ignore: cast_nullable_to_non_nullable
                      as String?,
            address: freezed == address
                ? _value.address
                : address // ignore: cast_nullable_to_non_nullable
                      as String?,
            history: freezed == history
                ? _value.history
                : history // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$CompanyOverviewImplCopyWith<$Res>
    implements $CompanyOverviewCopyWith<$Res> {
  factory _$$CompanyOverviewImplCopyWith(
    _$CompanyOverviewImpl value,
    $Res Function(_$CompanyOverviewImpl) then,
  ) = __$$CompanyOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'business_model') String? businessModel,
    @JsonKey(name: 'ceo_name') String? ceoName,
    String? website,
    @JsonKey(name: 'founded_date') String? foundedDate,
    String? address,
    String? history,
  });
}

/// @nodoc
class __$$CompanyOverviewImplCopyWithImpl<$Res>
    extends _$CompanyOverviewCopyWithImpl<$Res, _$CompanyOverviewImpl>
    implements _$$CompanyOverviewImplCopyWith<$Res> {
  __$$CompanyOverviewImplCopyWithImpl(
    _$CompanyOverviewImpl _value,
    $Res Function(_$CompanyOverviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CompanyOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? businessModel = freezed,
    Object? ceoName = freezed,
    Object? website = freezed,
    Object? foundedDate = freezed,
    Object? address = freezed,
    Object? history = freezed,
  }) {
    return _then(
      _$CompanyOverviewImpl(
        businessModel: freezed == businessModel
            ? _value.businessModel
            : businessModel // ignore: cast_nullable_to_non_nullable
                  as String?,
        ceoName: freezed == ceoName
            ? _value.ceoName
            : ceoName // ignore: cast_nullable_to_non_nullable
                  as String?,
        website: freezed == website
            ? _value.website
            : website // ignore: cast_nullable_to_non_nullable
                  as String?,
        foundedDate: freezed == foundedDate
            ? _value.foundedDate
            : foundedDate // ignore: cast_nullable_to_non_nullable
                  as String?,
        address: freezed == address
            ? _value.address
            : address // ignore: cast_nullable_to_non_nullable
                  as String?,
        history: freezed == history
            ? _value.history
            : history // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$CompanyOverviewImpl implements _CompanyOverview {
  const _$CompanyOverviewImpl({
    @JsonKey(name: 'business_model') this.businessModel,
    @JsonKey(name: 'ceo_name') this.ceoName,
    this.website,
    @JsonKey(name: 'founded_date') this.foundedDate,
    this.address,
    this.history,
  });

  factory _$CompanyOverviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$CompanyOverviewImplFromJson(json);

  @override
  @JsonKey(name: 'business_model')
  final String? businessModel;
  @override
  @JsonKey(name: 'ceo_name')
  final String? ceoName;
  @override
  final String? website;
  @override
  @JsonKey(name: 'founded_date')
  final String? foundedDate;
  @override
  final String? address;
  @override
  final String? history;

  @override
  String toString() {
    return 'CompanyOverview(businessModel: $businessModel, ceoName: $ceoName, website: $website, foundedDate: $foundedDate, address: $address, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CompanyOverviewImpl &&
            (identical(other.businessModel, businessModel) ||
                other.businessModel == businessModel) &&
            (identical(other.ceoName, ceoName) || other.ceoName == ceoName) &&
            (identical(other.website, website) || other.website == website) &&
            (identical(other.foundedDate, foundedDate) ||
                other.foundedDate == foundedDate) &&
            (identical(other.address, address) || other.address == address) &&
            (identical(other.history, history) || other.history == history));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    businessModel,
    ceoName,
    website,
    foundedDate,
    address,
    history,
  );

  /// Create a copy of CompanyOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CompanyOverviewImplCopyWith<_$CompanyOverviewImpl> get copyWith =>
      __$$CompanyOverviewImplCopyWithImpl<_$CompanyOverviewImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$CompanyOverviewImplToJson(this);
  }
}

abstract class _CompanyOverview implements CompanyOverview {
  const factory _CompanyOverview({
    @JsonKey(name: 'business_model') final String? businessModel,
    @JsonKey(name: 'ceo_name') final String? ceoName,
    final String? website,
    @JsonKey(name: 'founded_date') final String? foundedDate,
    final String? address,
    final String? history,
  }) = _$CompanyOverviewImpl;

  factory _CompanyOverview.fromJson(Map<String, dynamic> json) =
      _$CompanyOverviewImpl.fromJson;

  @override
  @JsonKey(name: 'business_model')
  String? get businessModel;
  @override
  @JsonKey(name: 'ceo_name')
  String? get ceoName;
  @override
  String? get website;
  @override
  @JsonKey(name: 'founded_date')
  String? get foundedDate;
  @override
  String? get address;
  @override
  String? get history;

  /// Create a copy of CompanyOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CompanyOverviewImplCopyWith<_$CompanyOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StockOverview _$StockOverviewFromJson(Map<String, dynamic> json) {
  return _StockOverview.fromJson(json);
}

/// @nodoc
mixin _$StockOverview {
  String get symbol => throw _privateConstructorUsedError;
  List<CompanyOverview> get overview => throw _privateConstructorUsedError;

  /// Serializes this StockOverview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockOverviewCopyWith<StockOverview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockOverviewCopyWith<$Res> {
  factory $StockOverviewCopyWith(
    StockOverview value,
    $Res Function(StockOverview) then,
  ) = _$StockOverviewCopyWithImpl<$Res, StockOverview>;
  @useResult
  $Res call({String symbol, List<CompanyOverview> overview});
}

/// @nodoc
class _$StockOverviewCopyWithImpl<$Res, $Val extends StockOverview>
    implements $StockOverviewCopyWith<$Res> {
  _$StockOverviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? symbol = null, Object? overview = null}) {
    return _then(
      _value.copyWith(
            symbol: null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                      as String,
            overview: null == overview
                ? _value.overview
                : overview // ignore: cast_nullable_to_non_nullable
                      as List<CompanyOverview>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockOverviewImplCopyWith<$Res>
    implements $StockOverviewCopyWith<$Res> {
  factory _$$StockOverviewImplCopyWith(
    _$StockOverviewImpl value,
    $Res Function(_$StockOverviewImpl) then,
  ) = __$$StockOverviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String symbol, List<CompanyOverview> overview});
}

/// @nodoc
class __$$StockOverviewImplCopyWithImpl<$Res>
    extends _$StockOverviewCopyWithImpl<$Res, _$StockOverviewImpl>
    implements _$$StockOverviewImplCopyWith<$Res> {
  __$$StockOverviewImplCopyWithImpl(
    _$StockOverviewImpl _value,
    $Res Function(_$StockOverviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockOverview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? symbol = null, Object? overview = null}) {
    return _then(
      _$StockOverviewImpl(
        symbol: null == symbol
            ? _value.symbol
            : symbol // ignore: cast_nullable_to_non_nullable
                  as String,
        overview: null == overview
            ? _value._overview
            : overview // ignore: cast_nullable_to_non_nullable
                  as List<CompanyOverview>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockOverviewImpl implements _StockOverview {
  const _$StockOverviewImpl({
    required this.symbol,
    final List<CompanyOverview> overview = const [],
  }) : _overview = overview;

  factory _$StockOverviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockOverviewImplFromJson(json);

  @override
  final String symbol;
  final List<CompanyOverview> _overview;
  @override
  @JsonKey()
  List<CompanyOverview> get overview {
    if (_overview is EqualUnmodifiableListView) return _overview;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_overview);
  }

  @override
  String toString() {
    return 'StockOverview(symbol: $symbol, overview: $overview)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockOverviewImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            const DeepCollectionEquality().equals(other._overview, _overview));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    const DeepCollectionEquality().hash(_overview),
  );

  /// Create a copy of StockOverview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockOverviewImplCopyWith<_$StockOverviewImpl> get copyWith =>
      __$$StockOverviewImplCopyWithImpl<_$StockOverviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockOverviewImplToJson(this);
  }
}

abstract class _StockOverview implements StockOverview {
  const factory _StockOverview({
    required final String symbol,
    final List<CompanyOverview> overview,
  }) = _$StockOverviewImpl;

  factory _StockOverview.fromJson(Map<String, dynamic> json) =
      _$StockOverviewImpl.fromJson;

  @override
  String get symbol;
  @override
  List<CompanyOverview> get overview;

  /// Create a copy of StockOverview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockOverviewImplCopyWith<_$StockOverviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StockHistoricalEntry _$StockHistoricalEntryFromJson(Map<String, dynamic> json) {
  return _StockHistoricalEntry.fromJson(json);
}

/// @nodoc
mixin _$StockHistoricalEntry {
  String get time => throw _privateConstructorUsedError;
  double? get open => throw _privateConstructorUsedError;
  double? get high => throw _privateConstructorUsedError;
  double? get low => throw _privateConstructorUsedError;
  double? get close => throw _privateConstructorUsedError;
  int? get volume => throw _privateConstructorUsedError;
  String? get ticker => throw _privateConstructorUsedError;

  /// Serializes this StockHistoricalEntry to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockHistoricalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockHistoricalEntryCopyWith<StockHistoricalEntry> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockHistoricalEntryCopyWith<$Res> {
  factory $StockHistoricalEntryCopyWith(
    StockHistoricalEntry value,
    $Res Function(StockHistoricalEntry) then,
  ) = _$StockHistoricalEntryCopyWithImpl<$Res, StockHistoricalEntry>;
  @useResult
  $Res call({
    String time,
    double? open,
    double? high,
    double? low,
    double? close,
    int? volume,
    String? ticker,
  });
}

/// @nodoc
class _$StockHistoricalEntryCopyWithImpl<
  $Res,
  $Val extends StockHistoricalEntry
>
    implements $StockHistoricalEntryCopyWith<$Res> {
  _$StockHistoricalEntryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockHistoricalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? open = freezed,
    Object? high = freezed,
    Object? low = freezed,
    Object? close = freezed,
    Object? volume = freezed,
    Object? ticker = freezed,
  }) {
    return _then(
      _value.copyWith(
            time: null == time
                ? _value.time
                : time // ignore: cast_nullable_to_non_nullable
                      as String,
            open: freezed == open
                ? _value.open
                : open // ignore: cast_nullable_to_non_nullable
                      as double?,
            high: freezed == high
                ? _value.high
                : high // ignore: cast_nullable_to_non_nullable
                      as double?,
            low: freezed == low
                ? _value.low
                : low // ignore: cast_nullable_to_non_nullable
                      as double?,
            close: freezed == close
                ? _value.close
                : close // ignore: cast_nullable_to_non_nullable
                      as double?,
            volume: freezed == volume
                ? _value.volume
                : volume // ignore: cast_nullable_to_non_nullable
                      as int?,
            ticker: freezed == ticker
                ? _value.ticker
                : ticker // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockHistoricalEntryImplCopyWith<$Res>
    implements $StockHistoricalEntryCopyWith<$Res> {
  factory _$$StockHistoricalEntryImplCopyWith(
    _$StockHistoricalEntryImpl value,
    $Res Function(_$StockHistoricalEntryImpl) then,
  ) = __$$StockHistoricalEntryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String time,
    double? open,
    double? high,
    double? low,
    double? close,
    int? volume,
    String? ticker,
  });
}

/// @nodoc
class __$$StockHistoricalEntryImplCopyWithImpl<$Res>
    extends _$StockHistoricalEntryCopyWithImpl<$Res, _$StockHistoricalEntryImpl>
    implements _$$StockHistoricalEntryImplCopyWith<$Res> {
  __$$StockHistoricalEntryImplCopyWithImpl(
    _$StockHistoricalEntryImpl _value,
    $Res Function(_$StockHistoricalEntryImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockHistoricalEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? time = null,
    Object? open = freezed,
    Object? high = freezed,
    Object? low = freezed,
    Object? close = freezed,
    Object? volume = freezed,
    Object? ticker = freezed,
  }) {
    return _then(
      _$StockHistoricalEntryImpl(
        time: null == time
            ? _value.time
            : time // ignore: cast_nullable_to_non_nullable
                  as String,
        open: freezed == open
            ? _value.open
            : open // ignore: cast_nullable_to_non_nullable
                  as double?,
        high: freezed == high
            ? _value.high
            : high // ignore: cast_nullable_to_non_nullable
                  as double?,
        low: freezed == low
            ? _value.low
            : low // ignore: cast_nullable_to_non_nullable
                  as double?,
        close: freezed == close
            ? _value.close
            : close // ignore: cast_nullable_to_non_nullable
                  as double?,
        volume: freezed == volume
            ? _value.volume
            : volume // ignore: cast_nullable_to_non_nullable
                  as int?,
        ticker: freezed == ticker
            ? _value.ticker
            : ticker // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockHistoricalEntryImpl implements _StockHistoricalEntry {
  const _$StockHistoricalEntryImpl({
    required this.time,
    this.open,
    this.high,
    this.low,
    this.close,
    this.volume,
    this.ticker,
  });

  factory _$StockHistoricalEntryImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockHistoricalEntryImplFromJson(json);

  @override
  final String time;
  @override
  final double? open;
  @override
  final double? high;
  @override
  final double? low;
  @override
  final double? close;
  @override
  final int? volume;
  @override
  final String? ticker;

  @override
  String toString() {
    return 'StockHistoricalEntry(time: $time, open: $open, high: $high, low: $low, close: $close, volume: $volume, ticker: $ticker)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockHistoricalEntryImpl &&
            (identical(other.time, time) || other.time == time) &&
            (identical(other.open, open) || other.open == open) &&
            (identical(other.high, high) || other.high == high) &&
            (identical(other.low, low) || other.low == low) &&
            (identical(other.close, close) || other.close == close) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.ticker, ticker) || other.ticker == ticker));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, time, open, high, low, close, volume, ticker);

  /// Create a copy of StockHistoricalEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockHistoricalEntryImplCopyWith<_$StockHistoricalEntryImpl>
  get copyWith =>
      __$$StockHistoricalEntryImplCopyWithImpl<_$StockHistoricalEntryImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StockHistoricalEntryImplToJson(this);
  }
}

abstract class _StockHistoricalEntry implements StockHistoricalEntry {
  const factory _StockHistoricalEntry({
    required final String time,
    final double? open,
    final double? high,
    final double? low,
    final double? close,
    final int? volume,
    final String? ticker,
  }) = _$StockHistoricalEntryImpl;

  factory _StockHistoricalEntry.fromJson(Map<String, dynamic> json) =
      _$StockHistoricalEntryImpl.fromJson;

  @override
  String get time;
  @override
  double? get open;
  @override
  double? get high;
  @override
  double? get low;
  @override
  double? get close;
  @override
  int? get volume;
  @override
  String? get ticker;

  /// Create a copy of StockHistoricalEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockHistoricalEntryImplCopyWith<_$StockHistoricalEntryImpl>
  get copyWith => throw _privateConstructorUsedError;
}

StockHistoricalData _$StockHistoricalDataFromJson(Map<String, dynamic> json) {
  return _StockHistoricalData.fromJson(json);
}

/// @nodoc
mixin _$StockHistoricalData {
  String get symbol => throw _privateConstructorUsedError;
  String get source => throw _privateConstructorUsedError;
  List<StockHistoricalEntry> get data => throw _privateConstructorUsedError;

  /// Serializes this StockHistoricalData to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockHistoricalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockHistoricalDataCopyWith<StockHistoricalData> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockHistoricalDataCopyWith<$Res> {
  factory $StockHistoricalDataCopyWith(
    StockHistoricalData value,
    $Res Function(StockHistoricalData) then,
  ) = _$StockHistoricalDataCopyWithImpl<$Res, StockHistoricalData>;
  @useResult
  $Res call({String symbol, String source, List<StockHistoricalEntry> data});
}

/// @nodoc
class _$StockHistoricalDataCopyWithImpl<$Res, $Val extends StockHistoricalData>
    implements $StockHistoricalDataCopyWith<$Res> {
  _$StockHistoricalDataCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockHistoricalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? source = null,
    Object? data = null,
  }) {
    return _then(
      _value.copyWith(
            symbol: null == symbol
                ? _value.symbol
                : symbol // ignore: cast_nullable_to_non_nullable
                      as String,
            source: null == source
                ? _value.source
                : source // ignore: cast_nullable_to_non_nullable
                      as String,
            data: null == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as List<StockHistoricalEntry>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$StockHistoricalDataImplCopyWith<$Res>
    implements $StockHistoricalDataCopyWith<$Res> {
  factory _$$StockHistoricalDataImplCopyWith(
    _$StockHistoricalDataImpl value,
    $Res Function(_$StockHistoricalDataImpl) then,
  ) = __$$StockHistoricalDataImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String symbol, String source, List<StockHistoricalEntry> data});
}

/// @nodoc
class __$$StockHistoricalDataImplCopyWithImpl<$Res>
    extends _$StockHistoricalDataCopyWithImpl<$Res, _$StockHistoricalDataImpl>
    implements _$$StockHistoricalDataImplCopyWith<$Res> {
  __$$StockHistoricalDataImplCopyWithImpl(
    _$StockHistoricalDataImpl _value,
    $Res Function(_$StockHistoricalDataImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockHistoricalData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? symbol = null,
    Object? source = null,
    Object? data = null,
  }) {
    return _then(
      _$StockHistoricalDataImpl(
        symbol: null == symbol
            ? _value.symbol
            : symbol // ignore: cast_nullable_to_non_nullable
                  as String,
        source: null == source
            ? _value.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        data: null == data
            ? _value._data
            : data // ignore: cast_nullable_to_non_nullable
                  as List<StockHistoricalEntry>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockHistoricalDataImpl implements _StockHistoricalData {
  const _$StockHistoricalDataImpl({
    required this.symbol,
    required this.source,
    required final List<StockHistoricalEntry> data,
  }) : _data = data;

  factory _$StockHistoricalDataImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockHistoricalDataImplFromJson(json);

  @override
  final String symbol;
  @override
  final String source;
  final List<StockHistoricalEntry> _data;
  @override
  List<StockHistoricalEntry> get data {
    if (_data is EqualUnmodifiableListView) return _data;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_data);
  }

  @override
  String toString() {
    return 'StockHistoricalData(symbol: $symbol, source: $source, data: $data)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockHistoricalDataImpl &&
            (identical(other.symbol, symbol) || other.symbol == symbol) &&
            (identical(other.source, source) || other.source == source) &&
            const DeepCollectionEquality().equals(other._data, _data));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    symbol,
    source,
    const DeepCollectionEquality().hash(_data),
  );

  /// Create a copy of StockHistoricalData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockHistoricalDataImplCopyWith<_$StockHistoricalDataImpl> get copyWith =>
      __$$StockHistoricalDataImplCopyWithImpl<_$StockHistoricalDataImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$StockHistoricalDataImplToJson(this);
  }
}

abstract class _StockHistoricalData implements StockHistoricalData {
  const factory _StockHistoricalData({
    required final String symbol,
    required final String source,
    required final List<StockHistoricalEntry> data,
  }) = _$StockHistoricalDataImpl;

  factory _StockHistoricalData.fromJson(Map<String, dynamic> json) =
      _$StockHistoricalDataImpl.fromJson;

  @override
  String get symbol;
  @override
  String get source;
  @override
  List<StockHistoricalEntry> get data;

  /// Create a copy of StockHistoricalData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockHistoricalDataImplCopyWith<_$StockHistoricalDataImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

StockFullInfo _$StockFullInfoFromJson(Map<String, dynamic> json) {
  return _StockFullInfo.fromJson(json);
}

/// @nodoc
mixin _$StockFullInfo {
  StockPrice get price => throw _privateConstructorUsedError;
  StockOverview get company => throw _privateConstructorUsedError;

  /// Serializes this StockFullInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $StockFullInfoCopyWith<StockFullInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StockFullInfoCopyWith<$Res> {
  factory $StockFullInfoCopyWith(
    StockFullInfo value,
    $Res Function(StockFullInfo) then,
  ) = _$StockFullInfoCopyWithImpl<$Res, StockFullInfo>;
  @useResult
  $Res call({StockPrice price, StockOverview company});

  $StockPriceCopyWith<$Res> get price;
  $StockOverviewCopyWith<$Res> get company;
}

/// @nodoc
class _$StockFullInfoCopyWithImpl<$Res, $Val extends StockFullInfo>
    implements $StockFullInfoCopyWith<$Res> {
  _$StockFullInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? price = null, Object? company = null}) {
    return _then(
      _value.copyWith(
            price: null == price
                ? _value.price
                : price // ignore: cast_nullable_to_non_nullable
                      as StockPrice,
            company: null == company
                ? _value.company
                : company // ignore: cast_nullable_to_non_nullable
                      as StockOverview,
          )
          as $Val,
    );
  }

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StockPriceCopyWith<$Res> get price {
    return $StockPriceCopyWith<$Res>(_value.price, (value) {
      return _then(_value.copyWith(price: value) as $Val);
    });
  }

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $StockOverviewCopyWith<$Res> get company {
    return $StockOverviewCopyWith<$Res>(_value.company, (value) {
      return _then(_value.copyWith(company: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$StockFullInfoImplCopyWith<$Res>
    implements $StockFullInfoCopyWith<$Res> {
  factory _$$StockFullInfoImplCopyWith(
    _$StockFullInfoImpl value,
    $Res Function(_$StockFullInfoImpl) then,
  ) = __$$StockFullInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({StockPrice price, StockOverview company});

  @override
  $StockPriceCopyWith<$Res> get price;
  @override
  $StockOverviewCopyWith<$Res> get company;
}

/// @nodoc
class __$$StockFullInfoImplCopyWithImpl<$Res>
    extends _$StockFullInfoCopyWithImpl<$Res, _$StockFullInfoImpl>
    implements _$$StockFullInfoImplCopyWith<$Res> {
  __$$StockFullInfoImplCopyWithImpl(
    _$StockFullInfoImpl _value,
    $Res Function(_$StockFullInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? price = null, Object? company = null}) {
    return _then(
      _$StockFullInfoImpl(
        price: null == price
            ? _value.price
            : price // ignore: cast_nullable_to_non_nullable
                  as StockPrice,
        company: null == company
            ? _value.company
            : company // ignore: cast_nullable_to_non_nullable
                  as StockOverview,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$StockFullInfoImpl implements _StockFullInfo {
  const _$StockFullInfoImpl({required this.price, required this.company});

  factory _$StockFullInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$StockFullInfoImplFromJson(json);

  @override
  final StockPrice price;
  @override
  final StockOverview company;

  @override
  String toString() {
    return 'StockFullInfo(price: $price, company: $company)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StockFullInfoImpl &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.company, company) || other.company == company));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, price, company);

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$StockFullInfoImplCopyWith<_$StockFullInfoImpl> get copyWith =>
      __$$StockFullInfoImplCopyWithImpl<_$StockFullInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StockFullInfoImplToJson(this);
  }
}

abstract class _StockFullInfo implements StockFullInfo {
  const factory _StockFullInfo({
    required final StockPrice price,
    required final StockOverview company,
  }) = _$StockFullInfoImpl;

  factory _StockFullInfo.fromJson(Map<String, dynamic> json) =
      _$StockFullInfoImpl.fromJson;

  @override
  StockPrice get price;
  @override
  StockOverview get company;

  /// Create a copy of StockFullInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$StockFullInfoImplCopyWith<_$StockFullInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
