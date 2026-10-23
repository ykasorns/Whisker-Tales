import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

class Time implements TimeSource {
  Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

Map<String, dynamic> balance() => jsonDecode(
        File('../../design/balance/idle_balance_v1.json').readAsStringSync())
    as Map<String, dynamic>;

void main() {
  final rules = AdRules.fromJson(balance());
  late Time time;
  late GameClock clock;
  late FakeAdNetwork net;
  var band = AgeBand.unset;
  var noAds = false;

  AdService service() => AdService(
      rules: rules,
      network: net,
      clock: clock,
      ageBand: () => band,
      hasNoAds: () => noAds);

  setUp(() {
    time = Time(DateTime.utc(2026, 10, 19, 3));
    clock = GameClock(time);
    net = FakeAdNetwork();
    band = AgeBand.unset;
    noAds = false;
  });

  Future<int> watchAll(AdService s, String id) async {
    var n = 0;
    while (await s.show(id) == AdOutcome.rewarded) {
      n++;
    }
    return n;
  }

  test('placements load from data (D-003, D-008)', () {
    expect(rules.dailyCapTotal, 10);
    expect(rules.placements['pet_hatch']!.perDay, 3);
    expect(rules.placements['road_event']!.perDay, 3);
    expect(rules.placements['offline_x2']!.enabled, isFalse);
    expect(rules.placements.values.every((p) => p.noAds == NoAdsBehavior.hide),
        isTrue);
  });

  test('a disabled or unknown placement never shows', () async {
    final s = service();
    expect(s.canShow('offline_x2'), isFalse);
    expect(s.canShow('banner'), isFalse);
    expect(await s.show('offline_x2'), AdOutcome.capped);
    expect(net.requests, isEmpty);
  });

  test('per-placement and total caps work together', () async {
    final s = service();
    expect(await watchAll(s, 'pet_hatch'), 3);
    expect(await watchAll(s, 'research_speedup'), 5);
    expect(s.remainingToday('yarn_bundle'), 2);
    expect(await watchAll(s, 'yarn_bundle'), 2); // total now 10
    expect(s.canShow('daily_gift'), isFalse);
    expect(s.canShow('road_event'), isFalse);
    expect(await s.show('road_event'), AdOutcome.capped);
    expect(net.requests, hasLength(10));
  });

  test('only a finished ad counts', () async {
    final s = service();
    net.next = AdNetworkResult.skipped;
    expect(await s.show('pet_hatch'), AdOutcome.skipped);
    net.next = AdNetworkResult.failed;
    expect(await s.show('pet_hatch'), AdOutcome.failed);
    expect(s.remainingToday('pet_hatch'), 3);
  });

  test('caps reset on a new local day, never by turning the clock back',
      () async {
    final s = service();
    await watchAll(s, 'pet_hatch');
    time.utc = DateTime.utc(2026, 10, 18, 3); // clock turned back a day
    clock.tick();
    expect(s.remainingToday('pet_hatch'), 0);
    time.utc = DateTime.utc(2026, 10, 19, 16, 59); // 23:59 local, same day
    clock.tick();
    expect(s.remainingToday('pet_hatch'), 0);
    time.utc = DateTime.utc(2026, 10, 19, 17, 1); // 00:01 local next day
    clock.tick();
    expect(s.remainingToday('pet_hatch'), 3);
  });

  test('under-13 and unset ask for child-directed, non-personalized ads',
      () async {
    final s = service();
    for (final b in AgeBand.values) {
      band = b;
      await s.show('research_speedup');
    }
    expect(net.requests.map((r) => r.childDirected), [true, true, false]);
    expect(net.requests.every((r) => r.nonPersonalized), isTrue);
  });

  test('Supporter Pack hides every placement and grants nothing', () async {
    noAds = true;
    final s = service();
    for (final id in rules.placements.keys) {
      expect(s.canShow(id), isFalse, reason: id);
      expect(await s.show(id), AdOutcome.capped);
    }
    expect(net.requests, isEmpty);
  });

  test('"grant" without a DECISIONS entry is refused', () {
    final b = balance();
    (b['ads']['placements'] as Map)['pet_hatch']['no_ads_behavior'] = 'grant';
    expect(() => AdRules.fromJson(b), throwsFormatException);
    (b['ads']['placements'] as Map)['pet_hatch']['grant_allowed'] = true;
    expect(AdRules.fromJson(b).placements['pet_hatch']!.noAds,
        NoAdsBehavior.grant);
  });

  test('one ad at a time', () async {
    final s = service();
    final first = s.show('pet_hatch');
    expect(await s.show('pet_hatch'), AdOutcome.failed);
    expect(await first, AdOutcome.rewarded);
  });

  test('coming back from an ad is not time away (welcome back)', () async {
    final s = service();
    expect(s.showingOrJustShown(), isFalse);
    final first = s.show('pet_hatch');
    expect(s.showingOrJustShown(), isTrue); // on screen
    await first;
    expect(s.showingOrJustShown(), isTrue); // just closed
    time.utc = time.utc.add(const Duration(seconds: 6));
    expect(s.showingOrJustShown(), isFalse);
  });

  test('daily counters save and load; an old day is dropped', () async {
    final s = service();
    await watchAll(s, 'pet_hatch');
    final json =
        jsonDecode(jsonEncode(s.snapshot().toJson())) as Map<String, dynamic>;
    expect(json, {
      'date_key': '2026-10-19',
      'ads_used': {'pet_hatch': 3},
      'ads_total': 3
    });
    final back = service()..restore(AdDailyState.fromJson(json));
    expect(back.remainingToday('pet_hatch'), 0);
    final stale = service()
      ..restore(const AdDailyState(
          dateKey: '2026-10-18', used: {'pet_hatch': 3}, total: 3));
    expect(stale.remainingToday('pet_hatch'), 3);
    expect(() => AdDailyState.fromJson({'date_key': 1}), throwsFormatException);
  });

  test('no other module touches the ad network or an ad SDK', () {
    final roots = ['lib', '../wt_mode_story/lib', '../../app/lib'];
    final offenders = <String>[];
    for (final root in roots) {
      final dir = Directory(root);
      if (!dir.existsSync()) continue;
      for (final f in dir.listSync(recursive: true).whereType<File>()) {
        if (!f.path.endsWith('.dart') ||
            f.path.contains('/src/ads/') ||
            f.path.contains('app/lib/ads/')) {
          continue; // the ads module: core + the app's SDK adapter (D-033)
        }
        if (f.path.endsWith('wt_core.dart') ||
            f.path.endsWith('providers.dart') ||
            f.path.endsWith('game_save.dart') ||
            f.path.endsWith('content_repository.dart')) {
          continue; // barrel export + the wiring layer (no network calls)
        }
        final src = f.readAsStringSync();
        if (src.contains('google_mobile_ads') ||
            src.contains('AdNetwork') ||
            src.contains("'../ads/") ||
            src.contains('src/ads/')) {
          offenders.add(f.path);
        }
      }
    }
    expect(offenders, isEmpty);
  });

  test('provider wiring: road events watch ads through the service', () async {
    final b = balance();
    final c = ProviderContainer(overrides: [
      timeSourceProvider.overrideWithValue(time),
      adRulesProvider.overrideWithValue(rules),
      adNetworkProvider.overrideWithValue(net),
    ]);
    addTearDown(c.dispose);
    final ads = c.read(adServiceProvider);
    expect(ads.remainingToday('road_event'), 3);
    expect(await ads.show('road_event'), AdOutcome.rewarded);
    expect(ads.remainingToday('road_event'), 2);
    expect(b['ads']['daily_cap_total'], 10);
  });
}
