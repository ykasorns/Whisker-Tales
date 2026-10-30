import '../combat/buffs.dart';
import '../core/contracts/run_systems.dart';

enum StoryEffectTarget { self, enemy }

class StoryEffect {
  const StoryEffect({
    required this.trigger,
    required this.buffId,
    required this.target,
    required this.chancePct,
  });

  final EffectTrigger trigger;
  final String buffId;
  final StoryEffectTarget target;
  final int chancePct;
}

class StorySynergy {
  const StorySynergy({required this.withRelic, required this.effect});
  final String withRelic;
  final StoryEffect effect;

  String get buffId => effect.buffId;
}

class StoryRelic {
  const StoryRelic({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.descriptionEn,
    required this.icon,
    required this.rarity,
    required this.effects,
    required this.synergies,
  });

  final String id, nameTh, nameEn, descriptionTh, descriptionEn, icon, rarity;
  final List<StoryEffect> effects;
  final List<StorySynergy> synergies;
}

class StoryTalentSynergy {
  const StoryTalentSynergy({required this.relicId, required this.effect});

  final String relicId;
  final StoryEffect effect;
}

class StoryTalent {
  const StoryTalent({
    required this.id,
    required this.tree,
    required this.tier,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.descriptionEn,
    required this.icon,
    required this.effects,
    required this.requires,
    required this.crossSynergies,
  });

  final String id, tree, nameTh, nameEn, descriptionTh, descriptionEn, icon;
  final int tier;
  final List<StoryEffect> effects;
  final String? requires;
  final List<StoryTalentSynergy> crossSynergies;
}

class StoryMonster {
  const StoryMonster({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.sprite,
    required this.role,
    required this.isBoss,
    required this.weight,
    required this.powerPct,
    required this.hpWeight,
    required this.atkWeight,
    required this.defWeight,
    required this.attackIntervalMs,
    required this.onHitBuffs,
  });

  final String id, nameTh, nameEn, sprite, role;
  final bool isBoss;
  final int weight, powerPct, hpWeight, atkWeight, defWeight, attackIntervalMs;
  final List<String> onHitBuffs;
}

class StoryEventOutcome {
  const StoryEventOutcome({
    this.goldfish = 0,
    this.xp = 0,
    this.healPct = 0,
    this.damagePct = 0,
    this.relicChoice = false,
    this.buffId,
  });

  final int goldfish, xp, healPct, damagePct;
  final bool relicChoice;
  final String? buffId;
}

class StoryEventChoice {
  const StoryEventChoice({
    required this.id,
    required this.labelTh,
    required this.labelEn,
    required this.resultTh,
    required this.resultEn,
    required this.icon,
    required this.outcome,
  });

  final String id, labelTh, labelEn, resultTh, resultEn, icon;
  final StoryEventOutcome outcome;
}

class StoryEvent {
  const StoryEvent({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.descriptionEn,
    required this.icon,
    required this.choices,
  });

  final String id, nameTh, nameEn, descriptionTh, descriptionEn, icon;
  final List<StoryEventChoice> choices;
}

class StoryPotion {
  const StoryPotion({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.descriptionTh,
    required this.descriptionEn,
    required this.icon,
    required this.price,
    required this.buffId,
  });

  final String id, nameTh, nameEn, descriptionTh, descriptionEn, icon, buffId;
  final int price;
}

class StoryBalance {
  const StoryBalance({
    required this.goldfishPerNode,
    required this.victoryBonus,
    required this.fullRewardRuns,
    required this.repeatRewardPct,
    required this.combatXp,
    required this.eventXp,
    required this.bossXp,
    required this.xpToNext,
    required this.campfireHealPct,
    required this.relicChoices,
    required this.shopSlots,
    required this.potions,
  });

  final int goldfishPerNode, victoryBonus, fullRewardRuns, repeatRewardPct;
  final int combatXp, eventXp, bossXp;
  final List<int> xpToNext;
  final int campfireHealPct, relicChoices, shopSlots;
  final List<StoryPotion> potions;
}

/// All data owned by the Story Challenge. JSON is the source of truth; the
/// later relic/talent systems consume these already-validated definitions.
class StoryContent {
  StoryContent({
    required Map<String, StoryRelic> relics,
    required Map<String, StoryTalent> talents,
    required Map<String, StoryMonster> monsters,
    required Map<String, StoryEvent> events,
    required this.balance,
  })  : relics = Map.unmodifiable(relics),
        talents = Map.unmodifiable(talents),
        monsters = Map.unmodifiable(monsters),
        events = Map.unmodifiable(events);

  final Map<String, StoryRelic> relics;
  final Map<String, StoryTalent> talents;
  final Map<String, StoryMonster> monsters;
  final Map<String, StoryEvent> events;
  final StoryBalance balance;

