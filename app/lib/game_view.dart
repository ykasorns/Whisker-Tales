import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'
    show Colors, TextStyle, FontWeight, Shadow;
import 'package:flutter/services.dart';
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
    // music follows the scene (T-024): the boss track while a boss fight
    // runs, crossfading in real time whatever the game speed
    final audio = _ref.read(audioServiceProvider);
    audio.playBgm(_ref.read(idleLoopProvider).isBossFight ? 'boss' : 'farm');
    audio.tick((dt * 1000).round());
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
      _ref.read(researchProvider)?.tick();
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
    chapters: ref.read(chapterBookProvider),
    classId: () => ref.read(catClassProvider).current,
    pets: () {
      final pets = ref.read(petsProvider);
      if (pets == null) return const [];
      return [
        for (final id in pets.deployed.take(pets.deploySlots))
          (id: id, icon: pets.rules.byId(id)?.icon ?? '🐾'),
      ];
    },
  );

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}

class BattleGame extends FlameGame {
  BattleGame({
    required this.rules,
    required this.driver,
    required this.loop,
    required this.chapters,
    required this.classId,
    this.pets,
  });

  /// Deployed pets (T-038), drawn following Mochi.
  final List<({String id, String icon})> Function()? pets;

  /// Seconds left of each pet's attack pose (by pet id).
  final _petAttack = <String, double>{};

  final AvatarRules rules;
  final GameDriver driver;
  final IdleLoop loop;

  /// Monsters, bosses and scenery per chapter (D-032).
  final ChapterBook chapters;

  /// The cat's class: Mochi wears its outfit (D-024).
  final String Function() classId;

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
    // class outfit frames that exist so far (cat/outfit_<class>_<frame>)
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final outfits = [
      for (final a in manifest.listAssets())
        if (a.startsWith('assets/game/cat/outfit_'))
          a.substring('assets/game/'.length),
    ];
    final petFrames = [
      for (final a in manifest.listAssets())
        if (a.startsWith('assets/game/pet/'))
          a.substring('assets/game/'.length),
    ];
    final iconFrames = [
      for (final a in manifest.listAssets())
        if (a.startsWith('assets/game/icon/') && a.endsWith('.png'))
          a.substring('assets/game/'.length),
    ];
    await images.loadAll([
      ...iconFrames
          .where((a) => a.endsWith('/crown.png') || a.endsWith('/evade.png')),
      for (final f in _catFrames) 'cat/$f.png',
      ...outfits,
      ...petFrames,
      for (final k in chapters.kinds)
        for (final f in _monFrames) 'mon/${k}_$f.png',
      'bg/bg_book1_L0_sky.webp',
      'bg/bg_book1_L3_ground.webp',
      for (final a in chapters.chapters)
        for (final l in ['L1_far', 'L2_mid']) 'bg/bg_book1_${a.layer}_$l.webp',
    ]);
    _bg = _Parallax(this);
    add(_bg);
    mochi = AvatarComponent(rules: rules, images: _image, priority: 10)
      ..play('walk');
    add(mochi);
    add(_Pets(this));
    _applyLook();
    _sub = loop.combatEvents.listen(_onCombat);
  }

  @override
  void onRemove() {
    _sub?.cancel();
    super.onRemove();
  }

  /// `<class>/<frame>` → `cat/outfit_<class>_<frame>` (D-024); a class
  /// without art yet uses the base frames (its attack pose is
  /// `bare_<class>`).
  ui.Image? _image(String key) {
    final slash = key.indexOf('/');
    final cls = key.substring(0, slash), frame = key.substring(slash + 1);
    for (final file in [
      'cat/outfit_${cls}_$frame.png',
      frame == 'attack' ? 'cat/bare_$cls.png' : 'cat/$frame.png',
    ]) {
      if (images.containsKey(file)) return images.fromCache(file);
    }
    return null;
  }

  void _applyLook() => mochi.setClass(classId());

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) _layout();
  }

  /// Mochi stands further right so the pets have room on her left (YK
  /// 2026-10-23: they were hidden behind her).
  static const _mochiX = 0.40;

  void _layout() {
    mochi
      ..position = Vector2(size.x * _mochiX, groundY)
      // a bit smaller so the scene breathes (YK 2026-10-23, D-030)
      ..frameScale = size.y * 0.27 / 335;
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
      1: [0.78],
      2: [0.70, 0.90],
      3: [0.66, 0.80, 0.93]
    };
    for (var i = 0; i < enemies.length; i++) {
      final e = enemies[i];
      final xs = spots[enemies.length] ??
          [
            for (var j = 0; j < enemies.length; j++)
              0.56 + 0.38 * j / (enemies.length - 1)
          ];
      final page = loop.state.farmPage;
      final mons = chapters.of(loop.rules, page).monsters;
      final kind = e.isBoss
          ? chapters.bossOf(loop.rules, page)
          : mons[(loop.fightId + i) % mons.length];
      final m = _Monster(this, kind, boss: e.isBoss)
        ..position = Vector2(size.x * xs[i], groundY)
        ..heightPx = size.y * (e.isBoss ? 0.3 : 0.19 - i * 0.009);
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
        if (attackerId.startsWith('pet_')) {
          _petAttack[attackerId.substring(4)] = 0.3;
        }
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
              outcome == HitOutcome.dodge ? Palette.plum : Palette.coral,
              icon: outcome == HitOutcome.dodge ? 'icon/evade.png' : null);
        }
      case UnitDefeated(:final unitId):
        _monsters[unitId]?.dead = true;
      case SkillCast():
        _attackT = 0.35;
      default:
    }
  }

  void _float(String text, Vector2 at, Color color, {String? icon}) {
    final im = icon != null && images.containsKey(icon)
        ? images.fromCache(icon)
        : null;
    add(_FloatText(text, at, color, size.y * 0.06, image: im));
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
    _tile('bg/bg_book1_L0_sky.webp', 0.05, s.y, s.y, c);
    final layer =
        game.chapters.of(game.loop.rules, game.loop.state.farmPage).layer;
    _tile('bg/bg_book1_${layer}_L1_far.webp', 0.2, s.y * 0.62, gy + s.y * 0.04,
        c);
    _tile(
        'bg/bg_book1_${layer}_L2_mid.webp', 0.5, s.y * 0.6, gy + s.y * 0.06, c);
    final hg = (s.y - gy) / 0.3;
    _tile('bg/bg_book1_L3_ground.webp', 1, hg, gy + 0.3 * hg, c);
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

  /// Laid out once for every boss, not once per frame.
  static final _crown = TextPainter(
      text: const TextSpan(text: '👑', style: TextStyle(fontSize: 22)),
      textDirection: TextDirection.ltr)
    ..layout();

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
      const key = 'icon/crown.png';
      if (game.images.containsKey(key)) {
        final im = game.images.fromCache(key);
        c.drawImageRect(
            im,
            ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
            ui.Rect.fromLTWH(-15, -heightPx - 34, 30, 30),
            ui.Paint()..filterQuality = ui.FilterQuality.medium);
      } else {
        _crown.paint(c, Offset(-_crown.width / 2, -heightPx - 26));
      }
    }
  }
}

