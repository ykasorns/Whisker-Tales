import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

class Time implements TimeSource {
  Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

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
  final balance = _j('../../design/balance/idle_balance_v1.json');
  final data = _j('../../design/data/pets.json');
  final rules = PetsRules.fromJson(balance, data);

  late Time time;
  late GameClock clock;
  late MemoryWallet wallet;
  late FakeAds ads;
  var cleared = 0;
  Pets pets({PetsRules? r, int seed = 1}) => Pets(
      rules: r ?? rules,
      wallet: wallet,
      ads: () => ads,
      clock: clock,
      clearedPage: () => cleared,
      seed: seed);
  setUp(() {
    time = Time(DateTime.utc(2026, 10, 20, 2));
    clock = GameClock(time);
    wallet = MemoryWallet();
    ads = FakeAds();
    cleared = 0;
  });

  test('roster and numbers load from data', () {
    expect(rules.pets, hasLength(6));
    expect([
      for (final r in PetRarity.values)
        rules.pets.where((p) => p.rarity == r).length
    ], [
      3,
      2,
      1
    ]);
    expect(rules.pullPct, [75, 22, 3]);
    expect(pets().rates,
        {PetRarity.common: 75, PetRarity.rare: 22, PetRarity.legend: 3});
    expect(rules.pityLegendEvery, 40);
  });

  test('rarity odds match the shown table (chi-square, 100k eggs)', () async {
    final b = _j('../../design/balance/idle_balance_v1.json');
    (b['pets'] as Map)['pity_legend_every'] = 1 << 30; // isolate the table
    final p = pets(r: PetsRules.fromJson(b, data));
    const n = 100000;
    wallet.add(RewardBundle({Currency.eggs: n}));
    final c = List.filled(3, 0);
    for (var i = 0; i < n; i++) {
      c[(await p.hatch(HatchSource.egg))!.rarity.index]++;
    }
    var chi = 0.0;
    for (var i = 0; i < 3; i++) {
      final e = rules.pullPct[i] * n / 100;
      chi += (c[i] - e) * (c[i] - e) / e;
    }
    expect(chi, lessThan(13.82), reason: '$c'); // df 2, p = 0.001
  });

  test('legend guarantee at 40, kept across days', () async {
    final p = pets(seed: 3);
    wallet.add(RewardBundle({Currency.eggs: 400}));
    var sinceLegend = 0;
    for (var i = 0; i < 400; i++) {
      if (i == 20) {
        time.utc = time.utc.add(const Duration(days: 1)); // a new day mid-count
        clock.tick();
        expect(p.pity, sinceLegend); // not reset
      }
      final r = (await p.hatch(HatchSource.egg))!;
      sinceLegend++;
      expect(sinceLegend, lessThanOrEqualTo(40));
      if (r.rarity == PetRarity.legend) sinceLegend = 0;
    }
  });

  test(
      'fish hatches: 5 a day, ×1.5 each, chapter scaling, reset on a new day only',
      () async {
    final p = pets();
    wallet.add(RewardBundle({Currency.goldfish: 100000}));
    final costs = <int>[];
    for (var i = 0; i < 5; i++) {
      costs.add(p.nextFishCost);
      expect(await p.hatch(HatchSource.fish), isNotNull);
    }
    expect(costs, [300, 450, 675, 1013, 1519]);
    expect(p.fishHatchesLeftToday, 0);
    expect(await p.hatch(HatchSource.fish), isNull);
    time.utc = time.utc.subtract(const Duration(days: 2)); // clock turned back
    clock.tick();
    expect(p.fishHatchesLeftToday, 0);
    time.utc = DateTime.utc(2026, 10, 21, 2);
    clock.tick();
    expect(p.fishHatchesLeftToday, 5);
    cleared = 10; // chapter 2: +8%
    expect(p.nextFishCost, 324);
  });

  test('not enough goldfish or eggs: nothing happens', () async {
    final p = pets();
    expect(await p.hatch(HatchSource.egg), isNull);
    expect(await p.hatch(HatchSource.fish), isNull);
    expect(p.fishHatchesLeftToday, 5);
    expect(p.owned, isEmpty);
  });

  test('ad hatch only pays out on a finished ad', () async {
    final p = pets();
    ads.allowed = false;
    expect(await p.hatch(HatchSource.ad), isNull);
    expect(ads.shown, 0);
    ads
      ..allowed = true
      ..outcome = AdOutcome.skipped;
    expect(await p.hatch(HatchSource.ad), isNull);
    expect(p.owned, isEmpty);
    ads.outcome = AdOutcome.rewarded;
    expect(await p.hatch(HatchSource.ad), isNotNull);
    expect(p.owned, hasLength(1));
  });

