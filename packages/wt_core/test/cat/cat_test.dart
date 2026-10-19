import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> balance() => jsonDecode(
        File('../../design/balance/idle_balance_v1.json').readAsStringSync())
    as Map<String, dynamic>;

void main() {
  final rules = CatRules.fromBalance(balance());
  final combat = CombatRules.fromBalance(balance());
  Map<String, dynamic> data(String f) =>
      jsonDecode(File('../../design/data/$f').readAsStringSync())
          as Map<String, dynamic>;
  final buffs = BuffBook.fromJson(data('buffs.json'));
  final skills = SkillBook.fromJson(data('skills.json'), buffs);

  CatClass catAt(int level, [String cls = 'novice']) {
    final c = CatClass(rules, CatProgress(rules), skillsFor: skills.skillsFor);
    c.restore(
        CatState(level: level, classId: cls, tier: rules.classById(cls)!.tier));
    return c;
  }

  group('data', () {
    test('classes load as fixed point', () {
      expect(rules.classes.map((c) => c.id),
          ['novice', 'warrior', 'rogue', 'archer', 'mage']);
      expect(rules.novice.id, 'novice');
      final rogue = rules.classById('rogue')!;
      expect(rogue.tier, 1);
      expect(rogue.attackIntervalMs, 600);
      expect(rogue.bonus[Attribute.evade], 1500);
      final mage = rules.classById('mage')!;
      expect(mage.bonus[Attribute.skillDmg], 8000);
      expect(mage.bonus[Attribute.cdr], 2500);
      expect(mage.range, AttackRange.ranged);
      expect(rules.classById('warrior')!.hpBp, 14000);
    });

    test('EXP curve and per-kill EXP come from data', () {
      expect(rules.expToNext(1), 20);
      expect(rules.expToNext(2), 22);
      expect(rules.expToNext(3), 24); // 20 × 1.10²
      expect(rules.expPerKill(1), 2);
      expect(rules.expPerKill(30), 11);
    });

    test('Lv1 novice power matches player.base_power', () {
      final power = PowerScore(combat.powerWeights);
      final p = power.of(catAt(1).combatSpec().stats);
      final base = (balance()['player'] as Map)['base_power'] as int;
      expect(p, closeTo(base, base * 0.1));
    });

    test('bad class data fails with the field', () {
      final b = balance();
      (b['classes'] as Map)['rogue']['range'] = 'far';
      expect(
          () => CatRules.fromBalance(b),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', contains('rogue'))));
      final c = balance();
      (c['classes'] as Map)['ninja'] = {
        ...(c['classes'] as Map)['rogue'] as Map<String, dynamic>,
        'tier': 2,
      };
      expect(() => CatRules.fromBalance(c), throwsFormatException);
    });
  });

  group('level', () {
    test('gainExp levels up and reports once per call', () {
      final p = CatProgress(rules);
      final ups = <CatLevelUp>[];
      p.levelUps.listen(ups.add);
      expect(p.gainExp(19), 0);
      expect(p.gainExp(1), 1);
      expect((p.level, p.exp), (2, 0));
      expect(p.gainExp(22 + 24 + 5), 2); // offline jump
      expect((p.level, p.exp), (4, 5));
      expect(ups, [
        const CatLevelUp(from: 1, to: 2),
        const CatLevelUp(from: 2, to: 4),
      ]);
    });

    test('no level cap; levels keep coming, just slower', () {
      final p = CatProgress(rules)..gainExp(1 << 40);
      expect(p.level, greaterThan(80));
      expect(p.exp, lessThan(p.expToNext));
      final before = p.level;
      p.gainExp(p.expToNext);
      expect(p.level, before + 1);
    });

    test('mid levels (20–39) get harder faster than early or late ones', () {
      double step(int l) => rules.expToNext(l + 1) / rules.expToNext(l);
      expect(step(10), closeTo(1.10, 0.01));
      expect(step(30), closeTo(1.15, 0.01));
      expect(step(60), closeTo(1.08, 0.01));
      expect(rules.expToNext(21), greaterThan(rules.expToNext(20)));
    });

    test('huge levels stay finite ints', () {
      expect(rules.expToNext(100000), 9007199254740992);
    });

    test('negative EXP is rejected', () {
      expect(() => CatProgress(rules).gainExp(-1), throwsArgumentError);
    });
  });

  group('class', () {
    test('no class before Lv10', () {
      final c = catAt(9);
      expect(c.available, isEmpty);
      expect(() => c.choose('rogue'), throwsStateError);
    });

    test('pick one of four at Lv10, then switch freely within the tier', () {
      final c = catAt(10);
      expect(
          c.available.map((m) => m.id), ['warrior', 'rogue', 'archer', 'mage']);
      c.choose('rogue');
      expect(c.current, 'rogue');
      expect(c.available.map((m) => m.id), ['warrior', 'archer', 'mage']);
      c.choose('mage');
      expect(c.modifiers.id, 'mage');
      expect(() => c.choose('novice'), throwsStateError);
      expect(() => c.choose('ninja'), throwsStateError);
    });

    test('no class change during a boss fight', () {
      var boss = true;
      final c = CatClass(rules, CatProgress(rules), inBossFight: () => boss)
        ..restore(const CatState(level: 10));
      expect(() => c.choose('archer'), throwsStateError);
      boss = false;
      c.choose('archer');
      expect(c.current, 'archer');
    });

    test('tier 2 grows from its parent at Lv40 (content v1.1)', () {
      final b = balance();
      (b['classes'] as Map)['knight'] = {
        ...(b['classes'] as Map)['warrior'] as Map<String, dynamic>,
        'tier': 2,
        'from': 'warrior',
      };
      final r = CatRules.fromBalance(b);
      final c = CatClass(r, CatProgress(r))
        ..restore(const CatState(level: 39, classId: 'warrior', tier: 1));
      expect(c.available.map((m) => m.id), isNot(contains('knight')));
      c.restore(const CatState(level: 40, classId: 'rogue', tier: 1));
      expect(c.available.map((m) => m.id), isNot(contains('knight')));
      c.choose('warrior');
      expect(c.available.map((m) => m.id), contains('knight'));
      c.choose('knight');
      expect(c.snapshot().tier, 2);
      expect(c.available, isEmpty); // no other tier-2 class yet
    });

    test('skill slots open at Lv10/20/30, never for the novice', () {
      expect(catAt(25).skillsUnlocked, 0);
      expect(catAt(10, 'rogue').skillsUnlocked, 1);
      expect(catAt(20, 'rogue').skillsUnlocked, 2);
      expect(catAt(30, 'rogue').skillsUnlocked, 3);
    });
  });

  group('save', () {
    test('decodes the Save v3 example and round-trips', () {
      final s = CatState.fromJson(
          jsonDecode('{"level": 1, "exp": 0, "class": "novice", "tier": 0}')
              as Map<String, dynamic>);
      final c = CatClass(rules, CatProgress(rules))..restore(s);
      expect(c.snapshot(), s);
      final c2 = catAt(12, 'archer');
      c2.progress.gainExp(7);
      final again = CatClass(rules, CatProgress(rules))
        ..restore(CatState.fromJson(c2.snapshot().toJson()));
      expect(again.snapshot(), c2.snapshot());
    });

    test('rejects saves that do not fit the data', () {
      void bad(CatState s) => expect(
          () => CatClass(rules, CatProgress(rules)).restore(s),
          throwsFormatException);
      bad(const CatState(classId: 'ninja'));
      bad(const CatState(level: 10, classId: 'rogue', tier: 0));
      bad(const CatState(level: 9, classId: 'rogue', tier: 1));
      bad(const CatState(level: 0));
      bad(const CatState(level: 1, exp: 20));
      expect(() => CatState.fromJson({'level': 1, 'exp': 0, 'class': 'novice'}),
          throwsFormatException);
    });
  });

  group('stats', () {
    test('(level base + extras) × class', () {
      final spec = catAt(11, 'warrior').combatSpec(
          extra: StatBlock(
              hp: 100, atk: 10, def: 1, attrs: {Attribute.evade: 300}));
      // Lv11: base ×1.2 · warrior hp ×1.4, atk ×0.8, def ×1.5
      expect(spec.stats.hp, (40 * 12 ~/ 10 + 100) * 14 ~/ 10);
      expect(spec.stats.atk, (6 * 12 ~/ 10 + 10) * 8 ~/ 10);
      expect(spec.stats.def, (3 * 12 ~/ 10 + 1) * 15 ~/ 10);
      expect(spec.stats[Attribute.evade], 300);
      expect(spec.attackIntervalMs, 1000);
      expect(catAt(10, 'rogue').combatSpec().stats[Attribute.evade], 1500);
    });

    test('the class still matters when gear dominates', () {
      final gear = StatBlock(hp: 5000, atk: 500, def: 100);
      final w = catAt(30, 'warrior').combatSpec(extra: gear).stats;
      final a = catAt(30, 'archer').combatSpec(extra: gear).stats;
      expect(w.hp / a.hp, closeTo(1.4 / 0.9, 0.02));
      expect(a.atk / w.atk, closeTo(1.35 / 0.8, 0.02));
    });
  });

  group('class identity in the same sim (GDD v0.5 §3.2)', () {
    const classes = ['warrior', 'rogue', 'archer', 'mage'];

    /// Fights a dummy for one minute; returns the engine and its events.
    (CombatEngine, List<CombatEvent>) duel(String cls, CombatUnitSpec dummy) {
      final e =
          CombatEngine(combat, buffs: buffs, firstCastPct: skills.firstCastPct);
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(
          seed: 11,
          units: [catAt(30, cls).combatSpec(), dummy],
          timeLimitMs: 60000));
      e.tick(60000);
      return (e, ev);
    }

    final punchingBag = CombatUnitSpec(
        id: 'bag',
        side: CombatSide.enemy,
        stats: StatBlock(hp: 1 << 30, atk: 1, def: 0),
        attackIntervalMs: 1000);
    final bruiser = CombatUnitSpec(
        id: 'bruiser',
        side: CombatSide.enemy,
        stats: StatBlock(hp: 1 << 30, atk: 30, def: 0),
        attackIntervalMs: 1000);

    Map<String, T> each<T>(T Function(String) f) =>
        {for (final c in classes) c: f(c)};

    /// Class with the single highest value ("tie" if shared).
    String top(Map<String, num> m) {
      num best = m.values.first;
      for (final v in m.values) {
        if (v > best) best = v;
      }
      final winners = m.keys.where((k) => m[k] == best).toList();
      return winners.length == 1 ? winners.single : 'tie';
    }

    test('archer deals the most normal-attack damage', () {
      final dmg = each(
          (c) => duel(c, punchingBag).$1.damageDealt(DamageChannel.normal));
      expect(top(dmg), 'archer', reason: '$dmg');
    });

    test('rogue attacks most often and dodges most', () {
      final hits = each((c) => duel(c, punchingBag)
          .$2
          .whereType<HitResolved>()
          .where(
              (h) => h.attackerId == 'mochi' && h.source == AttackSource.normal)
          .length);
      expect(top(hits), 'rogue', reason: '$hits');
      final dodges = each((c) => duel(c, punchingBag)
          .$2
          .whereType<HitResolved>()
          .where((h) => h.targetId == 'mochi' && h.outcome == HitOutcome.dodge)
          .length);
      expect(top(dodges), 'rogue', reason: '$dodges');
    });

    test('warrior has the most HP and DEF and outlasts a bruiser', () {
      final specs = each((c) => catAt(30, c).combatSpec().stats);
      expect(top(specs.map((k, v) => MapEntry(k, v.hp))), 'warrior');
      expect(top(specs.map((k, v) => MapEntry(k, v.def))), 'warrior');
      final survived = each((c) {
        final ev = duel(c, bruiser).$2;
        final down =
            ev.whereType<UnitDefeated>().where((d) => d.unitId == 'mochi');
        return down.isEmpty ? 60000 : down.first.atMs;
      });
      expect(top(survived), 'warrior', reason: '$survived');
    });

    test('mage deals the most skill damage (T-008)', () {
      final skill =
          each((c) => duel(c, punchingBag).$1.damageDealt(DamageChannel.skill));
      expect(top(skill), 'mage', reason: '$skill');
    });

    test('skills unlock by level: Lv10 = slot 1, Lv30 = all three', () {
      expect(
          catAt(10, 'mage').combatSpec().skills.map((s) => s.id), ['fireball']);
      expect(catAt(30, 'mage').combatSpec().skills, hasLength(3));
      expect(catAt(30, 'novice').combatSpec().skills, isEmpty);
    });
  });

  test('providers wire rules, progress and class', () {
    final container = ProviderContainer(overrides: [
      catRulesProvider.overrideWithValue(rules),
    ]);
    addTearDown(container.dispose);
    final cls = container.read(catClassProvider);
    container.read(catProgressProvider).gainExp(1 << 20);
    expect(cls.available, hasLength(4));
  });
}
