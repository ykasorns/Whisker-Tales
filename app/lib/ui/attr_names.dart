import 'package:wt_core/wt_core.dart';

import '../l10n/gen/app_localizations.dart';

/// The player-facing name of a secondary stat (TH/EN).
String attrName(AppLocalizations s, Attribute a) => switch (a) {
      Attribute.crit => s.attrCrit,
      Attribute.critDmg => s.attrCritDmg,
      Attribute.critRes => s.attrCritRes,
      Attribute.critDmgRes => s.attrCritDmgRes,
      Attribute.combo => s.attrCombo,
      Attribute.comboRes => s.attrComboRes,
      Attribute.counter => s.attrCounter,
      Attribute.counterRes => s.attrCounterRes,
      Attribute.stun => s.attrStun,
      Attribute.stunRes => s.attrStunRes,
      Attribute.evade => s.attrEvade,
      Attribute.accuracy => s.attrAccuracy,
      Attribute.lifesteal => s.attrLifesteal,
      Attribute.lifestealRes => s.attrLifestealRes,
      Attribute.regen => s.attrRegen,
      Attribute.attackSpeed => s.attrAttackSpeed,
      Attribute.skillDmg => s.attrSkillDmg,
      Attribute.bossDmg => s.attrBossDmg,
      Attribute.petDmg => s.attrPetDmg,
      Attribute.cdr => s.attrCdr,
      Attribute.yarnFind => s.attrYarnFind,
      Attribute.fishFind => s.attrFishFind,
      Attribute.expFind => s.attrExpFind,
      Attribute.craftLuck => s.attrCraftLuck,
      Attribute.armorPierce => s.attrArmorPierce,
      Attribute.dmgReduction => s.attrDmgReduction,
      Attribute.thorns => s.attrThorns,
      Attribute.execute => s.attrExecute,
      Attribute.openingShield => s.attrOpeningShield,
    };

/// "+5.0%" — attribute values are basis points.
String attrValue(int bp) => '+${(bp / 100).toStringAsFixed(1)}%';

/// Painted icon id of a secondary stat (`stat_crit_dmg`, …). Crit keeps the
/// older `crit` icon; a few stats have no stat sheet icon (and use none).
String? attrIconId(Attribute a) {
  if (a == Attribute.crit) return 'crit';
  if (a == Attribute.evade) return 'evade';
  if (a == Attribute.skillDmg) return 'sparkle';
  final snake = a.name.replaceAllMapped(
      RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');
  return 'stat_$snake';
}
