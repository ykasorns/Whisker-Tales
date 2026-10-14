import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  // The example manifest from MODE_PLUGIN_SPEC §4.
  final specExample = <String, dynamic>{
    'id': 'endless',
    'name_th': 'ตะลุยไร้จุดจบ',
    'name_en': 'Endless Tale',
    'icon': 'mode_endless',
    'order': 2,
    'enabled': true,
    'min_app_version': '1.2.0',
    'unlock': {'type': 'flag', 'flag': 'story_boss1_cleared'},
  };

  test('parses the spec example manifest', () {
    final m = ModeManifest.fromJson(specExample);
    expect(m.id, 'endless');
    expect(m.nameTh, 'ตะลุยไร้จุดจบ');
    expect(m.order, 2);
    expect(m.enabled, isTrue);
    expect(m.minAppVersion, '1.2.0');
    expect(m.unlock!.type, UnlockType.flag);
    expect(m.unlock!.value, 'story_boss1_cleared');
  });

  test('unlock is optional', () {
    final m = ModeManifest.fromJson({...specExample}..remove('unlock'));
    expect(m.unlock, isNull);
  });

  test('every unlock type in the vocabulary parses', () {
    expect(
        UnlockRule.fromJson({'type': 'fish_total', 'amount': 500}).value, 500);
    expect(
        UnlockRule.fromJson({'type': 'boss_cleared', 'boss': 'paper_wolf'})
            .value,
        'paper_wolf');
  });

  test('rejects unknown unlock types and missing values', () {
    expect(() => UnlockRule.fromJson({'type': 'paid'}), throwsFormatException);
    expect(() => UnlockRule.fromJson({'type': 'flag'}), throwsFormatException);
  });

  test('rejects missing or mistyped fields', () {
    expect(() => ModeManifest.fromJson({...specExample}..remove('id')),
        throwsFormatException);
    expect(() => ModeManifest.fromJson({...specExample, 'order': '2'}),
        throwsFormatException);
  });
}
