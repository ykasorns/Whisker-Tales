import 'dart:math';

import '../core/contracts/game_mode.dart';
import '../core/contracts/run_systems.dart';

/// Story-map generator: 8–10 stages, a boss at the end, weighted encounter
/// kinds, and no path containing more than three consecutive combats.
class SeededEncounterGenerator implements IEncounterGenerator {
  const SeededEncounterGenerator({
    this.combatIds = const ['eraserslime'],
    this.eventIds = const ['whispering_chest'],
    this.bossId = 'paperwolf',
  });

  final List<String> combatIds;
  final List<String> eventIds;
  final String bossId;

  static const _weighted = <(EncounterType, int)>[
    (EncounterType.combat, 50),
    (EncounterType.treasure, 10),
    (EncounterType.event, 15),
    (EncounterType.campfire, 10),
    (EncounterType.shop, 10),
    (EncounterType.fork, 5),
  ];

  @override
  EncounterMap generate(int seed) {
    final rng = Random(seed);
    final length = 8 + rng.nextInt(3);
    final stages = <EncounterStage>[];
    var possibleCombatStreak = 0;
    var forkBefore = false;

    for (var depth = 0; depth < length - 1; depth++) {
      if (forkBefore) {
        final riskyCombat = possibleCombatStreak < 3;
        final safeType =
            rng.nextBool() ? EncounterType.campfire : EncounterType.treasure;
        final riskyType = riskyCombat
            ? EncounterType.combat
            : (rng.nextBool() ? EncounterType.event : EncounterType.shop);
        stages.add(EncounterStage(depth: depth, choices: [
          Encounter(
            type: safeType,
            depth: depth,
            routeId: 'd${depth}_safe',
            contentId: _contentId(safeType, rng),
          ),
          Encounter(
            type: riskyType,
            depth: depth,
            routeId: 'd${depth}_risky',
            contentId: _contentId(riskyType, rng),
          ),
        ]));
        possibleCombatStreak =
            riskyType == EncounterType.combat ? possibleCombatStreak + 1 : 0;
        forkBefore = false;
        continue;
      }

      var type = _pick(rng);
      if (type == EncounterType.combat && possibleCombatStreak >= 3) {
        type = _pickNonCombat(rng, allowFork: depth < length - 2);
      }
      if (type == EncounterType.fork && depth >= length - 2) {
        type = _pickNonCombat(rng, allowFork: false);
      }
      stages.add(EncounterStage(depth: depth, choices: [
        Encounter(
          type: type,
          depth: depth,
          routeId: 'd$depth',
          contentId: _contentId(type, rng),
        ),
      ]));
      forkBefore = type == EncounterType.fork;
      possibleCombatStreak =
          type == EncounterType.combat ? possibleCombatStreak + 1 : 0;
    }

    final bossDepth = length - 1;
    stages.add(EncounterStage(depth: bossDepth, choices: [
      Encounter(
        type: EncounterType.boss,
        depth: bossDepth,
        routeId: 'd${bossDepth}_boss',
        contentId: bossId,
      ),
    ]));
    return EncounterMap(seed: seed, stages: stages);
  }

  static EncounterType _pick(Random rng) {
    var roll = rng.nextInt(100);
    for (final (type, weight) in _weighted) {
      if (roll < weight) return type;
      roll -= weight;
    }
    return EncounterType.combat;
  }

  static EncounterType _pickNonCombat(Random rng, {required bool allowFork}) {
    final choices = <EncounterType>[
      EncounterType.treasure,
      EncounterType.event,
      EncounterType.campfire,
      EncounterType.shop,
      if (allowFork) EncounterType.fork,
    ];
    return choices[rng.nextInt(choices.length)];
  }

  String? _contentId(EncounterType type, Random rng) => switch (type) {
        EncounterType.combat => combatIds[rng.nextInt(combatIds.length)],
        EncounterType.event => eventIds[rng.nextInt(eventIds.length)],
        EncounterType.treasure => 'relic_chest',
        EncounterType.campfire => 'campfire',
        EncounterType.shop => 'owl_shop',
        EncounterType.fork => 'safe_or_risky',
        EncounterType.boss => bossId,
      };
}

/// Presents a generated map through the mode contract. Branches reconverge
/// after one stage, which keeps a route 8–10 nodes long whichever side wins.
class MapEncounterSource implements ChoiceEncounterSource {
  MapEncounterSource(this.map);

  final EncounterMap map;

  @override
  List<Encounter> choices(int depth) => map.choicesAt(depth);

  @override
  Encounter? choose(int depth, String? routeId, Random rng) {
    final available = choices(depth);
    if (available.isEmpty) return null;
    if (routeId == null) {
      if (available.length > 1) {
        throw StateError('depth $depth requires a route choice');
      }
      return available.single;
    }
    for (final encounter in available) {
      if (encounter.routeId == routeId) return encounter;
    }
    throw ArgumentError.value(routeId, 'routeId', 'not available');
  }

  @override
  Encounter? next(int depth, Random rng) => choose(depth, null, rng);

  @override
  List<EncounterPreview> preview(int depth, int count) {
    final out = <EncounterPreview>[];
    for (var d = depth; d < map.length && out.length < count; d++) {
      final options = map.choicesAt(d);
      if (options.isEmpty) break;
      for (final e in options) {
        out.add(EncounterPreview(type: e.type, depth: d));
        if (out.length == count) break;
      }
    }
    return List.unmodifiable(out);
  }
}
