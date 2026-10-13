import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// Settable device clock + timezone.
class FakeTimeSource implements TimeSource {
  FakeTimeSource(this.utc, {this.offset = const Duration(hours: 7)});

  DateTime utc;
  Duration offset;

  void advance(Duration d) => utc = utc.add(d);

  @override
  DateTime nowUtc() => utc;

  @override
  Duration utcOffset() => offset;
}

void main() {
  // 2026-10-12 10:00 in Bangkok (UTC+7).
  final start = DateTime.utc(2026, 10, 12, 3);

  late FakeTimeSource time;
  late GameClock clock;
  late List<DayRollover> rollovers;

  setUp(() {
    time = FakeTimeSource(start);
    clock = GameClock(time);
    rollovers = [];
    clock.dayRollovers.listen(rollovers.add);
  });

  tearDown(() => clock.dispose());

  group('moving forward', () {
    test('effectiveNow follows the device clock', () {
      time.advance(const Duration(minutes: 90));
      expect(clock.effectiveNow, start.add(const Duration(minutes: 90)));
      expect(clock.maxSeenUtc, start.add(const Duration(minutes: 90)));
    });

    test('crossing local midnight emits one rollover', () {
      // 23:59 local, then 00:01 local.
      time.utc = DateTime.utc(2026, 10, 12, 16, 59);
      clock.tick();
      expect(rollovers, isEmpty);
      time.advance(const Duration(minutes: 2));
      clock.tick();
      clock.tick();
      expect(rollovers, [
        const DayRollover(fromDateKey: '2026-10-12', toDateKey: '2026-10-13'),
      ]);
      expect(clock.dateKey, '2026-10-13');
    });

    test('skipping several days emits a single rollover', () {
      time.advance(const Duration(days: 4));
      clock.tick();
      expect(rollovers, [
        const DayRollover(fromDateKey: '2026-10-12', toDateKey: '2026-10-16'),
      ]);
    });
  });

  group('moving backward', () {
    test('effectiveNow and max_seen never go back', () {
      time.advance(const Duration(hours: 5));
      final peak = clock.effectiveNow;
      time.utc = start.subtract(const Duration(days: 2));
      expect(clock.effectiveNow, peak);
      expect(clock.maxSeenUtc, peak);
      expect(clock.now(), time.utc, reason: 'raw now() still reports the device');
    });

    test('going back a day does not roll over or re-open the old day', () {
      time.advance(const Duration(days: 1));
      clock.tick();
      expect(rollovers, hasLength(1));
      time.utc = start;
      clock.tick();
      expect(rollovers, hasLength(1));
      expect(clock.dateKey, '2026-10-13');
      // Back to the real date: still the same day, no second reset.
      time.advance(const Duration(days: 1));
      clock.tick();
      expect(rollovers, hasLength(1));
    });

    test('markSeen uses effectiveNow, so a rewound clock cannot move last_seen back', () {
      time.advance(const Duration(hours: 3));
      clock.markSeen();
      final seen = clock.lastSeenUtc;
      time.utc = start;
      clock.markSeen();
      expect(clock.lastSeenUtc, seen);
    });
  });

  group('timezone changes', () {
    test('flying east past midnight rolls the day over', () {
      time.utc = DateTime.utc(2026, 10, 12, 16, 30); // 23:30 in UTC+7
      clock.tick();
      time.offset = const Duration(hours: 9); // 01:30 next day in UTC+9
      clock.tick();
      expect(rollovers.single.toDateKey, '2026-10-13');
    });

    test('flying west back across midnight does not roll back', () {
      time.utc = DateTime.utc(2026, 10, 12, 17, 30); // 00:30 on the 13th in UTC+7
      clock.tick();
      expect(clock.dateKey, '2026-10-13');
      time.offset = const Duration(hours: 1); // 18:30 on the 12th
      clock.tick();
      expect(clock.dateKey, '2026-10-13');
      expect(rollovers, hasLength(1));
    });
  });

  group('cloud merge', () {
    test('every field takes the later value', () {
      time.advance(const Duration(hours: 1));
      clock.markSeen();
      final other = ClockState(
        lastSeenUtc: start.add(const Duration(hours: 6)),
        maxSeenUtc: start.add(const Duration(hours: 8)),
        dateKey: '2026-10-14',
      );
      clock.mergeFrom(other);
      expect(clock.snapshot(), other);
    });

    test('an older device does not lower anything', () {
      time.advance(const Duration(hours: 4));
      clock.markSeen();
      clock.tick();
      final before = clock.snapshot();
      clock.mergeFrom(ClockState(
        lastSeenUtc: start,
        maxSeenUtc: start,
        dateKey: '2026-10-01',
      ));
      expect(clock.snapshot(), before);
    });

    test('merge does not emit a rollover; the next tick only rolls past the merged date', () {
      clock.mergeFrom(ClockState(
        lastSeenUtc: start,
        maxSeenUtc: start,
        dateKey: '2026-10-13',
      ));
      expect(rollovers, isEmpty);
      time.advance(const Duration(days: 1)); // local 2026-10-13: already reset
      clock.tick();
      expect(rollovers, isEmpty);
      time.advance(const Duration(days: 1));
      clock.tick();
      expect(rollovers.single.fromDateKey, '2026-10-13');
    });
  });

  group('restore', () {
    test('a later saved max_seen survives a rewound device clock', () {
      final saved = ClockState(
        lastSeenUtc: start.add(const Duration(hours: 2)),
        maxSeenUtc: start.add(const Duration(hours: 2)),
        dateKey: '2026-10-12',
      );
      final restored = GameClock(FakeTimeSource(start), restored: saved);
      addTearDown(restored.dispose);
      expect(restored.effectiveNow, saved.maxSeenUtc);
      expect(restored.lastSeenUtc, saved.lastSeenUtc);
    });

    test('a saved date older than today rolls over on the first tick', () {
      final restored = GameClock(
        FakeTimeSource(start),
        restored: ClockState(lastSeenUtc: start, maxSeenUtc: start, dateKey: '2026-10-10'),
      );
      addTearDown(restored.dispose);
      final events = <DayRollover>[];
      restored.dayRollovers.listen(events.add);
      restored.tick();
      expect(events, [
        const DayRollover(fromDateKey: '2026-10-10', toDateKey: '2026-10-12'),
      ]);
    });
  });

  test('dateKeyOf zero-pads', () {
    expect(GameClock.dateKeyOf(DateTime.utc(987, 3, 4)), '0987-03-04');
  });

  test('gameClockProvider reads the injected time source', () {
    final container = ProviderContainer(overrides: [
      timeSourceProvider.overrideWithValue(FakeTimeSource(start)),
    ]);
    addTearDown(container.dispose);
    expect(container.read(gameClockProvider).effectiveNow, start);
  });
}
