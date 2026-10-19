import '../core/contracts/combat.dart';
import 'fixed_point.dart';

/// Combat numbers from `design/balance/idle_balance_v1.json` → `combat`
/// (GDD v0.4 §4.2, §15.2). Percentages become basis points here, once.
///
/// A key may also appear as `ASSUMPTION_<key>` (a value the GDD has not
/// fixed yet); both spellings load the same way.
class CombatRules {
  const CombatRules({
    required this.defFloorBp,
    required this.critMultMinBp,
    required this.baseCritDmgBp,
    required this.capsBp,
    required this.stunMs,
    required this.regenTickMs,
    required this.powerWeights,
  });

  /// `base = max(ATK − DEF, ATK × floor)`.
  final int defFloorBp;

  /// Crit multiplier never goes below this.
  final int critMultMinBp;

  /// Crit multiplier before [Attribute.critDmg].
  final int baseCritDmgBp;

  /// Upper limit per proc stat; a missing entry means no cap.
  final Map<Attribute, int> capsBp;
  final int stunMs;
  final int regenTickMs;
  final PowerWeights powerWeights;

  /// Cap of [a] in basis points.
  int cap(Attribute a) => capsBp[a] ?? kBp;

  /// Chance or share `clamp(stat − anti, 0, cap)` (GDD v0.4 §4.2).
  int proc(Attribute a, int stat, int anti) => clampInt(stat - anti, 0, cap(a));

  /// Parses the `combat` section.
  factory CombatRules.fromJson(Map<String, dynamic> json) {
    final caps = _map(json, 'caps_pct');
    return CombatRules(
      defFloorBp: bpFromPct(_num(json, 'def_floor_pct')),
      critMultMinBp: bpFromPct(_num(json, 'crit_mult_min_pct')),
      baseCritDmgBp: bpFromPct(_num(json, 'base_crit_dmg_pct')),
      capsBp: {
        for (final k in caps.keys.where((k) => !k.startsWith('_')))
          _attr(_bare(k), 'caps_pct'): bpFromPct(_num(caps, _bare(k))),
      },
      stunMs: _num(json, 'stun_ms').round(),
      regenTickMs: _positive(json, 'regen_tick_ms'),
      powerWeights: PowerWeights.fromJson(_map(json, 'power_weights')),
    );
  }

  /// Parses the whole balance file and picks its `combat` section.
  factory CombatRules.fromBalance(Map<String, dynamic> balance) =>
      CombatRules.fromJson(_map(balance, 'combat'));
}

/// §15.2 weights in per-mille (1.2 → 1200).
class PowerWeights {
  const PowerWeights({
    required this.atkPm,
    required this.hpPm,
    required this.defPm,
    required this.attrPm,
  });

  final int atkPm;
  final int hpPm;
  final int defPm;
  final Map<Attribute, int> attrPm;

  factory PowerWeights.fromJson(Map<String, dynamic> json) {
    int pm(String k) => (_num(json, k) * 1000).round();
    const base = {'atk', 'hp', 'def'};
    return PowerWeights(
      atkPm: pm('atk'),
      hpPm: pm('hp'),
      defPm: pm('def'),
      attrPm: {
        for (final k in json.keys
            .where((k) => !k.startsWith('_') && !base.contains(_bare(k))))
          _attr(_bare(k), 'power_weights'): pm(_bare(k)),
      },
    );
  }
}

const _assumption = 'ASSUMPTION_';

String _bare(String k) =>
    k.startsWith(_assumption) ? k.substring(_assumption.length) : k;

num _num(Map<String, dynamic> m, String key) {
  final v = m[key] ?? m['$_assumption$key'];
  if (v is! num) {
    throw FormatException('combat: "$key" must be a number, got $v');
  }
  return v;
}

int _positive(Map<String, dynamic> m, String key) {
  final v = _num(m, key).round();
  if (v <= 0) throw FormatException('combat: "$key" must be > 0, got $v');
  return v;
}

Map<String, dynamic> _map(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! Map<String, dynamic>) {
    throw FormatException('combat: "$key" must be an object');
  }
  return v;
}

Attribute _attr(String key, String where) =>
    Attribute.fromKey(key) ??
    (throw FormatException('combat: unknown stat "$key" in $where'));
