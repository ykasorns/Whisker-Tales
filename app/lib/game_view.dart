import 'dart:async';
import 'dart:ui' as ui;

import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

/// The 60% game area (T-027 first cut): Mochi walking with the gear the
/// player wears. Scene, monsters and HUD come with T-042.
class GameView extends ConsumerStatefulWidget {
  const GameView({super.key, required this.avatarRules});
  final AvatarRules avatarRules;

  @override
  ConsumerState<GameView> createState() => _GameViewState();
}

class _GameViewState extends ConsumerState<GameView> {
  late final MochiGame _game = MochiGame(widget.avatarRules, _look);

  /// What Mochi shows right now, from the wardrobe + class (T-045).
  (String, Map<String, String?>) _look() {
    final cls = ref.read(catClassProvider).current;
    final w = ref.read(wardrobeProvider);
    return (
      cls,
      {
        'weapon': w.lookFor(GearSlot.weapon, cls),
        'offHand': w.offHandFor(cls),
        'hat': w.lookFor(GearSlot.hat, cls),
        'scarf': w.lookFor(GearSlot.scarf, cls),
        'bag': w.lookFor(GearSlot.bag, cls),
      }
    );
  }

  @override
  Widget build(BuildContext context) => GameWidget(game: _game);
}

class MochiGame extends FlameGame {
  MochiGame(this.rules, this.look);

  final AvatarRules rules;
  final (String, Map<String, String?>) Function() look;
  late final AvatarComponent mochi;
  double _sinceLook = 0;

  static const _frames = [
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

  @override
  Future<void> onLoad() async {
    images.prefix = 'assets/game/';
    await images.loadAll([for (final f in _frames) 'cat/$f.png']);
    final gear = <String>[
      for (final a in [
        'sword',
        'shield',
        'dagger',
        'bow',
        'staff',
        'hat',
        'scarf',
        'bag'
      ])
        for (final t in [1, 2, 3]) 'gear/${a}_$t.png',
    ];
    await images.loadAll(gear);
    mochi = AvatarComponent(rules: rules, images: _image)..play('walk');
    add(mochi);
    _applyLook();
  }

  ui.Image? _image(String key) {
    final file =
        key.startsWith('base/') ? 'cat/${key.substring(5)}.png' : '$key.png';
    return images.containsKey(file) ? images.fromCache(file) : null;
  }

  void _applyLook() {
    final (cls, slots) = look();
    mochi.setClass(cls);
    for (final e in slots.entries) {
      mochi.setGear(e.key, e.value);
    }
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (isLoaded) {
      mochi
        ..position = Vector2(size.x * 0.3, size.y * 0.85)
        ..frameScale = size.y * 0.5 / 335;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _sinceLook += dt;
    if (_sinceLook > 1) {
      _sinceLook = 0;
      _applyLook();
    }
  }
}
