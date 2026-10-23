import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart' as gma;
import 'package:wt_core/wt_core.dart';

/// Google AdMob rewarded ads behind wt_core's [AdNetwork] (T-039, D-033).
/// The app half of the `ads` module: only `AdService` calls it, so caps,
/// placements and the age flags stay in one place.
///
/// AdMob is on Google Play's Families self-certified ads SDK list. Every
/// request is rated G; under-13 / unknown age gets child treatment, and no
/// request is personalized (D-014). We start the SDK and request ads only
/// on the first ad, after the age flags are set; app measurement waits for
/// that too (manifest `DELAY_APP_MEASUREMENT_INIT`). The SDK's own startup
/// provider still loads with the app.
class AdMobNetwork implements AdNetwork {
  AdMobNetwork({String? unitId})
      : unitId = unitId ??
            const String.fromEnvironment('ADMOB_REWARDED_ID',
                // Google's published demo rewarded unit (test ads only)
                defaultValue: 'ca-app-pub-3940256099942544/5224354917');

  /// Rewarded ad unit: `--dart-define=ADMOB_REWARDED_ID=…` for release.
  final String unitId;

  /// A load that takes longer than this counts as failed (no reward, no
  /// cap used) so a child is never left waiting.
  static const loadTimeout = Duration(seconds: 12);

  bool _started = false;

  @override
  Future<AdNetworkResult> showRewarded(AdRequest request) async {
    await gma.MobileAds.instance
        .updateRequestConfiguration(gma.RequestConfiguration(
      maxAdContentRating: gma.MaxAdContentRating.g,
      ageRestrictedTreatment: request.childDirected
          ? gma.AgeRestrictedTreatment.child
          : gma.AgeRestrictedTreatment.unspecified,
    ));
    if (!_started) {
      await gma.MobileAds.instance.initialize();
      _started = true;
    }
    final loaded = Completer<gma.RewardedAd?>();
    await gma.RewardedAd.load(
      adUnitId: unitId,
      request: gma.AdRequest(nonPersonalizedAds: request.nonPersonalized),
      rewardedAdLoadCallback: gma.RewardedAdLoadCallback(
        // an ad that arrives after the timeout is never shown: free it
        onAdLoaded: (ad) =>
            loaded.isCompleted ? ad.dispose() : loaded.complete(ad),
        onAdFailedToLoad: (_) {
          if (!loaded.isCompleted) loaded.complete(null);
        },
      ),
    );
    final ad = await loaded.future.timeout(loadTimeout, onTimeout: () {
      loaded.complete(null); // a late load now disposes itself
      return null;
    });
    if (ad == null) return AdNetworkResult.failed;

    final done = Completer<AdNetworkResult>();
    var earned = false;
    ad.fullScreenContentCallback = gma.FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!done.isCompleted) {
          done.complete(
              earned ? AdNetworkResult.completed : AdNetworkResult.skipped);
        }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (!done.isCompleted) done.complete(AdNetworkResult.failed);
      },
    );
    await ad.show(onUserEarnedReward: (_, __) => earned = true);
    return done.future;
  }
}
