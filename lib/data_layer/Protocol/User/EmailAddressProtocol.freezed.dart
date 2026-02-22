// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'EmailAddressProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EmailAddressProtocol _$EmailAddressProtocolFromJson(Map<String, dynamic> json) {
  return _EmailAddressProtocol.fromJson(json);
}

/// @nodoc
mixin _$EmailAddressProtocol {
  int get emailAddressID => throw _privateConstructorUsedError;
  int get personID => throw _privateConstructorUsedError;
  String get emailAddress => throw _privateConstructorUsedError;
  String get emailType => throw _privateConstructorUsedError;
  bool get isPrimary => throw _privateConstructorUsedError;
  EmailStatus get status => throw _privateConstructorUsedError;
  DateTime? get verifiedAt => throw _privateConstructorUsedError;

  /// Serializes this EmailAddressProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EmailAddressProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EmailAddressProtocolCopyWith<EmailAddressProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EmailAddressProtocolCopyWith<$Res> {
  factory $EmailAddressProtocolCopyWith(
    EmailAddressProtocol value,
    $Res Function(EmailAddressProtocol) then,
  ) = _$EmailAddressProtocolCopyWithImpl<$Res, EmailAddressProtocol>;
  @useResult
  $Res call({
    int emailAddressID,
    int personID,
    String emailAddress,
    String emailType,
    bool isPrimary,
    EmailStatus status,
    DateTime? verifiedAt,
  });
}

/// @nodoc
class _$EmailAddressProtocolCopyWithImpl<
  $Res,
  $Val extends EmailAddressProtocol
>
    implements $EmailAddressProtocolCopyWith<$Res> {
  _$EmailAddressProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EmailAddressProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? emailAddressID = null,
    Object? personID = null,
    Object? emailAddress = null,
    Object? emailType = null,
    Object? isPrimary = null,
    Object? status = null,
    Object? verifiedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            emailAddressID: null == emailAddressID
                ? _value.emailAddressID
                : emailAddressID // ignore: cast_nullable_to_non_nullable
                      as int,
            personID: null == personID
                ? _value.personID
                : personID // ignore: cast_nullable_to_non_nullable
                      as int,
            emailAddress: null == emailAddress
                ? _value.emailAddress
                : emailAddress // ignore: cast_nullable_to_non_nullable
                      as String,
            emailType: null == emailType
                ? _value.emailType
                : emailType // ignore: cast_nullable_to_non_nullable
                      as String,
            isPrimary: null == isPrimary
                ? _value.isPrimary
                : isPrimary // ignore: cast_nullable_to_non_nullable
                      as bool,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as EmailStatus,
            verifiedAt: freezed == verifiedAt
                ? _value.verifiedAt
                : verifiedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EmailAddressProtocolImplCopyWith<$Res>
    implements $EmailAddressProtocolCopyWith<$Res> {
  factory _$$EmailAddressProtocolImplCopyWith(
    _$EmailAddressProtocolImpl value,
    $Res Function(_$EmailAddressProtocolImpl) then,
  ) = __$$EmailAddressProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int emailAddressID,
    int personID,
    String emailAddress,
    String emailType,
    bool isPrimary,
    EmailStatus status,
    DateTime? verifiedAt,
  });
}

