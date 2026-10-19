/// Shared combat types (GDD v0.4 §4, v0.5 §5). The engine lives in `combat`
/// (T-007); these types sit here so `cat_class`, `gear_basket`, `idle_loop`
/// and the UI can build stat blocks and read events without importing it.
///
/// Fixed point: every percentage is in basis points (10000 = 100%). HP, ATK
/// and DEF are plain ints. Nothing here that decides a fight is a `double`
/// (GAME_CONTRACT §5).
library;

/// 100% in basis points.
const int kBp = 10000;

/// Secondary and special stats (GDD v0.5 §5). Values are basis points unless
/// noted. `*Res` / [accuracy] are the anti-stats of the line above them.
enum Attribute {
  crit('crit'),

  /// Bonus crit multiplier on top of the base from data (5000 = +×0.5).
  critDmg('crit_dmg'),
  critRes('crit_res'),
  critDmgRes('crit_dmg_res'),

  /// Chance of one extra hit right after an attack (ตีติด).
  combo('combo'),
  comboRes('combo_res'),

  /// Chance to hit back when struck (สวนกลับ).
  counter('counter'),
  counterRes('counter_res'),
  stun('stun'),
  stunRes('stun_res'),
  evade('evade'),
  accuracy('accuracy'),

  /// Share of damage dealt that heals the attacker.
  lifesteal('lifesteal'),
  lifestealRes('lifesteal_res'),

  /// Share of max HP healed per regen tick.
  regen('regen'),

  /// Shortens the attack interval: interval × 10000 / (10000 + value).
  attackSpeed('attack_speed'),
  skillDmg('skill_dmg'),
  bossDmg('boss_dmg'),
  petDmg('pet_dmg'),
  cdr('cdr'),
  yarnFind('yarn_find'),
  fishFind('fish_find'),
  expFind('exp_find'),
  craftLuck('craft_luck');

  const Attribute(this.key);

  /// Key used in JSON data.
  final String key;

  static Attribute? fromKey(String key) {
    for (final a in values) {
      if (a.key == key) return a;
    }
    return null;
  }
}

/// A unit's final stats after level, class, gear and pets are applied
/// (`cat_class` / `gear_basket` build it; combat only reads it).
class StatBlock {
  StatBlock({
    required this.hp,
    required this.atk,
    required this.def,
    Map<Attribute, int> attrs = const {},
  }) : _attrs = Map.unmodifiable({
          for (final e in attrs.entries)
            if (e.value != 0) e.key: e.value
        });

  final int hp;
  final int atk;
  final int def;
  final Map<Attribute, int> _attrs;

  /// Value of [a], 0 when unset.
  int operator [](Attribute a) => _attrs[a] ?? 0;

  Map<Attribute, int> get attrs => _attrs;

  StatBlock copyWith(
          {int? hp, int? atk, int? def, Map<Attribute, int>? attrs}) =>
      StatBlock(
          hp: hp ?? this.hp,
          atk: atk ?? this.atk,
          def: def ?? this.def,
          attrs: attrs ?? _attrs);

  @override
  bool operator ==(Object other) {
    if (other is! StatBlock ||
        other.hp != hp ||
        other.atk != atk ||
        other.def != def ||
        other._attrs.length != _attrs.length) {
      return false;
    }
    for (final e in _attrs.entries) {
      if (other._attrs[e.key] != e.value) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
      hp,
      atk,
      def,
      Object.hashAllUnordered(
          _attrs.entries.map((e) => Object.hash(e.key, e.value))));

  @override
  String toString() => 'StatBlock(hp: $hp, atk: $atk, def: $def, $_attrs)';
}

enum CombatSide { cat, enemy }

/// Carried for rendering only — the sim does not model distance (D-004:
/// ranged classes attack from where they stand).
enum AttackRange { melee, ranged }

class CombatUnitSpec {
  const CombatUnitSpec({
    required this.id,
    required this.side,
    required this.stats,
    required this.attackIntervalMs,
    this.range = AttackRange.melee,
    this.isPartner = false,
    this.isBoss = false,
  });

  /// Unique within one fight.
  final String id;
  final CombatSide side;
  final StatBlock stats;

  /// Interval before [Attribute.attackSpeed] (class value from `cat_class`).
  final int attackIntervalMs;
  final AttackRange range;

  /// Animal friend on the cat's side: deals [DamageChannel.partner] damage
  /// and cannot be targeted (GDD v0.4 §6.1).
  final bool isPartner;

  /// [Attribute.bossDmg] applies against this unit.
  final bool isBoss;
}

/// Everything a fight needs to start (GDD v0.4 §4).
class CombatSetup {
  const CombatSetup({
    required this.seed,
    required this.units,
    this.timeLimitMs,
  });

