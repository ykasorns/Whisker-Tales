// Whisker Tales — idle main mode pacing simulator (GDD v0.4 §15).
//
// Pacing model only: power is an aggregate number compared against the enemy
// curve; it does not run the combat engine. All tunables come from
// design/balance/idle_balance_v1.json.
//
// Usage: dart run bin/sim.dart [path/to/idle_balance_v1.json] [--seeds N] [--extra a,b]
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _minutesPerDay = 1440;
const _maxDays = 60;

void main(List<String> args) {
  var path = '../../design/balance/idle_balance_v1.json';
  var seeds = 20;
  var extra = <String>{};
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--seeds') {
      seeds = int.parse(args[++i]);
    } else if (args[i] == '--extra') {
      extra = args[++i].split(',').where((s) => s.isNotEmpty).toSet();
    } else {
      path = args[i];
    }
  }
  final cfg = jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>;
  final targets = cfg['pacing_targets'] as Map<String, dynamic>;

  final profiles = <String, Set<String>>{
    'no_ads': <String>{},
    'full_ads': {..._enabledPlacements(cfg), ...extra},
  };

  final results = <String, _Agg>{};
  for (final entry in profiles.entries) {
    final agg = _Agg();
    for (var s = 0; s < seeds; s++) {
      agg.add(_Sim(cfg, entry.value, Random(1000 + s)).run());
    }
    results[entry.key] = agg;
  }

  final pages = (targets['book1_pages'] as num).toInt();
  print('Whisker Tales idle pacing sim — seeds=$seeds, extra placements=${extra.isEmpty ? '-' : extra.join(',')}');
  print('');
  print('profile    | ads used/day | day p10 | day p20 | day p$pages | power@p$pages | basket lv | pets owned');
  for (final e in results.entries) {
    final a = e.value;
    print('${e.key.padRight(10)} | ${a.mean((r) => r.adsPerDay).toStringAsFixed(1).padLeft(12)} '
        '| ${_d(a.mean((r) => r.dayAt[10]))} | ${_d(a.mean((r) => r.dayAt[20]))} '
        '| ${_d(a.mean((r) => r.dayAt[pages]))} | ${a.mean((r) => r.powerAtEnd).toStringAsFixed(0).padLeft(10)} '
        '| ${a.mean((r) => r.basketLevel.toDouble()).toStringAsFixed(1).padLeft(9)} '
        '| ${a.mean((r) => r.petsOwned.toDouble()).toStringAsFixed(1).padLeft(10)}');
  }

  final full = results['full_ads']!.mean((r) => r.dayAt[pages]);
  final none = results['no_ads']!.mean((r) => r.dayAt[pages]);
  final targetDay = (targets['book1_target_day_full_ads'] as num).toDouble();
  final tol = (targets['book1_target_day_tolerance'] as num).toDouble();
  final maxSlow = (targets['max_no_ads_slowdown_pct'] as num).toDouble();
  final slowPct = (none / full - 1) * 100;
  final paceOk = (full - targetDay).abs() <= tol;
  final gapOk = slowPct <= maxSlow;
  print('');
  print('Target 1 — book 1 in ${targetDay.toStringAsFixed(0)}±${tol.toStringAsFixed(0)} days (full ads): '
      '${full.toStringAsFixed(1)} → ${paceOk ? 'PASS' : 'FAIL'}');
  print('Target 2 — no-ads slower by ≤ ${maxSlow.toStringAsFixed(0)}%: '
      '${slowPct.toStringAsFixed(1)}% → ${gapOk ? 'PASS' : 'FAIL'}');
  exitCode = (paceOk && gapOk) ? 0 : 1;
}

String _d(double v) => (v.isFinite ? v.toStringAsFixed(1) : '>$_maxDays').padLeft(7);

Set<String> _enabledPlacements(Map<String, dynamic> cfg) {
  final p = (cfg['ads'] as Map<String, dynamic>)['placements'] as Map<String, dynamic>;
  return {
    for (final e in p.entries)
      if ((e.value as Map<String, dynamic>)['enabled'] == true) e.key,
  };
}

class _Result {
  final Map<int, double> dayAt = {};
  double powerAtEnd = 0;
  int basketLevel = 1;
  int petsOwned = 0;
  double adsPerDay = 0;
}

class _Agg {
  final List<_Result> rs = [];
  void add(_Result r) => rs.add(r);
  double mean(double? Function(_Result) f) {
    final vs = rs.map(f).map((v) => v ?? double.infinity).toList();
    return vs.reduce((a, b) => a + b) / vs.length;
  }
}

