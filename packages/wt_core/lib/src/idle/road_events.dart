import 'dart:async';

import '../core/contracts/ads.dart';
import '../core/contracts/combat.dart';
import '../core/contracts/idle_loop.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';
import '../core/random/seeded_rng.dart';
import 'idle_loop.dart';
import 'idle_rules.dart';

/// Ad placement for road events (idle_balance_v1.json `ads.placements`).
const roadEventPlacement = 'road_event';

/// One effect of a road event: a cat stat in % or a wave-reward multiplier.
class RoadEffect {
  const RoadEffect.stat(this.stat, this.pct)
      : reward = null,
        multPct = 100;
  const RoadEffect.reward(this.reward, this.multPct)
      : stat = null,
        pct = 0;

  /// `atk` / `hp` / `def` (relative %), `evade` (percentage points),
  /// `attack_speed` (relative attack rate).
  final String? stat;
  final int pct;
  final Currency? reward;
  final int multPct;
}

class RoadEventDef {
  const RoadEventDef({
    required this.id,
    required this.kind,
    required this.effects,
    required this.waves,
    this.instantFishWaves = 0,
    this.icon = '✨',
  });
  final String id;

  /// Shown on the road and on the effect chip.
  final String icon;
  final RoadEventKind kind;
  final List<RoadEffect> effects;
  final int waves;

  /// Paid at once: goldfish worth this many waves of income.
  final int instantFishWaves;
  bool get isInstant => instantFishWaves > 0;
}

/// `road_events` (balance) + `design/data/road_events.json`. Refuses any
/// bad event stronger or longer than the D-008 limits.
class RoadEventRules {
  const RoadEventRules({
    required this.everyWaves,
    required this.goodPct,
    required this.maxActive,
    required this.adBoostMult,
    required this.events,
  });

  final (int, int) everyWaves;
  final int goodPct;
  final int maxActive;
  final int adBoostMult;
  final List<RoadEventDef> events;

  static const _stats = {'atk', 'hp', 'def', 'evade', 'attack_speed'};

