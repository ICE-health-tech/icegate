// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'AuthenticationProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AuthenticationProtocol _$AuthenticationProtocolFromJson(
  Map<String, dynamic> json,
) {
  return _AuthenticationProtocol.fromJson(json);
}

/// @nodoc
mixin _$AuthenticationProtocol {
  String get username => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  String get jwt => throw _privateConstructorUsedError;

  /// Serializes this AuthenticationProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AuthenticationProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AuthenticationProtocolCopyWith<AuthenticationProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AuthenticationProtocolCopyWith<$Res> {
  factory $AuthenticationProtocolCopyWith(
    AuthenticationProtocol value,
    $Res Function(AuthenticationProtocol) then,
  ) = _$AuthenticationProtocolCopyWithImpl<$Res, AuthenticationProtocol>;
  @useResult
  $Res call({String username, String password, String jwt});
}

/// @nodoc
class _$AuthenticationProtocolCopyWithImpl<
  $Res,
  $Val extends AuthenticationProtocol
>
    implements $AuthenticationProtocolCopyWith<$Res> {
  _$AuthenticationProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AuthenticationProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? jwt = null,
  }) {
    return _then(
      _value.copyWith(
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            jwt: null == jwt
                ? _value.jwt
                : jwt // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AuthenticationProtocolImplCopyWith<$Res>
    implements $AuthenticationProtocolCopyWith<$Res> {
  factory _$$AuthenticationProtocolImplCopyWith(
    _$AuthenticationProtocolImpl value,
    $Res Function(_$AuthenticationProtocolImpl) then,
  ) = __$$AuthenticationProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String username, String password, String jwt});
}

/// @nodoc
class __$$AuthenticationProtocolImplCopyWithImpl<$Res>
    extends
        _$AuthenticationProtocolCopyWithImpl<$Res, _$AuthenticationProtocolImpl>
    implements _$$AuthenticationProtocolImplCopyWith<$Res> {
  __$$AuthenticationProtocolImplCopyWithImpl(
    _$AuthenticationProtocolImpl _value,
    $Res Function(_$AuthenticationProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AuthenticationProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? username = null,
    Object? password = null,
    Object? jwt = null,
  }) {
    return _then(
      _$AuthenticationProtocolImpl(
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        jwt: null == jwt
            ? _value.jwt
            : jwt // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AuthenticationProtocolImpl implements _AuthenticationProtocol {
  const _$AuthenticationProtocolImpl({
    required this.username,
    required this.password,
    required this.jwt,
  });

  factory _$AuthenticationProtocolImpl.fromJson(Map<String, dynamic> json) =>
      _$$AuthenticationProtocolImplFromJson(json);

  @override
  final String username;
  @override
  final String password;
  @override
  final String jwt;

  @override
  String toString() {
    return 'AuthenticationProtocol(username: $username, password: $password, jwt: $jwt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AuthenticationProtocolImpl &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.jwt, jwt) || other.jwt == jwt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, username, password, jwt);

  /// Create a copy of AuthenticationProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AuthenticationProtocolImplCopyWith<_$AuthenticationProtocolImpl>
  get copyWith =>
      __$$AuthenticationProtocolImplCopyWithImpl<_$AuthenticationProtocolImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AuthenticationProtocolImplToJson(this);
  }
}

abstract class _AuthenticationProtocol implements AuthenticationProtocol {
  const factory _AuthenticationProtocol({
    required final String username,
    required final String password,
    required final String jwt,
  }) = _$AuthenticationProtocolImpl;

  factory _AuthenticationProtocol.fromJson(Map<String, dynamic> json) =
      _$AuthenticationProtocolImpl.fromJson;

  @override
  String get username;
  @override
  String get password;
  @override
  String get jwt;

  /// Create a copy of AuthenticationProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AuthenticationProtocolImplCopyWith<_$AuthenticationProtocolImpl>
  get copyWith => throw _privateConstructorUsedError;
}
