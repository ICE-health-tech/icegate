// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'BluetoothDeviceInfo.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

BluetoothDeviceInfo _$BluetoothDeviceInfoFromJson(Map<String, dynamic> json) {
  return _BluetoothDeviceInfo.fromJson(json);
}

/// @nodoc
mixin _$BluetoothDeviceInfo {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;
  int get rssi => throw _privateConstructorUsedError; // Signal strength
  String get deviceType => throw _privateConstructorUsedError;

  /// Serializes this BluetoothDeviceInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BluetoothDeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BluetoothDeviceInfoCopyWith<BluetoothDeviceInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BluetoothDeviceInfoCopyWith<$Res> {
  factory $BluetoothDeviceInfoCopyWith(
    BluetoothDeviceInfo value,
    $Res Function(BluetoothDeviceInfo) then,
  ) = _$BluetoothDeviceInfoCopyWithImpl<$Res, BluetoothDeviceInfo>;
  @useResult
  $Res call({
    String id,
    String name,
    bool isConnected,
    int rssi,
    String deviceType,
  });
}

/// @nodoc
class _$BluetoothDeviceInfoCopyWithImpl<$Res, $Val extends BluetoothDeviceInfo>
    implements $BluetoothDeviceInfoCopyWith<$Res> {
  _$BluetoothDeviceInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BluetoothDeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isConnected = null,
    Object? rssi = null,
    Object? deviceType = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            isConnected: null == isConnected
                ? _value.isConnected
                : isConnected // ignore: cast_nullable_to_non_nullable
                      as bool,
            rssi: null == rssi
                ? _value.rssi
                : rssi // ignore: cast_nullable_to_non_nullable
                      as int,
            deviceType: null == deviceType
                ? _value.deviceType
                : deviceType // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BluetoothDeviceInfoImplCopyWith<$Res>
    implements $BluetoothDeviceInfoCopyWith<$Res> {
  factory _$$BluetoothDeviceInfoImplCopyWith(
    _$BluetoothDeviceInfoImpl value,
    $Res Function(_$BluetoothDeviceInfoImpl) then,
  ) = __$$BluetoothDeviceInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    bool isConnected,
    int rssi,
    String deviceType,
  });
}

/// @nodoc
class __$$BluetoothDeviceInfoImplCopyWithImpl<$Res>
    extends _$BluetoothDeviceInfoCopyWithImpl<$Res, _$BluetoothDeviceInfoImpl>
    implements _$$BluetoothDeviceInfoImplCopyWith<$Res> {
  __$$BluetoothDeviceInfoImplCopyWithImpl(
    _$BluetoothDeviceInfoImpl _value,
    $Res Function(_$BluetoothDeviceInfoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BluetoothDeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? isConnected = null,
    Object? rssi = null,
    Object? deviceType = null,
  }) {
    return _then(
      _$BluetoothDeviceInfoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        isConnected: null == isConnected
            ? _value.isConnected
            : isConnected // ignore: cast_nullable_to_non_nullable
                  as bool,
        rssi: null == rssi
            ? _value.rssi
            : rssi // ignore: cast_nullable_to_non_nullable
                  as int,
        deviceType: null == deviceType
            ? _value.deviceType
            : deviceType // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BluetoothDeviceInfoImpl implements _BluetoothDeviceInfo {
  const _$BluetoothDeviceInfoImpl({
    required this.id,
    required this.name,
    this.isConnected = false,
    this.rssi = 0,
    this.deviceType = 'Unknown',
  });

  factory _$BluetoothDeviceInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$BluetoothDeviceInfoImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  @JsonKey()
  final bool isConnected;
  @override
  @JsonKey()
  final int rssi;
  // Signal strength
  @override
  @JsonKey()
  final String deviceType;

  @override
  String toString() {
    return 'BluetoothDeviceInfo(id: $id, name: $name, isConnected: $isConnected, rssi: $rssi, deviceType: $deviceType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BluetoothDeviceInfoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected) &&
            (identical(other.rssi, rssi) || other.rssi == rssi) &&
            (identical(other.deviceType, deviceType) ||
                other.deviceType == deviceType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, name, isConnected, rssi, deviceType);

  /// Create a copy of BluetoothDeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BluetoothDeviceInfoImplCopyWith<_$BluetoothDeviceInfoImpl> get copyWith =>
      __$$BluetoothDeviceInfoImplCopyWithImpl<_$BluetoothDeviceInfoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BluetoothDeviceInfoImplToJson(this);
  }
}

abstract class _BluetoothDeviceInfo implements BluetoothDeviceInfo {
  const factory _BluetoothDeviceInfo({
    required final String id,
    required final String name,
    final bool isConnected,
    final int rssi,
    final String deviceType,
  }) = _$BluetoothDeviceInfoImpl;

  factory _BluetoothDeviceInfo.fromJson(Map<String, dynamic> json) =
      _$BluetoothDeviceInfoImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  bool get isConnected;
  @override
  int get rssi; // Signal strength
  @override
  String get deviceType;

  /// Create a copy of BluetoothDeviceInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BluetoothDeviceInfoImplCopyWith<_$BluetoothDeviceInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
