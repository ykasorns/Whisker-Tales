import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/l10n/strings.dart';
import 'package:whisker_tales/ui/pages.dart';
import 'package:whisker_tales/ui/shop.dart';
import 'package:wt_core/wt_core.dart';

class DiskSource implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}

/// Sells what it is given; a purchase arrives at once.
class FakeStore implements IapStore {
  final bought = <String>[];
  void Function(StoreEvent)? _h;
  @override
  set handler(void Function(StoreEvent) h) => _h = h;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<List<StoreProduct>> products(Set<String> skus) async => [
        for (final s in skus) StoreProduct(sku: s, title: s, price: '฿99.00'),
      ];
  @override
  Future<bool> buy(String sku) async {
    bought.add(sku);
    _h?.call(StoreEvent(StoreEventKind.purchased, sku));
    return true;
  }

  @override
  Future<void> restore() async {}
}

/// T-025 AC: buying is impossible without the parental gate, at every
/// entry point.
void main() {
  late GameContent content;
  setUpAll(
      () async => content = await ContentRepository(DiskSource()).loadAll());

  final words = {for (var n = 0; n < 100; n++) englishNumber(n): n};
  int answerOf(WidgetTester tester) {
    final q = tester.widget<Text>(find.byKey(const ValueKey('gate-question')));
    final m = RegExp(r'What is (.+) times (.+)\?').firstMatch(q.data!)!;
    return words[m.group(1)]! * words[m.group(2)]!;
  }

  Future<void> type(WidgetTester tester, String digits) async {
    for (final d in digits.split('')) {
      await tester.tap(find.text(d).last);
      await tester.pump();
    }
    await tester.tap(find.text('✓'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<(ProviderContainer, FakeStore)> shop(WidgetTester tester) async {
    final store = FakeStore();
    final c = ProviderContainer(overrides: [
      ...content.overrides,
      saveServiceProvider.overrideWithValue(SaveService(MemorySaveStore())),
      iapStoreProvider.overrideWithValue(store),
    ]);
    addTearDown(c.dispose);
    c.read(iapServiceProvider)!.start();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: c,
      child: MaterialApp(
          builder: (_, child) => LangScope(lang: 'en', child: child!),
          home: const Scaffold(body: ShopPage())),
    ));
    await tester.tap(find.text('👨‍👩‍👧 ${S.en.askParent}'));
    await tester.pump(const Duration(milliseconds: 300));
    return (c, store);
  }

  testWidgets('the shop opens on the gate; a wrong answer gets a new question',
      (tester) async {
    final (c, store) = await shop(tester);
    expect(find.byKey(const ValueKey('gate-question')), findsOneWidget);
    expect(find.byType(ShopSheet), findsNothing);
    final right = answerOf(tester);
    await type(tester, '${right + 1}');
    expect(find.text(S.en.gateWrong), findsOneWidget);
    expect(find.byType(ShopSheet), findsNothing); // still the gate
    // closing the gate opens nothing
    await tester.tap(find.text(S.en.cancel));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShopSheet), findsNothing);
    expect(store.bought, isEmpty);
    expect(c.read(iapServiceProvider)!.owned, isEmpty);
  });

  testWidgets('right answer → shop; buying the Supporter Pack hides ads',
      (tester) async {
    final (c, store) = await shop(tester);
    await type(tester, '${answerOf(tester)}');
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(ShopSheet), findsOneWidget);
    expect(find.text('Supporter Pack'), findsOneWidget);
    await tester.tap(find.text('฿99.00'));
    await tester.pump();
    await tester.pump();
    expect(store.bought, ['supporter_pack']);
    expect(c.read(noAdsProvider)(), isTrue);
    expect(c.read(adServiceProvider).canShow('pet_hatch'), isFalse);
    expect(find.text(S.en.owned), findsOneWidget);
  });

  test('the shop sheet and purchase calls exist only behind openShop', () {
    for (final f
        in Directory('lib').listSync(recursive: true).whereType<File>()) {
      final src = f.readAsStringSync();
      final path = f.path.replaceAll('\\', '/');
      if (path.endsWith('ui/shop.dart')) continue;
      expect(src.contains('ShopSheet('), isFalse, reason: path);
      expect(RegExp(r'\.purchase\(').hasMatch(src), isFalse, reason: path);
      expect(src.contains('.restore(') && src.contains('iap'), isFalse,
          reason: path);
    }
    final shop = File('lib/ui/shop.dart').readAsStringSync();
    // the sheet is only built after the gate gave a pass
    final open = shop.indexOf('Future<void> openShop');
    expect(shop.indexOf('showParentalGate(context, ref)', open),
        lessThan(shop.indexOf('ShopSheet(pass: pass)', open)));
  });
}
