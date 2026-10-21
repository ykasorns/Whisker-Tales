import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class Time implements TimeSource {
  Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final b = _j('../../design/balance/idle_balance_v1.json');
  final combat = CombatRules.fromBalance(b);
  final w = combat.powerWeights;
  final t0 = DateTime.utc(2026, 10, 19, 2);

  ProviderContainer game(Time time, SaveStore store) =>
      ProviderContainer(overrides: [
        timeSourceProvider.overrideWithValue(time),
        combatRulesProvider.overrideWithValue(combat),
        catRulesProvider.overrideWithValue(CatRules.fromBalance(b)),
        idleRulesProvider.overrideWithValue(IdleRules.fromBalance(b)),
        gearRulesProvider.overrideWithValue(GearRules.fromJson(
            b, _j('../../design/data/gear_slots.json'),
            hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm)),
        wardrobeRulesProvider.overrideWithValue(
            WardrobeRules.fromJson(_j('../../design/data/wardrobe.json'))),
        roadEventRulesProvider.overrideWithValue(RoadEventRules.fromJson(
            b, _j('../../design/data/road_events.json'))),
        adRulesProvider.overrideWithValue(AdRules.fromJson(b)),
        offlineRulesProvider.overrideWithValue(OfflineRules.fromBalance(b)),
        petsRulesProvider.overrideWithValue(
            PetsRules.fromJson(b, _j('../../design/data/pets.json'))),
        researchRulesProvider.overrideWithValue(ResearchRules.fromJson(
            b,
            _j('../../design/data/research.json'),
            AdRules.fromJson(b).placements['research_speedup']!.params)),
        saveServiceProvider.overrideWithValue(SaveService(store)),
      ]);

  test('play, save, reopen: everything comes back', () async {
    final time = Time(t0);
    final store = MemorySaveStore();
    final a = game(time, store);
    addTearDown(a.dispose);
    // play a bit
    final loop = a.read(idleLoopProvider)..restore(clearedPage: 3);
    final wallet = a.read(walletProvider) as MemoryWallet;
    wallet.add(RewardBundle(
        {Currency.yarn: 30, Currency.goldfish: 900, Currency.eggs: 2}));
    final basket = a.read(gearBasketProvider);
    for (var i = 0; i < 12; i++) {
      final r = basket.craft(null);
      i.isEven ? basket.equip(r.itemId) : basket.recycle(r.itemId);
    }
    basket.upgradeSlot(GearSlot.weapon);
    a.read(catProgressProvider).gainExp(500);
    a.read(catClassProvider).choose('mage');
    final look = a.read(wardrobeProvider).unlocked.first;
    a.read(wardrobeProvider).choose(
        GearSlot.values.firstWhere((s) => look.startsWith('${s.name}_')), look);
    a
        .read(autoCraftProvider)
        .configure(const AutoCraftRule(on: true, mode: AutoCraftMode.equip));
    await a.read(adServiceProvider).show('pet_hatch');
    final pets = a.read(petsProvider)!;
    wallet.add(RewardBundle({Currency.eggs: 5, Currency.goldfish: 1000}));
    for (var i = 0; i < 5; i++) {
      await pets.hatch(HatchSource.egg);
    }
    await pets.hatch(HatchSource.fish);
    final research = a.read(researchProvider)!..notifyDone = false;
    expect(research.start('sharp_claws'), isTrue);
    time.utc = time.utc.add(const Duration(minutes: 2));
    research.tick();
    expect(research.start('offline_cap'), isTrue);
    for (var i = 0; i < 300; i++) {
      loop.tick(100);
    }
    final before = a.read(gameSaverProvider).capture();
    await a.read(gameSaverProvider).save();

    final c = game(time, store);
    addTearDown(c.dispose);
    final r = await c.read(gameSaverProvider).load();
    expect(r.document, isNotNull);
    final after = c.read(gameSaverProvider).capture();
    for (final k in [
      'pets',
      'research',
      'settings',
      'profile',
      'idle',
      'gear',
      'cat',
      'wardrobe',
      'daily',
      'clock',
      'entitlements'
    ]) {
      expect(jsonEncode(after[k]), jsonEncode(before[k]), reason: k);
    }
    expect(c.read(catClassProvider).current, 'mage');
    expect(c.read(adServiceProvider).remainingToday('pet_hatch'), 2);
    expect(c.read(autoCraftProvider).running, isTrue);
    expect(c.read(petsProvider)!.fishHatchesLeftToday, 4);
    expect(c.read(petsProvider)!.owned, pets.owned);
    final r2 = c.read(researchProvider)!;
    expect(r2.levels, {'sharp_claws': 1});
    expect(r2.tasks.single.nodeId, 'offline_cap');
    expect(r2.notifyDone, isFalse);
  });

  test('the offline window survives save/load', () async {
    final time = Time(t0);
    final store = MemorySaveStore();
    final a = game(time, store);
    addTearDown(a.dispose);
    await a.read(gameSaverProvider).save(); // last_seen = t0
    time.utc = t0.add(const Duration(hours: 2));
    final c = game(time, store);
    addTearDown(c.dispose);
    await c.read(gameSaverProvider).load();
    expect(c.read(offlineRewardProvider).checkIn().creditedMinutes, 120);
  });

  test('a new day since the save resets the ad caps', () async {
    final time = Time(t0);
    final store = MemorySaveStore();
    final a = game(time, store);
    addTearDown(a.dispose);
    for (var i = 0; i < 3; i++) {
      await a.read(adServiceProvider).show('pet_hatch');
    }
    await a.read(gameSaverProvider).save();
    time.utc = t0.add(const Duration(days: 1));
    final c = game(time, store);
    addTearDown(c.dispose);
    await c.read(gameSaverProvider).load();
    expect(c.read(adServiceProvider).remainingToday('pet_hatch'), 3);
  });

  test('sections no module owns yet are kept as they were', () async {
    final time = Time(t0);
    final store = MemorySaveStore();
    final a = game(time, store);
    addTearDown(a.dispose);
    final doc = a.read(gameSaverProvider).capture()
      ..['modes'] = {
        'story': {'best': 7}
      }
      ..['age'] = {'band': 'under13'};
    a.read(gameSaverProvider).restore(doc);
    final again = a.read(gameSaverProvider).capture();
    expect(again['modes'], doc['modes']);
    expect(again['age'], {'band': 'under13'});
  });

  test('a broken section names itself', () {
    final time = Time(t0);
    final a = game(time, MemorySaveStore());
    addTearDown(a.dispose);
    final doc = a.read(gameSaverProvider).capture()..remove('cat');
    expect(
        () => a.read(gameSaverProvider).restore(doc),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('cat'))));
  });
}
