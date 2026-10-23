import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/away_tracker.dart';

/// YK 2026-10-23: the screenshot tool paused the app for a few seconds and
/// "welcome back" popped up. Only a real absence may open it.
void main() {
  final t0 = DateTime(2026, 10, 23, 18, 0);

  test('a blink (screenshot, dialog, ad) is not an absence', () {
    final a = AwayTracker()..left(t0);
    expect(a.back(t0.add(const Duration(seconds: 6))), isFalse);
    final b = AwayTracker()..left(t0);
    expect(b.back(t0.add(const Duration(seconds: 59))), isFalse);
  });

  test('a minute or more away is real', () {
    final a = AwayTracker()..left(t0);
    expect(a.back(t0.add(AwayTracker.minAway)), isTrue);
    final b = AwayTracker()..left(t0);
    expect(b.back(t0.add(const Duration(hours: 5))), isTrue);
  });

  test('the time counts from the FIRST step out of the foreground', () {
    // inactive → hidden → paused all report "left": it is one absence
    final a = AwayTracker()
      ..left(t0)
      ..left(t0.add(const Duration(seconds: 20)))
      ..left(t0.add(const Duration(seconds: 40)));
    expect(a.back(t0.add(const Duration(seconds: 70))), isTrue);
  });

  test('reset forgets an absence (a rewarded ad, however long)', () {
    final a = AwayTracker()..left(t0);
    a.reset();
    expect(a.back(t0.add(const Duration(minutes: 5))), isFalse);
  });

  test('it starts over after every return; no "left" means not away', () {
    final a = AwayTracker()..left(t0);
    expect(a.back(t0.add(const Duration(minutes: 3))), isTrue);
    expect(a.back(t0.add(const Duration(minutes: 9))), isFalse);
    a.left(t0.add(const Duration(minutes: 10)));
    expect(a.back(t0.add(const Duration(minutes: 10, seconds: 5))), isFalse);
  });
}
