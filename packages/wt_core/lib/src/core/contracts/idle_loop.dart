import 'rewards.dart';

/// Where the player is in the book (GDD v0.4 §2.2): book → chapter → page.
class IdleProgress {
  const IdleProgress({
    required this.book,
    required this.clearedPage,
    required this.farmPage,
  });

  final int book;

  /// Highest page whose boss has been beaten (0 = none).
  final int clearedPage;

  /// Page whose waves are being farmed right now.
  final int farmPage;
}

sealed class IdleEvent {
  const IdleEvent();
}

class WaveCleared extends IdleEvent {
  const WaveCleared({required this.page, required this.reward});
  final int page;
  final RewardBundle reward;
}

class BossResult extends IdleEvent {
  const BossResult(
      {required this.page, required this.won, required this.reward});
  final int page;
  final bool won;

  /// Empty when [won] is false — losing costs nothing (GDD v0.4 §1 Fail Forward).
  final RewardBundle reward;
}

/// Main idle loop — a core module, not a GameMode plugin (D-002,
/// MODE_PLUGIN_SPEC §10). Owner: `idle_loop` (T-034). GDD v0.4 §2.
abstract class IIdleLoop {
  IdleProgress get state;
  Stream<IdleEvent> get events;

  /// Fights the boss of `clearedPage + 1`.
  Future<BossResult> challengeBoss();
}

/// Income per wave for a page; shared by the online loop and offline rewards
/// so the two can never drift (T-034, T-035). GDD v0.4 §8, §15.
abstract class IIncomeModel {
  RewardBundle perWave(int page);

  /// Waves cleared per minute of farming.
  double get wavesPerMinute;
}