  factory RoadEventRules.fromJson(
      Map<String, dynamic> balance, Map<String, dynamic> data) {
    final b = balance['road_events'];
    if (b is! Map<String, dynamic>) {
      throw const FormatException('balance: "road_events" must be an object');
    }
    int i(String k) {
      final v = b[k] ?? b['ASSUMPTION_$k'];
      if (v is! int) throw FormatException('road_events: "$k" must be an int');
      return v;
    }

    final every = b['every_waves'] ?? b['ASSUMPTION_every_waves'];
    if (every is! List || every.length != 2 || every.any((e) => e is! int)) {
      throw const FormatException(
          'road_events: "every_waves" must be [min, max]');
    }
    final maxDebuff = i('debuff_max_stat_pct');
    final maxBadWaves = i('debuff_max_waves');
    final buffWaves = i('buff_waves');
    final raw = data['events'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('road_events.json: "events" must be a list');
    }
    final events = <RoadEventDef>[];
    for (final e in raw.cast<Map<String, dynamic>>()) {
      final id = e['id'];
      if (id is! String) {
        throw const FormatException('road_events.json: event needs an id');
      }
      final kind = RoadEventKind.values.where((k) => k.name == e['kind']);
      if (kind.isEmpty) {
        throw FormatException('road event $id: kind must be good or bad');
      }
      final effects = <RoadEffect>[];
      for (final f
          in (e['effects'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        if (f['stat'] != null) {
          final stat = f['stat'], pct = f['pct'];
          if (!_stats.contains(stat) || pct is! int) {
            throw FormatException('road event $id: bad stat effect $f');
          }
          effects.add(RoadEffect.stat(stat as String, pct));
        } else {
          final cur = Currency.values.where((c) => c.name == f['reward']);
          final mult = f['mult_pct'];
          if (cur.isEmpty || mult is! int) {
            throw FormatException('road event $id: bad reward effect $f');
          }
          effects.add(RoadEffect.reward(cur.first, mult));
        }
      }
      final instant =
          (e['instant'] as Map<String, dynamic>?)?['goldfish_waves'];
      final def = RoadEventDef(
        id: id,
        kind: kind.first,
        effects: List.unmodifiable(effects),
        waves: e['waves'] as int? ?? buffWaves,
        icon: e['icon'] as String? ?? '✨',
        instantFishWaves: instant is int ? instant : 0,
      );
      if (def.effects.isEmpty && !def.isInstant) {
        throw FormatException('road event $id: no effect');
      }
      if (def.kind == RoadEventKind.bad) {
        // D-008 §4: bad events are mild, short, and never pay out.
        final tooStrong = def.effects
            .any((f) => f.stat == null || f.pct > 0 || f.pct < -maxDebuff);
        if (tooStrong ||
            def.waves < 1 ||
            def.waves > maxBadWaves ||
            def.isInstant) {
          throw FormatException(
              'road event $id: bad events must be ≥ -$maxDebuff% and ≤ $maxBadWaves waves');
        }
      }
      events.add(def);
    }
    for (final k in RoadEventKind.values) {
      if (!events.any((e) => e.kind == k)) {
        throw FormatException(
            'road_events.json: needs at least one ${k.name} event');
      }
    }
    return RoadEventRules(
      everyWaves: (every[0] as int, every[1] as int),
      goodPct: i('good_pct'),
      maxActive: i('max_active'),
      adBoostMult: i('ad_boost_mult'),
      events: List.unmodifiable(events),
    );
  }
}

class _Active {
  _Active(this.uid, this.def, this.wavesLeft);
  final String uid;
  final RoadEventDef def;
  int wavesLeft;
  bool boosted = false;

  ActiveRoadEvent get view => ActiveRoadEvent(
      uid: uid,
      eventId: def.id,
      kind: def.kind,
      wavesLeft: wavesLeft,
      boosted: boosted);
}

/// Road events (GDD v0.5.2 §9.2–9.3, D-008): something turns up on the road
/// every few waves while walking; effects last a number of waves (a boss
/// fight counts as one) and carry into boss fights. Only runs through the
/// idle loop's hooks, so nothing happens offline. AUTO boss waits while a
/// bad event is active.
class RoadEvents implements IRoadEvents {
  RoadEvents({
    required this.rules,
    required this.idleRules,
    required this.wallet,
    required this.ads,
    int seed = 0,
  }) : _rng = SeededRng(seed ^ 0x5EED) {
    _untilNext = _roll();
  }

  final RoadEventRules rules;
  final IdleRules idleRules;
  final IWallet wallet;

  /// Read lazily: only an ad tap needs it (T-039 owns caps).
  final IAdService Function() ads;
  SeededRng _rng;
  final _active = <_Active>[];

  /// Dice state, so road events continue the same sequence after a reload.
  int get rngState => _rng.state;
  set rngState(int v) => _rng = SeededRng.fromState(v);
  final _news = StreamController<RoadEventNews>.broadcast(sync: true);
  int _untilNext = 0;
  int _nextUid = 1;

  /// Hooks for [IdleLoop.hooks].
  late final IdleHooks hooks = IdleHooks(
    onWalkBetweenWaves: _onWalk,
    onWaveCleared: (_, __) => _waveDone(countsTowardNext: true),
    onBossEnded: (_) => _waveDone(countsTowardNext: false),
    canAutoChallenge: () => !hasBad,
    adjustReward: _adjustReward,
  );

  @override
  List<ActiveRoadEvent> get active => [for (final a in _active) a.view];

  @override
  Stream<RoadEventNews> get news => _news.stream;

  bool get hasBad => _active.any((a) => a.def.kind == RoadEventKind.bad);

  /// Data of an active event (icon, effects) for the UI.
  RoadEventDef defOf(String uid) => _find(uid)!.def;

  int _roll() {
    final (lo, hi) = rules.everyWaves;
    return lo + _rng.nextUint32() % (hi - lo + 1);
  }

  void _onWalk(int page) {
    if (_untilNext > 0) return;
    _untilNext = _roll();
    if (_active.length >= rules.maxActive) return;
    final kind = _rng.nextUint32() % 100 < rules.goodPct
        ? RoadEventKind.good
        : RoadEventKind.bad;
    final pool = [
      for (final e in rules.events)
        if (e.kind == kind && !_active.any((a) => a.def.id == e.id)) e,
    ];
    if (pool.isEmpty) return;
    final def = pool[_rng.nextUint32() % pool.length];
    final a = _Active('r${_nextUid++}', def, def.isInstant ? 0 : def.waves);
    _news.add(RoadEventStarted(a.view));
    if (def.isInstant) {
      final fish = idleRules.perWaveMilli(page)[Currency.goldfish]! *
          def.instantFishWaves ~/
          1000;
      wallet.add(RewardBundle({Currency.goldfish: fish}));
      _news.add(RoadEventEnded(a.view, RoadEventEndReason.wornOff));
    } else {
      _active.add(a);
    }
  }

  void _waveDone({required bool countsTowardNext}) {
    if (countsTowardNext && _untilNext > 0) _untilNext--;
    for (final a in [..._active]) {
      a.wavesLeft--;
      if (a.wavesLeft <= 0) {
        _active.remove(a);
        _news.add(RoadEventEnded(a.view, RoadEventEndReason.wornOff));
      }
    }
  }

  RewardBundle _adjustReward(RewardBundle r) {
    var out = r;
    for (final a in _active) {
      for (final f in a.def.effects) {
        final c = f.reward;
        if (c != null) {
          out = RewardBundle({...out.amounts, c: out[c] * f.multPct ~/ 100});
        }
      }
    }
    return out;
  }

  /// The cat's fight stats with every active effect applied (after class
  /// and gear).
  CombatUnitSpec apply(CombatUnitSpec cat) =>
      applyRoadEffects(cat, [for (final a in _active) a.def]);

  _Active? _find(String uid) {
    for (final a in _active) {
      if (a.uid == uid) return a;
    }
    return null;
  }

  /// UI: show the small ad button next to this event's icon (no countdown,
  /// no full-screen prompt — D-008 §4).
  bool canOfferAd(String uid) {
    final a = _find(uid);
    if (a == null || (a.def.kind == RoadEventKind.good && a.boosted)) {
      return false;
    }
    return ads().canShow(roadEventPlacement);
  }

  @override
  Future<bool> boostWithAd(String uid) async {
    final a = _find(uid);
    if (a == null || a.def.kind != RoadEventKind.good || a.boosted) {
      return false;
    }
    if (!await _watch()) return false;
    if (!_active.contains(a)) return false;
    a.wavesLeft *= rules.adBoostMult;
    a.boosted = true;
    return true;
  }

  @override
  Future<bool> cleanseWithAd(String uid) async {
    final a = _find(uid);
    if (a == null || a.def.kind != RoadEventKind.bad) return false;
    if (!await _watch()) return false;
    if (!_active.remove(a)) return false;
    _news.add(RoadEventEnded(a.view, RoadEventEndReason.cleansed));
    return true;
  }

  Future<bool> _watch() async {
    final ad = ads();
    if (!ad.canShow(roadEventPlacement)) return false;
    return await ad.show(roadEventPlacement) == AdOutcome.rewarded;
  }

  Future<void> dispose() => _news.close();
}

/// [cat] with the stat effects of [events] applied: atk/hp/def change by
/// %, evade by percentage points (never below 0), attack_speed changes the
/// attack rate. Returns [cat] itself when nothing changes.
CombatUnitSpec applyRoadEffects(CombatUnitSpec cat, List<RoadEventDef> events) {
  var atk = 0, hp = 0, def = 0, evade = 0, speed = 0;
  for (final e in events) {
    for (final f in e.effects) {
      switch (f.stat) {
        case 'atk':
          atk += f.pct;
        case 'hp':
          hp += f.pct;
        case 'def':
          def += f.pct;
        case 'evade':
          evade += f.pct;
        case 'attack_speed':
          speed += f.pct;
      }
    }
  }
  if (atk == 0 && hp == 0 && def == 0 && evade == 0 && speed == 0) return cat;
  final s = cat.stats;
  final ev = s[Attribute.evade] + evade * 100;
  return cat.copyWith(
    attackIntervalMs: cat.attackIntervalMs * 100 ~/ (100 + speed),
    stats: s
        .scaledBp(
            atk: kBp + atk * 100, hp: kBp + hp * 100, def: kBp + def * 100)
        .copyWith(
      attrs: {...s.attrs, Attribute.evade: ev < 0 ? 0 : ev},
    ),
  );
}
