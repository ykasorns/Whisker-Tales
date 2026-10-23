/// Tells a real absence from a blink (YK 2026-10-23: the screenshot tool, a
/// notification shade or a system dialog pause the app for a moment — that
/// must not open "welcome back"). The time away is measured from the first
/// moment the app left the foreground; shorter than [minAway] is not away.
class AwayTracker {
  /// The offline reward pays from one minute (`creditedMinutes ≥ 1`).
  static const minAway = Duration(minutes: 1);

  DateTime? _left;

  /// The app left the foreground (inactive, hidden or paused).
  void left(DateTime now) => _left ??= now;

  /// The app is back. True only when it was gone for [minAway] or more;
  /// either way the tracker starts over.
  bool back(DateTime now) {
    final since = _left;
    _left = null;
    return since != null && now.difference(since) >= minAway;
  }
}
