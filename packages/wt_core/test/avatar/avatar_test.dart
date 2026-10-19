import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

const _app = '../../app/assets/game';

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

/// PNG width/height straight from the IHDR header.
(double, double) pngSize(String path) {
  final b = File(path).readAsBytesSync();
  final d = ByteData.sublistView(b);
  return (d.getUint32(16).toDouble(), d.getUint32(20).toDouble());
}

Future<ui.Image> decode(String path) async {
  final codec = await ui.instantiateImageCodec(File(path).readAsBytesSync());
  return (await codec.getNextFrame()).image;
}

void main() {
  final rules = AvatarRules.fromJson(_j('../../design/art/anchors_mochi.json'));
  final wardrobe =
      WardrobeRules.fromJson(_j('../../design/data/wardrobe.json'));
  (double, double) size(String art) => pngSize('$_app/gear/$art.png');
  const classes = ['warrior', 'rogue', 'archer', 'mage'];

  AvatarLook fullLook(String cls) => AvatarLook(
        weapon: '${wardrobe.weaponArt[cls]}_2',
        offHand: wardrobe.offHandArt[cls] == null
            ? null
            : '${wardrobe.offHandArt[cls]}_2',
        hat: 'hat_2',
        scarf: 'scarf_2',
        bag: 'bag_2',
      );

  test('anchors load: 12 anchored frames, gear grips, ground pad = slicer PAD',
      () {
    expect(rules.frames, hasLength(12));
    expect(
        rules.gear.keys,
        containsAll([
          'sword',
          'staff',
          'hat',
          'scarf',
          'bag',
          'shield',
          'dagger',
          'bow'
        ]));
    final slicer =
        File('../../tools/sprite_slicer/slice_sheet.py').readAsStringSync();
    expect(slicer, contains('PAD = ${rules.groundPadPx.toInt()}'));
  });

  test('layout matches the prototype fit tool for every frame × class', () {
    final expected = _j('test/avatar/layout_expected.json');
    expect(expected, hasLength(48));
    for (final e in expected.entries) {
      final [frame, cls] = e.key.split('|');
      final got = layoutAvatar(rules, frame, fullLook(cls), size);
      final want = e.value as List;
      expect(got, hasLength(want.length), reason: e.key);
      for (var i = 0; i < want.length; i++) {
        final w = want[i] as Map<String, dynamic>, g = got[i];
        final why = '${e.key} op $i';
        switch (w['op']) {
          case 'cat':
            expect(g, isA<DrawCat>(), reason: why);
          case 'gear':
            g as DrawGear;
            expect(g.image, w['image'], reason: why);
            for (final (k, v) in [
              ('x', g.x),
              ('y', g.y),
              ('w', g.w),
              ('h', g.h),
              ('gx', g.gx),
              ('gy', g.gy),
              ('deg', g.deg)
            ]) {
              expect(v, closeTo((w[k] as num).toDouble(), 0.01),
                  reason: '$why $k');
            }
          case 'restamp':
            g as RestampCat;
            if (w['circle'] case final List c) {
              expect(
                  g.circle,
                  (
                    (c[0] as num).toDouble(),
                    (c[1] as num).toDouble(),
                    (c[2] as num).toDouble()
                  ),
                  reason: why);
            } else {
              expect(
                  g.polygon,
                  [
                    for (final p in w['poly'] as List)
                      ((p[0] as num).toDouble(), (p[1] as num).toDouble())
                  ],
                  reason: why);
            }
        }
      }
    }
  });

  test('only shown gear is drawn; frames without anchors draw the cat', () {
    final bare = layoutAvatar(rules, 'idle', const AvatarLook(), size);
    expect(bare, [isA<DrawCat>()]);
    final hatOnly =
        layoutAvatar(rules, 'idle', const AvatarLook(hat: 'hat_3'), size);
    expect(hatOnly.whereType<DrawGear>().map((g) => g.image), ['hat_3']);
    expect(
        layoutAvatar(rules, 'sleep', fullLook('mage'), size), [isA<DrawCat>()]);
    // dodge / hurt keep the weapon behind the body
    final dodge = layoutAvatar(rules, 'dodge', fullLook('mage'), size);
    final cat = dodge.indexWhere((o) => o is DrawCat);
    final staff =
        dodge.indexWhere((o) => o is DrawGear && o.image == 'staff_2');
    expect(staff, lessThan(cat));
  });

  test('component: anims, gear, class and skin change in place', () async {
    final images = <String, ui.Image>{
      for (final f in [
        'idle',
        'walk_f1',
        'walk_f2',
        'walk_f3',
        'bare_mage',
        'bare_rogue'
      ])
        'base/$f': await decode('$_app/cat/$f.png'),
      'gear/staff_2': await decode('$_app/gear/staff_2.png'),
    };
    final c = AvatarComponent(
        rules: rules, images: (k) => images[k], classId: 'mage');
    expect(c.frame, 'idle');
    c.play('walk');
    final seen = <String>[];
    for (var i = 0; i < 4; i++) {
      seen.add(c.frame);
      c.update(1 / AvatarComponent.walkFps);
    }
    expect(seen, AvatarComponent.walkCycle);
    c.play('attack');
    expect(c.frame, 'bare_mage');
    c.setClass('rogue');
    expect(c.frame, 'bare_rogue');
    c.setGear('weapon', 'staff_2');
    expect(c.ops.whereType<DrawGear>().single.image, 'staff_2');
    c.setGear('weapon', null);
    expect(c.ops.whereType<DrawGear>(), isEmpty);
    expect(() => c.play('dance'), throwsArgumentError);
    expect(() => c.setGear('cape', 'x'), throwsArgumentError);
    // renders without throwing, missing images are skipped
    final rec = ui.PictureRecorder();
    c.render(ui.Canvas(rec));
    rec.endRecording();
  });

  group('golden: 13 frames × 4 classes (tier 2, all gear)', () {
    late Map<String, ui.Image> imgs;
    setUpAll(() async {
      imgs = {};
      for (final f in Directory('$_app/cat').listSync().whereType<File>()) {
        imgs['base/${f.uri.pathSegments.last.replaceAll('.png', '')}'] =
            await decode(f.path);
      }
      for (final f in Directory('$_app/gear').listSync().whereType<File>()) {
        imgs['gear/${f.uri.pathSegments.last.replaceAll('.png', '')}'] =
            await decode(f.path);
      }
    });
    const frames = [
      'idle',
      'walk_f1',
      'walk_f2',
      'walk_f3',
      'dodge',
      'hurt',
      'victory',
      'sleep',
      'bare_warrior',
      'bare_rogue',
      'bare_archer',
      'bare_mage',
      'bare_novice',
    ];
    for (final cls in classes) {
      testWidgets(cls, (tester) async {
        final rec = ui.PictureRecorder();
        final canvas = ui.Canvas(rec);
        const cw = 300.0, ch = 260.0;
        for (var i = 0; i < frames.length; i++) {
          final frame = imgs['base/${frames[i]}']!;
          final ops = layoutAvatar(rules, frames[i], fullLook(cls), size);
          final origin = ui.Offset((i % 5) * cw, (i ~/ 5) * ch);
          paintAvatar(canvas, ops, frame, (a) => imgs['gear/$a'],
              origin: origin + const ui.Offset(30, 30), scale: 0.6);
        }
        final image = await rec.endRecording().toImage(1500, 780);
        await expectLater(image, matchesGoldenFile('goldens/avatar_$cls.png'));
      });
    }
  });
}
