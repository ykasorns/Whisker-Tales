/// Everything a fight needs to start (GDD v0.4 §4); fields are defined by
/// `combat` (T-007).
abstract class CombatSetup {
  /// Seed for the deterministic sim (GAME_CONTRACT §5 v2.0).
  int get seed;
}

/// Base of every event the sim emits (GDD v0.4 §4). Concrete events (hits, crits, dodges,
/// buffs) are added by `combat` (T-007/T-008).
abstract class CombatEvent {
  const CombatEvent();
}

/// A unit left the fight — no gore, dizzy eyes + smoke only (GDD v0.3 §9.1).
class UnitDefeated extends CombatEvent {
  const UnitDefeated(this.unitId);
  final String unitId;
}

class CombatEnded extends CombatEvent {
  const CombatEnded({required this.playerWon});
  final bool playerWon;
}

/// Shared deterministic combat sim used by every mode (GDD v0.4 §4,
/// GAME_CONTRACT §3 `combat`). Owner: T-007 (engine), T-008 (skills).
abstract class ICombatEngine {
  void start(CombatSetup setup);

  /// Advances the sim by [dtMs] milliseconds of game time.
  void tick(int dtMs);

  Stream<CombatEvent> get events;

  /// Casts the skill in [slotIndex]; ignored while on cooldown (GDD v0.4 §5).
  void useSkill(int slotIndex);
}

/// Data-driven buffs (GDD v0.4 §4.3, GAME_CONTRACT §4.7). Relics and talents
/// resolve to buff ids and go through here. Owner: T-008.
abstract class IBuffEngine {
  void apply(String unitId, String buffId, {required String sourceId});
}
