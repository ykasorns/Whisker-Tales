import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

void main() {
  test('loads the combat section of the balance file', () {
    final r = loadRules();
    expect(r.defFloorBp, 500);
    expect(r.critMultMinBp, 15000);
    expect(r.baseCritDmgBp, 15000);
    expect(r.cap(Attribute.crit), 6000);
    expect(r.cap(Attribute.evade), 4000);
    expect(r.cap(Attribute.stun), 2500);
    expect(r.cap(Attribute.lifesteal), 3000); // ASSUMPTION_ key
    expect(r.cap(Attribute.accuracy), kBp); // no cap in data
    expect(r.powerWeights.hpPm, 500);
    expect(r.powerWeights.attrPm[Attribute.crit], 1200);
  });

  test('proc = clamp(stat − anti, 0, cap)', () {
    final r = loadRules();
    expect(r.proc(Attribute.crit, 9000, 1000), 6000);
    expect(r.proc(Attribute.crit, 1000, 3000), 0);
    expect(r.proc(Attribute.crit, 3000, 1000), 2000);
  });

  Map<String, dynamic> section() => {
        'def_floor_pct': 5,
        'crit_mult_min_pct': 150,
        'base_crit_dmg_pct': 150,
        'caps_pct': {'crit': 60},
        'stun_ms': 1000,
        'regen_tick_ms': 1000,
        'power_weights': {'atk': 5, 'hp': 0.5, 'def': 3},
      };

  test('plain and ASSUMPTION_ keys load the same', () {
    final s = section()
      ..remove('stun_ms')
      ..['ASSUMPTION_stun_ms'] = 700;
    expect(CombatRules.fromJson(s).stunMs, 700);
    expect(CombatRules.fromJson(section()).stunMs, 1000);
  });

  test('bad data fails with the field name', () {
    expect(
        () => CombatRules.fromJson(section()..remove('def_floor_pct')),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('def_floor_pct'))));
    expect(
        () => CombatRules.fromJson(section()..['caps_pct'] = {'luck': 5}),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('luck'))));
    expect(() => CombatRules.fromJson(section()..['regen_tick_ms'] = 0),
        throwsFormatException);
  });
}
