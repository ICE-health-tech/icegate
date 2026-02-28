// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'PersonProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PersonProtocol _$PersonProtocolFromJson(Map<String, dynamic> json) {
  return _PersonProtocol.fromJson(json);
}

/// @nodoc
mixin _$PersonProtocol {
  String get id => throw _privateConstructorUsedError;
  String get firstName => throw _privateConstructorUsedError;
  String? get lastName => throw _privateConstructorUsedError;
  DateTime? get dateOfBirth => throw _privateConstructorUsedError;
  String? get gender => throw _privateConstructorUsedError;
  String? get phoneNumber => throw _privateConstructorUsedError;
  String? get profileImageUrl => throw _privateConstructorUsedError;
  bool get isActive => throw _privateConstructorUsedError;

  /// Serializes this PersonProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PersonProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PersonProtocolCopyWith<PersonProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PersonProtocolCopyWith<$Res> {
  factory $PersonProtocolCopyWith(
    PersonProtocol value,
    $Res Function(PersonProtocol) then,
  ) = _$PersonProtocolCopyWithImpl<$Res, PersonProtocol>;
  @useResult
  $Res call({
    String id,
    String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profileImageUrl,
    bool isActive,
  });
}

/// @nodoc
class _$PersonProtocolCopyWithImpl<$Res, $Val extends PersonProtocol>
    implements $PersonProtocolCopyWith<$Res> {
  _$PersonProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PersonProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? phoneNumber = freezed,
    Object? profileImageUrl = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            firstName: null == firstName
                ? _value.firstName
                : firstName // ignore: cast_nullable_to_non_nullable
                      as String,
            lastName: freezed == lastName
                ? _value.lastName
                : lastName // ignore: cast_nullable_to_non_nullable
                      as String?,
            dateOfBirth: freezed == dateOfBirth
                ? _value.dateOfBirth
                : dateOfBirth // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            gender: freezed == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String?,
            phoneNumber: freezed == phoneNumber
                ? _value.phoneNumber
                : phoneNumber // ignore: cast_nullable_to_non_nullable
                      as String?,
            profileImageUrl: freezed == profileImageUrl
                ? _value.profileImageUrl
                : profileImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            isActive: null == isActive
                ? _value.isActive
                : isActive // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PersonProtocolImplCopyWith<$Res>
    implements $PersonProtocolCopyWith<$Res> {
  factory _$$PersonProtocolImplCopyWith(
    _$PersonProtocolImpl value,
    $Res Function(_$PersonProtocolImpl) then,
  ) = __$$PersonProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String firstName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? phoneNumber,
    String? profileImageUrl,
    bool isActive,
  });
}

/// @nodoc
class __$$PersonProtocolImplCopyWithImpl<$Res>
    extends _$PersonProtocolCopyWithImpl<$Res, _$PersonProtocolImpl>
    implements _$$PersonProtocolImplCopyWith<$Res> {
  __$$PersonProtocolImplCopyWithImpl(
    _$PersonProtocolImpl _value,
    $Res Function(_$PersonProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PersonProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? firstName = null,
    Object? lastName = freezed,
    Object? dateOfBirth = freezed,
    Object? gender = freezed,
    Object? phoneNumber = freezed,
    Object? profileImageUrl = freezed,
    Object? isActive = null,
  }) {
    return _then(
      _$PersonProtocolImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        firstName: null == firstName
            ? _value.firstName
            : firstName // ignore: cast_nullable_to_non_nullable
                  as String,
        lastName: freezed == lastName
            ? _value.lastName
            : lastName // ignore: cast_nullable_to_non_nullable
                  as String?,
        dateOfBirth: freezed == dateOfBirth
            ? _value.dateOfBirth
            : dateOfBirth // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        gender: freezed == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String?,
        phoneNumber: freezed == phoneNumber
            ? _value.phoneNumber
            : phoneNumber // ignore: cast_nullable_to_non_nullable
                  as String?,
        profileImageUrl: freezed == profileImageUrl
            ? _value.profileImageUrl
            : profileImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        isActive: null == isActive
            ? _value.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PersonProtocolImpl implements _PersonProtocol {
  const _$PersonProtocolImpl({
    required this.id,
    required this.firstName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.phoneNumber,
    this.profileImageUrl,
    this.isActive = true,
  });

  factory _$PersonProtocolImpl.fromJson(Map<String, dynamic> json) =>
      _$$PersonProtocolImplFromJson(json);

  @override
  final String id;
  @override
  final String firstName;
  @override
  final String? lastName;
  @override
  final DateTime? dateOfBirth;
  @override
  final String? gender;
  @override
  final String? phoneNumber;
  @override
  final String? profileImageUrl;
  @override
  @JsonKey()
  final bool isActive;

  @override
  String toString() {
    return 'PersonProtocol(id: $id, firstName: $firstName, lastName: $lastName, dateOfBirth: $dateOfBirth, gender: $gender, phoneNumber: $phoneNumber, profileImageUrl: $profileImageUrl, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PersonProtocolImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            (identical(other.dateOfBirth, dateOfBirth) ||
                other.dateOfBirth == dateOfBirth) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.phoneNumber, phoneNumber) ||
                other.phoneNumber == phoneNumber) &&
            (identical(other.profileImageUrl, profileImageUrl) ||
                other.profileImageUrl == profileImageUrl) &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    firstName,
    lastName,
    dateOfBirth,
    gender,
    phoneNumber,
    profileImageUrl,
    isActive,
  );

  /// Create a copy of PersonProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PersonProtocolImplCopyWith<_$PersonProtocolImpl> get copyWith =>
      __$$PersonProtocolImplCopyWithImpl<_$PersonProtocolImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PersonProtocolImplToJson(this);
  }
}

abstract class _PersonProtocol implements PersonProtocol {
  const factory _PersonProtocol({
    required final String id,
    required final String firstName,
    final String? lastName,
    final DateTime? dateOfBirth,
    final String? gender,
    final String? phoneNumber,
    final String? profileImageUrl,
    final bool isActive,
  }) = _$PersonProtocolImpl;

  factory _PersonProtocol.fromJson(Map<String, dynamic> json) =
      _$PersonProtocolImpl.fromJson;

  @override
  String get id;
  @override
  String get firstName;
  @override
  String? get lastName;
  @override
  DateTime? get dateOfBirth;
  @override
  String? get gender;
  @override
  String? get phoneNumber;
  @override
  String? get profileImageUrl;
  @override
  bool get isActive;

  /// Create a copy of PersonProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PersonProtocolImplCopyWith<_$PersonProtocolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
