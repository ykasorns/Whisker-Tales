import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../ads/admob_network.dart';
import '../cloud/play_cloud.dart';
import '../iap/play_store.dart';

/// True when this build can sell packs (a store to pay through).
const platformHasStore = true;

/// True when this build has a rewarded-ad SDK.
const platformHasAds = true;

/// Google Play services for the Android build. Billing is created here, at
/// boot, so no purchase is missed.
List<Override> platformOverrides() => [
      iapStoreProvider.overrideWithValue(PlayIapStore()),
      cloudStoreProvider.overrideWithValue(const PlayCloudStore()),
      // AdMob rewarded ads (D-033); caps and age flags stay in AdService
      adNetworkProvider.overrideWithValue(AdMobNetwork()),
    ];
