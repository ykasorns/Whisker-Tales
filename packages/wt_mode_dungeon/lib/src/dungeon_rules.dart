import 'dart:math' as math;

import 'package:wt_core/wt_core.dart';

class DungeonTier {
  const DungeonTier({required this.damagePct, required this.mult});

  /// Share of the boss's health that must be dealt to reach this tier.
  final int damagePct;
  final int mult;
}

/// `design/data/dungeon.json` (D-065).
class DungeonRules {
  DungeonRules._({
    required this.timeLimitMs,
    required this.freeRunsPerDay,
    required this.adPlacement,
    required this.maxLevel,
    required this.unlockTier,
    required this.pageStart,
    required this.pageStep,
    required this.hpMult,
    required this.atkMult,
    required this.intervalMs,
    required this.tiers,
    required this.cookiesBase,
    required this.cookiesPerLevel,
    required this.bossSprites,
  });

  factory DungeonRules.fromJson(Map<String, dynamic> j) {
    Never bad(String why) => throw FormatException('dungeon.json: $why');
    num n(Map<String, dynamic> m, String k) =>
        m[k] is num ? m[k] as num : bad('"$k" must be a number');
    final boss = j['boss'];
    final rawTiers = j['tiers'];
    if (boss is! Map<String, dynamic>) bad('"boss" must be an object');
    if (rawTiers is! List || rawTiers.isEmpty) bad('"tiers" must be a list');
    final tiers = [
      for (final t in rawTiers.cast<Map<String, dynamic>>())
        DungeonTier(
            damagePct: n(t, 'damage_pct').toInt(), mult: n(t, 'mult').toInt())
    ];
    for (var i = 0; i < tiers.length; i++) {
      if (tiers[i].damagePct <= 0 ||
          tiers[i].damagePct > 100 ||
          tiers[i].mult <= 0 ||
          (i > 0 &&
              (tiers[i].damagePct <= tiers[i - 1].damagePct ||
                  tiers[i].mult < tiers[i - 1].mult))) {
        bad('tiers must rise in damage_pct (1..100) and not fall in mult');
      }
    }
    final unlockTier = n(j, 'unlock_tier').toInt();
    if (unlockTier < 1 || unlockTier > tiers.length) {
      bad('unlock_tier must name a tier');
    }
    final sprites = j['boss_sprites'];
    if (sprites is! List ||
        sprites.isEmpty ||
        sprites.any((s) => s is! String)) {
      bad('"boss_sprites" must be a list of ids');
    }
    return DungeonRules._(
      timeLimitMs: n(j, 'time_limit_ms').toInt(),
      freeRunsPerDay: n(j, 'free_runs_per_day').toInt(),
      adPlacement: j['ad_placement'] as String? ?? bad('needs ad_placement'),
      maxLevel: n(j, 'max_level').toInt(),
      unlockTier: unlockTier,
      pageStart: n(boss, 'page_start').toInt(),
      pageStep: n(boss, 'page_step').toInt(),
      hpMult: n(boss, 'hp_mult'),
      atkMult: n(boss, 'atk_mult'),
      intervalMs: n(boss, 'interval_ms').toInt(),
      tiers: List.unmodifiable(tiers),
      cookiesBase: n(j, 'cookies_base'),
      cookiesPerLevel: n(j, 'cookies_per_level'),
      bossSprites: List.unmodifiable(sprites.cast<String>()),
    );
  }

  final int timeLimitMs;
  final int freeRunsPerDay;
  final String adPlacement;
  final int maxLevel;

  /// Reaching this tier (1-based) on the highest open level opens the next.
  final int unlockTier;
  final int pageStart, pageStep;
  final num hpMult, atkMult;
  final int intervalMs;
  final List<DungeonTier> tiers;
  final num cookiesBase, cookiesPerLevel;
  final List<String> bossSprites;

  /// The farm page whose boss power this level borrows.
  int pageOf(int level) => pageStart + (level - 1) * pageStep;

  /// Boss sprite for [level]: one per equal block of levels .
  String spriteOf(int level) {
    final block = (maxLevel / bossSprites.length).ceil();
    return bossSprites[math.min(bossSprites.length - 1, (level - 1) ~/ block)];
  }

  /// Boss stats from the idle boss formula at [pageOf], so the dungeon uses
  /// the same scale as the farm. HP is [hpMult] times a farm boss because a
  /// fight here lasts 30 seconds, not a minute.
  CombatUnitSpec bossSpec(int level, IdleRules idle, PowerWeights weights) {
    final power = idle.bossPower(pageOf(level));
    final hp = power * idle.hpSharePct * 1000 ~/ (100 * weights.hpPm);
    final atk = power * (100 - idle.hpSharePct) * 1000 ~/ (100 * weights.atkPm);
    return CombatUnitSpec(
      id: 'dungeon_boss',
      side: CombatSide.enemy,
      stats: StatBlock(
        hp: math.max(1, (hp * hpMult).round()),
        atk: math.max(1, (atk * atkMult).round()),
        def: 0,
      ),
      attackIntervalMs: intervalMs,
      isBoss: true,
    );
  }

  /// Highest tier (1-based; 0 = none) for [damage] of a boss with [maxHp].
  int tierFor(int damage, int maxHp) {
    if (maxHp <= 0) return 0;
    var tier = 0;
    for (var i = 0; i < tiers.length; i++) {
      if (damage * 100 >= maxHp * tiers[i].damagePct) tier = i + 1;
    }
    return tier;
  }

  int cookiesFor(int level, int tier) {
    if (tier <= 0) return 0;
    final base = cookiesBase + cookiesPerLevel * (level - 1);
    return (base * tiers[tier - 1].mult).round();
  }
}
