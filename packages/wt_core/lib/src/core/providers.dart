import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cat/cat.dart';
import '../combat/combat.dart';
import 'clock/game_clock.dart';
import 'contracts/combat.dart';
import 'contracts/idle_loop.dart';
import '../idle/idle.dart';
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

/// Combat numbers (`idle_balance_v1.json` → `combat`). Overridden at boot
/// with the rules the data loader (T-003) reads.
final combatRulesProvider = Provider<CombatRules>(
    (ref) => throw UnimplementedError('override with loaded CombatRules'));

/// Makes a fresh engine per fight (T-007).
final combatEngineFactoryProvider = Provider<ICombatEngine Function()>((ref) {
  final rules = ref.watch(combatRulesProvider);
  return () => CombatEngine(rules);
});

/// Cat power 🐾 (GDD v0.4 §15.2).
final powerScoreProvider = Provider<PowerScore>(
    (ref) => PowerScore(ref.watch(combatRulesProvider).powerWeights));

/// Cat level + class numbers (`cat_level`, `classes`). Overridden at boot
/// with the rules the data loader (T-003) reads.
final catRulesProvider = Provider<CatRules>(
    (ref) => throw UnimplementedError('override with loaded CatRules'));

/// True while a boss fight runs; class changes are refused then (T-044).
/// Reads the idle loop lazily so the two providers do not depend on each
/// other at build time.
final Provider<bool Function()> inBossFightProvider = Provider<bool Function()>(
    (ref) => () => ref.read(idleLoopProvider).isBossFight);

/// Cat level and EXP (T-044).
final catProgressProvider = Provider<CatProgress>((ref) {
  final p = CatProgress(ref.watch(catRulesProvider));
  ref.onDispose(p.dispose);
  return p;
});

/// Cat class (T-044).
final Provider<CatClass> catClassProvider = Provider<CatClass>((ref) =>
    CatClass(ref.watch(catRulesProvider), ref.watch(catProgressProvider),
        inBossFight: ref.watch(inBossFightProvider)));

/// Pages, waves, income numbers (`enemy`, `pages`, `income`, `player`).
/// Overridden at boot with the rules the data loader (T-003) reads.
final idleRulesProvider = Provider<IdleRules>(
    (ref) => throw UnimplementedError('override with loaded IdleRules'));

/// Seed of the player's world; restored from the save.
final idleSeedProvider = Provider<int>((ref) => 0);

/// Flat stats added to the cat before the class multiplier: gear, pets,
/// research, road-event buffs. Each module that adds stats overrides this.
final catExtraStatsProvider = Provider<StatBlock Function()>(
    (ref) => () => StatBlock(hp: 0, atk: 0, def: 0));

/// The one income formula for online and offline (T-034, T-035).
final incomeModelProvider = Provider<IncomeModel>((ref) => IncomeModel(
    ref.watch(idleRulesProvider),
    expPerKill: ref.watch(catRulesProvider).expPerKill));

/// The main idle loop (T-034). Cat EXP from waves and bosses is granted to
/// [catProgressProvider] here.
final Provider<IdleLoop> idleLoopProvider = Provider<IdleLoop>((ref) {
  final weights = ref.watch(combatRulesProvider).powerWeights;
  final loop = IdleLoop(
    rules: ref.watch(idleRulesProvider),
    income: ref.watch(incomeModelProvider),
    engineFactory: ref.watch(combatEngineFactoryProvider),
    catSpec: () => ref
        .read(catClassProvider)
        .combatSpec(extra: ref.read(catExtraStatsProvider)()),
    hpWeightPm: weights.hpPm,
    atkWeightPm: weights.atkPm,
    seed: ref.watch(idleSeedProvider),
  );
  final sub = loop.events.listen((e) {
    final exp = switch (e) {
      WaveCleared(:final exp) => exp,
      BossResult(:final exp) => exp,
      WaveFailed() => 0,
    };
    if (exp > 0) ref.read(catProgressProvider).gainExp(exp);
  });
  ref.onDispose(() {
    sub.cancel();
    loop.dispose();
  });
  return loop;
});
