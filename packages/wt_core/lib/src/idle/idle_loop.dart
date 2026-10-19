import 'dart:async';

import '../core/contracts/combat.dart';
import '../core/contracts/idle_loop.dart';
import '../core/contracts/rewards.dart';
import 'idle_rules.dart';
import 'income_model.dart';
import 'page_plan.dart';

enum IdlePhase { walking, fighting, resting, boss }

/// Extension points for road events (T-048, GDD v0.5.2 §9.2). The loop only
/// calls them; event logic lives elsewhere.
class IdleHooks {
  const IdleHooks({
    this.onWalkBetweenWaves,
    this.onWaveCleared,
    this.onBossEnded,
    this.canAutoChallenge,
  });

  /// The cat starts walking to the next fight.
  final void Function()? onWalkBetweenWaves;
  final void Function(int page, int waveIndex)? onWaveCleared;

  /// A boss fight ended; it counts as one wave of event duration.
  final void Function(bool won)? onBossEnded;

  /// AUTO boss waits while this is false (e.g. a debuff is active).
  final bool Function()? canAutoChallenge;
}

/// The main idle loop (GDD v0.4 §2, v0.5.2 §9): walk → wave → walk … on the
/// farm page; once a page's planned waves are done its boss can be fought.
/// Losing costs nothing: the cat rests and tries again, and after a few
/// losses in a row it farms one page back.
///
/// Driven by [tick] with game time (the caller applies the speed button).
/// Every fight is seeded from (seed, page, wave, attempt), so the same seed
/// and the same calls give the same events.
class IdleLoop implements IIdleLoop {
  IdleLoop({
    required this.rules,
    required this.income,
    required this.engineFactory,
    required this.catSpec,
    required this.hpWeightPm,
    required this.atkWeightPm,
    this.seed = 0,
    this.hooks = const IdleHooks(),
  });

  final IdleRules rules;
  final IncomeModel income;
  final ICombatEngine Function() engineFactory;

  /// The cat's current fight stats (class, level, gear, buffs).
  final CombatUnitSpec Function() catSpec;

  /// §15.2 power weights, used to turn wave power back into HP and ATK.
  final int hpWeightPm;
  final int atkWeightPm;
  final int seed;
  IdleHooks hooks;

  final _events = StreamController<IdleEvent>.broadcast(sync: true);
  final _remMilli = <Currency, int>{};

  int _cleared = 0;
  int _farmPage = 1;
  int _waveIndex = 0;
  int _attempt = 0;
  int _lossStreak = 0;
  int _autoBossWait = 0;
  IdlePhase _phase = IdlePhase.walking;
  late int _phaseLeftMs = rules.walkMs;

  ICombatEngine? _engine;
  StreamSubscription<CombatEvent>? _sub;
  int _fightElapsed = 0;
  CombatEnded? _ended;
  int _fightMonsters = 0;
  Completer<BossResult>? _bossRequest;

  /// AUTO boss button (GDD v0.5 §1).
  bool autoBoss = false;

  @override
  IdleProgress get state => IdleProgress(
      book: rules.bookOf(_cleared + 1),
      clearedPage: _cleared,
      farmPage: _farmPage);

  @override
  Stream<IdleEvent> get events => _events.stream;

  IdlePhase get phase => _phase;

  /// Waves cleared on the farm page since arriving there.
  int get waveIndex => _waveIndex;

  PagePlan get plan => pagePlan(rules, _farmPage);

  bool get isBossFight => _phase == IdlePhase.boss;

  /// Boss of `clearedPage + 1` can be fought: on that page with its planned
  /// waves done.
  bool get bossReady => _farmPage == _cleared + 1 && _waveIndex >= plan.waves;

  /// Highest page up to the frontier the cat is strong enough to farm
  /// (`farm_min_power_ratio`, GDD v0.4 §15).
  int recommendedFarmPage(int catPower) {
    for (var p = _cleared + 1; p > 1; p--) {
      if (catPower >= rules.farmMinPowerRatio * rules.wavePower(p)) return p;
    }
    return 1;
  }

