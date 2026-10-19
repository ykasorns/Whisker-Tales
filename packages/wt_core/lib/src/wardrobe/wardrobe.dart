import '../core/contracts/gear_basket.dart';
import '../core/contracts/wardrobe.dart';

/// `design/data/wardrobe.json` (GDD v0.5.1 §4.2).
class WardrobeRules {
  const WardrobeRules({
    required this.tiers,
    required this.onBody,
    required this.weaponArt,
    required this.offHandArt,
    required this.skins,
    required this.defaultSkin,
    required this.iap,
  });

  final int tiers;
  final Set<GearSlot> onBody;

  /// Weapon art per class id (`sword`, `dagger`, …).
  final Map<String, String> weaponArt;

  /// Second-hand art per class id (`shield`, `dagger`).
  final Map<String, String> offHandArt;

  /// Skin id → pages cleared to unlock it (null = default or IAP only).
  final Map<String, int?> skins;
  final String defaultSkin;

  /// Purchase sku → style / skin ids it unlocks (cosmetic only).
  final Map<String, List<String>> iap;

  /// Every style id in the collection book, by slot then tier.
  List<(GearSlot, int, String)> get catalog => [
        for (final s in GearSlot.values)
          for (var t = 1; t <= tiers; t++) (s, t, '${s.name}_$t'),
      ];

  factory WardrobeRules.fromJson(Map<String, dynamic> j) {
    Map<String, String> strMap(String k) {
      final v = j[k];
      if (v is! Map<String, dynamic> || v.values.any((e) => e is! String)) {
        throw FormatException('wardrobe: "$k" must map ids to names');
      }
      return Map.unmodifiable(v.cast<String, String>());
    }

    final tiers = j['tiers'];
    final onBody = j['on_body'];
    final skins = j['skins'];
    final iap = j['iap'];
    if (tiers is! int ||
        tiers < 1 ||
        onBody is! List ||
        skins is! List ||
        iap is! Map<String, dynamic>) {
      throw const FormatException('wardrobe: needs tiers, on_body, skins, iap');
    }
    final skinMap = <String, int?>{};
    String? def;
    for (final s in skins.cast<Map<String, dynamic>>()) {
      final id = s['id'];
      if (id is! String) {
        throw const FormatException('wardrobe: skin needs an id');
      }
      if (s['default'] == true) def = id;
      skinMap[id] = s['unlock'] == 'cleared_page' ? s['value'] as int : null;
    }
    if (def == null) {
      throw const FormatException('wardrobe: one skin must be default');
    }
    return WardrobeRules(
      tiers: tiers,
      onBody: {
        for (final n in onBody.cast<String>())
          GearSlot.fromName(n) ??
              (throw FormatException('wardrobe: unknown slot $n')),
      },
      weaponArt: strMap('weapon_art'),
      offHandArt: strMap('off_hand_art'),
      skins: Map.unmodifiable(skinMap),
      defaultSkin: def,
      iap: {
        for (final e in iap.entries)
          e.key: List.unmodifiable((e.value as List).cast<String>()),
      },
    );
  }
}

/// Wardrobe (GDD v0.5.1 §4.2): knitting a look for the first time unlocks it
/// for good; each slot can show a different unlocked look than the item
/// that gives the power. Never touches stats.
class Wardrobe implements IWardrobe {
  Wardrobe(this.rules, {required this.equipped, required this.clearedPage})
      : _skin = rules.defaultSkin,
        _skins = {rules.defaultSkin};

  final WardrobeRules rules;

  /// The item worn in a slot (from `gear_basket`), for "follow the item".
  final GearItem? Function(GearSlot) equipped;
  final int Function() clearedPage;

  final _unlocked = <String>{};
  final _chosen = <GearSlot, String>{};
  String _skin;
  final Set<String> _skins;

  @override
  Set<String> get unlocked => Set.unmodifiable(_unlocked);

  bool _isStyle(String id) => rules.catalog.any((c) => c.$3 == id);

