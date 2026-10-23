import 'dart:async';

import '../core/contracts/combat.dart';
import '../core/random/seeded_rng.dart';
import 'buffs.dart';
import 'combat_rules.dart';
import 'fixed_point.dart';

/// One hit, decided by a single roll in [0, kBp) (GDD v0.4 §4.2): below the
/// evade chance is a dodge, the next crit-chance band is a crit, the rest is
/// a normal hit.
///
/// A skill hit passes [skillPct] (% of ATK): it cannot be dodged (D-015),
/// can crit, and is scaled by the attacker's skill damage.
({HitOutcome outcome, int damage}) resolveHit({
  required CombatRules rules,
  required StatBlock attacker,
  required StatBlock defender,
  required int roll,
  bool defenderIsBoss = false,
  DamageChannel channel = DamageChannel.normal,
  int? skillPct,
}) {
  final evade = skillPct != null
      ? 0
      : rules.proc(Attribute.evade, defender[Attribute.evade],
          attacker[Attribute.accuracy]);
  if (roll < evade) return (outcome: HitOutcome.dodge, damage: 0);
  final crit = rules.proc(
      Attribute.crit, attacker[Attribute.crit], defender[Attribute.critRes]);
  final isCrit = roll < evade + crit;

  final atk = skillPct == null ? attacker.atk : attacker.atk * skillPct ~/ 100;
  final floor = mulBp(atk, rules.defFloorBp);
  final diff = atk - defender.def;
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
  if (skillPct != null) {
    damage = mulBp(damage, kBp + attacker[Attribute.skillDmg]);
  }
  if (defenderIsBoss) {
    damage = mulBp(damage, kBp + attacker[Attribute.bossDmg]);
  }
  return (
    outcome: isCrit ? HitOutcome.crit : HitOutcome.normal,
    damage: damage < 1 ? 1 : damage,
  );
}

class _Buff {
  _Buff(this.def, this.source);
  final BuffDef def;
  final _Unit source;
  int stacks = 1;

  /// -1 = never.
  int expiresAt = -1;
  int nextTickAt = -1;
  int shieldLeft = 0;

  /// dot damage per stack, fixed when applied.
  int perTick = 0;
}

class _Unit {
  _Unit(this.spec)
      : hp = spec.stats.hp,
        eff = spec.stats;

  final CombatUnitSpec spec;
  int hp;
  StatBlock eff;
  int intervalMs = 1;
  int nextActAt = 1;
  int stunnedUntil = 0;
  bool alive = true;
  final buffs = <_Buff>[];

  /// Next cast time per skill (same order as spec.skills).
  late final List<int> nextSkillAt = List.filled(spec.skills.length, 0);

  int get maxHp => spec.stats.hp;
  bool get isCatSide => spec.side == CombatSide.cat;
  bool get targetable => !spec.isPartner;
  DamageChannel get channel =>
      spec.isPartner ? DamageChannel.partner : DamageChannel.normal;
}

/// Deterministic auto-battle (GDD v0.4 §4, D-004: no player input). Time
/// jumps from one event to the next (attacks, skill casts, buff ticks and
/// expiries, regen), so any split of `tick` calls gives the same events —
/// offline rewards can run a fight in one call.
///
/// Order inside one millisecond: regen, buff ticks and expiries, then each
/// unit (cat side first, then enemies, in setup order) casts any ready
/// skills and attacks.
///
/// Skills (T-008, D-015) cast themselves on cooldown — first cast at
/// `firstCastPct` of it — `cooldown × (1 − cdr)`. Attack-speed buffs change
/// the interval from the next attack on (the one already queued keeps its
/// time).
class CombatEngine implements ICombatEngine, IBuffEngine {
  CombatEngine(this.rules, {BuffBook? buffs, this.firstCastPct = 50})
      : buffBook = buffs ?? BuffBook.empty;

  final CombatRules rules;
  final BuffBook buffBook;
  final int firstCastPct;

  /// on_event chains stop at this depth (A → B → A … never loops forever).
  static const maxEventDepth = 4;

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

  int hpOf(String unitId) => _unit(unitId).hp;

  /// Stats of [unitId] with its active buffs.
  StatBlock statsOf(String unitId) => _unit(unitId).eff;

  /// Total HP the cat side took off enemies on [channel] (shields excluded).
  int damageDealt(DamageChannel channel) => _damage[channel] ?? 0;

