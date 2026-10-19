import '../core/contracts/idle_loop.dart';
import '../core/contracts/rewards.dart';
import 'idle_rules.dart';

/// The one income formula for online waves and offline time (T-034/T-035).
class IncomeModel implements IIncomeModel {
  IncomeModel(this.rules, {required this.expPerKill});

  final IdleRules rules;

  /// `CatRules.expPerKill` (T-044), injected so idle_loop does not import cat.
  final int Function(int page) expPerKill;

  @override
  Map<Currency, int> perWaveMilli(int page) => rules.perWaveMilli(page);

  @override
  RewardBundle perWave(int page) => forWaves(page, 1);

  @override
  RewardBundle forWaves(int page, int waves) {
    if (waves < 0) throw ArgumentError.value(waves, 'waves', 'must be >= 0');
    return RewardBundle({
      for (final e in perWaveMilli(page).entries)
        e.key: e.value * waves ~/ 1000,
    });
  }

  @override
  int expForWaves(int page, int waves) {
    final (lo, hi) = rules.monstersByChapter[rules.chapterOf(page) - 1];
    return waves * (lo + hi) * 500 * expPerKill(page) ~/ 1000;
  }

  @override
  double get wavesPerMinute => rules.wavesPerMinute;
}
