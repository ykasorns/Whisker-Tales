import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

class FakeAds implements IAdService {
  bool allowed = true;
  AdOutcome outcome = AdOutcome.rewarded;
  int shown = 0;
  @override
  bool canShow(String placementId) => allowed;
  @override
  Future<AdOutcome> show(String placementId) async {
    shown++;
    return outcome;
  }

  @override
  int remainingToday(String placementId) => allowed ? 1 : 0;
}

void main() {
  final balance = _json('../../design/balance/idle_balance_v1.json');
  final data = _json('../../design/data/road_events.json');
  final rules = RoadEventRules.fromJson(balance, data);
  final idle = IdleRules.fromBalance(balance);
  final combat = CombatRules.fromBalance(balance);

  late FakeAds ads;
  late MemoryWallet wallet;
  RoadEvents road({int seed = 1}) => RoadEvents(
      rules: rules,
      idleRules: idle,
      wallet: wallet,
      ads: () => ads,
      seed: seed);
  setUp(() {
    ads = FakeAds();
    wallet = MemoryWallet();
  });

  /// One wave: clear it, then walk to the next.
  void wave(RoadEvents r, {int page = 1}) {
    r.hooks.onWaveCleared!(page, 0);
    r.hooks.onWalkBetweenWaves!(page);
  }

  RoadEvents withEvent(String id) {
    for (var seed = 0; seed < 500; seed++) {
      final r = road(seed: seed);
      for (var i = 0; i < 40; i++) {
        wave(r);
        if (r.active.any((a) => a.eventId == id)) return r;
      }
    }
    throw StateError('no seed gave $id');
  }

  CombatUnitSpec cat() => CombatUnitSpec(
      id: 'mochi',
      side: CombatSide.cat,
      stats:
          StatBlock(hp: 1000, atk: 100, def: 50, attrs: {Attribute.evade: 500}),
      attackIntervalMs: 900);

  group('data (D-008 limits)', () {
    test('loads the events', () {
      expect(rules.events.length, 7);
      expect(rules.everyWaves, (3, 5));
      expect(rules.maxActive, 2);
      expect(rules.events.firstWhere((e) => e.id == 'grilled_fish').waves, 3);
    });

    test('refuses bad events that are too strong, too long, or pay out', () {
      Map<String, dynamic> withBad(Map<String, dynamic> bad) => {
            'events': [
              ...(data['events'] as List),
              {'id': 'x', 'kind': 'bad', ...bad},
            ],
          };
      for (final bad in [
        {
          'effects': [
            {'stat': 'atk', 'pct': -11}
          ],
          'waves': 1
        },
        {
          'effects': [
            {'stat': 'atk', 'pct': -5}
          ],
          'waves': 3
        },
        {
          'effects': [
            {'stat': 'atk', 'pct': 5}
          ],
          'waves': 1
        },
        {
          'effects': [
            {'reward': 'yarn', 'mult_pct': 50}
          ],
          'waves': 1
        },
        {
          'instant': {'goldfish_waves': 1}
        },
      ]) {
        expect(() => RoadEventRules.fromJson(balance, withBad(bad)),
            throwsFormatException,
            reason: '$bad');
      }
    });
  });

  group('timing', () {
    test('an event turns up every 3–5 waves, at most 2 at once', () {
      final r = road();
      final news = <RoadEventNews>[];
      r.news.listen(news.add);
      var lastStart = 0;
      for (var w = 1; w <= 300; w++) {
        final before = news.whereType<RoadEventStarted>().length;
        wave(r);
        if (news.whereType<RoadEventStarted>().length > before) {
          expect(w - lastStart, inInclusiveRange(3, 5));
          lastStart = w;
        }
        expect(r.active.length, lessThanOrEqualTo(2));
      }
      final starts = news.whereType<RoadEventStarted>().toList();
      expect(starts.length, greaterThan(50));
      final good =
          starts.where((s) => s.event.kind == RoadEventKind.good).length;
      expect(good / starts.length, closeTo(0.7, 0.15));
    });

    test('same seed, same events', () {
      List<String> trace(int seed) {
        final r = road(seed: seed);
        final out = <String>[];
        r.news.listen((n) => out.add(n is RoadEventStarted
            ? '+${n.event.eventId}'
            : '-${(n as RoadEventEnded).event.eventId}'));
        for (var i = 0; i < 100; i++) {
          wave(r);
        }
        return out;
      }

      expect(trace(5), trace(5));
      expect(trace(5), isNot(trace(6)));
    });

    test('effects count down per wave and per boss fight, then wear off', () {
      final r = withEvent('grilled_fish');
      final a = r.active.firstWhere((a) => a.eventId == 'grilled_fish');
      expect(a.wavesLeft, 3);
      r.hooks.onBossEnded!(false); // a boss fight counts as one wave
      r.hooks.onWaveCleared!(1, 0);
      expect(r.active.firstWhere((x) => x.uid == a.uid).wavesLeft, 1);
      r.hooks.onWaveCleared!(1, 0);
      expect(r.active.where((x) => x.uid == a.uid), isEmpty);
    });

    test('instant events pay goldfish and do not take a slot', () {
      for (var seed = 0; seed < 200; seed++) {
        wallet = MemoryWallet();
        final r = road(seed: seed);
        var paid = false;
        r.news.listen((n) {
          if (n is RoadEventStarted && n.event.eventId == 'fish_bag') {
            paid = true;
          }
        });
        for (var i = 0; i < 40 && !paid; i++) {
          wave(r, page: 10);
        }
        if (paid) {
          expect(wallet.balance(Currency.goldfish),
              idle.perWaveMilli(10)[Currency.goldfish]! * 5 ~/ 1000);
          expect(r.active.where((a) => a.eventId == 'fish_bag'), isEmpty);
          return;
        }
      }
      fail('no fish bag in 200 seeds');
    });
  });

  group('effects', () {
    test('stats change by the data', () {
      final fish = withEvent('grilled_fish').apply(cat());
      expect(fish.stats.atk, 120);
      final rain = withEvent('drizzle').apply(cat());
      expect(rain.attackIntervalMs, 1000); // attacks 10% slower
      final bees = withEvent('bees').apply(cat());
      expect(bees.stats[Attribute.evade], 0); // 5% − 10 points, floored
      final mud = withEvent('mud').apply(cat());
      expect(mud.stats.def, 45);
      final plain = cat();
      expect(road().apply(plain), same(plain));
    });

    test('road effects keep the cat\'s skills', () {
      const sk = SkillSpec(
          id: 'fireball',
          cooldownMs: 3000,
          target: SkillTarget.front,
          damagePct: 200);
      final buffed =
          withEvent('grilled_fish').apply(cat().copyWith(skills: const [sk]));
      expect(buffed.skills.single.id, 'fireball');
    });

    test('rainbow doubles wave yarn', () {
      final r = withEvent('rainbow');
      final out = r.hooks.adjustReward!(
          RewardBundle({Currency.yarn: 3, Currency.goldfish: 5}));
      expect(out, RewardBundle({Currency.yarn: 6, Currency.goldfish: 5}));
    });

    test('AUTO boss waits while a bad event is active', () {
      final r = withEvent('drizzle');
      expect(r.hooks.canAutoChallenge!(), isFalse);
      r.hooks.onWaveCleared!(1, 0);
      r.hooks.onWaveCleared!(1, 0);
      expect(r.hasBad, r.active.any((a) => a.kind == RoadEventKind.bad));
    });
  });

  group('ads (placement road_event)', () {
    test('good event: an ad makes it last ×2, once', () async {
      final r = withEvent('grilled_fish');
      final uid = r.active.firstWhere((a) => a.eventId == 'grilled_fish').uid;
      expect(r.canOfferAd(uid), isTrue);
      expect(await r.boostWithAd(uid), isTrue);
      final a = r.active.firstWhere((a) => a.uid == uid);
      expect((a.wavesLeft, a.boosted), (6, true));
      expect(r.canOfferAd(uid), isFalse);
      expect(await r.boostWithAd(uid), isFalse);
      expect(ads.shown, 1);
    });

    test('bad event: an ad cleanses it now', () async {
      final r = withEvent('mud');
      final uid = r.active.firstWhere((a) => a.eventId == 'mud').uid;
      final news = <RoadEventNews>[];
      r.news.listen(news.add);
      expect(await r.cleanseWithAd(uid), isTrue);
      expect(r.active.where((a) => a.uid == uid), isEmpty);
      expect(
          (news.single as RoadEventEnded).reason, RoadEventEndReason.cleansed);
    });

    test('no ad (cap / Supporter Pack / skipped) changes nothing', () async {
      final r = withEvent('mud');
      final uid = r.active.firstWhere((a) => a.eventId == 'mud').uid;
      ads.allowed = false;
      expect(r.canOfferAd(uid), isFalse);
      expect(await r.cleanseWithAd(uid), isFalse);
      expect(ads.shown, 0);
      ads
        ..allowed = true
        ..outcome = AdOutcome.skipped;
      expect(await r.cleanseWithAd(uid), isFalse);
      expect(r.active.where((a) => a.uid == uid), hasLength(1));
      expect(await r.boostWithAd(uid), isFalse); // not a good event
    });
  });

  test('D-008: a debuff alone never loses a fight a fair cat would win', () {
    // A cat whose power equals the wave power P(n), against that page's
    // waves; then the same fight with the two strongest bad events at once.
    final bad = rules.events.where((e) => e.kind == RoadEventKind.bad).toList();
    var won = 0, flipped = 0;
    for (var seed = 0; seed < 1000; seed++) {
      final page = seed % 30 + 1;
      final p = idle.wavePower(page);
      final plan = pagePlan(idle, page);
      final k = plan.monstersIn(seed);
      final fair = CombatUnitSpec(
          id: 'mochi',
          side: CombatSide.cat,
          stats: StatBlock(
              hp: p * 600 ~/ combat.powerWeights.hpPm,
              atk: p * 400 ~/ combat.powerWeights.atkPm,
              def: 0),
          attackIntervalMs: 900);
      List<CombatUnitSpec> monsters() => [
            for (var i = 0; i < k; i++)
              CombatUnitSpec(
                  id: 'm$i',
                  side: CombatSide.enemy,
                  stats: StatBlock(
                      hp: p * 600 ~/ (combat.powerWeights.hpPm * k),
                      atk: p * 400 ~/ (combat.powerWeights.atkPm * k),
                      def: 0),
                  attackIntervalMs: idle.monsterIntervalMs),
          ];
      bool fight(CombatUnitSpec c) => (CombatEngine(combat)
            ..start(CombatSetup(seed: seed, units: [c, ...monsters()])))
          .runToEnd()!;
      if (!fight(fair)) continue;
      won++;
      for (var i = 0; i < bad.length; i++) {
        for (var j = i + 1; j < bad.length; j++) {
          if (!fight(applyRoadEffects(fair, [bad[i], bad[j]]))) flipped++;
        }
      }
    }
    expect(won, greaterThan(900));
    expect(flipped, 0, reason: '$flipped fights lost only because of debuffs');
  });

  test(
      'in the loop: effects reach boss fights; AUTO never starts a boss '
      'during a debuff; manual challenge still can', () {
    final r = road(seed: 3);
    final base = CombatUnitSpec(
        id: 'mochi',
        side: CombatSide.cat,
        stats: StatBlock(hp: 1 << 30, atk: 1 << 20, def: 0),
        attackIntervalMs: 500);
    var buffedBoss = 0, bosses = 0;
    late IdleLoop loop;
    loop = IdleLoop(
      rules: idle,
      income: IncomeModel(idle, expPerKill: (_) => 1),
      engineFactory: () => CombatEngine(combat),
      catSpec: () => r.apply(base),
      hpWeightPm: combat.powerWeights.hpPm,
      atkWeightPm: combat.powerWeights.atkPm,
      hooks: r.hooks,
    )..autoBoss = true;
    var wasBoss = false;
    for (var t = 0; t < 40 * 60000; t += 100) {
      loop.tick(100);
      if (loop.isBossFight && !wasBoss) {
        bosses++;
        expect(r.hasBad, isFalse,
            reason: 'AUTO started a boss during a debuff');
        if (r.apply(base) != base) buffedBoss++;
      }
      wasBoss = loop.isBossFight;
    }
    expect(bosses, greaterThan(10));
    expect(buffedBoss, greaterThan(0)); // a buff carried into a boss fight

    // a held AUTO (debuff) never blocks the player's own challenge
    final l2 = IdleLoop(
      rules: idle,
      income: IncomeModel(idle, expPerKill: (_) => 1),
      engineFactory: () => CombatEngine(combat),
      catSpec: () => base,
      hpWeightPm: combat.powerWeights.hpPm,
      atkWeightPm: combat.powerWeights.atkPm,
      hooks: IdleHooks(canAutoChallenge: () => false),
    )..autoBoss = true;
    for (var t = 0; t < 5 * 60000; t += 100) {
      l2.tick(100);
      expect(l2.isBossFight, isFalse);
    }
    expect(l2.bossReady, isTrue);
    l2.challengeBoss();
    expect(l2.isBossFight, isTrue);
  });
}