/// @nodoc
class __$$EmailAddressProtocolImplCopyWithImpl<$Res>
    extends _$EmailAddressProtocolCopyWithImpl<$Res, _$EmailAddressProtocolImpl>
    implements _$$EmailAddressProtocolImplCopyWith<$Res> {
  __$$EmailAddressProtocolImplCopyWithImpl(
    _$EmailAddressProtocolImpl _value,
    $Res Function(_$EmailAddressProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EmailAddressProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? emailAddressID = null,
    Object? personID = null,
    Object? emailAddress = null,
    Object? emailType = null,
    Object? isPrimary = null,
    Object? status = null,
    Object? verifiedAt = freezed,
  }) {
    return _then(
      _$EmailAddressProtocolImpl(
        emailAddressID: null == emailAddressID
            ? _value.emailAddressID
            : emailAddressID // ignore: cast_nullable_to_non_nullable
                  as int,
        personID: null == personID
            ? _value.personID
            : personID // ignore: cast_nullable_to_non_nullable
                  as int,
        emailAddress: null == emailAddress
            ? _value.emailAddress
            : emailAddress // ignore: cast_nullable_to_non_nullable
                  as String,
        emailType: null == emailType
            ? _value.emailType
            : emailType // ignore: cast_nullable_to_non_nullable
                  as String,
        isPrimary: null == isPrimary
            ? _value.isPrimary
            : isPrimary // ignore: cast_nullable_to_non_nullable
                  as bool,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as EmailStatus,
        verifiedAt: freezed == verifiedAt
            ? _value.verifiedAt
            : verifiedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EmailAddressProtocolImpl implements _EmailAddressProtocol {
  const _$EmailAddressProtocolImpl({
    required this.emailAddressID,
    required this.personID,
    required this.emailAddress,
    this.emailType = 'personal',
    this.isPrimary = true,
    this.status = EmailStatus.pending,
    this.verifiedAt,
  });

  factory _$EmailAddressProtocolImpl.fromJson(Map<String, dynamic> json) =>
      _$$EmailAddressProtocolImplFromJson(json);

  @override
  final int emailAddressID;
  @override
  final int personID;
  @override
  final String emailAddress;
  @override
  @JsonKey()
  final String emailType;
  @override
  @JsonKey()
  final bool isPrimary;
  @override
  @JsonKey()
  final EmailStatus status;
  @override
  final DateTime? verifiedAt;

  @override
  String toString() {
    return 'EmailAddressProtocol(emailAddressID: $emailAddressID, personID: $personID, emailAddress: $emailAddress, emailType: $emailType, isPrimary: $isPrimary, status: $status, verifiedAt: $verifiedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EmailAddressProtocolImpl &&
            (identical(other.emailAddressID, emailAddressID) ||
                other.emailAddressID == emailAddressID) &&
            (identical(other.personID, personID) ||
                other.personID == personID) &&
            (identical(other.emailAddress, emailAddress) ||
                other.emailAddress == emailAddress) &&
            (identical(other.emailType, emailType) ||
                other.emailType == emailType) &&
            (identical(other.isPrimary, isPrimary) ||
                other.isPrimary == isPrimary) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.verifiedAt, verifiedAt) ||
                other.verifiedAt == verifiedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    emailAddressID,
    personID,
    emailAddress,
    emailType,
    isPrimary,
    status,
    verifiedAt,
  );

  /// Create a copy of EmailAddressProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EmailAddressProtocolImplCopyWith<_$EmailAddressProtocolImpl>
  get copyWith =>
      __$$EmailAddressProtocolImplCopyWithImpl<_$EmailAddressProtocolImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EmailAddressProtocolImplToJson(this);
  }
}

abstract class _EmailAddressProtocol implements EmailAddressProtocol {
  const factory _EmailAddressProtocol({
    required final int emailAddressID,
    required final int personID,
    required final String emailAddress,
    final String emailType,
    final bool isPrimary,
    final EmailStatus status,
    final DateTime? verifiedAt,
  }) = _$EmailAddressProtocolImpl;

  factory _EmailAddressProtocol.fromJson(Map<String, dynamic> json) =
      _$EmailAddressProtocolImpl.fromJson;

  @override
  int get emailAddressID;
  @override
  int get personID;
  @override
  String get emailAddress;
  @override
  String get emailType;
  @override
  bool get isPrimary;
  @override
  EmailStatus get status;
  @override
  DateTime? get verifiedAt;

  /// Create a copy of EmailAddressProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EmailAddressProtocolImplCopyWith<_$EmailAddressProtocolImpl>
  get copyWith => throw _privateConstructorUsedError;
}
