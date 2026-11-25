import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No store on the web yet: nothing to buy (2026-11-25, no web income at
/// launch).
const platformHasStore = false;

/// No ad SDK on the web: every ad placement is switched off.
const platformHasAds = false;

/// The web build keeps wt_core's defaults: no store (nothing to buy), no
/// cloud save yet (the account save comes in a later phase).
List<Override> platformOverrides() => const [];
