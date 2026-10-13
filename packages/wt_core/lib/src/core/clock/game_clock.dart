import 'dart:async';

/// Wall-clock source for [GameClock]. The device clock is the only time
/// source the game has — there is no backend (GDD v0.4 §8, GAME_CONTRACT §4.6).
/// Tests inject a fake to move time and timezone freely.
abstract class TimeSource {
  /// Current instant in UTC.
  DateTime nowUtc();

  /// Current offset of the device's local timezone from UTC.
  Duration utcOffset();
}

/// Reads the real device clock.
class SystemTimeSource implements TimeSource {
  const SystemTimeSource();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();

  @override
  Duration utcOffset() => DateTime.now().timeZoneOffset;
}

/// Persisted clock fields: `clock.last_seen_utc`, `clock.max_seen_utc` and
/// `daily.date_key` in Save v3 (GAME_CONTRACT §4.6).
class ClockState {
  const ClockState({
    required this.lastSeenUtc,
    required this.maxSeenUtc,
    required this.dateKey,
  });

  final DateTime lastSeenUtc;
  final DateTime maxSeenUtc;

  /// Local calendar date `yyyy-MM-dd` of the last daily reset.
  final String dateKey;

  @override
  bool operator ==(Object other) =>
      other is ClockState &&
      other.lastSeenUtc == lastSeenUtc &&
      other.maxSeenUtc == maxSeenUtc &&
      other.dateKey == dateKey;

  @override
  int get hashCode => Object.hash(lastSeenUtc, maxSeenUtc, dateKey);
}

/// Emitted once when the local date moves forward, however many days were
/// skipped. Daily quotas (ads, fish pulls) reset on this event only.
class DayRollover {
  const DayRollover({required this.fromDateKey, required this.toDateKey});

  final String fromDateKey;
  final String toDateKey;

  @override
  bool operator ==(Object other) =>
      other is DayRollover &&
      other.fromDateKey == fromDateKey &&
      other.toDateKey == toDateKey;

  @override
  int get hashCode => Object.hash(fromDateKey, toDateKey);

  @override
  String toString() => 'DayRollover($fromDateKey → $toDateKey)';
}

/// The game's single source of time (GAME_CONTRACT §4.6 clock rules).
///
/// - [effectiveNow] never moves backwards: setting the device clock back
///   cannot undo research timers or create offline time.
/// - The daily reset follows the local date and only ever moves forward:
///   going back a day (clock or timezone) never re-opens daily quotas.
/// - Moving the clock forward is treated like real waiting; the offline cap
///   limits what that can earn.
class GameClock {
  GameClock(this._source, {ClockState? restored}) {
    final now = _source.nowUtc();
    _maxSeenUtc = restored == null ? now : _later(restored.maxSeenUtc, now);
    _lastSeenUtc = restored?.lastSeenUtc ?? now;
    _dateKey = restored?.dateKey ?? _localDateKey();
  }

  final TimeSource _source;
  final _rollovers = StreamController<DayRollover>.broadcast(sync: true);

  late DateTime _maxSeenUtc;
  late DateTime _lastSeenUtc;
  late String _dateKey;

  /// Raw device time in UTC. Prefer [effectiveNow] for anything that grants
  /// rewards or advances timers.
  DateTime now() => _source.nowUtc();

  /// `max(now, max_seen)`. Reading it also records the current time as seen,
  /// so [maxSeenUtc] only grows.
  DateTime get effectiveNow {
    _maxSeenUtc = _later(_maxSeenUtc, _source.nowUtc());
    return _maxSeenUtc;
  }

  DateTime get maxSeenUtc => _maxSeenUtc;

  /// When the player was last in the game; offline rewards count from here.
  DateTime get lastSeenUtc => _lastSeenUtc;

  /// Local date of the last daily reset.
  String get dateKey => _dateKey;

  Stream<DayRollover> get dayRollovers => _rollovers.stream;

  /// Samples the clock: updates [maxSeenUtc] and emits [DayRollover] if the
  /// local date moved forward. Call on resume and periodically while playing.
  void tick() {
    effectiveNow;
    final today = _localDateKey();
    if (today.compareTo(_dateKey) > 0) {
      final from = _dateKey;
      _dateKey = today;
      _rollovers.add(DayRollover(fromDateKey: from, toDateKey: today));
    }
  }

  /// Records that the player is present now (on pause/save).
  void markSeen() => _lastSeenUtc = effectiveNow;

  /// Merges a clock restored from another device's cloud save: every field
  /// takes the later value, so an offline window or a daily reset can never
  /// be claimed twice by switching devices.
  void mergeFrom(ClockState other) {
    _maxSeenUtc = _later(_maxSeenUtc, other.maxSeenUtc);
    _lastSeenUtc = _later(_lastSeenUtc, other.lastSeenUtc);
    if (other.dateKey.compareTo(_dateKey) > 0) _dateKey = other.dateKey;
  }

  ClockState snapshot() => ClockState(
        lastSeenUtc: _lastSeenUtc,
        maxSeenUtc: _maxSeenUtc,
        dateKey: _dateKey,
      );

  Future<void> dispose() => _rollovers.close();

  String _localDateKey() =>
      dateKeyOf(_source.nowUtc().add(_source.utcOffset()));

  /// `yyyy-MM-dd` of a wall-clock date; ISO ordering makes string comparison
  /// equal date comparison.
  static String dateKeyOf(DateTime localWallClock) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${localWallClock.year.toString().padLeft(4, '0')}-'
        '${two(localWallClock.month)}-${two(localWallClock.day)}';
  }

  static DateTime _later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
}
