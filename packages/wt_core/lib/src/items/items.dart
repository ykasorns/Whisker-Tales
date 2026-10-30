import 'dart:async';

import '../core/contracts/combat.dart';
import '../core/contracts/run_systems.dart';
import '../core/random/seeded_rng.dart';
import '../story/story_content.dart';

/// Combat context shared by relic and talent effect resolvers.
///
/// The run owns [rng], so chance checks resume from the same deterministic
/// stream after a save/load instead of using wall-clock randomness.
class RunEffectContext implements EffectContext {
  const RunEffectContext({
    required this.ownerUnitId,
    required this.buffEngine,
    required SeededRng rng,
    this.enemyUnitId,
  }) : _rng = rng;

  @override
  final String ownerUnitId;

  @override
  final String? enemyUnitId;

  @override
  final IBuffEngine buffEngine;

  final SeededRng _rng;

  @override
  int nextBasisPoint() => _rng.nextBp();
}

/// Routes Story data effects into combat without owning any combat formulas.
/// Relics and talents share this resolver so target/chance semantics cannot
/// drift between the two systems.
class StoryEffectResolver {
  const StoryEffectResolver();

  bool apply(StoryEffect effect, EffectContext ctx) {
    final targetId = switch (effect.target) {
      StoryEffectTarget.self => ctx.ownerUnitId,
      StoryEffectTarget.enemy => ctx.enemyUnitId,
    };
    if (targetId == null) return false;
    if (effect.chancePct < 100 &&
        ctx.nextBasisPoint() >= effect.chancePct * 100) {
      return false;
    }
    ctx.buffEngine.apply(targetId, effect.buffId, sourceId: ctx.ownerUnitId);
    return true;
  }
}

/// Detects active relic pairs and emits only newly activated pairs.
class SynergyResolver implements ISynergyResolver {
  SynergyResolver(Map<String, StoryRelic> relics)
      : _relics = Map.unmodifiable(relics);

  final Map<String, StoryRelic> _relics;
  final Set<String> _owned = {};
  final Map<String, (String, String)> _active = {};
  final StreamController<SynergyActivated> _controller =
      StreamController<SynergyActivated>.broadcast(sync: true);

  @override
  List<(String, String)> get activePairs {
    final pairs = _active.values.toList()
      ..sort((a, b) => _key(a.$1, a.$2).compareTo(_key(b.$1, b.$2)));
    return List.unmodifiable(pairs);
  }

  @override
  Stream<SynergyActivated> get activations => _controller.stream;

  /// Recomputes pairs from the complete run inventory. Removing a relic
  /// immediately removes every pair that depends on it.
  void updateRelics(Iterable<String> relicIds) {
    _owned
      ..clear()
      ..addAll(relicIds);
    final next = <String, (String, String)>{};
    for (final relicId in _owned) {
      final relic = _relics[relicId];
      if (relic == null) continue;
      for (final synergy in relic.synergies) {
        if (!_owned.contains(synergy.withRelic)) continue;
        final key = _key(relic.id, synergy.withRelic);
        next[key] = (relic.id, synergy.withRelic);
      }
    }
    for (final entry in next.entries) {
      if (!_active.containsKey(entry.key)) {
        _controller.add(SynergyActivated(entry.value.$1, entry.value.$2));
      }
    }
    _active
      ..clear()
      ..addAll(next);
  }

  void dispose() => _controller.close();

  static String _key(String a, String b) =>
      a.compareTo(b) <= 0 ? '$a+$b' : '$b+$a';
}

/// Run-scoped relic inventory and data-driven effect resolver.
class ItemSystem implements IItemSystem {
  ItemSystem(Map<String, StoryRelic> relics)
      : _relics = Map.unmodifiable(relics),
        synergies = SynergyResolver(relics);

  final Map<String, StoryRelic> _relics;
  final Set<String> _owned = {};
  final Map<String, int> _levels = {};
  final StoryEffectResolver _effects = const StoryEffectResolver();
  final SynergyResolver synergies;

  Set<String> get relicIds => Set.unmodifiable(_owned);

  int levelOf(String id) => _levels[id] ?? 0;

  @override
  void addRelic(String id) {
    if (!_relics.containsKey(id)) {
      throw ArgumentError.value(id, 'id', 'unknown relic');
    }
    if (_owned.add(id)) {
      _levels[id] = 1;
      synergies.updateRelics(_owned);
    }
  }

  void upgradeRelic(String id) {
    if (!_owned.contains(id)) {
      throw ArgumentError.value(id, 'id', 'relic is not owned');
    }
    _levels[id] = (_levels[id] ?? 1) + 1;
  }

  void removeRelic(String id) {
    if (_owned.remove(id)) {
      _levels.remove(id);
      synergies.updateRelics(_owned);
    }
  }

  @override
  void resolve(EffectTrigger trigger, EffectContext ctx) {
    for (final relicId in _owned) {
      final relic = _relics[relicId]!;
      for (final effect in relic.effects) {
        if (effect.trigger == trigger) {
          for (var i = 0; i < levelOf(relicId); i++) {
            _effects.apply(effect, ctx);
          }
        }
      }
      for (final synergy in relic.synergies) {
        if (_owned.contains(synergy.withRelic) &&
            synergy.effect.trigger == trigger) {
          _effects.apply(synergy.effect, ctx);
        }
      }
    }
  }
}
