import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

class Time implements TimeSource {
  Time(this.utc);
  DateTime utc;
  @override
  DateTime nowUtc() => utc;
  @override
  Duration utcOffset() => const Duration(hours: 7);
}

/// Test store: sells everything in [prices]; [buy] answers at once unless
/// [pendingFirst] (payment confirmed later, like cash at a shop).
class FakeIapStore implements IapStore {
  FakeIapStore(this.prices);
  final Map<String, String> prices;
  bool open = true;
  bool pendingFirst = false;
  final bought = <String>{};
  final _queue = <StoreEvent>[];
  void Function(StoreEvent)? _h;

  void emit(StoreEvent e) => _h == null ? _queue.add(e) : _h!(e);

  @override
  set handler(void Function(StoreEvent) h) {
    _h = h;
    _queue
      ..forEach(h)
      ..clear();
  }

  @override
  Future<bool> isAvailable() async => open;
  @override
  Future<List<StoreProduct>> products(Set<String> skus) async => [
        for (final e in prices.entries)
          if (skus.contains(e.key))
            StoreProduct(sku: e.key, title: e.key, price: e.value),
      ];
  @override
  Future<bool> buy(String sku) async {
    if (!open || !prices.containsKey(sku)) return false;
    if (pendingFirst) {
      emit(StoreEvent(StoreEventKind.pending, sku));
    } else {
      bought.add(sku);
      emit(StoreEvent(StoreEventKind.purchased, sku));
    }
    return true;
  }

  @override
  Future<void> restore() async {
    for (final s in bought) {
      emit(StoreEvent(StoreEventKind.purchased, s));
    }
  }
}

