import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock/game_clock.dart';

/// Shared Riverpod providers — the only channel between modules besides
/// `core/contracts/` (GAME_CONTRACT §3). T-002 adds the run-mode providers.

/// Device clock; override with a fake in tests.
final timeSourceProvider = Provider<TimeSource>((ref) => const SystemTimeSource());

/// The game's single clock (T-033). Save restore wraps this with the
/// persisted [ClockState] once `save_cloud` (T-022) exists.
final gameClockProvider = Provider<GameClock>((ref) {
  final clock = GameClock(ref.watch(timeSourceProvider));
  ref.onDispose(clock.dispose);
  return clock;
});
