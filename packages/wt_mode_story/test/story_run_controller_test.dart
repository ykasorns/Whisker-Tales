import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

class _RepoSource implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

class _InstantWinEngine implements ICombatEngine, IBuffEngine {
  final _events = StreamController<CombatEvent>.broadcast(sync: true);
  final applied = <String>[];
  List<UnitView> _view = const [];
  bool _done = false;

  @override
  Stream<CombatEvent> get events => _events.stream;

  @override
  List<UnitView> get view => _view;

  @override
  void start(CombatSetup setup) {
    final cat = setup.units.first;
    final enemy = setup.units.last;
    _view = [
      UnitView(
        id: cat.id,
        side: cat.side,
        isBoss: false,
        isPartner: false,
        hp: cat.initialHp ?? cat.stats.hp,
        maxHp: cat.stats.hp,
        shield: 0,
        alive: true,
        skills: [
          for (final skill in cat.skills)
            SkillView(id: skill.id, remainingMs: 100, totalMs: 1000),
        ],
      ),
      UnitView(
        id: enemy.id,
        side: enemy.side,
        isBoss: enemy.isBoss,
        isPartner: false,
        hp: enemy.stats.hp,
        maxHp: enemy.stats.hp,
        shield: 0,
        alive: true,
      ),
    ];
  }

  @override
  void tick(int dtMs) {
    if (_done) return;
    _done = true;
    final cat = _view.first;
    final enemy = _view.last;
    _events.add(HitResolved(
      atMs: 100,
      attackerId: cat.id,
      targetId: enemy.id,
      outcome: HitOutcome.crit,
      damage: enemy.hp,
      targetHp: 0,
    ));
    if (cat.skills.isNotEmpty) {
      _events.add(
          SkillCast(atMs: 120, unitId: cat.id, skillId: cat.skills.first.id));
    }
    _view = [
      cat,
      UnitView(
        id: enemy.id,
        side: enemy.side,
        isBoss: enemy.isBoss,
        isPartner: false,
        hp: 0,
        maxHp: enemy.maxHp,
        shield: 0,
        alive: false,
      ),
    ];
    _events.add(UnitDefeated(enemy.id, atMs: 150));
    _events.add(const CombatEnded(playerWon: true, atMs: 150));
  }

  @override
  void useSkill(int slotIndex) {}

  @override
  void apply(String unitId, String buffId, {required String sourceId}) {
    applied.add(buffId);
  }
}

void main() {
  late GameContent content;
  late StoryMode mode;

  setUpAll(() async {
    content = await ContentRepository(_RepoSource()).loadAll();
    mode = StoryMode(
      const ModeManifest(
        id: 'story',
        nameTh: 'ท้าทายนิทาน',
        nameEn: 'Story Challenge',
        icon: 'mode_story',
        order: 1,
        enabled: true,
        minAppVersion: '1.0.0',
      ),
      content.story,
    );
  });

  StoryRunController make(int runs, Set<StoryRunPanel> visited,
      {MemoryWallet? wallet}) {
    final run = StoryRunController(
      mode: mode,
      save: StorySave(runs: runs),
      manager: RunManager(RunStateMachine()),
      cat: CombatUnitSpec(
        id: 'mochi',
        side: CombatSide.cat,
        stats: StatBlock(hp: 1000, atk: 100, def: 30),
        attackIntervalMs: 1000,
        skills: const [
          SkillSpec(
              id: 'test_skill', cooldownMs: 1000, target: SkillTarget.front),
        ],
      ),
      classId: 'mage',
      powerScore: PowerScore(content.combat.powerWeights),
      engineFactory: _InstantWinEngine.new,
      wallet: wallet ?? MemoryWallet({Currency.goldfish: 10000}),
      buffBook: content.buffs,
      dayKey: '2026-10-25',
      onSave: (_) {},
    )..start();
    run.addListener(() => visited.add(run.panel));
    visited.add(run.panel);
    return run;
  }

  void finish(StoryRunController run, Set<StoryRunPanel> visited) {
    var guard = 0;
    while (run.panel != StoryRunPanel.result && guard++ < 100) {
      visited.add(run.panel);
      switch (run.panel) {
        case StoryRunPanel.map:
          run.advance(routeId: run.routeChoices.first.routeId);
        case StoryRunPanel.combat:
          run.tick(16);
        case StoryRunPanel.relicPick:
          run.chooseRelic(run.relicOptions.first);
        case StoryRunPanel.talentPick:
          run.chooseTalent(run.talents.pickOptions().first);
        case StoryRunPanel.event:
          run.chooseEvent(run.event!.choices.first);
        case StoryRunPanel.shop:
          run.buyPotion(run.mode.content.balance.potions.first);
          run.leaveShop();
        case StoryRunPanel.campfire:
          if (run.relicIds.isEmpty) {
            run.restAtCampfire();
          } else {
            run.upgradeAtCampfire(run.relicIds.first);
          }
        case StoryRunPanel.result:
          break;
      }
    }
    expect(guard, lessThan(100));
    expect(run.completion?.result.outcome, RunOutcome.won);
  }

  test('fifty seeded runs exercise every panel and finish with rewards', () {
    final visited = <StoryRunPanel>{};
    var upgraded = false;
    for (var seed = 0; seed < 50; seed++) {
      final wallet = MemoryWallet({Currency.goldfish: 10000});
      final run = make(seed, visited, wallet: wallet);
      finish(run, visited);
      upgraded |= run.relicIds.any((id) => run.items.levelOf(id) > 1);
      expect(run.save.runs, seed + 1);
      expect(run.save.bestDepth, inInclusiveRange(8, 10));
      expect(wallet.balance(Currency.goldfish), greaterThan(0));
      run.dispose();
    }

    expect(visited, containsAll(StoryRunPanel.values));
    expect(upgraded, isTrue);
  });

  test('abandon grants fail-forward state once and is safe to save', () {
    final visited = <StoryRunPanel>{};
    StorySave? saved;
    final run = StoryRunController(
      mode: mode,
      save: StorySave(),
      manager: RunManager(RunStateMachine()),
      cat: CombatUnitSpec(
          id: 'mochi',
          side: CombatSide.cat,
          stats: StatBlock(hp: 100, atk: 10, def: 2),
          attackIntervalMs: 1000),
      classId: 'novice',
      powerScore: PowerScore(content.combat.powerWeights),
      engineFactory: _InstantWinEngine.new,
      wallet: MemoryWallet(),
      buffBook: content.buffs,
      dayKey: '2026-10-25',
      onSave: (value) => saved = value,
    )..start();

    run.abandon();

    expect(run.panel, StoryRunPanel.result);
    expect(run.completion?.result.outcome, RunOutcome.abandoned);
    expect(saved, isNotNull);
    run.dispose();
    expect(visited, isEmpty);
  });

  test('shop healing changes HP immediately and never charges for no effect',
      () {
    final wallet = MemoryWallet({Currency.goldfish: 100});
    final run = make(0, <StoryRunPanel>{}, wallet: wallet)
      ..panel = StoryRunPanel.shop
      ..currentHp = 400;
    final potion = mode.content.balance.potions
        .firstWhere((item) => item.buffId == 'story_heal_20');

    expect(run.buyPotion(potion), isTrue);
    expect(run.currentHp, 600);
    expect(run.displayedHp, 600);
    expect(wallet.balance(Currency.goldfish), 80);
    expect(run.purchasedPotionIds, contains(potion.id));

    expect(run.buyPotion(potion), isFalse);
    expect(wallet.balance(Currency.goldfish), 80);
    run.dispose();
  });
}
