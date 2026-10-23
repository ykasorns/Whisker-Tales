import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'game_icon.dart';
import 'home_page.dart' show fmtNum;
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
    if (r != null) {
      ref.read(audioServiceProvider).playSfx('hatch');
      await _showResult(pets, r);
    }
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
              child: PetPicture(id: def.id, icon: def.icon, size: 110),
            ),
            IconText(s.lang == 'en' ? def.nameEn : def.nameTh,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            IconText(
                r.isNew
                    ? s.newPet
                    : r.cookies > 0
                        ? s.treats(r.cookies)
                        : s.starUp,
                style: TextStyle(
                    color: _rarityColor(r.rarity),
                    fontWeight: FontWeight.w800)),
            IconText('★' * r.stars,
                style: const TextStyle(fontSize: 22, color: Palette.sun)),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.of(ctx).pop(),
              child: Container(
                height: 52,
                alignment: Alignment.center,
                decoration: inkBox(fill: Palette.lime),
                child: IconText(s.yay,
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
                child: IconText(label,
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
          const IconText('🥚', style: TextStyle(fontSize: 64)),
          IconText(s.hatch,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          IconText(
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
      IconText(
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
                    : () async {
                        await showPetSheet(context, ref, def);
                        if (mounted) setState(() {});
                      },
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
                          child: stars == null
                              ? const IconText('❔',
                                  style: TextStyle(fontSize: 36))
                              : PetPicture(
                                  id: def.id, icon: def.icon, size: 48),
                        ),
                        IconText(
                            stars == null
                                ? ''
                                : (s.lang == 'en' ? def.nameEn : def.nameTh),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700)),
                        IconText(stars == null ? '' : '★' * stars,
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

/// A pet's picture (`assets/game/pet/<id>_idle.png`), or its emoji while
/// the pet has no art yet.
class PetPicture extends StatelessWidget {
  const PetPicture(
      {super.key, required this.id, required this.icon, required this.size});
  final String id, icon;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: size,
        child: Image.asset('assets/game/pet/${id}_idle.png',
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                IconText(icon, style: TextStyle(fontSize: size * 0.75))),
      );
}

/// Tap a pet to see everything about it: picture, rarity, stars, attack, the
/// bonus it gives while on the field, its skill and cooldown — and send it
/// to battle or rest it (YK 2026-10-23, D-039).
Future<void> showPetSheet(BuildContext context, WidgetRef ref, PetDef def) =>
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Palette.paper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => PetSheet(def: def),
    );

class PetSheet extends ConsumerStatefulWidget {
  const PetSheet({super.key, required this.def});
  final PetDef def;

  @override
  ConsumerState<PetSheet> createState() => _PetSheetState();
}

class _PetSheetState extends ConsumerState<PetSheet> {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final en = s.lang == 'en';
    final def = widget.def;
    final pets = ref.read(petsProvider)!;
    final stars = pets.owned[def.id] ?? 1;
    final out = pets.deployed.contains(def.id);
    final full = !out && pets.deployed.length >= pets.deploySlots;
    final cat = ref.read(catSpecProvider)();
    final atk = pets.attackOf(cat, def);
    final mult = pets.rules.starMultBp(stars) / kBp;
    final p = def.passive, k = def.skill;
    final rarity = switch (def.rarity) {
      PetRarity.common => s.rarityCommon,
      PetRarity.rare => s.rarityRare,
      PetRarity.legend => s.rarityLegend,
    };
    Widget section(String title, Widget body) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.all(10),
          decoration: inkBox(radius: 12, width: 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconText(title,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Palette.inkSoft)),
            const SizedBox(height: 4),
            body,
          ]),
        );
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Row(children: [
            PetPicture(id: def.id, icon: def.icon, size: 96),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconText(en ? def.nameEn : def.nameTh,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    IconText(rarity,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _PetsTabState._rarityColor(def.rarity))),
                    IconText('★' * stars,
                        style:
                            const TextStyle(fontSize: 18, color: Palette.sun)),
                    IconText('⚔️ ${s.petAttack} ${fmtNum(atk)}',
                        style: const TextStyle(fontWeight: FontWeight.w800)),
                  ]),
            ),
          ]),
          if (p != null)
            section(
                s.petPassive,
                IconText(
                    '${en ? p.textEn : p.textTh}\n${s.petStarsBoost(mult.toStringAsFixed(1))}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
          if (k != null)
            section(
                s.petActive,
                Row(children: [
                  GameIcon(k.icon, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          IconText(en ? k.nameEn : k.nameTh,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          IconText(en ? k.textEn : k.textTh),
                          IconText(
                              '⏱ ${s.petCooldown(k.spec.cooldownMs ~/ 1000)}',
                              style: const TextStyle(
                                  fontSize: 12, color: Palette.inkSoft)),
                        ]),
                  ),
                ])),
          const SizedBox(height: 14),
          if (full)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: IconText(s.slotsFull,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: Palette.coral)),
            ),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: full
                    ? null
                    : () => setState(() {
                          if (out) {
                            pets.undeploy(def.id);
                          } else if (pets.deployed.length < pets.deploySlots) {
                            pets.deploy(pets.deployed.length, def.id);
                          }
                        }),
                child: Opacity(
                  opacity: full ? 0.4 : 1,
                  child: Container(
                    height: 56,
                    alignment: Alignment.center,
                    decoration: inkBox(
                        fill: out ? Palette.paper : Palette.lime, radius: 14),
                    child: IconText(out ? s.restPet : s.sendToBattle,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 18),
                alignment: Alignment.center,
                decoration: inkBox(radius: 14),
                child: IconText(s.closeSheet,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}
