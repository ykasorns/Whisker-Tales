import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// One painted storybook frame and where live content may go
/// (`design/art/ui_frames.json`, D-059). All numbers are source pixels.
class FrameSpec {
  const FrameSpec({
    required this.asset,
    required this.w,
    required this.h,
    required this.capL,
    required this.capR,
    required this.content,
    this.rects = const {},
    this.slots = const [],
  });

  factory FrameSpec.fromJson(Map<String, dynamic> j) {
    Rect rect(Object? v) {
      final l = (v as List).map((e) => (e as num).toDouble()).toList();
      return Rect.fromLTRB(l[0], l[1], l[2], l[3]);
    }

    return FrameSpec(
      asset: j['asset'] as String,
      w: (j['w'] as num).toDouble(),
      h: (j['h'] as num).toDouble(),
      capL: (j['cap_l'] as num).toDouble(),
      capR: (j['cap_r'] as num).toDouble(),
      content: rect(j['content']),
      rects: {
        for (final e in ((j['rects'] as Map?) ?? const {}).entries)
          e.key as String: rect(e.value),
      },
      slots: [for (final s in (j['slots'] ?? []) as List) rect(s)],
    );
  }

  final String asset;
  final double w, h, capL, capR;
  final Rect content;
  final Map<String, Rect> rects;
  final List<Rect> slots;

  /// Width at which the art is not stretched at all, for [height].
  double naturalWidth(double height) => w * height / h;
}

/// The frames' data and pictures. Loaded once at boot (like [BasketArt]);
/// until then, or when a picture is missing, frames paint nothing and the
/// content still lays out.
class FrameArt {
  FrameArt._();

  static Map<String, FrameSpec> specs = {};
  static final Map<String, ui.Image> _images = {};

  /// A frame that is not loaded (data missing, a test that skips [load])
  /// draws nothing; its content takes the whole box.
  static FrameSpec spec(String name) =>
      specs[name] ??
      const FrameSpec(
          asset: '',
          w: 1,
          h: 1,
          capL: 0,
          capR: 0,
          content: Rect.fromLTWH(0, 0, 1, 1));

  static ui.Image? image(FrameSpec s) => _images[s.asset];

  static Future<void> load([AssetBundle? bundle]) async {
    final b = bundle ?? rootBundle;
    final j = jsonDecode(
            await b.loadString('assets/content/design/art/ui_frames.json'))
        as Map<String, dynamic>;
    specs = {
      for (final e in (j['frames'] as Map<String, dynamic>).entries)
        e.key: FrameSpec.fromJson(e.value as Map<String, dynamic>),
    };
    for (final s in specs.values) {
      if (_images.containsKey(s.asset)) continue;
      try {
        final data = await b.load('assets/game/ui/${s.asset}');
        final codec = await ui.instantiateImageCodec(
            data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
        _images[s.asset] = (await codec.getNextFrame()).image;
      } on Object catch (e) {
        debugPrint('frame ${s.asset} not loaded: $e');
      }
    }
  }
}

/// Where a frame's parts land once it is laid out at a size: the height sets
/// the scale, the caps keep their proportions, only the middle stretches.
class FrameGeometry {
  FrameGeometry(this.spec, this.size)
      : scale = size.height / spec.h,
        _capL = spec.capL * size.height / spec.h,
        _capR = spec.capR * size.height / spec.h {
    _mid = (size.width - _capL - _capR).clamp(0.0, double.infinity);
    _midScale = spec.w - spec.capL - spec.capR > 0
        ? _mid / (spec.w - spec.capL - spec.capR)
        : 1;
  }

  final FrameSpec spec;
  final Size size;
  final double scale;
  final double _capL, _capR;
  late final double _mid, _midScale;

  /// Source x → x in the laid-out frame.
  double x(double sx) {
    if (sx <= spec.capL) return sx * scale;
    if (sx >= spec.w - spec.capR) return size.width - (spec.w - sx) * scale;
    return _capL + (sx - spec.capL) * _midScale;
  }

  double y(double sy) => sy * scale;

  Rect rect(Rect r) =>
      Rect.fromLTRB(x(r.left), y(r.top), x(r.right), y(r.bottom));

  Rect get content => rect(spec.content);

  /// A named area of the frame; the content area when the frame is not loaded.
  Rect named(String key) => rect(spec.rects[key] ?? spec.content);
}

/// A painted frame with live content inside its paper area. The frame is
/// drawn at its own proportions (never squashed to fit); give it a height and
/// it takes the width the parent allows, or size the box with
/// [FrameSpec.naturalWidth]. [builder] gets the geometry to place content by
/// the frame's named rects; [child] simply fills the content area.
class StretchFrame extends StatelessWidget {
  const StretchFrame({
    super.key,
    required this.frame,
    this.child,
    this.builder,
    this.padding = EdgeInsets.zero,
  }) : assert(child != null || builder != null);

  final String frame;
  final Widget? child;
  final Widget Function(BuildContext context, FrameGeometry geometry)? builder;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final spec = FrameArt.spec(frame);
    return LayoutBuilder(builder: (context, box) {
      final h = box.hasBoundedHeight ? box.maxHeight : spec.h * .25;
      final w = box.hasBoundedWidth ? box.maxWidth : spec.naturalWidth(h);
      final g = FrameGeometry(spec, Size(w, h));
      final c = g.content;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned.fill(
            child: CustomPaint(painter: _FramePainter(g, FrameArt.image(spec))),
          ),
          if (child != null)
            Positioned.fromRect(
              rect: padding.deflateRect(c),
              child: child!,
            ),
          if (builder != null) builder!(context, g),
        ]),
      );
    });
  }
}

class _FramePainter extends CustomPainter {
  _FramePainter(this.g, this.image);
  final FrameGeometry g;
  final ui.Image? image;

  @override
  void paint(Canvas canvas, Size size) {
    final im = image;
    if (im == null) return;
    final s = g.spec;
    final paint = Paint()..filterQuality = FilterQuality.medium;
    void part(double sx1, double sx2, double dx1, double dx2) {
      if (sx2 <= sx1 || dx2 <= dx1) return;
      canvas.drawImageRect(
        im,
        Rect.fromLTRB(sx1 * im.width / s.w, 0, sx2 * im.width / s.w,
            im.height.toDouble()),
        // a hair of overlap hides the seam between parts
        Rect.fromLTRB(dx1 - .4, 0, dx2 + .4, size.height),
        paint,
      );
    }

    final l = g.x(s.capL), r = g.x(s.w - s.capR);
    part(0, s.capL, 0, l);
    part(s.capL, s.w - s.capR, l, r);
    part(s.w - s.capR, s.w, r, size.width);
  }

  @override
  bool shouldRepaint(_FramePainter old) =>
      old.g.size != g.size || old.image != image;
}

/// Presses in a little under the finger and springs back, so painted buttons
/// feel like they give. A still button under reduced motion.
class PressScale extends StatefulWidget {
  const PressScale({super.key, required this.onTap, required this.child});

  final VoidCallback? onTap;
  final Widget child;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown:
          widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) => setState(() => _down = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _down && !still ? .94 : 1,
        duration: Duration(milliseconds: still ? 0 : 90),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
