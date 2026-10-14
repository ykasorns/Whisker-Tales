/// Public API barrel for wt_core. Every consumer outside this package
/// (app/, packages/wt_mode_*) must import this file only — never
/// package:wt_core/src/... directly (GAME_CONTRACT.md §3).
library wt_core;

export 'src/core/clock/game_clock.dart';
export 'src/core/contracts/ads.dart';
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
export 'src/core/layout.dart';
export 'src/core/providers.dart';
export 'src/core/state/game_state.dart';
