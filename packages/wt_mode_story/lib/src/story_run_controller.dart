import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:wt_core/wt_core.dart';

import 'story_mode.dart';

enum StoryRunPanel {
  map,
  combat,
  relicPick,
  talentPick,
  event,
  shop,
  campfire,
  result,
}

/// One landed hit of the running fight, for floating numbers in the scene.
class StoryHit {
  const StoryHit({
    required this.serial,
    required this.onCat,
    required this.damage,
    required this.outcome,
  });

  /// Grows with every hit, so the UI shows each one once.
  final int serial;

  /// The hit landed on Mochi (not on the enemy).
  final bool onCat;
  final int damage;
  final HitOutcome outcome;
}

/// One complete Story Challenge run. UI only chooses routes/cards/actions;
/// combat, rewards and every effect stay in the shared deterministic engine.
class StoryRunController extends ChangeNotifier {
  StoryRunController({
    required this.mode,
    required StorySave save,
    required this.manager,
    required this.cat,
    required this.classId,
    required this.powerScore,
    required this.engineFactory,
    required this.wallet,
    required this.buffBook,
    required this.dayKey,
    required this.onSave,
  }) : _save = save;

  final StoryMode mode;
  final RunManager manager;
  final CombatUnitSpec cat;
  final String classId;
  final PowerScore powerScore;
  final ICombatEngine Function() engineFactory;
  final IWallet wallet;
  final BuffBook buffBook;
  final String dayKey;
  final void Function(StorySave save) onSave;

  late ItemSystem items;
  late TalentSystem talents;
  late SeededRng _effectRng;
  StorySave _save;
  StoryRunPanel panel = StoryRunPanel.map;
  ICombatEngine? _combat;
  StreamSubscription<CombatEvent>? _combatSub;
  StreamSubscription<SynergyActivated>? _synergySub;
  Encounter? encounter;
  StoryEvent? event;
  RunCompletion? completion;
  List<String> relicOptions = const [];
  String? lastSynergy;
  int currentHp = 1;
  final List<String> _runBuffs = [];
  final Set<String> _purchasedPotionIds = {};
  bool _pickCompletesEncounter = false;

  /// The last few hits of the fight, oldest first (cleared at each fight).
  final List<StoryHit> hits = [];
  int _hitSerial = 0;

  /// What the story says now: a key of [StoryNarrative] and a serial that
  /// grows each time a new line should be told (D-061).
  String? captionKey;
  int captionSerial = 0;
  bool _combatClosing = false;

  StorySave get save => _save;

  /// The lines to tell for [captionKey]: the opening and the endings in full,
  /// other moments one line picked by how far Mochi has come.
  List<String> captionLines(String lang) {
    final key = captionKey;
    if (key == null) return const [];
    if (key == _resultKey) {
      final text = lang == 'en' ? _resultEn : _resultTh;
      return text == null ? const [] : [text];
    }
    final all = mode.content.narrative.lines(key, lang);
    if (all.isEmpty) return const [];
    if (const {'intro', 'win', 'lose'}.contains(key)) return all;
    return [all[(manager.current?.clearedNodes ?? 0) % all.length]];
  }

  static const _resultKey = '@event_result';
  String? _resultTh, _resultEn;

  void _say(String? key) {
    captionKey = key;
    captionSerial++;
  }

  /// Tells what an event choice led to, in the event's own words.
  void _sayResult(StoryEventChoice choice) {
    _resultTh = choice.resultTh;
    _resultEn = choice.resultEn;
    _say(_resultKey);
  }

  List<UnitView> get combatView => _combat?.view ?? const [];
  UnitView? get liveCat {
    for (final unit in combatView) {
      if (unit.id == cat.id) return unit;
    }
    return null;
  }

  int get maxHp => cat.stats.hp;
  int get displayedHp =>
      panel == StoryRunPanel.combat ? (liveCat?.hp ?? currentHp) : currentHp;
  int get displayedMaxHp =>
      panel == StoryRunPanel.combat ? (liveCat?.maxHp ?? maxHp) : maxHp;
  int get displayedShield =>
      panel == StoryRunPanel.combat ? (liveCat?.shield ?? 0) : 0;
  Set<String> get purchasedPotionIds => Set.unmodifiable(_purchasedPotionIds);
  bool get active => completion == null;
  Set<String> get relicIds => items.relicIds;
  List<String> get talentIds => talents.selectedIds;
  int get talentLevel => talents.level;
  int get talentXp => talents.xp;
  int get talentXpToNext => talents.level < mode.content.balance.xpToNext.length
      ? mode.content.balance.xpToNext[talents.level]
      : 0;

