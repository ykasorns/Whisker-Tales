import 'dart:math' as math;
import 'dart:ui' as ui;

import 'avatar_layout.dart';

/// Paints [ops] (from `layoutAvatar`) with the frame's top-left at
/// [origin] and [scale] canvas px per frame px. Gear images come from
/// [gear]; a missing image is skipped (still loading).
void paintAvatar(
  ui.Canvas canvas,
  List<AvatarOp> ops,
  ui.Image frame,
  ui.Image? Function(String image) gear, {
  ui.Offset origin = ui.Offset.zero,
  double scale = 1,
}) {
  final paint = ui.Paint()..filterQuality = ui.FilterQuality.medium;
  ui.Offset at(double x, double y) => origin + ui.Offset(x * scale, y * scale);
  void cat() => canvas.drawImageRect(
      frame,
      ui.Rect.fromLTWH(0, 0, frame.width.toDouble(), frame.height.toDouble()),
      ui.Rect.fromLTWH(
          origin.dx, origin.dy, frame.width * scale, frame.height * scale),
      paint);

  for (final op in ops) {
    switch (op) {
      case DrawCat():
        cat();
      case DrawGear():
        final img = gear(op.image);
        if (img == null) continue;
        canvas.save();
        canvas.translate(at(op.x, op.y).dx, at(op.x, op.y).dy);
        canvas.rotate(op.deg * math.pi / 180);
        canvas.drawImageRect(
            img,
            ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            ui.Rect.fromLTWH(
                -op.gx * scale, -op.gy * scale, op.w * scale, op.h * scale),
            paint);
        canvas.restore();
      case RestampCat(:final polygon, :final circle):
        final path = ui.Path();
        if (polygon != null) {
          path.addPolygon([for (final (x, y) in polygon) at(x, y)], true);
        } else if (circle != null) {
          final (x, y, r) = circle;
          path.addOval(ui.Rect.fromCircle(center: at(x, y), radius: r * scale));
        }
        canvas.save();
        canvas.clipPath(path);
        cat();
        canvas.restore();
    }
  }
}
