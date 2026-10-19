import 'dart:async';

import '../core/contracts/combat.dart';
import 'combat_rules.dart';
import 'fixed_point.dart';
import '../core/random/seeded_rng.dart';

/// One hit, decided by a single roll in [0, kBp) (GDD v0.4 §4.2): below the
/// evade chance is a dodge, the next crit-chance band is a crit, the rest is
/// a normal hit.
({HitOutcome outcome, int damage}) resolveHit({
  required CombatRules rules,
  required StatBlock attacker,
  required StatBlock defender,
  required int roll,
  bool defenderIsBoss = false,
  DamageChannel channel = DamageChannel.normal,
}) {
  final evade = rules.proc(
      Attribute.evade, defender[Attribute.evade], attacker[Attribute.accuracy]);
  if (roll < evade) return (outcome: HitOutcome.dodge, damage: 0);
  final crit = rules.proc(
      Attribute.crit, attacker[Attribute.crit], defender[Attribute.critRes]);
  final isCrit = roll < evade + crit;

  final floor = mulBp(attacker.atk, rules.defFloorBp);
  final diff = attacker.atk - defender.def;
  var damage = diff > floor ? diff : floor;
  if (isCrit) {
    final mult = rules.baseCritDmgBp +
        attacker[Attribute.critDmg] -
        defender[Attribute.critDmgRes];
    damage =
        mulBp(damage, mult > rules.critMultMinBp ? mult : rules.critMultMinBp);
  }
  if (channel == DamageChannel.partner) {
    damage = mulBp(damage, kBp + attacker[Attribute.petDmg]);
  }
  if (defenderIsBoss) {
    damage = mulBp(damage, kBp + attacker[Attribute.bossDmg]);
  }
  return (
    outcome: isCrit ? HitOutcome.crit : HitOutcome.normal,
    damage: damage < 1 ? 1 : damage,
  );
}

class _Unit {
  _Unit(this.spec, int intervalMs)
      : hp = spec.stats.hp,
        intervalMs = intervalMs < 1 ? 1 : intervalMs,
        nextActAt = intervalMs < 1 ? 1 : intervalMs;

  final CombatUnitSpec spec;
  final int intervalMs;
  int hp;
  int nextActAt;
  bool alive = true;

  StatBlock get stats => spec.stats;
  bool get isCatSide => spec.side == CombatSide.cat;
  bool get targetable => !spec.isPartner;
  DamageChannel get channel =>
      spec.isPartner ? DamageChannel.partner : DamageChannel.normal;
}

/// Deterministic auto-battle (GDD v0.4 §4, D-004: no player input). Time
/// jumps from one action to the next, so any split of `tick` calls gives the
/// same events — offline rewards can run a fight in one call.
///
/// Turn order inside one millisecond: regen, then the cat side, then
/// enemies, each in setup order.
class CombatEngine implements ICombatEngine {
  CombatEngine(this.rules);

  final CombatRules rules;
  final _events = StreamController<CombatEvent>.broadcast(sync: true);
  final _damage = <DamageChannel, int>{};

  List<_Unit> _units = const [];
  SeededRng _rng = SeededRng(0);
  int _now = 0;
  int? _nextRegenAt;
  int? _timeLimit;
  bool _started = false;
  bool? _playerWon;

  @override
  Stream<CombatEvent> get events => _events.stream;

  int get nowMs => _now;
  bool get isOver => _playerWon != null;

  /// Null while the fight is running.
  bool? get playerWon => _playerWon;

  int hpOf(String unitId) => _units.firstWhere((u) => u.spec.id == unitId).hp;

  /// Total damage dealt by the cat side on [channel].
  int damageDealt(DamageChannel channel) => _damage[channel] ?? 0;

  @override
  void start(CombatSetup setup) {
    final ids = <String>{};
    for (final u in setup.units) {
      if (!ids.add(u.id)) throw ArgumentError('duplicate unit id ${u.id}');
    }
    if (!setup.units.any((u) => u.side == CombatSide.cat && !u.isPartner) ||
        !setup.units.any((u) => u.side == CombatSide.enemy)) {
      throw ArgumentError('a fight needs a targetable cat and an enemy');
    }
    _units = [
      for (final side in CombatSide.values)
        for (final u in setup.units.where((u) => u.side == side))
          _Unit(u, _interval(u)),
    ];
    _rng = SeededRng(setup.seed);
    _now = 0;
    _timeLimit = setup.timeLimitMs;
    _nextRegenAt = _units.any((u) => u.stats[Attribute.regen] > 0)
        ? rules.regenTickMs
        : null;
    _damage.clear();
    _playerWon = null;
    _started = true;
  }

  int _interval(CombatUnitSpec u) {
    final speed =
        rules.proc(Attribute.attackSpeed, u.stats[Attribute.attackSpeed], 0);
    return u.attackIntervalMs * kBp ~/ (kBp + speed);
  }

