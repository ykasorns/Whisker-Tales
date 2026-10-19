import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
Map<String, dynamic> balance() =>
    _json('../../design/balance/idle_balance_v1.json');
Map<String, dynamic> slotsJson() => _json('../../design/data/gear_slots.json');

void main() {
  final combat = CombatRules.fromBalance(balance());
  final w = combat.powerWeights;
  final power = PowerScore(w);
  GearRules rulesFrom(Map<String, dynamic> b) =>
      GearRules.fromJson(b, slotsJson(),
          hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm);
  final rules = rulesFrom(balance());

  var cleared = 0;
  GearBasket basket(MemoryWallet wallet, {int seed = 1, GearRules? r}) =>
      GearBasket(
          rules: r ?? rules,
          wallet: wallet,
          clearedPage: () => cleared,
          powerOf: power.of,
          seed: seed);
  setUp(() => cleared = 0);

  group('data', () {
    test('slots, unlocks and tables load', () {
      expect(rules.slots.length, 8);
      expect(rules.slots[GearSlot.weapon]!.unlockPage, 0);
      expect(rules.slots[GearSlot.bag]!.unlockPage, 30);
      expect(rules.gradeMultBp, [10000, 14000, 20000, 28000, 40000, 56000]);
      expect(rules.rowFor(7).pct, [40, 35, 20, 5, 0, 0]);
      expect(rules.itemPower(1, 0), 12);
      expect(rules.upgradeCost(0), 40);
    });

    test('bad data names the field', () {
      final s = slotsJson();
      (s['slots'] as Map)['hat']['power_split']['hp'] = 10;
      expect(
          () => GearRules.fromJson(balance(), s,
              hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm),
          throwsA(isA<FormatException>()
              .having((e) => e.message, 'message', contains('hat'))));
    });
  });

  group('craft', () {
    test('grade rates match the table (chi-square, 100k crafts)', () {
      final b = balance();
      (b['gear'] as Map)['pity_every'] = 1 << 30; // isolate the table
      const n = 100000;
      final k = basket(MemoryWallet({Currency.yarn: n}), r: rulesFrom(b));
      final counts = List.filled(6, 0);
      for (var i = 0; i < n; i++) {
        final r = k.craft(GearSlot.hat);
        counts[r.grade]++;
        k.recycle(r.itemId);
        if (k.basketLevel > 1) break;
      }
      // Basket levels up after 20 recycles; measure on a fresh level-1 table.
      final k2 = basket(MemoryWallet({Currency.yarn: n}), r: rulesFrom(b));
      final c = List.filled(6, 0);
      for (var i = 0; i < n; i++) {
        c[k2.craft(GearSlot.hat).grade]++;
      }
      final expected = [70, 25, 5].map((p) => p * n / 100).toList();
      var chi = 0.0;
      for (var g = 0; g < 3; g++) {
        chi += (c[g] - expected[g]) * (c[g] - expected[g]) / expected[g];
      }
      expect(c.sublist(3), [0, 0, 0]);
      expect(chi, lessThan(13.82), reason: '$c'); // df 2, p = 0.001
      expect(k2.gradeTable, [70, 25, 5, 0, 0, 0]);
    });

    test('pity: every 30th craft without purple is purple, then resets', () {
      final k = basket(MemoryWallet({Currency.yarn: 90}));
      for (var round = 0; round < 3; round++) {
        for (var i = 1; i < rules.pityEvery; i++) {
          expect(k.craft(GearSlot.hat).grade, lessThan(rules.pityMinGrade));
        }
        expect(k.pityLeft, 1);
        expect(k.craft(GearSlot.hat).grade, rules.pityMinGrade);
        expect(k.pity, 0);
      }
    });

    test('random slot only picks open slots; locked slots and no yarn throw',
        () {
      final wallet = MemoryWallet({Currency.yarn: 201});
      final k = basket(wallet);
      final seen = {for (var i = 0; i < 200; i++) k.craft(null).slot};
      expect(seen,
          {GearSlot.weapon, GearSlot.hat, GearSlot.shirt, GearSlot.shoes});
      expect(() => k.craft(GearSlot.scarf), throwsStateError);
      cleared = 5;
      expect(k.craft(null).slot, isNotNull);
      expect(k.openSlots, contains(GearSlot.scarf));
      final empty = basket(MemoryWallet());
      expect(() => empty.craft(GearSlot.hat), throwsStateError);
    });

    test('items: slot shapes stats, grade raises power, affixes by grade', () {
      final k = basket(MemoryWallet({Currency.yarn: 3000}));
      final special = {Attribute.bossDmg, Attribute.skillDmg};
      for (var i = 0; i < 3000; i++) {
        final it = k.craft(GearSlot.weapon).item;
        expect(it.stats.atk * w.atkPm, greaterThan(it.stats.hp * w.hpPm));
        expect(it.stats.attrs.length, rules.affixCountByGrade[it.grade]);
        if (it.grade < rules.specialMinGrade) {
          expect(it.stats.attrs.keys.toSet().intersection(special), isEmpty);
        }
        expect(it.styleId, 'weapon_${it.tier}');
      }
      expect(rules.itemPower(10, 5), greaterThan(rules.itemPower(10, 0) * 5));
    });

    test('first knit of a look is new; the same look again is not', () {
      final k = basket(MemoryWallet({Currency.yarn: 10}));
      expect(k.craft(GearSlot.hat).isNewStyle, isTrue);
      final again = k.craft(GearSlot.hat);
      expect(again.isNewStyle, again.item.tier != 1);
    });
  });

  group('compare, wear, recycle, slots', () {
    GearItem item(int hp, int atk, int def) => GearItem(
        id: 'x',
        slot: GearSlot.hat,
        grade: 0,
        page: 1,
        stats: StatBlock(hp: hp, atk: atk, def: def));

    test('strictly better = every base stat ≥ and not all equal', () {
      expect(item(5, 5, 5).isStrictlyBetterThan(item(5, 5, 4)), isTrue);
      expect(item(5, 5, 5).isStrictlyBetterThan(item(5, 5, 5)), isFalse);
      expect(item(9, 9, 1).isStrictlyBetterThan(item(5, 5, 2)), isFalse);
      expect(item(1, 1, 1).isStrictlyBetterThan(null), isTrue);
    });

    test('equip swaps and recycles the old item; slot level stays', () {
      final wallet = MemoryWallet({Currency.yarn: 10, Currency.goldfish: 1000});
      final k = basket(wallet);
      final a = k.craft(GearSlot.weapon).item;
      k.equip(a.id);
      k.upgradeSlot(GearSlot.weapon);
      expect(wallet.balance(Currency.goldfish), 1000 - 40);
      final b = k.craft(GearSlot.weapon).item;
      k.equip(b.id);
      expect(k.equipped(GearSlot.weapon)!.id, b.id);
      expect(k.slotLevel(GearSlot.weapon), 1);
      expect(wallet.balance(Currency.goldfish), 960 + rules.recycleFish(1));
      expect(k.basketExp, 1);
      expect(
          k.totalStats.atk, b.stats.atk * (kBp + rules.slotUpgradeBp) ~/ kBp);
      expect(() => k.equip(a.id), throwsStateError); // already recycled
    });

    test('random-slot knits give +50% basket EXP when recycled', () {
      final k = basket(MemoryWallet({Currency.yarn: 4}));
      for (var i = 0; i < 4; i++) {
        k.recycle(k.craft(null).itemId);
      }
      expect(k.basketExp, 6);
    });

    test('basket levels up and the table improves', () {
      final k = basket(MemoryWallet({Currency.yarn: 100}));
      for (var i = 0; i < 80; i++) {
        k.recycle(k.craft(GearSlot.shoes).itemId);
      }
      expect(k.basketLevel, 5);
      expect(k.gradeTable, [40, 35, 20, 5, 0, 0]);
    });

    test('upgrading needs goldfish and an open slot', () {
      final k = basket(MemoryWallet({Currency.goldfish: 39}));
      expect(() => k.upgradeSlot(GearSlot.hat), throwsStateError);
      expect(() => k.upgradeSlot(GearSlot.bag), throwsStateError);
    });

    test('yarn is never paid out by the basket (no IAP / reward path)', () {
      final wallet =
          MemoryWallet({Currency.yarn: 500, Currency.goldfish: 1 << 20});
      final k = basket(wallet);
      var last = wallet.balance(Currency.yarn);
      for (var i = 0; i < 500; i++) {
        final r = k.craft(null);
        i.isEven ? k.equip(r.itemId) : k.recycle(r.itemId);
        if (i % 50 == 0) k.upgradeSlot(GearSlot.hat);
        expect(wallet.balance(Currency.yarn), last - 1);
        last = wallet.balance(Currency.yarn);
      }
    });
  });

  test('save round-trip continues the same sequence', () {
    final k = basket(MemoryWallet({Currency.yarn: 50, Currency.goldfish: 500}));
    for (var i = 0; i < 20; i++) {
      final r = k.craft(null);
      i % 3 == 0 ? k.equip(r.itemId) : k.recycle(r.itemId);
    }
    k.stash(k.craft(GearSlot.shoes).itemId);
    k.upgradeSlot(GearSlot.weapon);
    final saved = jsonDecode(jsonEncode(k.toJson())) as Map<String, dynamic>;
    final k2 = basket(MemoryWallet({Currency.yarn: 50}), seed: 999)
      ..restore(saved);
    expect(k2.toJson(), k.toJson());
    expect(k2.craft(GearSlot.hat).item.toJson(),
        k.craft(GearSlot.hat).item.toJson());
    expect(() => k2.restore({'slots': []}), throwsFormatException);
  });

  group('auto-craft (GDD v0.5 §4.3)', () {
    test('fills the weakest slots, stops when the yarn runs out', () {
      final wallet = MemoryWallet({Currency.yarn: 40});
      final k = basket(wallet);
      final auto = AutoCraft(k, wallet)
        ..configure(const AutoCraftRule(mode: AutoCraftMode.equip))
        ..start();
      final stops = <AutoCraftStopReason>[];
      auto.stopped.listen(stops.add);
      final first = [for (var i = 0; i < 4; i++) auto.craftOnce()!.slot];
      expect(first.toSet(), k.openSlots.toSet());
      auto.tick(1 << 20);
      expect(wallet.balance(Currency.yarn), 0);
      expect(stops, [AutoCraftStopReason.outOfYarn]);
      expect(auto.running, isFalse);
      for (final s in k.openSlots) {
        expect(k.equipped(s), isNotNull);
        expect(k.stashed(s), isNull);
      }
    });

    test('never recycles an item ✨ better than what it would replace', () {
      for (final mode in AutoCraftMode.values) {
        final wallet = MemoryWallet({Currency.yarn: 600});
        final k = basket(wallet, seed: mode.index + 5);
        final auto = AutoCraft(k, wallet)
          ..configure(AutoCraftRule(mode: mode))
          ..start();
        while (wallet.balance(Currency.yarn) > 0) {
          final before = {
            for (final s in k.openSlots) s: k.stashed(s) ?? k.equipped(s)
          };
          final r = auto.craftOnce()!;
          if (r.item.isStrictlyBetterThan(before[r.slot])) {
            final kept = k.equipped(r.slot)?.id == r.itemId ||
                k.stashed(r.slot)?.id == r.itemId;
            expect(kept, isTrue, reason: '${mode.name} ${r.itemId}');
          }
        }
      }
    });

    test('stash mode keeps one best item per slot for the player', () {
      final wallet = MemoryWallet({Currency.yarn: 30});
      final k = basket(wallet);
      AutoCraft(k, wallet)
        ..start()
        ..tick(1 << 20);
      final stashed = k.openSlots.where((s) => k.stashed(s) != null);
      expect(stashed, isNotEmpty);
      for (final s in k.openSlots) {
        expect(k.equipped(s), isNull); // the player decides
      }
    });

    test('only crafts while ticked (online), one per interval', () {
      final wallet = MemoryWallet({Currency.yarn: 100});
      final auto = AutoCraft(basket(wallet), wallet)..start();
      auto.tick(rules.autoCraftIntervalMs * 10);
      expect(wallet.balance(Currency.yarn), 90);
      auto.stop();
      auto.tick(1 << 20);
      expect(wallet.balance(Currency.yarn), 90);
    });

    test('rule saves and loads', () {
      const r = AutoCraftRule(on: true, mode: AutoCraftMode.equip);
      expect(AutoCraftRule.fromJson(r.toJson()), r);
      expect(r.toJson(), {'on': true, 'better': 'equip'});
      expect(() => AutoCraftRule.fromJson({'on': true}), throwsFormatException);
    });
  });

  test('whole loop: farm → knit → early pages go fast (D-011)', () {
    final b = balance();
    final c = ProviderContainer(overrides: [
      combatRulesProvider.overrideWithValue(combat),
      catRulesProvider.overrideWithValue(CatRules.fromBalance(b)),
      idleRulesProvider.overrideWithValue(IdleRules.fromBalance(b)),
      gearRulesProvider.overrideWithValue(rules),
    ]);
    addTearDown(c.dispose);
    final loop = c.read(idleLoopProvider)..autoBoss = true;
    final auto = c.read(autoCraftProvider)
      ..configure(const AutoCraftRule(mode: AutoCraftMode.equip));
    for (var t = 0; t < 30 * 60000; t += 100) {
      loop.tick(100);
      if (!auto.running && c.read(walletProvider).balance(Currency.yarn) > 0) {
        auto.start();
      }
      auto.tick(100);
    }
    expect(loop.state.clearedPage, greaterThanOrEqualTo(4));
  });
}
