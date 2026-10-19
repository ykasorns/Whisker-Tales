import 'avatar_rules.dart';

/// What to draw for one frame, in frame pixels, in order (D-012).
sealed class AvatarOp {
  const AvatarOp();
}

/// The cat frame itself.
class DrawCat extends AvatarOp {
  const DrawCat();
}

/// A gear image with its grip at ([x], [y]), [w]×[h], rotated [deg] about
/// the grip.
class DrawGear extends AvatarOp {
  const DrawGear({
    required this.image,
    required this.x,
    required this.y,
    required this.w,
    required this.h,
    required this.gx,
    required this.gy,
    this.deg = 0,
  });
  final String image;
  final double x, y, w, h, gx, gy, deg;
}

/// Draw the cat again, clipped to a polygon or a circle, so the chin, an arm
/// or a paw sits in front of the gear.
class RestampCat extends AvatarOp {
  const RestampCat.polygon(this.polygon) : circle = null;
  const RestampCat.circle(double x, double y, double r)
      : circle = (x, y, r),
        polygon = null;
  final List<(double, double)>? polygon;
  final (double, double, double)? circle;
}

/// Art ids shown on the cat (`Wardrobe.lookFor` / `offHandFor`); null =
/// nothing on that slot.
class AvatarLook {
  const AvatarLook({this.weapon, this.offHand, this.hat, this.scarf, this.bag});
  final String? weapon, offHand, hat, scarf, bag;

  AvatarLook copyWith({
    String? Function()? weapon,
    String? Function()? offHand,
    String? Function()? hat,
    String? Function()? scarf,
    String? Function()? bag,
  }) =>
      AvatarLook(
        weapon: weapon != null ? weapon() : this.weapon,
        offHand: offHand != null ? offHand() : this.offHand,
        hat: hat != null ? hat() : this.hat,
        scarf: scarf != null ? scarf() : this.scarf,
        bag: bag != null ? bag() : this.bag,
      );
}

/// Pure layout (no drawing): the D-012 render order for [frame] with
/// [look]. [imageSize] gives a gear image's (trimmed) pixel size. Frames
/// without anchors (sleep) draw the cat only.
List<AvatarOp> layoutAvatar(
  AvatarRules rules,
  String frame,
  AvatarLook look,
  (double, double) Function(String image) imageSize,
) {
  final a = rules.frames[frame];
  if (a == null) return const [DrawCat()];
  DrawGear gear(String image, (double, double) at, double deg,
      [double scale = 1]) {
    final base = image.substring(0, image.lastIndexOf('_'));
    final g = rules.gear[base] ??
        (throw ArgumentError.value(image, 'image', 'no gear spec for $base'));
    final (iw, ih) = imageSize(image);
    final h = g.size * scale, w = iw / ih * h;
    return DrawGear(
        image: image,
        x: at.$1,
        y: at.$2,
        w: w,
        h: h,
        gx: g.gripX * w,
        gy: g.gripY * h,
        deg: deg);
  }

  final ops = <AvatarOp>[];
  // 1. behind the body
  if (look.bag case final bag?) {
    ops.add(gear(bag, a.back ?? (a.head.$1 - 55, a.head.$2 + 150), 0));
  }
  if ((look.offHand, a.bp) case (final off?, final bp?)) {
    final isDagger = off.startsWith('dagger_');
    ops.add(gear(off, bp, isDagger ? (a.bpDeg ?? a.fpDeg) : 0));
  }
  final weapon = look.weapon;
  if (weapon != null && a.fp != null && a.fpBehind) {
    ops.add(gear(weapon, a.fp!, a.fpDeg));
  }
  // 2. the cat
  ops.add(const DrawCat());
  // 3. scarf, tucked under the chin and any arm in front
  if (look.scarf case final scarf?) {
    ops.add(gear(scarf, a.neck, 0, rules.scarfScale));
    final ((x1, y1), (x2, y2)) = a.chin;
    ops.add(RestampCat.polygon([
      (x1 - 200, y1 - 400),
      (x2 + 200, y2 - 400),
      (x2 + 200, y2),
      (x1 - 200, y1)
    ]));
    for (final o in a.occluders) {
      ops.add(RestampCat.polygon(o));
    }
  }
  // 4. hat, tilted with the head
  if (look.hat case final hat?) {
    ops.add(gear(hat, (a.head.$1 + a.hat.$1, a.head.$2 + a.hat.$2), a.hatDeg,
        rules.hatScale));
  }
  // 5. weapon, then the paw wraps the grip
  if (weapon != null && a.fp != null && !a.fpBehind) {
    ops.add(gear(weapon, a.fp!, a.fpDeg));
    ops.add(RestampCat.circle(a.fp!.$1, a.fp!.$2, rules.pawRadius));
  }
  return ops;
}
