import '../core/contracts/combat.dart';

/// Buff actions (GAME_CONTRACT §4.7, T-008).
enum BuffAction {
  /// Changes a stat while active: `attr` + `mode` pct (main stats) or add.
  attrib,

  /// Absorbs damage: `pct_max_hp` of the holder's max HP.
  shield,

  /// Damage every `tick_ms`: `pct_atk` of the source's ATK per stack.
  dot,

  /// Holder can neither attack nor cast for `duration_ms`.
  stun,

  /// Instant: brings the holder's skills `ms` closer.
  cooldownMod,

  /// Instant: the holder attacks once more.
  extraHit,

  /// Instant: heals `pct_max_hp`.
  heal,

  /// Instant: applies buff `buff` to the holder.
  addBuff,
}

enum BuffEventKind { crit, dodge, kill, skillCast, shieldBreak, waveStart }

/// `on_event` entry: when the holder sees [event], apply [addBuff] to the
/// holder ([toOther] false) or to the other unit involved.
class BuffTrigger {
  const BuffTrigger(this.event, this.addBuff, {this.toOther = false});
  final BuffEventKind event;
  final String addBuff;
  final bool toOther;
}

class BuffDef {
  const BuffDef({
    required this.id,
    required this.action,
    this.durationMs = 0,
    this.tickMs = 0,
    this.group,
    this.mutex = const [],
    this.stackMax = 1,
    this.onEvent = const [],
    this.attr,
    this.mainStat,
    this.valueBp = 0,
    this.pctBp = 0,
    this.ms = 0,
    this.buff,
  });

  final String id;
  final BuffAction action;

  /// -1 = whole fight, 0 = instant.
  final int durationMs;
  final int tickMs;
  final String? group;
  final List<String> mutex;
  final int stackMax;
  final List<BuffTrigger> onEvent;

  /// attrib on a secondary stat (`mode: add`), in basis points.
  final Attribute? attr;

  /// attrib on a main stat: `atk` / `def` / `hp` (`mode: pct`).
  final String? mainStat;
  final int valueBp;

  /// shield / dot / heal percentage in basis points.
  final int pctBp;

  /// cooldown_mod milliseconds.
  final int ms;

  /// add_buff target id.
  final String? buff;

  bool get isInstant => durationMs == 0 && action != BuffAction.stun;
}

/// `design/data/buffs.json`. Percent values become basis points here.
class BuffBook {
  BuffBook(Map<String, BuffDef> defs) : defs = Map.unmodifiable(defs);

  static final empty = BuffBook(const {});

  final Map<String, BuffDef> defs;

  BuffDef operator [](String id) =>
      defs[id] ?? (throw ArgumentError.value(id, 'buffId', 'unknown buff'));

  static const _events = {
    'crit': BuffEventKind.crit,
    'dodge': BuffEventKind.dodge,
    'kill': BuffEventKind.kill,
    'skill_cast': BuffEventKind.skillCast,
    'shield_break': BuffEventKind.shieldBreak,
    'wave_start': BuffEventKind.waveStart,
  };
  static const _actions = {
    'attrib': BuffAction.attrib,
    'shield': BuffAction.shield,
    'dot': BuffAction.dot,
    'stun': BuffAction.stun,
    'cooldown_mod': BuffAction.cooldownMod,
    'extra_hit': BuffAction.extraHit,
    'heal': BuffAction.heal,
    'add_buff': BuffAction.addBuff,
  };

