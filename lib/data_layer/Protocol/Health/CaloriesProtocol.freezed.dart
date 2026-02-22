// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'CaloriesProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$CaloriesProtocol {
  int get calories => throw _privateConstructorUsedError;
  int get protein => throw _privateConstructorUsedError;
  int get carbs => throw _privateConstructorUsedError;
  int get fat => throw _privateConstructorUsedError;

  /// Create a copy of CaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $CaloriesProtocolCopyWith<CaloriesProtocol> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CaloriesProtocolCopyWith<$Res> {
  factory $CaloriesProtocolCopyWith(
    CaloriesProtocol value,
    $Res Function(CaloriesProtocol) then,
  ) = _$CaloriesProtocolCopyWithImpl<$Res, CaloriesProtocol>;
  @useResult
  $Res call({int calories, int protein, int carbs, int fat});
}

/// @nodoc
class _$CaloriesProtocolCopyWithImpl<$Res, $Val extends CaloriesProtocol>
    implements $CaloriesProtocolCopyWith<$Res> {
  _$CaloriesProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of CaloriesProtocol
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
abstract class _$$CaloriesProtocolImplCopyWith<$Res>
    implements $CaloriesProtocolCopyWith<$Res> {
  factory _$$CaloriesProtocolImplCopyWith(
    _$CaloriesProtocolImpl value,
    $Res Function(_$CaloriesProtocolImpl) then,
  ) = __$$CaloriesProtocolImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int calories, int protein, int carbs, int fat});
}

/// @nodoc
class __$$CaloriesProtocolImplCopyWithImpl<$Res>
    extends _$CaloriesProtocolCopyWithImpl<$Res, _$CaloriesProtocolImpl>
    implements _$$CaloriesProtocolImplCopyWith<$Res> {
  __$$CaloriesProtocolImplCopyWithImpl(
    _$CaloriesProtocolImpl _value,
    $Res Function(_$CaloriesProtocolImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of CaloriesProtocol
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
      _$CaloriesProtocolImpl(
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

class _$CaloriesProtocolImpl implements _CaloriesProtocol {
  const _$CaloriesProtocolImpl({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

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
    return 'CaloriesProtocol(calories: $calories, protein: $protein, carbs: $carbs, fat: $fat)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CaloriesProtocolImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.fat, fat) || other.fat == fat));
  }

  @override
  int get hashCode => Object.hash(runtimeType, calories, protein, carbs, fat);

  /// Create a copy of CaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$CaloriesProtocolImplCopyWith<_$CaloriesProtocolImpl> get copyWith =>
      __$$CaloriesProtocolImplCopyWithImpl<_$CaloriesProtocolImpl>(
        this,
        _$identity,
      );
}

abstract class _CaloriesProtocol implements CaloriesProtocol {
  const factory _CaloriesProtocol({
    required final int calories,
    required final int protein,
    required final int carbs,
    required final int fat,
  }) = _$CaloriesProtocolImpl;

  @override
  int get calories;
  @override
  int get protein;
  @override
  int get carbs;
  @override
  int get fat;

  /// Create a copy of CaloriesProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$CaloriesProtocolImplCopyWith<_$CaloriesProtocolImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
