import 'combat.dart';
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
  String? get enemyUnitId;
  IBuffEngine get buffEngine;

  /// Deterministic chance roll in basis points (`0 <= value < 10000`).
  int nextBasisPoint();
}

/// Run lifecycle for run-based modes only — the idle main loop does not use
/// it (D-002). GDD v0.3 §3.2. Owner: T-005.
abstract class IRunManager {
  RunSessionView? get current;
  RunCompletion? get completion;

  void startRun({
    required GameMode mode,
    required ModeSaveState modeState,
    required RunCatSnapshot cat,
    required String dayKey,
  });

  List<Encounter> get nextChoices;
  List<EncounterPreview> preview(int count);
  Encounter? advanceToNextNode({String? routeId});
  RunCompletion? resolveEncounter({required bool survived});
  RunCompletion endRun(RunOutcome outcome);
}

/// Seeded node map for the adventure mode (GDD v0.3 §3.3). Owner: T-006.
abstract class IEncounterGenerator {
  EncounterMap generate(int seed);
}

class EncounterStage {
  EncounterStage({required this.depth, required List<Encounter> choices})
      : choices = List.unmodifiable(choices) {
    if (choices.isEmpty) {
      throw ArgumentError('an encounter stage needs a choice');
    }
    if (choices.any((e) => e.depth != depth)) {
      throw ArgumentError('every choice must use stage depth $depth');
    }
  }

  final int depth;
  final List<Encounter> choices;
}

/// A finite, seeded route. Most stages have one encounter; the stage after a
/// fork has a safe and a risky choice that reconverge afterwards.
class EncounterMap {
  EncounterMap({required this.seed, required List<EncounterStage> stages})
      : stages = List.unmodifiable(stages);

  final int seed;
  final List<EncounterStage> stages;

  int get length => stages.length;
  List<Encounter> choicesAt(int depth) =>
      depth < 0 || depth >= stages.length ? const [] : stages[depth].choices;
}

class RunSessionView {
  const RunSessionView({
    required this.modeId,
    required this.config,
    required this.cat,
    required this.modeState,
    required this.clearedNodes,
    this.encounter,
  });

  final String modeId;
  final RunConfig config;
  final RunCatSnapshot cat;
  final ModeSaveState modeState;
  final int clearedNodes;
  final Encounter? encounter;
}

class RunCompletion {
  const RunCompletion({
    required this.result,
    required this.reward,
    required this.modeState,
  });

  final RunResult result;
  final RewardResult reward;
  final ModeSaveState modeState;
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
