import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _json(String path) =>
    jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  final balance = _json('../../design/balance/idle_balance_v1.json');
  final rules =
      WardrobeRules.fromJson(_json('../../design/data/wardrobe.json'));
  final combat = CombatRules.fromBalance(balance);
  final w = combat.powerWeights;
  final gearRules = GearRules.fromJson(
      balance, _json('../../design/data/gear_slots.json'),
      hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm);

  GearItem item(GearSlot slot, int grade) => GearItem(
      id: '${slot.name}$grade',
      slot: slot,
      grade: grade,
      page: 1,
      stats: StatBlock(hp: 1, atk: 1, def: 1));

  var cleared = 0;
  final worn = <GearSlot, GearItem>{};
  Wardrobe fresh() =>
      Wardrobe(rules, equipped: (s) => worn[s], clearedPage: () => cleared);
  setUp(() {
    cleared = 0;
    worn.clear();
  });

  test('catalog: 8 slots × 3 tiers; book shows silhouettes', () {
    final wd = fresh()..unlock('hat_2');
    expect(wd.collection, hasLength(24));
    expect(wd.collection.where((c) => c.unlocked).map((c) => c.styleId),
        ['hat_2']);
    expect(wd.unlock('hat_2'), isFalse);
    expect(() => wd.unlock('crown_9'), throwsArgumentError);
  });

  test('looks follow the worn item; weapons follow the class', () {
    final wd = fresh();
    expect(wd.lookFor(GearSlot.hat, 'novice'), isNull);
    worn[GearSlot.weapon] = item(GearSlot.weapon, 3); // purple → tier 2
    worn[GearSlot.hat] = item(GearSlot.hat, 5);
    worn[GearSlot.shirt] = item(GearSlot.shirt, 0);
    expect(wd.lookFor(GearSlot.weapon, 'rogue'), 'dagger_2');
    expect(wd.lookFor(GearSlot.weapon, 'mage'), 'staff_2'); // class change
    expect(wd.lookFor(GearSlot.weapon, 'novice'), 'sword_2');
    expect(wd.lookFor(GearSlot.hat, 'warrior'), 'hat_3');
    expect(wd.lookFor(GearSlot.shirt, 'warrior'), 'icon_shirt_1');
    expect(wd.offHandFor('warrior'), 'shield_2');
    expect(wd.offHandFor('rogue'), 'dagger_2');
    expect(wd.offHandFor('archer'), isNull);
  });

  test('choose an unlocked look, hide it, or go back to the item', () {
    final wd = fresh()..unlock('hat_1');
    worn[GearSlot.hat] = item(GearSlot.hat, 5);
    wd.choose(GearSlot.hat, 'hat_1');
    expect(wd.lookFor(GearSlot.hat, 'novice'), 'hat_1');
    wd.choose(GearSlot.hat, WardrobeState.hidden);
    expect(wd.lookFor(GearSlot.hat, 'novice'), isNull);
    wd.choose(GearSlot.hat, null);
    expect(wd.lookFor(GearSlot.hat, 'novice'), 'hat_3');
    expect(() => wd.choose(GearSlot.hat, 'hat_2'), throwsStateError);
    expect(() => wd.choose(GearSlot.bag, 'hat_1'), throwsArgumentError);
  });

  test('skins: progress unlocks, locked skins refuse', () {
    final wd = fresh();
    expect(wd.skin, 'base');
    expect(() => wd.chooseSkin('adventurer'), throwsStateError);
    cleared = 10;
    wd.chooseSkin('adventurer');
    expect(wd.skin, 'adventurer');
  });

  test('cosmetic purchases unlock looks only', () {
    final data = _json('../../design/data/wardrobe.json')
      ..['iap'] = {
        'cosmetic.rainbow_hat': ['hat_3'],
        'cosmetic.adventurer': ['adventurer'],
      };
    final wd = Wardrobe(WardrobeRules.fromJson(data),
        equipped: (_) => null, clearedPage: () => 0)
      ..grantPurchase('cosmetic.rainbow_hat')
      ..grantPurchase('cosmetic.adventurer');
    expect(wd.unlocked, {'hat_3'});
    expect(wd.skinsUnlocked, containsAll(['base', 'adventurer']));
    expect(() => wd.grantPurchase('no_ads'), throwsArgumentError);
  });

  test('save round-trip and validation', () {
    final wd = fresh()
      ..unlock('hat_1')
      ..unlock('scarf_2')
      ..choose(GearSlot.hat, 'hat_1')
      ..choose(GearSlot.bag, WardrobeState.hidden);
    final json =
        jsonDecode(jsonEncode(wd.snapshot().toJson())) as Map<String, dynamic>;
    expect(json['chosen'], {'hat': 'hat_1', 'bag': 'none'});
    final back = fresh()..restore(WardrobeState.fromJson(json));
    expect(back.snapshot().toJson(), wd.snapshot().toJson());
    final v3 = WardrobeState.fromJson({
      'unlocked': ['style_id'],
      'chosen': {'hat': 'style_id'},
      'skin': 'base',
      'skins_unlocked': ['base'],
    });
    expect(() => fresh().restore(v3), throwsFormatException);
    expect(
        () => WardrobeState.fromJson({'unlocked': []}), throwsFormatException);
    expect(() => fresh().restore(const WardrobeState(skin: 'adventurer')),
        throwsFormatException);
  });

  test('knitting unlocks looks; recycling keeps them; looks never change stats',
      () {
    final c = ProviderContainer(overrides: [
      combatRulesProvider.overrideWithValue(combat),
      catRulesProvider.overrideWithValue(CatRules.fromBalance(balance)),
      roadEventRulesProvider.overrideWithValue(RoadEventRules.fromJson(
          jsonDecode(File('../../design/balance/idle_balance_v1.json')
              .readAsStringSync()) as Map<String, dynamic>,
          jsonDecode(
                  File('../../design/data/road_events.json').readAsStringSync())
              as Map<String, dynamic>)),
      idleRulesProvider.overrideWithValue(IdleRules.fromBalance(balance)),
      gearRulesProvider.overrideWithValue(gearRules),
      wardrobeRulesProvider.overrideWithValue(rules),
      walletProvider.overrideWithValue(MemoryWallet({Currency.yarn: 20})),
    ]);
    addTearDown(c.dispose);
    final basket = c.read(gearBasketProvider);
    final wd = c.read(wardrobeProvider);
    final first = basket.craft(GearSlot.hat);
    expect(first.isNewStyle, isTrue);
    expect(wd.unlocked, {first.item.styleId});
    basket.recycle(first.itemId);
    expect(wd.unlocked, contains(first.item.styleId));

    final r = basket.craft(GearSlot.weapon);
    basket.equip(r.itemId);
    final before = c.read(catExtraStatsProvider)();
    final spec = c.read(catClassProvider).combatSpec(extra: before);
    wd.choose(GearSlot.hat, first.item.styleId);
    wd.choose(GearSlot.weapon, WardrobeState.hidden);
    expect(c.read(catExtraStatsProvider)(), before);
    expect(
        c
            .read(catClassProvider)
            .combatSpec(extra: c.read(catExtraStatsProvider)())
            .stats,
        spec.stats);
  });
}
