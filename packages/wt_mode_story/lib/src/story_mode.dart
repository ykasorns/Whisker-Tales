import 'dart:convert';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:wt_core/wt_core.dart';

/// Story mode's own save, kept under `modes.story` (MODE_PLUGIN_SPEC §5).
class StorySave extends ModeSaveState {
  StorySave({this.bestDepth = 0, this.runs = 0, List<String>? bossesCleared})
      : bossesCleared = List.unmodifiable(bossesCleared ?? const []);

  final int bestDepth;
  final int runs;
  final List<String> bossesCleared;

  StorySave copyWith(
          {int? bestDepth, int? runs, List<String>? bossesCleared}) =>
      StorySave(
          bestDepth: bestDepth ?? this.bestDepth,
          runs: runs ?? this.runs,
          bossesCleared: bossesCleared ?? this.bossesCleared);
}

/// Walks a fixed number of fights and ends at the chapter boss. A stand-in
/// until the seeded map generator (T-006) replaces it.
class _StubSource implements EncounterSource {
  _StubSource(this.length);
  final int length;

  @override
  Encounter? next(int depth, Random rng) {
    if (depth > length) return null;
    return depth == length
        ? Encounter(
            type: EncounterType.boss, depth: depth, contentId: 'eraserking')
        : Encounter(type: EncounterType.combat, depth: depth);
  }

  @override
  List<EncounterPreview> preview(int depth, int count) => [
        for (var d = depth; d < min(depth + count, length + 1); d++)
          EncounterPreview(
              type: d == length ? EncounterType.boss : EncounterType.combat,
              depth: d),
      ];
}

class _BossWins implements WinCondition {
  @override
  bool isWon(RunResult result) => result.outcome == RunOutcome.won;
}

/// "ท้าทายนิทาน" (D-042). Dormant while its manifest says `enabled: false`.
class StoryMode implements GameMode {
  StoryMode(this.manifest);

  /// Reads `assets/manifest.json` of this package; [load] is the app's
  /// `rootBundle.loadString`.
  static Future<StoryMode> fromAssets(
      Future<String> Function(String) load) async {
    final text = await load('packages/wt_mode_story/assets/manifest.json');
    return StoryMode(
        ModeManifest.fromJson(jsonDecode(text) as Map<String, dynamic>));
  }

  @override
  String get id => 'story';

  @override
  final ModeManifest manifest;

  @override
  Widget buildHubCard(BuildContext context, ModeSaveState state) =>
      const SizedBox.shrink(); // the adventure menu (T-020) draws the card

  @override
  RunConfig createRunConfig(ModeSaveState state) {
    final s = state as StorySave;
    return RunConfig(seed: mixSeed([0x57021, s.runs]));
  }

  @override
  EncounterSource encounterSource(RunConfig config) => _StubSource(9);

  @override
  WinCondition winCondition(RunConfig config) => _BossWins();

  @override
  RewardResult resolveReward(RunResult result, ModeSaveState state) =>
      RewardResult(
          reward: RewardBundle({Currency.goldfish: result.depthReached}));

  @override
  ModeSaveState decodeSave(Map<String, dynamic> json) {
    int n(String k) =>
        switch (json[k]) { final int v when v >= 0 => v, _ => 0 };
    return StorySave(
      bestDepth: n('best_depth'),
      runs: n('runs'),
      bossesCleared: [
        if (json['bosses_cleared'] case final List l) ...l.whereType<String>(),
      ],
    );
  }

  @override
  Map<String, dynamic> encodeSave(ModeSaveState state) {
    final s = state as StorySave;
    return {
      'best_depth': s.bestDepth,
      'runs': s.runs,
      'bosses_cleared': s.bossesCleared,
    };
  }
}
