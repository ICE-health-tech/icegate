import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ice_gate/orchestration_layer/IDGen.dart';

import '../Home/InternalWidgetProtocol.dart';
// import '../IDGen.dart';
// Required for code generation
part 'InternalWidgetDragProtocol.freezed.dart';

part 'InternalWidgetDragProtocol.g.dart';
// part 'InternalWidgetDragProtocol.g.dart';

// --- 1. PARENT PROTOCOL CLASS ---
// // Must have a const constructor to be extended by Freezed
// abstract class InternalWidgetProtocol {
//   final String url;
//   final String name;
//   final String imageUrl;
//   final String alias;
//   final String dateAdded;
//   final String widgetID;
//
//   const InternalWidgetProtocol({
//     required this.url,
//     required this.name,
//     required this.imageUrl,
//     required this.alias,
//     required this.dateAdded,
//     required this.widgetID,
//   });
// }

// --- 2. FREEZED IMPLEMENTATION ---
@freezed
abstract class InternalWidgetDragProtocol extends InternalWidgetProtocol
    with _$InternalWidgetDragProtocol {
  // Private constructor is REQUIRED to extend a class
  InternalWidgetDragProtocol._()
    : super(
        url: '', // defaults or passed via factory parameters (see below)
        name: '',
        imageUrl: '',
        alias: '',
        dateAdded: '',
        widgetID: IDGen.UUIDV7(),
      );

  // We use a single factory that implements the parent fields + new fields
  // We merge the 'Drag' and 'Target' concepts into the properties to keep it compatible with your grid UI
  factory InternalWidgetDragProtocol.item({
    // --- Parent Fields ---
    required String url,
    required String name,
    required String imageUrl,
    required String alias,
    required String dateAdded,
    required String widgetID,

    // --- UI Fields (From your Flutter Code) ---
    // We exclude Icon/String from JSON because they aren't natively serializable
    // ignore: invalid_annotation_target
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default('white')
    String color,
    // @JsonKey(includeFromJson: false, includeToJson: false) @Default(Icon(Icons.rectangle)) Icon icon,

    // --- State Fields ---
    @Default(false) bool isStay,
    @Default(false) bool isTarget,
    @Default(0) int score,
  }) = _Item;

  // --- Custom Logic ---

  // Helper to mimic the behavior of passing fields to super in a standard class.
  // Since Freezed generates the fields, we override the getters to return the values from the generated mixin.
  @override
  String get url => (this as _Item).url;
  @override
  String get name => (this as _Item).name;
  @override
  String get imageUrl => (this as _Item).imageUrl;
  @override
  String get alias => (this as _Item).alias;
  @override
  String get dateAdded => (this as _Item).dateAdded;
  @override
  String get widgetID => (this as _Item).widgetID;

  bool get isEmpty => name == 'Empty';

  // Custom comparison logic for Grid
  bool isSame(InternalWidgetDragProtocol other) {
    return name == other.name &&
        // We access the generated 'String' field
        // (this as _Item).String == (other as _Item).String &&
        widgetID == other.widgetID;
  }

  // Empty Factory
  factory InternalWidgetDragProtocol.empty() {
    return InternalWidgetDragProtocol.item(
      url: '',
      name: 'Empty',
      imageUrl: '',
      alias: 'empty',
      dateAdded: '',
      widgetID: IDGen.UUIDV7(),
      color: 'white',
      isStay: false,
      isTarget: false, // Default for empty
    );
  }

  factory InternalWidgetDragProtocol.fromJson(Map<String, dynamic> json) =>
      _$InternalWidgetDragProtocolFromJson(json);
}
