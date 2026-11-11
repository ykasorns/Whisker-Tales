import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const styles = ['normal', 'skill', 'crit', 'hurt'];
  const glyphs = [
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    'plus',
    'minus',
  ];

  test('all damage-number styles publish every glyph', () {
    for (final style in styles) {
      for (final glyph in glyphs) {
        final file = File('assets/game/damage_numbers/${style}_$glyph.png');
        expect(file.existsSync(), isTrue, reason: file.path);
      }
    }
  });

  test('damage glyphs stay compact enough for the mobile bundle', () {
    final files = Directory('assets/game/damage_numbers')
        .listSync()
        .whereType<File>()
        .toList();
    expect(files, hasLength(48));
    expect(files.fold<int>(0, (sum, file) => sum + file.lengthSync()),
        lessThan(600000));
  });
}
