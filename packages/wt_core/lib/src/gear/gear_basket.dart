import '../core/contracts/combat.dart';
import '../core/contracts/gear_basket.dart';
import '../core/contracts/rewards.dart';
import '../core/contracts/wallet.dart';
import '../core/random/seeded_rng.dart';
import 'gear_rules.dart';

/// Yarn basket, "knit it yourself" (GDD v0.4 §3, v0.5 §4): pick a slot →
/// grade from the basket table (+ pity) → power + affixes → compare → wear
/// or recycle. Slots level up, not items.
class GearBasket implements IGearBasket {
  GearBasket({
    required this.rules,
    required this.wallet,
    required this.clearedPage,
    required this.powerOf,
    int seed = 0,
    bool Function(String styleId)? unlockStyle,
  })  : _rng = SeededRng(seed),
        _unlockStyle = unlockStyle;

  final GearRules rules;
  final IWallet wallet;

  /// Pages cleared (opens slots, sets item power).
  final int Function() clearedPage;

  /// PowerScore of a stat block (§15.2), injected from `combat`.
  final int Function(StatBlock) powerOf;

  /// Wardrobe hook: returns true if [styleId] is new. Defaults to an
  /// in-memory set until `wardrobe` (T-045) is wired.
  final bool Function(String styleId)? _unlockStyle;
  final _seenStyles = <String>{};

  SeededRng _rng;
  int _nextId = 1;
  int _level = 1;
  int _expMilli = 0;
  int _pity = 0;
  final _equipped = <GearSlot, GearItem>{};
  final _stash = <GearSlot, GearItem>{};
  final _pending = <String, GearItem>{};
  final _slotLevel = <GearSlot, int>{};

  int get basketLevel => _level;

  /// Basket EXP into the current level.
  int get basketExp => _expMilli ~/ 1000;
  int get basketExpToNext => rules.rowFor(_level).expToNext;

  /// Crafts since the last grade ≥ pity grade.
  int get pity => _pity;

  /// Crafts left until a guaranteed pity-grade item.
  int get pityLeft => rules.pityEvery - _pity;

  GearItem? equipped(GearSlot s) => _equipped[s];
  GearItem? stashed(GearSlot s) => _stash[s];
  int slotLevel(GearSlot s) => _slotLevel[s] ?? 0;
  int upgradeCost(GearSlot s) => rules.upgradeCost(slotLevel(s));

  bool isOpen(GearSlot s) => clearedPage() >= rules.slots[s]!.unlockPage;
  List<GearSlot> get openSlots => [
        for (final s in GearSlot.values)
          if (isOpen(s)) s,
      ];

  @override
  List<double> get gradeTable =>
      [for (final p in rules.rowFor(_level).pct) p.toDouble()];

  /// Power of [item] as worn in its slot (slot level included).
  int powerOfItem(GearItem? item) =>
      item == null ? 0 : powerOf(_withSlotLevel(item));

  /// Power of the best item kept for [s], worn or stashed.
  int bestPower(GearSlot s) {
    final worn = powerOfItem(_equipped[s]), kept = powerOfItem(_stash[s]);
    return worn > kept ? worn : kept;
  }

  /// Worth keeping: more power than both the worn and the stashed item, or
  /// ✨ strictly better than the one it would replace (GDD v0.5 §4.3).
  bool isKeeper(GearItem item) =>
      powerOfItem(item) > bestPower(item.slot) ||
      item.isStrictlyBetterThan(_stash[item.slot] ?? _equipped[item.slot]);

  /// Knitted, waiting for the player to wear or recycle it.
  bool isPending(String itemId) => _pending.containsKey(itemId);

  /// Puts away a knitted item the player left without choosing (sheet
  /// closed, app restarted): into the stash (✨ on the slot) when it is a
  /// keeper, recycled for goldfish otherwise. Returns true when kept.
  bool settle(String itemId) {
    final item = _pending[itemId];
    if (item == null) throw StateError('item $itemId is not pending');
    if (isKeeper(item)) {
      stash(itemId);
      return true;
    }
    recycle(itemId);
    return false;
  }

  /// Sum of everything worn, slot levels applied — the `extra` the cat class
  /// multiplies (T-044 `combatSpec`).
  StatBlock get totalStats {
    var hp = 0, atk = 0, def = 0;
    final attrs = <Attribute, int>{};
    for (final item in _equipped.values) {
      final s = _withSlotLevel(item);
      hp += s.hp;
      atk += s.atk;
      def += s.def;
      for (final e in s.attrs.entries) {
        attrs[e.key] = (attrs[e.key] ?? 0) + e.value;
      }
    }
    return StatBlock(hp: hp, atk: atk, def: def, attrs: attrs);
  }

  StatBlock _withSlotLevel(GearItem item) {
    final bp = kBp + rules.slotUpgradeBp * slotLevel(item.slot);
    final s = item.stats;
    return s.copyWith(
        hp: s.hp * bp ~/ kBp, atk: s.atk * bp ~/ kBp, def: s.def * bp ~/ kBp);
  }

  @override
  CraftResult craft(GearSlot? slot) {
    final open = openSlots;
    final random = slot == null;
    final target = slot ?? open[_rng.nextUint32() % open.length];
    if (!open.contains(target)) {
      throw StateError('slot ${target.name} is locked');
    }
    if (!wallet.spend(Currency.yarn, 1)) throw StateError('no yarn');

    final grade = _rollGrade();
    final page = clearedPage() + 1;
    final item = GearItem(
      id: 'g${_nextId++}',
      slot: target,
      grade: grade,
      page: page,
      stats: rules.rollStats(_rng, target, grade, page),
      randomSlotBonus: random,
    );
    _pending[item.id] = item;
    final styleId = item.styleId;
    final isNew = _unlockStyle?.call(styleId) ?? _seenStyles.add(styleId);
    return CraftResult(
      item: item,
      isStrictlyBetter: item.isStrictlyBetterThan(_equipped[target]),
      isNewStyle: isNew,
    );
  }

