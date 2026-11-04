import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wt_core/wt_core.dart';

import 'dungeon_rules.dart';

/// The dungeon's own save, under `modes.dungeon`.
class DungeonSave extends ModeSaveState {
  DungeonSave({
    this.day = '',
    this.runsToday = 0,
    this.unlocked = 1,
    Map<int, int>? bestTier,
  }) : bestTier = Map.unmodifiable(bestTier ?? const {});

  /// The date key `runsToday` belongs to.
  final String day;
  final int runsToday;

  /// Highest level that may be entered.
  final int unlocked;

  /// Best tier reached per level.
  final Map<int, int> bestTier;

  /// Runs used today; yesterday's count is gone.
  int usedOn(String dayKey) => day == dayKey ? runsToday : 0;

  DungeonSave copyWith(
          {String? day,
          int? runsToday,
          int? unlocked,
          Map<int, int>? bestTier}) =>
      DungeonSave(
          day: day ?? this.day,
          runsToday: runsToday ?? this.runsToday,
          unlocked: unlocked ?? this.unlocked,
          bestTier: bestTier ?? this.bestTier);
}

/// "ถ้ำขนมแมว" (D-065): one boss, 30 seconds, treats by damage dealt. Runs
/// are daily counts that reset with the date, never a timer that refills.
class DungeonMode implements GameMode {
  DungeonMode(this.manifest, this.rules);

  final DungeonRules rules;

  static Future<DungeonMode> fromAssets(
      Future<String> Function(String) load, DungeonRules rules) async {
    final text = await load('packages/wt_mode_dungeon/assets/manifest.json');
    return DungeonMode(
        ModeManifest.fromJson(jsonDecode(text) as Map<String, dynamic>), rules);
  }

  @override
  String get id => 'dungeon';

  @override
  final ModeManifest manifest;

  /// Runs left today: the free ones plus one per ad watched.
  int entriesLeft(DungeonSave s, String dayKey, int adsWatchedToday) =>
      math.max(0, rules.freeRunsPerDay + adsWatchedToday - s.usedOn(dayKey));

  @override
  Widget buildHubCard(BuildContext context, ModeSaveState state) =>
      const SizedBox.shrink(); // the adventure menu draws the card

  @override
  RunConfig createRunConfig(ModeSaveState state) =>
      RunConfig(seed: mixSeed([0xD06E, (state as DungeonSave).runsToday]));

  @override
  EncounterSource encounterSource(RunConfig config) => _OneBoss();

  @override
  WinCondition winCondition(RunConfig config) => const _NeverWon();

  @override
  RewardResult resolveReward(RunResult result, ModeSaveState state) =>
      RewardResult(reward: RewardBundle.empty);

  @override
  ModeSaveState decodeSave(Map<String, dynamic> json) {
    int n(Object? v, int min) => v is int && v >= min ? v : min;
    final tiers = <int, int>{};
    if (json['best_tier'] case final Map m) {
      for (final e in m.entries) {
        final level = int.tryParse('${e.key}');
        if (level != null &&
            level >= 1 &&
            level <= rules.maxLevel &&
            e.value is int &&
            (e.value as int) >= 0 &&
            (e.value as int) <= rules.tiers.length) {
          tiers[level] = e.value as int;
        }
      }
    }
    return DungeonSave(
      day: json['day'] as String? ?? '',
      runsToday: n(json['runs_today'], 0),
      unlocked: math.min(rules.maxLevel, n(json['unlocked'], 1)),
      bestTier: tiers,
    );
  }

  @override
  Map<String, dynamic> encodeSave(ModeSaveState state) {
    final s = state as DungeonSave;
    return {
      'day': s.day,
      'runs_today': s.runsToday,
      'unlocked': s.unlocked,
      'best_tier': {for (final e in s.bestTier.entries) '${e.key}': e.value},
    };
  }
}

class _OneBoss implements EncounterSource {
  @override
  Encounter? next(int depth, math.Random rng) => depth == 0
      ? const Encounter(
          type: EncounterType.boss, depth: 0, contentId: 'dungeon_boss')
      : null;

  @override
  List<EncounterPreview> preview(int depth, int count) => const [];
}

class _NeverWon implements WinCondition {
  const _NeverWon();
  @override
  bool isWon(RunResult result) => false;
}