  /// Loads saved progress (Save v3 `idle.cleared_page`).
  void restore({required int clearedPage}) {
    if (clearedPage < 0) {
      throw FormatException('idle: cleared_page $clearedPage');
    }
    _endFight();
    _cleared = clearedPage;
    _farmPage = clearedPage + 1;
    _waveIndex = 0;
    _attempt = 0;
    _lossStreak = 0;
    _autoBossWait = 0;
    _remMilli.clear();
    _walk();
  }

  /// Farms another page (1 … frontier). Takes effect from the next wave.
  void setFarmPage(int page) {
    if (page < 1 || page > _cleared + 1) {
      throw RangeError.range(page, 1, _cleared + 1, 'page');
    }
    if (isBossFight) throw StateError('cannot change page during a boss fight');
    if (page == _farmPage) return;
    _farmPage = page;
    _waveIndex = 0;
    _attempt = 0;
    _lossStreak = 0;
  }

  /// Starts the boss after the current fight (or now, between fights).
  @override
  Future<BossResult> challengeBoss() {
    if (isBossFight) return _bossRequest!.future;
    if (!bossReady) {
      return Future.error(StateError('boss not ready: clear the page waves'));
    }
    final request = _bossRequest ??= Completer<BossResult>();
    if (_phase == IdlePhase.walking || _phase == IdlePhase.resting) {
      _startBoss();
    }
    return request.future;
  }

  void tick(int dtMs) {
    if (dtMs < 0) throw ArgumentError.value(dtMs, 'dtMs', 'must be >= 0');
    var left = dtMs;
    while (left > 0) {
      switch (_phase) {
        case IdlePhase.walking:
        case IdlePhase.resting:
          final use = left < _phaseLeftMs ? left : _phaseLeftMs;
          _phaseLeftMs -= use;
          left -= use;
          if (_phaseLeftMs == 0) {
            _phase == IdlePhase.resting ? _walk() : _startNextFight();
          }
        case IdlePhase.fighting:
        case IdlePhase.boss:
          final before = _fightElapsed;
          _engine!.tick(left);
          final ended = _ended;
          if (ended == null) {
            _fightElapsed += left;
            left = 0;
          } else {
            left -= ended.atMs - before;
            _finishFight(ended.playerWon);
          }
      }
    }
  }

  Future<void> dispose() async {
    _endFight();
    await _events.close();
  }

  void _walk() {
    _phase = IdlePhase.walking;
    _phaseLeftMs = rules.walkMs;
    hooks.onWalkBetweenWaves?.call();
  }

  void _rest() {
    _phase = IdlePhase.resting;
    _phaseLeftMs = rules.faintRestMs;
  }

  void _startNextFight() {
    final auto = autoBoss &&
        bossReady &&
        _autoBossWait == 0 &&
        (hooks.canAutoChallenge?.call() ?? true);
    if (_bossRequest != null && bossReady) {
      _startBoss();
    } else if (auto) {
      _bossRequest = Completer<BossResult>();
      _startBoss();
    } else {
      _startWave();
    }
  }

  void _startWave() {
    final k = plan.monstersIn(_waveIndex);
    _fightMonsters = k;
    final power = rules.wavePower(_farmPage);
    _startFight(
      IdlePhase.fighting,
      CombatSetup(
        seed: mixSeed([seed, _farmPage, _waveIndex, _attempt]),
        units: [
          catSpec(),
          for (var i = 0; i < k; i++)
            _monster('m$i', power, k, rules.monsterIntervalMs, boss: false),
        ],
      ),
    );
  }

  void _startBoss() {
    final page = _cleared + 1;
    _startFight(
      IdlePhase.boss,
      CombatSetup(
        seed: mixSeed([seed, page, -1, _attempt]),
        units: [
          catSpec(),
          _monster('boss', rules.bossPower(page), 1, rules.bossIntervalMs,
              boss: true),
        ],
        timeLimitMs: rules.bossTimeLimitMs,
      ),
    );
  }

