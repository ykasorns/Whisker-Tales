import 'dart:async';
import 'dart:math' as math;

import '../core/clock/game_clock.dart';
import '../core/contracts/ads.dart';
import '../core/contracts/combat.dart';
import '../core/contracts/research.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';

/// Ad placement for cutting research time (D-003).
const researchSpeedupPlacement = 'research_speedup';

enum ResearchEffect { stat, offlineCap, queue }

/// Why a node cannot start right now.
enum ResearchBlock { maxed, locked, running, queueFull, fish }

class ResearchNode {
  const ResearchNode({
    required this.id,
    required this.icon,
    required this.nameTh,
    required this.nameEn,
    required this.effect,
    required this.maxLevel,
    this.mainStat,
    this.costMult = 1,
    this.timeMult = 1,
    this.requires = const [],
  });

  final String id;
  final String icon, nameTh, nameEn;
  final ResearchEffect effect;
  final int maxLevel;

  /// `atk` / `hp` / `def` for stat nodes.
  final String? mainStat;
  final num costMult, timeMult;

  /// Every (node, level) must be reached first.
  final List<(String, int)> requires;
}

/// `research` (idle_balance_v1.json) + `design/data/research.json`
/// (GDD v0.4 §7, §15.6). The ad cut comes from the `research_speedup`
/// placement params.
class ResearchRules {
  const ResearchRules({
    required this.nodes,
    required this.timeBaseMin,
    required this.timeGrowth,
    required this.timeCapMin,
    required this.costBase,
    required this.costGrowth,
    required this.statBpPerLevel,
    required this.adCutMin,
    required this.adCutPct,
  });

  final List<ResearchNode> nodes;
  final num timeBaseMin, timeGrowth, costBase, costGrowth;
  final int timeCapMin;
  final int statBpPerLevel;
  final int adCutMin, adCutPct;

  ResearchNode? byId(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  /// Time for [node] to reach [level] (1-based), whole seconds, capped.
  Duration timeFor(ResearchNode node, int level) {
    final sec =
        (timeBaseMin * 60 * math.pow(timeGrowth, level - 1) * node.timeMult)
            .round();
    return Duration(seconds: math.min(sec, timeCapMin * 60));
  }

  /// Goldfish for [node] to reach [level] (1-based).
  int costFor(ResearchNode node, int level) =>
      (costBase * math.pow(costGrowth, level - 1) * node.costMult).round();

  factory ResearchRules.fromJson(Map<String, dynamic> balance,
      Map<String, dynamic> data, Map<String, num> adParams) {
    final r = balance['research'];
    if (r is! Map<String, dynamic>) {
      throw const FormatException('balance: needs research');
    }
    num n(String k) {
      final v = r[k] ?? r['ASSUMPTION_$k'];
      if (v is! num) throw FormatException('research: "$k" must be a number');
      return v;
    }

    final raw = data['nodes'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('research.json: "nodes" must be a list');
    }
    final nodes = <ResearchNode>[];
    for (final m in raw.cast<Map<String, dynamic>>()) {
      final id = m['id'];
      if (id is! String) {
        throw const FormatException('research.json: node needs an id');
      }
      FormatException bad(String why) => FormatException('node $id: $why');
      final effect = switch (m['effect']) {
        'stat' => ResearchEffect.stat,
        'offline_cap' => ResearchEffect.offlineCap,
        'queue' => ResearchEffect.queue,
        _ => throw bad('effect must be stat, offline_cap or queue'),
      };
      final attr = m['attr'];
      if (effect == ResearchEffect.stat &&
          !const {'atk', 'hp', 'def'}.contains(attr)) {
        throw bad('stat node needs attr atk, hp or def');
      }
      final max = m['max_level'];
      if (max is! int || max < 1) throw bad('max_level must be ≥ 1');
      if (effect == ResearchEffect.offlineCap &&
          max > n('offline_node_max_level')) {
        throw bad('max_level is above offline_node_max_level');
      }
      if (effect == ResearchEffect.queue && max != 1) {
        throw bad('a queue node has max_level 1');
      }
      if (nodes.any((x) => x.id == id)) throw bad('duplicate id');
      nodes.add(ResearchNode(
        id: id,
        icon: m['icon'] as String? ?? '📖',
        nameTh: m['name_th'] as String? ?? id,
        nameEn: m['name_en'] as String? ?? id,
        effect: effect,
        maxLevel: max,
        mainStat: effect == ResearchEffect.stat ? attr as String : null,
        costMult: m['cost_mult'] as num? ?? 1,
        timeMult: m['time_mult'] as num? ?? 1,
        requires: [
          for (final q in (m['requires'] as List? ?? const []))
            if (q is List && q.length == 2 && q[0] is String && q[1] is int)
              (q[0] as String, q[1] as int)
            else
              throw bad('requires entries are [node, level]'),
        ],
      ));
    }
    for (final node in nodes) {
      for (final (id, lv) in node.requires) {
        final dep = nodes.where((x) => x.id == id);
        if (dep.isEmpty) {
          throw FormatException('node ${node.id}: requires unknown node $id');
        }
        if (lv > dep.first.maxLevel) {
          throw FormatException('node ${node.id}: $id never reaches Lv$lv');
        }
      }
    }
    final cutMin = adParams['cut_min'], cutPct = adParams['cut_pct'];
    if (cutMin is! num || cutPct is! num) {
      throw const FormatException(
          'ads.placements.research_speedup needs cut_min and cut_pct');
    }
    return ResearchRules(
      nodes: List.unmodifiable(nodes),
      timeBaseMin: n('time_base_min'),
      timeGrowth: n('time_growth'),
      timeCapMin: n('time_cap_min').toInt(),
      costBase: n('cost_base'),
      costGrowth: n('cost_growth'),
      statBpPerLevel: (n('stat_node_pct_per_level') * kBp).round(),
      adCutMin: cutMin.toInt(),
      adCutPct: cutPct.toInt(),
    );
  }
}

/// Owl library (GDD v0.4 §7): goldfish + real time, one queue (a node opens
/// the second). Timers end against [GameClock.effectiveNow] and finish in
/// [tick], so a clock turned back never rewinds them. The only speed-up is
/// a rewarded ad through [IAdService] (caps live there) — nothing is sold.
class Research implements IResearch {
  Research(
      {required this.rules,
      required this.wallet,
      required this.ads,
      required this.clock});

