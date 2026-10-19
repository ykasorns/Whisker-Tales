import 'dart:math' as math;

import '../core/contracts/combat.dart';
import '../core/contracts/gear_basket.dart';
import '../core/random/seeded_rng.dart';

/// One affix the slot can roll (`design/data/gear_slots.json`).
class AffixDef {
  const AffixDef(this.attr, this.minBp, this.maxBp, {this.special = false});
  final Attribute attr;
  final int minBp;
  final int maxBp;

  /// Special-tier affix: purple grade and up only (GDD v0.5 §5).
  final bool special;
}

class SlotDef {
  const SlotDef({
    required this.slot,
    required this.atkPct,
    required this.hpPct,
    required this.defPct,
    required this.affixes,
    required this.unlockPage,
  });
  final GearSlot slot;

  /// Share of the item's power that becomes each main stat.
  final int atkPct, hpPct, defPct;
  final List<AffixDef> affixes;

  /// Pages cleared before the slot opens.
  final int unlockPage;
}

/// One row of the basket grade table (GDD v0.4 §15.4).
class BasketRow {
  const BasketRow(this.level, this.pct, this.expToNext);
  final int level;
  final List<int> pct;
  final int expToNext;
}

/// Gear + basket numbers: `gear`, `basket`, `slot_unlocks` and the fish
/// curve of `idle_balance_v1.json`, plus `design/data/gear_slots.json`.
/// Doubles become ints here, once.
class GearRules {
  GearRules._({
    required this.slots,
    required this.gradeMultBp,
    required this.rows,
    required this.basketMaxLevel,
    required this.pityEvery,
    required this.pityMinGrade,
    required this.slotUpgradeBp,
    required this.recycleBasketExp,
    required this.randomSlotBonusPct,
    required this.autoCraftIntervalMs,
    required this.affixCountByGrade,
    required this.specialMinGrade,
    required this.affixGradeBonusPct,
    required this.variancePct,
    required num itemPowerBase,
    required num itemPowerGrowth,
    required num upgradeCostBase,
    required num upgradeCostGrowth,
    required num recycleFish,
    required num fishGrowth,
    required this.hpPm,
    required this.atkPm,
    required this.defPm,
  })  : _itemPowerBase = itemPowerBase,
        _itemPowerGrowth = itemPowerGrowth,
        _upgradeCostBase = upgradeCostBase,
        _upgradeCostGrowth = upgradeCostGrowth,
        _recycleFish = recycleFish,
        _fishGrowth = fishGrowth;

  final Map<GearSlot, SlotDef> slots;
  final List<int> gradeMultBp;
  final List<BasketRow> rows;
  final int basketMaxLevel;
  final int pityEvery;
  final int pityMinGrade;
  final int slotUpgradeBp;
  final int recycleBasketExp;
  final int randomSlotBonusPct;
  final int autoCraftIntervalMs;
  final List<int> affixCountByGrade;
  final int specialMinGrade;
  final int affixGradeBonusPct;
  final int variancePct;
  final num _itemPowerBase, _itemPowerGrowth;
  final num _upgradeCostBase, _upgradeCostGrowth;
  final num _recycleFish, _fishGrowth;

  /// §15.2 power weights (per-mille) to turn item power into stats.
  final int hpPm, atkPm, defPm;

  /// Grade table row for basket [level] (last row at or below it).
  BasketRow rowFor(int level) => rows.lastWhere((r) => r.level <= level);

  /// Item power at [page] and [grade] before variance.
  int itemPower(int page, GearGrade grade) =>
      (_itemPowerBase * math.pow(_itemPowerGrowth, page - 1)).round() *
      gradeMultBp[grade] ~/
      kBp;

  /// Goldfish for one slot level-up from [level].
  int upgradeCost(int level) =>
      (_upgradeCostBase * math.pow(_upgradeCostGrowth, level)).round();

  /// Goldfish for recycling an item knitted on [page].
  int recycleFish(int page) =>
      (_recycleFish * math.pow(_fishGrowth, page - 1)).round();

  /// Rolls power variance and affixes for an item of [grade].
  StatBlock rollStats(SeededRng rng, GearSlot slot, GearGrade grade, int page) {
    final def = slots[slot]!;
    final spread = 2 * variancePct + 1;
    final power = itemPower(page, grade) *
        (100 - variancePct + rng.nextUint32() % spread) ~/
        100;
    final pool = [
      for (final a in def.affixes)
        if (!a.special || grade >= specialMinGrade) a,
    ];
    final attrs = <Attribute, int>{};
    for (var n = affixCountByGrade[grade]; n > 0 && pool.isNotEmpty; n--) {
      final a = pool.removeAt(rng.nextUint32() % pool.length);
      final v = a.minBp + rng.nextUint32() % (a.maxBp - a.minBp + 1);
      attrs[a.attr] =
          (attrs[a.attr] ?? 0) + v * (100 + grade * affixGradeBonusPct) ~/ 100;
    }
    int main(int pct, int pm) => power * pct * 10 ~/ pm;
    return StatBlock(
      hp: main(def.hpPct, hpPm),
      atk: main(def.atkPct, atkPm),
      def: main(def.defPct, defPm),
      attrs: attrs,
    );
  }