class _FloatText extends PositionComponent {
  _FloatText(this.text, Vector2 at, this.color, this.fontSize, {this.image})
      : super(position: at.clone(), priority: 20);
  final String text;

  /// Painted icon drawn instead of [text] (the dodge swoosh).
  final ui.Image? image;
  final Color color;
  final double fontSize;
  double t = 0;
  TextPainter? _tp;
  int _step = -1;

  @override
  void update(double dt) {
    t += dt;
    position.y -= dt * 40;
    if (t > 0.9) removeFromParent();
  }

  @override
  void render(ui.Canvas c) {
    // fades in 10 steps: the text is laid out again when the step changes,
    // not on every frame (dozens of numbers fly at ×3 speed)
    final step = ((1 - t).clamp(0.0, 1.0) * 10).ceil();
    if (image case final im?) {
      final s = fontSize * 1.4;
      c.drawImageRect(
          im,
          ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
          ui.Rect.fromLTWH(-s / 2, 0, s, s),
          ui.Paint()
            ..filterQuality = ui.FilterQuality.medium
            ..color = Colors.white.withValues(alpha: step / 10));
      return;
    }
    if (step != _step || _tp == null) {
      _step = step;
      _tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            color: color.withValues(alpha: step / 10),
            shadows: const [Shadow(color: Palette.paper, blurRadius: 3)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
    }
    final tp = _tp!;
    tp.paint(c, Offset(-tp.width / 2, 0));
  }
}

/// Deployed pets hop along behind Mochi (T-038): their sprite (attack pose
/// while they hit), or the emoji while a pet has no art yet.
class _Pets extends Component {
  _Pets(this.game) : super(priority: 9);
  final BattleGame game;
  double t = 0;

  /// Laid-out emoji by icon and size; a handful at most.
  final _painted = <String, TextPainter>{};

  @override
  void update(double dt) {
    t += dt;
    game._petAttack.updateAll((_, v) => v - dt);
  }

  @override
  void render(ui.Canvas c) {
    final pets = game.pets?.call() ?? const [];
    final u = game.size.y;
    for (var i = 0; i < pets.length; i++) {
      final p = pets[i];
      // a staggered formation to Mochi's left, clear of her body: the
      // front row stands on the ground, the back row a step higher and smaller
      final back = i.isOdd;
      final h = u * (back ? 0.078 : 0.088);
      final hop = (math.sin(t * 8 + i * 1.7)).abs() * u * 0.02;
      final lift = back ? u * 0.03 : 0.0;
      final x = game.mochi.position.x - u * (0.2 + 0.085 * i);
      final pose = (game._petAttack[p.id] ?? 0) > 0 ? 'attack' : 'idle';
      final key = 'pet/${p.id}_$pose.png';
      if (game.images.containsKey(key)) {
        final im = game.images.fromCache(key);
        final w = im.width * h / im.height;
        c.drawImageRect(
            im,
            ui.Rect.fromLTWH(0, 0, im.width.toDouble(), im.height.toDouble()),
            ui.Rect.fromLTWH(x - w / 2, game.groundY - h - hop - lift, w, h),
            ui.Paint()..filterQuality = ui.FilterQuality.medium);
        continue;
      }
      final size = game.size.y * 0.06;
      final tp = _painted.putIfAbsent(
          '${p.icon}@$size',
          () => TextPainter(
                text: TextSpan(text: p.icon, style: TextStyle(fontSize: size)),
                textDirection: TextDirection.ltr,
              )..layout());
      tp.paint(
          c, Offset(x - tp.width / 2, game.groundY - tp.height - hop - lift));
    }
  }
}
