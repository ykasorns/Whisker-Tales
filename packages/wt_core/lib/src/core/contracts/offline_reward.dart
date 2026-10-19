import 'rewards.dart';

/// Result of an offline-reward computation.
class OfflineRewardResult {
  const OfflineRewardResult({
    required this.creditedMinutes,
    required this.cappedAtMinutes,
    required this.reward,
    this.waves = 0,
    this.exp = 0,
  });

  static const none = OfflineRewardResult(
      creditedMinutes: 0, cappedAtMinutes: 0, reward: RewardBundle.emptyConst);

  /// Minutes actually paid out (0 if the clock moved backwards).
  final int creditedMinutes;
  final int cappedAtMinutes;
  final RewardBundle reward;

  /// Waves the cat "farmed" while away.
  final int waves;

  /// Cat EXP for those waves (same formula as online, T-044).
  final int exp;
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
