import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:wt_core/wt_core.dart';

/// Google Play Billing behind [IapStore] (T-025, D-017, D-023). Created at
/// boot so purchases that finished while the app was closed (or were paid
/// later) are delivered; every delivered purchase is acknowledged, or Play
/// refunds it. Events wait here until the game sets a handler.
class PlayIapStore implements IapStore {
  PlayIapStore([InAppPurchase? iap]) : _iap = iap ?? InAppPurchase.instance {
    _sub = _iap.purchaseStream.listen(_onPurchases, onError: (_) {});
  }

  final InAppPurchase _iap;
  late final StreamSubscription<List<PurchaseDetails>> _sub;
  final _details = <String, ProductDetails>{};
  final _waiting = <StoreEvent>[];
  void Function(StoreEvent)? _handler;

  @override
  set handler(void Function(StoreEvent) h) {
    _handler = h;
    final queued = [..._waiting];
    _waiting.clear();
    queued.forEach(h);
  }

  void _emit(StoreEvent e) {
    final h = _handler;
    h == null ? _waiting.add(e) : h(e);
  }

  Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      final kind = switch (p.status) {
        PurchaseStatus.purchased ||
        PurchaseStatus.restored =>
          StoreEventKind.purchased,
        PurchaseStatus.pending => StoreEventKind.pending,
        PurchaseStatus.error => StoreEventKind.failed,
        PurchaseStatus.canceled => StoreEventKind.canceled,
      };
      _emit(StoreEvent(kind, p.productID));
      // granted above (synchronously), so it is safe to acknowledge now
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }

  @override
  Future<bool> isAvailable() => _iap.isAvailable();

  @override
  Future<List<StoreProduct>> products(Set<String> skus) async {
    final r = await _iap.queryProductDetails(skus);
    for (final p in r.productDetails) {
      _details[p.id] = p;
    }
    return [
      for (final p in r.productDetails)
        StoreProduct(sku: p.id, title: p.title, price: p.price),
    ];
  }

  Future<ProductDetails?> _detail(String sku) async {
    final known = _details[sku];
    if (known != null) return known;
    final r = await _iap.queryProductDetails({sku});
    for (final p in r.productDetails) {
      _details[p.id] = p;
    }
    return _details[sku];
  }

  /// Every SKU is non-consumable (bought once, kept for good).
  @override
  Future<bool> buy(String sku) async {
    final d = await _detail(sku);
    if (d == null) return false;
    return _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: d));
  }

  @override
  Future<void> restore() => _iap.restorePurchases();

  Future<void> dispose() => _sub.cancel();
}
