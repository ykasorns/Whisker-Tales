import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class _RepoSource implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

class _Applied {
  const _Applied(this.unitId, this.buffId, this.sourceId);
  final String unitId, buffId, sourceId;
}

class _Buffs implements IBuffEngine {
  final applied = <_Applied>[];

  @override
  void apply(String unitId, String buffId, {required String sourceId}) {
    applied.add(_Applied(unitId, buffId, sourceId));
  }
}

class _Context implements EffectContext {
  _Context(this.buffEngine, {this.enemyUnitId = 'monster', this.roll = 0});

  @override
  String get ownerUnitId => 'cat';
  @override
  final String? enemyUnitId;
  @override
  final IBuffEngine buffEngine;
  int roll;

  @override
  int nextBasisPoint() => roll;
}

StoryRelic _relic(String id, StoryEffect effect,
        {List<StorySynergy> synergies = const []}) =>
    StoryRelic(
      id: id,
      nameTh: id,
      nameEn: id,
      descriptionTh: id,
      descriptionEn: id,
      icon: id,
      rarity: 'common',
      effects: [effect],
      synergies: synergies,
    );

StoryEffect _effect(EffectTrigger trigger,
        {String buff = 'test_buff',
        StoryEffectTarget target = StoryEffectTarget.self,
        int chance = 100}) =>
    StoryEffect(
      trigger: trigger,
      buffId: buff,
      target: target,
      chancePct: chance,
    );

void main() {
  late StoryContent story;

  setUpAll(() async {
    story = (await ContentRepository(_RepoSource()).loadAll()).story;
  });

  test('every trigger is resolved from relic data through BuffEngine', () {
    final relics = {
      for (final trigger in EffectTrigger.values)
        trigger.name: _relic(trigger.name, _effect(trigger)),
    };
    final items = ItemSystem(relics);
    for (final id in relics.keys) {
      items.addRelic(id);
    }
    final buffs = _Buffs();
    final context = _Context(buffs);

    for (final trigger in EffectTrigger.values) {
      items.resolve(trigger, context);
    }

    expect(buffs.applied, hasLength(EffectTrigger.values.length));
    expect(buffs.applied.map((e) => e.buffId), everyElement('test_buff'));
    expect(buffs.applied.map((e) => e.sourceId), everyElement('cat'));
  });

  test('target and chance are data-driven and deterministic', () {
    final item = ItemSystem({
      'new_json_relic': _relic(
        'new_json_relic',
        _effect(EffectTrigger.onAttack,
            buff: 'poison', target: StoryEffectTarget.enemy, chance: 25),
      ),
    })
      ..addRelic('new_json_relic');
    final buffs = _Buffs();
    final context = _Context(buffs, roll: 2499);

    item.resolve(EffectTrigger.onAttack, context);
    context.roll = 2500;
    item.resolve(EffectTrigger.onAttack, context);

    expect(buffs.applied, hasLength(1));
    expect(buffs.applied.single.unitId, 'monster');
    expect(buffs.applied.single.buffId, 'poison');
  });

  test('run context uses the reproducible seeded RNG stream', () {
    final a = RunEffectContext(
        ownerUnitId: 'cat', buffEngine: _Buffs(), rng: SeededRng(42));
    final b = RunEffectContext(
        ownerUnitId: 'cat', buffEngine: _Buffs(), rng: SeededRng(42));

    expect(
      List.generate(20, (_) => a.nextBasisPoint()),
      List.generate(20, (_) => b.nextBasisPoint()),
    );
  });

  test('an enemy effect is safely skipped when no enemy exists', () {
    final item = ItemSystem({
      'enemy_effect': _relic(
          'enemy_effect',
          _effect(EffectTrigger.onSkill,
              target: StoryEffectTarget.enemy, chance: 50)),
    })
      ..addRelic('enemy_effect');
    final buffs = _Buffs();

    item.resolve(
        EffectTrigger.onSkill, _Context(buffs, enemyUnitId: null, roll: 0));

    expect(buffs.applied, isEmpty);
  });

  test('GDD synergy pairs activate once and resolve at their data trigger', () {
    final items = ItemSystem(story.relics);
    final activated = <String>[];
    items.synergies.activations
        .listen((e) => activated.add('${e.relicA}+${e.relicB}'));

    for (final id in [
      'electric_fur',
      'echo_bell',
      'grilled_fish',
      'warm_scarf',
      'shadow_claw',
      'lightning_milk',
    ]) {
      items.addRelic(id);
    }
    items.addRelic('echo_bell');

    expect(
        activated,
        containsAll([
          'electric_fur+echo_bell',
          'grilled_fish+warm_scarf',
          'shadow_claw+lightning_milk',
        ]));
    expect(activated, hasLength(3));

    final buffs = _Buffs();
    final context = _Context(buffs, roll: 9999);
    items.resolve(EffectTrigger.onAttack, context);
    items.resolve(EffectTrigger.onCrit, context);
    items.resolve(EffectTrigger.onCombatEnd, context);

    expect(buffs.applied.map((e) => e.buffId), contains('story_extra_hit'));
    expect(buffs.applied.map((e) => e.buffId), contains('story_crit_haste'));
    expect(buffs.applied.map((e) => e.buffId), contains('story_heal_20'));
  });

  test('removing a relic deactivates its pairs', () {
    final items = ItemSystem(story.relics)
      ..addRelic('electric_fur')
      ..addRelic('echo_bell');
    expect(items.synergies.activePairs, hasLength(1));

    items.removeRelic('echo_bell');

    expect(items.synergies.activePairs, isEmpty);
    final buffs = _Buffs();
    items.resolve(EffectTrigger.onAttack, _Context(buffs, roll: 9999));
    expect(buffs.applied, isEmpty);
  });

  test('unknown relic id is rejected without changing the inventory', () {
    final items = ItemSystem(story.relics);
    expect(() => items.addRelic('missing'), throwsArgumentError);
    expect(items.relicIds, isEmpty);
  });
}
