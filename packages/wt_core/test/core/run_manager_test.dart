import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class _Save extends ModeSaveState {
  const _Save({this.runs = 0, this.best = 0});
  final int runs;
  final int best;
}

class _Source implements ChoiceEncounterSource {
  static const stages = [
    [Encounter(type: EncounterType.combat, depth: 0, routeId: 'fight')],
    [
      Encounter(type: EncounterType.campfire, depth: 1, routeId: 'safe'),
      Encounter(type: EncounterType.combat, depth: 1, routeId: 'risky'),
    ],
    [
      Encounter(
          type: EncounterType.boss,
          depth: 2,
          routeId: 'boss',
          contentId: 'paperwolf'),
    ],
  ];

  @override
  List<Encounter> choices(int depth) =>
      depth >= stages.length ? const [] : stages[depth];

  @override
  Encounter? choose(int depth, String? routeId, Random rng) {
    final available = choices(depth);
    if (available.isEmpty) return null;
    if (routeId == null && available.length == 1) return available.single;
    return available.firstWhere((e) => e.routeId == routeId);
  }

  @override
  Encounter? next(int depth, Random rng) => choose(depth, null, rng);

  @override
  List<EncounterPreview> preview(int depth, int count) => const [];
}

class _InfiniteSource implements EncounterSource {
  @override
  Encounter next(int depth, Random rng) =>
      Encounter(type: EncounterType.combat, depth: depth);

  @override
  List<EncounterPreview> preview(int depth, int count) => List.generate(count,
      (i) => EncounterPreview(type: EncounterType.combat, depth: depth + i));
}

class _Win implements WinCondition {
  @override
  bool isWon(RunResult result) => result.bossesCleared.contains('paperwolf');
}

class _Mode implements GameMode, RunProgressMode {
  _Mode({EncounterSource? source}) : _source = source;

  final EncounterSource? _source;

  @override
  String get id => 'test';

  @override
  ModeManifest get manifest => const ModeManifest(
      id: 'test',
      nameTh: 'ทดสอบ',
      nameEn: 'Test',
      icon: 'test',
      order: 1,
      enabled: true,
      minAppVersion: '1');

  @override
  Widget buildHubCard(BuildContext context, ModeSaveState state) =>
      const SizedBox();

  @override
  RunConfig createRunConfig(ModeSaveState state) => const RunConfig(seed: 77);

  @override
  EncounterSource encounterSource(RunConfig config) => _source ?? _Source();

  @override
  WinCondition winCondition(RunConfig config) => _Win();

  @override
  RewardResult resolveReward(RunResult result, ModeSaveState state) =>
      RewardResult(
          reward: RewardBundle({Currency.goldfish: result.depthReached * 10}));

  @override
  ModeSaveState updateAfterRun(RunResult result, ModeSaveState state) {
    final old = state as _Save;
    return _Save(runs: old.runs + 1, best: max(old.best, result.depthReached));
  }

  @override
  ModeSaveState decodeSave(Map<String, dynamic> json) => const _Save();

  @override
  Map<String, dynamic> encodeSave(ModeSaveState state) => const {};
}

final cat = RunCatSnapshot(
  id: 'mochi',
  classId: 'mage',
  stats: StatBlock(hp: 100, atk: 20, def: 10),
  power: 123,
);

void main() {
  test('runs a full route, snapshots Mochi and records the boss reward', () {
    final machine = RunStateMachine();
    final manager = RunManager(machine)
      ..startRun(
        mode: _Mode(),
        modeState: const _Save(),
        cat: cat,
        dayKey: '2026-10-24',
      );

    expect(manager.current!.config.cat, same(cat));
    expect(manager.current!.config.seed, 77);
    expect(machine.state.phase, RunPhase.walking);

    expect(manager.advanceToNextNode()!.type, EncounterType.combat);
    expect(machine.state.phase, RunPhase.encounter);
    expect(manager.resolveEncounter(survived: true), isNull);
    expect(machine.state.depth, 1);

    expect(manager.nextChoices.map((e) => e.routeId), ['safe', 'risky']);
    expect(manager.advanceToNextNode(routeId: 'risky')!.type,
        EncounterType.combat);
    manager.resolveEncounter(survived: true);

    expect(manager.advanceToNextNode()!.type, EncounterType.boss);
    final done = manager.resolveEncounter(survived: true)!;
    expect(machine.state.phase, RunPhase.ended);
    expect(done.result.outcome, RunOutcome.won);
    expect(done.result.depthReached, 3);
    expect(done.result.bossesCleared, ['paperwolf']);
    expect(done.reward.reward[Currency.goldfish], 30);
    expect((done.modeState as _Save).runs, 1);
    expect((done.modeState as _Save).best, 3);
  });

  test('dying midway still returns fail-forward rewards', () {
    final manager = RunManager(RunStateMachine())
      ..startRun(
        mode: _Mode(),
        modeState: const _Save(),
        cat: cat,
        dayKey: '2026-10-24',
      );
    manager.advanceToNextNode();
    manager.resolveEncounter(survived: true);
    manager.advanceToNextNode(routeId: 'risky');
    final done = manager.resolveEncounter(survived: false)!;
    expect(done.result.outcome, RunOutcome.died);
    expect(done.result.depthReached, 1);
    expect(done.reward.reward[Currency.goldfish], 10);
  });

  test('invalid phase and missing branch choices are rejected', () {
    final manager = RunManager(RunStateMachine())
      ..startRun(
        mode: _Mode(),
        modeState: const _Save(),
        cat: cat,
        dayKey: '2026-10-24',
      );
    expect(() => manager.resolveEncounter(survived: true), throwsStateError);
    manager.advanceToNextNode();
    expect(manager.advanceToNextNode, throwsStateError);
    manager.resolveEncounter(survived: true);
    expect(manager.advanceToNextNode, throwsStateError);
  });

  test('a caller cannot declare victory before the mode condition is met', () {
    final manager = RunManager(RunStateMachine())
      ..startRun(
        mode: _Mode(),
        modeState: const _Save(),
        cat: cat,
        dayKey: '2026-10-24',
      );

    expect(() => manager.endRun(RunOutcome.won), throwsStateError);
    expect(manager.completion, isNull);
  });

  test('the same manager can run an infinite source until the player leaves',
      () {
    final manager = RunManager(RunStateMachine())
      ..startRun(
        mode: _Mode(source: _InfiniteSource()),
        modeState: const _Save(),
        cat: cat,
        dayKey: '2026-10-24',
      );

    for (var i = 0; i < 5; i++) {
      expect(manager.advanceToNextNode()!.depth, i);
      expect(manager.resolveEncounter(survived: true), isNull);
    }
    final done = manager.endRun(RunOutcome.abandoned);
    expect(done.result.outcome, RunOutcome.abandoned);
    expect(done.result.depthReached, 5);
  });
}
