// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ExternalWidgetProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$ExternalWidgetProtocol {
  String get name => throw _privateConstructorUsedError;
  String get protocol => throw _privateConstructorUsedError;
  String get host => throw _privateConstructorUsedError;
  String get url => throw _privateConstructorUsedError;
  String? get alias => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  String? get dateAdded => throw _privateConstructorUsedError;

  /// Create a copy of ExternalWidgetProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExternalWidgetProtocolCopyWith<ExternalWidgetProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExternalWidgetProtocolCopyWith<$Res> {
  factory $ExternalWidgetProtocolCopyWith(
    ExternalWidgetProtocol value,
    $Res Function(ExternalWidgetProtocol) then,
  ) = _$ExternalWidgetProtocolCopyWithImpl<$Res, ExternalWidgetProtocol>;
  @useResult
  $Res call({
    String name,
    String protocol,
    String host,
    String url,
    String? alias,
    String? imageUrl,
    String? dateAdded,
  });
}

/// @nodoc
class _$ExternalWidgetProtocolCopyWithImpl<
  $Res,
  $Val extends ExternalWidgetProtocol
>
    implements $ExternalWidgetProtocolCopyWith<$Res> {
  _$ExternalWidgetProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExternalWidgetProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? protocol = null,
    Object? host = null,
    Object? url = null,
    Object? alias = freezed,
    Object? imageUrl = freezed,
    Object? dateAdded = freezed,
  }) {
    return _then(
      _value.copyWith(
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            protocol: null == protocol
                ? _value.protocol
                : protocol // ignore: cast_nullable_to_non_nullable
                      as String,
            host: null == host
                ? _value.host
                : host // ignore: cast_nullable_to_non_nullable
                      as String,
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            alias: freezed == alias
                ? _value.alias
                : alias // ignore: cast_nullable_to_non_nullable
                      as String?,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateAdded: freezed == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExternalWidgetProtocolImplCopyWith<$Res>
    implements $ExternalWidgetProtocolCopyWith<$Res> {
  factory _$$ExternalWidgetProtocolImplCopyWith(
    _$ExternalWidgetProtocolImpl value,
    $Res Function(_$ExternalWidgetProtocolImpl) then,
  ) = __$$ExternalWidgetProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String name,
    String protocol,
    String host,
    String url,
    String? alias,
    String? imageUrl,
    String? dateAdded,
  });
}

/// @nodoc
class __$$ExternalWidgetProtocolImplCopyWithImpl<$Res>
    extends
        _$ExternalWidgetProtocolCopyWithImpl<$Res, _$ExternalWidgetProtocolImpl>
    implements _$$ExternalWidgetProtocolImplCopyWith<$Res> {
  __$$ExternalWidgetProtocolImplCopyWithImpl(
    _$ExternalWidgetProtocolImpl _value,
    $Res Function(_$ExternalWidgetProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExternalWidgetProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? protocol = null,
    Object? host = null,
    Object? url = null,
    Object? alias = freezed,
    Object? imageUrl = freezed,
    Object? dateAdded = freezed,
  }) {
    return _then(
      _$ExternalWidgetProtocolImpl(
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        protocol: null == protocol
            ? _value.protocol
            : protocol // ignore: cast_nullable_to_non_nullable
                  as String,
        host: null == host
            ? _value.host
            : host // ignore: cast_nullable_to_non_nullable
                  as String,
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        alias: freezed == alias
            ? _value.alias
            : alias // ignore: cast_nullable_to_non_nullable
                  as String?,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateAdded: freezed == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _$ExternalWidgetProtocolImpl implements _ExternalWidgetProtocol {
  const _$ExternalWidgetProtocolImpl({
    required this.name,
    required this.protocol,
    required this.host,
    required this.url,
    this.alias,
    this.imageUrl,
    this.dateAdded,
  });

  @override
  final String name;
  @override
  final String protocol;
  @override
  final String host;
  @override
  final String url;
  @override
  final String? alias;
  @override
  final String? imageUrl;
  @override
  final String? dateAdded;

  @override
  String toString() {
    return 'ExternalWidgetProtocol(name: $name, protocol: $protocol, host: $host, url: $url, alias: $alias, imageUrl: $imageUrl, dateAdded: $dateAdded)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExternalWidgetProtocolImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.host, host) || other.host == host) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.alias, alias) || other.alias == alias) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    protocol,
    host,
    url,
    alias,
    imageUrl,
    dateAdded,
  );

  /// Create a copy of ExternalWidgetProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExternalWidgetProtocolImplCopyWith<_$ExternalWidgetProtocolImpl>
  get copyWith =>
      __$$ExternalWidgetProtocolImplCopyWithImpl<_$ExternalWidgetProtocolImpl>(
        this,
        _$identity,
      );
}

abstract class _ExternalWidgetProtocol implements ExternalWidgetProtocol {
  const factory _ExternalWidgetProtocol({
    required final String name,
    required final String protocol,
    required final String host,
    required final String url,
    final String? alias,
    final String? imageUrl,
    final String? dateAdded,
  }) = _$ExternalWidgetProtocolImpl;

  @override
  String get name;
  @override
  String get protocol;
  @override
  String get host;
  @override
  String get url;
  @override
  String? get alias;
  @override
  String? get imageUrl;
  @override
  String? get dateAdded;

  /// Create a copy of ExternalWidgetProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExternalWidgetProtocolImplCopyWith<_$ExternalWidgetProtocolImpl>
  get copyWith => throw _privateConstructorUsedError;
}
