import 'package:flutter/services.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

/// Registers available game modes with wt_core's ModeRegistry — the single
/// file touched when adding a mode package (MODE_PLUGIN_SPEC.md §2).
/// A mode that ships dormant still registers here: its manifest says
/// `enabled: false`, and the adventure menu skips it.
Future<ModeRegistry> registerModes() async {
  final registry = ModeRegistry();
  registry.register(await StoryMode.fromAssets(rootBundle.loadString));
  return registry;
}
