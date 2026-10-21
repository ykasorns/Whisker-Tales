import 'rewards.dart';

/// Where the player is in the book (GDD v0.4 §2.2): book → chapter → page.
/// Pages are numbered across books (page 31 = book 2, chapter 1, page 1).
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

  @override
  bool operator ==(Object other) =>
      other is IdleProgress &&
      other.book == book &&
      other.clearedPage == clearedPage &&
      other.farmPage == farmPage;

  @override
  int get hashCode => Object.hash(book, clearedPage, farmPage);

  @override
  String toString() =>
      'IdleProgress(book $book, cleared $clearedPage, farm $farmPage)';
}

/// What a page holds (GDD v0.5.2 §9.1), known before the first wave so the
/// UI can show ○○○ on the page sign. Same page → same plan, always.
class PagePlan {
  const PagePlan({
    required this.page,
    required this.chapter,
    required this.monstersPerWave,
    required this.isLong,
  });

  final int page;

  /// 1-based chapter inside its book.
  final int chapter;

  /// One entry per wave before the boss opens; farming past the plan cycles
  /// through it again.
  final List<int> monstersPerWave;

  /// Page 5 / 10 of a chapter: extra waves.
  final bool isLong;

  int get waves => monstersPerWave.length;

  /// Monsters in wave [index] (0-based; cycles past [waves]).
  int monstersIn(int index) => monstersPerWave[index % waves];
}

sealed class IdleEvent {
  const IdleEvent();
}

class WaveCleared extends IdleEvent {
  const WaveCleared({
    required this.page,
    required this.reward,
    this.waveIndex = 0,
    this.exp = 0,
  });
  final int page;
  final RewardBundle reward;

  /// Waves cleared on this page before this one.
  final int waveIndex;

  /// Cat EXP earned (GDD v0.5 §3.1); granted by whoever owns the cat.
  final int exp;
}

class BossResult extends IdleEvent {
  const BossResult({
    required this.page,
    required this.won,
    required this.reward,
    this.exp = 0,
  });
  final int page;
  final bool won;

  /// Empty when [won] is false — losing costs nothing (GDD v0.4 §1 Fail Forward).
  final RewardBundle reward;
  final int exp;
}

/// The cat lost a wave; it rests and tries again (no cost).
class WaveFailed extends IdleEvent {
  const WaveFailed({required this.page, required this.waveIndex});
  final int page;
  final int waveIndex;
}

/// Main idle loop — a core module, not a GameMode plugin (D-002,
/// MODE_PLUGIN_SPEC §10). Owner: `idle_loop` (T-034). GDD v0.4 §2, v0.5.2 §9.
abstract class IIdleLoop {
  IdleProgress get state;
  Stream<IdleEvent> get events;

  /// Fights the boss of `clearedPage + 1` once the page's waves are done.
  Future<BossResult> challengeBoss();
}

/// The cat's goldfish / EXP find (gear affixes `fish_find`, `exp_find`), in
/// basis points: +800 = +8% goldfish from waves, bosses and offline time.
typedef Finds = ({int fishBp, int expBp});

/// Income per wave for a page; shared by the online loop and offline rewards
/// so the two can never drift (T-034, T-035). GDD v0.4 §8, §15.
abstract class IIncomeModel {
  /// One wave's reward rounded down (fractions such as 0.1 yarn show as 0;
  /// use [forWaves] or [perWaveMilli] to add up several waves).
  RewardBundle perWave(int page);

  /// One wave's reward in thousandths of a unit.
  Map<Currency, int> perWaveMilli(int page);

  /// Reward for [waves] waves on [page], rounded down once at the end;
  /// [fishBp] = goldfish find.
  RewardBundle forWaves(int page, int waves, {int fishBp = 0});

  /// Cat EXP for [waves] waves on [page], using the chapter's average
  /// monsters per wave (offline); online play counts real kills. [expBp] =
  /// EXP find.
  int expForWaves(int page, int waves, {int expBp = 0});

  /// Waves cleared per minute of farming.
  double get wavesPerMinute;
}

/// Good or bad road event (GDD v0.5.2 §9.2).
enum RoadEventKind { good, bad }

/// A road event in effect. [wavesLeft] counts down per wave cleared and per
/// boss fight; it never counts real time.
class ActiveRoadEvent {
  const ActiveRoadEvent({
    required this.uid,
    required this.eventId,
    required this.kind,
    required this.wavesLeft,
    this.boosted = false,
  });

  /// Unique per occurrence (the same event can come back later).
  final String uid;
  final String eventId;
  final RoadEventKind kind;
  final int wavesLeft;

  /// Made longer with a rewarded ad.
  final bool boosted;
}

sealed class RoadEventNews {
  const RoadEventNews();
}

class RoadEventStarted extends RoadEventNews {
  const RoadEventStarted(this.event);
  final ActiveRoadEvent event;
}

enum RoadEventEndReason { wornOff, cleansed }

class RoadEventEnded extends RoadEventNews {
  const RoadEventEnded(this.event, this.reason);
  final ActiveRoadEvent event;
  final RoadEventEndReason reason;
}

/// Road events (GDD v0.5.2 §9.2–9.3). Owner: `idle_loop` (T-048).
abstract class IRoadEvents {
  List<ActiveRoadEvent> get active;
  Stream<RoadEventNews> get news;

  /// Watches a `road_event` ad to make a good event last longer. Returns
  /// false when no ad was watched (cap, Supporter Pack, skipped).
  Future<bool> boostWithAd(String uid);

  /// Watches a `road_event` ad to end a bad event now. A bad event always
  /// wears off by itself too.
  Future<bool> cleanseWithAd(String uid);
}
