import 'dart:async';
import 'dart:math' as math;

import 'package:wt_core/wt_core.dart';

import 'dungeon_mode.dart';
import 'dungeon_rules.dart';

/// What one dungeon run paid.
class DungeonResult {
  const DungeonResult({
    required this.level,
    required this.damage,
    required this.bossMaxHp,
    required this.tier,
    required this.cookies,
    required this.unlockedNext,
    required this.bossDefeated,
  });

  final int level;
  final int damage;
  final int bossMaxHp;

  /// 0 = none; 1-based tier reached.
  final int tier;
  final int cookies;
  final bool unlockedNext;
  final bool bossDefeated;

  double get fraction =>
      bossMaxHp == 0 ? 0 : (damage / bossMaxHp).clamp(0.0, 1.0);
}

/// One run: the cat side against one boss for [DungeonRules.timeLimitMs] of
/// game time. The run is used up when it starts (quitting cannot re-roll a
/// bad one) and pays what was dealt, whenever it ends.
class DungeonController {
  DungeonController({
    required this.mode,
    required DungeonSave save,
    required this.cat,
    required this.partners,
    required this.idle,
    required this.powerScore,
    required this.engineFactory,
    required this.wallet,
    required this.dayKey,
    required this.adsWatchedToday,
    required this.onSave,
  }) : _save = save;

  final DungeonMode mode;
  final CombatUnitSpec cat;
  final List<CombatUnitSpec> partners;
  final IdleRules idle;
  final PowerScore powerScore;
  final ICombatEngine Function() engineFactory;
  final IWallet wallet;
  final String dayKey;

  /// Ads watched today for the entry placement (the ad service counts them).
  final int Function() adsWatchedToday;
  final void Function(DungeonSave) onSave;

  DungeonSave _save;
  DungeonSave get save => _save;
  DungeonRules get rules => mode.rules;

  ICombatEngine? _engine;
  StreamSubscription<CombatEvent>? _sub;
  int _elapsed = 0;
  int level = 1;
  DungeonResult? result;

  /// New hits for the scene to float, newest last (capped).
  final hits = <({int serial, bool onCat, int damage, HitOutcome outcome})>[];
  int _serial = 0;

  bool get running => _engine != null && result == null;
  int get elapsedMs => _elapsed;
  int get remainingMs => math.max(0, rules.timeLimitMs - _elapsed);
  List<UnitView> get view => _engine?.view ?? const [];

  UnitView? get boss {
    for (final u in view) {
      if (u.id == 'dungeon_boss') return u;
    }
    return null;
  }

  int get entriesLeft => mode.entriesLeft(_save, dayKey, adsWatchedToday());

  bool canStart(int level) =>
      !running &&
      level >= 1 &&
      level <= _save.unlocked &&
      level <= rules.maxLevel &&
      entriesLeft > 0;

  /// Starts a run at [lvl]: the entry is spent now. False when not allowed.
  bool start(int lvl) {
    if (!canStart(lvl)) return false;
    level = lvl;
    result = null;
    hits.clear();
    _elapsed = 0;
    _save = _save.copyWith(day: dayKey, runsToday: _save.usedOn(dayKey) + 1);
    onSave(_save);
    final engine = engineFactory();
    _engine = engine;
    _sub = engine.events.listen(_onEvent);
    engine.start(CombatSetup(
      seed: mixSeed([0xD06E, dayKey.hashCode, _save.runsToday, lvl]),
      units: [
        cat,
        ...partners,
        rules.bossSpec(lvl, idle, powerScore.weights),
      ],
      timeLimitMs: rules.timeLimitMs,
    ));
    return true;
  }

  void _onEvent(CombatEvent e) {
    if (e is HitResolved) {
      hits.add((
        serial: ++_serial,
        onCat: e.targetId == cat.id,
        damage: e.damage,
        outcome: e.outcome,
      ));
      if (hits.length > 8) hits.removeAt(0);
    } else if (e is CombatEnded && result == null) {
      // the fight is over (boss down, cat down or time): pay on the next tick
      _over = true;
    }
  }

  bool _over = false;

  /// Advances the run by [ms] of game time; finishes it at the limit.
  void tick(int ms) {
    final engine = _engine;
    if (engine == null || result != null) return;
    final step = math.min(ms, rules.timeLimitMs - _elapsed);
    if (step > 0) {
      engine.tick(step);
      _elapsed += step;
    }
    if (_over || _elapsed >= rules.timeLimitMs) finish();
  }

  /// Ends the run now and pays what was dealt (leaving, or the app going to
  /// the background). Safe to call twice.
  DungeonResult? finish() {
    final engine = _engine;
    if (engine == null) return null;
    if (result != null) return result;
    final b = boss;
    final maxHp = b?.maxHp ?? 0;
    final defeated = b != null && !b.alive;
    final damage = b == null ? 0 : (defeated ? maxHp : maxHp - b.hp);
    final tier = rules.tierFor(damage, maxHp);
    final cookies = rules.cookiesFor(level, tier);
    if (cookies > 0) wallet.add(RewardBundle({Currency.cookies: cookies}));
    final best = Map<int, int>.of(_save.bestTier);
    if (tier > (best[level] ?? 0)) best[level] = tier;
    final opens = tier >= rules.unlockTier &&
        level == _save.unlocked &&
        _save.unlocked < rules.maxLevel;
    _save = _save.copyWith(
      bestTier: best,
      unlocked: opens ? _save.unlocked + 1 : _save.unlocked,
    );
    onSave(_save);
    _sub?.cancel();
    _sub = null;
    return result = DungeonResult(
      level: level,
      damage: damage,
      bossMaxHp: maxHp,
      tier: tier,
      cookies: cookies,
      unlockedNext: opens,
      bossDefeated: defeated,
    );
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
  }
}
