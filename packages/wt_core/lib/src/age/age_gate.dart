import '../core/contracts/age_gate.dart';

/// Save v3 `age.band` names (GAME_CONTRACT §4.6).
const ageBandNames = {
  AgeBand.unset: 'unset',
  AgeBand.under13: 'under13',
  AgeBand.over13: '13plus',
};

/// Age from the neutral first-launch screen (GDD v0.4 §14, T-040, D-026):
/// asked once, never skipped; anything unknown counts as under 13. Once
/// answered, only a grown-up who passed the parental gate can change it.
class AgeGate implements IAgeGate {
  AgeGate({required this.isParentPass});

  /// Whether a pass from the parental gate is live (wired to
  /// `ParentalGate.isValid`, so this module does not import iap).
  final bool Function(Object? pass) isParentPass;

  AgeBand _band = AgeBand.unset;

  /// Ages at or above this are `13plus`.
  static const adultFrom = 13;

  @override
  AgeBand get band => _band;

  /// What the rest of the game should assume: unset counts as under 13.
  bool get treatAsChild => _band != AgeBand.over13;

  @override
  bool get needsPrompt => _band == AgeBand.unset;

  static AgeBand bandFor(int age) =>
      age >= adultFrom ? AgeBand.over13 : AgeBand.under13;

  /// The first answer. Throws once answered — use [changeBand].
  @override
  void setBand(AgeBand band) {
    if (!needsPrompt) {
      throw StateError('age already answered: a grown-up changes it');
    }
    if (band == AgeBand.unset) throw ArgumentError.value(band, 'band');
    _band = band;
  }

  /// A grown-up changes the answer; false without a live parental [pass].
  bool changeBand(AgeBand band, {required Object? pass}) {
    if (band == AgeBand.unset || !isParentPass(pass)) return false;
    _band = band;
    return true;
  }

  String toJsonBand() => ageBandNames[_band]!;

  /// Unknown or missing names load as unset: asked again, a child till then.
  void restore(Object? name) {
    _band = ageBandNames.entries
        .firstWhere((e) => e.value == name,
            orElse: () => const MapEntry(AgeBand.unset, 'unset'))
        .key;
  }
}
