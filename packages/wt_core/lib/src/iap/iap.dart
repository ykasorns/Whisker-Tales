import 'dart:async';

import 'parental_gate.dart';

export 'parental_gate.dart';

/// Things a purchase may switch on besides cosmetics (D-003). Anything else
/// in the data is refused: no currency, eggs, speed-ups or power for money.
const kEntitlements = {'no_ads', 'gear_presets', 'basket_theme'};

/// Only the Supporter Pack for now; outfits come back as a kind when every
/// class has its art (D-024).
enum IapKind { supporter }

class IapProduct {
  const IapProduct({
    required this.sku,
    required this.kind,
    required this.icon,
    required this.nameTh,
    required this.nameEn,
    required this.descTh,
    required this.descEn,
    this.entitlements = const {},
  });
  final String sku;
  final IapKind kind;
  final String icon, nameTh, nameEn, descTh, descEn;
  final Set<String> entitlements;
}

/// `design/data/iap.json` (GDD v0.4 §10/§12, D-003, T-025, D-024).
class IapCatalog {
  const IapCatalog(this.products);
  final List<IapProduct> products;

  IapProduct? bySku(String sku) {
    for (final p in products) {
      if (p.sku == sku) return p;
    }
    return null;
  }

  static const _keys = {
    'sku', 'kind', 'icon', 'name_th', 'name_en', 'desc_th', 'desc_en', //
    'entitlements'
  };

  factory IapCatalog.fromJson(Map<String, dynamic> j) {
    final raw = j['products'];
    if (raw is! List) {
      throw const FormatException('iap.json: "products" must be a list');
    }
    final out = <IapProduct>[];
    for (final p in raw.cast<Map<String, dynamic>>()) {
      final sku = p['sku'];
      if (sku is! String || sku.isEmpty) {
        throw const FormatException('iap.json: product needs a sku');
      }
      FormatException bad(String why) => FormatException('iap $sku: $why');
      // a SKU can only carry what is listed here — never currency or power
      final extra =
          p.keys.where((k) => !_keys.contains(k) && !k.startsWith('_'));
      if (extra.isNotEmpty) throw bad('unknown field ${extra.first}');
      final kind = switch (p['kind']) {
        'supporter' => IapKind.supporter,
        _ => throw bad('kind must be supporter'),
      };
      final ent =
          (p['entitlements'] as List? ?? const []).cast<String>().toSet();
      final unknown = ent.difference(kEntitlements);
      if (unknown.isNotEmpty) throw bad('unknown entitlement ${unknown.first}');
      if (kind == IapKind.supporter && !ent.contains('no_ads')) {
        throw bad('the Supporter Pack must give no_ads');
      }
      String text(String k) => p[k] as String? ?? (throw bad('needs $k'));
      if (out.any((x) => x.sku == sku)) throw bad('duplicate sku');
      out.add(IapProduct(
        sku: sku,
        kind: kind,
        icon: p['icon'] as String? ?? '🎁',
        nameTh: text('name_th'),
        nameEn: text('name_en'),
        descTh: text('desc_th'),
        descEn: text('desc_en'),
        entitlements: Set.unmodifiable(ent),
      ));
    }
    return IapCatalog(List.unmodifiable(out));
  }
}

/// What the store has for sale right now (price in the player's currency).
class StoreProduct {
  const StoreProduct(
      {required this.sku, required this.title, required this.price});
  final String sku, title, price;
}

enum StoreEventKind { purchased, pending, failed, canceled }

/// From the store's purchase stream: a purchase (new, finished later or
/// restored) or a state the UI shows.
class StoreEvent {
  const StoreEvent(this.kind, this.sku);
  final StoreEventKind kind;
  final String sku;
}

/// The seam to the real store (Google Play Billing in the app, D-017).
/// Purchases arrive through [handler] at any time — also at boot for ones
/// that finished while the app was closed — so the app sets it up at boot.
abstract class IapStore {
  Future<bool> isAvailable();
  Future<List<StoreProduct>> products(Set<String> skus);

  /// Opens the store's own payment flow; the result comes as a [StoreEvent].
  Future<bool> buy(String sku);
  Future<void> restore();

