import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'home_page.dart';
import 'game_icon.dart';
import 'yarn_basket.dart';
import 'palette.dart';

/// Knit flow (GDD v0.4 §3, D-010): pick a slot → the yarn ball wiggles →
/// the item pops out → compare → wear or recycle. With [stashed], compares
/// an item auto-knit kept for the player.
Future<void> showCraftSheet(BuildContext context, WidgetRef ref,
    {GearItem? stashed}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Palette.storyPaper,
    isScrollControlled: true,
    shape: const ContinuousRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
    builder: (_) => _CraftSheet(stashed: stashed),
  );
}

class _CraftSheet extends ConsumerStatefulWidget {
  const _CraftSheet({this.stashed});
  final GearItem? stashed;

  @override
  ConsumerState<_CraftSheet> createState() => _CraftSheetState();
}

class _CraftSheetState extends ConsumerState<_CraftSheet> {
  late final GearBasket _basket;
  late final AutoCraft _auto;
  GearItem? _item;
  bool _knitting = false;
  int _wiggle = 0;

  @override
  void initState() {
    super.initState();
    _basket = ref.read(gearBasketProvider);
    // auto-knit waits while the sheet is open, so it can neither spend the
    // last yarn nor replace the stashed item being compared
    _auto = ref.read(autoCraftProvider)..hold();
    _item = widget.stashed;
  }

  @override
  void dispose() {
    // closed (✕, swipe, back) on the compare card: never lose the knit
    final item = _item;
    if (item != null && _basket.isPending(item.id)) _basket.settle(item.id);
    _auto.release();
    super.dispose();
  }

