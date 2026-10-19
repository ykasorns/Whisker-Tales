import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../cat/cat.dart';
import '../combat/combat.dart';
import 'clock/game_clock.dart';
import 'contracts/ads.dart';
import 'contracts/combat.dart';
import 'contracts/idle_loop.dart';
import 'contracts/rewards.dart';
import '../gear/gear.dart';
import '../idle/idle.dart';
import '../wardrobe/wardrobe.dart';
import 'contracts/wallet.dart';
import 'wallet/memory_wallet.dart';
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

/// Flat stats added to the cat before the class multiplier. Gear for now;
/// pets, research and road-event buffs add theirs here when they land.
final catExtraStatsProvider = Provider<StatBlock Function()>(
    (ref) => () => ref.read(gearBasketProvider).totalStats);

/// Player currencies. In memory until `meta_progression` (T-021) owns them;
/// a new game starts with the starter yarn (D-011).
final walletProvider = Provider<IWallet>((ref) =>
    MemoryWallet({Currency.yarn: ref.watch(idleRulesProvider).starterYarn}));

/// Gear + basket numbers (`gear`, `basket`, `slot_unlocks`,
/// `gear_slots.json`). Overridden at boot with the loaded rules (T-003).
final gearRulesProvider = Provider<GearRules>(
    (ref) => throw UnimplementedError('override with loaded GearRules'));

/// Yarn basket (T-036).
final Provider<GearBasket> gearBasketProvider = Provider<GearBasket>((ref) {
  final power = ref.watch(powerScoreProvider);
  return GearBasket(
    rules: ref.watch(gearRulesProvider),
    wallet: ref.watch(walletProvider),
    clearedPage: () => ref.read(idleLoopProvider).state.clearedPage,
    powerOf: power.of,
    seed: ref.watch(idleSeedProvider) ^ 0x6EA2,
    unlockStyle: (id) => ref.read(wardrobeProvider).unlock(id),
  );
});

/// Auto-craft (T-037) — call `tick` only while the game is open.
final autoCraftProvider = Provider<AutoCraft>((ref) {
  final auto =
      AutoCraft(ref.watch(gearBasketProvider), ref.watch(walletProvider));
  ref.onDispose(auto.dispose);
  return auto;
});

/// The one income formula for online and offline (T-034, T-035).
final incomeModelProvider = Provider<IncomeModel>((ref) => IncomeModel(
    ref.watch(idleRulesProvider),
    expPerKill: ref.watch(catRulesProvider).expPerKill));

/// The main idle loop (T-034). Rewards go to [walletProvider] and cat EXP
/// to [catProgressProvider] here.
final Provider<IdleLoop> idleLoopProvider = Provider<IdleLoop>((ref) {
  final weights = ref.watch(combatRulesProvider).powerWeights;
  final road = ref.watch(roadEventsProvider);
  final loop = IdleLoop(
    rules: ref.watch(idleRulesProvider),
    income: ref.watch(incomeModelProvider),
    engineFactory: ref.watch(combatEngineFactoryProvider),
    catSpec: () => road.apply(ref
        .read(catClassProvider)
        .combatSpec(extra: ref.read(catExtraStatsProvider)())),
    hpWeightPm: weights.hpPm,
    atkWeightPm: weights.atkPm,
    seed: ref.watch(idleSeedProvider),
    hooks: road.hooks,
  );
  final sub = loop.events.listen((e) {
    final (reward, exp) = switch (e) {
      WaveCleared(:final reward, :final exp) => (reward, exp),
      BossResult(:final reward, :final exp) => (reward, exp),
      WaveFailed() => (RewardBundle.empty, 0),
    };
    if (!reward.isEmpty) ref.read(walletProvider).add(reward);
    if (exp > 0) ref.read(catProgressProvider).gainExp(exp);
  });
  ref.onDispose(() {
    sub.cancel();
    loop.dispose();
  });
  return loop;
});

/// Wardrobe catalog (`design/data/wardrobe.json`). Overridden at boot (T-003).
final wardrobeRulesProvider = Provider<WardrobeRules>(
    (ref) => throw UnimplementedError('override with loaded WardrobeRules'));

/// Looks, collection book and skins (T-045). Reads gear lazily.
final Provider<Wardrobe> wardrobeProvider = Provider<Wardrobe>((ref) =>
    Wardrobe(ref.watch(wardrobeRulesProvider),
        equipped: (slot) => ref.read(gearBasketProvider).equipped(slot),
        clearedPage: () => ref.read(idleLoopProvider).state.clearedPage));

/// Rewarded ads (T-039). Until the ads module lands nothing can be watched.
final adServiceProvider = Provider<IAdService>(
    (ref) => throw UnimplementedError('ads module (T-039) not wired yet'));

/// Road-event numbers + events (`road_events`, `road_events.json`).
/// Overridden at boot with the loaded rules (T-003).
final roadEventRulesProvider = Provider<RoadEventRules>(
    (ref) => throw UnimplementedError('override with loaded RoadEventRules'));

/// Road events (T-048) — plugged into the idle loop's hooks.
final roadEventsProvider = Provider<RoadEvents>((ref) {
  final r = RoadEvents(
    rules: ref.watch(roadEventRulesProvider),
    idleRules: ref.watch(idleRulesProvider),
    wallet: ref.watch(walletProvider),
    ads: () => ref.read(adServiceProvider),
    seed: ref.watch(idleSeedProvider),
  );
  ref.onDispose(r.dispose);
  return r;
});
