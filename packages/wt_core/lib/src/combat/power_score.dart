import '../core/contracts/combat.dart';
import 'combat_rules.dart';

/// Cat power 🐾 — the one number kids see (GDD v0.4 §15.2):
/// `ATK×5 + HP×0.5 + DEF×3 + Σ(stat% × 100 × weight)`. A stat% × 100 is its
/// basis-point value; crit damage counts only the bonus above the base.
class PowerScore {
  const PowerScore(this.weights);

  final PowerWeights weights;

  int of(StatBlock s) {
    var total =
        s.atk * weights.atkPm + s.hp * weights.hpPm + s.def * weights.defPm;
    for (final e in weights.attrPm.entries) {
      total += s[e.key] * e.value;
    }
    return total ~/ 1000;
  }
}
