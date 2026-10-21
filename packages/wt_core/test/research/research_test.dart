import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

class Time implements TimeSource {
  Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

class FakeAds implements IAdService {
  bool allowed = true;
  AdOutcome outcome = AdOutcome.rewarded;
  final shown = <String>[];
  @override
  bool canShow(String placementId) => allowed;
  @override
  Future<AdOutcome> show(String placementId) async {
    shown.add(placementId);
    return outcome;
  }

  @override
  int remainingToday(String placementId) => allowed ? 1 : 0;
}

void main() {
  final balance = _j('../../design/balance/idle_balance_v1.json');
  final data = _j('../../design/data/research.json');
  final adParams =
      AdRules.fromJson(balance).placements['research_speedup']!.params;
  final rules = ResearchRules.fromJson(balance, data, adParams);
  final t0 = DateTime.utc(2026, 10, 21, 3);

  late Time time;
  late GameClock clock;
  late MemoryWallet wallet;
  late FakeAds ads;
  late Research research;

  setUp(() {
    time = Time(t0);
    clock = GameClock(time);
    wallet = MemoryWallet({Currency.goldfish: 1000000});
    ads = FakeAds();
    research =
        Research(rules: rules, wallet: wallet, ads: () => ads, clock: clock);
  });

  ResearchNode node(String id) => rules.byId(id)!;

  test('time and cost follow the JSON formula (GDD §15.6)', () {
    final claws = node('sharp_claws');
    expect(rules.timeFor(claws, 1), const Duration(seconds: 60));
    expect(rules.timeFor(claws, 2), const Duration(seconds: 96));
    expect(rules.timeFor(claws, 3), const Duration(seconds: 154));
    // 1.6^12 × 60 s ≈ 4.4 h → capped at 4 h from Lv13
    expect(rules.timeFor(claws, 12).inMinutes, lessThan(240));
    expect(rules.timeFor(claws, 13), const Duration(minutes: 240));
    expect(rules.timeFor(claws, 20), const Duration(minutes: 240));
    expect(rules.costFor(claws, 1), 100);
    expect(rules.costFor(claws, 2), 145);
    expect(rules.costFor(claws, 3), 210);
    final desk = node('queue_2');
    expect(rules.costFor(desk, 1), 500);
    expect(rules.timeFor(desk, 1), const Duration(minutes: 10));
  });

  test('start spends goldfish; the level lands when the timer ends', () async {
    final done = <ResearchCompleted>[];
    research.completed.listen(done.add);
    expect(research.start('sharp_claws'), isTrue);
    expect(wallet.balance(Currency.goldfish), 1000000 - 100);
    time.utc = t0.add(const Duration(seconds: 59));
    research.tick();
    expect(research.levelOf('sharp_claws'), 0);
    time.utc = t0.add(const Duration(seconds: 60));
    research.tick();
    expect(research.levelOf('sharp_claws'), 1);
    expect(done.single.nodeId, 'sharp_claws');
    expect(done.single.level, 1);
    expect(research.tasks, isEmpty);
  });

  test('one queue until the second desk; prerequisites gate nodes', () {
    expect(research.blockOf('fluffy_fur'), ResearchBlock.locked);
    expect(research.start('fluffy_fur'), isFalse);
    expect(research.start('sharp_claws'), isTrue);
    expect(research.blockOf('sharp_claws'), ResearchBlock.running);
    expect(research.blockOf('offline_cap'), ResearchBlock.queueFull);
    expect(research.start('offline_cap'), isFalse);

    research.restore(const ResearchState(
        levels: {'sharp_claws': 5, 'offline_cap': 3, 'queue_2': 1}));
    expect(research.queueSlots, 2);
    expect(research.start('sharp_claws'), isTrue);
    expect(research.start('offline_cap'), isTrue);
    expect(research.blockOf('fluffy_fur'), ResearchBlock.queueFull);
    expect(research.blockOf('queue_2'), ResearchBlock.maxed);
  });

  test('not enough goldfish = no start, nothing spent', () {
    wallet.setBalances({Currency.goldfish: 99});
    expect(research.blockOf('sharp_claws'), ResearchBlock.fish);
    expect(research.start('sharp_claws'), isFalse);
    expect(wallet.balance(Currency.goldfish), 99);
  });

  test('turning the clock back never rewinds a task; forward finishes it', () {
    research.start('sharp_claws');
    time.utc = t0.add(const Duration(seconds: 30));
    final left = research.remaining(research.tasks.single);
    time.utc = t0.subtract(const Duration(hours: 5));
    research.tick();
    expect(research.remaining(research.tasks.single), left);
    time.utc = t0.add(const Duration(days: 1));
    research.tick();
    expect(research.levelOf('sharp_claws'), 1);
  });

  test('ad cut = max(30 min, 25% of what is left), soonest task first',
      () async {
    research.restore(const ResearchState(
        levels: {'sharp_claws': 14, 'offline_cap': 3, 'queue_2': 1}));
    research.start('sharp_claws'); // 4 h
    research.start('offline_cap'); // 1 × 1.6^3 min ≈ 6.6 min
    expect(await research.speedUpWithAd(), isTrue);
    expect(ads.shown, ['research_speedup']);
    // the short one ends first: a 30-min cut finishes it
    expect(research.levelOf('offline_cap'), 4);
    final long = research.tasks.single;
    expect(research.remaining(long), const Duration(hours: 4));
    expect(await research.speedUpWithAd(), isTrue);
    expect(research.remaining(research.tasks.single), const Duration(hours: 3));
    // with 40 min left the flat 30 min beats 25%
    time.utc = t0.add(const Duration(hours: 2, minutes: 20));
    expect(
        research.remaining(research.tasks.single), const Duration(minutes: 40));
    await research.speedUpWithAd();
    expect(
        research.remaining(research.tasks.single), const Duration(minutes: 10));
  });

  test('a skipped or capped ad cuts nothing', () async {
    research.start('sharp_claws');
    ads.outcome = AdOutcome.skipped;
    expect(await research.speedUpWithAd(), isFalse);
    expect(
        research.remaining(research.tasks.single), const Duration(seconds: 60));
    ads.allowed = false;
    expect(research.canSpeedUp, isFalse);
    expect(await research.speedUpWithAd(), isFalse);
    expect(ads.shown, ['research_speedup']);
  });

  test('stat nodes add % of the main stats', () {
    research.restore(const ResearchState(
        levels: {'sharp_claws': 2, 'fluffy_fur': 1, 'tough_paws': 3}));
    final cat = CombatUnitSpec(
        id: 'cat',
        side: CombatSide.cat,
        attackIntervalMs: 1000,
        stats: StatBlock(hp: 1000, atk: 100, def: 50));
    final s = research.withBonus(cat).stats;
    expect(s.atk, 106);
    expect(s.hp, 1030);
    expect(s.def, 54);
  });

  test('the pillow node raises the offline cap (8 h + 10 min/level)', () {
    research.restore(const ResearchState(levels: {'offline_cap': 3}));
    expect(research.offlineCapLevel, 3);
    final offline = OfflineRules.fromBalance(balance);
    expect(offline.capFor(research.offlineCapLevel),
        const Duration(hours: 8, minutes: 30));
  });

  test('save round-trip; bad tasks are dropped on load', () {
    research.start('sharp_claws');
    final json = jsonDecode(jsonEncode(research.snapshot().toJson()))
        as Map<String, dynamic>;
    expect(json['task']['node'], 'sharp_claws');
    expect(json.containsKey('task_2'), isFalse);
    final other =
        Research(rules: rules, wallet: wallet, ads: () => ads, clock: clock)
          ..restore(ResearchState.fromJson(json));
    expect(other.tasks.single.endsAtUtc, research.tasks.single.endsAtUtc);

    other.restore(ResearchState.fromJson({
      'levels': {'ghost_node': 3, 'queue_2': 9},
      'task': {'node': 'ghost_node', 'ends_at_utc': t0.toIso8601String()},
      'task_2': {'node': 'queue_2', 'ends_at_utc': t0.toIso8601String()},
    }));
    expect(other.levels, {'queue_2': 1});
    expect(other.tasks, isEmpty);
  });

  test('a task due while away finishes on the first tick after load', () {
    research.start('sharp_claws');
    final saved = research.snapshot();
    time.utc = t0.add(const Duration(hours: 3));
    final reopened =
        Research(rules: rules, wallet: wallet, ads: () => ads, clock: clock)
          ..restore(saved);
    expect(reopened.tasks, hasLength(1));
    reopened.tick();
    expect(reopened.levelOf('sharp_claws'), 1);
  });

  test('no real-money path: research only touches goldfish and ads', () {
    final src = File('lib/src/research/research.dart').readAsStringSync();
    for (final bad in ['iap', 'purchase', 'billing', 'gems', 'Currency.gem']) {
      expect(src.toLowerCase().contains(bad.toLowerCase()), isFalse,
          reason: bad);
    }
    expect(
        RegExp(r'Currency\.(\w+)')
            .allMatches(src)
            .map((m) => m.group(1))
            .toSet(),
        {'goldfish'});
  });

  test('bad data names the node', () {
    Map<String, dynamic> withNode(Map<String, dynamic> n) => {
          'nodes': [n]
        };
    expect(
        () => ResearchRules.fromJson(
            balance,
            withNode(
                {'id': 'x', 'effect': 'stat', 'attr': 'luck', 'max_level': 1}),
            adParams),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('node x'))));
    expect(
        () => ResearchRules.fromJson(
            balance,
            withNode({
              'id': 'y',
              'effect': 'queue',
              'max_level': 1,
              'requires': [
                ['nope', 1]
              ]
            }),
            adParams),
        throwsA(isA<FormatException>()));
    expect(() => ResearchRules.fromJson(balance, data, const {}),
        throwsA(isA<FormatException>()));
  });
}
