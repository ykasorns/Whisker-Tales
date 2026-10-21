import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/craft_sheet.dart';
import 'package:wt_core/wt_core.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// Knit sheet (D-010) edge cases from the 2026-10-21 review: closing on the
/// compare card, and auto-knit racing the sheet.
void main() {
  late GameContent content;
  setUpAll(
      () async => content = await ContentRepository(DiskSource()).loadAll());

  /// The yarn ball bobs forever, so pumpAndSettle never settles.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<ProviderContainer> open(WidgetTester tester) async {
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
    ]);
    addTearDown(c.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
        home: LangScope(
          lang: 'th',
          child: Scaffold(
            body: Consumer(
              builder: (context, ref, _) => TextButton(
                  onPressed: () => showCraftSheet(context, ref),
                  child: const Text('open')),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    return c;
  }

  Future<void> knitFirstSlot(WidgetTester tester) async {
    await tester.tap(find
        .descendant(of: find.byType(Wrap), matching: find.byType(Image))
        .first);
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 500));
  }

  testWidgets('closing on the compare card keeps or recycles the knit',
      (tester) async {
    final c = await open(tester);
    final basket = c.read(gearBasketProvider);
    final yarn = c.read(walletProvider).balance(Currency.yarn);
    await knitFirstSlot(tester);
    expect(c.read(walletProvider).balance(Currency.yarn), yarn - 1);
    expect(basket.isPending('g1'), isTrue);
    await tester.tap(find.byIcon(Icons.close));
    await settle(tester);
    expect(find.byType(BottomSheet), findsNothing);
    expect(basket.isPending('g1'), isFalse);
    // nothing worn yet, so the first knit is a keeper: waiting with ✨
    expect(basket.stashed(GearSlot.weapon)?.id, 'g1');
  });

  testWidgets('auto-knit waits while the sheet is open', (tester) async {
    final c = await open(tester);
    final auto = c.read(autoCraftProvider)..start();
    final wallet = c.read(walletProvider);
    final yarn = wallet.balance(Currency.yarn);
    expect(auto.held, isTrue);
    auto.tick(c.read(gearRulesProvider).autoCraftIntervalMs * 5);
    expect(wallet.balance(Currency.yarn), yarn); // the sheet's yarn is safe
    await knitFirstSlot(tester);
    expect(wallet.balance(Currency.yarn), yarn - 1);
    // dismissed by tapping outside: still settled, auto-knit carries on
    await tester.tapAt(const Offset(10, 10));
    await settle(tester);
    expect(auto.held, isFalse);
    expect(c.read(gearBasketProvider).isPending('g1'), isFalse);
    auto.tick(c.read(gearRulesProvider).autoCraftIntervalMs);
    expect(wallet.balance(Currency.yarn), yarn - 2);
  });
}
