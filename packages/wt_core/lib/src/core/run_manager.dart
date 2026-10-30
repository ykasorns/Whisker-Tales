import 'dart:math';

import 'contracts/game_mode.dart';
import 'contracts/run_systems.dart';
import 'state/game_state.dart';

/// Executes the mode-independent walk → encounter → resolve loop (T-005).
/// Combat and panels decide whether an encounter was survived; this class
/// owns route choice, depth, deterministic RNG, rewards and mode progress.
class RunManager implements IRunManager {
  RunManager(this.stateMachine);

  final RunStateMachine stateMachine;
  GameMode? _mode;
  ModeSaveState? _modeState;
  EncounterSource? _source;
  WinCondition? _winCondition;
  Random? _rng;
  RunConfig? _config;
  RunCatSnapshot? _cat;
  Encounter? _encounter;
  int _cleared = 0;
  final _bosses = <String>[];
  RunCompletion? _completion;

  @override
  RunSessionView? get current {
    final mode = _mode;
    final config = _config;
    final cat = _cat;
    final modeState = _modeState;
    if (mode == null || config == null || cat == null || modeState == null) {
      return null;
    }
    return RunSessionView(
      modeId: mode.id,
      config: config,
      cat: cat,
      modeState: modeState,
      clearedNodes: _cleared,
      encounter: _encounter,
    );
  }

  @override
  RunCompletion? get completion => _completion;

  @override
  void startRun({
    required GameMode mode,
    required ModeSaveState modeState,
    required RunCatSnapshot cat,
    required String dayKey,
  }) {
    final base = mode.createRunConfig(modeState);
    final config = base.copyWith(
      cat: cat,
      dayKey: dayKey,
      completedRunsToday: mode is DailyRunMode
          ? (mode as DailyRunMode).completedRunsOn(modeState, dayKey)
          : 0,
    );
    stateMachine.start();
    _mode = mode;
    _modeState = modeState;
    _config = config;
    _cat = cat;
    _source = mode.encounterSource(config);
    _winCondition = mode.winCondition(config);
    _rng = Random(config.seed);
    _encounter = null;
    _cleared = 0;
    _bosses.clear();
    _completion = null;
  }

  @override
  List<Encounter> get nextChoices {
    _requireActive();
    if (stateMachine.phase != RunPhase.walking) return const [];
    final source = _source!;
    if (source is ChoiceEncounterSource) {
      return List.unmodifiable(source.choices(stateMachine.depth));
    }
    return const [];
  }

  @override
  List<EncounterPreview> preview(int count) {
    _requireActive();
    if (count < 0) throw ArgumentError.value(count, 'count');
    return _source!.preview(stateMachine.depth, count);
  }

  @override
  Encounter? advanceToNextNode({String? routeId}) {
    _requireActive();
    if (stateMachine.phase != RunPhase.walking) {
      throw StateError('advance is only allowed while walking');
    }
    final source = _source!;
    final depth = stateMachine.depth;
    final encounter = source is ChoiceEncounterSource
        ? source.choose(depth, routeId, _rng!)
        : source.next(depth, _rng!);
    if (encounter == null) {
      if (_wouldWin()) {
        _finish(RunOutcome.won);
        return null;
      }
      throw StateError('encounter source ended before the win condition');
    }
    _encounter = encounter;
    stateMachine.reachEncounter();
    return encounter;
  }

  @override
  RunCompletion? resolveEncounter({required bool survived}) {
    _requireActive();
    if (stateMachine.phase != RunPhase.encounter) {
      throw StateError('resolve is only allowed during an encounter');
    }
    stateMachine.resolve();
    if (!survived) return _finish(RunOutcome.died);

    final encounter = _encounter!;
    _cleared++;
    if (encounter.type == EncounterType.boss) {
      if (encounter.contentId case final id?) _bosses.add(id);
    }
    if (_wouldWin()) return _finish(RunOutcome.won);
    _encounter = null;
    stateMachine.walkOn();
    return null;
  }

  @override
  RunCompletion endRun(RunOutcome outcome) {
    _requireActive();
    if (outcome == RunOutcome.won && !_wouldWin()) {
      throw StateError('the mode win condition has not been met');
    }
    return _finish(outcome);
  }

  RunCompletion _finish(RunOutcome outcome) {
    if (_completion case final done?) return done;
    if (stateMachine.phase == RunPhase.ended) {
      throw StateError('run already ended');
    }
    stateMachine.end(outcome);
    final config = _config!;
    final result = RunResult(
      outcome: outcome,
      depthReached: _cleared,
      bossesCleared: List.unmodifiable(_bosses),
      dayKey: config.dayKey,
      completedRunsToday: config.completedRunsToday,
    );
    final mode = _mode!;
    final oldState = _modeState!;
    final reward = mode.resolveReward(result, oldState);
    final newState = mode is RunProgressMode
        ? (mode as RunProgressMode).updateAfterRun(result, oldState)
        : oldState;
    _modeState = newState;
    return _completion = RunCompletion(
      result: result,
      reward: reward,
      modeState: newState,
    );
  }

  bool _wouldWin() {
    final config = _config!;
    return _winCondition!.isWon(RunResult(
      outcome: RunOutcome.won,
      depthReached: _cleared,
      bossesCleared: List.unmodifiable(_bosses),
      dayKey: config.dayKey,
      completedRunsToday: config.completedRunsToday,
    ));
  }

  void _requireActive() {
    if (_mode == null || _completion != null) {
      throw StateError('no active run');
    }
  }
}
