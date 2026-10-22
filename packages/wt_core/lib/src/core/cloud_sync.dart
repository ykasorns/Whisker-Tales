import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../save/save.dart';
import 'game_save.dart';

enum SyncResult {
  /// No cloud (switched off, not signed in, no network, too slow).
  offline,

  /// This device had more progress (or the cloud was empty): uploaded.
  uploaded,

  /// The cloud had more progress: it is now the game here.
  downloaded,

  /// The cloud has more progress, and this sync only uploads (on pause):
  /// left alone, taken at the next boot.
  cloudAhead,

  /// The cloud answered with something unreadable; nothing was changed.
  failed,
}

/// Cloud save (T-023, D-025): one Save v3 document per Play Games account,
/// merged with [mergeSaves]. Never blocks play: every cloud call has a
/// [timeout], and any failure leaves the local game as it was.
///
/// - [sync] at boot, before the game starts: the side with more progress
///   becomes the game on this device, and the merge goes back up.
/// - [push] when leaving the app: uploads unless the cloud is ahead (then
///   the next boot takes it) — the game never changes under the player.
class CloudSync {
  CloudSync(this._ref, {this.timeout = const Duration(seconds: 3)});

  final Ref _ref;
  final Duration timeout;

  CloudStore get _store => _ref.read(cloudStoreProvider);
  GameSaver get _saver => _ref.read(gameSaverProvider);
  SaveService get _local => _ref.read(saveServiceProvider);

  Future<SyncResult> sync() => _run(pull: true);
  Future<SyncResult> push() => _run(pull: false);

  Future<SyncResult> _run({required bool pull}) async {
    // one deadline for the whole check: the game waits at most [timeout],
    // and once it has started the game is never changed by a late answer
    final clock = Stopwatch()..start();
    Duration left() {
      final l = timeout - clock.elapsed;
      if (l <= Duration.zero) throw TimeoutException('cloud', timeout);
      return l;
    }

    final Map<String, dynamic> mine;
    final ({Map<String, dynamic> doc, MergeWinner winner})? merged;
    try {
      if (!await _store.available().timeout(left())) return SyncResult.offline;
      final raw = await _store.read().timeout(left());
      left(); // too late: leave the game alone
      // a look only: the offline window must stay open for the player
      mine = _saver.capture(asSeen: false);
      if (raw == null) {
        merged = null;
      } else {
        final decoded = jsonDecode(raw);
        if (decoded is! Map<String, dynamic>) return SyncResult.failed;
        merged = mergeSaves(mine, _local.upgrade(decoded));
      }
    } on TimeoutException {
      return SyncResult.offline;
    } on Object {
      // unreadable cloud data, a newer app's save, a platform error: the
      // local game stays exactly as it was
      return SyncResult.failed;
    }

    final cloudWins = merged?.winner == MergeWinner.cloud;
    if (cloudWins && !pull) return SyncResult.cloudAhead;
    final up = merged?.doc ?? mine;
    if (pull && merged != null) {
      // the merge becomes the game here too: the other device's quotas,
      // purchases and clock count even when this device's game is kept
      try {
        _saver.restore(merged.doc);
      } on Object {
        _saver.restore(mine); // no half-loaded game: back as it was
        return SyncResult.failed;
      }
      await _local.save(_saver.capture(asSeen: false));
    }
    try {
      await _store.write(jsonEncode(up)).timeout(timeout);
    } on Object {
      // the game here is already right; the cloud catches up next time
      if (!cloudWins) return SyncResult.offline;
    }
    return cloudWins ? SyncResult.downloaded : SyncResult.uploaded;
  }
}

/// Play Games saved games in the app (T-023); none by default.
final cloudStoreProvider = Provider<CloudStore>((ref) => const NoCloudStore());

/// Cloud save (T-023).
final cloudSyncProvider = Provider<CloudSync>((ref) => CloudSync(ref));
