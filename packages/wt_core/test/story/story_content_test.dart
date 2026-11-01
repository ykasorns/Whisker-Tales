import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class _RepoSource implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

void main() {
  late StoryContent story;

  setUpAll(() async {
    story = (await ContentRepository(_RepoSource()).loadAll()).story;
  });

  test('MVP roster is complete and every entry is bilingual', () {
    expect(story.relics, hasLength(15));
    expect(story.talents, hasLength(9));
    expect(story.events, hasLength(12));
    expect(story.monsters.values.where((m) => !m.isBoss), hasLength(5));
    expect(story.monsters.values.where((m) => m.isBoss).single.id, 'paperwolf');
    expect(story.balance.potions, hasLength(4));

    for (final relic in story.relics.values) {
      expect([
        relic.nameTh,
        relic.nameEn,
        relic.descriptionTh,
        relic.descriptionEn
      ], everyElement(isNotEmpty));
    }
    for (final talent in story.talents.values) {
      expect([
        talent.nameTh,
        talent.nameEn,
        talent.descriptionTh,
        talent.descriptionEn
      ], everyElement(isNotEmpty));
    }
    for (final event in story.events.values) {
      expect([
        event.nameTh,
        event.nameEn,
        event.descriptionTh,
        event.descriptionEn
      ], everyElement(isNotEmpty));
      expect(event.choices, hasLength(2));
      expect(event.storyTh, isNotEmpty);
      expect(event.storyEn, isNotEmpty);
      if (event.speaker != null) {
        expect(story.narrative.cast, contains(event.speaker));
      }
    }
  });

  test('the run has a story thread in both languages', () {
    final n = story.narrative;
    for (final key in StoryNarrative.requiredKeys) {
      expect(n.lines(key, 'th'), isNotEmpty, reason: key);
      expect(n.lines(key, 'th'), hasLength(n.lines(key, 'en').length));
    }
    expect(n.line('intro', 'en', 7), isNotNull); // index wraps
    expect(n.line('nope', 'en', 0), isNull);
    // a vignette is told in two or three sentences, short enough to read
    for (final e in story.events.values) {
      expect(e.storyEn.length, lessThan(320), reason: e.id);
      expect(e.storyTh.length, lessThan(300), reason: e.id);
    }
  });

  test('synergy matrix contains all eight pairs including the GDD pairs', () {
    final pairs = {
      for (final relic in story.relics.values)
        for (final synergy in relic.synergies)
          '${relic.id}+${synergy.withRelic}',
    };
    expect(pairs, hasLength(8));
    expect(pairs, contains('electric_fur+echo_bell'));
    expect(pairs, contains('grilled_fish+warm_scarf'));
    expect(pairs, contains('shadow_claw+lightning_milk'));
    for (final relic in story.relics.values) {
      for (final synergy in relic.synergies) {
        expect(synergy.effect.chancePct, inInclusiveRange(1, 100));
      }
    }
  });

  test('talents form three complete tier chains and keep cross-synergy', () {
    for (final tree in ['claw', 'shadow', 'magic']) {
      final talents = story.talents.values.where((t) => t.tree == tree);
      expect(talents.map((t) => t.tier).toSet(), {1, 2, 3});
    }
    final cross = story.talents['magic_t3_starfall']!.crossSynergies.single;
    expect(cross.relicId, 'electric_fur');
    expect(cross.effect.buffId, 'story_extra_hit');
    expect(cross.effect.trigger, EffectTrigger.onSkill);
    expect(cross.effect.target, StoryEffectTarget.self);
  });

  test('XP curve yields two to three picks in an ordinary route', () {
    int levelsFor(int xp) {
      var levels = 0;
      for (final need in story.balance.xpToNext) {
        if (xp < need) break;
        xp -= need;
        levels++;
      }
      return levels;
    }

    final low = story.balance.combatXp * 4 +
        story.balance.eventXp +
        story.balance.bossXp;
    final high = story.balance.combatXp * 6 +
        story.balance.eventXp +
        story.balance.bossXp;
    expect(levelsFor(low), 2);
    expect(levelsFor(high), 3);
  });

  test('every Story monster already has a shipped idle sprite', () {
    for (final monster in story.monsters.values) {
      expect(
          File('../../app/assets/game/mon/${monster.sprite}_idle_f1.png')
              .existsSync(),
          isTrue,
          reason: monster.id);
    }
  });
}
