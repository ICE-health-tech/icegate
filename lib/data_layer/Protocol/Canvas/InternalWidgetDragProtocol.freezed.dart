// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'InternalWidgetDragProtocol.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InternalWidgetDragProtocol _$InternalWidgetDragProtocolFromJson(
  Map<String, dynamic> json,
) {
  return _Item.fromJson(json);
}

/// @nodoc
mixin _$InternalWidgetDragProtocol {
  // --- Parent Fields ---
  String get url => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get imageUrl => throw _privateConstructorUsedError;
  String get alias => throw _privateConstructorUsedError;
  String get dateAdded => throw _privateConstructorUsedError;
  int get widgetID =>
      throw _privateConstructorUsedError; // --- UI Fields (From your Flutter Code) ---
  // We exclude Icon/String from JSON because they aren't natively serializable
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get color => throw _privateConstructorUsedError; // @JsonKey(includeFromJson: false, includeToJson: false) @Default(Icon(Icons.rectangle)) Icon icon,
  // --- State Fields ---
  bool get isStay => throw _privateConstructorUsedError;
  bool get isTarget => throw _privateConstructorUsedError;
  int get score => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )
    item,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )?
    item,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )?
    item,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Item value) item,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Item value)? item,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Item value)? item,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;

  /// Serializes this InternalWidgetDragProtocol to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InternalWidgetDragProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InternalWidgetDragProtocolCopyWith<InternalWidgetDragProtocol>
  get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InternalWidgetDragProtocolCopyWith<$Res> {
  factory $InternalWidgetDragProtocolCopyWith(
    InternalWidgetDragProtocol value,
    $Res Function(InternalWidgetDragProtocol) then,
  ) =
      _$InternalWidgetDragProtocolCopyWithImpl<
        $Res,
        InternalWidgetDragProtocol
      >;
  @useResult
  $Res call({
    String url,
    String name,
    String imageUrl,
    String alias,
    String dateAdded,
    int widgetID,
    @JsonKey(includeFromJson: false, includeToJson: false) String color,
    bool isStay,
    bool isTarget,
    int score,
  });
}

/// @nodoc
class _$InternalWidgetDragProtocolCopyWithImpl<
  $Res,
  $Val extends InternalWidgetDragProtocol
