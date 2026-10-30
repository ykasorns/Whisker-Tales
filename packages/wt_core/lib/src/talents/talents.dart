import 'dart:async';

import '../core/contracts/run_systems.dart';
import '../core/random/seeded_rng.dart';
import '../items/items.dart';
import '../story/story_content.dart';

/// Run-scoped XP, talent choices and effects for Story Challenge.
class TalentSystem implements ITalentSystem {
  TalentSystem({
    required Map<String, StoryTalent> talents,
    required List<int> xpToNext,
    required int seed,
    Set<String> Function()? relicIds,
  })  : _talents = Map.unmodifiable(talents),
        _xpToNext = List.unmodifiable(xpToNext),
        _rng = SeededRng(seed),
        _relicIds = relicIds ?? _noRelics {
    if (_xpToNext.isEmpty || _xpToNext.any((value) => value <= 0)) {
      throw ArgumentError.value(xpToNext, 'xpToNext', 'must contain > 0');
    }
  }

  final Map<String, StoryTalent> _talents;
  final List<int> _xpToNext;
  final SeededRng _rng;
  final Set<String> Function() _relicIds;
  final StoryEffectResolver _effects = const StoryEffectResolver();
  final StreamController<LevelUp> _levelUps =
      StreamController<LevelUp>.broadcast(sync: true);
  final List<String> _selected = [];
  List<String>? _offered;
  int _xp = 0;
  int _level = 0;
  int _pendingPicks = 0;

  static Set<String> _noRelics() => const {};

  int get xp => _xp;
  int get level => _level;
  int get pendingPicks => _pendingPicks;
  List<String> get selectedIds => List.unmodifiable(_selected);

  @override
  Stream<LevelUp> get levelUps => _levelUps.stream;

  @override
  void gainXp(int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount', 'must be >= 0');
    _xp += amount;
    while (_level < _xpToNext.length && _xp >= _xpToNext[_level]) {
      _xp -= _xpToNext[_level];
      _level++;
      _pendingPicks++;
      _levelUps.add(LevelUp(_level));
    }
  }

  @override
  List<String> pickOptions() {
    if (_pendingPicks == 0) return const [];
    if (_offered case final cached?) return cached;

    final eligible = _talents.values
        .where((talent) =>
            !_selected.contains(talent.id) &&
            (talent.requires == null || _selected.contains(talent.requires)))
        .toList();
    final counts = <String, int>{};
    for (final id in _selected) {
      final tree = _talents[id]!.tree;
      counts[tree] = (counts[tree] ?? 0) + 1;
    }

    final result = <StoryTalent>[];
    if (counts.isNotEmpty) {
      final favored =
          counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
      if (favored.value >= 2) {
        final same = eligible.where((t) => t.tree == favored.key).toList();
        if (same.isNotEmpty) result.add(same[_rng.nextBp() % same.length]);
      }
    }

    final pool = eligible.where((t) => !result.contains(t)).toList();
    while (result.length < 3 && pool.isNotEmpty) {
      final total = pool.fold<int>(
          0, (sum, talent) => sum + 1 + (counts[talent.tree] ?? 0) * 2);
      var roll = _rng.nextBp() % total;
      var index = 0;
      for (; index < pool.length; index++) {
        roll -= 1 + (counts[pool[index].tree] ?? 0) * 2;
        if (roll < 0) break;
      }
      result.add(pool.removeAt(index));
    }
    _offered = List.unmodifiable(result.map((t) => t.id));
    return _offered!;
  }

  StoryTalent chooseTalent(String id) {
    if (_pendingPicks == 0) throw StateError('no pending talent pick');
    final options = pickOptions();
    if (!options.contains(id)) {
      throw ArgumentError.value(id, 'id', 'talent was not offered');
    }
    final talent = _talents[id]!;
    _selected.add(id);
    _pendingPicks--;
    _offered = null;
    return talent;
  }

  @override
  void resolve(EffectTrigger trigger, EffectContext ctx) {
    final relics = _relicIds();
    for (final id in _selected) {
      final talent = _talents[id]!;
      for (final effect in talent.effects) {
        if (effect.trigger == trigger) _effects.apply(effect, ctx);
      }
      for (final synergy in talent.crossSynergies) {
        if (relics.contains(synergy.relicId) &&
            synergy.effect.trigger == trigger) {
          _effects.apply(synergy.effect, ctx);
        }
      }
    }
  }

  void dispose() => _levelUps.close();
}
