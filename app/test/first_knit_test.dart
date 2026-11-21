import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/main.dart';
import 'package:whisker_tales/ui/frames.dart';
import 'package:whisker_tales/ui/game_icon.dart';
import 'package:whisker_tales/ui/home_page.dart';
import 'package:whisker_tales/ui/yarn_basket.dart';
import 'package:wt_core/wt_core.dart';

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// T-049: a new game points at the basket without words; the first tap knits
/// the onboarding slot, wears it and flies it into its slot. Auto-knit and
/// its "better" switch stay hidden until auto-knit opens.
void main() {
  late GameContent content;
  setUpAll(() async {
    content = await ContentRepository(_Disk()).loadAll();
    await IconRegistry.load();
    await BasketArt.load();
    await FrameArt.load();
  });

  /// The game as a save would load it: [cleared] pages, [worn] slots knitted.
  Future<ProviderContainer> boot(WidgetTester tester, String lang,
      {int cleared = 0, List<GearSlot> worn = const []}) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(c.dispose);
    c.read(ageGateProvider).setBand(AgeBand.under13);
    if (cleared > 0) {
      final saver = c.read(gameSaverProvider);
      final doc = saver.capture();
      (doc['idle'] as Map<String, dynamic>)['cleared_page'] = cleared;
      saver.restore(doc);
    }
    final basket = c.read(gearBasketProvider);
    for (final slot in worn) {
      basket.equip(basket.craft(slot).item.id);
    }
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);
    await tester.runAsync(() async {
      await tester.pumpWidget(UncontrolledProviderScope(
          container: c,
          child: WhiskerTalesApp(avatarRules: content.avatar, lang: lang)));
      await Future<void>.delayed(const Duration(seconds: 2));
    });
    await tester.pump(const Duration(milliseconds: 300));
    return c;
  }

  Future<void> settle(WidgetTester tester) async {
    for (var k = 0; k < 3; k++) {
      await tester.pump(const Duration(milliseconds: 200));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 500)));
    }
    await tester.pump(const Duration(milliseconds: 100));
  }

  final basketButton = find.byWidgetPredicate((w) =>
      w is Semantics &&
      w.properties.button == true &&
      (w.properties.label == 'ถักของ' || w.properties.label == 'Knit'));
  final pointer = find.byKey(const Key('first-knit-pointer'));
  final autoKnit = find.byWidgetPredicate(
      (w) => w.runtimeType.toString() == '_AutoKnitToggle');

  for (final lang in ['th', 'en']) {
    testWidgets('first knit: point, knit, wear, fly ($lang)', (tester) async {
      final c = await boot(tester, lang);
      final app = find.byType(WhiskerTalesApp);
      final rules = c.read(idleRulesProvider);
      final basket = c.read(gearBasketProvider);

      // a new game: the pointer, and no auto-knit switches yet
      expect(pointer, findsOneWidget);
      expect(autoKnit, findsNothing);
      await settle(tester);
      await expectLater(
          app, matchesGoldenFile('goldens/onboarding/${lang}_pointer.png'));

      // the first tap knits the onboarding slot and wears it: no sheet
      await tester.tap(basketButton);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(BottomSheet), findsNothing);
      expect(basket.equipped(rules.firstKnitSlot), isNotNull);
      expect(c.read(gameSaverProvider).profileFlags, contains(firstKnitFlag));
      expect(find.byKey(const Key('first-knit-flight')), findsOneWidget);
      expect(pointer, findsNothing);

      // it lands in its slot, which bounces with a sparkle
      await tester.pump(const Duration(milliseconds: 1000));
      expect(find.byKey(const Key('first-knit-flight')), findsNothing);
      expect(find.byKey(const Key('first-knit-sparkle')), findsOneWidget);
      await settle(tester);
      expect(tester.takeException(), isNull);
      await expectLater(
          app, matchesGoldenFile('goldens/onboarding/${lang}_worn.png'));

      // from now on the basket opens the knit sheet as before
      await tester.tap(basketButton);
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 200));
      }
      expect(find.byType(BottomSheet), findsOneWidget);
    });
  }

  testWidgets('the first-knit flag is saved and stops the pointer',
      (tester) async {
    final c = await boot(tester, 'en');
    await tester.tap(basketButton);
    await tester.pump(const Duration(milliseconds: 1500));
    final doc = c.read(gameSaverProvider).capture();
    expect((doc['profile'] as Map)['flags'], contains(firstKnitFlag));

    final again = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(again.dispose);
    again.read(gameSaverProvider).restore(doc);
    expect(again.read(gameSaverProvider).profileFlags, contains(firstKnitFlag));
  });

  testWidgets('a save past the auto-knit page: no pointer, switches shown',
      (tester) async {
    final c = await boot(tester, 'en', cleared: 6);
    expect(c.read(idleRulesProvider).autoKnitUnlockPage, lessThanOrEqualTo(6));
    expect(pointer, findsNothing);
    expect(autoKnit, findsOneWidget);
  });

  testWidgets('an early save with gear worn: no pointer, switches hidden',
      (tester) async {
    await boot(tester, 'en', cleared: 2, worn: const [GearSlot.weapon]);
    expect(pointer, findsNothing);
    expect(autoKnit, findsNothing);
  });

  test('onboarding values come from the balance data', () async {
    final rules = ProviderContainer(overrides: content.overrides);
    addTearDown(rules.dispose);
    final r = rules.read(idleRulesProvider);
    expect(r.firstKnitSlot, GearSlot.hat);
    expect(r.autoKnitUnlockPage, 5);
  });
}
