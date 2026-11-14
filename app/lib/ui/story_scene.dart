import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

import '../l10n/strings.dart';
import 'battle_fx.dart';
import 'frames.dart';
import 'game_icon.dart';
import 'palette.dart';

/// The upper part of a Story run: parallax scenery, Mochi and the enemy, the
/// HUD on painted frames, floating hit numbers and the story caption (D-061).
/// Every motion here stops under reduced motion.
class StoryScene extends StatefulWidget {
  const StoryScene({
    super.key,
    required this.controller,
    required this.onQuit,
    required this.nodeMap,
    required this.statusIcons,
  });

  final StoryRunController controller;
  final VoidCallback onQuit;

  /// The route preview strip (owned by the page so tests can find it).
  final Widget nodeMap;

  /// Builds the status icon row above a unit.
  final Widget Function(List<CombatStatusView>) statusIcons;

  @override
  State<StoryScene> createState() => _StorySceneState();
}

/// Aspect (width / height) of the painted background tiles.
const _tileAspect = {
  'L0_sky': 736 / 400,
  'L3_ground': 1103 / 400,
  'ch1_L1_far': 471 / 400,
  'ch1_L2_mid': 590 / 400,
  'ch2_L1_far': 567 / 400,
  'ch2_L2_mid': 551 / 400,
  'ch3_L1_far': 563 / 400,
  'ch3_L2_mid': 519 / 400,
};

/// How far the scenery slides while Mochi walks to the next stop.
const _travelPx = 300.0;

class _Float {
  _Float(this.hit);
  final StoryHit hit;
}

class _StorySceneState extends State<StoryScene> with TickerProviderStateMixin {
  late final AnimationController _motion;
  late final AnimationController _travel;
  bool _precacheStarted = false;
  bool _reduced = false;
  double _base = 0;
  int _lastDepth = -1;
  int _lastHit = 0;
  final List<_Float> _floats = [];
  final List<({int serial, ProjectileSpec spec})> _arrows = [];
  DateTime _enemyHitAt = epoch;
  DateTime _catHitAt = epoch;
  // Attack poses follow the real hit events, like the main battle.
  DateTime _catAttackAt = epoch;
  DateTime _enemyAttackAt = epoch;

