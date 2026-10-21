import 'gear_basket.dart';

/// Save v3 `wardrobe` (GAME_CONTRACT §4.6, D-024): looks knitted so far.
/// Saves from before D-024 also have `chosen` / `skin` — read and ignored,
/// since the cat now wears its class outfit.
class WardrobeState {
  const WardrobeState({this.unlocked = const []});

  final List<String> unlocked;

  Map<String, dynamic> toJson() => {'unlocked': unlocked};

  factory WardrobeState.fromJson(Map<String, dynamic> j) {
    final v = j['unlocked'];
    if (v is! List || v.any((e) => e is! String)) {
      throw const FormatException('wardrobe: "unlocked" must be a list of ids');
    }
    return WardrobeState(unlocked: List.unmodifiable(v.cast<String>()));
  }
}

/// One look in the collection book; [unlocked] false = shown as a
/// silhouette (GDD v0.5 §4.2).
class CollectionEntry {
  const CollectionEntry(
      {required this.styleId,
      required this.slot,
      required this.tier,
      required this.unlocked});
  final String styleId;
  final GearSlot slot;
  final int tier;
  final bool unlocked;
}

/// Collection book (D-024): every look knitted at least once, kept for
/// good. Looks are never worn on the cat — it wears its class outfit.
/// Owner: `wardrobe` (T-045).
abstract class IWardrobe {
  Set<String> get unlocked;

  /// Unlocks a look for good; returns true if it was new.
  bool unlock(String styleId);
}
