// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'TargetCaloriesProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

TargetCaloriesProtocol _$TargetCaloriesProtocolFromJson(
  Map<String, dynamic> json,
) {
  return _TargetCaloriesProtocol.fromJson(json);
}

/// @nodoc
mixin _$TargetCaloriesProtocol {
  int get calories => throw _privateConstructorUsedError;
  int get protein => throw _privateConstructorUsedError;
  int get carbs => throw _privateConstructorUsedError;
  int get fat => throw _privateConstructorUsedError;

  /// Serializes this TargetCaloriesProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of TargetCaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TargetCaloriesProtocolCopyWith<TargetCaloriesProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TargetCaloriesProtocolCopyWith<$Res> {
  factory $TargetCaloriesProtocolCopyWith(
    TargetCaloriesProtocol value,
    $Res Function(TargetCaloriesProtocol) then,
  ) = _$TargetCaloriesProtocolCopyWithImpl<$Res, TargetCaloriesProtocol>;
  @useResult
  $Res call({int calories, int protein, int carbs, int fat});
}

/// @nodoc
class _$TargetCaloriesProtocolCopyWithImpl<
  $Res,
  $Val extends TargetCaloriesProtocol
>
    implements $TargetCaloriesProtocolCopyWith<$Res> {
  _$TargetCaloriesProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TargetCaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(
      _value.copyWith(
            calories: null == calories
                ? _value.calories
                : calories // ignore: cast_nullable_to_non_nullable
                      as int,
            protein: null == protein
                ? _value.protein
                : protein // ignore: cast_nullable_to_non_nullable
                      as int,
            carbs: null == carbs
                ? _value.carbs
                : carbs // ignore: cast_nullable_to_non_nullable
                      as int,
            fat: null == fat
                ? _value.fat
                : fat // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$TargetCaloriesProtocolImplCopyWith<$Res>
    implements $TargetCaloriesProtocolCopyWith<$Res> {
  factory _$$TargetCaloriesProtocolImplCopyWith(
    _$TargetCaloriesProtocolImpl value,
    $Res Function(_$TargetCaloriesProtocolImpl) then,
  ) = __$$TargetCaloriesProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int calories, int protein, int carbs, int fat});
}

/// @nodoc
class __$$TargetCaloriesProtocolImplCopyWithImpl<$Res>
    extends
        _$TargetCaloriesProtocolCopyWithImpl<$Res, _$TargetCaloriesProtocolImpl>
    implements _$$TargetCaloriesProtocolImplCopyWith<$Res> {
  __$$TargetCaloriesProtocolImplCopyWithImpl(
    _$TargetCaloriesProtocolImpl _value,
    $Res Function(_$TargetCaloriesProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TargetCaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? carbs = null,
    Object? fat = null,
  }) {
    return _then(
      _$TargetCaloriesProtocolImpl(
        calories: null == calories
            ? _value.calories
            : calories // ignore: cast_nullable_to_non_nullable
                  as int,
        protein: null == protein
            ? _value.protein
            : protein // ignore: cast_nullable_to_non_nullable
                  as int,
        carbs: null == carbs
            ? _value.carbs
            : carbs // ignore: cast_nullable_to_non_nullable
                  as int,
        fat: null == fat
            ? _value.fat
            : fat // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$TargetCaloriesProtocolImpl implements _TargetCaloriesProtocol {
  const _$TargetCaloriesProtocolImpl({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory _$TargetCaloriesProtocolImpl.fromJson(Map<String, dynamic> json) =>
      _$$TargetCaloriesProtocolImplFromJson(json);

  @override
  final int calories;
  @override
  final int protein;
  @override
  final int carbs;
  @override
  final int fat;

  @override
  String toString() {
    return 'TargetCaloriesProtocol(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TargetCaloriesProtocolImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, calories, protein, carbs, fat);

  /// Create a copy of TargetCaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TargetCaloriesProtocolImplCopyWith<_$TargetCaloriesProtocolImpl>
  get copyWith =>
      __$$TargetCaloriesProtocolImplCopyWithImpl<_$TargetCaloriesProtocolImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$TargetCaloriesProtocolImplToJson(this);
  }
}

abstract class _TargetCaloriesProtocol implements TargetCaloriesProtocol {
  const factory _TargetCaloriesProtocol({
    required final int calories,
    required final int protein,
    required final int carbs,
    required final int fat,
  }) = _$TargetCaloriesProtocolImpl;

  factory _TargetCaloriesProtocol.fromJson(Map<String, dynamic> json) =
      _$TargetCaloriesProtocolImpl.fromJson;

  @override
  int get calories;
  @override
  int get protein;
  @override
  int get carbs;
  @override
  int get fat;

  /// Create a copy of TargetCaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TargetCaloriesProtocolImplCopyWith<_$TargetCaloriesProtocolImpl>
  get copyWith => throw _privateConstructorUsedError;
}
