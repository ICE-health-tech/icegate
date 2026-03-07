import 'package:flutter_test/flutter_test.dart';
// Replace with your actual path
import 'package:ice_gate/data_layer/Protocol/Canvas/InternalWidgetDragProtocol.dart';

void main() {
  group('InternalWidgetDragProtocol', () {
    // 1. Test Initialization and Defaults (The .empty() factory)
    test('empty factory initializes with correct defaults', () {
      var instance = InternalWidgetDragProtocol.empty();

      // Checks based on the .empty() factory logic
      expect(instance.name, 'Empty');
      expect(instance.alias, 'empty');
      expect(instance.color, "white");

      // WidgetID is generated randomly, so we check type and length
      expect(instance.widgetID, isA<int>());
      // expect(instance.widgetID, greaterThan(0));

      // Verify @Default(0) and @Default(false)
      expect(instance.score, 0);
      expect(instance.isTarget, isFalse);
    });

    // 2. Test Value Equality
    test('supports value equality', () {
      // Define all required fields
      var instanceA = InternalWidgetDragProtocol.item(
        widgetID: '1',
        alias: 'a',
        score: 10,
        name: 'Test A',
        url: 'url',
        imageUrl: 'img',
        dateAdded: '2024',
        color: "red",
      );

      var instanceB = InternalWidgetDragProtocol.item(
        widgetID: '11',
        alias: 'a',
        score: 10,
        name: 'Test A',
        url: 'url',
        imageUrl: 'img',
        dateAdded: '2024',
        color: "black",
      );

      var instanceC = InternalWidgetDragProtocol.item(
        widgetID: '222',
        alias: 'b',
        name: 'Test B',
        url: 'url',
        imageUrl: 'img',
        dateAdded: '2024',
        color: "blue",
      );

      // Freezed overrides == and hashCode automatically
      expect(instanceA, isNot(instanceB));
      expect(instanceA, isNot(equals(instanceC)));
    });

    // 3. Test copyWith (Immutability)
    test('copyWith creates a new instance with updated values', () {
      var instance = InternalWidgetDragProtocol.item(
        widgetID: '111',
        alias: 'original',
        name: 'Name',
        url: 'url',
        imageUrl: 'img',
        dateAdded: 'date',
        color: "black",
      );

      final updated = instance.copyWith(alias: 'updated', score: 50);

      // Check new instance values
      expect(updated.alias, 'updated');
      expect(updated.score, 50);
      expect(updated.widgetID, 111); // Should remain unchanged
      expect(updated.name, 'Name'); // Should remain unchanged

      // Check original instance remains untouched (Immutability)
      expect(instance.alias, 'original');
      expect(instance.score, 0);
    });

    // 4. Test JSON Serialization
    group('JSON Serialization', () {
      final validJson = {
        'widgetID': 500, // int
        'alias': 'json_test',
        'score': 99,
        'isTarget': true,
        'name': 'Json Item',
        'url': 'http://test.com',
        'imageUrl': 'img.png',
        'dateAdded': '2025-01-01',
        // Note: Color and Icon are excluded from JSON in the model
      };

      test('fromJson creates a valid instance', () {
        // NOTE: For this to pass, your Model constructor must have @Default values
        // for `color` and `icon` because they are not in the JSON map.
        final instance = InternalWidgetDragProtocol.fromJson(validJson);

        expect(instance.widgetID, 500);
        expect(instance.alias, 'json_test');
        expect(instance.score, 99);
        expect(instance.isTarget, isTrue);
        expect(instance.name, 'Json Item');
      });

      test('toJson creates a valid map', () {
        var instance = InternalWidgetDragProtocol.item(
          widgetID: '5555',
          alias: 'json_test',
          score: 99,
          isTarget: true,
          name: 'Json Item',
          url: 'http://test.com',
          imageUrl: 'img.png',
          dateAdded: '2025-01-01',
          color: "white",
        );

        final json = instance.toJson();

        // Verify fields match
        expect(json['widgetID'], 5555);
        expect(json['alias'], 'json_test');
        // Verify excluded fields are NOT in JSON
        expect(json.containsKey('color'), isFalse);
        expect(json.containsKey('icon'), isFalse);
      });
    });
  });
}
