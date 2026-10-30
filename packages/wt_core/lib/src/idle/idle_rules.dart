import 'dart:math' as math;

import '../core/contracts/rewards.dart';

/// `enemy`, `pages`, `income` and `player` from `idle_balance_v1.json`
/// (GDD v0.4 §15, v0.5.2 §9), read once. Keys may carry `ASSUMPTION_`.
class IdleRules {
  IdleRules._(Map<String, dynamic> b)
      : _enemy = _map(b, 'enemy'),
        _pages = _map(b, 'pages'),
        _income = _map(b, 'income'),
        _player = _map(b, 'player') {
    final steps = (_map(b, 'speed')['steps'] as List?) ?? const [];
    speedSteps = List.unmodifiable([
      for (final s in steps.cast<Map<String, dynamic>>())
        ((s['mult'] as num).toDouble(), s['unlock_cleared_page'] as int),
    ]);
    if (speedSteps.isEmpty) {
      throw const FormatException('balance: "speed.steps" must list speeds');
    }
    pagesPerChapter = _int(_enemy, 'pages_per_chapter');
    chaptersPerBook = _int(_pages, 'chapters_per_book');
    wavesByChapter = _ranges(_pages, 'waves_by_chapter');
    monstersByChapter = _ranges(_pages, 'monsters_per_wave_by_chapter');
    if (wavesByChapter.length != chaptersPerBook ||
        monstersByChapter.length != chaptersPerBook) {
      throw const FormatException(
          'pages: one [min, max] per chapter of a book is required');
    }
    longPages = List.unmodifiable(
        (_pages['long_pages_in_chapter'] as List? ?? const []).cast<int>());
    longExtraWaves = _int(_pages, 'long_page_extra_waves');
    walkMs = _int(_pages, 'walk_ms');
    faintRestMs = _int(_pages, 'faint_rest_ms');
    retreatAfterLosses = _int(_pages, 'retreat_after_losses');
    autoBossRetryWaves = _int(_pages, 'auto_boss_retry_waves');
    bossTimeLimitMs = _int(_pages, 'boss_time_limit_ms');
    hpSharePct = _int(_enemy, 'hp_share_pct');
    monsterIntervalMs = _int(_enemy, 'monster_attack_interval_ms');
    bossIntervalMs = _int(_enemy, 'boss_attack_interval_ms');
    farmMinPowerRatio = _num(_enemy, 'farm_min_power_ratio');
    wavesPerMinute = _num(_player, 'waves_per_minute_online').toDouble();
    bossExpKills = _int(_income, 'boss_exp_kills');
    bossFishWaves = _int(_income, 'boss_fish_mult_waves');
    eggPageBoss = _int(_income, 'egg_page_boss');
    eggChapterBoss = _int(_income, 'egg_chapter_boss');
  }

  factory IdleRules.fromBalance(Map<String, dynamic> balance) =>
      IdleRules._(balance);

  final Map<String, dynamic> _enemy, _pages, _income, _player;

  /// Speed button steps (GDD v0.5 §1): (multiplier, pages cleared to unlock).
  late final List<(double, int)> speedSteps;

  /// Speeds open after [clearedPage] pages.
  List<double> speedsFor(int clearedPage) => [
        for (final (m, at) in speedSteps)
          if (clearedPage >= at) m
      ];

  late final int pagesPerChapter;
  late final int chaptersPerBook;
  late final List<(int, int)> wavesByChapter;
  late final List<(int, int)> monstersByChapter;
  late final List<int> longPages;
  late final int longExtraWaves;
  late final int walkMs;
  late final int faintRestMs;
  late final int retreatAfterLosses;
  late final int autoBossRetryWaves;
  late final int bossTimeLimitMs;
  late final int hpSharePct;
  late final int monsterIntervalMs;
  late final int bossIntervalMs;
  late final num farmMinPowerRatio;
  late final double wavesPerMinute;
  late final int bossExpKills;
  late final int bossFishWaves;
  late final int eggPageBoss;
  late final int eggChapterBoss;

  int get pagesPerBook => pagesPerChapter * chaptersPerBook;

  int bookOf(int page) => (page - 1) ~/ pagesPerBook + 1;

  /// 1-based chapter inside its book.
  int chapterOf(int page) => ((page - 1) % pagesPerBook) ~/ pagesPerChapter + 1;

