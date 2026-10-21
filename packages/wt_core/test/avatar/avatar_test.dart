import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// Mochi in the class outfit (D-024): one image per frame, looked up as
/// `<class>/<frame>`; gear is never drawn on the cat.
void main() {
  final rules = AvatarRules.fromJson(
      jsonDecode(File('../../design/art/mochi_sprites.json').readAsStringSync())
          as Map<String, dynamic>);

  test('data: frames, classes, ground line', () {
    expect(rules.frames, containsAll(['idle', 'walk_f1', 'attack', 'sleep']));
    expect(rules.classes,
        containsAll(['novice', 'warrior', 'rogue', 'archer', 'mage']));
    expect(rules.groundPadPx, 12);
    expect(
        () => AvatarRules.fromJson({
              'frames': ['idle'],
              'classes': ['novice'],
              'ground_pad_px': 0
            }),
        throwsFormatException);
  });

  test('frames by animation and class; walking cycles', () {
    final asked = <String>[];
    final c = AvatarComponent(
        rules: rules,
        images: (k) {
          asked.add(k);
          return null;
        });
    expect(c.imageKey, 'novice/idle');
    c
      ..setClass('mage')
      ..play('attack');
    expect(c.imageKey, 'mage/attack');
    c.play('walk');
    final seen = <String>{};
    for (var i = 0; i < 8; i++) {
      seen.add(c.frame);
      c.update(1 / AvatarComponent.walkFps);
    }
    expect(seen, {'walk_f1', 'walk_f2', 'walk_f3'});
    expect(() => c.play('dance'), throwsArgumentError);
  });
}