  factory BuffBook.fromJson(Map<String, dynamic> json) {
    final raw = json['buffs'];
    if (raw is! List) {
      throw const FormatException('buffs.json: "buffs" must be a list');
    }
    final defs = <String, BuffDef>{};
    for (final b in raw.cast<Map<String, dynamic>>()) {
      final id = b['id'];
      if (id is! String) {
        throw const FormatException('buffs.json: buff needs an id');
      }
      FormatException bad(String why) => FormatException('buff $id: $why');
      final action =
          _actions[b['action']] ?? (throw bad('unknown action ${b['action']}'));
      final p = (b['params'] as Map?)?.cast<String, dynamic>() ?? const {};
      int bp(String k) {
        final v = p[k];
        if (v is! num) throw bad('needs params.$k');
        return (v * 100).round();
      }

      Attribute? attr;
      String? main;
      var value = 0;
      if (action == BuffAction.attrib) {
        final a = p['attr'] as String?;
        final mode = p['mode'];
        value = bp('value');
        if (mode == 'pct' && const {'atk', 'def', 'hp'}.contains(a)) {
          main = a;
        } else if (mode == 'add' && a != null && Attribute.fromKey(a) != null) {
          attr = Attribute.fromKey(a);
        } else {
          throw bad(
              'attrib needs attr + mode (pct for atk/def/hp, add for others)');
        }
      }
      final duration = b['duration_ms'] ?? 0;
      if (duration is! int || duration < -1) {
        throw bad('duration_ms must be ≥ -1');
      }
      final def = BuffDef(
        id: id,
        action: action,
        durationMs: duration,
        tickMs: b['tick_ms'] as int? ?? 0,
        group: b['group'] as String?,
        mutex:
            List.unmodifiable((b['mutex'] as List? ?? const []).cast<String>()),
        stackMax: b['stack_max'] as int? ?? 1,
        attr: attr,
        mainStat: main,
        valueBp: value,
        pctBp: switch (action) {
          BuffAction.shield || BuffAction.heal => bp('pct_max_hp'),
          BuffAction.dot => bp('pct_atk'),
          _ => 0,
        },
        ms: action == BuffAction.cooldownMod
            ? (p['ms'] as int? ?? (throw bad('needs params.ms')))
            : 0,
        buff: action == BuffAction.addBuff
            ? (p['buff'] as String? ?? (throw bad('needs params.buff')))
            : null,
        onEvent: List.unmodifiable([
          for (final t in (b['on_event'] as List? ?? const [])
              .cast<Map<String, dynamic>>())
            BuffTrigger(
              _events[t['event']] ?? (throw bad('unknown event ${t['event']}')),
              t['add_buff'] as String? ??
                  (throw bad('on_event needs add_buff')),
              toOther: t['target'] == 'other',
            ),
        ]),
      );
      if (def.action == BuffAction.dot && def.tickMs <= 0) {
        throw bad('dot needs tick_ms > 0');
      }
      if (def.action == BuffAction.dot && def.durationMs <= 0) {
        throw bad('dot needs a duration');
      }
      if (def.stackMax < 1) throw bad('stack_max must be ≥ 1');
      if (defs.containsKey(id)) throw bad('duplicate id');
      defs[id] = def;
    }
    for (final d in defs.values) {
      for (final ref in [d.buff, for (final t in d.onEvent) t.addBuff]) {
        if (ref != null && !defs.containsKey(ref)) {
          throw FormatException('buff ${d.id}: refers to unknown buff $ref');
        }
      }
    }
    return BuffBook(defs);
  }
}

/// `design/data/skills.json`: 3 skills per class (GDD v0.5 §3.2).
class SkillBook {
  const SkillBook(
      {required this.byClass,
      required this.firstCastPct,
      this.info = const {}});

  /// Skill id → icon and names, for the UI.
  final Map<String, ({String icon, String th, String en})> info;

  /// Class id → skills in slot order.
  final Map<String, List<SkillSpec>> byClass;

  /// First cast after this % of the cooldown.
  final int firstCastPct;

  /// The first [slots] skills of [classId] (novice has none).
  List<SkillSpec> skillsFor(String classId, int slots) {
    final all = byClass[classId] ?? const [];
    return List.unmodifiable(all.take(slots));
  }

  factory SkillBook.fromJson(Map<String, dynamic> json, BuffBook buffs) {
    final raw = json['skills'];
    final first = json['first_cast_pct'];
    if (raw is! List || first is! int || first < 0 || first > 100) {
      throw const FormatException(
          'skills.json: needs skills and first_cast_pct 0..100');
    }
    final byClass = <String, List<(int, SkillSpec)>>{};
    final info = <String, ({String icon, String th, String en})>{};
    for (final s in raw.cast<Map<String, dynamic>>()) {
      final id = s['id'];
      if (id is! String) {
        throw const FormatException('skills.json: skill needs an id');
      }
      FormatException bad(String why) => FormatException('skill $id: $why');
      final cls = s['class'], slot = s['slot'], cd = s['cooldown_ms'];
      if (cls is! String || slot is! int || cd is! int || cd <= 0) {
        throw bad('needs class, slot and cooldown_ms > 0');
      }
      final target = SkillTarget.values.where((t) => t.name == s['target']);
      if (target.isEmpty) throw bad('target must be front, all or self');
      List<String> ids(String k) {
        final v = (s[k] as List? ?? const []).cast<String>();
        for (final b in v) {
          if (!buffs.defs.containsKey(b)) throw bad('unknown buff $b');
        }
        return List.unmodifiable(v);
      }

      final spec = SkillSpec(
        id: id,
        cooldownMs: cd,
        target: target.first,
        damagePct: s['damage_pct'] as int? ?? 0,
        hits: s['hits'] as int? ?? 1,
        buffsTarget: ids('buffs_target'),
        buffsSelf: ids('buffs_self'),
      );
      (byClass[cls] ??= []).add((slot, spec));
      info[id] = (
        icon: s['icon'] as String? ?? '✨',
        th: s['name_th'] as String? ?? id,
        en: s['name_en'] as String? ?? id,
      );
    }
    return SkillBook(
      info: Map.unmodifiable(info),
      firstCastPct: first,
      byClass: {
        for (final e in byClass.entries)
          e.key: List.unmodifiable(
              (e.value..sort((a, b) => a.$1.compareTo(b.$1))).map((x) => x.$2)),
      },
    );
  }
}
