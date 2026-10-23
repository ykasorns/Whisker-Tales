import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'home_page.dart' show YarnBall;

/// One yarn ball resting in the basket (`design/art/home_basket.json`).
class BasketBall {
  const BasketBall(this.asset, this.x, this.y, this.size, this.phase);
  final String asset;
  final double x, y, size, phase;
}

/// The basket's art and layout (D-040). Loaded at boot; while the pictures
/// are not in the bundle the plain yarn ball is shown instead.
class BasketArt {
  BasketArt._();

  static bool ready = false;
  static double aspect = 1.3;

  /// The basket's opening as an ellipse (fractions of the picture).
  static Rect opening = const Rect.fromLTWH(0.14, 0.1, 0.7, 0.35);
  static List<BasketBall> balls = const [];

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final j = jsonDecode(
            await b.loadString('assets/content/design/art/home_basket.json'))
        as Map<String, dynamic>;
    final o = j['opening'] as Map<String, dynamic>;
    final cx = (o['cx'] as num).toDouble(), cy = (o['cy'] as num).toDouble();
    final rx = (o['rx'] as num).toDouble(), ry = (o['ry'] as num).toDouble();
    opening = Rect.fromLTRB(cx - rx, cy - ry, cx + rx, cy + ry);
    aspect = (j['aspect'] as num).toDouble();
    balls = [
      for (final m in (j['balls'] as List).cast<Map<String, dynamic>>())
        BasketBall(
            m['asset'] as String,
            (m['x'] as num).toDouble(),
            (m['y'] as num).toDouble(),
            (m['size'] as num).toDouble(),
            (m['phase'] as num).toDouble()),
    ];
    final manifest = await AssetManifest.loadFromAssetBundle(b);
    final assets = manifest.listAssets().toSet();
    ready = assets.contains('assets/game/home/basket.png') &&
        balls.every((x) => assets.contains('assets/game/home/${x.asset}.png'));
  }

  static void reset() {
    ready = false;
    balls = const [];
  }
}

/// A wicker basket of yarn balls that bob while idle and hop when something
/// is knitted: the basket squashes, the balls jump in turn, and one ball
/// leaps out in an arc and unrolls (YK 2026-10-23). [knit] counts knits —
/// it plays when the number changes; [quiet] is the gentler hop for
/// auto-knit; [empty] keeps the balls still and dim (no yarn).
class YarnBasket extends StatefulWidget {
  const YarnBasket(
      {super.key,
      required this.height,
      this.knit = 0,
      this.quiet = false,
      this.empty = false});

  final double height;
  final int knit;
  final bool quiet, empty;

  @override
  State<YarnBasket> createState() => _YarnBasketState();
}

class _YarnBasketState extends State<YarnBasket> with TickerProviderStateMixin {
  late final AnimationController _idle;
  late final AnimationController _knit;

  @override
  void initState() {
    super.initState();
    // created up front: dispose() must not be the first to touch them
    _idle = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    _knit = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void didUpdateWidget(YarnBasket old) {
    super.didUpdateWidget(old);
    if (widget.knit != old.knit) _knit.forward(from: 0);
  }

  @override
  void dispose() {
    _idle.dispose();
    _knit.dispose();
    super.dispose();
  }

  static double _bump(double t) => math.sin(math.pi * t.clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (!BasketArt.ready) {
      return YarnBall(size: widget.height * 0.8, wiggle: widget.knit);
    }
    final h = widget.height, w = h * BasketArt.aspect;
    final basket = Image.asset('assets/game/home/basket.png',
        width: w,
        height: h,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.medium);
    return AnimatedBuilder(
      animation: Listenable.merge([_idle, _knit]),
      builder: (context, _) {
        final k = _knit.isAnimating ? _knit.value : 0.0;
        final squash = widget.quiet ? 0.4 : 1.0;
        final chosen = BasketArt.balls.isEmpty
            ? -1
            : widget.knit.abs() % BasketArt.balls.length;
        final resting = <Widget>[];
        Widget? flying;
        for (var i = 0; i < BasketArt.balls.length; i++) {
          final b = BasketArt.balls[i];
          final d = b.size * w;
          final bob = widget.empty
              ? 0.0
              : math.sin(2 * math.pi * _idle.value + b.phase) * 0.012 * h;
          final hopT = k == 0 ? 0.0 : ((k - i * 0.06) / 0.4).clamp(0.0, 1.0);
          final hop = _bump(hopT) * (widget.quiet ? 0.07 : 0.15) * h;
          var dx = b.x * w - d / 2, dy = b.y * h - d / 2 + bob - hop;
          var angle = bob * 0.4;
          var opacity = widget.empty ? 0.5 : 1.0;
          var scale = 1.0;
          final isChosen = i == chosen && k > 0 && !widget.quiet;
          if (isChosen) {
            // hops, flies out in an arc spinning, fades out, reappears
            final fly = ((k - 0.12) / 0.58).clamp(0.0, 1.0);
            final arc = _bump(fly);
            dx += (0.5 * w - b.x * w) * Curves.easeOut.transform(fly);
            dy += (-0.62 * h - b.y * h) * Curves.easeOut.transform(fly) -
                arc * 0.18 * h;
            angle = fly * 2 * math.pi * 3;
            scale = 1 + 0.2 * arc;
            if (k > 0.7) opacity = (1 - (k - 0.7) / 0.15).clamp(0.0, 1.0);
            if (k > 0.85) {
              dx = b.x * w - d / 2;
              dy = b.y * h - d / 2;
              angle = 0;
              scale = 1;
              opacity = ((k - 0.85) / 0.15).clamp(0.0, 1.0);
            }
          }
          final ball = Positioned(
            left: dx,
            top: dy,
            width: d,
            height: d,
            child: Opacity(
              opacity: opacity,
              child: Transform.rotate(
                angle: angle,
                child: Transform.scale(
                  scale: scale,
                  child: Image.asset('assets/game/home/${b.asset}.png',
                      fit: BoxFit.contain, filterQuality: FilterQuality.medium),
                ),
              ),
            ),
          );
          if (isChosen && k > 0.12 && k < 0.85) {
            flying = ball; // drawn over the rim while it is in the air
          } else {
            resting.add(ball);
          }
        }
        final s = _bump(k * 2.2) * 0.9 * squash; // squash early in the knit
        return SizedBox(
          width: w,
          height: h,
          child: Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.diagonal3Values(1 + 0.05 * s, 1 - 0.08 * s, 1),
            child: Stack(clipBehavior: Clip.none, children: [
              basket,
              ...resting,
              // the front of the basket again, over the balls
              Positioned.fill(
                child: ClipPath(
                  clipper: _FrontOfRim(BasketArt.opening),
                  child: basket,
                ),
              ),
              if (flying != null) flying,
            ]),
          ),
        );
      },
    );
  }
}

/// The front of the basket only: everything below the middle of the opening
/// except the opening itself, drawn over the balls so they sit *inside* — the
/// rim curves, so a straight cut would show the back wall over the balls.
class _FrontOfRim extends CustomClipper<Path> {
  const _FrontOfRim(this.opening);
  final Rect opening;

  @override
  Path getClip(Size size) {
    final o = Rect.fromLTRB(
        opening.left * size.width,
        opening.top * size.height,
        opening.right * size.width,
        opening.bottom * size.height);
    return Path.combine(
        PathOperation.difference,
        Path()..addRect(Rect.fromLTRB(0, o.center.dy, size.width, size.height)),
        Path()..addOval(o));
  }

  @override
  bool shouldReclip(_FrontOfRim old) => old.opening != opening;
}
