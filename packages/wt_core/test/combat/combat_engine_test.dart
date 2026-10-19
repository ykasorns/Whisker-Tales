import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_fixtures.dart';

void main() {
  final rules = loadRules();

  group('determinism', () {
    test('same seed + setup → identical events, 1000 seeds', () {
      final outcomes = <bool>{};
      for (var seed = 0; seed < 1000; seed++) {
        final a = record(rules, wave(seed), stepMs: 16);
        final b = record(rules, wave(seed), stepMs: 16);
        expect(a, b, reason: 'seed $seed');
        expect(a.last, isA<CombatEnded>());
        outcomes.add((a.last as CombatEnded).playerWon);
      }
      expect(outcomes, {true}); // the fixture cat clears a page-1 wave
    });

    test('splitting tick() differently gives the same events', () {
      for (var seed = 0; seed < 200; seed++) {
        final small = record(rules, wave(seed), stepMs: 16);
        final odd = record(rules, wave(seed), stepMs: 37);
        final one = record(rules, wave(seed), stepMs: 120000);
        expect(odd, small, reason: 'seed $seed');
        expect(one, small, reason: 'seed $seed');
      }
    });

    test('different seeds give different fights', () {
      expect(record(rules, wave(1), stepMs: 50),
          isNot(record(rules, wave(2), stepMs: 50)));
    });
  });

  group('flow', () {
    test('defeated monsters emit UnitDefeated, then the fight ends', () {
      final ev = record(
          rules, CombatSetup(seed: 3, units: [cat(), mon('a'), mon('b')]),
          stepMs: 100);
      final defeated = ev.whereType<UnitDefeated>().map((e) => e.unitId);
      expect(defeated, ['a', 'b']);
      expect(ev.last,
          isA<CombatEnded>().having((e) => e.playerWon, 'playerWon', isTrue));
      expect(ev.whereType<CombatEnded>(), hasLength(1));
    });

    test('the cat loses to a much stronger monster', () {
      final e = CombatEngine(rules)
        ..start(CombatSetup(
            seed: 1, units: [cat(hp: 50), mon('king', hp: 9999, atk: 80)]));
      expect(e.runToEnd(), isFalse);
    });

    test('nothing happens after the fight ends', () {
      final e = CombatEngine(rules);
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(seed: 1, units: [cat(), mon('a')]));
      e.runToEnd();
      final n = ev.length;
      e.tick(60000);
      expect(ev, hasLength(n));
    });

    test('attacks land on the interval; monsters hit the front target first',
        () {
      final ev = record(
          rules,
          CombatSetup(seed: 1, units: [
            cat(atk: 1000, intervalMs: 500),
            mon('front', intervalMs: 700),
            mon('back', intervalMs: 700),
          ]),
          stepMs: 10);
      final hits = ev.whereType<HitResolved>().toList();
      expect(hits.first.atMs, 500);
      expect(hits.first.targetId, 'front');
      expect(hits[1].atMs, 700); // back attacks; front is gone
      expect(hits[1].attackerId, 'back');
    });

    test('time limit ends the fight as a loss', () {
      final e = CombatEngine(rules)
        ..start(CombatSetup(
            seed: 1,
            units: [cat(atk: 1), mon('wall', hp: 99999, atk: 1)],
            timeLimitMs: 5000));
      expect(e.runToEnd(), isFalse);
      expect(e.nowMs, 5000);
    });

    test('attack speed shortens the interval', () {
      final ev = record(
          rules,
          CombatSetup(seed: 1, units: [
            cat(intervalMs: 1000, attrs: {Attribute.attackSpeed: 10000}),
            mon('a', hp: 9999, intervalMs: 99999),
          ]),
          stepMs: 3000,
          maxMs: 3000);
      expect(ev.whereType<HitResolved>().map((e) => e.atMs).take(3),
          [500, 1000, 1500]);
    });
  });

  group('partners and procs', () {
    test('a partner deals partner-channel damage and is never targeted', () {
      final e = CombatEngine(rules);
      final ev = <CombatEvent>[];
      e.events.listen(ev.add);
      e.start(CombatSetup(
          seed: 9, units: [cat(hp: 5000, atk: 1), pet(), mon('a', hp: 3000)]));
      e.tick(30000);
      final hits = ev.whereType<HitResolved>();
      expect(hits.where((h) => h.targetId == 'sparrow'), isEmpty);
      final petHits = hits.where((h) => h.attackerId == 'sparrow');
      expect(petHits, isNotEmpty);
      expect(petHits.every((h) => h.channel == DamageChannel.partner), isTrue);
      expect(e.damageDealt(DamageChannel.partner), greaterThan(0));
      expect(e.damageDealt(DamageChannel.normal), greaterThan(0));
    });

    test('a fight with only a partner on the cat side is rejected', () {
      expect(
          () => CombatEngine(rules)
              .start(CombatSetup(seed: 1, units: [pet(), mon('a')])),
          throwsArgumentError);
      expect(
          () => CombatEngine(rules)
              .start(CombatSetup(seed: 1, units: [cat(), cat(), mon('a')])),
          throwsArgumentError);
    });

    test('stun pushes back the next attack', () {
      final ev = record(
          rules,
          CombatSetup(seed: 4, units: [
            cat(
                hp: 99999,
                atk: 1,
                intervalMs: 400,
                attrs: {Attribute.stun: 10000}),
            mon('a', hp: 99999, intervalMs: 1000),
          ]),
          stepMs: 5000,
          maxMs: 5000);
      final stuns = ev.whereType<UnitStunned>().toList();
      expect(stuns, isNotEmpty);
      final monHits =
          ev.whereType<HitResolved>().where((h) => h.attackerId == 'a');
      for (final h in monHits) {
        final active =
            stuns.where((s) => s.atMs < h.atMs && h.atMs < s.untilMs);
        expect(active, isEmpty, reason: 'hit at ${h.atMs} during a stun');
      }
    });

    test('lifesteal and regen heal, never above max HP', () {
      final ev = record(
          rules,
          CombatSetup(seed: 5, units: [
            cat(
                hp: 1000,
                attrs: {Attribute.lifesteal: 3000, Attribute.regen: 500}),
            mon('a', hp: 5000, atk: 60),
          ]),
          stepMs: 20000,
          maxMs: 20000);
      final heals = ev.whereType<UnitHealed>();
      expect(heals.map((h) => h.cause).toSet(),
          {HealCause.lifesteal, HealCause.regen});
      expect(heals.every((h) => h.hp <= 1000 && h.amount > 0), isTrue);
    });

    test('counters and combos are tagged with their source', () {
      final ev = record(
          rules,
          CombatSetup(seed: 6, units: [
            cat(
                hp: 99999,
                attrs: {Attribute.counter: 4000, Attribute.combo: 4000}),
            mon('a', hp: 99999),
          ]),
          stepMs: 20000,
          maxMs: 20000);
      final sources = ev.whereType<HitResolved>().map((h) => h.source).toSet();
      expect(sources, containsAll(AttackSource.values));
      // a counter answers a monster hit; a combo follows a cat hit
      for (final h in ev.whereType<HitResolved>()) {
        if (h.source != AttackSource.normal) expect(h.attackerId, 'mochi');
      }
    });
  });

  test('guards', () {
    expect(() => CombatEngine(rules).tick(16), throwsStateError);
    final e = CombatEngine(rules)
      ..start(CombatSetup(seed: 1, units: [cat(), mon('a')]));
    expect(() => e.tick(-1), throwsArgumentError);
    e.useSkill(0); // no-op until T-008 (D-004: no player input)
  });

  test('headless: one wave of 5 monsters in under 5 ms on average', () {
    for (var i = 0; i < 50; i++) {
      CombatEngine(rules)
        ..start(wave(i))
        ..runToEnd();
    }
    const runs = 500;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      final e = CombatEngine(rules)..start(wave(i));
      expect(e.runToEnd(), isNotNull);
    }
    sw.stop();
    final avgMs = sw.elapsedMicroseconds / runs / 1000;
    expect(avgMs, lessThan(5), reason: 'avg $avgMs ms');
    // ignore: avoid_print
    print('combat wave avg: ${avgMs.toStringAsFixed(3)} ms');
  });
}
