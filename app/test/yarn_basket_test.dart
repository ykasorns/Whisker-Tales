import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';

/// D-040: the basket shows its balls inside it, and a knit makes the balls
/// hop and one leap out and come back.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await BasketArt.load();
  });

  Future<void> precache(WidgetTester tester) async {
    final ctx = tester.element(find.byType(YarnBasket));
    await tester.runAsync(() async {
      await precacheImage(const AssetImage('assets/game/home/basket.png'), ctx);
      for (final b in BasketArt.balls) {
        await precacheImage(AssetImage('assets/game/home/${b.asset}.png'), ctx);
      }
    });
    await tester.pump();
  }

  Widget host(int knit, {bool quiet = false, bool empty = false}) =>
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xFFFFFBF2),
          body: Center(
              child: RepaintBoundary(
                  child: YarnBasket(
                      height: 220, knit: knit, quiet: quiet, empty: empty))),
        ),
      );

  testWidgets('art is in the bundle and the layout data is sane',
      (tester) async {
    expect(BasketArt.ready, isTrue);
    expect(BasketArt.balls.length, greaterThanOrEqualTo(5));
    expect(BasketArt.opening.width, inInclusiveRange(0.4, 0.9));
    expect(BasketArt.opening.height, inInclusiveRange(0.2, 0.6));
    for (final b in BasketArt.balls) {
      expect(b.x, inInclusiveRange(0.1, 0.9));
      expect(b.y, inInclusiveRange(0.1, 0.6));
    }
  });

  testWidgets('idle, mid-knit and after: goldens', (tester) async {
    await tester.pumpWidget(host(0));
    await precache(tester);
    await expectLater(find.byType(YarnBasket),
        matchesGoldenFile('goldens/yarn_basket_idle.png'));
    await tester.pumpWidget(host(1));
    await tester.pump(const Duration(milliseconds: 380));
    await expectLater(find.byType(YarnBasket),
        matchesGoldenFile('goldens/yarn_basket_knit.png'));
    await tester.pump(const Duration(milliseconds: 900));
    // the ball is back in the basket and the animation has finished
    await expectLater(find.byType(YarnBasket),
        matchesGoldenFile('goldens/yarn_basket_after.png'));
    await tester.pumpWidget(host(1, empty: true));
    await tester.pump();
    await expectLater(find.byType(YarnBasket),
        matchesGoldenFile('goldens/yarn_basket_empty.png'));
  });
}
