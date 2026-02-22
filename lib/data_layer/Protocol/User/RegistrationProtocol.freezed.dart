// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'RegistrationProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RegistrationPayload _$RegistrationPayloadFromJson(Map<String, dynamic> json) {
  return _RegistrationPayload.fromJson(json);
}

/// @nodoc
mixin _$RegistrationPayload {
  String get userName => throw _privateConstructorUsedError;
  String get password => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String get lastName => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;

  /// Serializes this RegistrationPayload to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RegistrationPayloadCopyWith<RegistrationPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RegistrationPayloadCopyWith<$Res> {
  factory $RegistrationPayloadCopyWith(
    RegistrationPayload value,
    $Res Function(RegistrationPayload) then,
  ) = _$RegistrationPayloadCopyWithImpl<$Res, RegistrationPayload>;
  @useResult
  $Res call({
    String userName,
    String password,
    String email,
    String firstName,
    String lastName,
    String role,
  });
}

/// @nodoc
class _$RegistrationPayloadCopyWithImpl<$Res, $Val extends RegistrationPayload>
    implements $RegistrationPayloadCopyWith<$Res> {
  _$RegistrationPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? password = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? role = null,
  }) {
    return _then(
      _value.copyWith(
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            password: null == password
                ? _value.password
                : password // ignore: cast_nullable_to_non_nullable
                      as String,
            email: null == email
                ? _value.email
                : email // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: null == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RegistrationPayloadImplCopyWith<$Res>
    implements $RegistrationPayloadCopyWith<$Res> {
  factory _$$RegistrationPayloadImplCopyWith(
    _$RegistrationPayloadImpl value,
    $Res Function(_$RegistrationPayloadImpl) then,
  ) = __$$RegistrationPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userName,
    String password,
    String email,
    String firstName,
    String lastName,
    String role,
  });
}

/// @nodoc
class __$$RegistrationPayloadImplCopyWithImpl<$Res>
    extends _$RegistrationPayloadCopyWithImpl<$Res, _$RegistrationPayloadImpl>
    implements _$$RegistrationPayloadImplCopyWith<$Res> {
  __$$RegistrationPayloadImplCopyWithImpl(
    _$RegistrationPayloadImpl _value,
    $Res Function(_$RegistrationPayloadImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? password = null,
    Object? email = null,
    Object? firstName = null,
    Object? lastName = null,
    Object? role = null,
  }) {
    return _then(
      _$RegistrationPayloadImpl(
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        password: null == password
            ? _value.password
            : password // ignore: cast_nullable_to_non_nullable
                  as String,
        email: null == email
            ? _value.email
            : email // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: null == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RegistrationPayloadImpl implements _RegistrationPayload {
  const _$RegistrationPayloadImpl({
    required this.userName,
    required this.password,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'USER',
  });

  factory _$RegistrationPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$RegistrationPayloadImplFromJson(json);

  @override
  final String userName;
  @override
  final String password;
  @override
  final String email;
  @override
  final String firstName;
  @override
  final String lastName;
  @override
  @JsonKey()
  final String role;

  @override
  String toString() {
    return 'RegistrationPayload(userName: $userName, password: $password, email: $email, firstName: $firstName, lastName: $lastName, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RegistrationPayloadImpl &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.password, password) ||
                other.password == password) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.role, role) || other.role == role));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userName,
    password,
    email,
    firstName,
    lastName,
    role,
  );

  /// Create a copy of RegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RegistrationPayloadImplCopyWith<_$RegistrationPayloadImpl> get copyWith =>
      __$$RegistrationPayloadImplCopyWithImpl<_$RegistrationPayloadImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RegistrationPayloadImplToJson(this);
  }
}

abstract class _RegistrationPayload implements RegistrationPayload {
  const factory _RegistrationPayload({
    required final String userName,
    required final String password,
    required final String email,
    required final String firstName,
    required final String lastName,
    final String role,
  }) = _$RegistrationPayloadImpl;

  factory _RegistrationPayload.fromJson(Map<String, dynamic> json) =
      _$RegistrationPayloadImpl.fromJson;

  @override
  String get userName;
  @override
  String get password;
  @override
  String get email;
  @override
  String get firstName;
  @override
  String get lastName;
  @override
  String get role;

  /// Create a copy of RegistrationPayload
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RegistrationPayloadImplCopyWith<_$RegistrationPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
