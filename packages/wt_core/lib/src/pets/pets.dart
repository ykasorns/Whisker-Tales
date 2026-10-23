import 'dart:math' as math;

import '../core/clock/game_clock.dart';
import '../core/contracts/ads.dart';
import '../core/contracts/combat.dart';
import '../core/contracts/pets.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';
import '../combat/buffs.dart';
import '../core/random/seeded_rng.dart';

/// Ad placement for hatching (D-003).
const petHatchPlacement = 'pet_hatch';

/// What a pet gives Mochi while it is on the field (D-039): a bonus stat
/// (`attr` = a secondary stat key, or `atk`/`hp`/`def`/`all` for the main
/// stats), scaled by its stars.
class PetPassive {
  const PetPassive({
    required this.attr,
    required this.bp,
    required this.textTh,
    required this.textEn,
  });
  final String attr;
  final int bp;
  final String textTh, textEn;
}

/// A pet's active skill: casts itself on a cooldown while the pet is on the
/// field (names and text for the UI live in the data).
class PetSkill {
  const PetSkill({
    required this.spec,
    required this.icon,
    required this.nameTh,
    required this.nameEn,
    required this.textTh,
    required this.textEn,
  });
  final SkillSpec spec;
  final String icon, nameTh, nameEn, textTh, textEn;
  String get id => spec.id;
}

class PetDef {
  const PetDef(
      {required this.id,
      required this.rarity,
      required this.icon,
      required this.nameTh,
      required this.nameEn,
      this.passive,
      this.skill});
  final String id;
  final PetRarity rarity;
  final String icon, nameTh, nameEn;
  final PetPassive? passive;
  final PetSkill? skill;
}

const _mainStats = {'atk', 'hp', 'def', 'all'};

PetPassive? _passive(Map<String, dynamic> r) {
  final m = r['passive'];
  if (m == null) return null;
  final id = r['id'];
  FormatException bad(String w) => FormatException('pets.json: $id passive $w');
  if (m is! Map<String, dynamic>) throw bad('must be an object');
  final attr = m['attr'], pct = m['pct'];
  if (attr is! String ||
      !(_mainStats.contains(attr) || Attribute.fromKey(attr) != null)) {
    throw bad('attr must be a stat key or atk/hp/def/all');
  }
  if (pct is! num || pct <= 0) throw bad('pct must be > 0');
  return PetPassive(
    attr: attr,
    bp: (pct * kBp / 100).round(),
    textTh: m['text_th'] as String? ?? '',
    textEn: m['text_en'] as String? ?? '',
  );
}

PetSkill? _skill(Map<String, dynamic> r, BuffBook? buffs) {
  final m = r['skill'];
  if (m == null) return null;
  final pet = r['id'];
  FormatException bad(String w) => FormatException('pets.json: $pet skill $w');
  if (m is! Map<String, dynamic>) throw bad('must be an object');
  final id = m['id'], cd = m['cooldown_ms'];
  if (id is! String || cd is! int || cd <= 0) {
    throw bad('needs id and cooldown_ms > 0');
  }
  final target = SkillTarget.values.where((t) => t.name == m['target']);
  if (target.isEmpty) throw bad('target must be front, all or self');
  List<String> ids(String k) {
    final v = (m[k] as List? ?? const []).cast<String>();
    if (buffs != null) {
      for (final b in v) {
        if (!buffs.defs.containsKey(b)) throw bad('$id: unknown buff $b');
      }
    }
    return List.unmodifiable(v);
  }

  return PetSkill(
    spec: SkillSpec(
      id: id,
      cooldownMs: cd,
      target: target.first,
      damagePct: m['damage_pct'] as int? ?? 0,
      hits: m['hits'] as int? ?? 1,
      buffsTarget: ids('buffs_target'),
      buffsSelf: ids('buffs_self'),
      buffsAlly: ids('buffs_ally'),
    ),
    icon: m['icon'] as String? ?? '✨',
    nameTh: m['name_th'] as String? ?? id,
    nameEn: m['name_en'] as String? ?? id,
    textTh: m['text_th'] as String? ?? '',
    textEn: m['text_en'] as String? ?? '',
  );
}

/// `pets` (idle_balance_v1.json) + `design/data/pets.json` (GDD v0.4 §6).
class PetsRules {
  const PetsRules({
    required this.pets,
    required this.pullPct,
    required this.pityLegendEvery,
    required this.deploySlotsByChapter,
    required this.deployedBp,
    required this.ownedBp,
    required this.starBonusBp,
    required this.maxStars,
    required this.fishDailyMax,
    required this.fishCostBase,
    required this.fishCostGrowth,
    required this.fishChapterScalePct,
    required this.attackIntervalMs,
    required this.dupCookies,
    required this.pagesPerChapter,
  });

