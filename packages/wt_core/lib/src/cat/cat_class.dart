import '../core/contracts/cat_class.dart';
import '../core/contracts/combat.dart';
import 'cat_progress.dart';
import 'cat_rules.dart';

/// Class choice (GDD v0.5 §3.2): pick a first class at
/// [CatRules.classUnlockLevel]; switch freely within the same tier outside a
/// boss fight; grow into a tier-2 class from the parent at
/// [CatRules.tier2Level].
class CatClass implements ICatClass {
  CatClass(this.rules, this.progress,
      {bool Function()? inBossFight, this.skillsFor})
      : _inBossFight = inBossFight ?? _never,
        _current = rules.novice;

  /// Skill lookup from `combat` (SkillBook.skillsFor), injected so this
  /// module does not import combat. Null = no skills.
  final List<SkillSpec> Function(String classId, int slots)? skillsFor;

  final CatRules rules;
  final CatProgress progress;
  final bool Function() _inBossFight;
  ClassModifiers _current;

  static bool _never() => false;

  @override
  String get current => _current.id;

  @override
  ClassModifiers get modifiers => _current;

  @override
  List<ClassModifiers> get available {
    final level = progress.level;
    if (level < rules.classUnlockLevel) return const [];
    final tier = _current.tier == 0 ? 1 : _current.tier;
    return [
      for (final c in rules.classes)
        if (c.id != _current.id &&
            (c.tier == tier ||
                (c.tier == 2 &&
                    _current.tier == 1 &&
                    c.from == _current.id &&
                    level >= rules.tier2Level)))
          c,
    ];
  }

  @override
  void choose(String classId) {
    if (progress.level < rules.classUnlockLevel) {
      throw StateError('classes open at Lv${rules.classUnlockLevel}');
    }
    if (_inBossFight()) throw StateError('cannot change class in a boss fight');
    final next = available.where((c) => c.id == classId);
    if (next.isEmpty) throw StateError('class $classId is not available');
    _current = next.first;
  }

  @override
  int get skillsUnlocked => _current.tier == 0
      ? 0
      : rules.skillSlotLevels.where((l) => progress.level >= l).length;

  /// Final stats for the fight: (level base + [extra]) × class, so the
  /// class keeps its identity when gear makes up most of the stats (YK
  /// 2026-10-19, D-007). [extra] = gear, pets, research. Bonus stats add up.
  /// Level growth is linear: base × (1 + growth × (level − 1)).
  CombatUnitSpec combatSpec({String id = 'mochi', StatBlock? extra}) {
    final c = _current;
    final levelBp = kBp + rules.levelGrowthBp * (progress.level - 1);
    final b = rules.baseStats;
    int main(int base, int add, int classBp) =>
        (base * levelBp ~/ kBp + add) * classBp ~/ kBp;
    final attrs = <Attribute, int>{...c.bonus};
    for (final e in (extra?.attrs ?? const <Attribute, int>{}).entries) {
      attrs[e.key] = (attrs[e.key] ?? 0) + e.value;
    }
    return CombatUnitSpec(
      id: id,
      side: CombatSide.cat,
      stats: StatBlock(
        hp: main(b.hp, extra?.hp ?? 0, c.hpBp),
        atk: main(b.atk, extra?.atk ?? 0, c.atkBp),
        def: main(b.def, extra?.def ?? 0, c.defBp),
        attrs: attrs,
      ),
      attackIntervalMs: c.attackIntervalMs,
      range: c.range,
      skills: skillsFor?.call(c.id, skillsUnlocked) ?? const [],
    );
  }

  /// Save v3 `cat` block.
  CatState snapshot() => CatState(
      level: progress.level,
      exp: progress.exp,
      classId: _current.id,
      tier: _current.tier);

  /// Restores level, EXP and class; throws [FormatException] if the save
  /// does not fit the data (unknown class, wrong tier, level too low).
  void restore(CatState s) {
    final c = rules.classById(s.classId);
    if (c == null) throw FormatException('cat: unknown class "${s.classId}"');
    if (c.tier != s.tier) {
      throw FormatException(
          'cat: class ${c.id} is tier ${c.tier}, save says ${s.tier}');
    }
    final need = switch (c.tier) {
      0 => 1,
      1 => rules.classUnlockLevel,
      _ => rules.tier2Level,
    };
    if (s.level < need) {
      throw FormatException(
          'cat: class ${c.id} needs Lv$need, save has Lv${s.level}');
    }
    progress.restore(s);
    _current = c;
  }
}
