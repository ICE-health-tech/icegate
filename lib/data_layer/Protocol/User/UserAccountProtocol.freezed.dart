// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'UserAccountProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

UserAccountProtocol _$UserAccountProtocolFromJson(Map<String, dynamic> json) {
  return _UserAccountProtocol.fromJson(json);
}

/// @nodoc
mixin _$UserAccountProtocol {
  String get accountID => throw _privateConstructorUsedError;
  String get personID => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get primaryEmail => throw _privateConstructorUsedError;
  String get role => throw _privateConstructorUsedError;
  bool get isLocked => throw _privateConstructorUsedError;
  DateTime? get lastLoginAt => throw _privateConstructorUsedError;

  /// Serializes this UserAccountProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UserAccountProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UserAccountProtocolCopyWith<UserAccountProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UserAccountProtocolCopyWith<$Res> {
  factory $UserAccountProtocolCopyWith(
    UserAccountProtocol value,
    $Res Function(UserAccountProtocol) then,
  ) = _$UserAccountProtocolCopyWithImpl<$Res, UserAccountProtocol>;
  @useResult
  $Res call({
    String accountID,
    String personID,
    String username,
    String? primaryEmail,
    String role,
    bool isLocked,
    DateTime? lastLoginAt,
  });
}

/// @nodoc
class _$UserAccountProtocolCopyWithImpl<$Res, $Val extends UserAccountProtocol>
    implements $UserAccountProtocolCopyWith<$Res> {
  _$UserAccountProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UserAccountProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountID = null,
    Object? personID = null,
    Object? username = null,
    Object? primaryEmail = freezed,
    Object? role = null,
    Object? isLocked = null,
    Object? lastLoginAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            accountID: null == accountID
                ? _value.accountID
                : accountID // ignore: cast_nullable_to_non_nullable
                      as String,
            personID: null == personID
                ? _value.personID
                : personID // ignore: cast_nullable_to_non_nullable
                      as String,
            username: null == username
                ? _value.username
                : username // ignore: cast_nullable_to_non_nullable
                      as String,
            primaryEmail: freezed == primaryEmail
                ? _value.primaryEmail
                : primaryEmail // ignore: cast_nullable_to_non_nullable
                      as String?,
            role: null == role
                ? _value.role
                : role // ignore: cast_nullable_to_non_nullable
                      as String,
            isLocked: null == isLocked
                ? _value.isLocked
                : isLocked // ignore: cast_nullable_to_non_nullable
                      as bool,
            lastLoginAt: freezed == lastLoginAt
                ? _value.lastLoginAt
                : lastLoginAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UserAccountProtocolImplCopyWith<$Res>
    implements $UserAccountProtocolCopyWith<$Res> {
  factory _$$UserAccountProtocolImplCopyWith(
    _$UserAccountProtocolImpl value,
    $Res Function(_$UserAccountProtocolImpl) then,
  ) = __$$UserAccountProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String accountID,
    String personID,
    String username,
    String? primaryEmail,
    String role,
    bool isLocked,
    DateTime? lastLoginAt,
  });
}

/// @nodoc
class __$$UserAccountProtocolImplCopyWithImpl<$Res>
    extends _$UserAccountProtocolCopyWithImpl<$Res, _$UserAccountProtocolImpl>
    implements _$$UserAccountProtocolImplCopyWith<$Res> {
  __$$UserAccountProtocolImplCopyWithImpl(
    _$UserAccountProtocolImpl _value,
    $Res Function(_$UserAccountProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UserAccountProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? accountID = null,
    Object? personID = null,
    Object? username = null,
    Object? primaryEmail = freezed,
    Object? role = null,
    Object? isLocked = null,
    Object? lastLoginAt = freezed,
  }) {
    return _then(
      _$UserAccountProtocolImpl(
        accountID: null == accountID
            ? _value.accountID
            : accountID // ignore: cast_nullable_to_non_nullable
                  as String,
        personID: null == personID
            ? _value.personID
            : personID // ignore: cast_nullable_to_non_nullable
                  as String,
        username: null == username
            ? _value.username
            : username // ignore: cast_nullable_to_non_nullable
                  as String,
        primaryEmail: freezed == primaryEmail
            ? _value.primaryEmail
            : primaryEmail // ignore: cast_nullable_to_non_nullable
                  as String?,
        role: null == role
            ? _value.role
            : role // ignore: cast_nullable_to_non_nullable
                  as String,
        isLocked: null == isLocked
            ? _value.isLocked
            : isLocked // ignore: cast_nullable_to_non_nullable
                  as bool,
        lastLoginAt: freezed == lastLoginAt
            ? _value.lastLoginAt
            : lastLoginAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$UserAccountProtocolImpl extends _UserAccountProtocol {
  const _$UserAccountProtocolImpl({
    required this.accountID,
    required this.personID,
    required this.username,
    this.primaryEmail,
    this.role = 'user',
    this.isLocked = false,
    this.lastLoginAt,
  }) : super._();

  factory _$UserAccountProtocolImpl.fromJson(Map<String, dynamic> json) =>
      _$$UserAccountProtocolImplFromJson(json);

  @override
  final String accountID;
  @override
  final String personID;
  @override
  final String username;
  @override
  final String? primaryEmail;
  @override
  @JsonKey()
  final String role;
  @override
  @JsonKey()
  final bool isLocked;
  @override
  final DateTime? lastLoginAt;

  @override
  String toString() {
    return 'UserAccountProtocol(accountID: $accountID, personID: $personID, username: $username, primaryEmail: $primaryEmail, role: $role, isLocked: $isLocked, lastLoginAt: $lastLoginAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UserAccountProtocolImpl &&
            (identical(other.accountID, accountID) ||
                other.accountID == accountID) &&
            (identical(other.personID, personID) ||
                other.personID == personID) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.primaryEmail, primaryEmail) ||
                other.primaryEmail == primaryEmail) &&
            (identical(other.role, role) || other.role == role) &&
            (identical(other.isLocked, isLocked) ||
                other.isLocked == isLocked) &&
            (identical(other.lastLoginAt, lastLoginAt) ||
                other.lastLoginAt == lastLoginAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    accountID,
    personID,
    username,
    primaryEmail,
    role,
    isLocked,
    lastLoginAt,
  );

  /// Create a copy of UserAccountProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UserAccountProtocolImplCopyWith<_$UserAccountProtocolImpl> get copyWith =>
      __$$UserAccountProtocolImplCopyWithImpl<_$UserAccountProtocolImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$UserAccountProtocolImplToJson(this);
  }
}

abstract class _UserAccountProtocol extends UserAccountProtocol {
  const factory _UserAccountProtocol({
    required final String accountID,
    required final String personID,
    required final String username,
    final String? primaryEmail,
    final String role,
    final bool isLocked,
    final DateTime? lastLoginAt,
  }) = _$UserAccountProtocolImpl;
  const _UserAccountProtocol._() : super._();

  factory _UserAccountProtocol.fromJson(Map<String, dynamic> json) =
      _$UserAccountProtocolImpl.fromJson;

  @override
  String get accountID;
  @override
  String get personID;
  @override
  String get username;
  @override
  String? get primaryEmail;
  @override
  String get role;
  @override
  bool get isLocked;
  @override
  DateTime? get lastLoginAt;

  /// Create a copy of UserAccountProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UserAccountProtocolImplCopyWith<_$UserAccountProtocolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