  final List<PetDef> pets;

  /// % per rarity, in [PetRarity] order.
  final List<int> pullPct;
  final int pityLegendEvery;
  final List<int> deploySlotsByChapter;

  /// Deployed pet ATK as share of the cat's ATK, per rarity (bp).
  final List<int> deployedBp;

  /// Passive HP/ATK bonus while owned, per rarity (bp).
  final List<int> ownedBp;

  /// Extra per star above 1 (bp).
  final int starBonusBp;
  final int maxStars;
  final int fishDailyMax;
  final int fishCostBase;
  final num fishCostGrowth;
  final int fishChapterScalePct;
  final int attackIntervalMs;
  final int dupCookies;
  final int pagesPerChapter;

  PetDef? byId(String id) {
    for (final p in pets) {
      if (p.id == id) return p;
    }
    return null;
  }

  int starMultBp(int stars) => kBp + starBonusBp * (stars - 1);

  /// The pet that owns skill [skillId], if any.
  PetDef? bySkill(String skillId) {
    for (final p in pets) {
      if (p.skill?.id == skillId) return p;
    }
    return null;
  }

  factory PetsRules.fromJson(
      Map<String, dynamic> balance, Map<String, dynamic> data,
      [BuffBook? buffs]) {
    final p = balance['pets'], e = balance['enemy'];
    if (p is! Map<String, dynamic> || e is! Map<String, dynamic>) {
      throw const FormatException('balance: needs pets and enemy');
    }
    num n(String k) {
      final v = p[k] ?? p['ASSUMPTION_$k'];
      if (v is! num) throw FormatException('pets: "$k" must be a number');
      return v;
    }

    List<num> l(String k) {
      final v = p[k] ?? p['ASSUMPTION_$k'];
      if (v is! List || v.length != 3 || v.any((x) => x is! num)) {
        throw FormatException(
            'pets: "$k" must be 3 numbers (common, rare, legend)');
      }
      return v.cast<num>();
    }

    final raw = data['pets'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('pets.json: "pets" must be a list');
    }
    final pets = [
      for (final r in raw.cast<Map<String, dynamic>>())
        PetDef(
          id: r['id'] as String? ??
              (throw const FormatException('pets.json: pet needs an id')),
          rarity: PetRarity.values.firstWhere((x) => x.name == r['rarity'],
              orElse: () => throw FormatException(
                  'pets.json: ${r['id']} has a bad rarity')),
          icon: r['icon'] as String? ?? '🐾',
          nameTh: r['name_th'] as String? ?? r['id'] as String,
          nameEn: r['name_en'] as String? ?? r['id'] as String,
          passive: _passive(r),
          skill: _skill(r, buffs),
        ),
    ];
    for (final rar in PetRarity.values) {
      if (!pets.any((x) => x.rarity == rar)) {
        throw FormatException('pets.json: needs at least one ${rar.name} pet');
      }
    }
    final pct = [for (final x in l('pull_pct')) x.toInt()];
    if (pct.fold(0, (a, b) => a + b) != 100) {
      throw const FormatException('pets: pull_pct must add to 100');
    }
    return PetsRules(
      pets: List.unmodifiable(pets),
      pullPct: List.unmodifiable(pct),
      pityLegendEvery: n('pity_legend_every').toInt(),
      deploySlotsByChapter: List.unmodifiable(
          [for (final x in l('deploy_slots_by_chapter')) x.toInt()]),
      deployedBp: List.unmodifiable(
          [for (final x in l('deployed_pct')) (x * kBp).round()]),
      ownedBp: List.unmodifiable(
          [for (final x in l('owned_pct')) (x * kBp).round()]),
      starBonusBp: (n('star_bonus_pct') * kBp).round(),
      maxStars: n('max_stars').toInt(),
      fishDailyMax: n('fish_pull_daily_max').toInt(),
      fishCostBase: n('fish_pull_cost_base').toInt(),
      fishCostGrowth: n('fish_pull_cost_growth'),
      fishChapterScalePct: n('fish_pull_chapter_scale_pct').toInt(),
      attackIntervalMs: data['attack_interval_ms'] as int? ?? 1500,
      dupCookies: data['dup_over_max_cookies'] as int? ?? 0,
      pagesPerChapter: (e['pages_per_chapter'] as num).toInt(),
    );
  }
}

/// Pets (GDD v0.4 §6): hatch from eggs, rewarded ads (3/day via AdService)
/// or goldfish (5/day, ×1.5 each); duplicates add stars; owned pets give a
/// small passive, deployed pets fight beside the cat (partner channel).
/// The legend guarantee counter never resets by day.
class Pets implements IPets {
  Pets({
    required this.rules,
    required this.wallet,
    required this.ads,
    required this.clock,
    required this.clearedPage,
    int seed = 0,
  })  : _rng = SeededRng(seed ^ 0x9E75),
        _dateKey = clock.dateKey;

