import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'game_icon.dart';
import 'palette.dart';

/// Which shelf of the shop a product sits on: one per currency it grants.
String packGroup(IapProduct p) => !p.consumable
    ? 'supporter'
    : p.grants[Currency.goldfish] > 0
        ? 'goldfish'
        : 'yarn';

/// The only way into buying (T-025): the parental gate first, then the
/// shop sheet. A pass that runs out sends the player back to the gate.
Future<void> openShop(BuildContext context, WidgetRef ref) async {
  final pass = await showParentalGate(context, ref);
  if (pass == null || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Palette.storyPaper,
    isScrollControlled: true,
    shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(38))),
    builder: (_) => ShopSheet(pass: pass),
  );
}

/// Parental gate (T-025, D-023): a multiplication in words on a number pad.
/// Wrong → a new question. Returns a pass, or null when closed.
Future<GatePass?> showParentalGate(BuildContext context, WidgetRef ref) =>
    showDialog<GatePass>(
      context: context,
      builder: (_) => _GateDialog(gate: ref.read(parentalGateProvider)),
    );

class _GateDialog extends StatefulWidget {
  const _GateDialog({required this.gate});
  final ParentalGate gate;

  @override
  State<_GateDialog> createState() => _GateDialogState();
}

class _GateDialogState extends State<_GateDialog> {
  late GateQuestion _q = widget.gate.next();
  String _typed = '';
  bool _wrong = false;

  void _key(String k) {
    setState(() {
      _wrong = false;
      if (k == '⌫') {
        if (_typed.isNotEmpty) _typed = _typed.substring(0, _typed.length - 1);
      } else if (_typed.length < 4) {
        _typed += k;
      }
    });
  }