  /// Seed for the deterministic sim (GAME_CONTRACT §5 v2.0).
  final int seed;

  /// Order matters: ties in the same millisecond resolve cat side first,
  /// then in list order.
  final List<CombatUnitSpec> units;

  /// The cat side loses when this runs out; null = no limit.
  final int? timeLimitMs;
}

enum HitOutcome { dodge, normal, crit }

/// Separate damage tallies so pet damage can be shown and scaled on its own.
enum DamageChannel { normal, partner, skill }

enum AttackSource { normal, combo, counter }

enum HealCause { lifesteal, regen }

/// Base of every event the sim emits (GDD v0.4 §4). Skill and buff events
/// are added by T-008.
abstract class CombatEvent {
  const CombatEvent();
}

class HitResolved extends CombatEvent {
  const HitResolved({
    required this.atMs,
    required this.attackerId,
    required this.targetId,
    required this.outcome,
    required this.damage,
    required this.targetHp,
    this.channel = DamageChannel.normal,
    this.source = AttackSource.normal,
  });

  final int atMs;
  final String attackerId;
  final String targetId;
  final HitOutcome outcome;

  /// Full hit size, overkill included; 0 on [HitOutcome.dodge]. HP actually
  /// lost is the drop in [targetHp] (what `CombatEngine.damageDealt` sums).
  final int damage;

  /// Target HP after the hit.
  final int targetHp;
  final DamageChannel channel;
  final AttackSource source;

  @override
  bool operator ==(Object other) =>
      other is HitResolved &&
      other.atMs == atMs &&
      other.attackerId == attackerId &&
      other.targetId == targetId &&
      other.outcome == outcome &&
      other.damage == damage &&
      other.targetHp == targetHp &&
      other.channel == channel &&
      other.source == source;

  @override
  int get hashCode => Object.hash(
      atMs, attackerId, targetId, outcome, damage, targetHp, channel, source);

  @override
  String toString() =>
      'HitResolved($atMs $attackerId→$targetId ${outcome.name} $damage '
      'hp=$targetHp ${channel.name} ${source.name})';
}

class UnitHealed extends CombatEvent {
  const UnitHealed({
    required this.atMs,
    required this.unitId,
    required this.amount,
    required this.hp,
    required this.cause,
  });

  final int atMs;
  final String unitId;
  final int amount;

  /// HP after healing.
  final int hp;
  final HealCause cause;

  @override
  bool operator ==(Object other) =>
      other is UnitHealed &&
      other.atMs == atMs &&
      other.unitId == unitId &&
      other.amount == amount &&
      other.hp == hp &&
      other.cause == cause;

  @override
  int get hashCode => Object.hash(atMs, unitId, amount, hp, cause);

  @override
  String toString() =>
      'UnitHealed($atMs $unitId +$amount hp=$hp ${cause.name})';
}

class UnitStunned extends CombatEvent {
  const UnitStunned(
      {required this.atMs, required this.unitId, required this.untilMs});

  final int atMs;
  final String unitId;
  final int untilMs;

  @override
  bool operator ==(Object other) =>
      other is UnitStunned &&
      other.atMs == atMs &&
      other.unitId == unitId &&
      other.untilMs == untilMs;

  @override
  int get hashCode => Object.hash(atMs, unitId, untilMs);

  @override
  String toString() => 'UnitStunned($atMs $unitId until $untilMs)';
}

/// A unit left the fight — no gore, dizzy eyes + smoke only (GDD v0.3 §9.1).
class UnitDefeated extends CombatEvent {
  const UnitDefeated(this.unitId, {this.atMs = 0});
  final String unitId;
  final int atMs;

  @override
  bool operator ==(Object other) =>
      other is UnitDefeated && other.unitId == unitId && other.atMs == atMs;

  @override
  int get hashCode => Object.hash(unitId, atMs);

  @override
  String toString() => 'UnitDefeated($atMs $unitId)';
}

class CombatEnded extends CombatEvent {
  const CombatEnded({required this.playerWon, this.atMs = 0});
  final bool playerWon;
  final int atMs;

  @override
  bool operator ==(Object other) =>
      other is CombatEnded &&
      other.playerWon == playerWon &&
      other.atMs == atMs;

  @override
  int get hashCode => Object.hash(playerWon, atMs);

  @override
  String toString() => 'CombatEnded($atMs won=$playerWon)';
}

/// Shared deterministic combat sim used by every mode (GDD v0.4 §4,
/// GAME_CONTRACT §3 `combat`). Owner: T-007 (engine), T-008 (skills).
abstract class ICombatEngine {
  void start(CombatSetup setup);

  /// Advances the sim by [dtMs] milliseconds of game time. Any split of the
  /// same total time gives the same events.
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
