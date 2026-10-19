import 'dart:math' as math;

import '../core/contracts/cat_class.dart';
import '../core/contracts/combat.dart';

/// `cat_level` + `classes` from `idle_balance_v1.json` (GDD v0.5 §3), turned
/// into ints once. Keys may carry an `ASSUMPTION_` prefix.
///
/// `classes` uses multipliers, not percentages: `hp`/`atk`/`def` ×10000 → bp,
/// `evade_add` ×10000 → evade bp, `skill_dmg` (m − 1) ×10000 → skill_dmg bp,
/// `cooldown_mult` (1 − m) ×10000 → cdr bp.
class CatRules {
  CatRules._({
    required this.classUnlockLevel,
    required this.tier2Level,
    required this.skillSlotLevels,
    required int expBase,
    required List<({int fromLevel, num growth})> expCurve,
    required this.levelGrowthBp,
    required this.baseStats,
    required this.classes,
    required num expPerKillBase,
    required num expPerKillGrowth,
  })  : _expToNextBase = expBase,
        _expCurve = expCurve,
        _expBase = expPerKillBase,
        _expGrowth = expPerKillGrowth;

  final int classUnlockLevel;
  final int tier2Level;
  final List<int> skillSlotLevels;
  final int _expToNextBase;

  /// Growth per level, by level range; sorted, first starts at 1.
  final List<({int fromLevel, num growth})> _expCurve;

  /// Main-stat growth per level above 1, linear: base × (1 + growth × (L−1)).
  final int levelGrowthBp;

  /// Lv1 stats before the class.
  final StatBlock baseStats;

  /// In data order; the first entry with tier 0 is the starting class.
  final List<ClassModifiers> classes;
  final num _expBase;
  final num _expGrowth;

  ClassModifiers get novice => classes.firstWhere((c) => c.tier == 0);

