import 'rewards.dart';

/// Result of an offline-reward computation.
class OfflineRewardResult {
  const OfflineRewardResult({
    required this.creditedMinutes,
    required this.cappedAtMinutes,
    required this.reward,
  });

  /// Minutes actually paid out (0 if the clock moved backwards).
  final int creditedMinutes;
  final int cappedAtMinutes;
  final RewardBundle reward;
}

/// Offline rewards (GDD v0.4 §8): `clamp(effectiveNow − lastSeen, 0, cap)`
/// × income per minute. Owner: `offline_reward` (T-035).
abstract class IOfflineReward {
  /// Cap = 8 h + 10 min per `offline_cap` research level (D-002 Q3).
  OfflineRewardResult compute({
    required DateTime lastSeenUtc,
    required DateTime effectiveNowUtc,
    required Duration cap,
  });

  /// Pays out the pending reward and marks the window consumed.
  RewardBundle claim();
}
