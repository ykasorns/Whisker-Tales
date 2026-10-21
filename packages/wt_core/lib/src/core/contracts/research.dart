class ResearchCompleted {
  const ResearchCompleted({required this.nodeId, required this.level});
  final String nodeId;
  final int level;
}

/// Owl library research tree (GDD v0.4 §7). Timers are measured against
/// `GameClock.effectiveNow`, so turning the clock back never rewinds them.
/// No real-money speed-up exists. Owner: `research` (T-041).
abstract class IResearch {
  Map<String, int> get levels;

  /// Starts the next level of [nodeId]; false if unaffordable, locked or the
  /// queue is full.
  bool start(String nodeId);

  /// Cuts the running task of [nodeId] (default: the one with the most time
  /// left, where an ad helps most) by max(30 min, 25% of remaining) after a
  /// completed rewarded ad. False if no task is running or no ad is left.
  Future<bool> speedUpWithAd([String? nodeId]);

  Stream<ResearchCompleted> get completed;
}

/// One running research: [nodeId] goes to [toLevel] at [endsAtUtc].
class ResearchTask {
  const ResearchTask(
      {required this.nodeId, required this.toLevel, required this.endsAtUtc});
  final String nodeId;
  final int toLevel;
  final DateTime endsAtUtc;

  Map<String, dynamic> toJson() =>
      {'node': nodeId, 'ends_at_utc': endsAtUtc.toIso8601String()};
}

/// Save v3 `research` block (GAME_CONTRACT §4.6). The second queue is saved
/// as `task_2` beside `task` so a one-queue save keeps the contract's shape
/// (D-020).
class ResearchState {
  const ResearchState({this.levels = const {}, this.tasks = const []});

  final Map<String, int> levels;

  /// Running tasks in queue order (0–2).
  final List<ResearchTask> tasks;

  Map<String, dynamic> toJson() => {
        'levels': levels,
        'task': tasks.isEmpty ? null : tasks[0].toJson(),
        if (tasks.length > 1) 'task_2': tasks[1].toJson(),
      };

  factory ResearchState.fromJson(Map<String, dynamic> j) {
    final levels = j['levels'];
    if (levels is! Map<String, dynamic>) {
      throw const FormatException('research: needs levels');
    }
    ResearchTask? task(Object? t) {
      if (t == null) return null;
      if (t is! Map<String, dynamic> ||
          t['node'] is! String ||
          t['ends_at_utc'] is! String) {
        throw const FormatException('research: task needs node + ends_at_utc');
      }
      final node = t['node'] as String;
      final lv = levels[node];
      return ResearchTask(
        nodeId: node,
        toLevel: (lv is int ? lv : 0) + 1,
        endsAtUtc: DateTime.parse(t['ends_at_utc'] as String).toUtc(),
      );
    }

    return ResearchState(
      levels: {
        for (final e in levels.entries)
          if (e.value is int) e.key: e.value as int,
      },
      tasks: [
        for (final t in [task(j['task']), task(j['task_2'])])
          if (t != null) t,
      ],
    );
  }
}