  StoryRunController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _travel = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000), value: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheStarted) {
      _precacheStarted = true;
      for (final frame in const [
        'idle',
        'walk_f1',
        'walk_f2',
        'walk_f3',
        'attack',
        'hurt',
        'victory',
        'sleep',
      ]) {
        precacheImage(
            AssetImage(
                'assets/game/cat/outfit_${controller.classId}_$frame.png'),
            context);
      }
      for (final monster in controller.mode.content.monsters.values) {
        for (final frame in const ['idle_f1', 'idle_f2', 'idle_f3', 'attack']) {
          precacheImage(
              AssetImage('assets/game/mon/${monster.sprite}_$frame.png'),
              context);
        }
      }
    }
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) {
      _motion
        ..stop()
        ..value = .35;
      _travel.value = 1;
    } else if (!_motion.isAnimating) {
      _motion.repeat();
    }
  }

  @override
  void dispose() {
    _motion.dispose();
    _travel.dispose();
    super.dispose();
  }

  /// Notices a new stop (start the walk) and new hits (floating numbers).
  /// Mutates plain fields only; the animations repaint on their own.
  void _sync() {
    final depth = controller.encounter?.depth ?? -1;
    if (depth >= 0 && depth != _lastDepth) {
      _lastDepth = depth;
      if (!_reduced) {
        _base += _travelPx;
        _travel.forward(from: 0);
      }
    }
    for (final h in controller.hits) {
      if (h.serial <= _lastHit) continue;
      _lastHit = h.serial;
      if (h.onCat) {
        _enemyAttackAt = DateTime.now();
      } else {
        _catAttackAt = DateTime.now();
        final spec = ProviderScope.containerOf(context, listen: false)
            .read(avatarRulesProvider)
            ?.projectiles[controller.classId];
        if (spec != null && !_reduced) {
          final entry = (serial: h.serial, spec: spec);
          _arrows.add(entry);
          Future.delayed(Duration(milliseconds: spec.flightMs + 40), () {
            if (mounted) setState(() => _arrows.remove(entry));
          });
        }
      }
      if (h.outcome == HitOutcome.dodge || h.damage <= 0) continue;
      if (h.onCat) {
        _catHitAt = DateTime.now();
      } else {
        _enemyHitAt = DateTime.now();
      }
      if (!_reduced) _floats.add(_Float(h));
    }
    if (_floats.length > 6) _floats.removeRange(0, _floats.length - 6);
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    final s = AppLocalizations.of(context);
    final cat = controller.combatView
        .where((u) => u.side == CombatSide.cat && !u.isPartner)
        .firstOrNull;
    final enemy = controller.combatView
        .where((u) => u.side == CombatSide.enemy)
        .firstOrNull;
    final chapter = (controller.manager.current?.config.seed ?? 0) % 3 + 1;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final gy = h * 0.84;
      return Stack(clipBehavior: Clip.hardEdge, children: [
        AnimatedBuilder(
          animation: _travel,
          builder: (_, __) {
            final scroll = _base -
                _travelPx * (1 - Curves.easeInOut.transform(_travel.value));
            return Stack(children: [
              _tile('L0_sky', scroll * .05, w, h, h),
              _tile('ch${chapter}_L1_far', scroll * .25, w, h * .62,
                  gy + h * .04),
              _tile(
                  'ch${chapter}_L2_mid', scroll * .55, w, h * .6, gy + h * .06),
              _tile('L3_ground', scroll, w, (h - gy) / .3, h),
            ]);
          },
        ),
        AnimatedBuilder(
          animation: Listenable.merge([_motion, _travel]),
          builder: (_, __) => _Actors(
            controller: controller,
            phase: _motion.value,
            walking: _travel.isAnimating,
            arrive: _travel.value,
            cat: cat,
            enemy: enemy,
            groundGap: h - gy,
            catAttack:
                DateTime.now().difference(_catAttackAt).inMilliseconds < 280,
            enemyAttack:
                DateTime.now().difference(_enemyAttackAt).inMilliseconds < 320,
            catHurt: _recent(_catHitAt),
            enemyHurt: _recent(_enemyHitAt),
            statusIcons: widget.statusIcons,
          ),
        ),
        for (final shot in _arrows)
          ArrowFlightFx(
            key: ValueKey('arrow-${shot.serial}'),
            spec: shot.spec,
            sceneHeight: h,
            from: Offset(24 + 52 + h * shot.spec.muzzleX,
                h - (h - gy) * .35 + h * shot.spec.muzzleY),
            to: Offset(w - 24 - 70, h - (h - gy) * .35 - 60),
          ),
        for (final f in _floats)
          HitSparkFx(
            key: ValueKey('spark-${f.hit.serial}'),
            onCat: f.hit.onCat,
            crit: f.hit.outcome == HitOutcome.crit,
            left: f.hit.onCat ? 24 : w - 112,
            bottom: (h - gy) + 52,
          ),
        for (final f in _floats)
          HitNumberFx(
            key: ValueKey(f.hit.serial),
            damage: f.hit.damage,
            onCat: f.hit.onCat,
            crit: f.hit.outcome == HitOutcome.crit,
            left: f.hit.onCat ? 40 : w - 150,
            bottom: (h - gy) + 96,
            onDone: () {
              if (mounted) setState(() => _floats.remove(f));
            },
          ),
        Positioned(
          left: 8,
          right: 8,
          top: 6,
          child: Column(children: [
            _HpPlate(controller: controller, onQuit: widget.onQuit),
            const SizedBox(height: 3),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: widget.nodeMap),
              const SizedBox(width: 6),
              _CountTag(icon: 'sparkle', count: controller.relicIds.length),
              const SizedBox(width: 4),
              _CountTag(icon: 'star', count: controller.talentIds.length),
            ]),
          ]),
        ),
        if (controller.panel != StoryRunPanel.event)
          Positioned(
            left: 22,
            right: 22,
            top: h * .30,
            child: StoryCaption(
              key: const Key('story-caption'),
              serial: controller.captionSerial,
              lines: controller.captionLines(s.lang),
            ),
          ),
        if (controller.panel == StoryRunPanel.result)
          Positioned(
            right: 36,
            bottom: (h - gy) + 20,
            child: GameIcon(
              controller.completion?.result.outcome == RunOutcome.won
                  ? 'victory'
                  : 'sadcat',
              size: 108,
            ),
          ),
      ]);
    });
  }

  static bool _recent(DateTime at) =>
      DateTime.now().difference(at).inMilliseconds < 220;

  Widget _tile(String name, double offset, double w, double h, double bottom) {
    final tileW = h * (_tileAspect[name] ?? 1);
    final first = -(offset % tileW);
    return Stack(clipBehavior: Clip.hardEdge, children: [
      for (var x = first; x < w; x += tileW - 1)
        Positioned(
          left: x,
          top: bottom - h,
          width: tileW,
          height: h,
          child: Image.asset('assets/game/bg/bg_book1_$name.webp',
              fit: BoxFit.fill, filterQuality: FilterQuality.low),
        ),
    ]);
  }
}

