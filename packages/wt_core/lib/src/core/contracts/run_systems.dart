import 'game_mode.dart';

/// Effect triggers from GAME_CONTRACT §4.5 (adventure mode relics/talents).
enum EffectTrigger {
  passive,
  onAttack,
  onCrit,
  onDodge,
  onSkill,
  onCombatEnd,
  onLevelUp
}

/// What an effect needs to know when it fires (GDD v0.3 §5–§6); extended by
/// T-010/T-013.
abstract class EffectContext {
  String get ownerUnitId;
}

/// Run lifecycle for run-based modes only — the idle main loop does not use
/// it (D-002). GDD v0.3 §3.2. Owner: T-005.
abstract class IRunManager {
  void startRun(String catId);
  void advanceToNextNode();
  void endRun(RunResult result);
}

/// Seeded node map for the adventure mode (GDD v0.3 §3.3). Owner: T-006.
abstract class IEncounterGenerator {
  List<Encounter> generate(int seed);
}

/// Relics held during a run; effects resolve to buffs (GDD v0.3 §6,
/// GAME_CONTRACT §4.7). Owner: T-010.
abstract class IItemSystem {
  void addRelic(String id);
  void resolve(EffectTrigger trigger, EffectContext ctx);
}

class SynergyActivated {
  const SynergyActivated(this.relicA, this.relicB);
  final String relicA;
  final String relicB;
}

/// Relic pairs that combo (GDD v0.3 §6.2). Owner: T-011.
abstract class ISynergyResolver {
  List<(String, String)> get activePairs;
  Stream<SynergyActivated> get activations;
}

class LevelUp {
  const LevelUp(this.level);
  final int level;
}

/// In-run XP and talent picks (GDD v0.3 §4.3, §5). Owner: T-012/T-013.
abstract class ITalentSystem {
  void gainXp(int amount);
  Stream<LevelUp> get levelUps;

  /// Three talent ids weighted by trees picked earlier.
  List<String> pickOptions();

  void resolve(EffectTrigger trigger, EffectContext ctx);
}