  /// [balance] = idle_balance_v1.json, [slotsJson] = gear_slots.json,
  /// [weights] = §15.2 weights in per-mille (hp, atk, def).
  factory GearRules.fromJson(
    Map<String, dynamic> balance,
    Map<String, dynamic> slotsJson, {
    required int hpPm,
    required int atkPm,
    required int defPm,
  }) {
    final gear = _map(balance, 'gear', 'balance');
    final basket = _map(balance, 'basket', 'balance');
    final unlocks = _map(balance, 'slot_unlocks', 'balance');
    final income = _map(balance, 'income', 'balance');
    final slotData = _map(slotsJson, 'slots', 'gear_slots');
    final slots = <GearSlot, SlotDef>{};
    for (final slot in GearSlot.values) {
      final d = _map(slotData, slot.name, 'gear_slots.slots');
      final split = _map(d, 'power_split', 'gear_slots.${slot.name}');
      final affixes = d['affixes'];
      if (affixes is! List) {
        throw FormatException(
            'gear_slots.${slot.name}: "affixes" must be a list');
      }
      slots[slot] = SlotDef(
        slot: slot,
        atkPct: _int(split, 'atk', slot.name),
        hpPct: _int(split, 'hp', slot.name),
        defPct: _int(split, 'def', slot.name),
        unlockPage: _int(unlocks, slot.name, 'slot_unlocks'),
        affixes: [
          for (final a in affixes)
            if (a is Map<String, dynamic>)
              AffixDef(
                Attribute.fromKey(a['stat'] as String? ?? '') ??
                    (throw FormatException(
                        'gear_slots.${slot.name}: unknown stat ${a['stat']}')),
                (_num(a, 'min', slot.name) * 100).round(),
                (_num(a, 'max', slot.name) * 100).round(),
                special: a['special'] == true,
              )
            else
              throw FormatException('gear_slots.${slot.name}: bad affix'),
        ],
      );
      final s = slots[slot]!;
      if (s.atkPct + s.hpPct + s.defPct != 100) {
        throw FormatException(
            'gear_slots.${slot.name}: power_split must add to 100');
      }
    }
    final grades = (gear['grade_mult'] as List).cast<num>();
    final rawRows = basket['rows'];
    if (rawRows is! List || rawRows.isEmpty) {
      throw const FormatException('basket: "rows" must be a non-empty list');
    }
    final rows = [
      for (final r in rawRows.cast<Map<String, dynamic>>())
        BasketRow(
            _int(r, 'level', 'basket'),
            List.unmodifiable((r['pct'] as List).cast<int>()),
            _int(r, 'exp_to_next', 'basket')),
    ];
    for (final r in rows) {
      if (r.pct.length != grades.length ||
          r.pct.fold(0, (a, b) => a + b) != 100) {
        throw FormatException(
            'basket row ${r.level}: pct must have one entry per grade and add to 100');
      }
    }
    final counts = (slotsJson['affix_count_by_grade'] as List).cast<int>();
    if (counts.length != grades.length) {
      throw const FormatException('gear_slots: one affix count per grade');
    }
    return GearRules._(
      slots: Map.unmodifiable(slots),
      gradeMultBp:
          List.unmodifiable([for (final g in grades) (g * kBp).round()]),
      rows: List.unmodifiable(rows),
      basketMaxLevel: _int(basket, 'max_level', 'basket'),
      pityEvery: _int(gear, 'pity_every', 'gear'),
      pityMinGrade: _int(gear, 'pity_min_grade', 'gear'),
      slotUpgradeBp:
          (_num(gear, 'slot_upgrade_pct_per_level', 'gear') * kBp).round(),
      recycleBasketExp: _int(gear, 'recycle_basket_exp', 'gear'),
      randomSlotBonusPct: _int(gear, 'random_slot_exp_bonus_pct', 'gear'),
      autoCraftIntervalMs: _int(gear, 'auto_craft_interval_ms', 'gear'),
      affixCountByGrade: List.unmodifiable(counts),
      specialMinGrade: _int(slotsJson, 'special_min_grade', 'gear_slots'),
      affixGradeBonusPct:
          _int(slotsJson, 'affix_grade_bonus_pct', 'gear_slots'),
      variancePct: _int(slotsJson, 'item_power_variance_pct', 'gear_slots'),
      itemPowerBase: _num(gear, 'item_power_base_per_slot', 'gear'),
      itemPowerGrowth: _num(gear, 'item_power_growth_per_page', 'gear'),
      upgradeCostBase: _num(gear, 'slot_upgrade_cost_base', 'gear'),
      upgradeCostGrowth: _num(gear, 'slot_upgrade_cost_growth', 'gear'),
      recycleFish: _num(gear, 'recycle_fish_per_item', 'gear'),
      fishGrowth: _num(income, 'fish_growth_per_page', 'income'),
      hpPm: hpPm,
      atkPm: atkPm,
      defPm: defPm,
    );
  }
}

num _num(Map<String, dynamic> m, String key, String where) {
  final v = m[key] ?? m['ASSUMPTION_$key'];
  if (v is! num) throw FormatException('$where: "$key" must be a number');
  return v;
}

int _int(Map<String, dynamic> m, String key, String where) {
  final v = m[key] ?? m['ASSUMPTION_$key'];
  if (v is! int) throw FormatException('$where: "$key" must be an integer');
  return v;
}

Map<String, dynamic> _map(Map<String, dynamic> m, String key, String where) {
  final v = m[key];
  if (v is! Map<String, dynamic>) {
    throw FormatException('$where: "$key" must be an object');
  }
  return v;
}
