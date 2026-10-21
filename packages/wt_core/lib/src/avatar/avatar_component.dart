import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'avatar_rules.dart';

/// Mochi on screen (T-027, D-024): one full-body image per frame, drawn in
/// the outfit of the current class — gear gives power and shows in the
/// slots, never on the cat. Rendering only. [position] is the point between
/// the feet on the ground line.
///
/// Images are looked up by `"<class>/<frame>"` (e.g. `mage/walk_f2`); the
/// app falls back to the base frames while a class has no art yet.
class AvatarComponent extends PositionComponent {
  AvatarComponent({
    required this.rules,
    required this.images,
    this.frameScale = 0.6,
    String classId = 'novice',
    super.position,
    super.priority,
  }) : _classId = classId;

  final AvatarRules rules;
  final ui.Image? Function(String key) images;

  /// Screen px per frame px.
  double frameScale;

  String _classId;
  String _anim = 'idle';
  double _t = 0;

  static const walkCycle = ['walk_f1', 'walk_f2', 'walk_f3', 'walk_f2'];
  static const walkFps = 8.0;
  static const anims = {
    'idle',
    'walk',
    'attack',
    'dodge',
    'hurt',
    'victory',
    'sleep'
  };

  String get anim => _anim;
  String get classId => _classId;

  /// Current frame name, e.g. `walk_f3` or `attack`.
  String get frame => _anim == 'walk'
      ? walkCycle[(_t * walkFps).floor() % walkCycle.length]
      : _anim;

  /// Image key of the current frame, e.g. `mage/attack`.
  String get imageKey => '$_classId/$frame';

  void play(String animId) {
    if (!anims.contains(animId)) throw ArgumentError.value(animId, 'animId');
    if (animId != _anim) _t = 0;
    _anim = animId;
  }

  void setClass(String classId) => _classId = classId;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final img = images(imageKey);
    if (img == null) return;
    final w = img.width * frameScale, h = img.height * frameScale;
    canvas.drawImageRect(
      img,
      ui.Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
      ui.Rect.fromLTWH(
          -w / 2, -(img.height - rules.groundPadPx) * frameScale, w, h),
      ui.Paint()..filterQuality = ui.FilterQuality.medium,
    );
  }
}
