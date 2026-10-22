import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
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

/// Every rule set from the repo's data, on a fake clock.
List<Override> world(Time time) {
  final b = _j('../../design/balance/idle_balance_v1.json');
  final combat = CombatRules.fromBalance(b);
  final w = combat.powerWeights;
  final ads = AdRules.fromJson(b);
  return [
    timeSourceProvider.overrideWithValue(time),
    combatRulesProvider.overrideWithValue(combat),
    catRulesProvider.overrideWithValue(CatRules.fromBalance(b)),
    idleRulesProvider.overrideWithValue(IdleRules.fromBalance(b)),
    gearRulesProvider.overrideWithValue(GearRules.fromJson(
        b, _j('../../design/data/gear_slots.json'),
        hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm)),
    wardrobeRulesProvider.overrideWithValue(
        WardrobeRules.fromJson(_j('../../design/data/wardrobe.json'))),
    roadEventRulesProvider.overrideWithValue(
        RoadEventRules.fromJson(b, _j('../../design/data/road_events.json'))),
    adRulesProvider.overrideWithValue(ads),
    offlineRulesProvider.overrideWithValue(OfflineRules.fromBalance(b)),
    petsRulesProvider.overrideWithValue(
        PetsRules.fromJson(b, _j('../../design/data/pets.json'))),
    researchRulesProvider.overrideWithValue(ResearchRules.fromJson(
        b,
        _j('../../design/data/research.json'),
        ads.placements['research_speedup']!.params)),
    iapCatalogProvider.overrideWithValue(
        IapCatalog.fromJson(_j('../../design/data/iap.json'))),
  ];
}
