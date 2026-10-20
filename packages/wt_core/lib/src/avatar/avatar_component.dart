import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'avatar_layout.dart';
import 'avatar_renderer.dart';
import 'avatar_rules.dart';

/// Mochi on screen (T-027, GDD v0.5.1 §2): full-body frame animation of the
/// current skin with the visible gear placed on per-frame anchors in the
/// D-012 render order. Rendering only — no game logic. [position] is the
/// point between the feet on the ground line.
///
/// Images are looked up by key: frames `"<skin>/<frame>"` (e.g.
/// `base/walk_f2`), gear `"gear/<art>"` (e.g. `gear/staff_2`). Art ids come
/// from `Wardrobe.lookFor` / `offHandFor` (T-045).
class AvatarComponent extends PositionComponent {
  AvatarComponent({
    required this.rules,
    required this.images,
    this.frameScale = 0.6,
    String skin = 'base',
    String classId = 'novice',
    super.position,
    super.priority,
  })  : _skin = skin,
        _classId = classId;

  final AvatarRules rules;
  final ui.Image? Function(String key) images;

  /// Screen px per frame px.
  double frameScale;

  String _skin;
  String _classId;
  String _anim = 'idle';
  double _t = 0;
  AvatarLook _look = const AvatarLook();
  List<AvatarOp>? _ops;
  String? _opsFrame;

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
  AvatarLook get look => _look;

  /// Current frame name, e.g. `walk_f3` or `bare_mage`.
  String get frame => switch (_anim) {
        'walk' => walkCycle[(_t * walkFps).floor() % walkCycle.length],
        'attack' => 'bare_$_classId',
        _ => _anim,
      };

  void play(String animId) {
    if (!anims.contains(animId)) throw ArgumentError.value(animId, 'animId');
    if (animId != _anim) _t = 0;
    _anim = animId;
  }

  /// [slot] = `weapon` / `offHand` / `hat` / `scarf` / `bag`; [art] null
  /// hides it.
  void setGear(String slot, String? art) {
    String? f() => art;
    _look = switch (slot) {
      'weapon' => _look.copyWith(weapon: f),
      'offHand' => _look.copyWith(offHand: f),
      'hat' => _look.copyWith(hat: f),
      'scarf' => _look.copyWith(scarf: f),
      'bag' => _look.copyWith(bag: f),
      _ => throw ArgumentError.value(slot, 'slot'),
    };
    _ops = null;
  }

  void setClass(String classId) {
    _classId = classId;
    _ops = null;
  }

  void setSkin(String skinId) {
    _skin = skinId;
    _ops = null;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
  }

  (double, double) _size(String art) {
    final img = images('gear/$art');
    return img == null ? (1, 1) : (img.width.toDouble(), img.height.toDouble());
  }

  /// Draw list for the current frame (cached until frame or gear changes).
  List<AvatarOp> get ops {
    final f = frame;
    if (_ops == null || _opsFrame != f) {
      _ops = layoutAvatar(rules, f, _look, _size);
      _opsFrame = f;
    }
    return _ops!;
  }

  @override
  void render(ui.Canvas canvas) {
    final img = images('$_skin/$frame');
    if (img == null) return;
    final origin = ui.Offset(
      -img.width * frameScale / 2,
      -(img.height - rules.groundPadPx) * frameScale,
    );
    paintAvatar(canvas, ops, img, (art) => images('gear/$art'),
        origin: origin, scale: frameScale);
  }
}
