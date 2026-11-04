import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_dungeon/wt_mode_dungeon.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

/// Registers available game modes with wt_core's ModeRegistry — the single
/// file touched when adding a mode package (MODE_PLUGIN_SPEC.md §2).
/// A mode that ships dormant still registers here: its manifest says
/// `enabled: false`, and the adventure menu skips it.
Future<ModeRegistry> registerModes(
    StoryContent story, Map<String, dynamic> dungeonJson) async {
  final registry = ModeRegistry();
  registry.register(await StoryMode.fromAssets(rootBundle.loadString, story));
  registry.register(await DungeonMode.fromAssets(
      rootBundle.loadString, DungeonRules.fromJson(dungeonJson)));
  return registry;
}

/// `design/data/dungeon.json` from the app bundle (D-065).
Future<Map<String, dynamic>> loadDungeonJson(ContentSource source) async =>
    jsonDecode(await source.read('design/data/dungeon.json'))
        as Map<String, dynamic>;
