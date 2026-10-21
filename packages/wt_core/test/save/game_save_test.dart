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

  List<Override> world(Time time) => [
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
      ];

  ProviderContainer game(Time time, SaveStore store) =>
      ProviderContainer(overrides: [
        ...world(time),
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

  test('a "welcome back" still open is paid before a save moves last_seen',
      () async {
    final time = Time(t0);
    final a = game(time, MemorySaveStore());
    addTearDown(a.dispose);
    await a.read(gameSaverProvider).save(); // last_seen = t0
    time.utc = t0.add(const Duration(hours: 3));
    final offline = a.read(offlineRewardProvider);
    final shown = offline.checkIn(); // the sheet is up, not claimed yet
    final fish = a.read(walletProvider).balance(Currency.goldfish);
    expect(shown.reward[Currency.goldfish], greaterThan(0));
    // the player leaves (pause → save) and comes back a minute later
    await a.read(gameSaverProvider).save();
    expect(offline.pending, isNull);
    expect(a.read(walletProvider).balance(Currency.goldfish),
        fish + shown.reward[Currency.goldfish]);
    time.utc = time.utc.add(const Duration(minutes: 1));
    expect(offline.checkIn().creditedMinutes, 1);
    // the old sheet's button now only pays the new minute: nothing twice
    final paid = offline.claim();
    expect(paid[Currency.goldfish], lessThan(shown.reward[Currency.goldfish]));
  });

  group('boot never stops on a save it cannot load', () {
    /// Writes [doc] as the newest save, beside what is stored.
    Future<void> write(SaveStore store, Map<String, dynamic> doc,
        {int version = 3}) async {
      final s = SaveService(store, currentVersion: version);
      final read = await s.readSlots();
      s.resumeAfter(read, read.slots.isEmpty ? null : read.slots.first);
      await s.save(doc);
    }

    Future<GameBoot> boot(Time time, SaveStore store) async {
      final saves = SaveService(store);
      final b = await bootGame(() => ProviderContainer(overrides: [
            ...world(time),
            saveServiceProvider.overrideWithValue(saves),
          ]));
      addTearDown(b.container.dispose);
      return b;
    }

    Map<String, dynamic> played(Time time, int fish) {
      final c = game(time, MemorySaveStore());
      addTearDown(c.dispose);
      (c.read(walletProvider) as MemoryWallet)
          .add(RewardBundle({Currency.goldfish: fish}));
      return c.read(gameSaverProvider).capture();
    }

    test('a new game gets its own dice; the same seed, the same rolls',
        () async {
      final time = Time(t0);
      Future<ProviderContainer> fresh(int seed) async {
        final saves = SaveService(MemorySaveStore());
        final b = await bootGame(
            () => ProviderContainer(overrides: [
                  ...world(time),
                  saveServiceProvider.overrideWithValue(saves),
                ]),
            newWorldSeed: () => seed);
        addTearDown(b.container.dispose);
        return b.container;
      }

      Future<List<String>> rolls(ProviderContainer c) async {
        (c.read(walletProvider) as MemoryWallet)
            .add(RewardBundle({Currency.yarn: 12, Currency.eggs: 12}));
        final basket = c.read(gearBasketProvider);
        final pets = c.read(petsProvider)!;
        return [
          for (var i = 0; i < 12; i++)
            jsonEncode(basket.craft(GearSlot.weapon).item.toJson()),
          for (var i = 0; i < 12; i++)
            (await pets.hatch(HatchSource.egg))!.petId,
        ];
      }

      final a = await rolls(await fresh(1));
      expect(await rolls(await fresh(2)), isNot(a));
      expect(await rolls(await fresh(1)), a);
    });

    test('a save that loads is used as is', () async {
      final time = Time(t0);
      final store = MemorySaveStore();
      await write(store, played(time, 50));
      final b = await boot(time, store);
      expect(b.fallback, isNull);
      expect(b.container.read(walletProvider).balance(Currency.goldfish), 50);
      expect(store.data.keys.where((k) => k.startsWith('broken')), isEmpty);
    });

    test('newest does not fit the data → the older slot, broken kept aside',
        () async {
      final time = Time(t0);
      final store = MemorySaveStore();
      await write(store, played(time, 50));
      final bad = played(time, 80)
        ..['pets'] = {
          'owned': {
            'dragon': {'stars': 1, 'level': 1}
          },
          'deployed': [],
          'pity': 0
        };
      await write(store, bad);
      final rawBad = store.data['save_b'];
      final b = await boot(time, store);
      expect(b.fallback, BootFallback.olderSave);
      expect(b.error, isA<FormatException>());
      expect(b.container.read(walletProvider).balance(Currency.goldfish), 50);
      expect(store.data['broken_save_b'], rawBad);
      // the next save replaces the broken slot, not the one the game runs on
      await b.container.read(gameSaverProvider).save();
      expect(store.data['save_b'], isNot(rawBad));
      final again = await boot(time, store);
      expect(again.fallback, isNull);
      expect(store.data['broken_save_b'], rawBad); // the copy stays
    });

    test('nothing fits (a newer app wrote it) → new game, save kept aside',
        () async {
      final time = Time(t0);
      final store = MemorySaveStore();
      await write(store, played(time, 50)..['save_version'] = 4, version: 4);
      final raw = store.data['save_a'];
      final b = await boot(time, store);
      expect(b.fallback, BootFallback.newGame);
      expect(b.container.read(walletProvider).balance(Currency.goldfish), 0);
      expect(store.data['broken_save_a'], raw);
      // new progress is saved as the newest and loads next time
      (b.container.read(walletProvider) as MemoryWallet)
          .add(RewardBundle({Currency.goldfish: 7}));
      await b.container.read(gameSaverProvider).save();
      final again = await boot(time, store);
      expect(again.fallback, isNull);
      expect(
          again.container.read(walletProvider).balance(Currency.goldfish), 7);
    });
  });

  test('hatching continues the same dice after a reload', () async {
    final time = Time(t0);
    final store = MemorySaveStore();
    final a = game(time, store);
    addTearDown(a.dispose);
    final pets = a.read(petsProvider)!;
    (a.read(walletProvider) as MemoryWallet)
        .add(RewardBundle({Currency.eggs: 10}));
    for (var i = 0; i < 3; i++) {
      await pets.hatch(HatchSource.egg);
    }
    await a.read(gameSaverProvider).save();
    final next = [
      for (var i = 0; i < 6; i++) (await pets.hatch(HatchSource.egg))!.petId
    ];
    final c = game(time, store);
    addTearDown(c.dispose);
    await c.read(gameSaverProvider).load();
    final again = [
      for (var i = 0; i < 6; i++)
        (await c.read(petsProvider)!.hatch(HatchSource.egg))!.petId
    ];
    expect(again, next);
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
