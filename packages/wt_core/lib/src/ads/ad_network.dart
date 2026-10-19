/// What the ad SDK is asked for. Built only by [AdService] so every request
/// carries the age-band flags (GDD v0.4 §14, D-002 Q6).
class AdRequest {
  const AdRequest({
    required this.placementId,
    required this.childDirected,
    required this.nonPersonalized,
  });
  final String placementId;
  final bool childDirected;
  final bool nonPersonalized;
}

enum AdNetworkResult { completed, skipped, failed }

/// The seam to a real rewarded-ad SDK (Families self-certified, chosen by
/// Opus and logged in DECISIONS before integration). Only the `ads` module
/// may implement or call it (GAME_CONTRACT §5).
abstract class AdNetwork {
  Future<AdNetworkResult> showRewarded(AdRequest request);
}

/// Dev/test network: answers with [next] and records every request.
class FakeAdNetwork implements AdNetwork {
  FakeAdNetwork({this.next = AdNetworkResult.completed});

  AdNetworkResult next;
  final requests = <AdRequest>[];

  @override
  Future<AdNetworkResult> showRewarded(AdRequest request) async {
    requests.add(request);
    return next;
  }
}
