import 'combat.dart';

/// Cat level + class shared types (GDD v0.5 §3). Owner: `cat_class` (T-044).

/// Fired once per [ICatProgress.gainExp] call that raised the level, even if
/// it jumped several levels (offline gains).
class CatLevelUp {
  const CatLevelUp({required this.from, required this.to});
  final int from;
  final int to;

  @override
  bool operator ==(Object other) =>
      other is CatLevelUp && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  String toString() => 'CatLevelUp($from → $to)';
}

/// One class row of `idle_balance_v1.json` → `classes`, already in fixed
/// point. Main stats are multipliers in basis points (14000 = ×1.4); the
/// bonus stats are added as [Attribute]s.
class ClassModifiers {
  const ClassModifiers({
    required this.id,
    required this.tier,
    required this.hpBp,
    required this.atkBp,
    required this.defBp,
    required this.attackIntervalMs,
    required this.range,
    this.from,
    this.bonus = const {},
  });

  final String id;

  /// 0 = novice, 1 = first class, 2 = second class (content v1.1).
  final int tier;

  /// Tier-1 class a tier-2 class grows from.
  final String? from;
  final int hpBp;
  final int atkBp;
  final int defBp;
  final int attackIntervalMs;
  final AttackRange range;

  /// evade (from `evade_add`), skill_dmg (from `skill_dmg` − 1), cdr (from
  /// 1 − `cooldown_mult`).
  final Map<Attribute, int> bonus;
}

/// Save v3 `cat` block (GAME_CONTRACT §4.6).
class CatState {
  const CatState({
    this.level = 1,
    this.exp = 0,
    this.classId = 'novice',
    this.tier = 0,
  });

  final int level;
  final int exp;
  final String classId;
  final int tier;

  Map<String, dynamic> toJson() =>
      {'level': level, 'exp': exp, 'class': classId, 'tier': tier};

  factory CatState.fromJson(Map<String, dynamic> json) {
    T field<T>(String k) {
      final v = json[k];
      if (v is! T) throw FormatException('cat: "$k" missing or wrong type');
      return v;
    }

    return CatState(
      level: field<int>('level'),
      exp: field<int>('exp'),
      classId: field<String>('class'),
      tier: field<int>('tier'),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CatState &&
      other.level == level &&
      other.exp == exp &&
      other.classId == classId &&
      other.tier == tier;

  @override
  int get hashCode => Object.hash(level, exp, classId, tier);

  @override
  String toString() => 'CatState(Lv$level exp $exp $classId t$tier)';
}

/// Cat level and EXP (GDD v0.5 §3.1). Owner: T-044.
abstract class ICatProgress {
  int get level;

  /// EXP into the current level.
  int get exp;

  /// EXP needed to reach the next level (there is no level cap).
  int get expToNext;

  /// Adds EXP (kills, bosses, offline). Returns the levels gained.
  int gainExp(int amount);

  Stream<CatLevelUp> get levelUps;
}

/// Class choice and its modifiers (GDD v0.5 §3.2). Owner: T-044.
abstract class ICatClass {
  /// Id of the current class (`novice` until the first choice).
  String get current;

  /// Classes [choose] accepts right now (empty before Lv10).
  List<ClassModifiers> get available;

  /// Throws [StateError] when not allowed (level, boss fight, tier).
  void choose(String classId);

  ClassModifiers get modifiers;

  /// Class skill slots open (0 for the novice at any level).
  int get skillsUnlocked;
}
