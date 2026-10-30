import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  const generator = SeededEncounterGenerator();

  String signature(EncounterMap map) => map.stages
      .map((s) => s.choices
          .map((e) => '${e.type.name}:${e.routeId}:${e.contentId}')
          .join('|'))
      .join(',');

  test('same seed gives the same 8–10 stage map ending in a boss', () {
    for (var seed = 0; seed < 100; seed++) {
      final a = generator.generate(seed);
      final b = generator.generate(seed);
      expect(signature(a), signature(b), reason: 'seed $seed');
      expect(a.length, inInclusiveRange(8, 10), reason: 'seed $seed');
      expect(a.stages.last.choices.single.type, EncounterType.boss);
      expect(a.stages.last.choices.single.contentId, 'paperwolf');
      for (var depth = 0; depth < a.length; depth++) {
        expect(a.stages[depth].depth, depth);
      }
    }
  });

  test('every possible route has at most three combats in a row', () {
    for (var seed = 0; seed < 1000; seed++) {
      final map = generator.generate(seed);
      var streaks = <int>{0};
      for (final stage in map.stages) {
        final next = <int>{};
        for (final streak in streaks) {
          for (final encounter in stage.choices) {
            final value =
                encounter.type == EncounterType.combat ? streak + 1 : 0;
            expect(value, lessThanOrEqualTo(3),
                reason: 'seed $seed depth ${stage.depth}');
            next.add(value);
          }
        }
        streaks = next;
      }
    }
  });

  test('1000 maps stay near the requested encounter mix and include forks', () {
    final counts = <EncounterType, int>{};
    var total = 0;
    var forkMaps = 0;
    for (var seed = 0; seed < 1000; seed++) {
      final map = generator.generate(seed);
      if (map.stages.any((s) =>
          s.choices.length == 1 &&
          s.choices.single.type == EncounterType.fork)) {
        forkMaps++;
      }
      for (final stage in map.stages.take(map.length - 1)) {
        final type = stage.choices.first.type; // safe/default route
        counts[type] = (counts[type] ?? 0) + 1;
        total++;
      }
    }
    const expected = {
      EncounterType.combat: 50,
      EncounterType.treasure: 10,
      EncounterType.event: 15,
      EncounterType.campfire: 10,
      EncounterType.shop: 10,
      EncounterType.fork: 5,
    };
    for (final entry in expected.entries) {
      final pct = (counts[entry.key] ?? 0) * 100 / total;
      expect(pct, closeTo(entry.value, 10), reason: entry.key.name);
    }
    expect(forkMaps, greaterThan(200));
  });

  test('a branch requires an explicit safe or risky route', () {
    EncounterMap? map;
    for (var seed = 0; seed < 1000; seed++) {
      final candidate = generator.generate(seed);
      if (candidate.stages.any((s) => s.choices.length == 2)) {
        map = candidate;
        break;
      }
    }
    expect(map, isNotNull);
    final source = MapEncounterSource(map!);
    final stage = map.stages.firstWhere((s) => s.choices.length == 2);
    final rng = Random(1);
    expect(() => source.next(stage.depth, rng), throwsStateError);
    final risky = stage.choices.last;
    expect(source.choose(stage.depth, risky.routeId, rng), same(risky));
  });
}
