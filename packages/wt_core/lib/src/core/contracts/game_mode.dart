import 'dart:math';

import 'package:flutter/widgets.dart';

import 'rewards.dart';

/// Encounter kinds and their target share (GDD v0.3 §3.3).
enum EncounterType { combat, treasure, event, campfire, shop, fork, boss }

/// One stop on a run's path. Payload ids point into design/data JSON.
class Encounter {
  const Encounter({required this.type, required this.depth, this.contentId});

  final EncounterType type;
  final int depth;

  /// Monster/event/shop id, or null where the type needs none.
  final String? contentId;
}

/// What the floating node map draws ahead of the player (GDD v0.3 §3.4).
class EncounterPreview {
  const EncounterPreview({required this.type, required this.depth});
  final EncounterType type;
  final int depth;
}

/// Where a mode's encounters come from — the main difference between modes
/// (MODE_PLUGIN_SPEC §3).
abstract class EncounterSource {
  /// Next encounter, or null when the mode's structure is finished.
  Encounter? next(int depth, Random rng);

  /// Upcoming encounters for the node map; infinite modes return what is
  /// visible.
  List<EncounterPreview> preview(int depth, int count);
}

/// Per-run settings a mode derives from its save (difficulty, seed, modifiers).
class RunConfig {
  const RunConfig({required this.seed, this.modifiers = const {}});
  final int seed;
  final Map<String, Object> modifiers;
}

enum RunOutcome { won, died, abandoned }

/// Summary handed to [GameMode.resolveReward] when a run ends.
class RunResult {
  const RunResult({
    required this.outcome,
    required this.depthReached,
    this.bossesCleared = const [],
  });

  final RunOutcome outcome;
  final int depthReached;
  final List<String> bossesCleared;
}

/// When a run counts as finished-and-won (MODE_PLUGIN_SPEC §3).
abstract class WinCondition {
  bool isWon(RunResult result);
}

/// Rewards a mode grants for a run; currencies and flags only from the
/// shared vocabulary (MODE_PLUGIN_SPEC §7, §10).
class RewardResult {
  const RewardResult(
      {required this.reward, this.flags = const [], this.cosmetics = const []});

  final RewardBundle reward;
  final List<String> flags;
  final List<String> cosmetics;
}

/// Opaque per-mode save; core stores it under `modes.<id>` without reading it
/// (MODE_PLUGIN_SPEC §5, GAME_CONTRACT §4.6).
abstract class ModeSaveState {}

/// Unlock vocabulary for mode manifests (MODE_PLUGIN_SPEC §4).
enum UnlockType { flag, fishTotal, bossCleared }

class UnlockRule {
  const UnlockRule({required this.type, required this.value});

  factory UnlockRule.fromJson(Map<String, dynamic> json) {
    final type = switch (json['type']) {
      'flag' => UnlockType.flag,
      'fish_total' => UnlockType.fishTotal,
      'boss_cleared' => UnlockType.bossCleared,
      final other => throw FormatException('Unknown unlock type: $other'),
    };
    final key = switch (type) {
      UnlockType.flag => 'flag',
      UnlockType.fishTotal => 'amount',
      UnlockType.bossCleared => 'boss',
    };
    final value = json[key];
    if (value == null) {
      throw FormatException('unlock.$key is required for ${json['type']}');
    }
    return UnlockRule(type: type, value: value as Object);
  }

  final UnlockType type;

  /// Flag name, fish amount or boss id depending on [type].
  final Object value;
}

/// `packages/wt_mode_<id>/assets/manifest.json` (MODE_PLUGIN_SPEC §4).
class ModeManifest {
  const ModeManifest({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.icon,
    required this.order,
    required this.enabled,
    required this.minAppVersion,
    this.unlock,
  });

  factory ModeManifest.fromJson(Map<String, dynamic> json) {
    T req<T>(String key) {
      final v = json[key];
      if (v is! T) {
        throw FormatException('manifest.$key must be $T, got ${v.runtimeType}');
      }
      return v;
    }

    final unlock = json['unlock'];
    return ModeManifest(
      id: req<String>('id'),
      nameTh: req<String>('name_th'),
      nameEn: req<String>('name_en'),
      icon: req<String>('icon'),
      order: req<int>('order'),
      enabled: req<bool>('enabled'),
      minAppVersion: req<String>('min_app_version'),
      unlock: unlock == null
          ? null
          : UnlockRule.fromJson(unlock as Map<String, dynamic>),
    );
  }

  final String id;
  final String nameTh;
  final String nameEn;
  final String icon;
  final int order;
  final bool enabled;
  final String minAppVersion;

  /// Null = always unlocked.
  final UnlockRule? unlock;
}

/// A run-based side mode plugged in from its own package (MODE_PLUGIN_SPEC §3).
/// The idle main loop is not a GameMode (D-002, spec §10).
abstract class GameMode {
  /// Stable for life; used as the save namespace `modes.<id>`.
  String get id;

  ModeManifest get manifest;

  /// Menu card shown in the adventure menu.
  Widget buildHubCard(BuildContext context, ModeSaveState state);

  RunConfig createRunConfig(ModeSaveState state);

  EncounterSource encounterSource(RunConfig config);

  WinCondition winCondition(RunConfig config);

  RewardResult resolveReward(RunResult result, ModeSaveState state);

  ModeSaveState decodeSave(Map<String, dynamic> json);

  Map<String, dynamic> encodeSave(ModeSaveState state);
}

/// Where modes register (MODE_PLUGIN_SPEC §2, §4; GDD v0.4 §9); the
/// adventure menu is built from here sorted by
/// `manifest.order`. Implemented by T-031.
abstract class IModeRegistry {
  void register(GameMode mode);

  /// All registered modes, sorted by [ModeManifest.order].
  List<GameMode> get modes;

  GameMode? byId(String id);
}