  @override
  bool unlock(String styleId) {
    if (!_isStyle(styleId)) throw ArgumentError.value(styleId, 'styleId');
    return _unlocked.add(styleId);
  }

  @override
  void choose(GearSlot slot, String? styleId) {
    if (styleId == null) {
      _chosen.remove(slot);
      return;
    }
    if (styleId != WardrobeState.hidden) {
      if (!styleId.startsWith('${slot.name}_')) {
        throw ArgumentError('style $styleId is not for ${slot.name}');
      }
      if (!_unlocked.contains(styleId)) {
        throw StateError('style $styleId is not unlocked');
      }
    }
    _chosen[slot] = styleId;
  }

  /// Style shown on [slot] before class art is applied, or null.
  String? styleOn(GearSlot slot) {
    final c = _chosen[slot];
    if (c == WardrobeState.hidden) return null;
    return c ?? equipped(slot)?.styleId;
  }

  @override
  String? lookFor(GearSlot slot, String classId) {
    final style = styleOn(slot);
    if (style == null) return null;
    final tier = style.substring(style.lastIndexOf('_') + 1);
    if (slot == GearSlot.weapon) {
      final art = rules.weaponArt[classId] ??
          (throw ArgumentError.value(classId, 'classId', 'no weapon art'));
      return '${art}_$tier';
    }
    return rules.onBody.contains(slot) ? style : 'icon_$style';
  }

  /// Second-hand art (shield / 2nd dagger) for [classId], matching the
  /// weapon tier, or null.
  String? offHandFor(String classId) {
    final art = rules.offHandArt[classId];
    final weapon = styleOn(GearSlot.weapon);
    if (art == null || weapon == null) return null;
    return '${art}_${weapon.substring(weapon.lastIndexOf('_') + 1)}';
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

  @override
  String get skin => _skin;
  Set<String> get skinsUnlocked {
    _checkProgressSkins();
    return Set.unmodifiable(_skins);
  }

  void _checkProgressSkins() {
    for (final e in rules.skins.entries) {
      final need = e.value;
      if (need != null && clearedPage() >= need) _skins.add(e.key);
    }
  }

  @override
  void chooseSkin(String skinId) {
    _checkProgressSkins();
    if (!_skins.contains(skinId)) throw StateError('skin $skinId is locked');
    _skin = skinId;
  }

  /// Applies a cosmetic purchase (called behind the parental gate, T-025).
  void grantPurchase(String sku) {
    final ids = rules.iap[sku] ??
        (throw ArgumentError.value(sku, 'sku', 'not a cosmetic'));
    for (final id in ids) {
      if (rules.skins.containsKey(id)) {
        _skins.add(id);
      } else {
        unlock(id);
      }
    }
  }

  WardrobeState snapshot() => WardrobeState(
        unlocked: List.unmodifiable(_unlocked.toList()..sort()),
        chosen: Map.unmodifiable(_chosen),
        skin: _skin,
        skinsUnlocked: List.unmodifiable(_skins.toList()..sort()),
      );

  /// Throws [FormatException] for ids the data does not know.
  void restore(WardrobeState s) {
    for (final id in s.unlocked) {
      if (!_isStyle(id)) throw FormatException('wardrobe: unknown style $id');
    }
    for (final id in s.skinsUnlocked) {
      if (!rules.skins.containsKey(id)) {
        throw FormatException('wardrobe: unknown skin $id');
      }
    }
    if (!s.skinsUnlocked.contains(s.skin)) {
      throw FormatException('wardrobe: skin ${s.skin} is not unlocked');
    }
    for (final e in s.chosen.entries) {
      if (e.value != WardrobeState.hidden &&
          (!e.value.startsWith('${e.key.name}_') ||
              !s.unlocked.contains(e.value))) {
        throw FormatException(
            'wardrobe: bad look ${e.value} for ${e.key.name}');
      }
    }
    _unlocked
      ..clear()
      ..addAll(s.unlocked);
    _chosen
      ..clear()
      ..addAll(s.chosen);
    _skins
      ..clear()
      ..addAll(s.skinsUnlocked);
    _skin = s.skin;
  }
}
