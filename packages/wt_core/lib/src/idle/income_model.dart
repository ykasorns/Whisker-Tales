import '../core/contracts/combat.dart';
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
  RewardBundle forWaves(int page, int waves, {int fishBp = 0}) {
    if (waves < 0) throw ArgumentError.value(waves, 'waves', 'must be >= 0');
    return RewardBundle({
      for (final e in perWaveMilli(page).entries)
        e.key: withFind(e.key, e.value, fishBp) * waves ~/ 1000,
    });
  }

  /// [milli] of [c] with the goldfish find applied (other currencies as is).
  static int withFind(Currency c, int milli, int fishBp) =>
      c == Currency.goldfish ? milli * (kBp + fishBp) ~/ kBp : milli;

  @override
  int expForWaves(int page, int waves, {int expBp = 0}) {
    final (lo, hi) = rules.monstersByChapter[rules.chapterOf(page) - 1];
    return waves *
        (lo + hi) *
        500 *
        expPerKill(page) ~/
        1000 *
        (kBp + expBp) ~/
        kBp;
  }

  @override
  double get wavesPerMinute => rules.wavesPerMinute;
}
