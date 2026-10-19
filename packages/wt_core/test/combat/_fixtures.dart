import 'dart:convert';
import 'dart:io';

import 'package:wt_core/wt_core.dart';

/// Rules from the real balance file (the data loader is T-003).
CombatRules loadRules() => CombatRules.fromBalance(jsonDecode(
        File('../../design/balance/idle_balance_v1.json').readAsStringSync())
    as Map<String, dynamic>);

CombatUnitSpec cat({
  String id = 'mochi',
  int hp = 300,
  int atk = 30,
  int def = 5,
  int intervalMs = 900,
  Map<Attribute, int> attrs = const {},
}) =>
    CombatUnitSpec(
        id: id,
        side: CombatSide.cat,
        stats: StatBlock(hp: hp, atk: atk, def: def, attrs: attrs),
        attackIntervalMs: intervalMs);

CombatUnitSpec mon(
  String id, {
  int hp = 60,
  int atk = 12,
  int def = 2,
  int intervalMs = 1200,
  bool boss = false,
  Map<Attribute, int> attrs = const {},
}) =>
    CombatUnitSpec(
        id: id,
        side: CombatSide.enemy,
        stats: StatBlock(hp: hp, atk: atk, def: def, attrs: attrs),
        attackIntervalMs: intervalMs,
        isBoss: boss);

/// One wave: a cat with every proc stat, a pet, and five monsters.
CombatSetup wave(int seed, {int monsters = 5}) =>
    CombatSetup(seed: seed, units: [
      cat(attrs: {
        Attribute.crit: 2000,
        Attribute.critDmg: 3000,
        Attribute.combo: 1500,
        Attribute.counter: 1000,
        Attribute.stun: 800,
        Attribute.evade: 1200,
        Attribute.lifesteal: 500,
        Attribute.regen: 100,
      }),
      pet(),
      for (var i = 0; i < monsters; i++)
        mon('slime$i', attrs: {Attribute.crit: 1000, Attribute.evade: 500}),
    ]);

/// Runs [setup] in steps of [stepMs] and returns every event.
List<CombatEvent> record(CombatRules rules, CombatSetup setup,
    {required int stepMs, int maxMs = 120000}) {
  final engine = CombatEngine(rules);
  final out = <CombatEvent>[];
  engine.events.listen(out.add);
  engine.start(setup);
  for (var t = 0; t < maxMs && !engine.isOver; t += stepMs) {
    engine.tick(stepMs);
  }
  return out;
}

CombatUnitSpec pet({int atk = 8, int petDmg = 5000}) => CombatUnitSpec(
    id: 'sparrow',
    side: CombatSide.cat,
    stats:
        StatBlock(hp: 1, atk: atk, def: 0, attrs: {Attribute.petDmg: petDmg}),
    attackIntervalMs: 1500,
    isPartner: true);