void main() {
  final catalog = IapCatalog.fromJson(_j('../../design/data/iap.json'));
  final t0 = DateTime.utc(2026, 10, 21, 3);
  late Time time;
  late GameClock clock;
  late ParentalGate gate;
  late FakeIapStore store;
  late List<String> granted;
  late IapService iap;

  setUp(() {
    time = Time(t0);
    clock = GameClock(time);
    var n = 0;
    gate = ParentalGate(clock: clock, random: (max) => (n++ * 7) % max);
    store = FakeIapStore({
      for (final p in catalog.products) p.sku: '฿35.00',
    });
    granted = [];
    iap = IapService(
        catalog: catalog, store: store, gate: gate, grantCosmetics: granted.add)
      ..start();
  });

  GatePass pass() {
    final q = gate.next();
    return gate.answer(q, q.answer)!;
  }

  group('parental gate', () {
    test('questions are grown-up sized, in words, new every time', () {
      final g = ParentalGate(clock: clock);
      final seen = <String>{};
      for (var i = 0; i < 200; i++) {
        final q = g.next();
        expect(q.a, inInclusiveRange(13, 49));
        expect(q.a % 10, isNot(0));
        expect(q.b, inInclusiveRange(3, 9));
        expect(q.words('th'), isNot(contains(RegExp(r'\d'))));
        expect(q.words('en'), isNot(contains(RegExp(r'\d'))));
        seen.add('${q.a}x${q.b}');
      }
      expect(seen.length, greaterThan(100)); // not a fixed short list
    });

    test('number words', () {
      expect(thaiNumber(21), 'ยี่สิบเอ็ด');
      expect(thaiNumber(11), 'สิบเอ็ด');
      expect(thaiNumber(47), 'สี่สิบเจ็ด');
      expect(thaiNumber(301), 'สามร้อยเอ็ด');
      expect(thaiNumber(120), 'หนึ่งร้อยยี่สิบ');
      expect(thaiNumber(7), 'เจ็ด');
      expect(englishNumber(47), 'forty-seven');
      expect(englishNumber(13), 'thirteen');
      expect(englishNumber(305), 'three hundred five');
      expect(const GateQuestion(27, 6).words('th'), 'ยี่สิบเจ็ด คูณ หก');
      expect(const GateQuestion(27, 6).words('en'), 'twenty-seven times six');
    });

    test('only the right answer gives a pass; it runs out', () {
      final q = gate.next();
      expect(gate.answer(q, q.answer + 1), isNull);
      expect(gate.answer(q, null), isNull);
      final p = gate.answer(q, q.answer);
      expect(gate.isValid(p), isTrue);
      time.utc = t0.add(gate.passFor);
      expect(gate.isValid(p), isFalse);
      // a pass from another gate (another game) is no good here
      final other = ParentalGate(clock: clock);
      final q2 = other.next();
      expect(gate.isValid(other.answer(q2, q2.answer)), isFalse);
    });
  });

  group('purchases', () {
    test('no pass, no purchase and no restore', () async {
      expect(
          await iap.purchase('supporter_pack', null), PurchaseStart.needsGate);
      expect(await iap.restore(null), isFalse);
      expect(store.bought, isEmpty);
      final p = pass();
      time.utc = t0.add(const Duration(hours: 1)); // left the shop open
      expect(await iap.purchase('supporter_pack', p), PurchaseStart.needsGate);
    });

    test('Supporter Pack: no_ads, no reward, nothing else', () async {
      expect(iap.hasNoAds, isFalse);
      expect(
          await iap.purchase('supporter_pack', pass()), PurchaseStart.started);
      expect(iap.hasNoAds, isTrue);
      expect(iap.owned, {'supporter_pack'});
      expect(await iap.purchase('supporter_pack', pass()), PurchaseStart.owned);
    });

    test('a cosmetic unlocks its look through the wardrobe only', () async {
      await iap.purchase('skin_pajama', pass());
      expect(granted, ['skin_pajama']);
      expect(iap.hasNoAds, isFalse);
      expect(await iap.purchase('gold_pile', pass()), PurchaseStart.unknown);
    });

    test('delivery needs no gate (already paid) and grants once', () {
      final news = <StoreEvent>[];
      iap.news.listen(news.add);
      expect(iap.deliver('skin_raincoat'), isTrue);
      expect(iap.deliver('skin_raincoat'), isFalse);
      expect(iap.deliver('not_a_sku'), isFalse);
      expect(iap.owned, {'skin_raincoat'});
      expect(
          news.where((e) => e.kind == StoreEventKind.purchased), hasLength(1));
    });

    test('a purchase paid later still arrives; events wait for start()',
        () async {
      store.pendingFirst = true;
      final news = <StoreEvent>[];
      iap.news.listen(news.add);
      expect(
          await iap.purchase('skin_explorer', pass()), PurchaseStart.started);
      expect(news.single.kind, StoreEventKind.pending);
      expect(iap.owned, isEmpty);
      // the payment clears while the app is closed; next boot delivers it
      final store2 = FakeIapStore({})
        ..emit(const StoreEvent(StoreEventKind.purchased, 'skin_explorer'));
      final iap2 = IapService(
          catalog: catalog, store: store2, gate: gate, grantCosmetics: (_) {});
      expect(iap2.owned, isEmpty);
      iap2.start();
      expect(iap2.owned, {'skin_explorer'});
    });

    test('restore brings back everything bought before', () async {
      await iap.purchase('supporter_pack', pass());
      await iap.purchase('skin_pajama', pass());
      final fresh = IapService(
          catalog: catalog, store: store, gate: gate, grantCosmetics: (_) {})
        ..start();
      expect(fresh.owned, isEmpty);
      expect(await fresh.restore(pass()), isTrue);
      expect(fresh.owned, {'supporter_pack', 'skin_pajama'});
      expect(fresh.hasNoAds, isTrue);
    });

    test('a closed store lists nothing and starts nothing', () async {
      store.open = false;
      expect(await iap.products(), isEmpty);
      expect(await iap.purchase('supporter_pack', pass()),
          PurchaseStart.unavailable);
      expect(iap.owned, isEmpty);
      const none = UnavailableIapStore();
      expect(await none.products({'supporter_pack'}), isEmpty);
      expect(await none.buy('supporter_pack'), isFalse);
    });

    test('save keeps owned SKUs; unknown ones are dropped', () async {
      await iap.purchase('supporter_pack', pass());
      final json = jsonDecode(jsonEncode(iap.toJson())) as Map<String, dynamic>;
      expect(json, {
        'no_ads': true,
        'skus': ['supporter_pack']
      });
      final back = IapService(
          catalog: catalog, store: store, gate: gate, grantCosmetics: (_) {})
        ..restoreSaved({
          ...json,
          'skus': ['supporter_pack', 'retired_sku']
        });
      expect(back.owned, {'supporter_pack'});
      expect(back.hasNoAds, isTrue);
    });
  });

  group('catalog never sells gameplay', () {
    test('shipped data: Supporter Pack + cosmetics, no currency', () {
      expect(catalog.products.map((p) => p.sku).toSet(),
          {'supporter_pack', 'skin_pajama', 'skin_raincoat', 'skin_explorer'});
      for (final p in catalog.products) {
        expect(kEntitlements.containsAll(p.entitlements), isTrue);
      }
    });

    test('a SKU that gives currency, power or unknown rights is refused', () {
      Map<String, dynamic> one(Map<String, dynamic> extra) => {
            'products': [
              {
                'sku': 'x',
                'kind': 'cosmetic',
                'name_th': 'x',
                'name_en': 'x',
                'desc_th': 'x',
                'desc_en': 'x',
                ...extra,
              }
            ]
          };
      for (final bad in [
        {'goldfish': 1000},
        {'eggs': 5},
        {'yarn': 50},
        {
          'grants': {'cookies': 3}
        },
        {
          'kind': 'supporter',
          'entitlements': ['no_ads', 'skip_timers']
        },
        {
          'kind': 'supporter',
          'entitlements': ['gear_presets']
        },
        {
          'entitlements': ['no_ads']
        },
        {'kind': 'bundle'},
      ]) {
        expect(() => IapCatalog.fromJson(one(bad)), throwsFormatException,
            reason: '$bad');
      }
    });

    test('the iap module never touches the wallet or currencies', () {
      for (final f in Directory('lib/src/iap').listSync().whereType<File>()) {
        final src = f.readAsStringSync();
        for (final w in [
          'IWallet',
          'Currency.',
          'wallet',
          'goldfish',
          'eggs'
        ]) {
          expect(src.contains(w), isFalse, reason: '${f.path}: $w');
        }
      }
    });
  });
}
