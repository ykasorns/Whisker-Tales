import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ads/ads.dart';
import '../cat/cat.dart';
import '../combat/combat.dart';
import 'clock/game_clock.dart';
import 'contracts/ads.dart';
import 'contracts/age_gate.dart';
import 'contracts/combat.dart';
import 'contracts/idle_loop.dart';
import 'contracts/rewards.dart';
import '../gear/gear.dart';
import '../idle/idle.dart';
import '../offline/offline_reward.dart';
import '../pets/pets.dart';
import '../research/research.dart';
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

/// Buffs (`design/data/buffs.json`). Empty until boot loads it (T-003).
final buffBookProvider = Provider<BuffBook>((ref) => BuffBook.empty);

/// Class skills (`design/data/skills.json`). Empty until boot loads it.
final skillBookProvider = Provider<SkillBook>(
    (ref) => const SkillBook(byClass: {}, firstCastPct: 50));

/// Makes a fresh engine per fight (T-007, T-008).
final combatEngineFactoryProvider = Provider<ICombatEngine Function()>((ref) {
  final rules = ref.watch(combatRulesProvider);
  final buffs = ref.watch(buffBookProvider);
  final first = ref.watch(skillBookProvider).firstCastPct;
  return () => CombatEngine(rules, buffs: buffs, firstCastPct: first);
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
        inBossFight: ref.watch(inBossFightProvider),
        skillsFor: ref.watch(skillBookProvider).skillsFor));

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

/// The cat as it fights right now: class × (level + gear), then road
/// events, the pet passive and research. The idle loop fights with it and
/// the UI shows its power and stats from it, so the two never disagree.
final Provider<CombatUnitSpec Function()> catSpecProvider =
    Provider<CombatUnitSpec Function()>((ref) => () {
          final cat = ref.read(roadEventsProvider).apply(ref
              .read(catClassProvider)
              .combatSpec(extra: ref.read(catExtraStatsProvider)()));
          final withPets = ref.read(petsProvider)?.withPassive(cat) ?? cat;
          return ref.read(researchProvider)?.withBonus(withPets) ?? withPets;
        });

/// The cat's goldfish / EXP find (gear affixes, capped by `caps_pct`) for
/// waves, bosses and offline time.
final findsProvider = Provider<Finds Function()>((ref) {
  final rules = ref.watch(combatRulesProvider);
  final spec = ref.watch(catSpecProvider);
  return () {
    final s = spec().stats;
    return (
      fishBp: rules.proc(Attribute.fishFind, s[Attribute.fishFind], 0),
      expBp: rules.proc(Attribute.expFind, s[Attribute.expFind], 0),
    );
  };
});

/// The main idle loop (T-034). Rewards go to [walletProvider] and cat EXP
/// to [catProgressProvider] here.
final Provider<IdleLoop> idleLoopProvider = Provider<IdleLoop>((ref) {
  final weights = ref.watch(combatRulesProvider).powerWeights;
  final road = ref.watch(roadEventsProvider);
  final loop = IdleLoop(
    rules: ref.watch(idleRulesProvider),
    income: ref.watch(incomeModelProvider),
    engineFactory: ref.watch(combatEngineFactoryProvider),
    catSpec: ref.watch(catSpecProvider),
    partners: (cat) => ref.read(petsProvider)?.partners(cat) ?? const [],
    finds: ref.watch(findsProvider),
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

/// Ad placements + caps (`ads`). Overridden at boot with the loaded rules.
final adRulesProvider = Provider<AdRules>(
    (ref) => throw UnimplementedError('override with loaded AdRules'));

/// The ad SDK seam. A fake until Opus picks a Families-certified SDK.
final adNetworkProvider = Provider<AdNetwork>((ref) => FakeAdNetwork());

/// Age band from the first-launch screen (T-040 overrides this).
final ageBandProvider =
    Provider<AgeBand Function()>((ref) => () => AgeBand.unset);

/// Supporter Pack `no_ads` entitlement (T-025 overrides this).
final noAdsProvider = Provider<bool Function()>((ref) => () => false);

/// Rewarded ads with daily caps (T-039) — every placement goes through here.
final adServiceProvider = Provider<IAdService>((ref) => AdService(
      rules: ref.watch(adRulesProvider),
      network: ref.watch(adNetworkProvider),
      clock: ref.watch(gameClockProvider),
      ageBand: ref.watch(ageBandProvider),
      hasNoAds: ref.watch(noAdsProvider),
    ));

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

/// Offline numbers (`offline`, `research.offline_node_*`). Overridden at boot.
final offlineRulesProvider = Provider<OfflineRules>(
    (ref) => throw UnimplementedError('override with loaded OfflineRules'));

/// Offline rewards (T-035): call `checkIn()` on open/resume, show the
/// result, then `claim()`. Same income formula as online (T-034).
final offlineRewardProvider = Provider<OfflineReward>((ref) => OfflineReward(
      rules: ref.watch(offlineRulesProvider),
      income: ref.watch(incomeModelProvider),
      clock: ref.watch(gameClockProvider),
      wallet: ref.watch(walletProvider),
      farmPage: () => ref.read(idleLoopProvider).state.farmPage,
      grantExp: (exp) => ref.read(catProgressProvider).gainExp(exp),
      offlineCapLevel: () => ref.read(researchProvider)?.offlineCapLevel ?? 0,
      finds: ref.watch(findsProvider),
    ));

/// Pet roster + hatch numbers (`pets`, `pets.json`). Null until boot loads
/// them (T-003) — then the loop simply has no pets.
final petsRulesProvider = Provider<PetsRules?>((ref) => null);

/// Pets and hatching (T-038).
final Provider<Pets?> petsProvider = Provider<Pets?>((ref) {
  final rules = ref.watch(petsRulesProvider);
  if (rules == null) return null;
  return Pets(
    rules: rules,
    wallet: ref.watch(walletProvider),
    ads: () => ref.read(adServiceProvider),
    clock: ref.watch(gameClockProvider),
    clearedPage: () => ref.read(idleLoopProvider).state.clearedPage,
    seed: ref.watch(idleSeedProvider) ^ 0x7E75,
  );
});

/// Library tree + timer numbers (`research`, `research.json`). Null until
/// boot loads them (T-003) — then there is no library.
final researchRulesProvider = Provider<ResearchRules?>((ref) => null);

/// Owl library research (T-041).
final Provider<Research?> researchProvider = Provider<Research?>((ref) {
  final rules = ref.watch(researchRulesProvider);
  if (rules == null) return null;
  final r = Research(
    rules: rules,
    wallet: ref.watch(walletProvider),
    ads: () => ref.read(adServiceProvider),
    clock: ref.watch(gameClockProvider),
  );
  ref.onDispose(r.dispose);
  return r;
});