  /// Events wait in the store until a handler is set.
  set handler(void Function(StoreEvent) h);
}

/// No store: nothing is for sale and nothing is ever granted. The default,
/// so a build without billing can never hand out purchases for free.
class UnavailableIapStore implements IapStore {
  const UnavailableIapStore();
  @override
  Future<bool> isAvailable() async => false;
  @override
  Future<List<StoreProduct>> products(Set<String> skus) async => const [];
  @override
  Future<bool> buy(String sku) async => false;
  @override
  Future<void> restore() async {}
  @override
  set handler(void Function(StoreEvent) h) {}
}

enum PurchaseStart { started, needsGate, owned, unknown, unavailable }

/// Purchases (T-025, D-003, D-023): the Supporter Pack only (D-024),
/// started only with a live [GatePass]. What the store delivers is granted
/// once ([deliver] is idempotent) and kept in Save v3 `entitlements`.
/// Never touches the wallet.
class IapService {
  IapService({
    required this.catalog,
    required this.store,
    required this.gate,
  });

  final IapCatalog catalog;
  final IapStore store;
  final ParentalGate gate;

  final _owned = <String>{};
  final _news = StreamController<StoreEvent>.broadcast(sync: true);

  Set<String> get owned => Set.unmodifiable(_owned);

  /// Delivered, pending, failed and canceled purchases, for the shop UI.
  Stream<StoreEvent> get news => _news.stream;

  bool has(String entitlement) => _owned.any(
      (s) => catalog.bySku(s)?.entitlements.contains(entitlement) ?? false);

  /// Supporter Pack: hide every ad button, with no reward instead (D-003).
  bool get hasNoAds => has('no_ads');

  /// Listens to the store. Call once at boot.
  void start() => store.handler = _onStore;

  void _onStore(StoreEvent e) {
    if (e.kind == StoreEventKind.purchased) {
      deliver(e.sku);
    } else if (_news.hasListener) {
      _news.add(e);
    }
  }

  /// Products of the catalog the store sells now; empty when it is closed.
  Future<List<StoreProduct>> products() async {
    if (!await store.isAvailable()) return const [];
    final sold =
        await store.products({for (final p in catalog.products) p.sku});
    return [
      for (final p in catalog.products)
        for (final s in sold)
          if (s.sku == p.sku) s,
    ];
  }

  /// Starts buying [sku]; needs a live [pass] from the parental gate.
  Future<PurchaseStart> purchase(String sku, GatePass? pass) async {
    if (!gate.isValid(pass)) return PurchaseStart.needsGate;
    if (catalog.bySku(sku) == null) return PurchaseStart.unknown;
    if (_owned.contains(sku)) return PurchaseStart.owned;
    return await store.buy(sku)
        ? PurchaseStart.started
        : PurchaseStart.unavailable;
  }

  /// Asks the store for everything bought before (new phone, reinstall);
  /// needs a live [pass]. Results arrive through the store's events.
  Future<bool> restore(GatePass? pass) async {
    if (!gate.isValid(pass)) return false;
    await store.restore();
    return true;
  }

  /// Grants [sku] (store purchases only — no gate: the parent already
  /// paid). Unknown SKUs are ignored; a second delivery grants nothing new.
  bool deliver(String sku) {
    if (catalog.bySku(sku) == null) return false;
    if (!_owned.add(sku)) return false;
    if (_news.hasListener) {
      _news.add(StoreEvent(StoreEventKind.purchased, sku));
    }
    return true;
  }

  /// Save v3 `entitlements`.
  Map<String, dynamic> toJson() => {
        'no_ads': hasNoAds,
        'skus': (_owned.toList()..sort()),
      };

  /// Loads owned SKUs; ones the catalog no longer has are dropped.
  void restoreSaved(Map<String, dynamic> j) {
    _owned
      ..clear()
      ..addAll([
        for (final s in (j['skus'] as List? ?? const []).whereType<String>())
          if (catalog.bySku(s) != null) s,
      ]);
  }

  Future<void> dispose() => _news.close();
}
