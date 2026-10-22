import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'palette.dart';

/// 🐦 Pets (GDD v0.4 §6, T-038): hatch (egg / ad / goldfish, odds always
/// shown), roster with stars, deploy slots by chapter.
class PetsTab extends ConsumerStatefulWidget {
  const PetsTab({super.key, this.tick = 0});

  /// Changes a few times a second so counts (eggs, goldfish) stay current.
  final int tick;

  @override
  ConsumerState<PetsTab> createState() => _PetsTabState();
}

class _PetsTabState extends ConsumerState<PetsTab> {
  bool _busy = false;

  Future<void> _hatch(Pets pets, HatchSource src) async {
    if (_busy) return;
    setState(() => _busy = true);
    final r = await pets.hatch(src);
    if (!mounted) return;
    setState(() => _busy = false);
    if (r != null) await _showResult(pets, r);
  }

  Future<void> _showResult(Pets pets, HatchResult r) {
    final s = AppLocalizations.of(context);
    final def = pets.rules.byId(r.petId)!;
    return showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Palette.paper,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: _rarityColor(r.rarity), width: 4)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.2, end: 1),
              duration: const Duration(milliseconds: 600),
              curve: Curves.elasticOut,
              builder: (_, v, child) => Transform.scale(scale: v, child: child),
              child: Text(def.icon, style: const TextStyle(fontSize: 88)),
            ),
            Text(s.lang == 'en' ? def.nameEn : def.nameTh,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(
                r.isNew
                    ? s.newPet
                    : r.cookies > 0
                        ? s.treats(r.cookies)
                        : s.starUp,
                style: TextStyle(
                    color: _rarityColor(r.rarity),
                    fontWeight: FontWeight.w800)),
            Text('★' * r.stars,
                style: const TextStyle(fontSize: 22, color: Palette.sun)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: inkBox(fill: Palette.lime),
                child: Text(s.yay,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  static Color _rarityColor(PetRarity r) =>
      [Palette.inkSoft, Palette.teal, Palette.coral][r.index];

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final pets = ref.read(petsProvider);
    if (pets == null) return const SizedBox();
    final wallet = ref.read(walletProvider);
    final ads = ref.read(adServiceProvider);
    final rates = pets.rates;
    Widget button(String label, bool enabled, Color fill, HatchSource src) =>
        Expanded(
          child: GestureDetector(
            onTap: enabled && !_busy ? () => _hatch(pets, src) : null,
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Container(
                height: 56,
                alignment: Alignment.center,
                margin: const EdgeInsets.all(4),
                decoration: inkBox(fill: fill, radius: 12),
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        );
    return ListView(padding: const EdgeInsets.all(12), children: [
      // hatch
      Container(
        padding: const EdgeInsets.all(12),
        decoration: inkBox(fill: const Color(0xFFFFF3D6)),
        child: Column(children: [
          const Text('🥚', style: TextStyle(fontSize: 64)),
          Text(s.hatch,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          Text(
            s.odds(
                rates[PetRarity.common]!.round(),
                rates[PetRarity.rare]!.round(),
                rates[PetRarity.legend]!.round(),
                pets.pityLeft),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Palette.inkSoft),
          ),
          const SizedBox(height: 8),
          Row(children: [
            button(s.useEgg(wallet.balance(Currency.eggs)),
                pets.canHatch(HatchSource.egg), Palette.paper, HatchSource.egg),
            button(s.adFree(ads.remainingToday(petHatchPlacement)),
                pets.canHatch(HatchSource.ad), Palette.sun, HatchSource.ad),
            button(
                s.fishHatch(pets.nextFishCost, pets.fishHatchesLeftToday),
                pets.canHatch(HatchSource.fish),
                Palette.paper,
                HatchSource.fish),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      Text(
          '${s.deploySlots(pets.deployed.length, pets.deploySlots)} · ${s.deployHint}',
          style: const TextStyle(fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final def in pets.rules.pets)
            Builder(builder: (_) {
              final stars = pets.owned[def.id];
              final out = pets.deployed.contains(def.id);
              return GestureDetector(
                onTap: stars == null
                    ? null
                    : () => setState(() {
                          if (out) {
                            pets.undeploy(def.id);
                          } else if (pets.deployed.length < pets.deploySlots) {
                            pets.deploy(pets.deployed.length, def.id);
                          }
                        }),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: inkBox(
                      fill: out ? Palette.lime : Palette.paper,
                      border: stars == null
                          ? Palette.inkSoft
                          : _rarityColor(def.rarity),
                      radius: 12),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Opacity(
                          opacity: stars == null ? 0.25 : 1,
                          child: Text(stars == null ? '❔' : def.icon,
                              style: const TextStyle(fontSize: 36)),
                        ),
                        Text(
                            stars == null
                                ? ''
                                : (s.lang == 'en' ? def.nameEn : def.nameTh),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                        Text(stars == null ? '' : '★' * stars,
                            style: const TextStyle(color: Palette.sun)),
                      ]),
                ),
              );
            }),
        ],
      ),
    ]);
  }
}