  GearGrade _rollGrade() {
    _pity++;
    final pct = rules.rowFor(_level).pct;
    var roll = _rng.nextUint32() % 100;
    var grade = pct.length - 1;
    for (var i = 0; i < pct.length; i++) {
      if (roll < pct[i]) {
        grade = i;
        break;
      }
      roll -= pct[i];
    }
    if (_pity >= rules.pityEvery && grade < rules.pityMinGrade) {
      grade = rules.pityMinGrade;
    }
    if (grade >= rules.pityMinGrade) _pity = 0;
    return grade;
  }

  GearItem _take(String itemId) {
    final item = _pending.remove(itemId);
    if (item != null) return item;
    for (final e in _stash.entries) {
      if (e.value.id == itemId) return _stash.remove(e.key)!;
    }
    throw StateError('item $itemId is not pending or stashed');
  }

  @override
  void equip(String itemId) {
    final item = _take(itemId);
    final old = _equipped[item.slot];
    _equipped[item.slot] = item;
    if (old != null) _recycleItem(old);
  }

  @override
  void recycle(String itemId) => _recycleItem(_take(itemId));

  /// Keeps a pending item in the slot's stash (one per slot); an item
  /// already there is recycled.
  void stash(String itemId) {
    final item = _take(itemId);
    final old = _stash[item.slot];
    _stash[item.slot] = item;
    if (old != null) _recycleItem(old);
  }

  void _recycleItem(GearItem item) {
    wallet.add(RewardBundle({Currency.goldfish: rules.recycleFish(item.page)}));
    var exp = rules.recycleBasketExp * 1000;
    if (item.randomSlotBonus) {
      exp = exp * (100 + rules.randomSlotBonusPct) ~/ 100;
    }
    _expMilli += exp;
    while (_level < rules.basketMaxLevel &&
        basketExpToNext > 0 &&
        _expMilli >= basketExpToNext * 1000) {
      _expMilli -= basketExpToNext * 1000;
      _level++;
    }
    if (_level >= rules.basketMaxLevel) _expMilli = 0;
  }

  @override
  void upgradeSlot(GearSlot slot) {
    if (!isOpen(slot)) throw StateError('slot ${slot.name} is locked');
    if (!wallet.spend(Currency.goldfish, upgradeCost(slot))) {
      throw StateError('not enough goldfish');
    }
    _slotLevel[slot] = slotLevel(slot) + 1;
  }

  /// Save v3 `gear` (+ `basket.rng` / `basket.next_id` so the sequence
  /// continues). Pending items are saved too and [settle]d on load, so an
  /// app closed on the compare card never loses the yarn spent.
  Map<String, dynamic> toJson() => {
        'slots': [
          for (final s in GearSlot.values)
            {
              'slot': s.name,
              'item': _equipped[s]?.toJson(),
              'level': slotLevel(s)
            },
        ],
        'unlocked_slots': [for (final s in openSlots) s.name],
        'stash': {for (final e in _stash.entries) e.key.name: e.value.toJson()},
        'pending': [for (final i in _pending.values) i.toJson()],
        'basket': {
          'level': _level,
          'exp': _expMilli ~/ 1000,
          'pity': _pity,
          'rng': _rng.state,
          'next_id': _nextId,
        },
      };

  void restore(Map<String, dynamic> j) {
    final slots = j['slots'];
    final stash = j['stash'];
    final basket = j['basket'];
    if (slots is! List ||
        stash is! Map<String, dynamic> ||
        basket is! Map<String, dynamic>) {
      throw const FormatException('gear: needs slots, stash and basket');
    }
    final equipped = <GearSlot, GearItem>{};
    final levels = <GearSlot, int>{};
    for (final raw in slots.cast<Map<String, dynamic>>()) {
      final slot = GearSlot.fromName(raw['slot'] as String? ?? '') ??
          (throw FormatException('gear: unknown slot ${raw['slot']}'));
      final item = raw['item'];
      if (item != null) {
        equipped[slot] = GearItem.fromJson(item as Map<String, dynamic>);
      }
      levels[slot] = raw['level'] as int? ?? 0;
    }
    final level = basket['level'], pity = basket['pity'], exp = basket['exp'];
    if (level is! int ||
        level < 1 ||
        level > rules.basketMaxLevel ||
        pity is! int ||
        pity < 0 ||
        exp is! int ||
        exp < 0) {
      throw const FormatException('gear.basket: bad level/exp/pity');
    }
    _equipped
      ..clear()
      ..addAll(equipped);
    _slotLevel
      ..clear()
      ..addAll(levels);
    _stash
      ..clear()
      ..addAll({
        for (final e in stash.entries)
          GearSlot.fromName(e.key) ??
                  (throw FormatException('gear: unknown stash slot ${e.key}')):
              GearItem.fromJson(e.value as Map<String, dynamic>),
      });
    _pending.clear();
    _level = level;
    _expMilli = exp * 1000;
    _pity = pity;
    if (basket['rng'] is int) _rng = SeededRng.fromState(basket['rng'] as int);
    if (basket['next_id'] is int) _nextId = basket['next_id'] as int;
    for (final raw
        in (j['pending'] as List? ?? const []).cast<Map<String, dynamic>>()) {
      final item = GearItem.fromJson(raw);
      _pending[item.id] = item;
      settle(item.id);
    }
  }
}
