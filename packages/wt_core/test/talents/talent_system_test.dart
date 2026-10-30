import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class _RepoSource implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

class _Applied {
  const _Applied(this.unitId, this.buffId);
  final String unitId, buffId;
}

class _Buffs implements IBuffEngine {
  final applied = <_Applied>[];

  @override
  void apply(String unitId, String buffId, {required String sourceId}) {
    expect(sourceId, 'cat');
    applied.add(_Applied(unitId, buffId));
  }
}

class _Context implements EffectContext {
  _Context(this.buffEngine);

  @override
  String get ownerUnitId => 'cat';
  @override
  String get enemyUnitId => 'monster';
  @override
  final IBuffEngine buffEngine;
  @override
  int nextBasisPoint() => 0;
}

void main() {
  late StoryContent story;

  setUpAll(() async {
    story = (await ContentRepository(_RepoSource()).loadAll()).story;
  });

  TalentSystem system(int seed, {Set<String> relics = const {}}) =>
      TalentSystem(
        talents: story.talents,
        xpToNext: story.balance.xpToNext,
        seed: seed,
        relicIds: () => relics,
      );

  void unlock(TalentSystem talents, String id, int levelIndex) {
    talents.gainXp(story.balance.xpToNext[levelIndex]);
    expect(talents.pickOptions(), contains(id));
    talents.chooseTalent(id);
  }

  test('XP thresholds come from Story balance and emit every crossed level',
      () {
    final talents = system(1);
    final levels = <int>[];
    talents.levelUps.listen((event) => levels.add(event.level));

    talents.gainXp(story.balance.xpToNext.first - 1);
    expect((talents.level, talents.pendingPicks), (0, 0));
    talents.gainXp(1);
    talents.gainXp(story.balance.xpToNext[1] + story.balance.xpToNext[2]);

    expect(levels, [1, 2, 3]);
    expect((talents.level, talents.pendingPicks, talents.xp), (3, 3, 0));
  });

  test('two picks in one tree guarantee that tree in 1000 seeded rolls', () {
    for (var seed = 0; seed < 1000; seed++) {
      final talents = system(seed);
      unlock(talents, 'claw_t1_sharpen', 0);
      unlock(talents, 'claw_t2_double', 1);
      talents.gainXp(story.balance.xpToNext[2]);
      expect(talents.pickOptions(), contains('claw_t3_reset'), reason: '$seed');
    }
  });

  test('an offer is stable until one of its three cards is chosen', () {
    final talents = system(12)..gainXp(story.balance.xpToNext.first);
    final first = talents.pickOptions();

    expect(first, hasLength(3));
    expect(talents.pickOptions(), same(first));
    expect(
        () => talents.chooseTalent('magic_t3_starfall'), throwsArgumentError);
    talents.chooseTalent(first.first);
    expect(talents.pendingPicks, 0);
  });

  test('all nine MVP talents route their data effects through BuffEngine', () {
    final buffs = _Buffs();
    for (final tree in ['claw', 'shadow', 'magic']) {
      final talents = system(tree.hashCode);
      final chain = story.talents.values
          .where((talent) => talent.tree == tree)
          .toList()
        ..sort((a, b) => a.tier.compareTo(b.tier));
      for (var i = 0; i < chain.length; i++) {
        unlock(talents, chain[i].id, i);
      }
      for (final trigger in EffectTrigger.values) {
        talents.resolve(trigger, _Context(buffs));
      }
    }

    expect(buffs.applied, hasLength(9));
    expect(
        buffs.applied.map((e) => e.buffId),
        containsAll([
          'story_atk_15',
          'story_extra_hit',
          'story_cooldown_1000',
          'story_evade_8',
          'story_crit_haste',
          'story_skill_20',
          'story_cdr_15',
          'story_star_bomb',
        ]));
  });

  test('electric fur and magic tier 3 fire the cross-synergy on skill', () {
    final talents = system(99, relics: {'electric_fur'});
    unlock(talents, 'magic_t1_glow', 0);
    unlock(talents, 'magic_t2_quickspell', 1);
    unlock(talents, 'magic_t3_starfall', 2);
    final buffs = _Buffs();

    talents.resolve(EffectTrigger.onSkill, _Context(buffs));

    expect(
        buffs.applied.map((e) => (e.unitId, e.buffId)),
        containsAll([
          ('monster', 'story_star_bomb'),
          ('cat', 'story_extra_hit'),
        ]));
  });

  test('bad XP and selecting without a pending level are rejected', () {
    final talents = system(4);
    expect(() => talents.gainXp(-1), throwsArgumentError);
    expect(() => talents.chooseTalent('claw_t1_sharpen'), throwsStateError);
  });
}
