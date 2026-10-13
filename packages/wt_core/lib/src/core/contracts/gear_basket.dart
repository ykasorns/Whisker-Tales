/// The eight gear slots (GDD v0.4 §3).
enum GearSlot { hat, scarf, shirt, armband, shoes, bell, bag, toy }

/// Grade index 0–5 (white → rainbow) as listed in idle_balance_v1.json.
typedef GearGrade = int;

/// Outcome of one craft. Item details are defined by `gear_basket` (T-036).
class CraftResult {
  const CraftResult({
    required this.itemId,
    required this.slot,
    required this.grade,
    required this.isStrictlyBetter,
  });

  final String itemId;
  final GearSlot slot;
  final GearGrade grade;

  /// Every base stat ≥ the equipped item and not all equal → ✨ star.
  final bool isStrictlyBetter;
}

/// Yarn basket, "knit it yourself" variant (D-002 Q0 = ข). Owner:
/// `gear_basket` (T-036). GDD v0.4 §3.
abstract class IGearBasket {
  /// Crafts for [slot], or a random slot (bonus basket EXP) when null.
  CraftResult craft(GearSlot? slot);

  void equip(String itemId);
  void recycle(String itemId);

  /// Upgrades the slot, not the item — swapping items keeps the level.
  void upgradeSlot(GearSlot slot);

  /// Grade percentages shown to the player before crafting; must be the
  /// same table the roll uses.
  List<double> get gradeTable;
}

/// Why auto-craft stopped.
enum AutoCraftStopReason { outOfYarn, matchFound, strictlyBetterFound, stoppedByPlayer, appBackgrounded }

class AutoCraftRule {
  const AutoCraftRule({
    required this.slots,
    required this.minGrade,
    this.wantedAffixes = const [],
  });

  final List<GearSlot> slots;
  final GearGrade minGrade;

  /// At most two affix ids.
  final List<String> wantedAffixes;
}

/// Auto-craft, online only (D-002 Q4). Owner: `gear_basket` (T-037).
abstract class IAutoCraft {
  void configure(AutoCraftRule rule);
  void start();
  void stop();
  Stream<AutoCraftStopReason> get stopped;
}
