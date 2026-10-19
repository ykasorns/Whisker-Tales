/// `design/art/anchors_mochi.json` (GDD v0.5.1 §2, D-005, D-012): per-frame
/// anchors in each frame's own pixels, gear grip/size, and render order.
class FrameAnchors {
  const FrameAnchors({
    required this.head,
    required this.neck,
    required this.chin,
    required this.hat,
    this.hatDeg = 0,
    this.fp,
    this.fpDeg = 0,
    this.fpBehind = false,
    this.bp,
    this.bpDeg,
    this.back,
    this.occluders = const [],
  });

  final (double, double) head;
  final (double, double) neck;

  /// Back-of-head point → chin point; the cat is drawn again above it.
  final ((double, double), (double, double)) chin;

  /// Hat offset from [head].
  final (double, double) hat;
  final double hatDeg;
  final (double, double)? fp;
  final double fpDeg;
  final bool fpBehind;
  final (double, double)? bp;
  final double? bpDeg;

  /// Bag point (default head + (-55, 150)).
  final (double, double)? back;
  final List<List<(double, double)>> occluders;
}

class GearSpec {
  const GearSpec(this.size, this.gripX, this.gripY);

  /// Drawn height in frame pixels.
  final double size;

  /// Grip point as a fraction of the (trimmed) image.
  final double gripX, gripY;
}

class AvatarRules {
  const AvatarRules({
    required this.frames,
    required this.gear,
    required this.pawRadius,
    required this.hatScale,
    required this.scarfScale,
    required this.groundPadPx,
  });

  final Map<String, FrameAnchors> frames;
  final Map<String, GearSpec> gear;
  final double pawRadius, hatScale, scarfScale, groundPadPx;

  factory AvatarRules.fromJson(Map<String, dynamic> json) {
    FormatException bad(String w) => FormatException('anchors_mochi: $w');
    (double, double) pt(Object? v, String where) {
      if (v is! List || v.length != 2 || v.any((e) => e is! num)) {
        throw bad('$where must be [x, y]');
      }
      return ((v[0] as num).toDouble(), (v[1] as num).toDouble());
    }

    (double, double)? opt(Object? v, String where) =>
        v == null ? null : pt(v, where);
    double n(Map m, String k, String where, [double? fallback]) {
      final v = m[k];
      if (v is num) return v.toDouble();
      if (fallback != null) return fallback;
      throw bad('$where.$k must be a number');
    }

    final rawFrames = json['frames'];
    final rawGear = json['gear'];
    final order = json['render_order'];
    if (rawFrames is! Map || rawGear is! Map || order is! Map) {
      throw bad('needs frames, gear and render_order');
    }
    final frames = <String, FrameAnchors>{};
    for (final e in rawFrames.entries) {
      final k = e.key as String, f = e.value as Map;
      final chin = f['chin'];
      if (chin is! List || chin.length != 2) {
        throw bad('$k.chin must be [[x,y],[x,y]]');
      }
      frames[k] = FrameAnchors(
        head: pt(f['head'], '$k.head'),
        neck: pt(f['neck'], '$k.neck'),
        chin: (pt(chin[0], '$k.chin'), pt(chin[1], '$k.chin')),
        hat: pt(f['hat'], '$k.hat'),
        hatDeg: n(f, 'hatDeg', k, 0),
        fp: opt(f['fp'], '$k.fp'),
        fpDeg: n(f, 'fpDeg', k, 0),
        fpBehind: f['fpBehind'] == true,
        bp: opt(f['bp'], '$k.bp'),
        bpDeg: f['bpDeg'] is num ? (f['bpDeg'] as num).toDouble() : null,
        back: opt(f['back'], '$k.back'),
        occluders: [
          for (final o in (f['occluders'] as List? ?? const []))
            [for (final p in o as List) pt(p, '$k.occluders')],
        ],
      );
    }
    final gear = <String, GearSpec>{};
    for (final e in rawGear.entries) {
      if ((e.key as String).startsWith('_')) continue;
      final g = e.value as Map;
      final grip = pt(g['grip'], '${e.key}.grip');
      gear[e.key as String] =
          GearSpec(n(g, 'size', e.key as String), grip.$1, grip.$2);
    }
    return AvatarRules(
      frames: Map.unmodifiable(frames),
      gear: Map.unmodifiable(gear),
      pawRadius: n(order, 'paw_radius', 'render_order'),
      hatScale: n(order, 'hat_scale', 'render_order'),
      scarfScale: n(order, 'scarf_scale', 'render_order'),
      groundPadPx: n(order, 'ground_pad_px', 'render_order'),
    );
  }
}
