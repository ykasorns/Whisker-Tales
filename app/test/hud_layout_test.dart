import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/game_view.dart';
import 'package:whisker_tales/main.dart';
import 'package:whisker_tales/ui/frames.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';
import 'package:wt_core/wt_core.dart';

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// D-059: the painted frames keep their proportions, text stays in their
/// paper, and the HUD never reaches Mochi's health bar or the wallet.
void main() {
  late GameContent content;
  setUpAll(() async {
    content = await ContentRepository(_Disk()).loadAll();
    await IconRegistry.load();
    await BasketArt.load();
    await FrameArt.load();
  });

  test('frame data matches the shipped pictures', () {
    expect(FrameArt.specs.keys,
        containsAll(['profile', 'currency', 'chapter', 'action', 'dock']));
    for (final e in FrameArt.specs.entries) {
      final s = e.value;
      final im = FrameArt.image(s);
      expect(im, isNotNull, reason: '${s.asset} missing');
      // a re-cropped picture shifts every measured rect: re-measure it
      expect([im!.width, im.height], [s.w.toInt(), s.h.toInt()],
          reason: '${e.key}: ${s.asset} changed size');
      final all = Rect.fromLTWH(0, 0, s.w, s.h);
      for (final r in [s.content, ...s.rects.values, ...s.slots]) {
        expect(all.contains(r.topLeft) && all.contains(r.bottomRight), isTrue,
            reason: '${e.key}: a rect leaves the picture');
      }
      expect(s.capL + s.capR, lessThan(s.w));
    }
    expect(FrameArt.spec('dock').slots, hasLength(5));
  });

  test('only the middle stretches: caps keep the height ratio', () {
    final s = FrameArt.spec('currency');
    final g = FrameGeometry(s, const Size(200, 31));
    expect(g.x(s.capL), closeTo(s.capL * 31 / s.h, 1e-6));
    expect(200 - g.x(s.w - s.capR), closeTo(s.capR * 31 / s.h, 1e-6));
    // the paper area grows with the width, so a longer text has room
    final wide = FrameGeometry(s, const Size(260, 31)).content.width;
    expect(wide, greaterThan(g.content.width));
  });

  for (final lang in ['th', 'en']) {
    for (final size in const [
      Size(320, 640),
      Size(360, 728),
      Size(393, 851),
      Size(412, 915),
    ]) {
      testWidgets(
          'HUD and dock keep clear, ${size.width.toInt()}×'
          '${size.height.toInt()} $lang', (tester) async {
        final c = ProviderContainer(overrides: [
          ...content.overrides,
          saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
        ]);
        addTearDown(c.dispose);
        c.read(ageGateProvider).setBand(AgeBand.under13);
        tester.view.physicalSize = size * 2.5;
        tester.view.devicePixelRatio = 2.5;
        addTearDown(tester.view.reset);
        await tester.runAsync(() async {
          await tester.pumpWidget(UncontrolledProviderScope(
              container: c,
              child: WhiskerTalesApp(avatarRules: content.avatar, lang: lang)));
          await Future<void>.delayed(const Duration(seconds: 2));
        });
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull); // no overflow anywhere

        final sceneTop = tester.getTopLeft(find.byType(GameView)).dy;
        final sceneH = tester.getSize(find.byType(GameView)).height;
        final barTop = sceneTop +
            sceneH * (BattleGame.groundFrac - BattleGame.mochiBarFrac);
        final cluster = find.byKey(const Key('hud-cluster'));
        // room for Mochi's status icons above his bar
        expect(
            tester.getBottomRight(cluster).dy, lessThanOrEqualTo(barTop - 28),
            reason: 'the top-left HUD reaches Mochi\'s health bar');
        expect(
            tester.getBottomRight(find.byKey(const Key('hud-profile'))).dx,
            lessThanOrEqualTo(
                tester.getTopLeft(find.byKey(const Key('hud-wallet'))).dx),
            reason: 'profile runs under the wallet');
        expect(tester.getTopLeft(cluster).dx, greaterThanOrEqualTo(0));

        // the dock: five tabs side by side, each inside the dock
        final tabs = find.byWidgetPredicate((w) =>
            w is Semantics &&
            w.properties.button == true &&
            w.properties.selected != null);
        expect(tabs, findsNWidgets(5));
        final rects = [
          for (var i = 0; i < 5; i++)
            tester.getTopLeft(tabs.at(i)) & tester.getSize(tabs.at(i)),
        ];
        for (var i = 0; i < 4; i++) {
          expect(rects[i].right, lessThanOrEqualTo(rects[i + 1].left + .5));
        }
        expect(rects.first.left, greaterThan(0));
        expect(rects.last.right, lessThan(size.width));
      });
    }
  }
}
