import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:wt_core/wt_core.dart';

/// Story mode's own save, kept under `modes.story` (MODE_PLUGIN_SPEC §5).
class StorySave extends ModeSaveState {
  StorySave({
    this.bestDepth = 0,
    this.runs = 0,
    this.rewardDay = '',
    this.rewardRunsToday = 0,
    List<String>? bossesCleared,
  }) : bossesCleared = List.unmodifiable(bossesCleared ?? const []);

  final int bestDepth;
  final int runs;
  final String rewardDay;
  final int rewardRunsToday;
  final List<String> bossesCleared;

  StorySave copyWith(
          {int? bestDepth,
          int? runs,
          String? rewardDay,
          int? rewardRunsToday,
          List<String>? bossesCleared}) =>
      StorySave(
          bestDepth: bestDepth ?? this.bestDepth,
          runs: runs ?? this.runs,
          rewardDay: rewardDay ?? this.rewardDay,
          rewardRunsToday: rewardRunsToday ?? this.rewardRunsToday,
          bossesCleared: bossesCleared ?? this.bossesCleared);
}

class _BossWins implements WinCondition {
  const _BossWins(this.bossId);
  final String bossId;

  @override
  bool isWon(RunResult result) => result.bossesCleared.contains(bossId);
}

/// "ท้าทายนิทาน" (D-042), registered through the mode manifest.
class StoryMode implements GameMode, DailyRunMode, RunProgressMode {
  StoryMode(this.manifest, this.content);

  final StoryContent content;

  /// Reads `assets/manifest.json` of this package; [load] is the app's
  /// `rootBundle.loadString`.
  static Future<StoryMode> fromAssets(
      Future<String> Function(String) load, StoryContent content) async {
    final text = await load('packages/wt_mode_story/assets/manifest.json');
    return StoryMode(
        ModeManifest.fromJson(jsonDecode(text) as Map<String, dynamic>),
        content);
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
  EncounterSource encounterSource(RunConfig config) {
    final enemies = content.monsters.values.where((m) => !m.isBoss).toList();
    final boss = content.monsters.values.singleWhere((m) => m.isBoss);
    return MapEncounterSource(SeededEncounterGenerator(
      combatIds: [for (final m in enemies) m.id],
      eventIds: content.events.keys.toList(),
      bossId: boss.id,
    ).generate(config.seed));
  }

  @override
  WinCondition winCondition(RunConfig config) =>
      _BossWins(content.monsters.values.singleWhere((m) => m.isBoss).id);

  @override
  RewardResult resolveReward(RunResult result, ModeSaveState state) {
    final rules = content.balance;
    final base = result.depthReached * rules.goldfishPerNode +
        (result.outcome == RunOutcome.won ? rules.victoryBonus : 0);
    final multiplier = result.completedRunsToday < rules.fullRewardRuns
        ? kBp
        : rules.repeatRewardPct * 100;
    return RewardResult(
        reward: RewardBundle({Currency.goldfish: base * multiplier ~/ kBp}));
  }

  @override
  int completedRunsOn(ModeSaveState state, String dayKey) {
    final s = state as StorySave;
    return s.rewardDay == dayKey ? s.rewardRunsToday : 0;
  }

  @override
  ModeSaveState updateAfterRun(RunResult result, ModeSaveState state) {
    final s = state as StorySave;
    final counts = result.outcome != RunOutcome.abandoned;
    final bosses = {...s.bossesCleared, ...result.bossesCleared}.toList();
    return s.copyWith(
      bestDepth:
          result.depthReached > s.bestDepth ? result.depthReached : s.bestDepth,
      runs: s.runs + (counts ? 1 : 0),
      rewardDay: counts ? result.dayKey : s.rewardDay,
      rewardRunsToday:
          counts ? result.completedRunsToday + 1 : s.rewardRunsToday,
      bossesCleared: bosses,
    );
  }

  @override
  ModeSaveState decodeSave(Map<String, dynamic> json) {
    int n(String k) =>
        switch (json[k]) { final int v when v >= 0 => v, _ => 0 };
    return StorySave(
      bestDepth: n('best_depth'),
      runs: n('runs'),
      rewardDay: json['reward_day'] as String? ?? '',
      rewardRunsToday: n('reward_runs_today'),
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
      'reward_day': s.rewardDay,
      'reward_runs_today': s.rewardRunsToday,
      'bosses_cleared': s.bossesCleared,
    };
  }
}
