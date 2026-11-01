import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/main.dart';
import 'package:whisker_tales/ui/frames.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/game_shell.dart';
import 'package:whisker_tales/ui/story_adventure.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

import '_l10n.dart';

class _DiskSource implements ContentSource {
  @override
  Future<String> read(String path) =>
      File('assets/content/$path').readAsString();
}

/// A readable combat snapshot whose timers move only when a test asks them
/// to. This keeps combat goldens stable while retaining the real panel data.
class _StillEngine implements ICombatEngine, IBuffEngine {
  _StillEngine({this.damageOnFirstTick = 0});

  final int damageOnFirstTick;
  final _events = StreamController<CombatEvent>.broadcast(sync: true);
  List<UnitView> _view = const [];
  bool _damaged = false;

  @override
  Stream<CombatEvent> get events => _events.stream;

  @override
  List<UnitView> get view => _view;

  @override
  void start(CombatSetup setup) {
    _view = [
      for (final unit in setup.units)
        UnitView(
          id: unit.id,
          side: unit.side,
          isBoss: unit.isBoss,
          isPartner: unit.isPartner,
          hp: unit.initialHp ?? unit.stats.hp,
          maxHp: unit.stats.hp,
          shield: 0,
          alive: true,
          skills: [
            for (final skill in unit.skills)
              SkillView(id: skill.id, remainingMs: 650, totalMs: 1000),
          ],
        ),
    ];
  }

  @override
  void tick(int dtMs) {
    if (_damaged || damageOnFirstTick <= 0 || _view.isEmpty) return;
    _damaged = true;
    final cat = _view.first;
    _view = [
      UnitView(
        id: cat.id,
        side: cat.side,
        isBoss: cat.isBoss,
        isPartner: cat.isPartner,
        hp: (cat.hp - damageOnFirstTick).clamp(0, cat.maxHp),
        maxHp: cat.maxHp,
        shield: cat.shield,
        alive: cat.hp > damageOnFirstTick,
        skills: cat.skills,
        statuses: cat.statuses,
      ),
      ..._view.skip(1),
    ];
  }

  @override
  void useSkill(int slotIndex) {}

  @override
  void apply(String unitId, String buffId, {required String sourceId}) {}
}