  ClassModifiers? classById(String id) {
    for (final c in classes) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// EXP from [level] to the next one. No level cap (YK 2026-10-19): each
  /// level costs `growth` times the one before, with `growth` taken from the
  /// `exp_curve` range the level falls in. Capped at 2^53 so huge levels stay
  /// exact ints.
  int expToNext(int level) {
    var exp = _expToNextBase.toDouble();
    for (var i = 0; i < _expCurve.length; i++) {
      final from = _expCurve[i].fromLevel;
      if (level <= from) break;
      final to = i + 1 < _expCurve.length ? _expCurve[i + 1].fromLevel : level;
      final steps = (level < to ? level : to) - from;
      exp *= math.pow(_expCurve[i].growth, steps);
      if (exp >= _maxExp) return _maxExp.toInt();
    }
    return exp.round();
  }

  static const double _maxExp = 9007199254740992; // 2^53

  /// EXP for one monster on [page]. The idle loop and offline rewards both
  /// call this so they cannot drift (T-034, T-035).
  int expPerKill(int page) =>
      (_expBase * math.pow(_expGrowth, page < 1 ? 0 : page - 1)).round();

  factory CatRules.fromBalance(Map<String, dynamic> balance) {
    final lv = _map(balance, 'cat_level');
    final curve = _parseExpCurve(lv);
    final stats = _map(lv, 'base_stats');
    final slots = lv['skill_slot_levels'];
    if (slots is! List || slots.any((e) => e is! int)) {
      throw const FormatException(
          'cat_level: "skill_slot_levels" must be ints');
    }
    final classes = [
      for (final e in _map(balance, 'classes').entries)
        if (!e.key.startsWith('_')) _class(e.key, e.value),
    ];
    _checkClasses(classes);
    return CatRules._(
      classUnlockLevel: _int(lv, 'class_unlock_level'),
      tier2Level: _int(lv, 'class_tier2_level'),
      skillSlotLevels: List.unmodifiable(slots.cast<int>()),
      expBase: _int(lv, 'exp_to_next_base'),
      expCurve: curve,
      levelGrowthBp: (_num(lv, 'base_stat_pct_per_level') * kBp).round(),
      baseStats: StatBlock(
          hp: _int(stats, 'hp'),
          atk: _int(stats, 'atk'),
          def: _int(stats, 'def')),
      classes: List.unmodifiable(classes),
      expPerKillBase: _num(lv, 'exp_per_kill_base'),
      expPerKillGrowth: _num(lv, 'exp_per_kill_growth_per_page'),
    );
  }
}

List<({int fromLevel, num growth})> _parseExpCurve(Map<String, dynamic> lv) {
  final raw = lv['exp_curve'] ?? lv['${_assumption}exp_curve'];
  if (raw is! List || raw.isEmpty) {
    throw const FormatException(
        'cat_level: "exp_curve" must be a non-empty list');
  }
  final curve = [
    for (final r in raw)
      if (r is Map<String, dynamic>)
        (
          fromLevel: _int(r, 'from_level', 'cat_level.exp_curve'),
          growth: _num(r, 'growth', 'cat_level.exp_curve'),
        )
      else
        throw const FormatException(
            'cat_level: "exp_curve" entries must be objects'),
  ];
  for (var i = 0; i < curve.length; i++) {
    final ok = i == 0
        ? curve[i].fromLevel == 1
        : curve[i].fromLevel > curve[i - 1].fromLevel;
    if (!ok || curve[i].growth < 1) {
      throw const FormatException(
          'cat_level: "exp_curve" must start at level 1, rise, and have growth >= 1');
    }
  }
  return List.unmodifiable(curve);
}

ClassModifiers _class(String id, Object? raw) {
  if (raw is! Map<String, dynamic>) {
    throw FormatException('classes: "$id" must be an object');
  }
  int bp(String k) => (_num(raw, k, 'classes.$id') * kBp).round();
  final rangeKey = raw['range'];
  final range = AttackRange.values.where((r) => r.name == rangeKey);
  if (range.isEmpty) {
    throw FormatException('classes.$id: unknown range "$rangeKey"');
  }
  final cooldown = raw.containsKey('cooldown_mult') ? bp('cooldown_mult') : kBp;
  final from = raw['from'];
  return ClassModifiers(
    id: id,
    tier: _int(raw, 'tier', 'classes.$id'),
    from: from is String ? from : null,
    hpBp: bp('hp'),
    atkBp: bp('atk'),
    defBp: bp('def'),
    attackIntervalMs:
        (_num(raw, 'attack_interval_s', 'classes.$id') * 1000).round(),
    range: range.first,
    bonus: {
      Attribute.evade: bp('evade_add'),
      Attribute.skillDmg: bp('skill_dmg') - kBp,
      Attribute.cdr: kBp - cooldown,
    },
  );
}

void _checkClasses(List<ClassModifiers> classes) {
  if (classes.where((c) => c.tier == 0).length != 1) {
    throw const FormatException('classes: need exactly one tier-0 class');
  }
  for (final c in classes) {
    if (c.tier < 0 || c.tier > 2) {
      throw FormatException('classes.${c.id}: tier must be 0, 1 or 2');
    }
    if (c.tier == 2 && !classes.any((p) => p.id == c.from && p.tier == 1)) {
      throw FormatException(
          'classes.${c.id}: tier 2 needs "from" a tier-1 class');
    }
  }
}

const _assumption = 'ASSUMPTION_';

num _num(Map<String, dynamic> m, String key, [String where = 'cat_level']) {
  final v = m[key] ?? m['$_assumption$key'];
  if (v is! num) throw FormatException('$where: "$key" must be a number');
  return v;
}

int _int(Map<String, dynamic> m, String key, [String where = 'cat_level']) {
  final v = m[key] ?? m['$_assumption$key'];
  if (v is! int) throw FormatException('$where: "$key" must be an integer');
  return v;
}

Map<String, dynamic> _map(Map<String, dynamic> m, String key) {
  final v = m[key] ?? m['$_assumption$key'];
  if (v is! Map<String, dynamic>) {
    throw FormatException('"$key" must be an object');
  }
  return v;
}