  _Unit _unit(String id) => _units.firstWhere((u) => u.spec.id == id);

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
        for (final u in setup.units.where((u) => u.side == side)) _Unit(u),
    ];
    _rng = SeededRng(setup.seed);
    _now = 0;
    _timeLimit = setup.timeLimitMs;
    _damage.clear();
    _playerWon = null;
    _started = true;
    _nextRegenAt = null;
    for (final u in _units) {
      _recompute(u);
      u.nextActAt = u.intervalMs;
      for (var i = 0; i < u.spec.skills.length; i++) {
        final first = _cooldown(u, i) * firstCastPct ~/ 100;
        u.nextSkillAt[i] = first < 1 ? 1 : first;
      }
    }
    for (final u in _units) {
      _fire(u, BuffEventKind.waveStart, null, 0);
    }
  }

  @override
  List<UnitView> get view => [
        for (final u in _units)
          UnitView(
            id: u.spec.id,
            side: u.spec.side,
            isBoss: u.spec.isBoss,
            isPartner: u.spec.isPartner,
            hp: u.hp,
            maxHp: u.maxHp,
            shield: u.buffs
                .where((b) => b.def.action == BuffAction.shield)
                .fold(0, (a, b) => a + b.shieldLeft),
            alive: u.alive,
            skills: [
              for (var i = 0; i < u.spec.skills.length; i++)
                SkillView(
                  id: u.spec.skills[i].id,
                  remainingMs:
                      u.nextSkillAt[i] > _now ? u.nextSkillAt[i] - _now : 0,
                  totalMs: _cooldown(u, i),
                ),
            ],
          ),
      ];

  /// Cooldown of skill [i] with the unit's CDR right now (buffs included).
  int _cooldown(_Unit u, int i) {
    final cdr = rules.proc(Attribute.cdr, u.eff[Attribute.cdr], 0);
    final cd = u.spec.skills[i].cooldownMs * (kBp - cdr) ~/ kBp;
    return cd < 1 ? 1 : cd;
  }

  /// Effective stats + attack interval from the base spec and buffs. Regen
  /// ticks start once any unit has regen (from the start or a buff).
  void _recompute(_Unit u) {
    var s = u.spec.stats;
    if (u.buffs.isNotEmpty) {
      var atkBp = kBp, defBp = kBp, hpBp = kBp;
      final add = <Attribute, int>{};
      for (final b in u.buffs) {
        final d = b.def;
        if (d.action != BuffAction.attrib) continue;
        final v = d.valueBp * b.stacks;
        switch (d.mainStat) {
          case 'atk':
            atkBp += v;
          case 'def':
            defBp += v;
          case 'hp':
            hpBp += v;
          default:
            add[d.attr!] = (add[d.attr!] ?? 0) + v;
        }
      }
      final attrs = {...s.attrs};
      for (final e in add.entries) {
        attrs[e.key] = (attrs[e.key] ?? 0) + e.value;
      }
      s = s.copyWith(
        atk: mulBp(s.atk, atkBp < 0 ? 0 : atkBp),
        def: mulBp(s.def, defBp < 0 ? 0 : defBp),
        hp: mulBp(s.hp, hpBp < 0 ? 0 : hpBp),
        attrs: attrs,
      );
    }
    u.eff = s;
    final speed =
        rules.proc(Attribute.attackSpeed, s[Attribute.attackSpeed], 0);
    final interval = u.spec.attackIntervalMs * kBp ~/ (kBp + speed);
    u.intervalMs = interval < 1 ? 1 : interval;
    if (_nextRegenAt == null && s[Attribute.regen] > 0) {
      _nextRegenAt = _now + rules.regenTickMs;
    }
  }

  @override
  void tick(int dtMs) {
    if (!_started) throw StateError('tick before start');
    if (dtMs < 0) throw ArgumentError.value(dtMs, 'dtMs', 'must be >= 0');
    final end = _now + dtMs;
    while (!isOver) {
      var t = end + 1;
      for (final u in _units) {
        if (!u.alive) continue;
        if (u.nextActAt < t) t = u.nextActAt;
        for (final at in u.nextSkillAt) {
          if (at < t) t = at;
        }
        for (final b in u.buffs) {
          if (b.expiresAt >= 0 && b.expiresAt < t) t = b.expiresAt;
          if (b.nextTickAt >= 0 && b.nextTickAt < t) t = b.nextTickAt;
        }
      }
      final regenAt = _nextRegenAt;
      if (regenAt != null && regenAt < t) t = regenAt;
      final limit = _timeLimit;
      if (limit != null && limit < t) t = limit;
      if (t > end) break;

      _now = t;
      if (t == regenAt) _regen();
      _tickBuffs(t);
      for (final u in _units) {
        if (isOver) break;
        if (!u.alive) continue;
        for (var i = 0; i < u.spec.skills.length && !isOver && u.alive; i++) {
          if (u.nextSkillAt[i] != t) continue;
          if (t < u.stunnedUntil) {
            u.nextSkillAt[i] = u.stunnedUntil;
          } else {
            _cast(u, i);
          }
        }
        if (!isOver && u.alive && u.nextActAt == t) {
          final target = _targetFor(u);
          if (target != null) _attack(u, target, AttackSource.normal);
          u.nextActAt = t + u.intervalMs;
        }
      }
      if (!isOver && limit != null && t >= limit) _end(false);
    }
    if (!isOver) _now = end;
  }

  /// Casts skill [slotIndex] of the cat now if it is off cooldown; does
  /// nothing otherwise. Auto-cast is the normal path (D-004) — kept for
  /// modes that may want a manual cast.
  @override
  void useSkill(int slotIndex) {
    if (!_started || isOver) return;
    final cat = _units.firstWhere((u) => u.isCatSide && u.targetable);
    if (!cat.alive || slotIndex < 0 || slotIndex >= cat.spec.skills.length) {
      return;
    }
    if (cat.nextSkillAt[slotIndex] > _now || _now < cat.stunnedUntil) return;
    _cast(cat, slotIndex);
  }

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

  // ---------------------------------------------------------------- skills

  void _cast(_Unit u, int i) {
    final skill = u.spec.skills[i];
    u.nextSkillAt[i] = _now + _cooldown(u, i);
    _emit(SkillCast(atMs: _now, unitId: u.spec.id, skillId: skill.id));
    for (final b in skill.buffsSelf) {
      _applyBuff(u, buffBook[b], u, 0);
    }
    if (skill.buffsAlly.isNotEmpty) {
      for (final a in _units) {
        if (a.alive && a.isCatSide == u.isCatSide && a.targetable) {
          for (final b in skill.buffsAlly) {
            _applyBuff(a, buffBook[b], u, 0);
          }
          break; // the cat (first targetable unit on this side)
        }
      }
    }
    final targets = switch (skill.target) {
      SkillTarget.self => const <_Unit>[],
      SkillTarget.front => [if (_targetFor(u) case final t?) t],
      SkillTarget.all => [
          for (final o in _units)
            if (o.alive && o.isCatSide != u.isCatSide && o.targetable) o,
        ],
    };
    for (final d in targets) {
      for (var h = 0; h < skill.hits && d.alive && !isOver; h++) {
        if (skill.damagePct > 0) _skillHit(u, d, skill.damagePct);
      }
      if (d.alive && !isOver) {
        for (final b in skill.buffsTarget) {
          _applyBuff(d, buffBook[b], u, 0);
        }
      }
      if (isOver) return;
    }
    if (!isOver && u.alive) _fire(u, BuffEventKind.skillCast, null, 0);
  }

  void _skillHit(_Unit a, _Unit d, int pct) {
    final hit = resolveHit(
      rules: rules,
      attacker: a.eff,
      defender: d.eff,
      roll: _rng.nextBp(),
      defenderIsBoss: d.spec.isBoss,
      skillPct: pct,
    );
    final lost = _damageUnit(d, hit.damage, a, DamageChannel.skill);
    _emit(HitResolved(
      atMs: _now,
      attackerId: a.spec.id,
      targetId: d.spec.id,
      outcome: hit.outcome,
      damage: hit.damage,
      targetHp: d.hp,
      channel: DamageChannel.skill,
      source: AttackSource.skill,
    ));
    if (hit.outcome == HitOutcome.crit) _fire(a, BuffEventKind.crit, d, 0);
    if (lost >= 0 && d.hp == 0) _kill(a, d);
  }

  // ----------------------------------------------------------------- hits

  /// Takes [amount] off [d] (shields first). Returns HP lost.
  int _damageUnit(_Unit d, int amount, _Unit? from, DamageChannel channel) {
    var left = amount;
    for (final b in [...d.buffs]) {
      if (left == 0) break;
      if (b.def.action != BuffAction.shield || b.shieldLeft <= 0) continue;
      final taken = left < b.shieldLeft ? left : b.shieldLeft;
      b.shieldLeft -= taken;
      left -= taken;
      _emit(ShieldAbsorbed(
          atMs: _now, unitId: d.spec.id, amount: taken, left: b.shieldLeft));
      if (b.shieldLeft == 0) {
        _removeBuff(d, b);
        _fire(d, BuffEventKind.shieldBreak, from, 0);
      }
    }
    final lost = left < d.hp ? left : d.hp;
    d.hp -= lost;
    if (from != null && from.isCatSide) {
      _damage[channel] = (_damage[channel] ?? 0) + lost;
    }
    return lost;
  }

  void _attack(_Unit a, _Unit d, AttackSource source) {
    final hit = resolveHit(
      rules: rules,
      attacker: a.eff,
      defender: d.eff,
      roll: _rng.nextBp(),
      defenderIsBoss: d.spec.isBoss,
      channel: a.channel,
    );
    final dealt = hit.outcome == HitOutcome.dodge
        ? 0
        : _damageUnit(d, hit.damage, a, a.channel);
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

    if (hit.outcome == HitOutcome.dodge) {
      _fire(d, BuffEventKind.dodge, a, 0);
      if (isOver) return;
    } else {
      if (hit.outcome == HitOutcome.crit) {
        _fire(a, BuffEventKind.crit, d, 0);
        if (isOver) return;
      }
      final share = rules.proc(Attribute.lifesteal, a.eff[Attribute.lifesteal],
          d.eff[Attribute.lifestealRes]);
      if (share > 0) _heal(a, mulBp(dealt, share), HealCause.lifesteal);

      if (d.hp == 0) {
        if (d.alive) _kill(a, d);
        if (isOver) return;
      } else {
        _maybeStun(a, d);
        if (source == AttackSource.normal &&
            a.targetable &&
            _now >= d.stunnedUntil) {
          final counter = rules.proc(Attribute.counter,
              d.eff[Attribute.counter], a.eff[Attribute.counterRes]);
          if (counter > 0 && _rng.nextBp() < counter) {
            _attack(d, a, AttackSource.counter);
            if (isOver || !a.alive) return;
          }
        }
      }
    }

    if (source == AttackSource.normal) {
      final combo = rules.proc(
          Attribute.combo, a.eff[Attribute.combo], d.eff[Attribute.comboRes]);
      if (combo > 0 && _rng.nextBp() < combo) {
        final next = d.alive ? d : _targetFor(a);
        if (next != null) _attack(a, next, AttackSource.combo);
      }
    }
  }

  void _kill(_Unit killer, _Unit victim) {
    _defeat(victim);
    if (!isOver && killer.alive) _fire(killer, BuffEventKind.kill, victim, 0);
  }

  void _maybeStun(_Unit a, _Unit d) {
    final chance = rules.proc(
        Attribute.stun, a.eff[Attribute.stun], d.eff[Attribute.stunRes]);
    if (chance == 0 || _rng.nextBp() >= chance) return;
    _stun(d, rules.stunMs);
  }

  void _stun(_Unit d, int ms) {
    final until = _now + ms;
    if (d.stunnedUntil < until) d.stunnedUntil = until;
    if (d.nextActAt < until) d.nextActAt = until;
    _emit(UnitStunned(atMs: _now, unitId: d.spec.id, untilMs: until));
  }

  // ---------------------------------------------------------------- buffs

  /// IBuffEngine: applies [buffId] to [unitId] from [sourceId] mid-fight.
  @override
  void apply(String unitId, String buffId, {required String sourceId}) {
    if (!_started || isOver) return;
    final u = _unit(unitId);
    if (!u.alive) return;
    _applyBuff(u, buffBook[buffId], _unit(sourceId), 0);
  }

  void _applyBuff(_Unit u, BuffDef def, _Unit source, int depth) {
    if (!u.alive || isOver) return;
    switch (def.action) {
      case BuffAction.stun:
        _stun(u, def.durationMs);
        return;
      case BuffAction.cooldownMod:
        for (var i = 0; i < u.nextSkillAt.length; i++) {
          final at = u.nextSkillAt[i] - def.ms;
          u.nextSkillAt[i] = at > _now ? at : _now + 1;
        }
        return;
      case BuffAction.extraHit:
        final t = _targetFor(u);
        if (t != null && _now >= u.stunnedUntil) {
          _attack(u, t, AttackSource.extra);
        }
        return;
      case BuffAction.heal:
        _heal(u, mulBp(u.maxHp, def.pctBp), HealCause.regen);
        return;
      case BuffAction.addBuff:
        if (_chain < maxEventDepth) {
          _chain++;
          _applyBuff(u, buffBook[def.buff!], source, depth + 1);
          _chain--;
        }
        return;
      case BuffAction.attrib:
      case BuffAction.shield:
      case BuffAction.dot:
        break;
    }
    // mutex: applying this buff clears the listed groups
    if (def.mutex.isNotEmpty) {
      for (final b in [...u.buffs]) {
        if (b.def.group != null && def.mutex.contains(b.def.group)) {
          _removeBuff(u, b);
        }
      }
    }
    _Buff? same;
    if (def.group != null) {
      for (final b in u.buffs) {
        if (b.def.group == def.group) same = b;
      }
    }
    final _Buff b;
    if (same != null && same.def.id == def.id) {
      b = same;
      if (b.stacks < def.stackMax) b.stacks++;
    } else {
      if (same != null) _removeBuff(u, same);
      b = _Buff(def, source);
      u.buffs.add(b);
    }
    b.expiresAt = def.durationMs > 0 ? _now + def.durationMs : -1;
    if (def.action == BuffAction.shield) {
      b.shieldLeft = mulBp(u.maxHp, def.pctBp);
    }
    if (def.action == BuffAction.dot) {
      b.perTick = mulBp(mulBp(source.eff.atk, def.pctBp),
          kBp + source.eff[Attribute.skillDmg]);
      if (b.nextTickAt < 0) b.nextTickAt = _now + def.tickMs;
    }
    _recompute(u);
    _emit(BuffApplied(
        atMs: _now, unitId: u.spec.id, buffId: def.id, stacks: b.stacks));
  }

  void _removeBuff(_Unit u, _Buff b) {
    if (!u.buffs.remove(b)) return;
    _recompute(u);
    _emit(BuffEnded(atMs: _now, unitId: u.spec.id, buffId: b.def.id));
  }

  void _tickBuffs(int t) {
    for (final u in _units) {
      if (!u.alive || u.buffs.isEmpty) continue;
      for (final b in [...u.buffs]) {
        if (isOver) return;
        if (!u.alive) break; // its buffs went with it; others still tick
        if (b.nextTickAt == t &&
            (b.expiresAt < 0 || b.nextTickAt <= b.expiresAt)) {
          b.nextTickAt = t + b.def.tickMs;
          final amount = b.perTick * b.stacks;
          final lost = _damageUnit(u, amount, b.source, DamageChannel.skill);
          _emit(HitResolved(
            atMs: t,
            attackerId: b.source.spec.id,
            targetId: u.spec.id,
            outcome: HitOutcome.normal,
            damage: amount,
            targetHp: u.hp,
            channel: DamageChannel.skill,
            source: AttackSource.dot,
          ));
          if (lost >= 0 && u.hp == 0 && u.alive) {
            _kill(b.source, u);
            if (isOver) return;
            if (!u.alive) break;
          }
        }
        if (b.expiresAt == t) _removeBuff(u, b);
      }
    }
  }

  /// Runs the holder's on_event triggers for [kind]. [other] is the unit on
  /// the other end (target, attacker) when there is one. Chains (a trigger
  /// whose buff causes another event or adds another buff) stop at
  /// [maxEventDepth], whatever path they take — A → B → A never loops.
  void _fire(_Unit u, BuffEventKind kind, _Unit? other, int depth) {
    if (_chain >= maxEventDepth || u.buffs.isEmpty) return;
    for (final b in [...u.buffs]) {
      for (final trig in b.def.onEvent) {
        if (trig.event != kind || isOver) continue;
        final to = trig.toOther ? other : u;
        if (to == null || !to.alive) continue;
        _chain++;
        _applyBuff(to, buffBook[trig.addBuff], u, _chain);
        _chain--;
      }
    }
  }

  int _chain = 0;

  // ---------------------------------------------------------------- misc

  void _regen() {
    for (final u in _units) {
      final share = rules.proc(Attribute.regen, u.eff[Attribute.regen], 0);
      if (u.alive && share > 0) {
        _heal(u, mulBp(u.maxHp, share), HealCause.regen);
      }
    }
    _nextRegenAt = _now + rules.regenTickMs;
  }

  void _heal(_Unit u, int amount, HealCause cause) {
    final room = u.maxHp - u.hp;
    final healed = amount < room ? amount : room;
    if (!u.alive || healed <= 0) return;
    u.hp += healed;
    _emit(UnitHealed(
        atMs: _now, unitId: u.spec.id, amount: healed, hp: u.hp, cause: cause));
  }

  void _defeat(_Unit u) {
    u.alive = false;
    u.buffs.clear();
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
