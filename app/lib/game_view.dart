import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Shadow;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import 'ui/palette.dart';

/// Drives the game while the app is open: the idle loop, auto-knit and the
/// clock, at the chosen speed (GDD v0.5 §1). Offline time is handled by
/// OfflineReward, never by this ticker.
class GameDriver {
  GameDriver(this._ref);
  final WidgetRef _ref;
  double speed = 1;
  double _carryMs = 0;
  double _sinceClock = 0;
  final ui$ = ValueNotifier<int>(0);
  double _sinceUi = 0;

  void tick(double dt) {
    _carryMs += dt * 1000 * speed;
    final ms = _carryMs.floor();
    _carryMs -= ms;
    if (ms > 0) {
      _ref.read(idleLoopProvider).tick(ms);
      _ref.read(autoCraftProvider).tick(ms);
    }
    _sinceClock += dt;
    if (_sinceClock > 5) {
      _sinceClock = 0;
      _ref.read(gameClockProvider).tick();
    }
    _sinceUi += dt;
    if (_sinceUi > 0.25) {
      _sinceUi = 0;
      ui$.value++;
    }
  }
}

/// The 60% game area (T-042a): parallax storybook page, Mochi with the worn
/// gear (T-027) and the monsters of the idle loop's current fight.
class GameView extends ConsumerStatefulWidget {
  const GameView({super.key, required this.avatarRules, required this.driver});
  final AvatarRules avatarRules;
  final GameDriver driver;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  late final BattleGame _game = BattleGame(
    rules: widget.avatarRules,
    driver: widget.driver,
    loop: ref.read(idleLoopProvider),
    look: _look,
  );

  (String, Map<String, String?>) _look() {
    final cls = ref.read(catClassProvider).current;
    final w = ref.read(wardrobeProvider);
    return (
      cls,
      {
        'weapon': w.lookFor(GearSlot.weapon, cls),
        'offHand': w.offHandFor(cls),
        'hat': w.lookFor(GearSlot.hat, cls),
        'scarf': w.lookFor(GearSlot.scarf, cls),
        'bag': w.lookFor(GearSlot.bag, cls),
      }
    );
  }

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}

class BattleGame extends FlameGame {
  BattleGame(
      {required this.rules,
      required this.driver,
      required this.loop,
      required this.look});

  final AvatarRules rules;
  final GameDriver driver;
  final IdleLoop loop;
  final (String, Map<String, String?>) Function() look;

  late final AvatarComponent mochi;
  late final _Parallax _bg;
  final _monsters = <String, _Monster>{};
  int _seenFight = -1;
  double _sinceLook = 0;
  double _attackT = 0;
  StreamSubscription<CombatEvent>? _sub;

  static const _catFrames = [
    'idle',
    'walk_f1',
    'walk_f2',
    'walk_f3',
    'dodge',
    'hurt',
    'victory',
    'sleep',
    'bare_novice',
    'bare_warrior',
    'bare_rogue',
    'bare_archer',
    'bare_mage',
  ];
  static const _monFrames = [
    'idle_f1',
    'idle_f2',
    'idle_f3',
    'telegraph_f1',
    'telegraph_f2',
    'attack',
    'defeated',
  ];

