import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

/// Shared battle visuals for the Story run and the Treat Dungeon, so a hit
/// looks the same in every mode as in the main battle: the strike pose on
/// the real hit, the archer's arrow, the hit burst and painted digit numbers.

/// Avatar rules (projectiles per class). Overridden in `main`; null in tests.
final avatarRulesProvider = Provider<AvatarRules?>((_) => null);

bool recentAt(DateTime at, int ms) =>
    DateTime.now().difference(at).inMilliseconds < ms;

final epoch = DateTime.fromMillisecondsSinceEpoch(0);

/// The burst where a hit lands.
class HitSparkFx extends StatelessWidget {
  const HitSparkFx({
    super.key,
    required this.onCat,
    required this.crit,
    required this.left,
    required this.bottom,
  });

  final bool onCat, crit;
  final double left, bottom;

  @override
  Widget build(BuildContext context) {
    final name =
        onCat ? 'fx_hit_hurt' : (crit ? 'fx_hit_crit' : 'fx_hit_white');
    final size = crit ? 92.0 : 70.0;
    return Positioned(
      left: left,
      bottom: bottom,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 380),
          builder: (_, t, __) => Opacity(
            opacity: (1 - t * t).clamp(0, 1),
            child: Transform.scale(
              scale: 0.5 +
                  0.8 * Curves.easeOutBack.transform(math.min(1, t * 1.6)),
              child: Image.asset('assets/game/story/fx/$name.png',
                  width: size,
                  height: size,
                  filterQuality: FilterQuality.medium),
            ),
          ),
        ),
      ),
    );
  }
}

/// A damage number that pops, drifts up and fades once.
class HitNumberFx extends StatelessWidget {
  const HitNumberFx({
    super.key,
    required this.damage,
    required this.onCat,
    required this.crit,
    required this.left,
    required this.bottom,
    this.onDone,
  });

  final int damage;
  final bool onCat, crit;
  final double left, bottom;
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      bottom: bottom,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 850),
          onEnd: onDone,
          builder: (_, t, __) => Opacity(
            opacity: (1 - t * t).clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, -46 * Curves.easeOut.transform(t)),
              child: Transform.scale(
                scale:
                    0.7 + 0.5 * Curves.elasticOut.transform(math.min(1, t * 2)),
                child: GlyphNumber(
                  text: onCat ? '-$damage' : '$damage',
                  style: onCat ? 'hurt' : (crit ? 'crit' : 'normal'),
                  height: crit ? 40 : 30,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A number drawn from the painted digit sprites (`damage_numbers/`).
class GlyphNumber extends StatelessWidget {
  const GlyphNumber(
      {super.key,
      required this.text,
      required this.style,
      required this.height});

  final String text, style;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final ch in text.split(''))
          Align(
            widthFactor: .88,
            child: Image.asset(
              'assets/game/damage_numbers/${style}_${switch (ch) {
                '-' => 'minus',
                '+' => 'plus',
                _ => ch,
              }}.png',
              height: height,
              filterQuality: FilterQuality.medium,
            ),
          ),
      ],
    );
  }
}

/// The class projectile (the archer's arrow) flying from [from] to [to] in
/// the scene's local coordinates (top-left origin).
class ArrowFlightFx extends StatelessWidget {
  const ArrowFlightFx({
    super.key,
    required this.spec,
    required this.from,
    required this.to,
    required this.sceneHeight,
  });

  final ProjectileSpec spec;
  final Offset from, to;
  final double sceneHeight;

  @override
  Widget build(BuildContext context) {
    final len = sceneHeight * spec.length;
    final angle = math.atan2(to.dy - from.dy, to.dx - from.dx);
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: Duration(milliseconds: spec.flightMs),
        builder: (_, k, __) {
          final p = Offset.lerp(from, to, k)!;
          return Stack(children: [
            Positioned(
              left: p.dx - len / 2,
              top: p.dy - len / 2,
              width: len,
              height: len,
              child: Opacity(
                opacity: k < .98 ? 1 : 0,
                child: Transform.rotate(
                  angle: angle,
                  child: Image.asset('assets/game/icon/${spec.icon}.png',
                      fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
