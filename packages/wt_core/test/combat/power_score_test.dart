import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

void main() {
  final power = PowerScore(loadRules().powerWeights);

  test('ATK×5 + HP×0.5 + DEF×3', () {
    expect(power.of(StatBlock(hp: 200, atk: 20, def: 10)), 100 + 100 + 30);
  });

  test('secondary stats scale main power by stat% × weight (D-011)', () {
    final s = StatBlock(hp: 200, atk: 20, def: 10, attrs: {
      Attribute.crit: 1000, // 10% × 1.2 = +12%
      Attribute.evade: 500, // 5% × 0.9 = +4.5%
      Attribute.yarnFind: 3000, // no weight → no power
    });
    expect(power.of(s), 230 * 11650 ~/ 10000);
  });

  test('an affix never outweighs real main stats', () {
    final affix =
        StatBlock(hp: 40, atk: 6, def: 3, attrs: {Attribute.critDmg: 3000});
    final stronger = StatBlock(hp: 40, atk: 12, def: 3);
    expect(power.of(stronger), greaterThan(power.of(affix)));
  });

  test('more of any weighted stat never lowers power', () {
    final base = StatBlock(hp: 100, atk: 10, def: 5);
    for (final a in [Attribute.crit, Attribute.combo, Attribute.lifesteal]) {
      expect(power.of(base.copyWith(attrs: {a: 1000})),
          greaterThan(power.of(base)));
    }
  });
}
