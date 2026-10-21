import '../core/contracts/gear_basket.dart';
import '../core/contracts/wardrobe.dart';

/// `design/data/wardrobe.json` (GDD v0.5.1 §4.2, D-024).
class WardrobeRules {
  const WardrobeRules({required this.tiers, required this.weaponArt});

  final int tiers;

  /// Weapon icon art per class id (`sword`, `dagger`, …) for the slot.
  final Map<String, String> weaponArt;

  /// Every style id in the collection book, by slot then tier.
  List<(GearSlot, int, String)> get catalog => [
        for (final s in GearSlot.values)
          for (var t = 1; t <= tiers; t++) (s, t, '${s.name}_$t'),
      ];

  factory WardrobeRules.fromJson(Map<String, dynamic> j) {
    final tiers = j['tiers'];
    final art = j['weapon_art'];
    if (tiers is! int || tiers < 1) {
      throw const FormatException('wardrobe: needs tiers ≥ 1');
    }
    if (art is! Map<String, dynamic> || art.values.any((e) => e is! String)) {
      throw const FormatException(
          'wardrobe: "weapon_art" must map class ids to art names');
    }
    return WardrobeRules(
        tiers: tiers, weaponArt: Map.unmodifiable(art.cast<String, String>()));
  }
}

/// Collection book (GDD v0.5.1 §4.2, D-024): knitting a look for the first
/// time keeps it in the book for good. Never touches stats, never dresses
/// the cat.
class Wardrobe implements IWardrobe {
  Wardrobe(this.rules);

  final WardrobeRules rules;
  final _unlocked = <String>{};

  @override
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  bool _isStyle(String id) => rules.catalog.any((c) => c.$3 == id);

  @override
  bool unlock(String styleId) {
    if (!_isStyle(styleId)) throw ArgumentError.value(styleId, 'styleId');
    return _unlocked.add(styleId);
  }

  /// The collection book: every look, unlocked or silhouette.
  List<CollectionEntry> get collection => [
        for (final (slot, tier, id) in rules.catalog)
          CollectionEntry(
              styleId: id,
              slot: slot,
              tier: tier,
              unlocked: _unlocked.contains(id)),
      ];

  WardrobeState snapshot() =>
      WardrobeState(unlocked: List.unmodifiable(_unlocked.toList()..sort()));

  /// Looks the data no longer has are dropped (a look is only a picture).
  void restore(WardrobeState s) {
    _unlocked
      ..clear()
      ..addAll(s.unlocked.where(_isStyle));
  }
}
