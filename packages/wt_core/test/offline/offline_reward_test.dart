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
  final b = balance();
  final rules = OfflineRules.fromBalance(b);
  final idle = IdleRules.fromBalance(b);
  final cat = CatRules.fromBalance(b);
  final income = IncomeModel(idle, expPerKill: cat.expPerKill);
  final t0 = DateTime.utc(2026, 10, 19, 2);

  late Time time;
  late GameClock clock;
  late MemoryWallet wallet;
  var exp = 0;
  var page = 4;
  OfflineReward offline() => OfflineReward(
      rules: rules,
      income: income,
      clock: clock,
      wallet: wallet,
      farmPage: () => page,
      grantExp: (n) => exp += n);

  setUp(() {
    time = Time(t0);
    clock = GameClock(time);
    wallet = MemoryWallet();
    exp = 0;
    page = 4;
  });

  void away(Duration d) {
    clock.markSeen();
    time.utc = time.utc.add(d);
  }

  test('goldfish / EXP find from gear count offline too', () {
    away(const Duration(hours: 2));
    final plain = offline().compute(
        lastSeenUtc: clock.lastSeenUtc,
        effectiveNowUtc: clock.effectiveNow,
        cap: rules.capFor(0));
    final found = OfflineReward(
            rules: rules,
            income: income,
            clock: clock,
            wallet: wallet,
            farmPage: () => page,
            finds: () => (fishBp: 1000, expBp: 500))
        .compute(
            lastSeenUtc: clock.lastSeenUtc,
            effectiveNowUtc: clock.effectiveNow,
            cap: rules.capFor(0));
    final fish = plain.reward[Currency.goldfish];
    expect(found.reward[Currency.goldfish], closeTo(fish * 1.1, 1));
    expect(found.reward[Currency.yarn], plain.reward[Currency.yarn]);
    expect(found.exp, closeTo(plain.exp * 1.05, 1));
  });

  test('cap = 8 h + 10 min per research level, up to the max level', () {
    expect(rules.capFor(0), const Duration(hours: 8));
    expect(rules.capFor(3), const Duration(minutes: 510));
    expect(rules.capFor(99), const Duration(minutes: 600));
    expect(rules.ratePct, 100);
  });

  test('an hour away pays an hour of farming, same formula as online', () {
    away(const Duration(hours: 1));
    final r = offline().checkIn();
    final waves = (60 * income.wavesPerMinute).floor();
    expect((r.creditedMinutes, r.waves), (60, waves));
    expect(r.reward, income.forWaves(4, waves));
    expect(r.exp, income.expForWaves(4, waves));
  });

  test('longer than the cap pays the cap', () {
    away(const Duration(hours: 20));
    expect(offline().checkIn().creditedMinutes, 480);
    away(const Duration(hours: 20));
    expect(offline().checkIn(offlineResearchLevel: 6).creditedMinutes, 540);
  });

  test('negative time pays nothing', () {
    final r = offline().compute(
        lastSeenUtc: t0,
        effectiveNowUtc: t0.subtract(const Duration(hours: 3)),
        cap: rules.capFor(0));
    expect((r.creditedMinutes, r.reward.isEmpty), (0, true));
  });

  test('a clock turned back pays nothing', () {
    time.utc = t0.add(const Duration(hours: 2));
    clock.tick(); // max_seen = t0 + 2h
    clock.markSeen();
    time.utc = t0.add(const Duration(hours: 1)); // set back
    final r = offline().checkIn();
    expect((r.creditedMinutes, r.reward.isEmpty), (0, true));
  });

  test('a clock pushed forward pays at most the cap', () {
    away(const Duration(days: 3));
    expect(offline().checkIn().creditedMinutes, 480);
  });

  test('claim pays once, then the window is used up', () {
    away(const Duration(hours: 2));
    final o = offline();
    final r = o.checkIn();
    expect(o.claim(), r.reward);
    expect(wallet.balance(Currency.goldfish), r.reward[Currency.goldfish]);
    expect(exp, r.exp);
    expect(o.claim(), RewardBundle.empty); // twice → nothing
    expect(o.checkIn().creditedMinutes, 0); // last_seen moved to now
  });

  test('cloud merge from another device cannot pay the same window twice', () {
    away(const Duration(hours: 5));
    final staleOtherDevice = clock.snapshot(); // last_seen = t0
    offline()
      ..checkIn()
      ..claim(); // last_seen = t0 + 5h
    clock.mergeFrom(staleOtherDevice);
    expect(clock.lastSeenUtc, t0.add(const Duration(hours: 5)));
    expect(offline().checkIn().creditedMinutes, 0);

    // the other way: this device is stale, the cloud has the claim
    final c2 = GameClock(Time(t0.add(const Duration(hours: 5))),
        restored:
            ClockState(lastSeenUtc: t0, maxSeenUtc: t0, dateKey: '2026-10-19'));
    c2.mergeFrom(clock.snapshot());
    final o2 = OfflineReward(
        rules: rules,
        income: income,
        clock: c2,
        wallet: wallet,
        farmPage: () => 4);
    expect(o2.checkIn().creditedMinutes, 0);
  });

  test('bad data fails with the field', () {
    final bad = balance()..['offline'] = {'base_cap_min': '8h'};
    expect(
        () => OfflineRules.fromBalance(bad),
        throwsA(isA<FormatException>()
            .having((e) => e.message, 'message', contains('base_cap_min'))));
  });

  test('providers: offline pays into the wallet and levels the cat', () {
    time.utc = t0;
    final c = ProviderContainer(overrides: [
      timeSourceProvider.overrideWithValue(time),
      combatRulesProvider.overrideWithValue(CombatRules.fromBalance(b)),
      catRulesProvider.overrideWithValue(cat),
      idleRulesProvider.overrideWithValue(idle),
      offlineRulesProvider.overrideWithValue(rules),
      roadEventRulesProvider.overrideWithValue(RoadEventRules.fromJson(
          b,
          jsonDecode(
                  File('../../design/data/road_events.json').readAsStringSync())
              as Map<String, dynamic>)),
      gearRulesProvider.overrideWithValue(GearRules.fromJson(
          b,
          jsonDecode(
                  File('../../design/data/gear_slots.json').readAsStringSync())
              as Map<String, dynamic>,
          hpPm: 1,
          atkPm: 1,
          defPm: 1)),
      walletProvider.overrideWithValue(MemoryWallet()),
    ]);
    addTearDown(c.dispose);
    c.read(gameClockProvider).markSeen();
    time.utc = t0.add(const Duration(hours: 8));
    final o = c.read(offlineRewardProvider);
    final r = o.checkIn();
    expect(r.creditedMinutes, 480);
    o.claim();
    expect(c.read(walletProvider).balance(Currency.goldfish),
        r.reward[Currency.goldfish]);
    expect(c.read(catProgressProvider).level, greaterThan(1));
  });
}