  List<EncounterPreview> get preview => active ? manager.preview(3) : const [];
  List<Encounter> get routeChoices => active ? manager.nextChoices : const [];

  void start() {
    final config = mode.createRunConfig(_save);
    final snapshot = RunCatSnapshot(
      id: cat.id,
      classId: classId,
      stats: cat.stats,
      power: powerScore.of(cat.stats),
    );
    manager.startRun(
        mode: mode, modeState: _save, cat: snapshot, dayKey: dayKey);
    items = ItemSystem(mode.content.relics);
    talents = TalentSystem(
      talents: mode.content.talents,
      xpToNext: mode.content.balance.xpToNext,
      seed: config.seed ^ 0x7A1E17,
      relicIds: () => items.relicIds,
    );
    _effectRng = SeededRng(config.seed ^ 0xEFFECC7);
    _synergySub?.cancel();
    _synergySub = items.synergies.activations.listen((pair) {
      lastSynergy = '${pair.relicA}+${pair.relicB}';
      notifyListeners();
    });
    completion = null;
    encounter = null;
    event = null;
    relicOptions = const [];
    currentHp = cat.stats.hp;
    _runBuffs.clear();
    _purchasedPotionIds.clear();
    panel = StoryRunPanel.map;
    hits.clear();
    _say('intro');
    notifyListeners();
  }

  void advance({String? routeId}) {
    if (!active || panel != StoryRunPanel.map) return;
    final next = manager.advanceToNextNode(routeId: routeId);
    if (next == null) return;
    encounter = next;
    _say(switch (next.type) {
      EncounterType.combat => 'arrive_combat',
      EncounterType.boss => 'arrive_boss',
      EncounterType.treasure => 'arrive_treasure',
      EncounterType.event => 'arrive_event',
      EncounterType.shop => 'arrive_shop',
      EncounterType.campfire => 'arrive_campfire',
      EncounterType.fork => null,
    });
    switch (next.type) {
      case EncounterType.combat || EncounterType.boss:
        _startCombat(next);
      case EncounterType.treasure:
        _openRelicPick(completesEncounter: true);
      case EncounterType.event:
        event = mode.content.events[next.contentId];
        panel = StoryRunPanel.event;
      case EncounterType.shop:
        _purchasedPotionIds.clear();
        panel = StoryRunPanel.shop;
      case EncounterType.campfire:
        panel = StoryRunPanel.campfire;
      case EncounterType.fork:
        _completeEncounter(true);
    }
    notifyListeners();
  }

  void tick(int milliseconds) {
    if (panel != StoryRunPanel.combat || milliseconds <= 0) return;
    _combat?.tick(milliseconds);
    notifyListeners();
  }

  void chooseRelic(String id) {
    if (panel != StoryRunPanel.relicPick || !relicOptions.contains(id)) return;
    items.addRelic(id);
    final completes = _pickCompletesEncounter;
    relicOptions = const [];
    _pickCompletesEncounter = false;
    if (completes) {
      _completeEncounter(true);
    } else {
      _afterEncounter();
    }
  }

  void chooseTalent(String id) {
    if (panel != StoryRunPanel.talentPick) return;
    talents.chooseTalent(id);
    if (talents.pendingPicks > 0) {
      panel = StoryRunPanel.talentPick;
    } else {
      panel = StoryRunPanel.map;
    }
    notifyListeners();
  }

  void chooseEvent(StoryEventChoice choice) {
    if (panel != StoryRunPanel.event || event == null) return;
    final outcome = choice.outcome;
    _changeHp(outcome.healPct - outcome.damagePct);
    if (outcome.goldfish > 0) {
      wallet.add(RewardBundle({Currency.goldfish: outcome.goldfish}));
    }
    if (outcome.xp > 0) talents.gainXp(outcome.xp);
    if (outcome.buffId case final buff?) _runBuffs.add(buff);
    event = null;
    _sayResult(choice);
    if (outcome.relicChoice) {
      _openRelicPick(completesEncounter: true);
      notifyListeners();
      return;
    }
    _completeEncounter(currentHp > 0);
  }

