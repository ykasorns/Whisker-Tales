import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

Map<String, dynamic> _json(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final rules = loadRules();
  final buffsJson = _json('../../design/data/buffs.json');
  final buffs = BuffBook.fromJson(buffsJson);
  final skills =
      SkillBook.fromJson(_json('../../design/data/skills.json'), buffs);

  BuffBook withFixture(List<Map<String, dynamic>> extra) => BuffBook.fromJson({
        'buffs': [...(buffsJson['buffs'] as List), ...extra],
      });

  CombatEngine engine([BuffBook? b]) =>
      CombatEngine(rules, buffs: b ?? buffs, firstCastPct: skills.firstCastPct);

  CombatUnitSpec caster(List<SkillSpec> sk,
          {int atk = 100,
          Map<Attribute, int> attrs = const {},
          int hp = 100000}) =>
      CombatUnitSpec(
          id: 'mochi',
          side: CombatSide.cat,
          stats: StatBlock(hp: hp, atk: atk, def: 0, attrs: attrs),
          attackIntervalMs: 100000, // skills only
          skills: sk);

  List<CombatEvent> run(CombatEngine e, CombatSetup s,
      {int ms = 20000, int step = 20000}) {
    final out = <CombatEvent>[];
    e.events.listen(out.add);
    e.start(s);
    for (var t = 0; t < ms && !e.isOver; t += step) {
      e.tick(step);
    }
    return out;
  }

  SkillSpec skill(String id) =>
      skills.byClass.values.expand((l) => l).firstWhere((s) => s.id == id);

  group('data', () {
    test('12 skills, 3 per class, by slot; buffs load as basis points', () {
      for (final c in ['warrior', 'rogue', 'archer', 'mage']) {
        expect(skills.byClass[c], hasLength(3), reason: c);
      }
      expect(skills.skillsFor('mage', 2).map((s) => s.id),
          ['fireball', 'frost_nova']);
      expect(skills.skillsFor('novice', 3), isEmpty);
      expect(buffs['shadow_evade'].valueBp, 2000);
      expect(buffs['eagle_crit_dmg'].valueBp, 5000);
      expect(buffs['iron_wall'].pctBp, 2500);
    });

    test('bad data names the buff', () {
      for (final bad in [
        {'id': 'x', 'action': 'teleport'},
        {
          'id': 'x',
          'action': 'dot',
          'params': {'pct_atk': 5},
          'duration_ms': 1000
        },
        {
          'id': 'x',
          'action': 'add_buff',
          'params': {'buff': 'nope'}
        },
        {
          'id': 'x',
          'action': 'attrib',
          'params': {'attr': 'luck', 'mode': 'add', 'value': 1}
        },
      ]) {
        expect(
            () => withFixture([bad]),
            throwsA(isA<FormatException>()
                .having((e) => e.message, 'message', contains('x'))));
      }
    });
  });

  group('casting', () {
    test('casts on cooldown: first at 50%, cdr shortens it', () {
      final ev = run(
          engine(),
          CombatSetup(seed: 1, units: [
            caster([skill('fireball')], attrs: {Attribute.cdr: 2500}),
            mon('dummy', hp: 1 << 30, atk: 0, intervalMs: 1 << 30),
          ]),
          ms: 10000,
          step: 10000);
      expect(ev.whereType<SkillCast>().map((e) => e.atMs),
          [1125, 3375, 5625, 7875]);
    });

    test('the fight view: skill timers, HP and shields, read-only (D-038)', () {
      final e = engine();
      final setup = CombatSetup(seed: 1, units: [
        caster([skill('fireball')], attrs: {Attribute.cdr: 2500}),
        mon('dummy', hp: 5000, atk: 0, intervalMs: 1 << 30),
      ]);
      final out = <CombatEvent>[];
      e.events.listen(out.add);
      e.start(setup);
      var v = e.view.firstWhere((u) => u.id == 'mochi');
      // cooldown 3 s with 25 % CDR = 2.25 s; the first cast comes at 50 % of it
      expect(v.skills.single.totalMs, 2250);
      expect(v.skills.single.remainingMs, 1125);
      e.tick(1000);
      v = e.view.firstWhere((u) => u.id == 'mochi');
      expect(v.skills.single.remainingMs, 125);
      e.tick(125); // cast: timer starts over
      v = e.view.firstWhere((u) => u.id == 'mochi');
      expect(v.skills.single.remainingMs, 2250);
      final dummy = e.view.firstWhere((u) => u.id == 'dummy');
      expect(dummy.maxHp, 5000);
      expect(dummy.hp, lessThan(5000)); // the fireball landed
      expect(dummy.alive, isTrue);
      expect(dummy.side, CombatSide.enemy);
      // reading the view never changes the fight
      final plain = <CombatEvent>[];
      final e2 = engine();
      e2.events.listen(plain.add);
      e2.start(setup);
      e2.tick(1125);
      expect(out, plain);
    });

    test('skills cannot be dodged; skill damage and crits scale', () {
      final ev = run(
          engine(),
          CombatSetup(seed: 2, units: [
            caster([skill('power_shot')], attrs: {Attribute.skillDmg: 8000}),
            mon('slippery',
                hp: 1 << 30,
                def: 0,
                attrs: {Attribute.evade: 9000},
                intervalMs: 1 << 30),
          ]),
          ms: 60000,
          step: 60000);
      final hits = ev
          .whereType<HitResolved>()
          .where((h) => h.source == AttackSource.skill);
      expect(hits, isNotEmpty);
      expect(hits.any((h) => h.outcome == HitOutcome.dodge), isFalse);
      // 100 ATK × 220% × (1 + 80%) = 396
      expect(
          hits.where((h) => h.outcome == HitOutcome.normal).first.damage, 396);
    });

    test('area skills hit every enemy', () {
      final ev = run(
          engine(),
          CombatSetup(seed: 3, units: [
            caster([skill('arrow_rain')]),
            for (var i = 0; i < 4; i++)
              mon('m$i', hp: 1 << 30, intervalMs: 1 << 30),
          ]),
          ms: 5000,
          step: 5000);
      final first = ev
          .whereType<HitResolved>()
          .where((h) => h.source == AttackSource.skill);
      expect(first.map((h) => h.targetId).toSet(), {'m0', 'm1', 'm2', 'm3'});
    });

    test('a stunned caster waits; useSkill on cooldown does nothing', () {
      final e = engine(withFixture([
        {
          'id': 'long_stun',
          'action': 'stun',
          'params': {},
          'duration_ms': 3000
        },
      ]));
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(seed: 4, units: [
        caster([skill('fireball')]),
        mon('dummy', hp: 1 << 30, intervalMs: 1 << 30),
      ]));
      e.useSkill(0); // not ready at 0 ms
      expect(ev.whereType<SkillCast>(), isEmpty);
      e.apply('mochi', 'long_stun', sourceId: 'dummy');
      e.tick(3100);
      // first cast was due at 1500 (cd 3000 × 50%); the stun held it to 3000
      expect(ev.whereType<SkillCast>().single.atMs, 3000);
      e.useSkill(0);
      expect(ev.whereType<SkillCast>(), hasLength(1));
    });
  });

  group('buffs', () {
    test('shield absorbs first, then breaks; absorbed damage is not dealt', () {
      final e = engine();
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(seed: 5, units: [
        cat(hp: 1000, atk: 1, intervalMs: 1 << 30),
        mon('hitter', atk: 105, intervalMs: 1000),
      ]));
      e.apply('mochi', 'iron_wall', sourceId: 'mochi'); // 250 shield
      e.tick(3000);
      final absorbed = ev.whereType<ShieldAbsorbed>().toList();
      expect(absorbed.fold<int>(0, (a, s) => a + s.amount), 250);
      expect(absorbed.last.left, 0);
      expect(ev.whereType<BuffEnded>().single.buffId, 'iron_wall');
      expect(e.hpOf('mochi'), 1000 - (300 - 250));
    });

    test('poison stacks to 3 and ticks as skill damage', () {
      final e = engine();
      e.start(CombatSetup(seed: 6, units: [
        caster(const [], atk: 100),
        mon('target', hp: 1 << 30, intervalMs: 1 << 30),
      ]));
      for (var i = 0; i < 5; i++) {
        e.apply('target', 'poison', sourceId: 'mochi');
      }
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.tick(1000);
      final dot = ev.whereType<HitResolved>().single;
      expect((dot.source, dot.damage), (AttackSource.dot, 20 * 3));
      expect(e.damageDealt(DamageChannel.skill), 60);
    });

    test('attrib buffs change stats, then wear off', () {
      final e = engine()
        ..start(CombatSetup(seed: 7, units: [
          cat(atk: 100, def: 10),
          mon('m', hp: 1 << 30, intervalMs: 1 << 30),
        ]));
      e.apply('mochi', 'war_cry_atk', sourceId: 'mochi');
      e.apply('mochi', 'war_cry_def', sourceId: 'mochi');
      expect((e.statsOf('mochi').atk, e.statsOf('mochi').def), (130, 13));
      e.tick(6000);
      expect((e.statsOf('mochi').atk, e.statsOf('mochi').def), (100, 10));
    });

    test('a buff defined only in data works (no code change)', () {
      final b = withFixture([
        {
          'id': 'second_wind',
          'action': 'heal',
          'params': {'pct_max_hp': 50}
        },
        {
          'id': 'vampire',
          'action': 'attrib',
          'params': {'attr': 'atk', 'mode': 'pct', 'value': 0},
          'duration_ms': -1,
          'on_event': [
            {'event': 'kill', 'add_buff': 'second_wind'}
          ]
        },
      ]);
      final e = engine(b);
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(seed: 8, units: [
        cat(hp: 1000, atk: 1000, intervalMs: 500),
        mon('a', hp: 10, atk: 1, intervalMs: 1 << 30),
        mon('b', hp: 1 << 20, atk: 1, intervalMs: 1 << 30),
      ]));
      e.apply('mochi', 'vampire', sourceId: 'mochi');
      e.apply('mochi', 'iron_wall', sourceId: 'mochi');
      e.tick(600);
      expect(ev.whereType<UnitDefeated>().map((d) => d.unitId), ['a']);
      expect(ev.whereType<UnitHealed>(), isEmpty); // full HP: nothing to heal
    });

    test('on_event chains go ≥3 deep; loops stop at the depth cap', () {
      final b = withFixture([
        {
          'id': 'c3',
          'action': 'attrib',
          'params': {'attr': 'crit', 'mode': 'add', 'value': 1},
          'duration_ms': -1,
          'group': 'c3',
          'stack_max': 99
        },
        {
          'id': 'c2',
          'action': 'add_buff',
          'params': {'buff': 'c3'}
        },
        {
          'id': 'c1',
          'action': 'add_buff',
          'params': {'buff': 'c2'}
        },
        {
          'id': 'root',
          'action': 'attrib',
          'params': {'attr': 'atk', 'mode': 'pct', 'value': 0},
          'duration_ms': -1,
          'on_event': [
            {'event': 'skill_cast', 'add_buff': 'c1'}
          ]
        },
        {
          'id': 'loop_a',
          'action': 'add_buff',
          'params': {'buff': 'loop_b'}
        },
        {
          'id': 'loop_b',
          'action': 'add_buff',
          'params': {'buff': 'loop_a'}
        },
      ]);
      final e = engine(b);
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(seed: 9, units: [
        caster([skill('fireball')]),
        mon('m', hp: 1 << 30, intervalMs: 1 << 30),
      ]));
      e.apply('mochi', 'root', sourceId: 'mochi');
      e.tick(2000); // one cast → root → c1 → c2 → c3
      expect(ev.whereType<BuffApplied>().where((x) => x.buffId == 'c3'),
          hasLength(1));
      e.apply('mochi', 'loop_a', sourceId: 'mochi'); // must return, not hang
      expect(e.isOver, isFalse);
    });

    test('relic synergy via on_event: static fur + echo bell (fixtures)', () {
      final b = withFixture([
        // ขนแมวไฟฟ้า: crits shock the target
        {
          'id': 'spark',
          'action': 'dot',
          'params': {'pct_atk': 10},
          'duration_ms': 2000,
          'tick_ms': 500,
          'group': 'spark',
          'stack_max': 5
        },
        {
          'id': 'static_fur',
          'action': 'attrib',
          'params': {'attr': 'crit', 'mode': 'add', 'value': 30},
          'duration_ms': -1,
          'on_event': [
            {'event': 'crit', 'add_buff': 'spark', 'target': 'other'}
          ]
        },
        // กระดิ่งสะท้อน: each cast brings the next one closer
        {
          'id': 'echo',
          'action': 'cooldown_mod',
          'params': {'ms': 1000}
        },
        {
          'id': 'echo_bell',
          'action': 'attrib',
          'params': {'attr': 'atk', 'mode': 'pct', 'value': 0},
          'duration_ms': -1,
          'on_event': [
            {'event': 'skill_cast', 'add_buff': 'echo'}
          ]
        },
      ]);
      int casts(bool relics) {
        final e = engine(b);
        final ev = <CombatEvent>[];
        e.events.listen(ev.add);
        e.start(CombatSetup(seed: 10, units: [
          caster([skill('fireball')]),
          mon('m', hp: 1 << 30, intervalMs: 1 << 30),
        ]));
        if (relics) {
          e.apply('mochi', 'static_fur', sourceId: 'mochi');
          e.apply('mochi', 'echo_bell', sourceId: 'mochi');
        }
        e.tick(30000);
        if (relics) {
          expect(
              ev
                  .whereType<BuffApplied>()
                  .any((x) => x.buffId == 'spark' && x.unitId == 'm'),
              isTrue);
        }
        return ev.whereType<SkillCast>().length;
      }

      expect(casts(true), greaterThan(casts(false)));
    });
  });

  test('with skills, any split of tick() still gives the same events', () {
    for (final cls in ['warrior', 'rogue', 'archer', 'mage']) {
      CombatSetup setup(int seed) => CombatSetup(seed: seed, units: [
            CombatUnitSpec(
                id: 'mochi',
                side: CombatSide.cat,
                stats: StatBlock(
                    hp: 600, atk: 40, def: 5, attrs: {Attribute.crit: 2000}),
                attackIntervalMs: 900,
                skills: skills.skillsFor(cls, 3)),
            for (var i = 0; i < 4; i++) mon('m$i', hp: 300, atk: 15),
          ]);
      for (var seed = 0; seed < 40; seed++) {
        List<CombatEvent> rec(int step) {
          final e = engine();
          final out = <CombatEvent>[];
          e.events.listen(out.add);
          e.start(setup(seed));
          for (var t = 0; t < 120000 && !e.isOver; t += step) {
            e.tick(step);
          }
          return out;
        }

        final a = rec(16);
        expect(rec(37), a, reason: '$cls $seed');
        expect(rec(120000), a, reason: '$cls $seed');
      }
    }
  });

  group('review fixes (2026-10-21)', () {
    List<CombatEvent> runWith(
        CombatEngine e, CombatSetup s, void Function(CombatEngine) after,
        {int ms = 20000}) {
      final out = <CombatEvent>[];
      e.events.listen(out.add);
      e.start(s);
      after(e);
      e.tick(ms);
      return out;
    }

    test('a stunned unit never attacks — not even a counter', () {
      for (var seed = 0; seed < 30; seed++) {
        final ev = record(
            rules,
            CombatSetup(seed: seed, units: [
              cat(atk: 20, attrs: {Attribute.stun: 2500}),
              mon('m', hp: 4000, attrs: {Attribute.counter: 4000}),
            ]),
            stepMs: 20000);
        final stunnedUntil = <String, int>{};
        for (final e in ev) {
          if (e is UnitStunned) stunnedUntil[e.unitId] = e.untilMs;
          if (e is HitResolved) {
            expect(
                e.atMs, greaterThanOrEqualTo(stunnedUntil[e.attackerId] ?? 0),
                reason: 'seed $seed: ${e.attackerId} hit while stunned');
          }
        }
        expect(ev.whereType<UnitStunned>(), isNotEmpty);
      }
    });

    test('one unit dying to a dot does not delay the other units\' ticks', () {
      final tick = buffs['poison'].tickMs;
      final ev = runWith(
          engine(),
          CombatSetup(seed: 1, units: [
            caster(const [], atk: 100),
            mon('m0', hp: 1, intervalMs: 100000),
            mon('m1', hp: 100000, intervalMs: tick),
          ]), (e) {
        e.apply('m0', 'poison', sourceId: 'mochi');
        e.apply('m1', 'poison', sourceId: 'mochi');
      }, ms: tick);
      final dot = ev.indexWhere((e) =>
          e is HitResolved &&
          e.targetId == 'm1' &&
          e.source == AttackSource.dot);
      final attack = ev.indexWhere((e) =>
          e is HitResolved &&
          e.attackerId == 'm1' &&
          e.source == AttackSource.normal);
      expect(ev.whereType<UnitDefeated>().single.unitId, 'm0');
      expect(dot, greaterThanOrEqualTo(0));
      expect(attack, greaterThan(dot)); // buff ticks, then units act
    });

    test('regen and CDR from a buff given mid-fight take effect', () {
      final book = withFixture([
        {
          'id': 'test_regen',
          'action': 'attrib',
          'params': {'attr': 'regen', 'mode': 'add', 'value': 2},
          'duration_ms': -1,
        },
        {
          'id': 'test_cdr',
          'action': 'attrib',
          'params': {'attr': 'cdr', 'mode': 'add', 'value': 50},
          'duration_ms': -1,
        },
      ]);
      const sk =
          SkillSpec(id: 'tick', cooldownMs: 10000, target: SkillTarget.self);
      final ev = runWith(
          engine(book),
          CombatSetup(seed: 3, units: [
            caster(const [sk], hp: 5000),
            mon('m', hp: 1 << 30, atk: 40, intervalMs: 300),
          ]), (e) {
        e.apply('mochi', 'test_regen', sourceId: 'mochi');
        e.apply('mochi', 'test_cdr', sourceId: 'mochi');
      }, ms: 30000);
      expect(
          ev
              .whereType<UnitHealed>()
              .where((h) => h.unitId == 'mochi' && h.cause == HealCause.regen),
          isNotEmpty);
      final casts = [for (final c in ev.whereType<SkillCast>()) c.atMs];
      expect(casts.length, greaterThanOrEqualTo(3));
      expect(casts[2] - casts[1], 5000); // cooldown × (1 − 50% CDR)
    });
  });
}
