import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../contracts/game_mode.dart';

/// Top-level screens of the app (GDD v0.4 §2, §14).
enum GameState {
  /// Loading data and save.
  boot,

  /// Neutral first-launch age screen (T-040).
  ageGate,

  /// The idle farm — the main loop and home screen (D-002).
  hub,

  /// Inside a run-based side mode (adventure / endless).
  run,
}

/// Allowed screen changes; anything else is a bug.
class GameStateMachine extends StateNotifier<GameState> {
  GameStateMachine() : super(GameState.boot);

  static const _allowed = {
    GameState.boot: {GameState.ageGate, GameState.hub},
    GameState.ageGate: {GameState.hub},
    GameState.hub: {GameState.run},
    GameState.run: {GameState.hub},
  };

  void goTo(GameState next) {
    if (!_allowed[state]!.contains(next)) {
      throw StateError('Illegal game state change: $state → $next');
    }
    state = next;
  }
}

/// Phases of a run in run-based modes: walk → encounter → resolve → walk
/// (GDD v0.3 §3.2). The idle main loop does not use this (D-002).
enum RunPhase { notStarted, walking, encounter, resolving, ended }

class RunState {
  const RunState({required this.phase, this.depth = 0, this.outcome});

  static const initial = RunState(phase: RunPhase.notStarted);

  final RunPhase phase;

  /// Index of the node the cat is at or walking to.
  final int depth;

  /// Set once [phase] is [RunPhase.ended].
  final RunOutcome? outcome;

  @override
  bool operator ==(Object other) =>
      other is RunState &&
      other.phase == phase &&
      other.depth == depth &&
      other.outcome == outcome;

  @override
  int get hashCode => Object.hash(phase, depth, outcome);

  @override
  String toString() => 'RunState($phase, depth: $depth, outcome: $outcome)';
}

/// Drives [RunState]. RunManager (T-005) calls these as the run plays out.
class RunStateMachine extends StateNotifier<RunState> {
  RunStateMachine() : super(RunState.initial);

  /// Starts a new run; allowed before the first run or after one ended.
  void start() {
    _expect({RunPhase.notStarted, RunPhase.ended}, 'start');
    state = const RunState(phase: RunPhase.walking);
  }

  /// The cat reached the encounter at the current depth.
  void reachEncounter() {
    _expect({RunPhase.walking}, 'reachEncounter');
    state = RunState(phase: RunPhase.encounter, depth: state.depth);
  }

  /// The player interacted; the encounter's result is being applied.
  void resolve() {
    _expect({RunPhase.encounter}, 'resolve');
    state = RunState(phase: RunPhase.resolving, depth: state.depth);
  }

  /// Resolution done; walk on to the next node.
  void walkOn() {
    _expect({RunPhase.resolving}, 'walkOn');
    state = RunState(phase: RunPhase.walking, depth: state.depth + 1);
  }

  /// Ends the run from any active phase (boss beaten, cat fainted, quit).
  void end(RunOutcome outcome) {
    _expect({RunPhase.walking, RunPhase.encounter, RunPhase.resolving}, 'end');
    state =
        RunState(phase: RunPhase.ended, depth: state.depth, outcome: outcome);
  }

  void _expect(Set<RunPhase> allowed, String action) {
    if (!allowed.contains(state.phase)) {
      throw StateError('$action is not allowed during ${state.phase}');
    }
  }
}
