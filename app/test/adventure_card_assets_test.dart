import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const variants = [
    'relic_common',
    'relic_rare',
    'relic_epic',
    'talent_claw',
    'talent_shadow',
    'talent_magic',
  ];

  test('every Adventure pick type has a collectible card frame', () {
    for (final variant in variants) {
      final file = File('assets/game/story/cards_v2/card_$variant.png');
      expect(file.existsSync(), isTrue, reason: file.path);
    }
  });

  test('card frames remain compact enough for the mobile bundle', () {
    final files = Directory('assets/game/story/cards_v2')
        .listSync()
        .whereType<File>()
        .toList();
    expect(files, hasLength(variants.length));
    expect(files.fold<int>(0, (sum, file) => sum + file.lengthSync()),
        lessThan(1800000));
  });
}
