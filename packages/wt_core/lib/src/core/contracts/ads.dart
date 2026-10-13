enum AdOutcome { rewarded, skipped, failed, capped }

/// Rewarded ads, the only module allowed to touch an ad SDK
/// (GAME_CONTRACT §5 v2.0). Placements, per-placement and total daily caps
/// and `no_ads_behavior` come from idle_balance_v1.json `ads` (D-003).
/// Requests are child-directed / non-personalized unless the age band is
/// `13plus`. Owner: `ads` (T-039).
abstract class IAdService {
  bool canShow(String placementId);

  /// Grant the placement's reward only on [AdOutcome.rewarded].
  Future<AdOutcome> show(String placementId);

  int remainingToday(String placementId);
}
