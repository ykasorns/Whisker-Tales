import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/src/core/random/seeded_rng.dart';

void main() {
  test('mul32 equals the 64-bit product mod 2^32', () {
    final rng = SeededRng(7);
    for (var i = 0; i < 5000; i++) {
      final a = rng.nextUint32(), b = rng.nextUint32();
      expect(mul32(a, b), (a * b) & 0xFFFFFFFF, reason: '$a * $b');
    }
    expect(mul32(0xFFFFFFFF, 0x01000193), (0xFFFFFFFF * 0x01000193) & 0xFFFFFFFF);
  });
}