class _Sim {
  _Sim(this.cfg, this.ads, this.rng) {
    enemy = cfg['enemy'] as Map<String, dynamic>;
    gear = cfg['gear'] as Map<String, dynamic>;
    basket = cfg['basket'] as Map<String, dynamic>;
    income = cfg['income'] as Map<String, dynamic>;
    pets = cfg['pets'] as Map<String, dynamic>;
    research = cfg['research'] as Map<String, dynamic>;
    adCfg = cfg['ads'] as Map<String, dynamic>;
    final slots = _i(gear, 'slots');
    slotItem = List.filled(slots, 0.0);
    slotLevel = List.filled(slots, 0);
    final roster = pets['roster'] as Map<String, dynamic>;
    for (final r in _rarities) {
      petStars[r] = List.filled(_i(roster, r), 0);
    }
  }

  final Map<String, dynamic> cfg;
  final Set<String> ads;
  final Random rng;
  late final Map<String, dynamic> enemy, gear, basket, income, pets, research, adCfg;

  static const _rarities = ['common', 'rare', 'legend'];

  // State.
  int cleared = 0;
  late List<double> slotItem;
  late List<int> slotLevel;
  int basketLevel = 1, basketExp = 0, gearPity = 0;
  double yarn = 0, fish = 0, eggFrac = 0;
  int eggs = 0, petPity = 0;
  final Map<String, List<int>> petStars = {};
  int statLv = 0, offlineLv = 0;
  String? task;
  double taskRemaining = 0;
  final Map<String, int> adsToday = {};
  int adsTotal = 0, fishPullsToday = 0, adsAll = 0;

  // ---- config helpers
  static int _i(Map<String, dynamic> m, String k) => (m[k] as num).toInt();
  static double _n(Map<String, dynamic> m, String k) => (m[k] as num).toDouble();
  static List<double> _l(Map<String, dynamic> m, String k) =>
      (m[k] as List).map((e) => (e as num).toDouble()).toList();
  Map<String, dynamic> _placement(String id) =>
      (adCfg['placements'] as Map<String, dynamic>)[id] as Map<String, dynamic>;

  // ---- curves
  double pagePower(int n) =>
      _n(enemy, 'page_power_base') * pow(_n(enemy, 'page_power_growth'), n - 1);
  double bossPower(int n) =>
      pagePower(n) *
      (n % _i(enemy, 'pages_per_chapter') == 0
          ? _n(enemy, 'chapter_boss_mult')
          : _n(enemy, 'page_boss_mult'));
  int get chapterIdx => min(cleared ~/ _i(enemy, 'pages_per_chapter'), 2);

  int get farmPage {
    final next = cleared + 1;
    return power >= pagePower(next) * _n(enemy, 'farm_min_power_ratio')
        ? next
        : max(1, cleared);
  }

  double get power {
    var gearSum = 0.0;
    for (var i = 0; i < slotItem.length; i++) {
      gearSum += slotItem[i] *
          (1 + slotLevel[i] * _n(gear, 'ASSUMPTION_slot_upgrade_pct_per_level'));
    }
    final skills = cfg['skills'] as Map<String, dynamic>;
    final skillPct = _n(skills, 'ASSUMPTION_pct_per_skill') *
        (skills['unlocked_by_chapter'] as List)[chapterIdx];
    final researchPct = statLv * _n(research, 'ASSUMPTION_stat_node_pct_per_level');
    return (_n(cfg['player'] as Map<String, dynamic>, 'base_power') + gearSum) *
        (1 + skillPct + researchPct + petPct);
  }

  double get petPct {
    final owned = _l(pets, 'ASSUMPTION_owned_pct');
    final deployed = _l(pets, 'ASSUMPTION_deployed_pct');
    final starBonus = _n(pets, 'ASSUMPTION_star_bonus_pct');
    var total = 0.0;
    final deploy = <double>[];
    for (var r = 0; r < _rarities.length; r++) {
      for (final s in petStars[_rarities[r]]!) {
        if (s == 0) continue;
        final m = 1 + starBonus * (s - 1);
        total += owned[r] * m;
        deploy.add(deployed[r] * m);
      }
    }
    deploy.sort((a, b) => b.compareTo(a));
    final slots = (pets['deploy_slots_by_chapter'] as List)[chapterIdx] as int;
    return total + deploy.take(slots).fold(0.0, (a, b) => a + b);
  }

  double fishPerWave(int page) =>
      _n(income, 'ASSUMPTION_fish_per_wave_base') *
      pow(_n(income, 'ASSUMPTION_fish_growth_per_page'), page - 1);
  double yarnPerWave(int page) =>
      _n(income, 'ASSUMPTION_yarn_per_wave') *
      (1 + _n(income, 'ASSUMPTION_yarn_growth_per_page_pct') / 100 * (page - 1));