  final ResearchRules rules;
  final IWallet wallet;
  final IAdService Function() ads;
  final GameClock clock;

  final _levels = <String, int>{};
  final _tasks = <ResearchTask>[];
  final _done = StreamController<ResearchCompleted>.broadcast(sync: true);

  /// The player's "research done" notice switch (settings, D-020).
  bool notifyDone = true;

  @override
  Map<String, int> get levels => Map.unmodifiable(_levels);

  List<ResearchTask> get tasks => List.unmodifiable(_tasks);

  @override
  Stream<ResearchCompleted> get completed => _done.stream;

  int levelOf(String id) => _levels[id] ?? 0;

  int get queueSlots =>
      1 +
      rules.nodes
          .where((n) => n.effect == ResearchEffect.queue)
          .fold(0, (a, n) => a + levelOf(n.id));

  /// Levels of the offline-cap node(s), for `OfflineReward`.
  int get offlineCapLevel => rules.nodes
      .where((n) => n.effect == ResearchEffect.offlineCap)
      .fold(0, (a, n) => a + levelOf(n.id));

  /// Main-stat bonus in basis points (`atk` / `hp` / `def`).
  int statBp(String mainStat) => rules.nodes
      .where((n) => n.effect == ResearchEffect.stat && n.mainStat == mainStat)
      .fold(0, (a, n) => a + levelOf(n.id) * rules.statBpPerLevel);

  /// [cat] with the stat nodes applied (% of the main stats).
  CombatUnitSpec withBonus(CombatUnitSpec cat) {
    final atk = statBp('atk'), hp = statBp('hp'), def = statBp('def');
    if (atk == 0 && hp == 0 && def == 0) return cat;
    final s = cat.stats;
    return cat.copyWith(
        stats: s.copyWith(
            atk: s.atk * (kBp + atk) ~/ kBp,
            hp: s.hp * (kBp + hp) ~/ kBp,
            def: s.def * (kBp + def) ~/ kBp));
  }

  int costOf(ResearchNode node) => rules.costFor(node, levelOf(node.id) + 1);
  Duration timeOf(ResearchNode node) =>
      rules.timeFor(node, levelOf(node.id) + 1);

