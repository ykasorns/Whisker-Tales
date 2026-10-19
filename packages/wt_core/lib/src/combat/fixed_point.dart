import '../core/contracts/combat.dart';

/// Converts a JSON percentage (5, 0.5, 150) to basis points. The only place
/// a `double` turns into combat state, at load time.
int bpFromPct(num pct) => (pct * 100).round();

/// [value] × [bp] / 10000, truncated. Both are non-negative in combat.
int mulBp(int value, int bp) => value * bp ~/ kBp;

int clampInt(int v, int lo, int hi) => v < lo ? lo : (v > hi ? hi : v);
