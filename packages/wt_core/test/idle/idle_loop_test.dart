import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> balance() => jsonDecode(
        File('../../design/balance/idle_balance_v1.json').readAsStringSync())
    as Map<String, dynamic>;

void main() {
  final rules = IdleRules.fromBalance(balance());
  final combat = CombatRules.fromBalance(balance());
  final cat = CatRules.fromBalance(balance());
  final income = IncomeModel(rules, expPerKill: cat.expPerKill);

  CombatUnitSpec catWith(int hp, int atk) => CombatUnitSpec(
      id: 'mochi',
      side: CombatSide.cat,
      stats: StatBlock(hp: hp, atk: atk, def: 0),
      attackIntervalMs: 500);
  final strong = catWith(1 << 30, 1 << 20);
  final weak = catWith(1, 1);

  IdleLoop loop({
    required CombatUnitSpec Function() spec,
    int seed = 7,
    IdleHooks hooks = const IdleHooks(),
  }) =>
      IdleLoop(
        rules: rules,
        income: income,
        engineFactory: () => CombatEngine(combat),
        catSpec: spec,
        hpWeightPm: combat.powerWeights.hpPm,
        atkWeightPm: combat.powerWeights.atkPm,
        seed: seed,
        hooks: hooks,
      );

  String describe(IdleEvent e) => switch (e) {
        WaveCleared() => 'W${e.page}.${e.waveIndex} ${e.reward} exp${e.exp}',
        BossResult() => 'B${e.page} ${e.won} ${e.reward} exp${e.exp}',
        WaveFailed() => 'F${e.page}.${e.waveIndex}',
      };

  List<IdleEvent> run(IdleLoop l, {required int ms, int step = 100}) {
    final out = <IdleEvent>[];
    l.events.listen(out.add);
    for (var t = 0; t < ms; t += step) {
      l.tick(step);
    }
    return out;
  }

  group('curves from data', () {
    test('P(n) and boss multipliers (GDD v0.4 §15.3)', () {
      expect(rules.wavePower(1), 100);
      expect(rules.wavePower(10), 444);
      // page boss ×1.5, early-page discount 40% fading over pages 1–10 (D-011)
      expect(rules.bossPower(5), 221); // 194 × 1.5 × 0.76
      expect(rules.bossPower(10), 938); // chapter boss 444 × 2.2 × 0.96
      expect(rules.bossPower(20),
          (rules.wavePower(20) * 2.2).round()); // no discount after chapter 1
      expect(rules.isChapterBoss(20), isTrue);
    });

    test('book / chapter / page numbering', () {
      expect((rules.bookOf(30), rules.chapterOf(30)), (1, 3));
      expect((rules.bookOf(31), rules.chapterOf(31), rules.pageInChapter(31)),
          (2, 1, 1));
      expect(rules.chapterOf(11), 2);
    });

    test('income per wave in thousandths', () {
      // yarn 0.1 + early bonus 0.5 fading over pages 1–10 (D-011)
      expect(income.perWaveMilli(1),
          {Currency.goldfish: 2000, Currency.yarn: 600, Currency.eggs: 10});
      expect(income.perWaveMilli(10)[Currency.goldfish], 3379);
      expect(income.perWaveMilli(10)[Currency.yarn], 168);
      expect(income.perWaveMilli(11)[Currency.yarn], 120);
      expect(income.forWaves(1, 10),
          RewardBundle({Currency.goldfish: 20, Currency.yarn: 6}));
      expect(rules.starterYarn, 10);
      expect(income.perWave(1), RewardBundle({Currency.goldfish: 2}));
      expect(income.expForWaves(1, 10), 50); // 10 × 2.5 monsters × 2 EXP
    });
  });

  group('page plan (GDD v0.5.2 §9.1)', () {
    test('same page, same plan', () {
      for (var p = 1; p <= 60; p++) {
        expect(pagePlan(rules, p).monstersPerWave,
            pagePlan(rules, p).monstersPerWave);
      }
    });

    test('waves and monsters stay in the chapter ranges', () {
      for (var p = 1; p <= 90; p++) {
        final plan = pagePlan(rules, p);
        final (wlo, whi) = rules.wavesByChapter[plan.chapter - 1];
        final extra = plan.isLong ? rules.longExtraWaves : 0;
        expect(plan.waves, inInclusiveRange(wlo + extra, whi + extra),
            reason: 'page $p');
        final (mlo, mhi) = rules.monstersByChapter[plan.chapter - 1];
        for (final m in plan.monstersPerWave) {
          expect(m, inInclusiveRange(mlo, mhi));
        }
      }
    });

    test('pages 5 and 10 of each chapter are long; lengths vary', () {
      expect([
        for (var p = 1; p <= 30; p++)
          if (pagePlan(rules, p).isLong) p
      ], [
        5,
        10,
        15,
        20,
        25,
        30
      ]);
      final ch3 = {for (var p = 21; p <= 30; p++) pagePlan(rules, p).waves};
      expect(ch3.length, greaterThan(1));
      expect(pagePlan(rules, 1).monstersIn(100), isPositive); // cycles
    });
  });

  group('loop', () {
    test('waves pay the same as the offline formula', () {
      final l = loop(spec: () => strong);
      final ev = run(l, ms: 120000).whereType<WaveCleared>().toList();
      expect(ev.length, greaterThan(10));
      expect(ev.every((e) => e.page == 1), isTrue); // no boss without AUTO
      final total = ev.map((e) => e.reward).reduce((a, b) => a + b);
      expect(total, income.forWaves(1, ev.length));
      final plan = pagePlan(rules, 1);
      for (final e in ev) {
        expect(e.exp, plan.monstersIn(e.waveIndex) * cat.expPerKill(1));
      }
    });

    test('boss opens after the planned waves; a win moves on', () async {
      final l = loop(spec: () => strong);
      expect(l.bossReady, isFalse);
      expect(l.challengeBoss(), throwsStateError);
      while (!l.bossReady) {
        l.tick(100);
      }
      final result = l.challengeBoss();
      expect(l.isBossFight, isTrue);
      while (l.isBossFight) {
        l.tick(100);
      }
      final r = await result;
      expect(r.won, isTrue);
      expect(r.reward, RewardBundle({Currency.goldfish: 40, Currency.eggs: 1}));
      expect(r.exp, rules.bossExpKills * cat.expPerKill(1));
      expect(l.state, const IdleProgress(book: 1, clearedPage: 1, farmPage: 2));
      expect(l.waveIndex, 0);
    });

    test('losing a boss costs nothing and farming goes on', () async {
      var spec = strong;
      final l = loop(spec: () => spec);
      while (!l.bossReady) {
        l.tick(100);
      }
      spec = weak;
      final r = l.challengeBoss();
      run(l, ms: 70000);
      expect((await r).won, isFalse);
      expect((await r).reward, RewardBundle.empty);
      expect(l.state.clearedPage, 0);
      expect(l.state.farmPage, 1);
      expect(l.bossReady, isTrue);
    });

    test('AUTO boss climbs pages; a hook can hold it back', () {
      final l = loop(spec: () => strong)..autoBoss = true;
      run(l, ms: 10 * 60000);
      expect(l.state.clearedPage, greaterThan(3));

      var held = 0;
      final h = loop(
          spec: () => strong,
          hooks: IdleHooks(canAutoChallenge: () {
            held++;
            return false;
          }))
        ..autoBoss = true;
      run(h, ms: 5 * 60000);
      expect(h.state.clearedPage, 0);
      expect(held, greaterThan(0));
    });

    test('after a lost boss AUTO waits a few waves before retrying', () {
      var spec = strong;
      final l = loop(spec: () => spec)..autoBoss = true;
      final ev = <IdleEvent>[];
      l.events.listen(ev.add);
      while (!l.bossReady) {
        l.tick(100);
      }
      spec = weak;
      while (ev.whereType<BossResult>().isEmpty) {
        l.tick(100);
      }
      spec = strong;
      while (ev.whereType<BossResult>().length < 2) {
        l.tick(100);
      }
      final first = ev.indexWhere((e) => e is BossResult);
      final second = ev.lastIndexWhere((e) => e is BossResult);
      final between = ev.sublist(first, second).whereType<WaveCleared>();
      expect(between.length, rules.autoBossRetryWaves);
    });

    test('a weak cat rests, retries, then farms one page back', () {
      final l = loop(spec: () => weak)..restore(clearedPage: 2);
      expect(l.state.farmPage, 3);
      final ev = run(l, ms: 60000);
      expect(ev.whereType<WaveFailed>().length,
          greaterThanOrEqualTo(rules.retreatAfterLosses));
      expect(l.state.farmPage, lessThan(3));
      expect(l.state.clearedPage, 2);
    });

    test('farm page can be chosen up to the frontier', () {
      final l = loop(spec: () => strong)..restore(clearedPage: 4);
      l.setFarmPage(2);
      expect(l.state.farmPage, 2);
      expect(l.bossReady, isFalse); // boss only on the frontier page
      expect(() => l.setFarmPage(6), throwsRangeError);
      expect(() => l.setFarmPage(0), throwsRangeError);
      expect(l.recommendedFarmPage(1 << 30), 5);
      expect(l.recommendedFarmPage(0), 1);
    });

    test('hooks fire for walks, waves and bosses', () {
      var walks = 0, waves = 0, bosses = 0;
      final l = loop(
          spec: () => strong,
          hooks: IdleHooks(
            onWalkBetweenWaves: () => walks++,
            onWaveCleared: (_, __) => waves++,
            onBossEnded: (_) => bosses++,
          ))
        ..autoBoss = true;
      run(l, ms: 3 * 60000);
      expect(waves, greaterThan(5));
      expect(bosses, greaterThan(0));
      expect(walks, greaterThanOrEqualTo(waves));
    });
  });

  group('determinism', () {
    /// A cat close to the page-1 monsters, so luck decides some fights.
    List<String> trace(int seed, int step) {
      final l = loop(
          seed: seed,
          spec: () => CombatUnitSpec(
              id: 'mochi',
              side: CombatSide.cat,
              stats: StatBlock(hp: 30, atk: 10, def: 0, attrs: {
                Attribute.crit: 3000,
                Attribute.evade: 3000,
              }),
              attackIntervalMs: 900))
        ..autoBoss = true;
      return run(l, ms: 8 * 60000, step: step).map(describe).toList();
    }

    test('same seed → same events, however time is split', () {
      final a = trace(3, 16);
      expect(a, isNotEmpty);
      expect(trace(3, 16), a);
      expect(trace(3, 1000), a);
      expect(trace(3, 37), a);
    });

    test('different seeds differ', () {
      final traces = {
        for (var seed = 1; seed <= 8; seed++) trace(seed, 100).join('|')
      };
      expect(traces.length, greaterThan(1));
    });
  });

  test('providers: waves grant cat EXP; boss fight blocks class change', () {
    final c = ProviderContainer(overrides: [
      combatRulesProvider.overrideWithValue(combat),
      catRulesProvider.overrideWithValue(cat),
      idleRulesProvider.overrideWithValue(rules),
      catExtraStatsProvider
          .overrideWithValue(() => StatBlock(hp: 100000, atk: 100000, def: 0)),
    ]);
    addTearDown(c.dispose);
    final l = c.read(idleLoopProvider);
    for (var i = 0; i < 1200; i++) {
      l.tick(100);
    }
    final p = c.read(catProgressProvider);
    expect(p.level, greaterThan(1));
    expect(c.read(inBossFightProvider)(), l.isBossFight);
  });
}
