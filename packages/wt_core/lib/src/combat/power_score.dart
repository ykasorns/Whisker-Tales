import '../core/contracts/combat.dart';
import 'combat_rules.dart';

/// Cat power 🐾 — the one number kids see (GDD v0.4 §15.2 as revised by
/// D-011): `(ATK×5 + HP×0.5 + DEF×3) × (1 + Σ stat% × weight)`. Secondary
/// stats scale the main power instead of adding a flat amount, so a small
/// affix never outweighs real ATK/HP/DEF. Crit damage counts only its bonus
/// above the base.
class PowerScore {
  const PowerScore(this.weights);

  final PowerWeights weights;

  int of(StatBlock s) {
    final main =
        s.atk * weights.atkPm + s.hp * weights.hpPm + s.def * weights.defPm;
    var bonusBp = 0;
    for (final e in weights.attrPm.entries) {
      bonusBp += s[e.key] * e.value ~/ 1000;
    }
    return main * (kBp + bonusBp) ~/ (kBp * 1000);
  }
}
