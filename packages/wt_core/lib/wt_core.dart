/// Public API barrel for wt_core. Every consumer outside this package
/// (app/, packages/wt_mode_*) must import this file only — never
/// package:wt_core/src/... directly (GAME_CONTRACT.md §3).
library wt_core;

export 'src/ads/ads.dart';
export 'src/age/age_gate.dart';
export 'src/audio/audio.dart';
export 'src/avatar/avatar.dart';
export 'src/cat/cat.dart';
export 'src/combat/combat.dart';
export 'src/gear/gear.dart';
export 'src/core/ad_gifts.dart';
export 'src/core/clock/game_clock.dart';
export 'src/core/cloud_sync.dart';
export 'src/core/content_repository.dart';
export 'src/core/contracts/ads.dart';
export 'src/core/game_save.dart';
export 'src/core/contracts/cat_class.dart';
export 'src/core/contracts/age_gate.dart';
export 'src/core/contracts/combat.dart';
export 'src/core/contracts/game_mode.dart';
export 'src/core/contracts/gear_basket.dart';
export 'src/core/contracts/idle_loop.dart';
export 'src/core/contracts/offline_reward.dart';
export 'src/core/contracts/pets.dart';
export 'src/core/contracts/research.dart';
export 'src/core/contracts/rewards.dart';
export 'src/core/contracts/run_systems.dart';
export 'src/core/contracts/services.dart';
export 'src/core/contracts/wallet.dart';
export 'src/core/contracts/wardrobe.dart';
export 'src/core/layout.dart';
export 'src/core/providers.dart';
export 'src/core/random/seeded_rng.dart';
export 'src/core/state/game_state.dart';
export 'src/core/wallet/memory_wallet.dart';
export 'src/iap/iap.dart';
export 'src/idle/idle.dart';
export 'src/offline/offline_reward.dart';
export 'src/pets/pets.dart';
export 'src/research/research.dart';
export 'src/save/save.dart';
export 'src/wardrobe/wardrobe.dart';
