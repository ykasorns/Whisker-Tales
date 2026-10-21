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

  test('catalog: 8 slots × 3 tiers; book shows silhouettes', () {
    final wd = Wardrobe(rules)..unlock('hat_2');
    expect(wd.collection, hasLength(24));
    expect(wd.collection.where((c) => c.unlocked).map((c) => c.styleId),
        ['hat_2']);
    expect(wd.unlock('hat_2'), isFalse);
    expect(() => wd.unlock('crown_9'), throwsArgumentError);
    expect(rules.weaponArt['mage'], 'staff');
  });

  test('save round-trip; old saves with chosen looks / skins still load', () {
    final wd = Wardrobe(rules)
      ..unlock('hat_1')
      ..unlock('scarf_2');
    final json =
        jsonDecode(jsonEncode(wd.snapshot().toJson())) as Map<String, dynamic>;
    expect(json, {
      'unlocked': ['hat_1', 'scarf_2']
    });
    // before D-024: chosen looks and skins — ignored, unknown looks dropped
    final old = WardrobeState.fromJson({
      'unlocked': ['hat_1', 'crown_9'],
      'chosen': {'hat': 'hat_1'},
      'skin': 'adventurer',
      'skins_unlocked': ['base', 'adventurer'],
    });
    expect((Wardrobe(rules)..restore(old)).unlocked, {'hat_1'});
    expect(() => WardrobeState.fromJson({'chosen': {}}), throwsFormatException);
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

    // the book only remembers: recycling, wearing, reloading never forget
    final again = Wardrobe(rules)..restore(wd.snapshot());
    expect(again.unlocked, wd.unlocked);
  });
}