  @override
  void tick(int dtMs) {
    if (!_started) throw StateError('tick before start');
    if (dtMs < 0) throw ArgumentError.value(dtMs, 'dtMs', 'must be >= 0');
    final end = _now + dtMs;
    while (!isOver) {
      var t = end + 1;
      for (final u in _units) {
        if (u.alive && u.nextActAt < t) t = u.nextActAt;
      }
      final regenAt = _nextRegenAt;
      if (regenAt != null && regenAt < t) t = regenAt;
      final limit = _timeLimit;
      if (limit != null && limit < t) t = limit;
      if (t > end) break;

      _now = t;
      if (t == regenAt) _regen();
      for (final u in _units) {
        if (isOver) break;
        if (u.alive && u.nextActAt == t) {
          final target = _targetFor(u);
          if (target != null) _attack(u, target, AttackSource.normal);
          u.nextActAt = t + u.intervalMs;
        }
      }
      if (!isOver && limit != null && t >= limit) _end(false);
    }
    if (!isOver) _now = end;
  }

  /// Skills arrive with T-008. Kept for the shared interface; idle play has
  /// no player input (D-004), so this does nothing for now.
  @override
  void useSkill(int slotIndex) {}

  /// Runs until the fight ends or [maxMs] passes. Returns [playerWon]
  /// (null when still running).
  bool? runToEnd({int maxMs = 10 * 60 * 1000}) {
    tick(maxMs);
    return _playerWon;
  }

  Future<void> dispose() => _events.close();

  _Unit? _targetFor(_Unit u) {
    for (final o in _units) {
      if (o.alive && o.isCatSide != u.isCatSide && o.targetable) return o;
    }
    return null;
  }

  void _attack(_Unit a, _Unit d, AttackSource source) {
    final hit = resolveHit(
      rules: rules,
      attacker: a.stats,
      defender: d.stats,
      roll: _rng.nextBp(),
      defenderIsBoss: d.spec.isBoss,
      channel: a.channel,
    );
    final dealt = hit.damage < d.hp ? hit.damage : d.hp;
    d.hp -= dealt;
    if (a.isCatSide) _damage[a.channel] = (_damage[a.channel] ?? 0) + dealt;
    _emit(HitResolved(
      atMs: _now,
      attackerId: a.spec.id,
      targetId: d.spec.id,
      outcome: hit.outcome,
      damage: hit.damage,
      targetHp: d.hp,
      channel: a.channel,
      source: source,
    ));

    if (hit.outcome != HitOutcome.dodge) {
      final share = rules.proc(Attribute.lifesteal,
          a.stats[Attribute.lifesteal], d.stats[Attribute.lifestealRes]);
      if (share > 0) _heal(a, mulBp(dealt, share), HealCause.lifesteal);

      if (d.hp == 0) {
        _defeat(d);
        if (isOver) return;
      } else {
        _maybeStun(a, d);
        if (source == AttackSource.normal && a.targetable) {
          final counter = rules.proc(Attribute.counter,
              d.stats[Attribute.counter], a.stats[Attribute.counterRes]);
          if (counter > 0 && _rng.nextBp() < counter) {
            _attack(d, a, AttackSource.counter);
            if (isOver || !a.alive) return;
          }
        }
      }
    }

    if (source == AttackSource.normal) {
      final combo = rules.proc(Attribute.combo, a.stats[Attribute.combo],
          d.stats[Attribute.comboRes]);
      if (combo > 0 && _rng.nextBp() < combo) {
        final next = d.alive ? d : _targetFor(a);
        if (next != null) _attack(a, next, AttackSource.combo);
      }
    }
  }

  void _maybeStun(_Unit a, _Unit d) {
    final chance = rules.proc(
        Attribute.stun, a.stats[Attribute.stun], d.stats[Attribute.stunRes]);
    if (chance == 0 || _rng.nextBp() >= chance) return;
    final until = _now + rules.stunMs;
    if (d.nextActAt < until) d.nextActAt = until;
    _emit(UnitStunned(atMs: _now, unitId: d.spec.id, untilMs: until));
  }

  void _regen() {
    for (final u in _units) {
      final share = rules.proc(Attribute.regen, u.stats[Attribute.regen], 0);
      if (u.alive && share > 0) {
        _heal(u, mulBp(u.stats.hp, share), HealCause.regen);
      }
    }
    _nextRegenAt = _now + rules.regenTickMs;
  }

  void _heal(_Unit u, int amount, HealCause cause) {
    final room = u.stats.hp - u.hp;
    final healed = amount < room ? amount : room;
    if (!u.alive || healed <= 0) return;
    u.hp += healed;
    _emit(UnitHealed(
        atMs: _now, unitId: u.spec.id, amount: healed, hp: u.hp, cause: cause));
  }

  void _defeat(_Unit u) {
    u.alive = false;
    _emit(UnitDefeated(u.spec.id, atMs: _now));
    if (!_units.any((o) => o.alive && !o.isCatSide)) {
      _end(true);
    } else if (!_units.any((o) => o.alive && o.isCatSide && o.targetable)) {
      _end(false);
    }
  }

  void _end(bool won) {
    _playerWon = won;
    _emit(CombatEnded(playerWon: won, atMs: _now));
  }

  void _emit(CombatEvent e) {
    if (_events.hasListener) _events.add(e);
  }
}