  Future<void> _knit(GearSlot slot) async {
    if (_knitting) return; // a second tap in the same frame
    if (ref.read(walletProvider).balance(Currency.yarn) < 1) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _knitting = true;
      _wiggle++;
    });
    final r = _basket.craft(slot);
    ref.read(audioServiceProvider).playSfx('knit');
    await Future<void>.delayed(
        const Duration(milliseconds: 550)); // wiggle, then pop
    if (mounted) {
      setState(() {
        _knitting = false;
        _item = r.item;
      });
    }
  }

  void _done() {
    final yarn = ref.read(walletProvider).balance(Currency.yarn);
    if (widget.stashed != null || yarn < 1) {
      Navigator.of(context).pop();
    } else {
      setState(() => _item = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final basket = _basket;
    final cls = ref.read(catClassProvider).current;
    final wr = ref.read(wardrobeRulesProvider);
    final grades = s.gradeNames.split(',');
    final item = _item;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            // the same basket as on the home panel: its balls leap where the
            // knit happens (D-040)
            YarnBasket(height: 64, knit: _wiggle),
            const SizedBox(width: 8),
            Expanded(
                child: IconText(item == null ? s.pickSlot : s.newItem,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800))),
            IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const GameIcon('cross', size: 28)),
          ]),
          if (item == null) ...[
            // grade odds, always shown before knitting
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(children: [
                for (var g = 0; g < basket.gradeTable.length; g++)
                  if (basket.gradeTable[g] > 0)
                    Expanded(
                        flex: basket.gradeTable[g].round(),
                        child: Container(height: 10, color: Palette.grades[g])),
              ]),
            ),
            const SizedBox(height: 4),
            IconText(
                '${_odds(grades, basket.gradeTable)} · 💜 ${s.pityLabel(basket.pityLeft)}',
                style: const TextStyle(fontSize: 12, color: Palette.inkSoft)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: storybookCard(
                fill: Palette.parchmentDeep,
                accent: Palette.wood,
                radius: 9,
              ),
              child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final slot in basket.openSlots)
                      GestureDetector(
                        onTap: _knitting ? null : () => _knit(slot),
                        child: Container(
                          width: 72,
                          height: 72,
                          padding: const EdgeInsets.all(7),
                          decoration: storybookButton(
                            fill: const Color(0xFFFFEDCF),
                            accent: Palette.mochi,
                            enabled: !_knitting,
                            radius: 8,
                          ),
                          child: Image.asset(
                              'assets/game/${FarmPanel.slotArt(slot, basket.equipped(slot), cls, wr)}.png'),
                        ),
                      ),
                  ]),
            ),
          ] else
            TweenAnimationBuilder<double>(
              key: ValueKey(item.id),
              tween: Tween(begin: 0.4, end: 1),
              duration: const Duration(milliseconds: 450),
              curve: Curves.easeOutBack,
              builder: (context, v, child) =>
                  Transform.scale(scale: v, child: child),
              child: _Compare(
                  item: item,
                  worn: basket.equipped(item.slot),
                  cls: cls,
                  wr: wr,
                  fish: basket.rules.recycleFish(item.page),
                  onEquip: () {
                    basket.equip(item.id);
                    _done();
                  },
                  onRecycle: () {
                    basket.recycle(item.id);
                    _done();
                  }),
            ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

/// "white 70% · green 25% …" — grade names from the arb, odds from data.
String _odds(List<String> grades, List<double> table) => [
      for (var g = 0; g < grades.length && g < table.length; g++)
        if (table[g] > 0) '${grades[g]} ${table[g].round()}%'
    ].join(' · ');

class _Compare extends StatelessWidget {
  const _Compare({
    required this.item,
    required this.worn,
    required this.cls,
    required this.wr,
    required this.onEquip,
    required this.onRecycle,
    required this.fish,
  });
  final int fish;
  final GearItem item;
  final GearItem? worn;
  final String cls;
  final WardrobeRules wr;
  final VoidCallback onEquip, onRecycle;

  Widget _card(
      BuildContext context, String label, GearItem? g, GearItem? other) {
    final s = AppLocalizations.of(context);
    final grades = s.gradeNames.split(',');
    String arrow(int a, int? b) => b == null
        ? ''
        : a > b
            ? ' ▲'
            : a < b
                ? ' ▼'
                : '';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: storybookCard(
          fill: g == null
              ? Palette.sheet
              : Color.lerp(Palette.parchment, Palette.grades[g.grade], .13)!,
          accent: g == null ? Palette.inkSoft : Palette.grades[g.grade],
          radius: 8,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconText(label,
              style: const TextStyle(fontSize: 12, color: Palette.inkSoft)),
          if (g == null)
            IconText(s.empty,
                style: const TextStyle(fontWeight: FontWeight.w800))
          else ...[
            Row(children: [
              SizedBox(
                  width: 36,
                  height: 36,
                  child: Image.asset(
                      'assets/game/${FarmPanel.slotArt(g.slot, g, cls, wr)}.png')),
              const SizedBox(width: 6),
              IconText(grades[g.grade],
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ]),
            IconText(
                '⚔️ ${s.shortAtk} ${g.stats.atk}${arrow(g.stats.atk, other?.stats.atk)}'),
            IconText(
                '❤️ ${s.shortHp} ${g.stats.hp}${arrow(g.stats.hp, other?.stats.hp)}'),
            IconText(
                '🛡️ ${s.shortDef} ${g.stats.def}${arrow(g.stats.def, other?.stats.def)}'),
            for (final e in g.stats.attrs.entries)
              IconText('✦ ${e.key.key} +${(e.value / 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontSize: 12)),
          ],
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final better = item.isStrictlyBetterThan(worn);
    return Column(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _card(context, s.worn, worn, null),
        const Padding(
            padding: EdgeInsets.all(6),
            child: IconText('→', style: TextStyle(fontSize: 22))),
        _card(context, '${s.newItem}${better ? ' ✨' : ''}', item, worn),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
            child: _Big(
                label: s.recycle(fish),
                color: Palette.sheet,
                onTap: onRecycle)),
        const SizedBox(width: 10),
        Expanded(
            child: _Big(label: s.equip, color: Palette.lime, onTap: onEquip)),
      ]),
    ]);
  }
}

class _Big extends StatelessWidget {
  const _Big({required this.label, required this.color, required this.onTap});
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          alignment: Alignment.center,
          decoration: color == Palette.lime
              ? storybookButton(fill: color, accent: Palette.teal, radius: 10)
              : storybookCard(fill: color, accent: Palette.inkSoft, radius: 9),
          child: IconText(label,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        ),
      );
}