class _Actors extends StatelessWidget {
  const _Actors({
    required this.controller,
    required this.phase,
    required this.walking,
    required this.arrive,
    required this.cat,
    required this.enemy,
    required this.groundGap,
    required this.catAttack,
    required this.enemyAttack,
    required this.catHurt,
    required this.enemyHurt,
    required this.statusIcons,
  });

  final StoryRunController controller;
  final double phase, arrive, groundGap;
  final bool walking, catAttack, enemyAttack, catHurt, enemyHurt;
  final UnitView? cat;
  final UnitView? enemy;
  final Widget Function(List<CombatStatusView>) statusIcons;

  bool get fighting => controller.panel == StoryRunPanel.combat;

  String get catFrame {
    if (fighting) {
      if (catHurt) return 'hurt';
      if (catAttack) return 'attack';
      return 'idle';
    }
    if (controller.panel == StoryRunPanel.result) {
      return controller.completion?.result.outcome == RunOutcome.won
          ? 'victory'
          : 'sleep';
    }
    if (walking) return 'walk_f${(phase * 3).floor().clamp(0, 2) + 1}';
    return 'idle';
  }

  String get enemyFrame {
    if (enemyAttack) return 'attack';
    return 'idle_f${(phase * 3).floor().clamp(0, 2) + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final catAdvance = fighting && catAttack ? 16.0 : 0.0;
    final enemyAdvance = fighting && enemyAttack ? 14.0 : 0.0;
    final bob = walking
        ? math.sin(phase * math.pi * 6).abs() * 5
        : math.sin(phase * math.pi * 2) * 1.5;
    // the enemy walks in from the right while the scenery slides
    final enter = (1 - Curves.easeOut.transform(arrive)) * 180;
    final bottom = groundGap * .35;
    final monsterSprite = enemy == null
        ? null
        : controller.mode.content.monsters[enemy!.id]?.sprite ?? enemy!.id;
    final shake = enemyHurt ? math.sin(phase * 90) * 3 : 0.0;
    final dust = (phase * 3) % 1;
    return Stack(children: [
      if (walking)
        Positioned(
          left: 6 - dust * 22,
          bottom: bottom - 2,
          child: Opacity(
            opacity: (.8 * (1 - dust)).clamp(0, 1),
            child: Image.asset('assets/game/story/fx/fx_dust.png',
                width: 44 + dust * 16, height: 44 + dust * 16),
          ),
        ),
      Positioned(
        left: 24 + catAdvance + (catHurt ? -4 : 0),
        bottom: bottom + bob,
        child: Column(children: [
          if (cat != null) statusIcons(cat!.statuses),
          Image.asset(
            'assets/game/cat/outfit_${controller.classId}_$catFrame.png',
            key: const Key('story-cat'),
            width: 104,
            height: 130,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Image.asset(
              'assets/game/cat/$catFrame.png',
              width: 104,
              height: 130,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ]),
      ),
      if (fighting && enemy != null)
        Positioned(
          right: 24 + enemyAdvance - enter + shake,
          bottom: bottom + 4,
          child: Column(children: [
            statusIcons(enemy!.statuses),
            ColorFiltered(
              colorFilter: enemyHurt
                  ? const ColorFilter.mode(Color(0x99FFFFFF), BlendMode.srcATop)
                  : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
              child: Image.asset(
                'assets/game/mon/${monsterSprite}_$enemyFrame.png',
                key: const Key('story-enemy'),
                width: enemy!.isBoss ? 150 : 112,
                height: enemy!.isBoss ? 150 : 112,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
          ]),
        ),
    ]);
  }
}

/// A speaker's painted face (GPT art, story_v1/portraits).
Widget storyPortrait(String id, double size) => Image.asset(
      'assets/game/story/portraits/portrait_$id.png',
      key: Key('portrait-$id'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => SizedBox(width: size, height: size),
    );

/// A painted impact burst that pops and fades once under a hit number.
/// HP and talent progress on the long wood plate; its round button is the
/// quit button.
class _HpPlate extends StatelessWidget {
  const _HpPlate({required this.controller, required this.onQuit});

  final StoryRunController controller;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final hpNow = controller.displayedHp;
    final hpMax = controller.displayedMaxHp;
    final shield = controller.displayedShield;
    final hp = hpMax == 0 ? 0.0 : hpNow / hpMax;
    final xp = controller.talentXpToNext == 0
        ? 1.0
        : controller.talentXp / controller.talentXpToNext;
    final low = hp < .3;
    return SizedBox(
      height: 46,
      child: StretchFrame(
        frame: 'currency',
        builder: (context, g) => Stack(children: [
          Positioned.fromRect(
            rect: g.content,
            child: Row(children: [
              const GameIcon('heart', size: 22),
              const SizedBox(width: 6),
              SizedBox(
                width: 104,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: IconText(
                      '${s.storyHp} $hpNow/$hpMax${shield > 0 ? ' · 🛡️ $shield' : ''}',
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: Palette.ink)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _Bar(
                          value: hp, color: low ? Palette.coral : Palette.lime),
                      const SizedBox(height: 2),
                      _Bar(value: xp, color: Palette.plum, height: 3),
                    ]),
              ),
            ]),
          ),
          Positioned.fromRect(
            rect: g.named('button'),
            child: Semantics(
              button: true,
              label: s.storyQuit,
              child: GestureDetector(
                key: const Key('story-quit'),
                behavior: HitTestBehavior.opaque,
                onTap: onQuit,
                child: const Center(child: GameIcon('cross', size: 20)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.value, required this.color, this.height = 6});
  final double value, height;
  final Color color;

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: LinearProgressIndicator(
            value: value.clamp(0, 1),
            minHeight: height,
            color: color,
            backgroundColor: Palette.ink.withValues(alpha: .15)),
      );
}

class _CountTag extends StatelessWidget {
  const _CountTag({required this.icon, required this.count});
  final String icon;
  final int count;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 54,
        height: 36,
        child: StretchFrame(
          frame: 'action',
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                GameIcon(icon, size: 16),
                const SizedBox(width: 2),
                Text('$count',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Palette.ink)),
              ]),
            ),
          ),
        ),
      );
}

/// One or more story lines on a painted plate. Each line is typed out (tap to
/// show it whole, tap again for the next), rests a moment, then the next line
/// follows; after the last the plate fades away. No timers: one controller per
/// line, so a test pump settles. Reduced motion shows each line whole.
class StoryCaption extends StatefulWidget {
  const StoryCaption({super.key, required this.serial, required this.lines});

  /// Changes when a new caption should be told from its first line.
  final int serial;
  final List<String> lines;

  @override
  State<StoryCaption> createState() => _StoryCaptionState();
}

class _StoryCaptionState extends State<StoryCaption>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  int _index = 0;
  bool _gone = false;
  bool _typed = false;

  static const _typeMs = 28;

  String get _line => widget.lines.isEmpty ? '' : widget.lines[_index];

  bool get _last => _index + 1 >= widget.lines.length;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this)..addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _begin());
  }

  void _begin() {
    if (!mounted) return;
    if (widget.lines.isEmpty) {
      setState(() => _gone = true);
      return;
    }
    final reduced = MediaQuery.disableAnimationsOf(context);
    _typed = false;
    _c.duration =
        Duration(milliseconds: reduced ? 0 : _line.characters.length * _typeMs);
    _c.forward(from: 0);
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _typed = true);
    }
  }

  @override
  void didUpdateWidget(StoryCaption old) {
    super.didUpdateWidget(old);
    if (old.serial != widget.serial) {
      _index = 0;
      _gone = false;
      _begin();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// The line stays until it is read: a tap shows it whole, the next tap
  /// moves on (and closes the caption after the last line).
  void _tap() {
    if (!_typed) {
      _c.value = 1;
    } else if (!_last) {
      _index++;
      _begin();
    } else {
      setState(() => _gone = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_gone || widget.lines.isEmpty || !_c.isAnimating && _c.value == 0) {
      return const SizedBox.shrink();
    }
    final s = AppLocalizations.of(context);
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final n = _line.characters.length;
        final shown = _c.duration == Duration.zero
            ? n
            : (_c.value * n).floor().clamp(0, n);
        return GestureDetector(
          key: const Key('story-caption-tap'),
          onTap: _tap,
          behavior: HitTestBehavior.opaque,
          child: SizedBox(
            height: 58,
            child: Row(children: [
              storyPortrait('bobbin', 48),
              const SizedBox(width: 2),
              Expanded(
                child: StretchFrame(
                  frame: 'action',
                  builder: (context, g) => Positioned.fromRect(
                    rect: g.content,
                    child: Row(children: [
                      Expanded(
                        child: Center(
                          child: _TypedText(
                              text: _line,
                              shown: shown,
                              style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.25,
                                  fontWeight: FontWeight.w800,
                                  color: Palette.ink)),
                        ),
                      ),
                      if (_typed)
                        IconText(_last ? s.storyOk : s.storyNext,
                            key: const Key('story-caption-next'),
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: Palette.teal)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        );
      },
    );
  }
}

/// [head] visible, [tail] laid out but invisible, so the block never reflows.
Widget _typed(String head, String tail, TextStyle style, TextAlign align) =>
    Text.rich(
      TextSpan(style: style, children: [
        TextSpan(text: head),
        TextSpan(text: tail, style: const TextStyle(color: Colors.transparent)),
      ]),
      textAlign: align,
    );

/// Text that is laid out whole (so nothing jumps) but only [shown] characters
/// are visible.
class _TypedText extends StatelessWidget {
  const _TypedText(
      {required this.text, required this.shown, required this.style});

  final String text;
  final int shown;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final head = text.characters.take(shown).toString();
    final tail = text.characters.skip(shown).toString();
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: _typed(head, tail, style, TextAlign.center),
      ),
    );
  }
}

/// Types out [text] for the event panel; tap to show it whole.
class StoryTypewriter extends StatefulWidget {
  const StoryTypewriter({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<StoryTypewriter> createState() => _StoryTypewriterState();
}

class _StoryTypewriterState extends State<StoryTypewriter>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (!mounted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.value = 1;
      return;
    }
    _c.duration = Duration(
        milliseconds: math.max(200, widget.text.characters.length * 22));
    _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(StoryTypewriter old) {
    super.didUpdateWidget(old);
    if (old.text != widget.text) _start();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _c.value = 1,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final n = widget.text.characters.length;
            final shown = _c.duration == null && _c.value == 0
                ? 0
                : (n * _c.value).floor().clamp(0, n);
            return _typed(
                widget.text.characters.take(shown).toString(),
                widget.text.characters.skip(shown).toString(),
                widget.style,
                TextAlign.left);
          },
        ),
      );
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
