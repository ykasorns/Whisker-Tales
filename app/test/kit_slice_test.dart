import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/kit_specs.g.dart';
import 'package:whisker_tales/ui/palette.dart';

/// Regression: the UI kit's nine-slices once passed `centerSlice` in source
/// pixels although Flutter wants it in logical units (px / scale). On a phone
/// the whole picture then drew unstretched in the box's corner, and the
/// goldens did not notice. Flutter's rule: the slice, times `scale`, must be
/// a real rectangle strictly inside the picture, with a border on each side.
void main() {
  (int, int) pngSize(String path) {
    final b = ByteData.sublistView(
        Uint8List.fromList(File(path).openSync().readSync(24)));
    return (b.getUint32(16), b.getUint32(20));
  }

  // every stretch piece, straight from its decoration
  for (final name in kitSpecs.keys) {
    final k = kitSpecs[name]!;
    if (k.left == 0 && k.right == k.w) continue; // drawn whole
    test('$name: centerSlice is in logical units inside the picture', () {
      final img = kitDecoration(name).image!;
      final file = (img.image as AssetImage).assetName;
      final (w, h) = pngSize(file);
      expect((w, h), (k.w.toInt(), k.h.toInt()),
          reason: 'kit_specs.g.dart is stale: run tools/sync_sprites.py');
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
