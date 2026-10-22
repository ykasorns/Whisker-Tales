import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

import '_world.dart';

/// Play Games saved game slot, in memory.
class FakeCloud implements CloudStore {
  bool on = true;
  String? data;
  int writes = 0;
  Object? readError;
  bool hang = false;

  @override
  Future<bool> available() async => on;
  @override
  Future<String?> read() async {
    if (hang) return Completer<String?>().future;
    if (readError case final e?) throw e;
    return data;
  }

  @override
  Future<void> write(String d) async {
    writes++;
    data = d;
  }

  Map<String, dynamic> get doc => jsonDecode(data!) as Map<String, dynamic>;
}

void main() {
  final t0 = DateTime.utc(2026, 10, 22, 2);

  /// One phone: its own clock and local save, sharing [cloud].
  ProviderContainer phone(Time time, FakeCloud cloud,
      {SaveStore? store, Duration timeout = const Duration(seconds: 3)}) {
    final c = ProviderContainer(overrides: [
      ...world(time),
      saveServiceProvider
          .overrideWithValue(SaveService(store ?? MemorySaveStore())),
      cloudStoreProvider.overrideWithValue(cloud),
      cloudSyncProvider.overrideWith((ref) => CloudSync(ref, timeout: timeout)),
    ]);
    addTearDown(c.dispose);
    return c;
  }

  Map<String, dynamic> doc(
          {int page = 1,
          int power = 100,
          String updated = '2026-10-22T02:00:00.000Z',
          Map<String, dynamic>? clock,
          Map<String, dynamic>? daily,
          Map<String, dynamic>? ent}) =>
      {
        'save_version': 3,
        'idle': {'cleared_page': page},
        'profile': {'power': power},
        'clock': clock ??
            {
              'last_seen_utc': '2026-10-22T02:00:00.000Z',
              'max_seen_utc': '2026-10-22T02:00:00.000Z'
            },
        'daily': daily ?? {'date_key': '2026-10-22', 'ads_used': {}},
        'entitlements': ent ?? {'no_ads': false, 'skus': []},
        'updated_at': updated,
      };

  group('conflict rule (GAME_CONTRACT §4.6)', () {
    test('more pages cleared wins, from either side', () {
      expect(mergeSaves(doc(page: 5), doc(page: 3)).winner, MergeWinner.local);
      expect(mergeSaves(doc(page: 3), doc(page: 5)).winner, MergeWinner.cloud);
      expect(mergeSaves(doc(page: 3), doc(page: 5)).doc['idle'],
          {'cleared_page': 5});
    });

    test('same page: more power wins; then the later save; a tie keeps local',
        () {
      expect(mergeSaves(doc(power: 90), doc(power: 120)).winner,
          MergeWinner.cloud);
      expect(mergeSaves(doc(power: 120), doc(power: 90)).winner,
          MergeWinner.local);
      expect(
          mergeSaves(doc(updated: '2026-10-22T05:00:00Z'),
                  doc(updated: '2026-10-22T06:00:00Z'))
              .winner,
          MergeWinner.cloud);
      expect(mergeSaves(doc(), doc()).winner, MergeWinner.local);
      // a save from before T-023 has no power: counts as 0
      expect(
          mergeSaves(doc()..['profile'] = {}, doc()).winner, MergeWinner.cloud);
    });

    test('clock: the later last_seen and max_seen, whoever wins', () {
      final m = mergeSaves(
          doc(page: 9, clock: {
            'last_seen_utc': '2026-10-22T01:00:00Z',
            'max_seen_utc': '2026-10-22T09:00:00Z'
          }),
          doc(page: 2, clock: {
            'last_seen_utc': '2026-10-22T08:00:00Z',
            'max_seen_utc': '2026-10-22T08:30:00Z'
          }));
      expect(m.winner, MergeWinner.local);
      expect(m.doc['clock'], {
        'last_seen_utc': '2026-10-22T08:00:00Z',
        'max_seen_utc': '2026-10-22T09:00:00Z'
      });
    });

    test('daily: the newer day; the same day keeps the larger counts', () {
      final older = {
        'date_key': '2026-10-21',
        'ads_used': {'pet_hatch': 3},
        'ads_total': 9,
        'fish_pulls': 5
      };
      final today = {
        'date_key': '2026-10-22',
        'ads_used': {'yarn_bundle': 1},
        'ads_total': 1,
        'fish_pulls': 0
      };
      expect(
          mergeSaves(doc(page: 9, daily: older), doc(daily: today))
              .doc['daily'],
          today);
      final other = {
        'date_key': '2026-10-22',
        'ads_used': {'pet_hatch': 2, 'yarn_bundle': 0},
        'ads_total': 2,
        'fish_pulls': 4
      };
      expect(mergeSaves(doc(daily: today), doc(daily: other)).doc['daily'], {
        'date_key': '2026-10-22',
        'ads_used': {'yarn_bundle': 1, 'pet_hatch': 2},
        'ads_total': 2,
        'fish_pulls': 4
      });
    });

    test('purchases from either phone are kept', () {
      final m = mergeSaves(
          doc(page: 9),
          doc(ent: {
            'no_ads': true,
            'skus': ['supporter_pack']
          }));
      expect(m.winner, MergeWinner.local);
      expect(m.doc['entitlements'], {
        'no_ads': true,
        'skus': ['supporter_pack']
      });
    });

    test('the two inputs are never changed', () {
      final a = doc(page: 2), b = doc(page: 7);
      final before = jsonEncode([a, b]);
      final m = mergeSaves(a, b);
      (m.doc['idle'] as Map)['cleared_page'] = 99;
      expect(jsonEncode([a, b]), before);
    });
  });

  group('sync never blocks or breaks play', () {
    test('no cloud: offline, nothing written, the game untouched', () async {
      final cloud = FakeCloud()..on = false;
      final p = phone(Time(t0), cloud);
      p.read(idleLoopProvider).restore(clearedPage: 4);
      expect(await p.read(cloudSyncProvider).sync(), SyncResult.offline);
      expect(cloud.writes, 0);
      expect(p.read(idleLoopProvider).state.clearedPage, 4);
    });

    test('an empty cloud gets this phone', () async {
      final cloud = FakeCloud();
      final p = phone(Time(t0), cloud);
      p.read(idleLoopProvider).restore(clearedPage: 4);
      expect(await p.read(cloudSyncProvider).sync(), SyncResult.uploaded);
      expect(cloud.doc['idle']['cleared_page'], 4);
      expect(cloud.doc['profile']['power'], greaterThan(0));
    });

    test('unreadable, garbage or too slow: nothing changes', () async {
      final cloud = FakeCloud()..readError = Exception('PGS error');
      final p =
          phone(Time(t0), cloud, timeout: const Duration(milliseconds: 50));
      p.read(idleLoopProvider).restore(clearedPage: 4);
      expect(await p.read(cloudSyncProvider).sync(), SyncResult.failed);
      cloud
        ..readError = null
        ..data = '[not a save';
      expect(await p.read(cloudSyncProvider).sync(), SyncResult.failed);
      cloud
        ..data = null
        ..hang = true;
      expect(await p.read(cloudSyncProvider).sync(), SyncResult.offline);
      expect(cloud.writes, 0);
      expect(p.read(idleLoopProvider).state.clearedPage, 4);
    });

    test('a cloud save that does not fit the data leaves the game as it was',
        () async {
      final cloud = FakeCloud();
      final a = phone(Time(t0), cloud);
      a.read(idleLoopProvider).restore(clearedPage: 9);
      await a.read(cloudSyncProvider).sync();
      cloud.data = jsonEncode(cloud.doc
        ..['pets'] = {
          'owned': {
            'dragon': {'stars': 1}
          },
          'deployed': [],
          'pity': 0
        });
      final b = phone(Time(t0), cloud);
      b.read(idleLoopProvider).restore(clearedPage: 2);
      expect(await b.read(cloudSyncProvider).sync(), SyncResult.failed);
      expect(b.read(idleLoopProvider).state.clearedPage, 2);
    });
  });

  group('two phones', () {
    test('the phone further ahead wins at boot; the other takes it', () async {
      final cloud = FakeCloud();
      final a = phone(Time(t0), cloud);
      a.read(idleLoopProvider).restore(clearedPage: 9);
      (a.read(walletProvider) as MemoryWallet)
          .add(RewardBundle({Currency.goldfish: 777}));
      expect(await a.read(cloudSyncProvider).push(), SyncResult.uploaded);

      final store = MemorySaveStore();
      final b = phone(Time(t0), cloud, store: store);
      b.read(idleLoopProvider).restore(clearedPage: 3);
      expect(await b.read(cloudSyncProvider).sync(), SyncResult.downloaded);
      expect(b.read(idleLoopProvider).state.clearedPage, 9);
      expect(b.read(walletProvider).balance(Currency.goldfish), 777);
      // kept on this phone too
      final local = await SaveService(store).load();
      expect(local.document!['idle']['cleared_page'], 9);
    });

    test('leaving the app never overwrites a cloud that is ahead', () async {
      final cloud = FakeCloud();
      final a = phone(Time(t0), cloud);
      a.read(idleLoopProvider).restore(clearedPage: 9);
      await a.read(cloudSyncProvider).push();
      final before = cloud.data;
      final b = phone(Time(t0), cloud);
      b.read(idleLoopProvider).restore(clearedPage: 3);
      expect(await b.read(cloudSyncProvider).push(), SyncResult.cloudAhead);
      expect(cloud.data, before);
      expect(b.read(idleLoopProvider).state.clearedPage, 3);
      // this phone further ahead: its push goes up
      b.read(idleLoopProvider).restore(clearedPage: 12);
      expect(await b.read(cloudSyncProvider).push(), SyncResult.uploaded);
      expect(cloud.doc['idle']['cleared_page'], 12);
    });

    test('different clocks: an offline window is never paid twice', () async {
      final cloud = FakeCloud();
      // phone A: played until 10:00 and left (last_seen 10:00)
      final ta = Time(t0.add(const Duration(hours: 8)));
      final a = phone(ta, cloud);
      a.read(idleLoopProvider).restore(clearedPage: 5);
      a.read(gameSaverProvider).capture(); // leaving marks seen
      await a.read(cloudSyncProvider).push();

      // phone B: last played at 02:00, opened at 11:00 → only 1 h is new
      final tb = Time(t0);
      final b = phone(tb, cloud);
      b.read(gameClockProvider).markSeen();
      tb.utc = t0.add(const Duration(hours: 9));
      await b.read(cloudSyncProvider).sync();
      expect(b.read(offlineRewardProvider).checkIn().creditedMinutes, 60);

      // phone C: its clock is 3 h behind A's — no window at all
      final tc = Time(t0.add(const Duration(hours: 5)));
      final c = phone(tc, cloud);
      await c.read(cloudSyncProvider).sync();
      expect(c.read(offlineRewardProvider).checkIn().creditedMinutes, 0);
    });

    test('today\'s quotas and purchases follow the player', () async {
      final cloud = FakeCloud();
      final a = phone(Time(t0), cloud);
      a.read(idleLoopProvider).restore(clearedPage: 5);
      for (var i = 0; i < 3; i++) {
        await a.read(adServiceProvider).show('pet_hatch');
      }
      a.read(iapServiceProvider)!.deliver('supporter_pack');
      await a.read(cloudSyncProvider).push();

      // phone B is further ahead, but the same day: A's ads still count
      final b = phone(Time(t0.add(const Duration(minutes: 30))), cloud);
      b.read(idleLoopProvider).restore(clearedPage: 8);
      expect(await b.read(cloudSyncProvider).sync(), SyncResult.uploaded);
      expect(b.read(idleLoopProvider).state.clearedPage, 8);
      expect(b.read(iapServiceProvider)!.hasNoAds, isTrue);
      expect(b.read(adServiceProvider).remainingToday('pet_hatch'), 0);
      expect(cloud.doc['idle']['cleared_page'], 8);
    });
  });
}
