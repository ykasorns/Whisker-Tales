import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/palette.dart';

/// Regression: the UI kit's nine-slices once passed `centerSlice` in source
/// pixels although Flutter wants it in logical units (px / scale). On a phone
/// the whole picture then drew unstretched in the box's corner, and the
/// goldens did not notice. Flutter's rule: the slice, times `scale`, must be
/// a real rectangle strictly inside the picture, with a border on each side.
void main() {
  (int, int) pngSize(String path) {
    final b = ByteData.sublistView(Uint8List.fromList(
        File(path).openSync().readSync(24)));
    return (b.getUint32(16), b.getUint32(20));
  }

  final cases = <String, BoxDecoration Function()>{
    'card': () => storybookCard(radius: 14),
    'tile': () => storybookCard(radius: 8),
    'button yellow': () => storybookButton(fill: const Color(0xFFFFD77F)),
    'button green': () => storybookButton(fill: const Color(0xFF8CC152)),
    'button purple': () => storybookButton(fill: const Color(0xFF7A5E8C)),
    'button coral': () => storybookButton(fill: const Color(0xFFEE6352)),
    'button disabled': () =>
        storybookButton(fill: const Color(0xFFFFD77F), enabled: false),
    'dialog': kitDialogDecoration,
  };

  for (final c in cases.entries) {
    test('${c.key}: centerSlice is in logical units inside the picture', () {
      final img = c.value().image!;
      final name = (img.image as AssetImage).assetName;
      final (w, h) = pngSize(name);
      final s = img.centerSlice!;
      final px = Rect.fromLTRB(s.left * img.scale, s.top * img.scale,
          s.right * img.scale, s.bottom * img.scale);
      expect(px.left, greaterThan(0), reason: name);
      expect(px.top, greaterThan(0), reason: name);
      expect(px.right, lessThan(w), reason: name);
      expect(px.bottom, lessThan(h), reason: name);
      expect(px.width, greaterThan(0), reason: name);
      expect(px.height, greaterThan(0), reason: name);
    });
  }
}