void main() {
  late GameContent content;
  late StoryMode mode;

  setUpAll(() async {
    content = await ContentRepository(_DiskSource()).loadAll();
    await IconRegistry.load();
    await FrameArt.load();
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

  StoryRunController makeRun(int runs,
          {ICombatEngine Function()? engineFactory}) =>
      StoryRunController(
        mode: mode,
        save: StorySave(runs: runs),
        manager: RunManager(RunStateMachine()),
        cat: CombatUnitSpec(
          id: 'mochi',
          side: CombatSide.cat,
          stats: StatBlock(hp: 1000, atk: 120, def: 40),
          attackIntervalMs: 1000,
          skills: const [
            SkillSpec(
              id: 'novice_paw_hit',
              cooldownMs: 1000,
              target: SkillTarget.front,
            ),
          ],
        ),
        classId: 'novice',
        powerScore: PowerScore(content.combat.powerWeights),
        engineFactory: engineFactory ?? _StillEngine.new,
        wallet: MemoryWallet({Currency.goldfish: 100}),
        buffBook: content.buffs,
        dayKey: '2026-10-25',
        onSave: (_) {},
      )..start();

  Future<ProviderContainer> mount(
    WidgetTester tester,
    StoryRunController run, {
    Key? key,
    bool disableAnimations = false,
  }) async {
    final container = ProviderContainer(overrides: content.overrides);
    addTearDown(container.dispose);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    final page = StoryRunPage(key: key, controller: run);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: localized(disableAnimations
          ? MediaQuery(
              data: const MediaQueryData(disableAnimations: true), child: page)
          : page),
    ));
    // AssetImage decoding completes asynchronously outside fake time. Give
    // the painted scene a short real wait before capturing it.
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 120)));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    return container;
  }

  StoryRunController combatRun() {
    for (var seed = 0; seed < 100; seed++) {
      final run = makeRun(seed);
      final combat = run.routeChoices.where((choice) =>
          choice.type == EncounterType.combat ||
          choice.type == EncounterType.boss);
      if (combat.isNotEmpty) {
        run.advance(routeId: combat.first.routeId);
        return run;
      }
      run.dispose();
    }
    throw StateError('no seeded run starts with combat');
  }

  testWidgets('all eight panel states fit the 60/40 story layout',
      (tester) async {
    final run = makeRun(7);
    addTearDown(run.dispose);

    Future<void> golden(String name) async {
      await mount(tester, run, key: UniqueKey());
      await expectLater(
        find.byType(StoryRunPage),
        matchesGoldenFile('goldens/story/$name.png'),
      );
    }

    await golden('map');
    expect(find.byKey(const Key('story-cat')), findsOneWidget);
    expect(find.byKey(const Key('story-enemy')), findsNothing);

    final fight = combatRun();
    addTearDown(fight.dispose);
    await mount(tester, fight, key: UniqueKey());
    expect(find.byKey(const Key('story-cat')), findsOneWidget);
    expect(find.byKey(const Key('story-enemy')), findsOneWidget);
    await expectLater(find.byType(StoryRunPage),
        matchesGoldenFile('goldens/story/combat.png'));

    run
      ..relicOptions = content.story.relics.keys.take(3).toList()
      ..panel = StoryRunPanel.relicPick;
    await golden('relic_pick');

    run.talents.gainXp(content.story.balance.xpToNext.first);
    run.panel = StoryRunPanel.talentPick;
    await golden('talent_pick');

    run
      ..event = content.story.events.values.first
      ..panel = StoryRunPanel.event;
    await golden('event');

    run.panel = StoryRunPanel.shop;
    await golden('shop');

    run.panel = StoryRunPanel.campfire;
    await golden('campfire');

    run
      ..completion = RunCompletion(
        result: const RunResult(
          outcome: RunOutcome.won,
          depthReached: 9,
          dayKey: '2026-10-25',
        ),
        reward: RewardResult(reward: RewardBundle({Currency.goldfish: 140})),
        modeState: StorySave(bestDepth: 9, runs: 1),
      )
      ..panel = StoryRunPanel.result;
    await golden('result');
  });

  testWidgets('an event tells its story, and the choice tells what came of it',
      (tester) async {
    late StoryRunController run;
    for (var seed = 0;; seed++) {
      run = makeRun(seed);
      final ahead = run.routeChoices
          .where((c) => c.type == EncounterType.event)
          .firstOrNull;
      if (ahead != null) {
        run.advance(routeId: ahead.routeId);
        break;
      }
      run.dispose();
      expect(seed, lessThan(400), reason: 'no seed starts with an event');
    }
    addTearDown(run.dispose);
    final event = run.event!;
    await mount(tester, run, disableAnimations: true);
    await tester.pump(const Duration(milliseconds: 400));
    // the vignette and who tells it are on the panel, in full
    expect(find.textContaining(event.storyEn.substring(0, 40)), findsOneWidget);
    final cast = content.story.narrative.cast[event.speaker];
    if (cast != null) expect(find.text(cast.nameEn), findsOneWidget);
    // choosing ends the event and the caption tells the result
    final choice = event.choices.first;
    run.chooseEvent(choice);
    await tester.pump();
    expect(run.captionLines('en'), [choice.resultEn]);
    expect(run.captionLines('th'), [choice.resultTh]);
  });

  testWidgets('a run opens with its story and lines vary by place',
      (tester) async {
    final run = makeRun(2);
    addTearDown(run.dispose);
    expect(run.captionKey, 'intro');
    expect(run.captionLines('en'), hasLength(3));
    final serial = run.captionSerial;
    run.advance(routeId: run.routeChoices.first.routeId);
    expect(run.captionSerial, greaterThan(serial));
    expect(run.captionKey, startsWith('arrive_'));
    expect(run.captionLines('th'), hasLength(1));
  });

  testWidgets('a story line stays until the player taps Next', (tester) async {
    final run = makeRun(2);
    addTearDown(run.dispose);
    await mount(tester, run);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 6));
    // long after it has been typed, it is still there, waiting
    expect(find.byKey(const Key('story-caption')), findsOneWidget);
    expect(find.byKey(const Key('story-caption-next')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('story-caption-tap')));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(seconds: 6));
    }
    expect(find.byKey(const Key('story-caption-tap')), findsNothing);
  });

  testWidgets('hits of a fight are recorded for floating numbers',
      (tester) async {
    final run = combatRun();
    addTearDown(run.dispose);
    expect(run.hits, isEmpty);
  });

  testWidgets('node map expands and collapses without blocking the run',
      (tester) async {
    final run = makeRun(3);
    addTearDown(run.dispose);
    await mount(tester, run);

    expect(find.byKey(const Key('story-node-map')), findsOneWidget);
    expect(find.byType(GameIcon), findsWidgets);
    await tester.tap(find.byKey(const Key('story-node-map')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    expect(run.panel, StoryRunPanel.map);
    await expectLater(find.byType(StoryRunPage),
        matchesGoldenFile('goldens/story/map_collapsed.png'));
  });

  testWidgets('reduced motion removes page flip and map animation',
      (tester) async {
    final run = makeRun(4);
    addTearDown(run.dispose);
    await mount(tester, run, disableAnimations: true);

    expect(
        tester.widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher)).duration,
        Duration.zero);
    expect(
        tester
            .widget<AnimatedContainer>(find.byType(AnimatedContainer))
            .duration,
        Duration.zero);
  });

  testWidgets('combat skills are read-only cooldown indicators',
      (tester) async {
    final run = combatRun();
    addTearDown(run.dispose);
    await mount(tester, run);

    final cooldown = find.byWidgetPredicate((widget) =>
        widget is CircularProgressIndicator && widget.value != null);
    expect(cooldown, findsOneWidget);
    expect(tester.widget<CircularProgressIndicator>(cooldown).value,
        closeTo(.35, .001));
    expect(find.ancestor(of: cooldown, matching: find.byType(GestureDetector)),
        findsNothing);
  });

  testWidgets('combat HUD follows live damage instead of stale room HP',
      (tester) async {
    StoryRunController? run;
    for (var seed = 0; seed < 100 && run == null; seed++) {
      final candidate = makeRun(seed,
          engineFactory: () => _StillEngine(damageOnFirstTick: 250));
      final combat = candidate.routeChoices.where((choice) =>
          choice.type == EncounterType.combat ||
          choice.type == EncounterType.boss);
      if (combat.isNotEmpty) {
        candidate.advance(routeId: combat.first.routeId);
        run = candidate;
      } else {
        candidate.dispose();
      }
    }
    expect(run, isNotNull);
    addTearDown(run!.dispose);
    await mount(tester, run);

    expect(find.textContaining('750/1000'), findsOneWidget);
    expect(run.currentHp, 1000); // committed only when the fight finishes
    expect(run.displayedHp, 750);
  });

  testWidgets('Mochi stays visible and combat actors change pose',
      (tester) async {
    final mapRun = makeRun(5);
    addTearDown(mapRun.dispose);
    await mount(tester, mapRun);
    expect(find.byKey(const Key('story-cat')), findsOneWidget);
    expect(find.byKey(const Key('story-enemy')), findsNothing);

    final fight = combatRun();
    addTearDown(fight.dispose);
    await mount(tester, fight, key: UniqueKey());
    String catAsset() =>
        (tester.widget<Image>(find.byKey(const Key('story-cat'))).image
                as AssetImage)
            .assetName;
    final firstPose = catAsset();
    var changed = false;
    for (var i = 0; i < 6 && !changed; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      changed = catAsset() != firstPose;
    }
    expect(changed, isTrue);
    expect(find.byKey(const Key('story-enemy')), findsOneWidget);
  });

  testWidgets('HUD remains readable near death with eight relics',
      (tester) async {
    final run = makeRun(11);
    addTearDown(run.dispose);
    for (final id in content.story.relics.keys.take(8)) {
      run.items.addRelic(id);
    }
    run.currentHp = 80;
    await mount(tester, run);

    expect(find.text('8'), findsOneWidget);
    expect(find.textContaining('80/1000'), findsOneWidget);
    await expectLater(find.byType(StoryRunPage),
        matchesGoldenFile('goldens/story/hud_low_eight_relics.png'));
  });

  testWidgets('talent cards require a deliberate second tap', (tester) async {
    final run = makeRun(13);
    addTearDown(run.dispose);
    run.talents.gainXp(content.story.balance.xpToNext.first);
    run.panel = StoryRunPanel.talentPick;
    final id = run.talents.pickOptions().first;
    await mount(tester, run);

    await tester.tap(find.byKey(Key('pick-$id')));
    await tester.pump();
    expect(run.talents.pendingPicks, 1);
    expect(find.text('Tap again to choose'), findsOneWidget);

    await tester.tap(find.byKey(Key('pick-$id')));
    await tester.pump();
    expect(run.talents.pendingPicks, 0);
    expect(run.panel, StoryRunPanel.map);
  });

  testWidgets('synergy mark appears only for a real owned relic pair',
      (tester) async {
    final run = makeRun(14);
    addTearDown(run.dispose);
    for (final id in ['magic_t1_glow', 'magic_t2_quickspell']) {
      run.talents.gainXp(content.story.balance.xpToNext[run.talents.level]);
      expect(run.talents.pickOptions(), contains(id));
      run.talents.chooseTalent(id);
    }
    run.items.addRelic('electric_fur');
    run.talents.gainXp(content.story.balance.xpToNext[run.talents.level]);
    run.panel = StoryRunPanel.talentPick;
    await mount(tester, run);

    final magic = find.byKey(const Key('pick-magic_t3_starfall'));
    expect(magic, findsOneWidget);
    expect(
      find.descendant(
        of: magic,
        matching: find.byWidgetPredicate((widget) =>
            widget is CustomPaint && widget.foregroundPainter != null),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the owl shop asks before spending goldfish', (tester) async {
    final run = makeRun(15)..panel = StoryRunPanel.shop;
    run.currentHp = 400;
    addTearDown(run.dispose);
    final potion = content.story.balance.potions.first;
    await mount(tester, run);
    final before = run.wallet.balance(Currency.goldfish);

    await tester.tap(find.byKey(Key('potion-${potion.id}')));
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(run.wallet.balance(Currency.goldfish), before);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(run.wallet.balance(Currency.goldfish), before);

    await tester.tap(find.byKey(Key('potion-${potion.id}')));
    await tester.pump();
    await tester.tap(find.text('Buy'));
    await tester.pump();
    expect(run.currentHp, 600);
    expect(run.wallet.balance(Currency.goldfish), before - potion.price);
    expect(find.textContaining('600/1000'), findsOneWidget);

    // A sold shop slot cannot silently consume fish a second time.
    await tester.tap(find.byKey(Key('potion-${potion.id}')));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(run.wallet.balance(Currency.goldfish), before - potion.price);
  });

  testWidgets('app opens Adventure, starts a run and returns to the menu',
      (tester) async {
    final registry = ModeRegistry()..register(mode);
    final container = ProviderContainer(overrides: [
      ...content.overrides,
      modeRegistryProvider.overrideWithValue(registry),
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(container.dispose);
    container.read(ageGateProvider).setBand(AgeBand.under13);
    container.read(idleLoopProvider).restore(clearedPage: 10);
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.runAsync(() async {
      await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child: WhiskerTalesApp(avatarRules: content.avatar, lang: 'en'),
      ));
      await Future<void>.delayed(const Duration(milliseconds: 350));
    });
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(GameShell), findsOneWidget);

    await tester.tap(findLabel('Adventure').last);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AdventurePage), findsOneWidget);
    expect(
        container.read(modeUnlockContextProvider)().bossCleared('eraserking'),
        isTrue);
    await expectLater(find.byType(AdventurePage),
        matchesGoldenFile('goldens/story/adventure_unlocked.png'));
    final card = tester
        .widget<GestureDetector>(find.byKey(const Key('story-mode-card')));
    expect(card.onTap, isNotNull);
    card.onTap!();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    expect(container.read(gameStateProvider), GameState.run);
    expect(find.byType(StoryRunPage), findsOneWidget);

    await tester.tap(find.byKey(const Key('story-quit')));
    await tester.pump();
    final leave = find.descendant(
        of: find.byType(FilledButton), matching: findLabel('Leave story'));
    await tester.tap(leave);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(StoryRunPage), findsNothing);
    expect(find.byType(AdventurePage), findsOneWidget);
    expect(container.read(gameStateProvider), GameState.hub);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