  /// 1-based page inside its chapter.
  int pageInChapter(int page) => (page - 1) % pagesPerChapter + 1;

  bool isChapterBoss(int page) => pageInChapter(page) == pagesPerChapter;

  /// Book 1 ramps quickly; later books track gear's per-page growth.
  /// The two segments meet at the last page of book 1 without a reset.
  int wavePower(int page) {
    if (page < 1) throw ArgumentError.value(page, 'page', 'must be >= 1');
    final firstBookPages = pagesPerBook;
    final firstBookSteps = math.min(page - 1, firstBookPages - 1);
    final laterSteps = math.max(0, page - firstBookPages);
    return (_num(_enemy, 'page_power_base') *
            math.pow(_num(_enemy, 'page_power_growth'), firstBookSteps) *
            math.pow(_num(_enemy, 'page_power_growth_after_book1'), laterSteps))
        .round();
  }

  /// Boss power: page boss or chapter boss multiplier × P(n), minus the
  /// early-page discount (D-011).
  int bossPower(int page) => (wavePower(page) *
          _num(_enemy,
              isChapterBoss(page) ? 'chapter_boss_mult' : 'page_boss_mult') *
          (100 - earlyBossDiscountPct(page)) /
          100)
      .round();

  /// % taken off bosses during onboarding. The full discount is held through
  /// the first book, then fades to zero so later repeated content keeps
  /// scaling without a sudden wall (D-050).
  num earlyBossDiscountPct(int page) {
    final hold = _int(_enemy, 'early_boss_hold_until_page');
    final until = _int(_enemy, 'early_boss_until_page');
    final discount = _num(_enemy, 'early_boss_discount_pct');
    if (hold < 0 || until <= hold) {
      throw const FormatException(
          'balance: early boss pages must satisfy 0 <= hold < until');
    }
    if (page <= hold) return discount;
    if (page > until) return 0;
    return discount * (until - page + 1) / (until - hold);
  }

  /// Yarn a new player starts with (D-011).
  int get starterYarn => _int(_income, 'starter_yarn');

  /// Extra yarn per wave on the first pages, fading linearly to 0 (D-011).
  num _earlyYarn(int page) {
    final until = _int(_income, 'early_yarn_until_page');
    if (page > until) return 0;
    return _num(_income, 'early_yarn_bonus_per_wave') *
        (until - page + 1) /
        until;
  }

  /// One wave's income in thousandths (rounded once per page).
  Map<Currency, int> perWaveMilli(int page) => {
        Currency.goldfish: (_num(_income, 'fish_per_wave_base') *
                math.pow(_num(_income, 'fish_growth_per_page'), page - 1) *
                1000)
            .round(),
        Currency.yarn: ((_num(_income, 'yarn_per_wave') *
                        (1 +
                            _num(_income, 'yarn_growth_per_page_pct') /
                                100 *
                                (page - 1)) +
                    _earlyYarn(page)) *
                1000)
            .round(),
        Currency.eggs: (_num(_income, 'egg_drop_wave_chance') * 1000).round(),
      };
}

num _num(Map<String, dynamic> m, String key) {
  final v = m[key] ?? m['ASSUMPTION_$key'];
  if (v is! num) throw FormatException('balance: "$key" must be a number');
  return v;
}

int _int(Map<String, dynamic> m, String key) {
  final v = m[key] ?? m['ASSUMPTION_$key'];
  if (v is! int) throw FormatException('balance: "$key" must be an integer');
  return v;
}

Map<String, dynamic> _map(Map<String, dynamic> m, String key) {
  final v = m[key];
  if (v is! Map<String, dynamic>) {
    throw FormatException('balance: "$key" must be an object');
  }
  return v;
}

List<(int, int)> _ranges(Map<String, dynamic> m, String key) {
  final v = m[key] ?? m['ASSUMPTION_$key'];
  if (v is! List) throw FormatException('pages: "$key" must be a list');
  return List.unmodifiable([
    for (final r in v)
      if (r is List &&
          r.length == 2 &&
          r[0] is int &&
          r[1] is int &&
          (r[0] as int) >= 1 &&
          (r[0] as int) <= (r[1] as int))
        (r[0] as int, r[1] as int)
      else
        throw FormatException('pages: "$key" entries must be [min, max]'),
  ]);
}
