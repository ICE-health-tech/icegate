// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'HumanEvaluation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

HumanBodyMetrics _$HumanBodyMetricsFromJson(Map<String, dynamic> json) {
  return _HumanBodyMetrics.fromJson(json);
}

/// @nodoc
mixin _$HumanBodyMetrics {
  double get weight => throw _privateConstructorUsedError; // in kg
  double get height => throw _privateConstructorUsedError; // in cm
  int get age => throw _privateConstructorUsedError;
  String get gender => throw _privateConstructorUsedError; // 'male' or 'female'
  String get activityLevel =>
      throw _privateConstructorUsedError; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  String? get goal => throw _privateConstructorUsedError;

  /// Serializes this HumanBodyMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HumanBodyMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HumanBodyMetricsCopyWith<HumanBodyMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HumanBodyMetricsCopyWith<$Res> {
  factory $HumanBodyMetricsCopyWith(
    HumanBodyMetrics value,
    $Res Function(HumanBodyMetrics) then,
  ) = _$HumanBodyMetricsCopyWithImpl<$Res, HumanBodyMetrics>;
  @useResult
  $Res call({
    double weight,
    double height,
    int age,
    String gender,
    String activityLevel,
    String? goal,
  });
}

/// @nodoc
class _$HumanBodyMetricsCopyWithImpl<$Res, $Val extends HumanBodyMetrics>
    implements $HumanBodyMetricsCopyWith<$Res> {
  _$HumanBodyMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HumanBodyMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? height = null,
    Object? age = null,
    Object? gender = null,
    Object? activityLevel = null,
    Object? goal = freezed,
  }) {
    return _then(
      _value.copyWith(
            weight: null == weight
                ? _value.weight
                : weight // ignore: cast_nullable_to_non_nullable
                      as double,
            height: null == height
                ? _value.height
                : height // ignore: cast_nullable_to_non_nullable
                      as double,
            age: null == age
                ? _value.age
                : age // ignore: cast_nullable_to_non_nullable
                      as int,
            gender: null == gender
                ? _value.gender
                : gender // ignore: cast_nullable_to_non_nullable
                      as String,
            activityLevel: null == activityLevel
                ? _value.activityLevel
                : activityLevel // ignore: cast_nullable_to_non_nullable
                      as String,
            goal: freezed == goal
                ? _value.goal
                : goal // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$HumanBodyMetricsImplCopyWith<$Res>
    implements $HumanBodyMetricsCopyWith<$Res> {
  factory _$$HumanBodyMetricsImplCopyWith(
    _$HumanBodyMetricsImpl value,
    $Res Function(_$HumanBodyMetricsImpl) then,
  ) = __$$HumanBodyMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double weight,
    double height,
    int age,
    String gender,
    String activityLevel,
    String? goal,
  });
}

/// @nodoc
class __$$HumanBodyMetricsImplCopyWithImpl<$Res>
    extends _$HumanBodyMetricsCopyWithImpl<$Res, _$HumanBodyMetricsImpl>
    implements _$$HumanBodyMetricsImplCopyWith<$Res> {
  __$$HumanBodyMetricsImplCopyWithImpl(
    _$HumanBodyMetricsImpl _value,
    $Res Function(_$HumanBodyMetricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HumanBodyMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weight = null,
    Object? height = null,
    Object? age = null,
    Object? gender = null,
    Object? activityLevel = null,
    Object? goal = freezed,
  }) {
    return _then(
      _$HumanBodyMetricsImpl(
        weight: null == weight
            ? _value.weight
            : weight // ignore: cast_nullable_to_non_nullable
                  as double,
        height: null == height
            ? _value.height
            : height // ignore: cast_nullable_to_non_nullable
                  as double,
        age: null == age
            ? _value.age
            : age // ignore: cast_nullable_to_non_nullable
                  as int,
        gender: null == gender
            ? _value.gender
            : gender // ignore: cast_nullable_to_non_nullable
                  as String,
        activityLevel: null == activityLevel
            ? _value.activityLevel
            : activityLevel // ignore: cast_nullable_to_non_nullable
                  as String,
        goal: freezed == goal
            ? _value.goal
            : goal // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HumanBodyMetricsImpl implements _HumanBodyMetrics {
  const _$HumanBodyMetricsImpl({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    this.goal,
  });

  factory _$HumanBodyMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$HumanBodyMetricsImplFromJson(json);

  @override
  final double weight;
  // in kg
  @override
  final double height;
  // in cm
  @override
  final int age;
  @override
  final String gender;
  // 'male' or 'female'
  @override
  final String activityLevel;
  // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  @override
  final String? goal;

  @override
  String toString() {
    return 'HumanBodyMetrics(weight: $weight, height: $height, age: $age, gender: $gender, activityLevel: $activityLevel, goal: $goal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HumanBodyMetricsImpl &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.height, height) || other.height == height) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.gender, gender) || other.gender == gender) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.goal, goal) || other.goal == goal));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    weight,
    height,
    age,
    gender,
    activityLevel,
    goal,
  );

  /// Create a copy of HumanBodyMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HumanBodyMetricsImplCopyWith<_$HumanBodyMetricsImpl> get copyWith =>
      __$$HumanBodyMetricsImplCopyWithImpl<_$HumanBodyMetricsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HumanBodyMetricsImplToJson(this);
  }
}

abstract class _HumanBodyMetrics implements HumanBodyMetrics {
  const factory _HumanBodyMetrics({
    required final double weight,
    required final double height,
    required final int age,
    required final String gender,
    required final String activityLevel,
    final String? goal,
  }) = _$HumanBodyMetricsImpl;

  factory _HumanBodyMetrics.fromJson(Map<String, dynamic> json) =
      _$HumanBodyMetricsImpl.fromJson;

  @override
  double get weight; // in kg
  @override
  double get height; // in cm
  @override
  int get age;
  @override
  String get gender; // 'male' or 'female'
  @override
  String get activityLevel; // 'sedentary', 'light', 'moderate', 'active', 'very_active'
  @override
  String? get goal;

  /// Create a copy of HumanBodyMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HumanBodyMetricsImplCopyWith<_$HumanBodyMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BloodTestMetrics _$BloodTestMetricsFromJson(Map<String, dynamic> json) {
  return _BloodTestMetrics.fromJson(json);
}

/// @nodoc
mixin _$BloodTestMetrics {
  double? get glucose => throw _privateConstructorUsedError; // mg/dL
  double? get cholesterol => throw _privateConstructorUsedError; // mg/dL
  double? get hdl =>
      throw _privateConstructorUsedError; // mg/dL (good cholesterol)
  double? get ldl =>
      throw _privateConstructorUsedError; // mg/dL (bad cholesterol)
  double? get triglycerides => throw _privateConstructorUsedError; // mg/dL
  double? get hemoglobin => throw _privateConstructorUsedError; // g/dL
  double? get whiteBloodCells =>
      throw _privateConstructorUsedError; // cells/mcL
  double? get platelets => throw _privateConstructorUsedError; // cells/mcL
  String? get bloodType => throw _privateConstructorUsedError;

  /// Serializes this BloodTestMetrics to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of BloodTestMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BloodTestMetricsCopyWith<BloodTestMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BloodTestMetricsCopyWith<$Res> {
  factory $BloodTestMetricsCopyWith(
    BloodTestMetrics value,
    $Res Function(BloodTestMetrics) then,
  ) = _$BloodTestMetricsCopyWithImpl<$Res, BloodTestMetrics>;
  @useResult
  $Res call({
    double? glucose,
    double? cholesterol,
    double? hdl,
    double? ldl,
    double? triglycerides,
    double? hemoglobin,
    double? whiteBloodCells,
    double? platelets,
    String? bloodType,
  });
}

/// @nodoc
class _$BloodTestMetricsCopyWithImpl<$Res, $Val extends BloodTestMetrics>
    implements $BloodTestMetricsCopyWith<$Res> {
  _$BloodTestMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BloodTestMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? glucose = freezed,
    Object? cholesterol = freezed,
    Object? hdl = freezed,
    Object? ldl = freezed,
    Object? triglycerides = freezed,
    Object? hemoglobin = freezed,
    Object? whiteBloodCells = freezed,
    Object? platelets = freezed,
    Object? bloodType = freezed,
  }) {
    return _then(
      _value.copyWith(
            glucose: freezed == glucose
                ? _value.glucose
                : glucose // ignore: cast_nullable_to_non_nullable
                      as double?,
            cholesterol: freezed == cholesterol
                ? _value.cholesterol
                : cholesterol // ignore: cast_nullable_to_non_nullable
                      as double?,
            hdl: freezed == hdl
                ? _value.hdl
                : hdl // ignore: cast_nullable_to_non_nullable
                      as double?,
            ldl: freezed == ldl
                ? _value.ldl
                : ldl // ignore: cast_nullable_to_non_nullable
                      as double?,
            triglycerides: freezed == triglycerides
                ? _value.triglycerides
                : triglycerides // ignore: cast_nullable_to_non_nullable
                      as double?,
            hemoglobin: freezed == hemoglobin
                ? _value.hemoglobin
                : hemoglobin // ignore: cast_nullable_to_non_nullable
                      as double?,
            whiteBloodCells: freezed == whiteBloodCells
                ? _value.whiteBloodCells
                : whiteBloodCells // ignore: cast_nullable_to_non_nullable
                      as double?,
            platelets: freezed == platelets
                ? _value.platelets
                : platelets // ignore: cast_nullable_to_non_nullable
                      as double?,
            bloodType: freezed == bloodType
                ? _value.bloodType
                : bloodType // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BloodTestMetricsImplCopyWith<$Res>
    implements $BloodTestMetricsCopyWith<$Res> {
  factory _$$BloodTestMetricsImplCopyWith(
    _$BloodTestMetricsImpl value,
    $Res Function(_$BloodTestMetricsImpl) then,
  ) = __$$BloodTestMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    double? glucose,
    double? cholesterol,
    double? hdl,
    double? ldl,
    double? triglycerides,
    double? hemoglobin,
    double? whiteBloodCells,
    double? platelets,
    String? bloodType,
  });
}

/// @nodoc
class __$$BloodTestMetricsImplCopyWithImpl<$Res>
    extends _$BloodTestMetricsCopyWithImpl<$Res, _$BloodTestMetricsImpl>
    implements _$$BloodTestMetricsImplCopyWith<$Res> {
  __$$BloodTestMetricsImplCopyWithImpl(
    _$BloodTestMetricsImpl _value,
    $Res Function(_$BloodTestMetricsImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BloodTestMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? glucose = freezed,
    Object? cholesterol = freezed,
    Object? hdl = freezed,
    Object? ldl = freezed,
    Object? triglycerides = freezed,
    Object? hemoglobin = freezed,
    Object? whiteBloodCells = freezed,
    Object? platelets = freezed,
    Object? bloodType = freezed,
  }) {
    return _then(
      _$BloodTestMetricsImpl(
        glucose: freezed == glucose
            ? _value.glucose
            : glucose // ignore: cast_nullable_to_non_nullable
                  as double?,
        cholesterol: freezed == cholesterol
            ? _value.cholesterol
            : cholesterol // ignore: cast_nullable_to_non_nullable
                  as double?,
        hdl: freezed == hdl
            ? _value.hdl
            : hdl // ignore: cast_nullable_to_non_nullable
                  as double?,
        ldl: freezed == ldl
            ? _value.ldl
            : ldl // ignore: cast_nullable_to_non_nullable
                  as double?,
        triglycerides: freezed == triglycerides
            ? _value.triglycerides
            : triglycerides // ignore: cast_nullable_to_non_nullable
                  as double?,
        hemoglobin: freezed == hemoglobin
            ? _value.hemoglobin
            : hemoglobin // ignore: cast_nullable_to_non_nullable
                  as double?,
        whiteBloodCells: freezed == whiteBloodCells
            ? _value.whiteBloodCells
            : whiteBloodCells // ignore: cast_nullable_to_non_nullable
                  as double?,
        platelets: freezed == platelets
            ? _value.platelets
            : platelets // ignore: cast_nullable_to_non_nullable
                  as double?,
        bloodType: freezed == bloodType
            ? _value.bloodType
            : bloodType // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$BloodTestMetricsImpl implements _BloodTestMetrics {
  const _$BloodTestMetricsImpl({
    this.glucose,
    this.cholesterol,
    this.hdl,
    this.ldl,
    this.triglycerides,
    this.hemoglobin,
    this.whiteBloodCells,
    this.platelets,
    this.bloodType,
  });

  factory _$BloodTestMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BloodTestMetricsImplFromJson(json);

  @override
  final double? glucose;
  // mg/dL
  @override
  final double? cholesterol;
  // mg/dL
  @override
  final double? hdl;
  // mg/dL (good cholesterol)
  @override
  final double? ldl;
  // mg/dL (bad cholesterol)
  @override
  final double? triglycerides;
  // mg/dL
  @override
  final double? hemoglobin;
  // g/dL
  @override
  final double? whiteBloodCells;
  // cells/mcL
  @override
  final double? platelets;
  // cells/mcL
  @override
  final String? bloodType;

  @override
  String toString() {
    return 'BloodTestMetrics(glucose: $glucose, cholesterol: $cholesterol, hdl: $hdl, ldl: $ldl, triglycerides: $triglycerides, hemoglobin: $hemoglobin, whiteBloodCells: $whiteBloodCells, platelets: $platelets, bloodType: $bloodType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BloodTestMetricsImpl &&
            (identical(other.glucose, glucose) || other.glucose == glucose) &&
            (identical(other.cholesterol, cholesterol) ||
                other.cholesterol == cholesterol) &&
            (identical(other.hdl, hdl) || other.hdl == hdl) &&
            (identical(other.ldl, ldl) || other.ldl == ldl) &&
            (identical(other.triglycerides, triglycerides) ||
                other.triglycerides == triglycerides) &&
            (identical(other.hemoglobin, hemoglobin) ||
                other.hemoglobin == hemoglobin) &&
            (identical(other.whiteBloodCells, whiteBloodCells) ||
                other.whiteBloodCells == whiteBloodCells) &&
            (identical(other.platelets, platelets) ||
                other.platelets == platelets) &&
            (identical(other.bloodType, bloodType) ||
                other.bloodType == bloodType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    glucose,
    cholesterol,
    hdl,
    ldl,
    triglycerides,
    hemoglobin,
    whiteBloodCells,
    platelets,
    bloodType,
  );

  /// Create a copy of BloodTestMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BloodTestMetricsImplCopyWith<_$BloodTestMetricsImpl> get copyWith =>
      __$$BloodTestMetricsImplCopyWithImpl<_$BloodTestMetricsImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$BloodTestMetricsImplToJson(this);
  }
}

abstract class _BloodTestMetrics implements BloodTestMetrics {
  const factory _BloodTestMetrics({
    final double? glucose,
    final double? cholesterol,
    final double? hdl,
    final double? ldl,
    final double? triglycerides,
    final double? hemoglobin,
    final double? whiteBloodCells,
    final double? platelets,
    final String? bloodType,
  }) = _$BloodTestMetricsImpl;

  factory _BloodTestMetrics.fromJson(Map<String, dynamic> json) =
      _$BloodTestMetricsImpl.fromJson;

  @override
  double? get glucose; // mg/dL
  @override
  double? get cholesterol; // mg/dL
  @override
  double? get hdl; // mg/dL (good cholesterol)
  @override
  double? get ldl; // mg/dL (bad cholesterol)
  @override
  double? get triglycerides; // mg/dL
  @override
  double? get hemoglobin; // g/dL
  @override
  double? get whiteBloodCells; // cells/mcL
  @override
  double? get platelets; // cells/mcL
  @override
  String? get bloodType;

  /// Create a copy of BloodTestMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BloodTestMetricsImplCopyWith<_$BloodTestMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HumanInputValues _$HumanInputValuesFromJson(Map<String, dynamic> json) {
  return _HumanInputValues.fromJson(json);
}

/// @nodoc
mixin _$HumanInputValues {
  HumanBodyMetrics get humanBodyMetrics => throw _privateConstructorUsedError;
  BloodTestMetrics get bloodTestMetrics => throw _privateConstructorUsedError;
  TargetCaloriesProtocol get caloriesProtocol =>
      throw _privateConstructorUsedError;

  /// Serializes this HumanInputValues to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HumanInputValuesCopyWith<HumanInputValues> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HumanInputValuesCopyWith<$Res> {
  factory $HumanInputValuesCopyWith(
    HumanInputValues value,
    $Res Function(HumanInputValues) then,
  ) = _$HumanInputValuesCopyWithImpl<$Res, HumanInputValues>;
  @useResult
  $Res call({
    HumanBodyMetrics humanBodyMetrics,
    BloodTestMetrics bloodTestMetrics,
    TargetCaloriesProtocol caloriesProtocol,
  });

  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics;
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics;
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol;
}

/// @nodoc
class _$HumanInputValuesCopyWithImpl<$Res, $Val extends HumanInputValues>
    implements $HumanInputValuesCopyWith<$Res> {
  _$HumanInputValuesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? humanBodyMetrics = null,
    Object? bloodTestMetrics = null,
    Object? caloriesProtocol = null,
  }) {
    return _then(
      _value.copyWith(
            humanBodyMetrics: null == humanBodyMetrics
                ? _value.humanBodyMetrics
                : humanBodyMetrics // ignore: cast_nullable_to_non_nullable
                      as HumanBodyMetrics,
            bloodTestMetrics: null == bloodTestMetrics
                ? _value.bloodTestMetrics
                : bloodTestMetrics // ignore: cast_nullable_to_non_nullable
                      as BloodTestMetrics,
            caloriesProtocol: null == caloriesProtocol
                ? _value.caloriesProtocol
                : caloriesProtocol // ignore: cast_nullable_to_non_nullable
                      as TargetCaloriesProtocol,
          )
          as $Val,
    );
  }

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics {
    return $HumanBodyMetricsCopyWith<$Res>(_value.humanBodyMetrics, (value) {
      return _then(_value.copyWith(humanBodyMetrics: value) as $Val);
    });
  }

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics {
    return $BloodTestMetricsCopyWith<$Res>(_value.bloodTestMetrics, (value) {
      return _then(_value.copyWith(bloodTestMetrics: value) as $Val);
    });
  }

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol {
    return $TargetCaloriesProtocolCopyWith<$Res>(_value.caloriesProtocol, (
      value,
    ) {
      return _then(_value.copyWith(caloriesProtocol: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HumanInputValuesImplCopyWith<$Res>
    implements $HumanInputValuesCopyWith<$Res> {
  factory _$$HumanInputValuesImplCopyWith(
    _$HumanInputValuesImpl value,
    $Res Function(_$HumanInputValuesImpl) then,
  ) = __$$HumanInputValuesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    HumanBodyMetrics humanBodyMetrics,
    BloodTestMetrics bloodTestMetrics,
    TargetCaloriesProtocol caloriesProtocol,
  });

  @override
  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics;
  @override
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics;
  @override
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol;
}

/// @nodoc
class __$$HumanInputValuesImplCopyWithImpl<$Res>
    extends _$HumanInputValuesCopyWithImpl<$Res, _$HumanInputValuesImpl>
    implements _$$HumanInputValuesImplCopyWith<$Res> {
  __$$HumanInputValuesImplCopyWithImpl(
    _$HumanInputValuesImpl _value,
    $Res Function(_$HumanInputValuesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? humanBodyMetrics = null,
    Object? bloodTestMetrics = null,
    Object? caloriesProtocol = null,
  }) {
    return _then(
      _$HumanInputValuesImpl(
        humanBodyMetrics: null == humanBodyMetrics
            ? _value.humanBodyMetrics
            : humanBodyMetrics // ignore: cast_nullable_to_non_nullable
                  as HumanBodyMetrics,
        bloodTestMetrics: null == bloodTestMetrics
            ? _value.bloodTestMetrics
            : bloodTestMetrics // ignore: cast_nullable_to_non_nullable
                  as BloodTestMetrics,
        caloriesProtocol: null == caloriesProtocol
            ? _value.caloriesProtocol
            : caloriesProtocol // ignore: cast_nullable_to_non_nullable
                  as TargetCaloriesProtocol,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HumanInputValuesImpl implements _HumanInputValues {
  const _$HumanInputValuesImpl({
    required this.humanBodyMetrics,
    required this.bloodTestMetrics,
    required this.caloriesProtocol,
  });

  factory _$HumanInputValuesImpl.fromJson(Map<String, dynamic> json) =>
      _$$HumanInputValuesImplFromJson(json);

  @override
  final HumanBodyMetrics humanBodyMetrics;
  @override
  final BloodTestMetrics bloodTestMetrics;
  @override
  final TargetCaloriesProtocol caloriesProtocol;

  @override
  String toString() {
    return 'HumanInputValues(humanBodyMetrics: $humanBodyMetrics, bloodTestMetrics: $bloodTestMetrics, caloriesProtocol: $caloriesProtocol)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HumanInputValuesImpl &&
            (identical(other.humanBodyMetrics, humanBodyMetrics) ||
                other.humanBodyMetrics == humanBodyMetrics) &&
            (identical(other.bloodTestMetrics, bloodTestMetrics) ||
                other.bloodTestMetrics == bloodTestMetrics) &&
            (identical(other.caloriesProtocol, caloriesProtocol) ||
                other.caloriesProtocol == caloriesProtocol));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    humanBodyMetrics,
    bloodTestMetrics,
    caloriesProtocol,
  );

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HumanInputValuesImplCopyWith<_$HumanInputValuesImpl> get copyWith =>
      __$$HumanInputValuesImplCopyWithImpl<_$HumanInputValuesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HumanInputValuesImplToJson(this);
  }
}

abstract class _HumanInputValues implements HumanInputValues {
  const factory _HumanInputValues({
    required final HumanBodyMetrics humanBodyMetrics,
    required final BloodTestMetrics bloodTestMetrics,
    required final TargetCaloriesProtocol caloriesProtocol,
  }) = _$HumanInputValuesImpl;

  factory _HumanInputValues.fromJson(Map<String, dynamic> json) =
      _$HumanInputValuesImpl.fromJson;

  @override
  HumanBodyMetrics get humanBodyMetrics;
  @override
  BloodTestMetrics get bloodTestMetrics;
  @override
  TargetCaloriesProtocol get caloriesProtocol;

  /// Create a copy of HumanInputValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HumanInputValuesImplCopyWith<_$HumanInputValuesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HumanTargetValues _$HumanTargetValuesFromJson(Map<String, dynamic> json) {
  return _HumanTargetValues.fromJson(json);
}

/// @nodoc
mixin _$HumanTargetValues {
  HumanBodyMetrics get humanBodyMetrics => throw _privateConstructorUsedError;
  BloodTestMetrics get bloodTestMetrics => throw _privateConstructorUsedError;
  TargetCaloriesProtocol get caloriesProtocol =>
      throw _privateConstructorUsedError;
  double? get bmi => throw _privateConstructorUsedError; // Body Mass Index
  double? get bmr => throw _privateConstructorUsedError; // Basal Metabolic Rate
  double? get tdee =>
      throw _privateConstructorUsedError; // Total Daily Energy Expenditure
  String? get healthStatus =>
      throw _privateConstructorUsedError; // 'excellent', 'good', 'fair', 'poor'
  List<String>? get recommendations => throw _privateConstructorUsedError;

  /// Serializes this HumanTargetValues to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $HumanTargetValuesCopyWith<HumanTargetValues> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HumanTargetValuesCopyWith<$Res> {
  factory $HumanTargetValuesCopyWith(
    HumanTargetValues value,
    $Res Function(HumanTargetValues) then,
  ) = _$HumanTargetValuesCopyWithImpl<$Res, HumanTargetValues>;
  @useResult
  $Res call({
    HumanBodyMetrics humanBodyMetrics,
    BloodTestMetrics bloodTestMetrics,
    TargetCaloriesProtocol caloriesProtocol,
    double? bmi,
    double? bmr,
    double? tdee,
    String? healthStatus,
    List<String>? recommendations,
  });

  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics;
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics;
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol;
}

/// @nodoc
class _$HumanTargetValuesCopyWithImpl<$Res, $Val extends HumanTargetValues>
    implements $HumanTargetValuesCopyWith<$Res> {
  _$HumanTargetValuesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? humanBodyMetrics = null,
    Object? bloodTestMetrics = null,
    Object? caloriesProtocol = null,
    Object? bmi = freezed,
    Object? bmr = freezed,
    Object? tdee = freezed,
    Object? healthStatus = freezed,
    Object? recommendations = freezed,
  }) {
    return _then(
      _value.copyWith(
            humanBodyMetrics: null == humanBodyMetrics
                ? _value.humanBodyMetrics
                : humanBodyMetrics // ignore: cast_nullable_to_non_nullable
                      as HumanBodyMetrics,
            bloodTestMetrics: null == bloodTestMetrics
                ? _value.bloodTestMetrics
                : bloodTestMetrics // ignore: cast_nullable_to_non_nullable
                      as BloodTestMetrics,
            caloriesProtocol: null == caloriesProtocol
                ? _value.caloriesProtocol
                : caloriesProtocol // ignore: cast_nullable_to_non_nullable
                      as TargetCaloriesProtocol,
            bmi: freezed == bmi
                ? _value.bmi
                : bmi // ignore: cast_nullable_to_non_nullable
                      as double?,
            bmr: freezed == bmr
                ? _value.bmr
                : bmr // ignore: cast_nullable_to_non_nullable
                      as double?,
            tdee: freezed == tdee
                ? _value.tdee
                : tdee // ignore: cast_nullable_to_non_nullable
                      as double?,
            healthStatus: freezed == healthStatus
                ? _value.healthStatus
                : healthStatus // ignore: cast_nullable_to_non_nullable
                      as String?,
            recommendations: freezed == recommendations
                ? _value.recommendations
                : recommendations // ignore: cast_nullable_to_non_nullable
                      as List<String>?,
          )
          as $Val,
    );
  }

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics {
    return $HumanBodyMetricsCopyWith<$Res>(_value.humanBodyMetrics, (value) {
      return _then(_value.copyWith(humanBodyMetrics: value) as $Val);
    });
  }

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics {
    return $BloodTestMetricsCopyWith<$Res>(_value.bloodTestMetrics, (value) {
      return _then(_value.copyWith(bloodTestMetrics: value) as $Val);
    });
  }

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol {
    return $TargetCaloriesProtocolCopyWith<$Res>(_value.caloriesProtocol, (
      value,
    ) {
      return _then(_value.copyWith(caloriesProtocol: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HumanTargetValuesImplCopyWith<$Res>
    implements $HumanTargetValuesCopyWith<$Res> {
  factory _$$HumanTargetValuesImplCopyWith(
    _$HumanTargetValuesImpl value,
    $Res Function(_$HumanTargetValuesImpl) then,
  ) = __$$HumanTargetValuesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    HumanBodyMetrics humanBodyMetrics,
    BloodTestMetrics bloodTestMetrics,
    TargetCaloriesProtocol caloriesProtocol,
    double? bmi,
    double? bmr,
    double? tdee,
    String? healthStatus,
    List<String>? recommendations,
  });

  @override
  $HumanBodyMetricsCopyWith<$Res> get humanBodyMetrics;
  @override
  $BloodTestMetricsCopyWith<$Res> get bloodTestMetrics;
  @override
  $TargetCaloriesProtocolCopyWith<$Res> get caloriesProtocol;
}

/// @nodoc
class __$$HumanTargetValuesImplCopyWithImpl<$Res>
    extends _$HumanTargetValuesCopyWithImpl<$Res, _$HumanTargetValuesImpl>
    implements _$$HumanTargetValuesImplCopyWith<$Res> {
  __$$HumanTargetValuesImplCopyWithImpl(
    _$HumanTargetValuesImpl _value,
    $Res Function(_$HumanTargetValuesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? humanBodyMetrics = null,
    Object? bloodTestMetrics = null,
    Object? caloriesProtocol = null,
    Object? bmi = freezed,
    Object? bmr = freezed,
    Object? tdee = freezed,
    Object? healthStatus = freezed,
    Object? recommendations = freezed,
  }) {
    return _then(
      _$HumanTargetValuesImpl(
        humanBodyMetrics: null == humanBodyMetrics
            ? _value.humanBodyMetrics
            : humanBodyMetrics // ignore: cast_nullable_to_non_nullable
                  as HumanBodyMetrics,
        bloodTestMetrics: null == bloodTestMetrics
            ? _value.bloodTestMetrics
            : bloodTestMetrics // ignore: cast_nullable_to_non_nullable
                  as BloodTestMetrics,
        caloriesProtocol: null == caloriesProtocol
            ? _value.caloriesProtocol
            : caloriesProtocol // ignore: cast_nullable_to_non_nullable
                  as TargetCaloriesProtocol,
        bmi: freezed == bmi
            ? _value.bmi
            : bmi // ignore: cast_nullable_to_non_nullable
                  as double?,
        bmr: freezed == bmr
            ? _value.bmr
            : bmr // ignore: cast_nullable_to_non_nullable
                  as double?,
        tdee: freezed == tdee
            ? _value.tdee
            : tdee // ignore: cast_nullable_to_non_nullable
                  as double?,
        healthStatus: freezed == healthStatus
            ? _value.healthStatus
            : healthStatus // ignore: cast_nullable_to_non_nullable
                  as String?,
        recommendations: freezed == recommendations
            ? _value._recommendations
            : recommendations // ignore: cast_nullable_to_non_nullable
                  as List<String>?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$HumanTargetValuesImpl implements _HumanTargetValues {
  const _$HumanTargetValuesImpl({
    required this.humanBodyMetrics,
    required this.bloodTestMetrics,
    required this.caloriesProtocol,
    this.bmi,
    this.bmr,
    this.tdee,
    this.healthStatus,
    final List<String>? recommendations,
  }) : _recommendations = recommendations;

  factory _$HumanTargetValuesImpl.fromJson(Map<String, dynamic> json) =>
      _$$HumanTargetValuesImplFromJson(json);

  @override
  final HumanBodyMetrics humanBodyMetrics;
  @override
  final BloodTestMetrics bloodTestMetrics;
  @override
  final TargetCaloriesProtocol caloriesProtocol;
  @override
  final double? bmi;
  // Body Mass Index
  @override
  final double? bmr;
  // Basal Metabolic Rate
  @override
  final double? tdee;
  // Total Daily Energy Expenditure
  @override
  final String? healthStatus;
  // 'excellent', 'good', 'fair', 'poor'
  final List<String>? _recommendations;
  // 'excellent', 'good', 'fair', 'poor'
  @override
  List<String>? get recommendations {
    final value = _recommendations;
    if (value == null) return null;
    if (_recommendations is EqualUnmodifiableListView) return _recommendations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  String toString() {
    return 'HumanTargetValues(humanBodyMetrics: $humanBodyMetrics, bloodTestMetrics: $bloodTestMetrics, caloriesProtocol: $caloriesProtocol, bmi: $bmi, bmr: $bmr, tdee: $tdee, healthStatus: $healthStatus, recommendations: $recommendations)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HumanTargetValuesImpl &&
            (identical(other.humanBodyMetrics, humanBodyMetrics) ||
                other.humanBodyMetrics == humanBodyMetrics) &&
            (identical(other.bloodTestMetrics, bloodTestMetrics) ||
                other.bloodTestMetrics == bloodTestMetrics) &&
            (identical(other.caloriesProtocol, caloriesProtocol) ||
                other.caloriesProtocol == caloriesProtocol) &&
            (identical(other.bmi, bmi) || other.bmi == bmi) &&
            (identical(other.bmr, bmr) || other.bmr == bmr) &&
            (identical(other.tdee, tdee) || other.tdee == tdee) &&
            (identical(other.healthStatus, healthStatus) ||
                other.healthStatus == healthStatus) &&
            const DeepCollectionEquality().equals(
              other._recommendations,
              _recommendations,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    humanBodyMetrics,
    bloodTestMetrics,
    caloriesProtocol,
    bmi,
    bmr,
    tdee,
    healthStatus,
    const DeepCollectionEquality().hash(_recommendations),
  );

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$HumanTargetValuesImplCopyWith<_$HumanTargetValuesImpl> get copyWith =>
      __$$HumanTargetValuesImplCopyWithImpl<_$HumanTargetValuesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$HumanTargetValuesImplToJson(this);
  }
}

abstract class _HumanTargetValues implements HumanTargetValues {
  const factory _HumanTargetValues({
    required final HumanBodyMetrics humanBodyMetrics,
    required final BloodTestMetrics bloodTestMetrics,
    required final TargetCaloriesProtocol caloriesProtocol,
    final double? bmi,
    final double? bmr,
    final double? tdee,
    final String? healthStatus,
    final List<String>? recommendations,
  }) = _$HumanTargetValuesImpl;

  factory _HumanTargetValues.fromJson(Map<String, dynamic> json) =
      _$HumanTargetValuesImpl.fromJson;

  @override
  HumanBodyMetrics get humanBodyMetrics;
  @override
  BloodTestMetrics get bloodTestMetrics;
  @override
  TargetCaloriesProtocol get caloriesProtocol;
  @override
  double? get bmi; // Body Mass Index
  @override
  double? get bmr; // Basal Metabolic Rate
  @override
  double? get tdee; // Total Daily Energy Expenditure
  @override
  String? get healthStatus; // 'excellent', 'good', 'fair', 'poor'
  @override
  List<String>? get recommendations;

  /// Create a copy of HumanTargetValues
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$HumanTargetValuesImplCopyWith<_$HumanTargetValuesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