  bool buyPotion(StoryPotion potion) {
    if (panel != StoryRunPanel.shop ||
        !potionWouldHaveEffect(potion) ||
        !wallet.spend(Currency.goldfish, potion.price)) {
      return false;
    }
    final def = buffBook[potion.buffId];
    if (def.action == BuffAction.heal) {
      _changeHp(def.pctBp ~/ 100);
    } else {
      _runBuffs.add(potion.buffId);
    }
    _purchasedPotionIds.add(potion.id);
    notifyListeners();
    return true;
  }

  /// A shop slot is sold once. Healing cannot consume goldfish at full HP,
  /// and a run-long non-stacking potion cannot be bought while already active.
  bool potionWouldHaveEffect(StoryPotion potion) {
    if (_purchasedPotionIds.contains(potion.id)) return false;
    final def = buffBook[potion.buffId];
    if (def.action == BuffAction.heal) return currentHp < maxHp;
    return !_runBuffs.contains(potion.buffId);
  }

  void leaveShop() {
    if (panel == StoryRunPanel.shop) _completeEncounter(true);
  }

  void restAtCampfire() {
    if (panel != StoryRunPanel.campfire) return;
    _changeHp(mode.content.balance.campfireHealPct);
    _completeEncounter(true);
  }

  void upgradeAtCampfire(String relicId) {
    if (panel != StoryRunPanel.campfire || !items.relicIds.contains(relicId)) {
      return;
    }
    items.upgradeRelic(relicId);
    _completeEncounter(true);
  }

  void leaveCampfireWithoutUpgrade() {
    if (panel == StoryRunPanel.campfire) _completeEncounter(true);
  }

  void abandon() {
    if (!active) return;
    _finish(manager.endRun(RunOutcome.abandoned));
  }

  void _startCombat(Encounter node) {
    final monster = mode.content.monsters[node.contentId]!;
    final engine = engineFactory();
    if (engine is! IBuffEngine) {
      throw StateError('Story combat engine must implement IBuffEngine');
    }
    final buffEngine = engine as IBuffEngine;
    _combatSub?.cancel();
    _combat = engine;
    _combatClosing = false;
    hits.clear();
    _combatSub = engine.events.listen(_onCombatEvent);
    final enemy = _monsterSpec(monster, manager.current!.cat.power);
    engine.start(CombatSetup(
      seed: mixSeed([manager.current!.config.seed, node.depth, 0xC08A7]),
      units: [cat.copyWith(initialHp: currentHp), enemy],
      timeLimitMs: monster.isBoss ? 60000 : 30000,
    ));
    final context = RunEffectContext(
      ownerUnitId: cat.id,
      enemyUnitId: enemy.id,
      buffEngine: buffEngine,
      rng: _effectRng,
    );
    for (final buff in _runBuffs) {
      buffEngine.apply(cat.id, buff, sourceId: cat.id);
    }
    items.resolve(EffectTrigger.passive, context);
    talents.resolve(EffectTrigger.passive, context);
    panel = StoryRunPanel.combat;
  }

  CombatUnitSpec _monsterSpec(StoryMonster monster, int catPower) {
    final targetPower =
        (catPower * monster.powerPct ~/ 100).clamp(1, 1 << 30).toInt();
    final weights = powerScore.weights;
    final divisor = monster.hpWeight * weights.hpPm +
        monster.atkWeight * weights.atkPm +
        monster.defWeight * weights.defPm;
    final scale =
        (targetPower * 1000 / divisor).ceil().clamp(1, 1 << 24).toInt();
    return CombatUnitSpec(
      id: monster.id,
      side: CombatSide.enemy,
      stats: StatBlock(
        hp: monster.hpWeight * scale,
        atk: monster.atkWeight * scale,
        def: monster.defWeight * scale,
      ),
      attackIntervalMs: monster.attackIntervalMs,
      isBoss: monster.isBoss,
    );
  }

