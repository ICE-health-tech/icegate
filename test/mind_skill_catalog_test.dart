import 'package:flutter_test/flutter_test.dart';
import 'package:ice_gate/sensor_layer/ui_layer/social_page/mind_skill_catalog.dart';

void main() {
  group('MindSkillCatalog.normalizeName', () {
    test('trims and title-cases', () {
      expect(MindSkillCatalog.normalizeName('  writing  '), 'Writing');
    });

    test('maps to canonical default', () {
      expect(MindSkillCatalog.normalizeName('focus'), 'Focus');
      expect(MindSkillCatalog.normalizeName('meta mental'), 'Meta Mental');
    });

    test('rejects empty and too long', () {
      expect(MindSkillCatalog.normalizeName(''), isNull);
      expect(MindSkillCatalog.normalizeName('a' * 25), isNull);
    });

    test('dedupeNames is case-insensitive', () {
      expect(
        MindSkillCatalog.dedupeNames(['Focus', 'focus', 'Logic']),
        ['Focus', 'Logic'],
      );
    });
  });
}