  // ---- actions
  void farmWaves(double waves) {
    final p = farmPage;
    yarn += waves * yarnPerWave(p);
    fish += waves * fishPerWave(p);
    eggFrac += waves * _n(income, 'egg_drop_wave_chance');
    final whole = eggFrac.floor();
    eggs += whole;
    eggFrac -= whole;
  }

  bool adAvailable(String id) {
    if (!ads.contains(id)) return false;
    if (adsTotal >= _i(adCfg, 'daily_cap_total')) return false;
    return (adsToday[id] ?? 0) < _i(_placement(id), 'per_day');
  }

  void useAd(String id) {
    adsToday[id] = (adsToday[id] ?? 0) + 1;
    adsTotal++;
    adsAll++;
  }

  List<double> basketRow() {
    List<double> pct = [];
    for (final row in basket['rows'] as List) {
      final r = row as Map<String, dynamic>;
      if (_i(r, 'level') <= basketLevel) pct = _l(r, 'pct');
    }
    return pct;
  }

  int basketExpToNext() {
    var exp = 0;
    for (final row in basket['rows'] as List) {
      final r = row as Map<String, dynamic>;
      if (_i(r, 'level') <= basketLevel) exp = _i(r, 'exp_to_next');
    }
    return exp;
  }

  int rollGrade() {
    gearPity++;
    var grade = _weighted(basketRow());
    if (gearPity >= _i(gear, 'pity_every')) {
      grade = max(grade, _i(gear, 'pity_min_grade'));
    }
    if (grade >= _i(gear, 'pity_min_grade')) gearPity = 0;
    return grade;
  }

  int _weighted(List<double> pct) {
    var x = rng.nextDouble() * pct.reduce((a, b) => a + b);
    for (var i = 0; i < pct.length; i++) {
      x -= pct[i];
      if (x < 0) return i;
    }
    return pct.length - 1;
  }

  void craftAll() {
    final p = farmPage;
    final mults = _l(gear, 'grade_mult');
    while (yarn >= 1) {
      yarn -= 1;
      // Auto-craft targets the weakest slot.
      var slot = 0;
      for (var i = 1; i < slotItem.length; i++) {
        if (slotItem[i] < slotItem[slot]) slot = i;
      }
      final item = _n(gear, 'ASSUMPTION_item_power_base_per_slot') *
          pow(_n(gear, 'ASSUMPTION_item_power_growth_per_page'), p - 1) *
          mults[rollGrade()];
      if (item > slotItem[slot]) {
        slotItem[slot] = item;
      } else {
        fish += _n(gear, 'ASSUMPTION_recycle_fish_per_item') *
            pow(_n(income, 'ASSUMPTION_fish_growth_per_page'), p - 1);
      }
      basketExp += _i(gear, 'recycle_basket_exp');
      final need = basketExpToNext();
      if (basketLevel < _i(basket, 'max_level') && need > 0 && basketExp >= need) {
        basketExp -= need;
        basketLevel++;
      }
    }
  }

  void tryBosses() {
    while (cleared < 1000 && power >= bossPower(cleared + 1)) {
      cleared++;
      fish += _n(income, 'boss_fish_mult_waves') * fishPerWave(cleared);
      eggs += cleared % _i(enemy, 'pages_per_chapter') == 0
          ? _i(income, 'egg_chapter_boss')
          : _i(income, 'egg_page_boss');
    }
  }

  double researchCost(int lv) =>
      _n(research, 'cost_base') * pow(_n(research, 'cost_growth'), lv);
  double researchTime(int lv) => min(
      _n(research, 'time_base_min') * pow(_n(research, 'time_growth'), lv),
      _n(research, 'time_cap_min'));

  void startResearch() {
    if (task != null) return;
    final canOffline = offlineLv < _i(research, 'offline_node_max_level');
    final node = (canOffline && offlineLv <= statLv ~/ 2) ? 'offline' : 'stat';
    final lv = node == 'offline' ? offlineLv : statLv;
    final cost = researchCost(lv);
    if (fish < cost) return;
    fish -= cost;
    task = node;
    taskRemaining = researchTime(lv);
  }

  void tickResearch(double minutes) {
    if (task == null) return;
    taskRemaining -= minutes;
    if (taskRemaining <= 0) {
      task == 'offline' ? offlineLv++ : statLv++;
      task = null;
      taskRemaining = 0;
    }
  }

  void researchAds() {
    final pl = _placement('research_speedup');
    while (task != null && adAvailable('research_speedup')) {
      useAd('research_speedup');
      tickResearch(max(_n(pl, 'cut_min'), taskRemaining * _n(pl, 'cut_pct') / 100));
      startResearch();
    }
  }

  double pullCost() =>
      _n(pets, 'fish_pull_cost_base') *
      pow(_n(pets, 'fish_pull_cost_growth'), fishPullsToday) *
      (1 + _n(pets, 'fish_pull_chapter_scale_pct') / 100 * chapterIdx);

