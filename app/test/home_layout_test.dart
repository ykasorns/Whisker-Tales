import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/game_view.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/home_page.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';
import 'package:wt_core/wt_core.dart';

import '_l10n.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// D-040: the gear shelf + switches + basket must fit a big phone and a small
/// one without an overflow, and the basket is a ≥ 72 dp target.
void main() {
  late GameContent content;
  setUpAll(() async {
    content = await ContentRepository(DiskSource()).loadAll();
    await IconRegistry.load();
    await BasketArt.load();
  });

  // panel sizes in dp: a 1080×2340 phone (≈ 411×892), a 720×1280 phone
  // (360×640) and a very small one
  for (final size in const [Size(411, 330), Size(360, 224), Size(320, 190)]) {
    testWidgets('farm panel fits ${size.width.toInt()}×${size.height.toInt()}',
        (tester) async {
      final c = ProviderContainer(overrides: [
        ...content.overrides,
        saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
      ]);
      addTearDown(c.dispose);
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: localized(Scaffold(
          body: Center(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Consumer(
                  builder: (context, ref, _) =>
                      FarmPanel(driver: GameDriver(ref))),
            ),
          ),
        )),
      ));
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull); // no overflow
      final basket = tester.getSize(find.byType(YarnBasket));
      expect(basket.height, greaterThanOrEqualTo(72));
      expect(find.byType(YarnBasket), findsOneWidget);
    });
  }
}
