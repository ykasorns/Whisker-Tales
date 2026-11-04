import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_dungeon/wt_mode_dungeon.dart';

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

const _manifest = ModeManifest(
    id: 'dungeon',
    nameTh: 'x',
    nameEn: 'x',
    icon: 'x',
    order: 2,
    enabled: true,
    minAppVersion: '1');

Map<String, dynamic> _json() =>
    jsonDecode(File('../../design/data/dungeon.json').readAsStringSync())
        as Map<String, dynamic>;

/// Deals [perTick] to the boss on each tick; the cat is never hurt.
class _FakeEngine implements ICombatEngine {
  _FakeEngine(this.perTick);
  final int perTick;
  final _events = StreamController<CombatEvent>.broadcast(sync: true);
  List<UnitView> _view = const [];
  int _now = 0;

  @override
  Stream<CombatEvent> get events => _events.stream;

  @override
  List<UnitView> get view => _view;

  @override
  void useSkill(int slotIndex) {}

  @override
  void start(CombatSetup setup) {
    final boss = setup.units.last;
    _view = [
      UnitView(
          id: boss.id,
          side: boss.side,
          isBoss: true,
          isPartner: false,
          hp: boss.stats.hp,
          maxHp: boss.stats.hp,
          shield: 0,
          alive: true),
    ];
  }

  @override
  void tick(int dtMs) {
    _now += dtMs;
    final b = _view.single;
    final hp = (b.hp - perTick).clamp(0, b.maxHp);
    _view = [
      UnitView(
          id: b.id,
          side: b.side,
          isBoss: true,
          isPartner: false,
          hp: hp,
          maxHp: b.maxHp,
          shield: 0,
          alive: hp > 0),
    ];
    _events.add(HitResolved(
        atMs: _now,
        attackerId: 'mochi',
        targetId: b.id,
        outcome: HitOutcome.normal,
        damage: b.hp - hp,
        targetHp: hp));
    if (hp == 0) _events.add(CombatEnded(playerWon: true, atMs: _now));
  }
}

