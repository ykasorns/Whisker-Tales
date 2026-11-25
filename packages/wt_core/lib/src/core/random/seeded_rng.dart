import '../contracts/combat.dart';

/// Deterministic xorshift32 (GAME_CONTRACT §5). Shifts and xors on 32-bit
/// values only, so it gives the same sequence on every platform.
class SeededRng {
  SeededRng(int seed) : _s = _mix(seed);

  /// Resumes a generator saved with [state].
  SeededRng.fromState(int state)
      : _s = (state & 0xFFFFFFFF) == 0 ? 0x6D2B79F5 : state & 0xFFFFFFFF;

  int _s;

  /// Current internal state; save it to continue the same sequence later.
  int get state => _s;

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

/// `(a * b) mod 2^32` for 32-bit [a] and [b], exact on every platform. A
/// plain product can pass 2^53, where web numbers lose their low bits, so
/// hashes would differ between the web and Android builds.
int mul32(int a, int b) {
  a &= 0xFFFFFFFF;
  b &= 0xFFFFFFFF;
  final lo = (a & 0xFFFF) * b; // < 2^48
  final hi = ((a >> 16) * b) & 0xFFFF; // only its low 16 bits survive
  return (lo + hi * 0x10000) & 0xFFFFFFFF;
}