  /// One of [count] monsters sharing [power]: HP:ATK split by `hp_share`,
  /// turned back into stats with the §15.2 weights.
  CombatUnitSpec _monster(String id, int power, int count, int intervalMs,
      {required bool boss}) {
    final hp = power * rules.hpSharePct * 1000 ~/ (100 * hpWeightPm * count);
    final atk =
        power * (100 - rules.hpSharePct) * 1000 ~/ (100 * atkWeightPm * count);
    return CombatUnitSpec(
      id: id,
      side: CombatSide.enemy,
      stats: StatBlock(hp: hp < 1 ? 1 : hp, atk: atk < 1 ? 1 : atk, def: 0),
      attackIntervalMs: intervalMs,
      isBoss: boss,
    );
  }

  void _startFight(IdlePhase phase, CombatSetup setup) {
    _endFight();
    final engine = engineFactory();
    _sub = engine.events.listen((e) {
      if (e is CombatEnded) _ended = e;
    });
    _engine = engine;
    _fightElapsed = 0;
    _phase = phase;
    engine.start(setup);
  }

  void _endFight() {
    _sub?.cancel();
    _sub = null;
    _engine = null;
    _ended = null;
  }

  void _finishFight(bool won) {
    final wasBoss = _phase == IdlePhase.boss;
    _endFight();
    if (wasBoss) {
      _finishBoss(won);
    } else if (won) {
      _finishWave();
    } else {
      _failWave();
    }
  }

  void _finishWave() {
    final page = _farmPage, index = _waveIndex;
    final reward = _pay(page);
    _waveIndex++;
    _attempt = 0;
    _lossStreak = 0;
    if (_autoBossWait > 0) _autoBossWait--;
    _events.add(WaveCleared(
      page: page,
      waveIndex: index,
      reward: reward,
      exp: _fightMonsters * income.expPerKill(page),
    ));
    hooks.onWaveCleared?.call(page, index);
    _walk();
  }

  void _failWave() {
    _events.add(WaveFailed(page: _farmPage, waveIndex: _waveIndex));
    _attempt++;
    _lossStreak++;
    if (_lossStreak >= rules.retreatAfterLosses && _farmPage > 1) {
      _farmPage--;
      _waveIndex = 0;
      _attempt = 0;
      _lossStreak = 0;
    }
    _rest();
  }

  void _finishBoss(bool won) {
    final page = _cleared + 1;
    final BossResult result;
    if (won) {
      final fish = rules.perWaveMilli(page)[Currency.goldfish]! *
          rules.bossFishWaves ~/
          1000;
      result = BossResult(
        page: page,
        won: true,
        reward: RewardBundle({
          Currency.goldfish: fish,
          Currency.eggs: rules.isChapterBoss(page)
              ? rules.eggChapterBoss
              : rules.eggPageBoss,
        }),
        exp: rules.bossExpKills * income.expPerKill(page),
      );
      _cleared = page;
      _farmPage = page + 1;
      _waveIndex = 0;
      _autoBossWait = 0;
      _attempt = 0;
    } else {
      result = BossResult(page: page, won: false, reward: RewardBundle.empty);
      _autoBossWait = rules.autoBossRetryWaves;
      _attempt++;
    }
    final request = _bossRequest;
    _bossRequest = null;
    _events.add(result);
    request?.complete(result);
    hooks.onBossEnded?.call(won);
    won ? _walk() : _rest();
  }

  /// Adds one wave of income in thousandths and pays out whole units.
  RewardBundle _pay(int page) {
    final paid = <Currency, int>{};
    for (final e in rules.perWaveMilli(page).entries) {
      final total = (_remMilli[e.key] ?? 0) + e.value;
      paid[e.key] = total ~/ 1000;
      _remMilli[e.key] = total % 1000;
    }
    return RewardBundle(paid);
  }
}
