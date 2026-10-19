import 'combat.dart';

/// The eight gear slots (GDD v0.5 §4.1). The first four are open from the
/// start; the rest open by pages cleared (`slot_unlocks`).
enum GearSlot {
  weapon,
  hat,
  shirt,
  shoes,
  scarf,
  gloves,
  bell,
  bag;

  static GearSlot? fromName(String name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// Grade index 0–5 (white → rainbow) as listed in idle_balance_v1.json.
typedef GearGrade = int;

/// One knitted item. Stats are final (grade and page applied); the slot
/// level bonus is added when the item is worn.
class GearItem {
  const GearItem({
    required this.id,
    required this.slot,
    required this.grade,
    required this.page,
    required this.stats,
    this.randomSlotBonus = false,
  });

  final String id;
  final GearSlot slot;
  final GearGrade grade;

  /// Page the item was knitted at (sets its power).
  final int page;
  final StatBlock stats;

  /// Knitted with "random slot": recycling it gives bonus basket EXP.
  final bool randomSlotBonus;

  /// Art tier: white/green → 1, blue/purple → 2, gold/rainbow → 3
  /// (design/art/gear_prompts.md).
  int get tier => grade < 2 ? 1 : (grade < 4 ? 2 : 3);

  /// Look unlocked in the wardrobe when first knitted (GDD v0.5 §4.2).
  String get styleId => '${slot.name}_$tier';

  /// Every base stat ≥ [other]'s and not all equal → ✨ star.
  bool isStrictlyBetterThan(GearItem? other) {
    if (other == null) return true;
    final a = stats, b = other.stats;
    final ge = a.hp >= b.hp && a.atk >= b.atk && a.def >= b.def;
    final same = a.hp == b.hp && a.atk == b.atk && a.def == b.def;
    return ge && !same;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slot': slot.name,
        'grade': grade,
        'page': page,
        'hp': stats.hp,
        'atk': stats.atk,
        'def': stats.def,
        'attrs': {for (final e in stats.attrs.entries) e.key.key: e.value},
        if (randomSlotBonus) 'random': true,
      };

  factory GearItem.fromJson(Map<String, dynamic> j) {
    T f<T>(String k) {
      final v = j[k];
      if (v is! T) {
        throw FormatException('gear item: "$k" missing or wrong type');
      }
      return v;
    }

    final slot = GearSlot.fromName(f<String>('slot')) ??
        (throw FormatException('gear item: unknown slot ${j['slot']}'));
    final attrs = <Attribute, int>{};
    for (final e in f<Map<String, dynamic>>('attrs').entries) {
      final a = Attribute.fromKey(e.key) ??
          (throw FormatException('gear item: unknown stat ${e.key}'));
      if (e.value is! int) throw FormatException('gear item: ${e.key} not int');
      attrs[a] = e.value as int;
    }
    return GearItem(
      id: f<String>('id'),
      slot: slot,
      grade: f<int>('grade'),
      page: f<int>('page'),
      stats: StatBlock(
          hp: f<int>('hp'),
          atk: f<int>('atk'),
          def: f<int>('def'),
          attrs: attrs),
      randomSlotBonus: j['random'] == true,
    );
  }
}

/// Outcome of one craft. The item waits as "pending" until it is equipped
/// or recycled.
class CraftResult {
  const CraftResult({
    required this.item,
    required this.isStrictlyBetter,
    required this.isNewStyle,
  });

  final GearItem item;
  String get itemId => item.id;
  GearSlot get slot => item.slot;
  GearGrade get grade => item.grade;

  /// Every base stat ≥ the equipped item and not all equal → ✨ star.
  final bool isStrictlyBetter;

  /// First time this look was knitted (wardrobe unlock).
  final bool isNewStyle;
}

/// Yarn basket, "knit it yourself" variant (D-002 Q0 = ข). Owner:
/// `gear_basket` (T-036). GDD v0.4 §3, v0.5 §4.
abstract class IGearBasket {
  /// Crafts for [slot], or a random open slot (bonus basket EXP) when null.
  /// Costs one yarn; throws [StateError] without yarn or for a locked slot.
  CraftResult craft(GearSlot? slot);

  /// Wears a pending or stashed item; the item it replaces is recycled.
  void equip(String itemId);

  /// Turns a pending or stashed item into goldfish + basket EXP.
  void recycle(String itemId);

  /// Upgrades the slot, not the item — swapping items keeps the level.
  void upgradeSlot(GearSlot slot);

  /// Grade percentages shown to the player before crafting; must be the
  /// same table the roll uses.
  List<double> get gradeTable;
}

/// What auto-craft does with an item stronger than what the slot has
/// (GDD v0.5 §4.3).
enum AutoCraftMode {
  /// Keep the best one per slot for the player to compare (✨ on the slot).
  stash,

  /// Wear it right away; the old item is recycled.
  equip,
}

/// Why auto-craft stopped.
enum AutoCraftStopReason {
  outOfYarn,
  stoppedByPlayer,
  appBackgrounded,
}

/// Save v3 `gear.auto_craft` (GDD v0.5 §4.3 — min grade / affix filters are
/// out of the MVP, D-004).
class AutoCraftRule {
  const AutoCraftRule({this.on = false, this.mode = AutoCraftMode.stash});

  final bool on;
  final AutoCraftMode mode;

  Map<String, dynamic> toJson() => {'on': on, 'better': mode.name};

  factory AutoCraftRule.fromJson(Map<String, dynamic> j) {
    final on = j['on'];
    final mode = AutoCraftMode.values.where((m) => m.name == j['better']);
    if (on is! bool || mode.isEmpty) {
      throw const FormatException('auto_craft: needs "on" and "better"');
    }
    return AutoCraftRule(on: on, mode: mode.first);
  }

  @override
  bool operator ==(Object other) =>
      other is AutoCraftRule && other.on == on && other.mode == mode;

  @override
  int get hashCode => Object.hash(on, mode);
}

/// Auto-craft, online only (GDD v0.5 §4.3). Owner: `gear_basket` (T-037).
abstract class IAutoCraft {
  void configure(AutoCraftRule rule);
  void start();
  void stop();
  Stream<AutoCraftStopReason> get stopped;
}