  final PetsRules rules;
  final IWallet wallet;
  final IAdService Function() ads;
  final GameClock clock;
  final int Function() clearedPage;

  SeededRng _rng;
  final _owned = <String, int>{};
  final _deployed = <String>[];
  int _pity = 0;
  int _fishPulls = 0;
  String _dateKey;

  Map<String, int> get owned => Map.unmodifiable(_owned);
  List<String> get deployed => List.unmodifiable(_deployed);

  /// Hatches since the last legend; the next legend is guaranteed at
  /// [PetsRules.pityLegendEvery].
  int get pity => _pity;
  int get pityLeft => rules.pityLegendEvery - _pity;

  void _rollDay() {
    if (clock.dateKey.compareTo(_dateKey) > 0) {
      _dateKey = clock.dateKey;
      _fishPulls = 0;
    }
  }

  int get _chapterIdx => math.min(clearedPage() ~/ rules.pagesPerChapter, 2);

  @override
  int get nextFishCost {
    _rollDay();
    return (rules.fishCostBase *
            math.pow(rules.fishCostGrowth, _fishPulls) *
            (100 + rules.fishChapterScalePct * _chapterIdx) /
            100)
        .round();
  }

  @override
  int get fishHatchesLeftToday {
    _rollDay();
    return math.max(0, rules.fishDailyMax - _fishPulls);
  }

  int get fishPullsToday {
    _rollDay();
    return _fishPulls;
  }

  @override
  Map<PetRarity, double> get rates =>
      {for (final r in PetRarity.values) r: rules.pullPct[r.index].toDouble()};

  /// Deploy slots open now (by chapters cleared).
  int get deploySlots {
    final i = math.min(clearedPage() ~/ rules.pagesPerChapter,
        rules.deploySlotsByChapter.length - 1);
    return rules.deploySlotsByChapter[i];
  }

  bool canHatch(HatchSource s) => switch (s) {
        HatchSource.egg => wallet.balance(Currency.eggs) > 0,
        HatchSource.ad => ads().canShow(petHatchPlacement),
        HatchSource.fish => fishHatchesLeftToday > 0 &&
            wallet.balance(Currency.goldfish) >= nextFishCost,
      };

  @override
  Future<HatchResult?> hatch(HatchSource source) async {
    switch (source) {
      case HatchSource.egg:
        if (!wallet.spend(Currency.eggs, 1)) return null;
      case HatchSource.ad:
        final ad = ads();
        if (!ad.canShow(petHatchPlacement)) return null;
        if (await ad.show(petHatchPlacement) != AdOutcome.rewarded) return null;
      case HatchSource.fish:
        if (fishHatchesLeftToday == 0) return null;
        if (!wallet.spend(Currency.goldfish, nextFishCost)) return null;
        _fishPulls++;
    }
    return _roll();
  }

  HatchResult _roll() {
    _pity++;
    var roll = _rng.nextUint32() % 100;
    var rarity = PetRarity.legend;
    for (final r in PetRarity.values) {
      if (roll < rules.pullPct[r.index]) {
        rarity = r;
        break;
      }
      roll -= rules.pullPct[r.index];
    }
    final pity = _pity >= rules.pityLegendEvery && rarity != PetRarity.legend;
    if (pity) rarity = PetRarity.legend;
    if (rarity == PetRarity.legend) _pity = 0;
    final pool = rules.pets.where((p) => p.rarity == rarity).toList();
    final pet = pool[_rng.nextUint32() % pool.length];
    final had = _owned[pet.id];
    var cookies = 0;
    if (had == null) {
      _owned[pet.id] = 1;
      // first pets fill empty deploy slots on their own
      if (_deployed.length < deploySlots) _deployed.add(pet.id);
    } else if (had < rules.maxStars) {
      _owned[pet.id] = had + 1;
    } else {
      cookies = rules.dupCookies;
      wallet.add(RewardBundle({Currency.cookies: cookies}));
    }
    return HatchResult(
      petId: pet.id,
      rarity: rarity,
      isNew: had == null,
      stars: _owned[pet.id]!,
      cookies: cookies,
      wasPity: pity,
    );
  }

  /// Puts an owned pet in [slot] (0-based, < [deploySlots]); a pet already
  /// deployed elsewhere moves.
  @override
  void deploy(int slot, String petId) {
    if (!_owned.containsKey(petId)) throw StateError('pet $petId is not owned');
    if (slot < 0 || slot >= deploySlots) {
      throw RangeError.range(slot, 0, deploySlots - 1, 'slot');
    }
    _deployed.remove(petId);
    if (slot < _deployed.length) {
      _deployed[slot] = petId;
    } else {
      _deployed.add(petId);
    }
  }