void main() {
  late GameContent content;
  late DungeonRules rules;
  late DungeonMode mode;

  setUpAll(() async {
    content = await ContentRepository(_Disk()).loadAll();
    rules = DungeonRules.fromJson(_json());
    mode = DungeonMode(_manifest, rules);
  });

  final cat = CombatUnitSpec(
      id: 'mochi',
      side: CombatSide.cat,
      stats: StatBlock(hp: 1000, atk: 100, def: 0),
      attackIntervalMs: 1000);

  DungeonController controller(ICombatEngine Function() engine,
          {DungeonSave? save,
          MemoryWallet? wallet,
          int ads = 0,
          String day = '2026-11-04',
          void Function(DungeonSave)? onSave}) =>
      DungeonController(
        mode: mode,
        save: save ?? DungeonSave(),
        cat: cat,
        partners: const [],
        idle: content.idle,
        powerScore: PowerScore(content.combat.powerWeights),
        engineFactory: engine,
        wallet: wallet ?? MemoryWallet(),
        dayKey: day,
        adsWatchedToday: () => ads,
        onSave: onSave ?? (_) {},
      );

  group('rules', () {
    test('shipped data: 3 free runs, 30 s, five rising tiers, 30 levels', () {
      expect(rules.freeRunsPerDay, 3);
      expect(rules.timeLimitMs, 30000);
      expect(rules.maxLevel, 30);
      expect(rules.tiers, hasLength(5));
      expect(rules.tiers.last.damagePct, 100);
    });

    test('bosses get stronger with every level', () {
      final w = content.combat.powerWeights;
      var last = 0;
      for (var l = 1; l <= rules.maxLevel; l++) {
        final b = rules.bossSpec(l, content.idle, w);
        expect(b.stats.hp, greaterThan(last), reason: 'level $l');
        last = b.stats.hp;
      }
    });

    test('tiers and cookies rise with damage and level', () {
      expect(rules.tierFor(0, 1000), 0);
      expect(rules.tierFor(199, 1000), 0);
      expect(rules.tierFor(200, 1000), 1);
      expect(rules.tierFor(600, 1000), 3);
      expect(rules.tierFor(1000, 1000), 5);
      expect(rules.cookiesFor(1, 0), 0);
      for (var t = 2; t <= 5; t++) {
        expect(rules.cookiesFor(5, t), greaterThan(rules.cookiesFor(5, t - 1)));
      }
      expect(rules.cookiesFor(20, 3), greaterThan(rules.cookiesFor(2, 3)));
    });

    test('bad data names the field', () {
      final j = _json()..['unlock_tier'] = 9;
      expect(() => DungeonRules.fromJson(j), throwsFormatException);
      final k = _json();
      (k['tiers'] as List).add({'damage_pct': 10, 'mult': 9});
      expect(() => DungeonRules.fromJson(k), throwsFormatException);
    });
  });

  group('entries', () {
    test('3 free runs, +1 per ad watched, reset on a new day', () {
      final s = DungeonSave(day: 'd1', runsToday: 2);
      expect(mode.entriesLeft(s, 'd1', 0), 1);
      expect(mode.entriesLeft(s, 'd1', 2), 3);
      expect(
          mode.entriesLeft(DungeonSave(day: 'd1', runsToday: 5), 'd1', 2), 0);
      expect(mode.entriesLeft(s, 'd2', 0), 3); // a new day
    });

    test('starting spends the entry at once; none left, no start', () {
      final saves = <DungeonSave>[];
      final c = controller(() => _FakeEngine(1),
          save: DungeonSave(day: '2026-11-04', runsToday: 3),
          onSave: saves.add);
      expect(c.entriesLeft, 0);
      expect(c.start(1), isFalse);
      expect(saves, isEmpty);
      final c2 = controller(() => _FakeEngine(1),
          save: DungeonSave(day: '2026-11-04', runsToday: 3), ads: 1);
      expect(c2.start(1), isTrue);
      expect(c2.save.runsToday, 4);
    });

    test('a level above the unlocked one cannot be entered', () {
      final c = controller(() => _FakeEngine(1));
      expect(c.canStart(2), isFalse);
      expect(c.start(2), isFalse);
    });
  });

  group('a run', () {
    test('stops at 30 s of game time and pays by the damage dealt', () {
      final wallet = MemoryWallet();
      final save = DungeonSave(unlocked: 20);
      final probe = controller(() => _FakeEngine(0), save: save)..start(20);
      final maxHp = probe.boss!.maxHp;
      // 45% of the boss over the 30 s (300 ticks of 100 ms)
      final engine = _FakeEngine(maxHp * 45 ~/ 100 ~/ 300);
      final c = controller(() => engine, wallet: wallet, save: save)..start(20);
      var ticks = 0;
      while (c.running) {
        c.tick(100);
        ticks++;
      }
      expect(ticks, 300);
      final r = c.result!;
      expect(r.tier, 2);
      expect(r.cookies, rules.cookiesFor(20, 2));
      expect(wallet.balance(Currency.cookies), r.cookies);
      expect(r.bossDefeated, isFalse);
    });

    test('killing the boss early ends the run at the top tier', () {
      final wallet = MemoryWallet();
      final c = controller(() => _FakeEngine(1 << 30), wallet: wallet);
      c.start(1);
      c.tick(100);
      expect(c.running, isFalse);
      expect(c.result!.tier, rules.tiers.length);
      expect(c.result!.bossDefeated, isTrue);
      expect(c.elapsedMs, lessThan(30000));
    });

    test('leaving early still pays what was dealt, once', () {
      final wallet = MemoryWallet();
      final save = DungeonSave(unlocked: 20);
      final probe = controller(() => _FakeEngine(0), save: save)..start(20);
      final engine = _FakeEngine(probe.boss!.maxHp * 65 ~/ 100);
      final d = controller(() => engine, wallet: wallet, save: save)..start(20);
      d.tick(100); // 65% of the boss in one tick
      final r = d.finish()!;
      expect(r.tier, 3);
      final paid = wallet.balance(Currency.cookies);
      expect(paid, rules.cookiesFor(20, 3));
      expect(d.finish(), same(r));
      expect(wallet.balance(Currency.cookies), paid);
    });

    test('nothing dealt pays nothing but still uses the entry', () {
      final wallet = MemoryWallet();
      final c = controller(() => _FakeEngine(0), wallet: wallet);
      c.start(1);
      final r = c.finish()!;
      expect(r.cookies, 0);
      expect(wallet.balance(Currency.cookies), 0);
      expect(c.save.runsToday, 1);
    });

    test('the unlock tier on the top open level opens the next level', () {
      final c = controller(() => _FakeEngine(1 << 30));
      c.start(1);
      c.tick(100);
      expect(c.result!.unlockedNext, isTrue);
      expect(c.save.unlocked, 2);
      expect(c.save.bestTier[1], rules.tiers.length);
      // replaying level 1 does not open level 3
      final again = controller(() => _FakeEngine(1 << 30), save: c.save);
      again.start(1);
      again.tick(100);
      expect(again.result!.unlockedNext, isFalse);
      expect(again.save.unlocked, 2);
    });

    test('a weaker run never lowers the best tier', () {
      final c = controller(() => _FakeEngine(1 << 30));
      c.start(1);
      c.tick(100);
      final weak = controller(() => _FakeEngine(0), save: c.save);
      weak.start(1);
      weak.finish();
      expect(weak.save.bestTier[1], rules.tiers.length);
    });
  });

  group('real combat', () {
    CombatUnitSpec catOfPower(int page) {
      final w = content.combat.powerWeights;
      final power = content.idle.bossPower(page);
      return CombatUnitSpec(
          id: 'mochi',
          side: CombatSide.cat,
          stats: StatBlock(
              hp: power * content.idle.hpSharePct * 1000 ~/ (100 * w.hpPm),
              atk: power *
                  (100 - content.idle.hpSharePct) *
                  1000 ~/
                  (100 * w.atkPm),
              def: 0),
          attackIntervalMs: 1000);
    }

    double fraction(int catPage, int level) {
      final c = DungeonController(
        mode: mode,
        save: DungeonSave(unlocked: 30),
        cat: catOfPower(catPage),
        partners: const [],
        idle: content.idle,
        powerScore: PowerScore(content.combat.powerWeights),
        engineFactory: () => CombatEngine(content.combat),
        wallet: MemoryWallet(),
        dayKey: 'd',
        adsWatchedToday: () => 0,
        onSave: (_) {},
      )..start(level);
      while (c.running) {
        c.tick(100);
      }
      return c.result!.fraction;
    }

    test('a stronger cat deals more; a higher level deals less', () {
      expect(fraction(60, 8), greaterThanOrEqualTo(fraction(25, 8)));
      expect(fraction(25, 8), greaterThan(fraction(25, 20)));
      expect(fraction(120, 30), greaterThan(fraction(40, 30)));
    });

    test('a cat far ahead of the level takes the top tier', () {
      expect(fraction(120, 1), 1.0);
    });

    test('a cat far behind the level reaches no tier', () {
      expect(fraction(8, 30), lessThan(0.2));
    });
  });

  group('save', () {
    test('round trip; bad values fall back', () {
      final s = DungeonSave(
          day: 'd', runsToday: 2, unlocked: 5, bestTier: {1: 5, 4: 3});
      final back = mode.decodeSave(mode.encodeSave(s))
          as DungeonSave;
      expect(back.unlocked, 5);
      expect(back.runsToday, 2);
      expect(back.bestTier, {1: 5, 4: 3});
      final bad = mode.decodeSave({
        'runs_today': -3,
        'unlocked': 9999,
        'best_tier': {'1': 99, 'x': 1, '2': 'no'},
      }) as DungeonSave;
      expect(bad.runsToday, 0);
      expect(bad.unlocked, rules.maxLevel);
      expect(bad.bestTier, isEmpty);
      expect((mode.decodeSave(const {}) as DungeonSave).unlocked, 1);
    });
  });
}
