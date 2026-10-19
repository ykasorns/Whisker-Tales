import 'gear_basket.dart';

/// Save v3 `wardrobe` (GAME_CONTRACT §4.6). `chosen` maps a slot to a style
/// id or [WardrobeState.hidden]; a slot missing from it follows the worn item.
class WardrobeState {
  const WardrobeState({
    this.unlocked = const [],
    this.chosen = const {},
    this.skin = 'base',
    this.skinsUnlocked = const ['base'],
  });

  /// Chosen value that hides the slot's look.
  static const hidden = 'none';

  final List<String> unlocked;
  final Map<GearSlot, String> chosen;
  final String skin;
  final List<String> skinsUnlocked;

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked,
        'chosen': {for (final e in chosen.entries) e.key.name: e.value},
        'skin': skin,
        'skins_unlocked': skinsUnlocked,
      };

  factory WardrobeState.fromJson(Map<String, dynamic> j) {
    List<String> strings(String k) {
      final v = j[k];
      if (v is! List || v.any((e) => e is! String)) {
        throw FormatException('wardrobe: "$k" must be a list of ids');
      }
      return List.unmodifiable(v.cast<String>());
    }

    final chosen = j['chosen'];
    final skin = j['skin'];
    if (chosen is! Map<String, dynamic> || skin is! String) {
      throw const FormatException('wardrobe: needs "chosen" and "skin"');
    }
    return WardrobeState(
      unlocked: strings('unlocked'),
      skinsUnlocked: strings('skins_unlocked'),
      skin: skin,
      chosen: {
        for (final e in chosen.entries)
          (GearSlot.fromName(e.key) ??
              (throw FormatException('wardrobe: unknown slot ${e.key}'))): e
                  .value is String
              ? e.value as String
              : throw FormatException('wardrobe: ${e.key} must be a style id'),
      },
    );
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

/// Wardrobe: looks are separate from power (GDD v0.5 §4.2). Owner:
/// `wardrobe` (T-045).
abstract class IWardrobe {
  Set<String> get unlocked;

  /// Unlocks a look for good; returns true if it was new.
  bool unlock(String styleId);

  /// Shows [styleId] on [slot]; null = follow the worn item;
  /// [WardrobeState.hidden] = show nothing.
  void choose(GearSlot slot, String? styleId);

  /// Art to draw for [slot] (e.g. `dagger_2`, `hat_3`, `icon_bell_1`), or
  /// null when nothing shows. Weapons follow [classId].
  String? lookFor(GearSlot slot, String classId);

  String get skin;
  void chooseSkin(String skinId);
}