  /// Unmet (node, level) prerequisites of [node].
  List<(String, int)> missing(ResearchNode node) => [
        for (final q in node.requires)
          if (levelOf(q.$1) < q.$2) q,
      ];

  /// Why [nodeId] cannot start now, or null when it can.
  ResearchBlock? blockOf(String nodeId) {
    final node = rules.byId(nodeId);
    if (node == null) return ResearchBlock.locked;
    if (levelOf(nodeId) >= node.maxLevel) return ResearchBlock.maxed;
    if (missing(node).isNotEmpty) return ResearchBlock.locked;
    if (_tasks.any((t) => t.nodeId == nodeId)) return ResearchBlock.running;
    if (_tasks.length >= queueSlots) return ResearchBlock.queueFull;
    if (wallet.balance(Currency.goldfish) < costOf(node)) {
      return ResearchBlock.fish;
    }
    return null;
  }

  @override
  bool start(String nodeId) {
    tick();
    if (blockOf(nodeId) != null) return false;
    final node = rules.byId(nodeId)!;
    if (!wallet.spend(Currency.goldfish, costOf(node))) return false;
    _tasks.add(ResearchTask(
      nodeId: nodeId,
      toLevel: levelOf(nodeId) + 1,
      endsAtUtc: clock.effectiveNow.add(timeOf(node)),
    ));
    return true;
  }

  /// Time left on [task] (zero when due).
  Duration remaining(ResearchTask task) {
    final left = task.endsAtUtc.difference(clock.effectiveNow);
    return left.isNegative ? Duration.zero : left;
  }

  /// Finishes every task that is due. Call from the game ticker and after
  /// loading a save.
  void tick() {
    final now = clock.effectiveNow;
    final due = _tasks.where((t) => !t.endsAtUtc.isAfter(now)).toList();
    for (final t in due) {
      _tasks.remove(t);
      _levels[t.nodeId] = t.toLevel;
      _done.add(ResearchCompleted(nodeId: t.nodeId, level: t.toLevel));
    }
  }

  /// What one ad takes off [task]: max(cut_min, cut_pct% of what is left).
  Duration adCut(ResearchTask task) {
    final left = remaining(task);
    final pct = left * rules.adCutPct ~/ 100;
    final flat = Duration(minutes: rules.adCutMin);
    return pct > flat ? pct : flat;
  }

  bool get canSpeedUp =>
      _tasks.isNotEmpty && ads().canShow(researchSpeedupPlacement);

  /// Cuts the task that ends first (D-020) after a rewarded ad. A cut that
  /// covers the rest finishes it now.
  @override
  Future<bool> speedUpWithAd() async {
    tick();
    if (!canSpeedUp) return false;
    if (await ads().show(researchSpeedupPlacement) != AdOutcome.rewarded) {
      return false;
    }
    if (_tasks.isEmpty) return false;
    final task =
        _tasks.reduce((a, b) => b.endsAtUtc.isBefore(a.endsAtUtc) ? b : a);
    final i = _tasks.indexOf(task);
    _tasks[i] = ResearchTask(
        nodeId: task.nodeId,
        toLevel: task.toLevel,
        endsAtUtc: task.endsAtUtc.subtract(adCut(task)));
    tick();
    return true;
  }

  ResearchState snapshot() =>
      ResearchState(levels: Map.of(_levels), tasks: List.of(_tasks));

  /// Loads a save. Unknown nodes are dropped, levels clamp to the node's
  /// max, and a task that no longer fits (maxed, duplicate, over the queue)
  /// is dropped. Due tasks finish on the next [tick].
  void restore(ResearchState s) {
    _levels.clear();
    _tasks.clear();
    for (final e in s.levels.entries) {
      final node = rules.byId(e.key);
      if (node != null && e.value > 0) {
        _levels[e.key] = math.min(e.value, node.maxLevel);
      }
    }
    for (final t in s.tasks) {
      final node = rules.byId(t.nodeId);
      if (node == null ||
          levelOf(t.nodeId) >= node.maxLevel ||
          _tasks.any((x) => x.nodeId == t.nodeId) ||
          _tasks.length >= queueSlots) {
        continue;
      }
      _tasks.add(ResearchTask(
          nodeId: t.nodeId,
          toLevel: levelOf(t.nodeId) + 1,
          endsAtUtc: t.endsAtUtc));
    }
  }

  void dispose() => _done.close();
}