  double get groundY => size.y * 0.84;

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/game/';
    await images.loadAll([
      for (final f in _catFrames) 'cat/$f.png',
      for (final a in [
        'sword',
        'shield',
        'dagger',
        'bow',
        'staff',
        'hat',
        'scarf',
        'bag'
      ])
        for (final t in [1, 2, 3]) 'gear/${a}_$t.png',
      for (final k in ['eraserslime', 'acorn', 'eraserking'])
        for (final f in _monFrames) 'mon/${k}_$f.png',
      for (final b in [
        'bg_book1_L0_sky',
        'bg_book1_ch1_L1_far',
        'bg_book1_ch1_L2_mid',
        'bg_book1_L3_ground'
      ])
        'bg/$b.png',
    ]);
    _bg = _Parallax(this);
    add(_bg);
    mochi = AvatarComponent(rules: rules, images: _image, priority: 10)
      ..play('walk');
    add(mochi);
    _applyLook();
    _sub = loop.combatEvents.listen(_onCombat);
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }

  ui.Image? _image(String key) {
    final file =
        key.startsWith('base/') ? 'cat/${key.substring(5)}.png' : '$key.png';
    return images.containsKey(file) ? images.fromCache(file) : null;
  }

  void _applyLook() {
    final (cls, slots) = look();
    mochi.setClass(cls);
    for (final e in slots.entries) {
      mochi.setGear(e.key, e.value);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  void _layout() {
    mochi
      ..position = Vector2(size.x * 0.24, groundY)
      ..frameScale = size.y * 0.36 / 335;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isLoaded) return;
    if (mochi.position.x == 0) _layout();
    _sinceLook += dt;
    if (_sinceLook > 0.5) {
      _sinceLook = 0;
      _applyLook();
    }
    final walking =
        loop.phase == IdlePhase.walking || loop.phase == IdlePhase.resting;
    if (walking) {
      _bg.scroll += dt * driver.speed * size.y * 0.35;
      if (_monsters.isNotEmpty) _clearMonsters();
      mochi.play(loop.phase == IdlePhase.resting ? 'hurt' : 'walk');
    } else {
      if (loop.fightId != _seenFight) _spawn();
      _attackT -= dt;
      mochi.play(_attackT > 0 ? 'attack' : 'idle');
    }
  }

  void _spawn() {
    _seenFight = loop.fightId;
    _clearMonsters();
    final enemies =
        loop.fightUnits.where((u) => u.side == CombatSide.enemy).toList();
    const spots = {
      1: [0.74],
      2: [0.64, 0.86],
      3: [0.6, 0.76, 0.92]
    };
    for (var i = 0; i < enemies.length; i++) {
      final e = enemies[i];
      final xs = spots[enemies.length] ??
          [
            for (var j = 0; j < enemies.length; j++)
              0.56 + 0.38 * j / (enemies.length - 1)
          ];
      final kind = e.isBoss
          ? (loop.state.clearedPage + 1) % 10 == 0
              ? 'eraserking'
              : 'eraserslime'
          : (loop.fightId + i).isEven
              ? 'eraserslime'
              : 'acorn';
      final m = _Monster(this, kind, boss: e.isBoss)
        ..position = Vector2(size.x * xs[i], groundY)
        ..heightPx = size.y * (e.isBoss ? 0.4 : 0.25 - i * 0.012);
      _monsters[e.id] = m;
      add(m);
    }
  }

  void _clearMonsters() {
    for (final m in _monsters.values) {
      m.removeFromParent();
    }
    _monsters.clear();
  }

  void _onCombat(CombatEvent e) {
    switch (e) {
      case HitResolved(
          :final attackerId,
          :final targetId,
          :final damage,
          :final outcome,
          :final source
        ):
        final target = _monsters[targetId];
        if (attackerId == 'mochi' && source != AttackSource.dot) {
          _attackT = 0.25;
        }
        if (target != null) {
          target.flash = 0.15;
          _float(
              outcome == HitOutcome.dodge ? '·' : '$damage',
              target.position + Vector2(0, -target.heightPx - 8),
              outcome == HitOutcome.crit
                  ? Palette.coral
                  : source == AttackSource.skill
                      ? const Color(0xFFE8742B)
                      : Palette.ink);
        } else if (targetId == 'mochi') {
          _monsters[attackerId]?.attackT = 0.3;
          _float(
              outcome == HitOutcome.dodge ? '💨' : '-$damage',
              mochi.position + Vector2(-10, -size.y * 0.3),
              outcome == HitOutcome.dodge ? Palette.plum : Palette.coral);
        }
      case UnitDefeated(:final unitId):
        _monsters[unitId]?.dead = true;
      case SkillCast():
        _attackT = 0.35;
      default:
    }
  }

  void _float(String text, Vector2 at, Color color) {
    add(_FloatText(text, at, color, size.y * 0.06));
  }
}

