import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads.dart';
import '../avatar/avatar.dart';
import '../cat/cat.dart';
import '../combat/combat.dart';
import '../gear/gear.dart';
import '../idle/idle.dart';
import '../offline/offline_reward.dart';
import '../pets/pets.dart';
import '../wardrobe/wardrobe.dart';
import 'providers.dart';

/// Where content files come from: the app bundle on device, the repo in
/// tests. [path] is repo-relative, e.g. `design/data/skills.json`.
abstract class ContentSource {
  Future<String> read(String path);
}

/// Content data failed to load. [file] and the message name what is wrong.
class ContentError implements Exception {
  ContentError(this.file, this.message);
  final String file;
  final String message;

  @override
  String toString() => 'ContentError($file): $message';
}

/// Every rule set the game needs, parsed and checked (T-003).
class GameContent {
  const GameContent({
    required this.combat,
    required this.cat,
    required this.idle,
    required this.gear,
    required this.wardrobe,
    required this.roadEvents,
    required this.ads,
    required this.offline,
    required this.buffs,
    required this.skills,
    required this.avatar,
    required this.pets,
  });

  final CombatRules combat;
  final CatRules cat;
  final IdleRules idle;
  final GearRules gear;
  final WardrobeRules wardrobe;
  final RoadEventRules roadEvents;
  final AdRules ads;
  final OfflineRules offline;
  final BuffBook buffs;
  final SkillBook skills;

  /// Mochi anchors + gear grips (T-027) — used by the app's AvatarComponent.
  final AvatarRules avatar;

  /// Pets roster + hatch numbers (T-038).
  final PetsRules pets;

  /// Provider overrides for `ProviderScope` / `ProviderContainer`.
  List<Override> get overrides => [
        combatRulesProvider.overrideWithValue(combat),
        catRulesProvider.overrideWithValue(cat),
        idleRulesProvider.overrideWithValue(idle),
        gearRulesProvider.overrideWithValue(gear),
        wardrobeRulesProvider.overrideWithValue(wardrobe),
        roadEventRulesProvider.overrideWithValue(roadEvents),
        adRulesProvider.overrideWithValue(ads),
        offlineRulesProvider.overrideWithValue(offline),
        buffBookProvider.overrideWithValue(buffs),
        skillBookProvider.overrideWithValue(skills),
        petsRulesProvider.overrideWithValue(pets),
      ];
}

/// Loads all content at boot and fails fast with the file and field
/// (GAME_CONTRACT §4: data is the source of truth). Part of `core_loop`.
class ContentRepository {
  ContentRepository(this.source);

  final ContentSource source;

  static const balancePath = 'design/balance/idle_balance_v1.json';

  /// File → schema_version this build understands.
  static const files = {
    balancePath: 1,
    'design/data/buffs.json': 1,
    'design/data/skills.json': 1,
    'design/data/gear_slots.json': 1,
    'design/data/wardrobe.json': 1,
    'design/data/road_events.json': 1,
    'design/art/anchors_mochi.json': 1,
    'design/data/pets.json': 1,
  };

  Future<GameContent> loadAll() async {
    final json = <String, Map<String, dynamic>>{};
    for (final e in files.entries) {
      json[e.key] = await _read(e.key, e.value);
    }
    T parse<T>(String file, T Function() f) {
      try {
        return f();
      } on FormatException catch (e) {
        throw ContentError(file, e.message);
      } on ArgumentError catch (e) {
        throw ContentError(file, '${e.message}');
      } on TypeError catch (e) {
        throw ContentError(file, 'wrong type: $e');
      }
    }

    final b = json[balancePath]!;
    final combat = parse(balancePath, () => CombatRules.fromBalance(b));
    final cat = parse(balancePath, () => CatRules.fromBalance(b));
    final idle = parse(balancePath, () => IdleRules.fromBalance(b));
    final ads = parse(balancePath, () => AdRules.fromJson(b));
    final offline = parse(balancePath, () => OfflineRules.fromBalance(b));
    final w = combat.powerWeights;
    final gear = parse(
        'design/data/gear_slots.json',
        () => GearRules.fromJson(b, json['design/data/gear_slots.json']!,
            hpPm: w.hpPm, atkPm: w.atkPm, defPm: w.defPm));
    final buffs = parse('design/data/buffs.json',
        () => BuffBook.fromJson(json['design/data/buffs.json']!));
    final skills = parse('design/data/skills.json',
        () => SkillBook.fromJson(json['design/data/skills.json']!, buffs));
    final wardrobe = parse('design/data/wardrobe.json',
        () => WardrobeRules.fromJson(json['design/data/wardrobe.json']!));
    final avatar = parse('design/art/anchors_mochi.json',
        () => AvatarRules.fromJson(json['design/art/anchors_mochi.json']!));
    for (final art in {
      ...wardrobe.weaponArt.values,
      ...wardrobe.offHandArt.values,
      'hat',
      'scarf',
      'bag',
    }) {
      if (!avatar.gear.containsKey(art)) {
        throw ContentError(
            'design/art/anchors_mochi.json', 'gear has no "$art"');
      }
    }
    final pets = parse('design/data/pets.json',
        () => PetsRules.fromJson(b, json['design/data/pets.json']!));
    final road = parse(
        'design/data/road_events.json',
        () =>
            RoadEventRules.fromJson(b, json['design/data/road_events.json']!));

    // cross-references between files
    final classIds = {for (final c in cat.classes) c.id};
    for (final cls in skills.byClass.keys) {
      if (!classIds.contains(cls)) {
        throw ContentError(
            'design/data/skills.json', 'skills for unknown class "$cls"');
      }
    }
    for (final c in cat.classes.where((c) => c.tier > 0)) {
      if ((skills.byClass[c.id]?.length ?? 0) < cat.skillSlotLevels.length) {
        throw ContentError('design/data/skills.json',
            'class "${c.id}" needs ${cat.skillSlotLevels.length} skills');
      }
    }
    for (final id in classIds) {
      if (!wardrobe.weaponArt.containsKey(id)) {
        throw ContentError(
            'design/data/wardrobe.json', 'weapon_art has no "$id"');
      }
    }
    for (final p in [
      'road_event',
      'pet_hatch',
      'research_speedup',
      'yarn_bundle',
      'daily_gift'
    ]) {
      if (!ads.placements.containsKey(p)) {
        throw ContentError(balancePath, 'ads.placements has no "$p"');
      }
    }

    return GameContent(
      combat: combat,
      cat: cat,
      idle: idle,
      gear: gear,
      wardrobe: wardrobe,
      roadEvents: road,
      ads: ads,
      offline: offline,
      buffs: buffs,
      skills: skills,
      avatar: avatar,
      pets: pets,
    );
  }

  Future<Map<String, dynamic>> _read(String path, int version) async {
    final String raw;
    try {
      raw = await source.read(path);
    } catch (e) {
      throw ContentError(path, 'cannot read: $e');
    }
    final Object? doc;
    try {
      doc = jsonDecode(raw);
    } on FormatException catch (e) {
      throw ContentError(path, 'not valid JSON: ${e.message}');
    }
    if (doc is! Map<String, dynamic>) {
      throw ContentError(path, 'top level must be an object');
    }
    final v = doc['schema_version'];
    if (v != version) {
      throw ContentError(
          path, 'schema_version is $v, this build reads $version');
    }
    return doc;
  }
}