  void _onCombatEvent(CombatEvent combatEvent) {
    final engine = _combat;
    final node = encounter;
    if (engine == null || engine is! IBuffEngine || node == null) return;
    final buffEngine = engine as IBuffEngine;
    final enemyId = node.contentId;
    final context = RunEffectContext(
      ownerUnitId: cat.id,
      enemyUnitId: enemyId,
      buffEngine: buffEngine,
      rng: _effectRng,
    );
    switch (combatEvent) {
      case HitResolved(
          :final attackerId,
          :final targetId,
          :final outcome,
          :final damage,
          :final source
        ):
        hits.add(StoryHit(
            serial: ++_hitSerial,
            onCat: targetId == cat.id,
            damage: damage,
            outcome: outcome));
        if (hits.length > 8) hits.removeAt(0);
        if (attackerId == cat.id && source == AttackSource.normal) {
          items.resolve(EffectTrigger.onAttack, context);
          talents.resolve(EffectTrigger.onAttack, context);
        }
        if (attackerId == cat.id && outcome == HitOutcome.crit) {
          items.resolve(EffectTrigger.onCrit, context);
          talents.resolve(EffectTrigger.onCrit, context);
        }
        if (attackerId != cat.id && outcome == HitOutcome.dodge) {
          items.resolve(EffectTrigger.onDodge, context);
          talents.resolve(EffectTrigger.onDodge, context);
        }
        final monsterId = node.contentId;
        if (attackerId != cat.id &&
            source == AttackSource.normal &&
            monsterId != null) {
          for (final buff in mode.content.monsters[monsterId]!.onHitBuffs) {
            buffEngine.apply(cat.id, buff, sourceId: attackerId);
          }
        }
      case SkillCast(:final unitId) when unitId == cat.id:
        items.resolve(EffectTrigger.onSkill, context);
        talents.resolve(EffectTrigger.onSkill, context);
      case UnitDefeated(:final unitId) when unitId != cat.id:
        final enemiesAlive = engine.view
            .any((unit) => unit.side == CombatSide.enemy && unit.alive);
        if (!enemiesAlive) {
          items.resolve(EffectTrigger.onCombatEnd, context);
          talents.resolve(EffectTrigger.onCombatEnd, context);
        }
      case CombatEnded(:final playerWon):
        if (_combatClosing) return;
        _combatClosing = true;
        final catView = engine.view.where((unit) => unit.id == cat.id);
        currentHp = catView.isEmpty ? 0 : catView.single.hp;
        if (playerWon) {
          talents.gainXp(node.type == EncounterType.boss
              ? mode.content.balance.bossXp
              : mode.content.balance.combatXp);
        }
        _completeEncounter(playerWon);
      default:
    }
  }

  void _openRelicPick({required bool completesEncounter}) {
    final pool = mode.content.relics.keys
        .where((id) => !items.relicIds.contains(id))
        .toList();
    final picked = <String>[];
    while (
        pool.isNotEmpty && picked.length < mode.content.balance.relicChoices) {
      picked.add(pool.removeAt(_effectRng.nextBp() % pool.length));
    }
    if (picked.isEmpty) {
      if (completesEncounter) _completeEncounter(true);
      return;
    }
    relicOptions = List.unmodifiable(picked);
    _pickCompletesEncounter = completesEncounter;
    panel = StoryRunPanel.relicPick;
  }

  void _completeEncounter(bool survived) {
    final done = manager.resolveEncounter(survived: survived);
    if (done != null) {
      _finish(done);
      return;
    }
    _afterEncounter();
  }

  void _afterEncounter() {
    if (talents.pendingPicks > 0) {
      panel = StoryRunPanel.talentPick;
    } else {
      panel = StoryRunPanel.map;
    }
    encounter = null;
    notifyListeners();
  }

  void _finish(RunCompletion done) {
    completion = done;
    _save = done.modeState as StorySave;
    onSave(_save);
    wallet.add(done.reward.reward);
    _say(switch (done.result.outcome) {
      RunOutcome.won => 'win',
      RunOutcome.died => 'lose',
      RunOutcome.abandoned => null,
    });
    panel = StoryRunPanel.result;
    notifyListeners();
  }

  void _changeHp(int percent) {
    currentHp = (currentHp + maxHp * percent ~/ 100).clamp(0, maxHp).toInt();
  }

  @override
  void dispose() {
    _combatSub?.cancel();
    _synergySub?.cancel();
    talents.dispose();
    items.synergies.dispose();
    super.dispose();
  }
}
