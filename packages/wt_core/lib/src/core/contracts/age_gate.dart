/// Age band from the neutral first-launch screen. [unset] is treated as
/// [under13] everywhere (GDD v0.4 §14, D-002 Q6).
/// Save v3 stores these as `unset | under13 | 13plus` (GAME_CONTRACT §4.6);
/// [over13] is the Dart name for `13plus`.
enum AgeBand { unset, under13, over13 }

/// Owner: `age_gate` (T-040).
abstract class IAgeGate {
  AgeBand get band;

  /// True until the player has answered the first-launch screen.
  bool get needsPrompt;

  /// Changing an answered band later goes through the parental gate (T-025).
  void setBand(AgeBand band);
}
