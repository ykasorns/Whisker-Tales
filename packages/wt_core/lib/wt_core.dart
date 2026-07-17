/// Public API barrel for wt_core. Every consumer outside this package
/// (app/, packages/wt_mode_*) must import this file only — never
/// package:wt_core/src/... directly (GAME_CONTRACT.md §3).
library wt_core;

export 'src/core/layout.dart';