  void undeploy(String petId) => _deployed.remove(petId);

  /// Passive HP/ATK bonus from every owned pet (bp).
  int get passiveBp {
    var bp = 0;
    for (final e in _owned.entries) {
      final def = rules.byId(e.key);
      if (def == null) continue;
      bp += rules.ownedBp[def.rarity.index] * rules.starMultBp(e.value) ~/ kBp;
    }
    return bp;
  }

  /// The pets on the field right now, in slot order.
  List<PetDef> get fieldPets => [
        for (final id in _deployed.take(deploySlots))
          if (rules.byId(id) case final def?) def,
      ];

  /// The deployed pet's own bonus, scaled by its stars (bp).
  int passiveBpOf(PetDef def) {
    final p = def.passive;
    return p == null ? 0 : p.bp * rules.starMultBp(_owned[def.id] ?? 1) ~/ kBp;
  }

  /// The cat with the owned-pet passive and the deployed pets' bonuses
  /// applied (D-039: the owned collection bonus stays; deploying adds more).
  CombatUnitSpec withPassive(CombatUnitSpec cat) {
    final bp = passiveBp;
    var out = bp == 0
        ? cat
        : cat.copyWith(stats: cat.stats.scaledBp(hp: kBp + bp, atk: kBp + bp));
    var hp = 0, atk = 0, def = 0;
    final extra = <Attribute, int>{};
    for (final pet in fieldPets) {
      final p = pet.passive;
      if (p == null) continue;
      final b = passiveBpOf(pet);
      switch (p.attr) {
        case 'hp':
          hp += b;
        case 'atk':
          atk += b;
        case 'def':
          def += b;
        case 'all':
          hp += b;
          atk += b;
          def += b;
        default:
          final a = Attribute.fromKey(p.attr);
          if (a != null) extra[a] = (extra[a] ?? 0) + b;
      }
    }
    if (hp == 0 && atk == 0 && def == 0 && extra.isEmpty) return out;
    var stats =
        out.stats.scaledBp(hp: kBp + hp, atk: kBp + atk, def: kBp + def);
    if (extra.isNotEmpty) {
      stats = stats.copyWith(attrs: {
        ...stats.attrs,
        for (final e in extra.entries) e.key: stats[e.key] + e.value,
      });
    }
    return out.copyWith(stats: stats);
  }

  /// The ATK pet [def] fights with beside [cat] (rarity share × stars).
  int attackOf(CombatUnitSpec cat, PetDef def) => math.max(
      1,
      cat.stats.atk *
          rules.deployedBp[def.rarity.index] ~/
          kBp *
          rules.starMultBp(_owned[def.id] ?? 1) ~/
          kBp);

  /// Deployed pets as partner units for a fight beside [cat].
  List<CombatUnitSpec> partners(CombatUnitSpec cat) => [
        for (final id in _deployed.take(deploySlots))
          if (rules.byId(id) case final def?)
            CombatUnitSpec(
              id: 'pet_$id',
              side: CombatSide.cat,
              isPartner: true,
              skills: [if (def.skill case final k?) k.spec],
              attackIntervalMs: rules.attackIntervalMs,
              range: AttackRange.ranged,
              stats: StatBlock(
                hp: 1,
                atk: attackOf(cat, def),
                def: 0,
                attrs: {
                  if (cat.stats[Attribute.petDmg] != 0)
                    Attribute.petDmg: cat.stats[Attribute.petDmg],
                },
              ),
            ),
      ];

  PetsState snapshot() => PetsState(
      owned: Map.unmodifiable(_owned),
      deployed: List.unmodifiable(_deployed),
      pity: _pity);

  /// Loads pets + today's fish hatches (`daily.fish_pulls` of [dateKey]).
  void restore(PetsState s, {int fishPulls = 0, String? dateKey}) {
    for (final e in s.owned.entries) {
      if (rules.byId(e.key) == null) {
        throw FormatException('pets: unknown pet ${e.key}');
      }
      if (e.value < 1 || e.value > rules.maxStars) {
        throw FormatException('pets: ${e.key} stars ${e.value}');
      }
    }
    for (final d in s.deployed) {
      if (!s.owned.containsKey(d)) {
        throw FormatException('pets: deployed $d is not owned');
      }
    }
    if (s.pity < 0) throw const FormatException('pets: pity < 0');
    _owned
      ..clear()
      ..addAll(s.owned);
    _deployed
      ..clear()
      ..addAll(s.deployed);
    _pity = s.pity;
    _fishPulls = fishPulls;
    _dateKey = dateKey ?? _dateKey;
    _rollDay();
  }

  /// RNG continues after a reload.
  int get rngState => _rng.state;
  set rngState(int v) => _rng = SeededRng.fromState(v);
}
