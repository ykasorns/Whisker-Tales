import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

void main() {
  List<int> take(int seed, int n) {
    final r = SeededRng(seed);
    return [for (var i = 0; i < n; i++) r.nextUint32()];
  }

  test('known sequence (guards against accidental algorithm changes)', () {
    expect(take(42, 3), [1369506609, 1227121042, 1742610489]);
  });

  test('same seed, same sequence; different seed, different sequence', () {
    expect(take(7, 50), take(7, 50));
    expect(take(7, 50), isNot(take(8, 50)));
  });

  test('values stay in range, including seed 0', () {
    for (final seed in [0, 1, -1, 0x9E3779B9]) {
      final r = SeededRng(seed);
      for (var i = 0; i < 1000; i++) {
        final v = r.nextUint32();
        expect(v, inInclusiveRange(1, 0xFFFFFFFF));
        expect(r.nextBp(), inInclusiveRange(0, kBp - 1));
      }
    }
  });

  test('nextBp is roughly uniform', () {
    final r = SeededRng(123);
    var below = 0;
    for (var i = 0; i < 100000; i++) {
      if (r.nextBp() < 2500) below++;
    }
    expect(below / 100000, closeTo(0.25, 0.01));
  });
}