  void _submit() {
    final pass = widget.gate.answer(_q, int.tryParse(_typed));
    if (pass != null) {
      Navigator.of(context).pop(pass);
      return;
    }
    setState(() {
      _q = widget.gate.next(); // never the same question twice
      _typed = '';
      _wrong = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    Widget key(String k, {VoidCallback? onTap}) => Expanded(
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: GestureDetector(
              onTap: onTap ?? () => _key(k),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: storybookButton(
                    fill: k == '✓' ? Palette.lime : Palette.paper, radius: 10),
                child: IconText(k,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        );
    return Dialog(
      backgroundColor: Palette.storyPaper,
      shadowColor: Palette.plum.withValues(alpha: 0.30),
      shape: ContinuousRectangleBorder(borderRadius: BorderRadius.circular(34)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          IconText(s.gateTitle,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(s.gateAsk(_q.words(s.lang)),
              key: const ValueKey('gate-question'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
          if (_wrong)
            IconText(s.gateWrong, style: const TextStyle(color: Palette.coral)),
          const SizedBox(height: 8),
          Container(
            height: 44,
            width: double.infinity,
            alignment: Alignment.center,
            decoration: storybookCard(
                fill: Palette.sheet, accent: Palette.plum, radius: 8),
            child: IconText(_typed,
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 8),
          for (final row in const [
            ['1', '2', '3'],
            ['4', '5', '6'],
            ['7', '8', '9'],
          ])
            Row(children: [for (final k in row) key(k)]),
          Row(children: [
            key('⌫'),
            key('0'),
            key('✓', onTap: _typed.isEmpty ? () {} : _submit),
          ]),
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: IconText(s.cancel)),
        ]),
      ),
    );
  }
}

/// What can be bought now, with Play's prices, and restore. Opened only by
/// [openShop] with a live [pass].
class ShopSheet extends ConsumerStatefulWidget {
  const ShopSheet({super.key, required this.pass});
  final GatePass pass;

  @override
  ConsumerState<ShopSheet> createState() => _ShopSheetState();
}

class _ShopSheetState extends ConsumerState<ShopSheet> {
  late final IapService? _iap = ref.read(iapServiceProvider);
  late final Future<List<StoreProduct>> _products =
      _iap?.products() ?? Future.value(const []);
  StreamSubscription<StoreEvent>? _sub;
  String? _status;

  @override
  void initState() {
    super.initState();
    _sub = _iap?.news.listen((e) {
      if (!mounted) return;
      final s = AppLocalizations.of(context);
      setState(() => _status = switch (e.kind) {
            StoreEventKind.purchased => s.bought,
            StoreEventKind.pending => s.payPending,
            StoreEventKind.failed => s.buyFailed,
            StoreEventKind.canceled => null,
          });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _buy(String sku) async {
    final s = AppLocalizations.of(context);
    final r = await _iap!.purchase(sku, widget.pass);
    if (!mounted) return;
    if (r == PurchaseStart.needsGate) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: IconText(s.gateExpired)));
      return;
    }
    setState(() => _status = switch (r) {
          PurchaseStart.started => s.buying,
          PurchaseStart.owned => s.owned,
          _ => s.buyFailed,
        });
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final iap = _iap;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.84,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Column(children: [
            Row(children: [
              Expanded(
                  child: IconText(s.navShop,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w800))),
              IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const GameIcon('cross', size: 28)),
            ]),
            Expanded(
              child: FutureBuilder<List<StoreProduct>>(
                future: _products,
                builder: (context, snap) {
                  final sold = snap.data ?? const [];
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (iap == null || sold.isEmpty) {
                    return Center(
                        child: IconText(s.shopClosed,
                            textAlign: TextAlign.center));
                  }
                  final cards = <Widget>[];
                  String? previous;
                  for (final sp in sold) {
                    final p = iap.catalog.bySku(sp.sku);
                    if (p == null) continue;
                    final group = packGroup(p);
                    if (group != previous) {
                      previous = group;
                      cards.add(Padding(
                        padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: IconText(
                            switch (group) {
                              'goldfish' => s.lang == 'th'
                                  ? '🐟 แพ็กปลาทอง'
                                  : '🐟 Goldfish packs',
                              'yarn' => s.lang == 'th'
                                  ? '🧶 แพ็กไหมพรม'
                                  : '🧶 Yarn packs',
                              _ => s.lang == 'th'
                                  ? 'เล่นแบบไม่มีโฆษณา'
                                  : 'Play without ads',
                            },
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ));
                    }
                    cards.add(_productCard(s, iap, p, sp));
                  }
                  final table = ref.read(gearBasketProvider).gradeTable;
                  final names = s.gradeNames.split(',');
                  final odds = [
                    for (var i = 0; i < table.length; i++)
                      if (table[i] > 0)
                        '${names[i]} ${table[i].toStringAsFixed(table[i] % 1 == 0 ? 0 : 1)}%'
                  ].join(' · ');
                  return ListView(children: [
                    IconText(
                      s.lang == 'th'
                          ? 'ไหมพรมใช้ถักอุปกรณ์แบบสุ่ม · อัตราตอนนี้: $odds'
                          : 'Yarn knits random gear · current rates: $odds',
                      style:
                          const TextStyle(fontSize: 11, color: Palette.inkSoft),
                    ),
                    ...cards,
                  ]);
                },
              ),
            ),
            if (_status case final st?)
              Padding(
                  padding: const EdgeInsets.all(6),
                  child: IconText(st,
                      style: const TextStyle(fontWeight: FontWeight.w700))),
            if (iap != null)
              TextButton(
                onPressed: () async {
                  await iap.restore(widget.pass);
                  if (mounted) setState(() => _status = s.restoring);
                },
                child: IconText(s.restorePurchases),
              ),
          ]),
        ),
      ),
    );
  }

  Widget _productCard(
      AppLocalizations s, IapService iap, IapProduct p, StoreProduct sp) {
    final owned = !p.consumable && iap.owned.contains(p.sku);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(12),
      decoration: storybookCard(
          fill:
              p.consumable ? const Color(0xFFFFF1D5) : const Color(0xFFE4F4EC),
          accent: p.consumable ? Palette.sun : Palette.teal),
      child: Row(children: [
        IconText(p.icon, style: const TextStyle(fontSize: 34)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconText(s.lang == 'en' ? p.nameEn : p.nameTh,
                style: const TextStyle(fontWeight: FontWeight.w800)),
            IconText(s.lang == 'en' ? p.descEn : p.descTh,
                style: const TextStyle(fontSize: 12, color: Palette.inkSoft)),
          ]),
        ),
        const SizedBox(width: 8),
        owned
            ? IconText(s.owned,
                style: const TextStyle(fontWeight: FontWeight.w800))
            : GestureDetector(
                key: ValueKey('buy-${p.sku}'),
                onTap: () => _buy(p.sku),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: storybookButton(
                      fill: Palette.lime, accent: Palette.teal, radius: 9),
                  child: IconText(sp.price,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
      ]),
    );
  }
}
