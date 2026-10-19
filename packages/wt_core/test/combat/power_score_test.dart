import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

void main() {
  final power = PowerScore(loadRules().powerWeights);

  test('ATK×5 + HP×0.5 + DEF×3', () {
    expect(power.of(StatBlock(hp: 200, atk: 20, def: 10)), 100 + 100 + 30);
  });

  test('secondary stats add stat% × 100 × weight', () {
    final s = StatBlock(hp: 0, atk: 0, def: 0, attrs: {
      Attribute.crit: 1000, // 10% × 100 × 1.2
      Attribute.evade: 500, // 5% × 100 × 0.9
      Attribute.yarnFind: 3000, // no weight → no power
    });
    expect(power.of(s), 1200 + 450);
  });

  test('more of any weighted stat never lowers power', () {
    final base = StatBlock(hp: 100, atk: 10, def: 5);
    for (final a in [Attribute.crit, Attribute.combo, Attribute.lifesteal]) {
      expect(power.of(base.copyWith(attrs: {a: 100})),
          greaterThan(power.of(base)));
    }
  });
}
