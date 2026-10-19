import '../core/contracts/combat.dart';

/// Deterministic xorshift32 (GAME_CONTRACT §5). Shifts and xors on 32-bit
/// values only, so it gives the same sequence on every platform.
class SeededRng {
  SeededRng(int seed) : _s = _mix(seed);

  int _s;

  static int _mix(int seed) {
    final s = (seed ^ 0x9E3779B9) & 0xFFFFFFFF;
    return s == 0 ? 0x6D2B79F5 : s;
  }

  /// Next value in [0, 2^32).
  int nextUint32() {
    var x = _s;
    x ^= (x << 13) & 0xFFFFFFFF;
    x ^= x >> 17;
    x ^= (x << 5) & 0xFFFFFFFF;
    return _s = x;
  }

  /// Next value in [0, [kBp]) — compared against basis-point chances.
  int nextBp() => nextUint32() % kBp;
}
