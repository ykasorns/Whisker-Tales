@Timeout.none
library;

// Balance on the real engine (T-029, D-027): a scripted player plays the
// actual wt_core game — combat engine, skills, gear, pets, research, road
// events, offline rewards, ads — the way the app's GameDriver drives it,
// over simulated days. Not part of `flutter test` (lives in tool/):
//
//   cd packages/wt_core && flutter test tool/headless_player_test.dart
//
// Options via --dart-define: SEEDS=3, CLASSES=warrior,rogue,archer,mage,
// DAYS=30. Prints a report; exits non-zero when a pacing target fails.

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// Repo data; `--dart-define=BALANCE=<file>` swaps the balance file to try
/// numbers without touching the repo.
class _Disk implements ContentSource {
  static const balance = String.fromEnvironment('BALANCE');
  @override
  Future<String> read(String path) async =>
      File(balance.isNotEmpty && path == ContentRepository.balancePath
              ? balance
              : '../../$path')
          .readAsStringSync();
}

class _Time implements TimeSource {
  _Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

/// The player (fixed, written in D-027):
/// - 3 sessions a day, 15 min each, at 08:00 / 13:00 / 20:00 local; the
///   rest is offline (claimed at each session start, like the app).
/// - AUTO boss on; auto-knit on, "wear if better".
/// - Class at Lv10 = [cls]; skills cast themselves.
/// - Every egg hatched; pets deployed best first (rarity, then stars).
/// - Goldfish, in this order: research (cheapest open node, a free desk),
///   then the lowest open gear slot level, then a goldfish hatch.
/// - Ads (full profile), first come first served under the caps: cleanse a
///   bad road event, hatch, research time cut (longest desk), yarn bundle,
///   daily gift, boost a good road event.
class _Player {
  _Player(this.c, this.cls, {required this.ads});
  final ProviderContainer c;
  final String cls;
  final bool ads;

  T read<T>(ProviderListenable<T> p) => c.read(p);

  Future<void> act() async {
    final cat = read(catClassProvider);
    if (cat.current == 'novice' &&
        !read(idleLoopProvider).isBossFight &&
        cat.available.any((x) => x.id == cls)) {
      cat.choose(cls);
    }
    final pets = read(petsProvider)!;
    final wallet = read(walletProvider);
    while (wallet.balance(Currency.eggs) > 0) {
      await pets.hatch(HatchSource.egg);
    }
    if (ads) await _ads(pets);
    _spendFish(pets);
    await _fishHatch(pets);
    _deployBest(pets);
  }

  Future<void> _ads(Pets pets) async {
    final adSvc = read(adServiceProvider);
    final road = read(roadEventsProvider);
    for (final e in road.active) {
      if (e.kind == RoadEventKind.bad) await road.cleanseWithAd(e.uid);
    }
    while (adSvc.canShow(petHatchPlacement)) {
      if (await pets.hatch(HatchSource.ad) == null) break;
    }
    final research = read(researchProvider)!;
    while (research.tasks.isNotEmpty && research.canSpeedUp) {
      if (!await research.speedUpWithAd()) break;
    }
    for (final g in AdGifts.gifts.keys) {
      while (adSvc.canShow(g)) {
        if (await read(adGiftsProvider).watch(g) == null) break;
      }
    }
    for (final e in road.active) {
      if (e.kind == RoadEventKind.good) await road.boostWithAd(e.uid);
    }
  }

  void _spendFish(Pets pets) {
    final research = read(researchProvider)!;
    final basket = read(gearBasketProvider);
    final wallet = read(walletProvider);
    for (var guard = 0; guard < 200; guard++) {
      research.tick();
      final open = research.rules.nodes
          .where((n) => research.blockOf(n.id) == null)
          .toList()
        ..sort((a, b) => research.costOf(a).compareTo(research.costOf(b)));
      if (open.isNotEmpty && research.start(open.first.id)) continue;
      final slots = basket.openSlots
        ..sort((a, b) => basket.slotLevel(a).compareTo(basket.slotLevel(b)));
      if (slots.isEmpty) return;
      final s = slots.first;
      if (wallet.balance(Currency.goldfish) < basket.upgradeCost(s)) return;
      basket.upgradeSlot(s);
    }
  }

  Future<void> _fishHatch(Pets pets) async {
    while (pets.canHatch(HatchSource.fish)) {
      if (await pets.hatch(HatchSource.fish) == null) break;
    }
  }

