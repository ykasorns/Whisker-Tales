import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const skills = [
    'shield_bash',
    'iron_wall',
    'war_cry',
    'twin_strike',
    'poison_blade',
    'shadow_step',
    'power_shot',
    'arrow_rain',
    'eagle_eye',
    'fireball',
    'frost_nova',
    'meteor',
  ];

  test('all class skills publish eight animation frames', () {
    for (final skill in skills) {
      for (var frame = 1; frame <= 8; frame++) {
        final number = frame.toString().padLeft(2, '0');
        final file = File('assets/game/skill_fx/${skill}_$number.png');
        expect(file.existsSync(), isTrue, reason: file.path);
      }
    }
  });

  test('no obsolete prototype frames ship in the app', () {
    final names = Directory('assets/game/skill_fx')
        .listSync()
        .whereType<File>()
        .map((file) => file.path);
    expect(names.any((name) => name.contains('_v1_')), isFalse);
  });
}
