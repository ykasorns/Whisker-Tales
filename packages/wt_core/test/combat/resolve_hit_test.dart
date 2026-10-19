import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

void main() {
  final rules = loadRules();
  StatBlock s(
          {int atk = 100, int def = 30, Map<Attribute, int> a = const {}}) =>
      StatBlock(hp: 1000, atk: atk, def: def, attrs: a);
  ({HitOutcome outcome, int damage}) hit(StatBlock a, StatBlock d, int roll,
          {bool boss = false, DamageChannel ch = DamageChannel.normal}) =>
      resolveHit(
          rules: rules,
          attacker: a,
          defender: d,
          roll: roll,
          defenderIsBoss: boss,
          channel: ch);

  test('base = ATK − DEF', () {
    expect(hit(s(), s(), 9999), (outcome: HitOutcome.normal, damage: 70));
  });

  test('DEF floor: always at least 5% of ATK, never 0', () {
    expect(hit(s(atk: 100), s(def: 200), 9999).damage, 5);
    expect(hit(s(atk: 10), s(def: 50), 9999).damage, 1);
  });

  test('one roll splits dodge / crit / normal', () {
    final a = s(a: {Attribute.crit: 2000});
    final d = s(a: {Attribute.evade: 1000});
    expect(hit(a, d, 0).outcome, HitOutcome.dodge);
    expect(hit(a, d, 999), (outcome: HitOutcome.dodge, damage: 0));
    expect(hit(a, d, 1000), (outcome: HitOutcome.crit, damage: 105));
    expect(hit(a, d, 2999).outcome, HitOutcome.crit);
    expect(hit(a, d, 3000), (outcome: HitOutcome.normal, damage: 70));
  });

  test('crit multiplier = max(1.5, base + crit dmg − crit dmg res)', () {
    final a = s(a: {Attribute.crit: 6000, Attribute.critDmg: 5000});
    expect(hit(a, s(), 0).damage, 140);
    expect(hit(a, s(a: {Attribute.critDmgRes: 2000}), 0).damage, 126);
    expect(hit(a, s(a: {Attribute.critDmgRes: 9000}), 0).damage, 105);
  });

  test('chances are stat − anti, capped by data', () {
    // crit cap 60%
    final a = s(a: {Attribute.crit: 9000});
    expect(hit(a, s(), 5999).outcome, HitOutcome.crit);
    expect(hit(a, s(), 6000).outcome, HitOutcome.normal);
    // crit res
    expect(
        hit(a, s(a: {Attribute.critRes: 8000}), 999).outcome, HitOutcome.crit);
    expect(hit(a, s(a: {Attribute.critRes: 8000}), 1000).outcome,
        HitOutcome.normal);
    // evade cap 40%, accuracy cancels evade
    final d = s(a: {Attribute.evade: 9000});
    expect(hit(s(), d, 3999).outcome, HitOutcome.dodge);
    expect(hit(s(), d, 4000).outcome, HitOutcome.normal);
    final sharp = s(a: {Attribute.accuracy: 1000});
    final quick = s(a: {Attribute.evade: 3000});
    expect(hit(sharp, quick, 1999).outcome, HitOutcome.dodge);
    expect(hit(sharp, quick, 2000).outcome, HitOutcome.normal);
  });

  test('boss damage applies only against bosses', () {
    final a = s(a: {Attribute.bossDmg: 5000});
    expect(hit(a, s(), 9999, boss: true).damage, 105);
    expect(hit(a, s(), 9999).damage, 70);
  });

  test('pet damage applies only on the partner channel', () {
    final a = s(a: {Attribute.petDmg: 5000});
    expect(hit(a, s(), 9999, ch: DamageChannel.partner).damage, 105);
    expect(hit(a, s(), 9999).damage, 70);
  });
}
