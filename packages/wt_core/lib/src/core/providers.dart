import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock/game_clock.dart';
import 'state/game_state.dart';

/// Shared Riverpod providers — the only channel between modules besides
/// `core/contracts/` (GAME_CONTRACT §3). Module tasks add their providers here.

/// Device clock; override with a fake in tests.
final timeSourceProvider =
    Provider<TimeSource>((ref) => const SystemTimeSource());

/// The game's single clock (T-033). Save restore wraps this with the
/// persisted [ClockState] once `save_cloud` (T-022) exists.
final gameClockProvider = Provider<GameClock>((ref) {
  final clock = GameClock(ref.watch(timeSourceProvider));
  ref.onDispose(clock.dispose);
  return clock;
});

/// Current top-level screen (T-002).
final gameStateProvider = StateNotifierProvider<GameStateMachine, GameState>(
    (ref) => GameStateMachine());

/// Phase of the current run in a run-based side mode (T-002, used by T-005).
final runStateProvider = StateNotifierProvider<RunStateMachine, RunState>(
    (ref) => RunStateMachine());