  void hatch() {
    petPity++;
    var r = _weighted(_l(pets, 'pull_pct'));
    if (petPity >= _i(pets, 'pity_legend_every')) r = 2;
    if (r == 2) petPity = 0;
    final list = petStars[_rarities[r]]!;
    final i = rng.nextInt(list.length);
    list[i] = min(list[i] + 1, _i(pets, 'max_stars'));
  }

  void spend() {
    startResearch();
    while (eggs > 0) {
      eggs--;
      hatch();
    }
    while (adAvailable('pet_hatch')) {
      useAd('pet_hatch');
      hatch();
    }
    // Keep enough for the next research level before optional spending.
    final reserve = task == null ? researchCost(min(statLv, offlineLv)) : 0.0;
    while (fishPullsToday < _i(pets, 'fish_pull_daily_max') &&
        fish - pullCost() >= reserve) {
      fish -= pullCost();
      fishPullsToday++;
      hatch();
    }
    while (true) {
      var slot = 0;
      for (var i = 1; i < slotLevel.length; i++) {
        if (slotLevel[i] < slotLevel[slot]) slot = i;
      }
      final cost = _n(gear, 'ASSUMPTION_slot_upgrade_cost_base') *
          pow(_n(gear, 'ASSUMPTION_slot_upgrade_cost_growth'), slotLevel[slot]);
      if (fish - cost < reserve) break;
      fish -= cost;
      slotLevel[slot]++;
    }
  }

  void extraAds() {
    final wpm = _n(cfg['player'] as Map<String, dynamic>, 'ASSUMPTION_waves_per_minute_online');
    if (adAvailable('yarn_bundle')) {
      useAd('yarn_bundle');
      yarn += yarnPerWave(farmPage) * wpm * _n(_placement('yarn_bundle'), 'yarn_minutes_of_income');
    }
    if (adAvailable('daily_gift')) {
      useAd('daily_gift');
      fish += fishPerWave(farmPage) * wpm * _n(_placement('daily_gift'), 'fish_minutes_of_income');
    }
  }

  _Result run() {
    final res = _Result();
    final player = cfg['player'] as Map<String, dynamic>;
    final profile = cfg['ASSUMPTION_player_profile'] as Map<String, dynamic>;
    final wpm = _n(player, 'ASSUMPTION_waves_per_minute_online');
    final sessions = _i(profile, 'sessions_per_day');
    final len = _i(profile, 'session_minutes');
    final awake = _i(profile, 'awake_hours') * 60;
    final starts = [
      for (var i = 0; i < sessions; i++)
        8 * 60 + (sessions == 1 ? 0 : i * (awake - len) ~/ (sessions - 1)),
    ];
    final pagesTarget = _i(cfg['pacing_targets'] as Map<String, dynamic>, 'book1_pages');
    var lastSeen = 0;
    var day = 0;
    for (var t = 0; t < _maxDays * _minutesPerDay; t++) {
      if (t ~/ _minutesPerDay != day) {
        day = t ~/ _minutesPerDay;
        adsToday.clear();
        adsTotal = 0;
        fishPullsToday = 0;
      }
      final m = t % _minutesPerDay;
      final online = starts.any((s) => m >= s && m < s + len);
      final sessionStart = starts.contains(m);
      if (sessionStart) {
        final cap = _n(cfg['offline'] as Map<String, dynamic>, 'base_cap_min') +
            offlineLv * _n(research, 'offline_node_min_per_level');
        var waves = min((t - lastSeen).toDouble(), cap) * wpm * _n(player, 'offline_rate_vs_online');
        if (adAvailable('offline_x2')) {
          useAd('offline_x2');
          waves *= 2;
        }
        farmWaves(waves);
        extraAds();
      }
      tickResearch(1);
      if (online) {
        farmWaves(wpm);
        craftAll();
        tryBosses();
        spend();
        researchAds();
        lastSeen = t + 1;
        for (final p in [10, 20, pagesTarget]) {
          if (cleared >= p && !res.dayAt.containsKey(p)) {
            res.dayAt[p] = t / _minutesPerDay;
          }
        }
        if (cleared >= pagesTarget && res.powerAtEnd == 0) {
          res.powerAtEnd = power;
          res.basketLevel = basketLevel;
          res.petsOwned = petStars.values.expand((l) => l).where((s) => s > 0).length;
          res.adsPerDay = adsAll / (day + 1);
          return res;
        }
      }
    }
    res.powerAtEnd = power;
    res.basketLevel = basketLevel;
    res.petsOwned = petStars.values.expand((l) => l).where((s) => s > 0).length;
    res.adsPerDay = adsAll / _maxDays;
    return res;
  }
}