  void _deployBest(Pets pets) {
    final ranked = pets.owned.keys.toList()
      ..sort((a, b) {
        final ra = pets.rules.byId(a)!.rarity.index;
        final rb = pets.rules.byId(b)!.rarity.index;
        return rb != ra ? rb - ra : pets.owned[b]! - pets.owned[a]!;
      });
    for (final id in [...pets.deployed]) {
      pets.undeploy(id);
    }
    for (var i = 0; i < pets.deploySlots && i < ranked.length; i++) {
      pets.deploy(i, ranked[i]);
    }
  }
}

class _Run {
  final dayAt = <int, double>{};
  final pageMinutes = <int, double>{}; // online + offline minutes per page
  int level = 1;
  int power = 0;
  double fishOnline = 0, fishOffline = 0;
  final adsUsed = <String, int>{};
  int days = 0;

  /// Boss fights lost by time running out vs by the cat fainting.
  int bossTimeouts = 0, bossFaints = 0;

  /// Waves cleared while playing, and the minutes played (to compare with
  /// the offline rate `player.waves_per_minute_online`).
  int wavesOnline = 0;
  double minutesOnline = 0;

  int get worstPage => pageMinutes.entries
      .fold(const MapEntry(0, -1.0), (a, e) => e.value > a.value ? e : a)
      .key;
}

Future<_Run> _play(GameContent content, String cls, int seed,
    {required bool ads, required int maxDays}) async {
  final start = DateTime.utc(2026, 11, 1, 1); // 08:00 local
  final time = _Time(start);
  final c = ProviderContainer(overrides: [
    ...content.overrides,
    timeSourceProvider.overrideWithValue(time),
    idleSeedProvider.overrideWithValue(seed),
    saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
  ]);
  c.read(ageGateProvider).setBand(AgeBand.under13);
  c.read(gameSaverProvider).newWorld(seed * 7919 + 1);
  final run = _Run();
  final loop = c.read(idleLoopProvider);
  final auto = c.read(autoCraftProvider)
    ..configure(const AutoCraftRule(on: true, mode: AutoCraftMode.equip))
    ..start();
  loop.autoBoss = true;
  final player = _Player(c, cls, ads: ads);
  final rules = c.read(idleRulesProvider);
  var pageSince = start;
  // why bosses are lost: the fight's own end event
  var catAlive = true;
  loop.combatEvents.listen((e) {
    if (e is UnitDefeated && e.unitId == 'mochi') catAlive = false;
    if (e is CombatEnded && !e.playerWon && loop.isBossFight) {
      catAlive ? run.bossTimeouts++ : run.bossFaints++;
    }
    if (e is CombatEnded) catAlive = true;
  });
  loop.events.listen((e) {
    switch (e) {
      case WaveCleared(:final reward):
        run.fishOnline += reward[Currency.goldfish];
        run.wavesOnline++;
      case BossResult(:final reward, :final won, :final page):
        run.fishOnline += reward[Currency.goldfish];

        if (won) {
          run.pageMinutes[page] = time.utc.difference(pageSince).inSeconds / 60;
          pageSince = time.utc;
          run.dayAt[page] =
              time.utc.difference(start).inMinutes / Duration.minutesPerDay;
        }
      case WaveFailed():
    }
  });

  const sessions = [
    Duration(hours: 1),
    Duration(hours: 6),
    Duration(hours: 13)
  ];
  const sessionMs = 15 * 60 * 1000, stepMs = 2000;
  const target = 30;
  for (var day = 0; day < maxDays && loop.state.clearedPage < target; day++) {
    for (final at in sessions) {
      final open =
          DateTime.utc(start.year, start.month, start.day + day).add(at);
      if (open.isAfter(time.utc)) time.utc = open; // offline until now
      c.read(gameClockProvider).tick();
      final off = c.read(offlineRewardProvider)..checkIn();
      run.fishOffline += off.claim()[Currency.goldfish];
      await player.act();
      for (var ms = 0; ms < sessionMs; ms += stepMs) {
        time.utc = time.utc.add(const Duration(milliseconds: stepMs));
        final speed = rules.speedsFor(loop.state.clearedPage).reduce(math.max);
        final dt = (stepMs * speed).round();
        loop.tick(dt);
        auto.tick(dt);
        c.read(researchProvider)!.tick();
        c.read(gameClockProvider).tick();
        if (ms % 30000 == 0) await player.act();
        if (!auto.running &&
            c.read(walletProvider).balance(Currency.yarn) > 0) {
          auto.start();
        }
      }
      run.minutesOnline += sessionMs / 60000;
      c.read(gameSaverProvider).capture(); // leaving: marks the player seen
    }
    run.days = day + 1;
  }
  run.level = c.read(catProgressProvider).level;
  run.power = c.read(powerScoreProvider).of(c.read(catSpecProvider)().stats);
  final daily = c.read(gameSaverProvider).capture(asSeen: false)['daily'];
  run.adsUsed.addAll({...?(daily['ads_used'] as Map?)?.cast<String, int>()});
  c.dispose();
  return run;
}

String _f(double? v) => v == null ? '  —  ' : v.toStringAsFixed(1).padLeft(5);

double? _median(List<double?> xs) {
  final v = xs.whereType<double>().toList()..sort();
  if (v.length < xs.length) return null; // some runs never got there
  return v.isEmpty ? null : v[v.length ~/ 2];
}

void main() {
  test('headless player — book 1 pacing on the real engine', () async {
    final content = await ContentRepository(_Disk()).loadAll();
    final balance =
        jsonDecode(await _Disk().read(ContentRepository.balancePath));
    final t = balance['pacing_targets'] as Map<String, dynamic>;
    const seeds = int.fromEnvironment('SEEDS', defaultValue: 3);
    const maxDays = int.fromEnvironment('DAYS', defaultValue: 30);
    const clsArg = String.fromEnvironment('CLASSES',
        defaultValue: 'warrior,rogue,archer,mage');
    final classes = clsArg.split(',');

    final out = StringBuffer()
      ..writeln('Headless player on the real engine — seeds=$seeds, '
          'sessions 3×15 min/day')
      ..writeln()
      ..writeln('profile  class    | day p10 | day p20 | day p30 | '
          'Lv  | power   | offline fish % | longest page (h)');
    final book = <bool, List<double?>>{true: [], false: []};
    for (final ads in [true, false]) {
      for (final cls in classes) {
        final runs = [
          for (var s = 0; s < seeds; s++)
            await _play(content, cls, 101 + s, ads: ads, maxDays: maxDays),
        ];
        double? med(double? Function(_Run) f) => _median(runs.map(f).toList());
        book[ads]!.addAll(runs.map((r) => r.dayAt[30]));
        final longest = runs
            .map((r) => r.pageMinutes.values.fold(0.0, math.max) / 60)
            .reduce(math.max);
        final offPct = runs
                .map((r) => r.fishOffline / (r.fishOffline + r.fishOnline))
                .reduce((a, b) => a + b) /
            runs.length *
            100;
        out.writeln('${(ads ? 'full_ads' : 'no_ads').padRight(8)} '
            '${cls.padRight(8)} | ${_f(med((r) => r.dayAt[10]))}   | '
            '${_f(med((r) => r.dayAt[20]))}   | ${_f(med((r) => r.dayAt[30]))}   | '
            '${(runs.map((r) => r.level).reduce((a, b) => a + b) ~/ runs.length).toString().padLeft(3)} | '
            '${(runs.map((r) => r.power).reduce((a, b) => a + b) ~/ runs.length).toString().padLeft(7)} | '
            '${offPct.toStringAsFixed(0).padLeft(14)} | ${longest.toStringAsFixed(1).padLeft(6)}');
        out.writeln(
            '         worst page: ${runs.map((r) => r.worstPage).join('/')}'
            ' · online waves/min ${(runs.map((r) => r.wavesOnline / r.minutesOnline).reduce((a, b) => a + b) / runs.length).toStringAsFixed(1)}'
            ' · boss losses timeout/faint: '
            '${runs.map((r) => '${r.bossTimeouts}/${r.bossFaints}').join(' ')}'
            '${ads ? ' · ads last day: ${runs.first.adsUsed}' : ''}');
      }
    }
    final full = _median(book[true]!), none = _median(book[false]!);
    final target = (t['book1_target_day_full_ads'] as num).toDouble();
    final tol = (t['book1_target_day_tolerance'] as num).toDouble();
    final maxSlow = (t['max_no_ads_slowdown_pct'] as num).toDouble();
    final paceOk = full != null && (full - target).abs() <= tol;
    final slow = full == null || none == null
        ? double.infinity
        : (none / full - 1) * 100;
    out
      ..writeln()
      ..writeln('Target 1 — book 1 in ${target.toStringAsFixed(0)}±'
          '${tol.toStringAsFixed(0)} days (full ads, median): '
          '${_f(full)} → ${paceOk ? 'PASS' : 'FAIL'}')
      ..writeln('Target 2 — no-ads slower by ≤ ${maxSlow.toStringAsFixed(0)}%: '
          '${slow.toStringAsFixed(1)}% → ${slow <= maxSlow ? 'PASS' : 'FAIL'}');
    // ignore: avoid_print
    print(out);
    if (_Disk.balance.isEmpty) {
      File('../../tools/balance_sim/headless_report.txt')
          .writeAsStringSync(out.toString());
    }
  });
}