  factory StoryContent.fromJson({
    required Map<String, dynamic> relicsJson,
    required Map<String, dynamic> talentsJson,
    required Map<String, dynamic> monstersJson,
    required Map<String, dynamic> eventsJson,
    required Map<String, dynamic> balanceJson,
    required BuffBook buffs,
  }) {
    String text(Map<String, dynamic> m, String field, String owner) {
      final value = m[field];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('$owner: "$field" must be non-empty text');
      }
      return value;
    }

    int integer(Map<String, dynamic> m, String field, String owner,
        {int min = 0, int? max}) {
      final value = m[field];
      if (value is! int || value < min || (max != null && value > max)) {
        throw FormatException(
            '$owner: "$field" must be an integer from $min${max == null ? '' : ' to $max'}');
      }
      return value;
    }

    List<Map<String, dynamic>> objects(
        Map<String, dynamic> m, String field, String owner) {
      final value = m[field];
      if (value is! List || value.any((e) => e is! Map<String, dynamic>)) {
        throw FormatException('$owner: "$field" must be a list of objects');
      }
      return value.cast<Map<String, dynamic>>();
    }

    void unique(String kind, Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) throw FormatException('$kind $id: duplicate id');
      }
    }

    String buff(Map<String, dynamic> m, String field, String owner) {
      final id = text(m, field, owner);
      if (!buffs.defs.containsKey(id)) {
        throw FormatException('$owner: unknown buff "$id"');
      }
      return id;
    }

    StoryEffect effect(Map<String, dynamic> m, String owner) {
      final triggerName = text(m, 'trigger', owner);
      final trigger = const {
        'passive': EffectTrigger.passive,
        'on_attack': EffectTrigger.onAttack,
        'on_crit': EffectTrigger.onCrit,
        'on_dodge': EffectTrigger.onDodge,
        'on_skill': EffectTrigger.onSkill,
        'on_combat_end': EffectTrigger.onCombatEnd,
        'on_level_up': EffectTrigger.onLevelUp,
      }[triggerName];
      if (trigger == null) {
        throw FormatException('$owner: unknown trigger "$triggerName"');
      }
      final targetName = m['target'] ?? 'self';
      final targets =
          StoryEffectTarget.values.where((e) => e.name == targetName);
      if (targets.isEmpty) {
        throw FormatException('$owner: target must be self or enemy');
      }
      final chance = m['chance_pct'] ?? 100;
      if (chance is! int || chance < 1 || chance > 100) {
        throw FormatException('$owner: chance_pct must be 1..100');
      }
      return StoryEffect(
        trigger: trigger,
        buffId: buff(m, 'buff', owner),
        target: targets.single,
        chancePct: chance,
      );
    }

    final relicRows = objects(relicsJson, 'relics', 'relics.json');
    if (relicRows.length != 15) {
      throw const FormatException('relics.json: MVP needs exactly 15 relics');
    }
    unique('relic', relicRows.map((m) => text(m, 'id', 'relic')));
    final relics = <String, StoryRelic>{};
    for (final m in relicRows) {
      final id = text(m, 'id', 'relic');
      final owner = 'relic $id';
      final rarity = text(m, 'rarity', owner);
      if (!const {'common', 'rare', 'epic'}.contains(rarity)) {
        throw FormatException('$owner: unknown rarity "$rarity"');
      }
      relics[id] = StoryRelic(
        id: id,
        nameTh: text(m, 'name_th', owner),
        nameEn: text(m, 'name_en', owner),
        descriptionTh: text(m, 'description_th', owner),
        descriptionEn: text(m, 'description_en', owner),
        icon: text(m, 'icon', owner),
        rarity: rarity,
        effects: List.unmodifiable([
          for (final e in objects(m, 'effects', owner)) effect(e, owner),
        ]),
        synergies: List.unmodifiable([
          for (final s in objects(m, 'synergies', owner))
            StorySynergy(
              withRelic: text(s, 'with', '$owner synergy'),
              effect: effect(s, '$owner synergy'),
            ),
        ]),
      );
    }
    final pairs = <String>{};
    for (final relic in relics.values) {
      for (final synergy in relic.synergies) {
        if (synergy.withRelic == relic.id ||
            !relics.containsKey(synergy.withRelic)) {
          throw FormatException(
              'relic ${relic.id}: bad synergy ${synergy.withRelic}');
        }
        final pair = [relic.id, synergy.withRelic]..sort();
        if (!pairs.add(pair.join('+'))) {
          throw FormatException('relic synergy ${pair.join('+')}: duplicate');
        }
      }
    }
    if (pairs.length < 6) {
      throw const FormatException(
          'relics.json: MVP needs at least 6 synergies');
    }

    final treeRows = talentsJson['trees'];
    if (treeRows is! List ||
        treeRows.toSet().length != 3 ||
        !treeRows.toSet().containsAll({'claw', 'shadow', 'magic'})) {
      throw const FormatException(
          'talents.json: trees must be claw, shadow and magic');
    }
    final talentRows = objects(talentsJson, 'talents', 'talents.json');
    if (talentRows.length != 9) {
      throw const FormatException('talents.json: MVP needs exactly 9 talents');
    }
    unique('talent', talentRows.map((m) => text(m, 'id', 'talent')));
    final talents = <String, StoryTalent>{};
    for (final m in talentRows) {
      final id = text(m, 'id', 'talent');
      final owner = 'talent $id';
      final tree = text(m, 'tree', owner);
      if (!treeRows.contains(tree)) throw FormatException('$owner: bad tree');
      final crosses = <StoryTalentSynergy>[];
      for (final c in objects(m, 'cross_synergies', owner)) {
        final relic = text(c, 'relic', '$owner cross synergy');
        if (!relics.containsKey(relic)) {
          throw FormatException('$owner: unknown relic "$relic"');
        }
        crosses.add(StoryTalentSynergy(
          relicId: relic,
          effect: effect(c, '$owner cross synergy'),
        ));
      }
      talents[id] = StoryTalent(
        id: id,
        tree: tree,
        tier: integer(m, 'tier', owner, min: 1, max: 3),
        nameTh: text(m, 'name_th', owner),
        nameEn: text(m, 'name_en', owner),
        descriptionTh: text(m, 'description_th', owner),
        descriptionEn: text(m, 'description_en', owner),
        icon: text(m, 'icon', owner),
        effects: List.unmodifiable([
          for (final e in objects(m, 'effects', owner)) effect(e, owner),
        ]),
        requires: m['requires'] as String?,
        crossSynergies: List.unmodifiable(crosses),
      );
    }
    for (final talent in talents.values) {
      if (talent.requires case final required?) {
        final previous = talents[required];
        if (previous == null ||
            previous.tree != talent.tree ||
            previous.tier != talent.tier - 1) {
          throw FormatException(
              'talent ${talent.id}: invalid requirement "$required"');
        }
      } else if (talent.tier != 1) {
        throw FormatException('talent ${talent.id}: tier > 1 needs requires');
      }
    }
    for (final tree in treeRows.cast<String>()) {
      final tiers = talents.values
          .where((t) => t.tree == tree)
          .map((t) => t.tier)
          .toSet();
      if (tiers.length != 3 || !tiers.containsAll({1, 2, 3})) {
        throw FormatException('talents.json: $tree needs tiers 1, 2 and 3');
      }
    }

    final monsterRows = objects(monstersJson, 'monsters', 'monsters.json');
    if (monsterRows.length < 6) {
      throw const FormatException('monsters.json: needs 5 monsters and a boss');
    }
    unique('monster', monsterRows.map((m) => text(m, 'id', 'monster')));
    final monsters = <String, StoryMonster>{};
    for (final m in monsterRows) {
      final id = text(m, 'id', 'monster');
      final owner = 'monster $id';
      final stats = m['stat_weights'];
      if (stats is! Map<String, dynamic>) {
        throw FormatException('$owner: stat_weights must be an object');
      }
      final onHit = (m['on_hit_buffs'] as List? ?? const []).cast<String>();
      for (final id in onHit) {
        if (!buffs.defs.containsKey(id)) {
          throw FormatException('$owner: unknown buff "$id"');
        }
      }
      monsters[id] = StoryMonster(
        id: id,
        nameTh: text(m, 'name_th', owner),
        nameEn: text(m, 'name_en', owner),
        sprite: text(m, 'sprite', owner),
        role: text(m, 'role', owner),
        isBoss: m['is_boss'] == true,
        weight: integer(m, 'weight', owner, min: 0),
        powerPct: integer(m, 'power_pct', owner, min: 1),
        hpWeight: integer(stats, 'hp', '$owner stat_weights', min: 1),
        atkWeight: integer(stats, 'atk', '$owner stat_weights', min: 1),
        defWeight: integer(stats, 'def', '$owner stat_weights', min: 1),
        attackIntervalMs: integer(m, 'attack_interval_ms', owner, min: 200),
        onHitBuffs: List.unmodifiable(onHit),
      );
    }
    if (monsters.values.where((m) => m.isBoss).length != 1) {
      throw const FormatException('monsters.json: needs exactly one boss');
    }

    final eventRows = objects(eventsJson, 'events', 'events.json');
    if (eventRows.length != 8) {
      throw const FormatException('events.json: MVP needs exactly 8 events');
    }
    unique('event', eventRows.map((m) => text(m, 'id', 'event')));
    final events = <String, StoryEvent>{};
    for (final m in eventRows) {
      final id = text(m, 'id', 'event');
      final owner = 'event $id';
      final choices = objects(m, 'choices', owner);
      if (choices.length != 2) {
        throw FormatException('$owner: needs exactly two choices');
      }
      events[id] = StoryEvent(
        id: id,
        nameTh: text(m, 'name_th', owner),
        nameEn: text(m, 'name_en', owner),
        descriptionTh: text(m, 'description_th', owner),
        descriptionEn: text(m, 'description_en', owner),
        icon: text(m, 'icon', owner),
        choices: List.unmodifiable([
          for (final c in choices) _parseChoice(c, owner, text, buffs),
        ]),
      );
    }

    final rewards = balanceJson['rewards'];
    final xp = balanceJson['xp'];
    final campfire = balanceJson['campfire'];
    final treasure = balanceJson['treasure'];
    final shop = balanceJson['shop'];
    if (rewards is! Map<String, dynamic> ||
        xp is! Map<String, dynamic> ||
        campfire is! Map<String, dynamic> ||
        treasure is! Map<String, dynamic> ||
        shop is! Map<String, dynamic>) {
      throw const FormatException('story balance: missing rule section');
    }
    final curve = xp['to_next'];
    if (curve is! List ||
        curve.length != 3 ||
        curve.any((e) => e is! int || e <= 0)) {
      throw const FormatException('story balance: xp.to_next needs 3 values');
    }
    final potionRows = objects(shop, 'potions', 'story balance shop');
    if (potionRows.length != 4) {
      throw const FormatException('story balance: shop needs 4 potions');
    }
    final potions = <StoryPotion>[];
    for (final p in potionRows) {
      final id = text(p, 'id', 'potion');
      final owner = 'potion $id';
      potions.add(StoryPotion(
        id: id,
        nameTh: text(p, 'name_th', owner),
        nameEn: text(p, 'name_en', owner),
        descriptionTh: text(p, 'description_th', owner),
        descriptionEn: text(p, 'description_en', owner),
        icon: text(p, 'icon', owner),
        price: integer(p, 'price', owner, min: 1),
        buffId: buff(p, 'buff', owner),
      ));
    }
    unique('potion', potions.map((p) => p.id));
    final balance = StoryBalance(
      goldfishPerNode:
          integer(rewards, 'goldfish_per_node', 'story rewards', min: 0),
      victoryBonus: integer(rewards, 'victory_bonus', 'story rewards', min: 0),
      fullRewardRuns:
          integer(rewards, 'full_runs_per_day', 'story rewards', min: 1),
      repeatRewardPct: integer(rewards, 'repeat_reward_pct', 'story rewards',
          min: 0, max: 100),
      combatXp: integer(xp, 'combat', 'story xp', min: 0),
      eventXp: integer(xp, 'event', 'story xp', min: 0),
      bossXp: integer(xp, 'boss', 'story xp', min: 0),
      xpToNext: List.unmodifiable(curve.cast<int>()),
      campfireHealPct:
          integer(campfire, 'heal_pct', 'story campfire', min: 1, max: 100),
      relicChoices:
          integer(treasure, 'relic_choices', 'story treasure', min: 1),
      shopSlots: integer(shop, 'slots', 'story shop', min: 1),
      potions: List.unmodifiable(potions),
    );

    return StoryContent(
      relics: relics,
      talents: talents,
      monsters: monsters,
      events: events,
      balance: balance,
    );
  }

  static StoryEventChoice _parseChoice(
    Map<String, dynamic> c,
    String eventOwner,
    String Function(Map<String, dynamic>, String, String) text,
    BuffBook buffs,
  ) {
    final id = text(c, 'id', '$eventOwner choice');
    final owner = '$eventOwner choice $id';
    final raw = c['outcome'];
    if (raw is! Map<String, dynamic>) {
      throw FormatException('$owner: outcome must be an object');
    }
    int number(String key, {int min = 0, int max = 1000000}) {
      final value = raw[key] ?? 0;
      if (value is! int || value < min || value > max) {
        throw FormatException('$owner: outcome.$key is invalid');
      }
      return value;
    }

    final buffId = raw['buff'] as String?;
    if (buffId != null && !buffs.defs.containsKey(buffId)) {
      throw FormatException('$owner: unknown buff "$buffId"');
    }
    return StoryEventChoice(
      id: id,
      labelTh: text(c, 'label_th', owner),
      labelEn: text(c, 'label_en', owner),
      resultTh: text(c, 'result_th', owner),
      resultEn: text(c, 'result_en', owner),
      icon: text(c, 'icon', owner),
      outcome: StoryEventOutcome(
        goldfish: number('goldfish'),
        xp: number('xp'),
        healPct: number('heal_pct', max: 100),
        damagePct: number('damage_pct', max: 100),
        relicChoice: raw['relic_choice'] == true,
        buffId: buffId,
      ),
    );
  }
}
