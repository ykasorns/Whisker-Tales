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

  /// Cuts the running task by max(30 min, 25% of remaining) after a
  /// completed rewarded ad. False if no task is running or no ad is left.
  Future<bool> speedUpWithAd();

  Stream<ResearchCompleted> get completed;
}