>
    implements $InternalWidgetDragProtocolCopyWith<$Res> {
  _$InternalWidgetDragProtocolCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InternalWidgetDragProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? alias = null,
    Object? dateAdded = null,
    Object? widgetID = null,
    Object? color = null,
    Object? isStay = null,
    Object? isTarget = null,
    Object? score = null,
  }) {
    return _then(
      _value.copyWith(
            url: null == url
                ? _value.url
                : url // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: null == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String,
            alias: null == alias
                ? _value.alias
                : alias // ignore: cast_nullable_to_non_nullable
                      as String,
            dateAdded: null == dateAdded
                ? _value.dateAdded
                : dateAdded // ignore: cast_nullable_to_non_nullable
                      as String,
            widgetID: null == widgetID
                ? _value.widgetID
                : widgetID // ignore: cast_nullable_to_non_nullable
                      as int,
            color: null == color
                ? _value.color
                : color // ignore: cast_nullable_to_non_nullable
                      as String,
            isStay: null == isStay
                ? _value.isStay
                : isStay // ignore: cast_nullable_to_non_nullable
                      as bool,
            isTarget: null == isTarget
                ? _value.isTarget
                : isTarget // ignore: cast_nullable_to_non_nullable
                      as bool,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ItemImplCopyWith<$Res>
    implements $InternalWidgetDragProtocolCopyWith<$Res> {
  factory _$$ItemImplCopyWith(
    _$ItemImpl value,
    $Res Function(_$ItemImpl) then,
  ) = __$$ItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String url,
    String name,
    String imageUrl,
    String alias,
    String dateAdded,
    int widgetID,
    @JsonKey(includeFromJson: false, includeToJson: false) String color,
    bool isStay,
    bool isTarget,
    int score,
  });
}

/// @nodoc
class __$$ItemImplCopyWithImpl<$Res>
    extends _$InternalWidgetDragProtocolCopyWithImpl<$Res, _$ItemImpl>
    implements _$$ItemImplCopyWith<$Res> {
  __$$ItemImplCopyWithImpl(_$ItemImpl _value, $Res Function(_$ItemImpl) _then)
    : super(_value, _then);

  /// Create a copy of InternalWidgetDragProtocol
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? url = null,
    Object? name = null,
    Object? imageUrl = null,
    Object? alias = null,
    Object? dateAdded = null,
    Object? widgetID = null,
    Object? color = null,
    Object? isStay = null,
    Object? isTarget = null,
    Object? score = null,
  }) {
    return _then(
      _$ItemImpl(
        url: null == url
            ? _value.url
            : url // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: null == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String,
        alias: null == alias
            ? _value.alias
            : alias // ignore: cast_nullable_to_non_nullable
                  as String,
        dateAdded: null == dateAdded
            ? _value.dateAdded
            : dateAdded // ignore: cast_nullable_to_non_nullable
                  as String,
        widgetID: null == widgetID
            ? _value.widgetID
            : widgetID // ignore: cast_nullable_to_non_nullable
                  as int,
        color: null == color
            ? _value.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        isStay: null == isStay
            ? _value.isStay
            : isStay // ignore: cast_nullable_to_non_nullable
                  as bool,
        isTarget: null == isTarget
            ? _value.isTarget
            : isTarget // ignore: cast_nullable_to_non_nullable
                  as bool,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ItemImpl extends _Item {
  _$ItemImpl({
    required this.url,
    required this.name,
    required this.imageUrl,
    required this.alias,
    required this.dateAdded,
    required this.widgetID,
    @JsonKey(includeFromJson: false, includeToJson: false) this.color = 'white',
    this.isStay = false,
    this.isTarget = false,
    this.score = 0,
  }) : super._();

  factory _$ItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$ItemImplFromJson(json);

  // --- Parent Fields ---
  @override
  final String url;
  @override
  final String name;
  @override
  final String imageUrl;
  @override
  final String alias;
  @override
  final String dateAdded;
  @override
  final int widgetID;
  // --- UI Fields (From your Flutter Code) ---
  // We exclude Icon/String from JSON because they aren't natively serializable
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String color;
  // @JsonKey(includeFromJson: false, includeToJson: false) @Default(Icon(Icons.rectangle)) Icon icon,
  // --- State Fields ---
  @override
  @JsonKey()
  final bool isStay;
  @override
  @JsonKey()
  final bool isTarget;
  @override
  @JsonKey()
  final int score;

  @override
  String toString() {
    return 'InternalWidgetDragProtocol.item(url: $url, name: $name, imageUrl: $imageUrl, alias: $alias, dateAdded: $dateAdded, widgetID: $widgetID, color: $color, isStay: $isStay, isTarget: $isTarget, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ItemImpl &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.alias, alias) || other.alias == alias) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded) &&
            (identical(other.widgetID, widgetID) ||
                other.widgetID == widgetID) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.isStay, isStay) || other.isStay == isStay) &&
            (identical(other.isTarget, isTarget) ||
                other.isTarget == isTarget) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    url,
    name,
    imageUrl,
    alias,
    dateAdded,
    widgetID,
    color,
    isStay,
    isTarget,
    score,
  );

  /// Create a copy of InternalWidgetDragProtocol
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      __$$ItemImplCopyWithImpl<_$ItemImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )
    item,
  }) {
    return item(
      url,
      name,
      imageUrl,
      alias,
      dateAdded,
      widgetID,
      color,
      isStay,
      isTarget,
      score,
    );
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )?
    item,
  }) {
    return item?.call(
      url,
      name,
      imageUrl,
      alias,
      dateAdded,
      widgetID,
      color,
      isStay,
      isTarget,
      score,
    );
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(
      String url,
      String name,
      String imageUrl,
      String alias,
      String dateAdded,
      int widgetID,
      @JsonKey(includeFromJson: false, includeToJson: false) String color,
      bool isStay,
      bool isTarget,
      int score,
    )?
    item,
    required TResult orElse(),
  }) {
    if (item != null) {
      return item(
        url,
        name,
        imageUrl,
        alias,
        dateAdded,
        widgetID,
        color,
        isStay,
        isTarget,
        score,
      );
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(_Item value) item,
  }) {
    return item(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(_Item value)? item,
  }) {
    return item?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(_Item value)? item,
    required TResult orElse(),
  }) {
    if (item != null) {
      return item(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ItemImplToJson(this);
  }
}

abstract class _Item extends InternalWidgetDragProtocol {
  factory _Item({
    required final String url,
    required final String name,
    required final String imageUrl,
    required final String alias,
    required final String dateAdded,
    required final int widgetID,
    @JsonKey(includeFromJson: false, includeToJson: false) final String color,
    final bool isStay,
    final bool isTarget,
    final int score,
  }) = _$ItemImpl;
  _Item._() : super._();

  factory _Item.fromJson(Map<String, dynamic> json) = _$ItemImpl.fromJson;

  // --- Parent Fields ---
  @override
  String get url;
  @override
  String get name;
  @override
  String get imageUrl;
  @override
  String get alias;
  @override
  String get dateAdded;
  @override
  int get widgetID; // --- UI Fields (From your Flutter Code) ---
  // We exclude Icon/String from JSON because they aren't natively serializable
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String get color; // @JsonKey(includeFromJson: false, includeToJson: false) @Default(Icon(Icons.rectangle)) Icon icon,
  // --- State Fields ---
  @override
  bool get isStay;
  @override
  bool get isTarget;
  @override
  int get score;

  /// Create a copy of InternalWidgetDragProtocol
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ItemImplCopyWith<_$ItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