  test('duplicates add stars up to max, then give treats', () async {
    final p = pets();
    wallet.add(RewardBundle({Currency.eggs: 3000}));
    final stars = <String, int>{};
    var treats = 0;
    for (var i = 0; i < 3000; i++) {
      final r = (await p.hatch(HatchSource.egg))!;
      if (r.isNew) expect(r.stars, 1);
      if (r.cookies > 0) {
        expect(stars[r.petId], rules.maxStars);
        treats += r.cookies;
      }
      stars[r.petId] = r.stars;
    }
    expect(p.owned.values.every((s) => s <= rules.maxStars), isTrue);
    expect(wallet.balance(Currency.cookies), treats);
  });

  test('deploy slots open by chapter; first pets deploy themselves', () async {
    final p = pets();
    expect(p.deploySlots, 1);
    wallet.add(RewardBundle({Currency.eggs: 30}));
    for (var i = 0; i < 30; i++) {
      await p.hatch(HatchSource.egg);
    }
    expect(p.deployed, hasLength(1));
    cleared = 10;
    expect(p.deploySlots, 2);
    final other = p.owned.keys.firstWhere((id) => id != p.deployed.first);
    p.deploy(1, other);
    expect(p.deployed, hasLength(2));
    cleared = 25;
    expect(p.deploySlots, 3);
    expect(() => p.deploy(3, other), throwsRangeError);
    expect(() => p.deploy(0, 'dragon'), throwsStateError);
  });

  test('owned pets give a passive; deployed pets fight as partners', () async {
    final p = pets();
    wallet.add(RewardBundle({Currency.eggs: 1}));
    final r = (await p.hatch(HatchSource.egg))!;
    final cat = CombatUnitSpec(
        id: 'mochi',
        side: CombatSide.cat,
        stats: StatBlock(
            hp: 1000, atk: 100, def: 0, attrs: {Attribute.petDmg: 5000}),
        attackIntervalMs: 900);
    final own = rules.ownedBp[r.rarity.index];
    expect(p.withPassive(cat).stats.atk, 100 * (kBp + own) ~/ kBp);
    final partner = p.partners(cat).single;
    expect(partner.isPartner, isTrue);
    expect(partner.stats.atk, 100 * rules.deployedBp[r.rarity.index] ~/ kBp);
    expect(partner.stats[Attribute.petDmg], 5000);

    final b = balance;
    final idle = IdleRules.fromBalance(b);
    final combat = CombatRules.fromBalance(b);
    final loop = IdleLoop(
      rules: idle,
      income: IncomeModel(idle, expPerKill: (_) => 1),
      engineFactory: () => CombatEngine(combat),
      catSpec: () => cat,
      partners: p.partners,
      hpWeightPm: combat.powerWeights.hpPm,
      atkWeightPm: combat.powerWeights.atkPm,
    );
    final hits = <HitResolved>[];
    loop.combatEvents.listen((e) {
      if (e is HitResolved) hits.add(e);
    });
    for (var i = 0; i < 100; i++) {
      loop.tick(100);
    }
    expect(
        hits.any((h) =>
            h.channel == DamageChannel.partner &&
            h.attackerId == 'pet_${r.petId}'),
        isTrue);
  });

  test('hatching never pays out eggs or goldfish (no IAP path to them)',
      () async {
    final p = pets();
    wallet.add(RewardBundle({Currency.eggs: 500, Currency.goldfish: 1 << 20}));
    var eggs = wallet.balance(Currency.eggs),
        fish = wallet.balance(Currency.goldfish);
    for (var i = 0; i < 500; i++) {
      await p.hatch(i.isEven ? HatchSource.egg : HatchSource.fish);
      expect(wallet.balance(Currency.eggs), lessThanOrEqualTo(eggs));
      expect(wallet.balance(Currency.goldfish), lessThanOrEqualTo(fish));
      eggs = wallet.balance(Currency.eggs);
      fish = wallet.balance(Currency.goldfish);
    }
  });

  test('save round-trip; bad saves fail', () async {
    final p = pets();
    wallet.add(RewardBundle({Currency.eggs: 20, Currency.goldfish: 10000}));
    for (var i = 0; i < 20; i++) {
      await p.hatch(HatchSource.egg);
    }
    await p.hatch(HatchSource.fish);
    final json =
        jsonDecode(jsonEncode(p.snapshot().toJson())) as Map<String, dynamic>;
    final q = pets()
      ..restore(PetsState.fromJson(json),
          fishPulls: p.fishPullsToday, dateKey: clock.dateKey);
    expect(q.snapshot().toJson(), p.snapshot().toJson());
    expect(q.fishHatchesLeftToday, 4);
    expect(() => pets().restore(const PetsState(owned: {'dragon': 1})),
        throwsFormatException);
    expect(() => pets().restore(const PetsState(owned: {'frog': 9})),
        throwsFormatException);
    expect(() => pets().restore(const PetsState(deployed: ['frog'])),
        throwsFormatException);
  });
}