class _Parallax extends Component {
  _Parallax(this.game);
  final BattleGame game;
  double scroll = 0;

  void _tile(
      String key, double parallax, double h, double bottom, ui.Canvas c) {
    if (!game.images.containsKey(key)) return;
    final im = game.images.fromCache(key);
    final w = im.width * h / im.height;
    var x = -((scroll * parallax) % w);
    final src =
        ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble());
    final p = ui.Paint()..filterQuality = ui.FilterQuality.low;
    for (; x < game.size.x; x += w - 1) {
      c.drawImageRect(im, src, ui.Rect.fromLTWH(x, bottom - h, w, h), p);
    }
  }

  @override
  void render(ui.Canvas c) {
    final s = game.size, gy = game.groundY;
    _tile('bg/bg_book1_L0_sky.png', 0.05, s.y, s.y, c);
    _tile('bg/bg_book1_ch1_L1_far.png', 0.2, s.y * 0.62, gy + s.y * 0.04, c);
    _tile('bg/bg_book1_ch1_L2_mid.png', 0.5, s.y * 0.6, gy + s.y * 0.06, c);
    final hg = (s.y - gy) / 0.3;
    _tile('bg/bg_book1_L3_ground.png', 1, hg, gy + 0.3 * hg, c);
  }
}

class _Monster extends PositionComponent {
  _Monster(this.game, this.kind, {this.boss = false}) : super(priority: 5);
  final BattleGame game;
  final String kind;
  final bool boss;
  double heightPx = 80;
  double t = 0, flash = 0, attackT = 0;
  bool dead = false;
  double deadT = 0;

  /// Extra transparent rows below the feet in some sheets (slicer PAD = 12).
  double get _feetPad => kind == 'eraserslime' ? 24 : 12;

  @override
  void update(double dt) {
    t += dt;
    flash = math.max(0, flash - dt);
    attackT = math.max(0, attackT - dt);
    if (dead) deadT += dt;
  }

  @override
  void render(ui.Canvas c) {
    final f = dead
        ? 'defeated'
        : attackT > 0
            ? 'attack'
            : 'idle_f${1 + (t * 6).floor() % 3}';
    final key = 'mon/${kind}_$f.png';
    if (!game.images.containsKey(key)) return;
    final im = game.images.fromCache(key);
    final s = heightPx / im.height;
    final w = im.width * s;
    final p = ui.Paint();
    if (dead) {
      p.color = Colors.white.withValues(alpha: math.max(0, 1 - deadT * 1.4));
    }
    if (flash > 0) {
      p.colorFilter =
          const ui.ColorFilter.mode(Colors.white54, ui.BlendMode.srcATop);
    }
    c.drawImageRect(
      im,
      ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
      ui.Rect.fromLTWH(-w / 2, -(im.height - _feetPad) * s, w, im.height * s),
      p,
    );
    if (boss) {
      final tp = TextPainter(
          text: const TextSpan(text: '👑', style: TextStyle(fontSize: 22)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset(-tp.width / 2, -heightPx - 26));
    }
  }
}

class _FloatText extends PositionComponent {
  _FloatText(this.text, Vector2 at, this.color, this.fontSize)
      : super(position: at.clone(), priority: 20);
  final String text;
  final Color color;
  final double fontSize;
  double t = 0;

  @override
  void update(double dt) {
    t += dt;
    position.y -= dt * 40;
    if (t > 0.9) removeFromParent();
  }

  @override
  void render(ui.Canvas c) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          color: color.withValues(alpha: (1 - t).clamp(0, 1)),
          shadows: const [Shadow(color: Palette.paper, blurRadius: 3)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, Offset(-tp.width / 2, 0));
  }
}
