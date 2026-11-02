import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'home_page.dart';
import 'game_icon.dart';
import 'palette.dart';
import 'age_screen.dart';
import 'library_tab.dart';
import 'pets_tab.dart';
import 'shop.dart';

Widget _pageTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: IconText(t,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    );

Widget _storyHeading(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 10),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(children: [
          Transform.rotate(
            angle: -.08,
            child: Container(
              width: 28,
              height: 7,
              decoration: storybookButton(
                fill: Palette.coral,
                accent: Palette.mochi,
                radius: 3,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Flexible(
            child: IconText(t,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ),
        ]),
      ),
    );

Widget _statCell(String label, String value, Color accent) => Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 8),
        color: Color.lerp(Palette.parchment, accent, .11),
        child: Column(children: [
          IconText(label,
              maxLines: 1,
              style: const TextStyle(fontSize: 11, color: Palette.inkSoft)),
          const SizedBox(height: 2),
          IconText(value,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
        ]),
      ),
    );

Widget _soon(BuildContext context, String icon, String text) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        IconText(icon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        IconText(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
      ]),
    );

/// 🐱 Character (D-018): cat · wardrobe · pets · library.
class CharacterPage extends ConsumerWidget {
  const CharacterPage({super.key, required this.refresh});
  final ValueNotifier<int> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return StorybookPaper(
        child: DefaultTabController(
      length: 4,
      child: Column(children: [
        Builder(
          builder: (tabContext) {
            final controller = DefaultTabController.of(tabContext);
            final chapters = [
              (s.tabCat, '🐱'),
              (s.tabWardrobe, 'openbook'),
              (s.tabPets, '🐾'),
              (s.tabLibrary, 'books'),
            ];
            return AnimatedBuilder(
              animation: controller,
              builder: (context, _) => Container(
                margin: const EdgeInsets.fromLTRB(8, 7, 8, 4),
                padding: const EdgeInsets.all(3),
                decoration: storybookCard(
                  fill: Palette.parchmentDeep,
                  accent: Palette.wood,
                  radius: 9,
                ),
                child: TabBar(
                  dividerHeight: 0,
                  indicatorColor: Colors.transparent,
                  labelPadding: EdgeInsets.zero,
                  tabs: [
                    for (var i = 0; i < chapters.length; i++)
                      Tab(
                        height: 62,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: double.infinity,
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: i == controller.index
                              ? storybookButton(
                                  fill: const Color(0xFFFFE1A0),
                                  accent: Palette.coral,
                                  radius: 8,
                                )
                              : null,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GameIcon(chapters[i].$2, size: 22),
                              const SizedBox(height: 1),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: IconText(chapters[i].$1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: i == controller.index
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        Expanded(
          child: TabBarView(children: [
            ValueListenableBuilder(
                valueListenable: refresh,
                builder: (_, __, ___) => const _CatTab()),
            const _WardrobeTab(),
            ValueListenableBuilder(
                valueListenable: refresh,
                builder: (_, v, __) => PetsTab(tick: v)),
            ValueListenableBuilder(
                valueListenable: refresh,
                builder: (_, v, __) => LibraryTab(tick: v)),
          ]),
        ),
      ]),
    ));
  }
}

class _CatTab extends ConsumerStatefulWidget {
  const _CatTab();

  @override
  ConsumerState<_CatTab> createState() => _CatTabState();
}

class _CatTabState extends ConsumerState<_CatTab> {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final lang = s.lang;
    final cls = ref.read(catClassProvider);
    final cat = ref.read(catProgressProvider);
    final rules = ref.read(catRulesProvider);
    final skills = ref.read(skillBookProvider);
    final st = ref.read(catSpecProvider)().stats; // as it fights
    String pct(Attribute a) => '${(st[a] / 100).toStringAsFixed(1)}%';
    final unlocked = cat.level >= rules.classUnlockLevel;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
        decoration: storybookCard(
            fill: const Color(0xFFFFE9B8), accent: Palette.mochi, radius: 11),
        child: Row(children: [
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Palette.paper.withValues(alpha: .62),
              shape: BoxShape.circle,
            ),
            child: GameIcon.classEmblem(cls.current, size: 38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconText(s.className(cls.current),
                  style: const TextStyle(
                      fontSize: 21, fontWeight: FontWeight.w900)),
              IconText(s.level(cat.level),
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkSoft)),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                    value: cat.expToNext == 0 ? 1 : cat.exp / cat.expToNext,
                    color: Palette.teal,
                    backgroundColor: Palette.paper.withValues(alpha: .75),
                    minHeight: 7),
              ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 10),
      ClipRRect(
        borderRadius: BorderRadius.circular(9),
        child: Container(
          decoration: storybookCard(
            fill: Palette.parchment,
            accent: Palette.storyEdge,
            radius: 9,
          ),
          child: Column(children: [
            Row(children: [
              _statCell('❤️ ${s.shortHp}', '${st.hp}', Palette.coral),
              _statCell('⚔️ ${s.shortAtk}', '${st.atk}', Palette.mochi),
              _statCell('🛡️ ${s.shortDef}', '${st.def}', Palette.teal),
            ]),
            Row(children: [
              _statCell(
                  '💨 ${s.shortEvade}', pct(Attribute.evade), Palette.lime),
              _statCell(
                  '💥 ${s.shortCrit}', pct(Attribute.crit), Palette.coral),
              _statCell(
                  '✨ ${s.shortSkill}', pct(Attribute.skillDmg), Palette.sun),
            ]),
          ]),
        ),
      ),
      _storyHeading(s.classPick),
      if (!unlocked) IconText(s.classAt(rules.classUnlockLevel)),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final c in rules.classes.where((c) => c.tier == 1))
          GestureDetector(
            onTap: !unlocked || c.id == cls.current
                ? null
                : () {
                    try {
                      cls.choose(c.id);
                    } on StateError catch (_) {}
                    setState(() {});
                  },
            child: Opacity(
              opacity: unlocked ? 1 : 0.45,
              child: Container(
                width: 150,
                padding: const EdgeInsets.all(10),
                decoration: c.id == cls.current
                    ? storybookButton(
                        fill: const Color(0xFFFFD77F),
                        accent: Palette.coral,
                        radius: 9)
                    : storybookCard(
                        fill: const Color(0xFFFFEDCF),
                        accent: unlocked ? Palette.storyEdge : Palette.inkSoft,
                        radius: 8),
                child: Row(children: [
                  GameIcon.classEmblem(c.id, size: 30),
                  const SizedBox(width: 8),
                  Flexible(
                      child: IconText(s.className(c.id),
                          style: const TextStyle(fontWeight: FontWeight.w800))),
                ]),
              ),
            ),
          ),
      ]),
      _storyHeading(s.skills),
      for (final sk in skills.byClass[cls.current] ?? const <SkillSpec>[])
        Builder(builder: (_) {
          final i = skills.info[sk.id];
          final open = cls.combatSpec().skills.any((x) => x.id == sk.id);
          final description = lang == 'en'
              ? (i?.descriptionEn ?? '')
              : (i?.descriptionTh ?? '');
          return Opacity(
            opacity: open ? 1 : 0.72,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: storybookCard(
                fill: open ? const Color(0xFFFFEFD2) : const Color(0xFFE9E1D4),
                accent: open ? Palette.mochi : Palette.inkSoft,
                radius: 8,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GameIcon.skill(sk.id, i?.icon ?? '✨', size: 36),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            IconText(
                                lang == 'en'
                                    ? (i?.en ?? sk.id)
                                    : (i?.th ?? sk.id),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w800)),
                            if (description.isNotEmpty)
                              IconText(description,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      height: 1.25,
                                      color: Palette.inkSoft)),
                            const SizedBox(height: 3),
                            IconText(
                                s.cooldownSeconds(
                                    (sk.cooldownMs / 1000).toStringAsFixed(1)),
                                style: const TextStyle(
                                    fontSize: 11, color: Palette.inkSoft)),
                          ],
                        ),
                      ),
                    ]),
              ),
            ),
          );
        }),
    ]);
  }
}

/// Collection book (D-024): the outfit of every class (Mochi always wears
/// the current one) and every look ever knitted — silhouettes until found.
/// Nothing here is worn or chosen.
class _WardrobeTab extends ConsumerWidget {
  const _WardrobeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final wd = ref.read(wardrobeProvider);
    final cls = ref.read(catClassProvider).current;
    final wr = ref.read(wardrobeRulesProvider);
    final classes = ref.read(catRulesProvider).classes;
    final found = wd.collection.where((e) => e.unlocked).length;
    return ListView(padding: const EdgeInsets.all(12), children: [
      _storyHeading(s.classOutfits),
      const SizedBox(height: 6),
      Container(
        height: 112,
        padding: const EdgeInsets.all(6),
        decoration: storybookCard(
          fill: Palette.parchmentDeep,
          accent: Palette.wood,
          radius: 9,
        ),
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in classes)
            Container(
              width: 82,
              margin: const EdgeInsets.only(right: 5),
              padding: const EdgeInsets.all(4),
              decoration: c.id == cls
                  ? storybookButton(
                      fill: const Color(0xFFFFD77F),
                      accent: Palette.coral,
                      radius: 8,
                    )
                  : null,
              child: Column(children: [
                Expanded(
                    child: Image.asset('assets/game/cat/bare_${c.id}.png',
                        fit: BoxFit.contain)),
                IconText(s.className(c.id),
                    maxLines: 1,
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight:
                            c.id == cls ? FontWeight.w900 : FontWeight.w700)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      _storyHeading(s.looksFound(found, wd.collection.length)),
      const SizedBox(height: 6),
      GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 4,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: [
          for (final e in wd.collection)
            Container(
              padding: const EdgeInsets.all(7),
              decoration: storybookCard(
                  fill: e.unlocked
                      ? const Color(0xFFFFEBC9)
                      : const Color(0xFFE6DAC2),
                  accent: e.unlocked ? Palette.mochi : Palette.inkSoft,
                  radius: 7),
              child: ColorFiltered(
                colorFilter: e.unlocked
                    ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                    : const ColorFilter.mode(Palette.ink, BlendMode.srcIn),
                child: Opacity(
                  opacity: e.unlocked ? 1 : 0.25,
                  child: Image.asset(
                      'assets/game/${FarmPanel.slotArt(e.slot, GearItem(id: '', slot: e.slot, grade: (e.tier - 1) * 2, page: 1, stats: StatBlock(hp: 0, atk: 0, def: 0)), cls, wr)}.png'),
                ),
              ),
            ),
        ],
      ),
    ]);
  }
}

/// 🏰 Dungeon — v1.1 (D-018).
class DungeonPage extends StatelessWidget {
  const DungeonPage({super.key});

  @override
  Widget build(BuildContext context) =>
      _soon(context, '🏰🔒', AppLocalizations.of(context).dungeonSoon);
}

/// 🎁 Events are reserved for rotating activities. Daily shop gifts moved to
/// Shop in D-053 so every way of getting supplies lives in one place.
class EventsPage extends ConsumerWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return StorybookPaper(
      child: ListView(children: [
        _pageTitle(s.navEvents),
        const SizedBox(height: 80),
        _soon(context, '🎁', s.comingSoon),
      ]),
    );
  }
}

/// 🛒 Unified shop: free daily gifts first, then grown-up purchases.
class ShopPage extends ConsumerStatefulWidget {
  const ShopPage({super.key});

  @override
  ConsumerState<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends ConsumerState<ShopPage> {
  Future<void> _claim(String placement) async {
    final reward = await ref.read(adGiftsProvider).watch(placement);
    if (!mounted) return;
    setState(() {});
    if (reward != null) {
      final amount = reward.amounts.values.single;
      final s = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: IconText('${s.claim} +$amount'),
          duration: const Duration(seconds: 1)));
    }
  }

  /// A row of the packs that give [c]: amounts only (Play shows the price
  /// after the parental gate, which opens on any tap).
  Widget _packShelf(AppLocalizations s, Currency c, String icon) {
    final packs = [
      for (final p in (ref.read(iapCatalogProvider)?.products ?? const <IapProduct>[]))
        if (p.consumable && p.grants[c] > 0) p
    ];
    return SizedBox(
      height: 66,
      child: Row(children: [
        for (final p in packs)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: GestureDetector(
                key: ValueKey('pack-${p.sku}'),
                onTap: () => openShop(context, ref),
                child: Container(
                  alignment: Alignment.center,
                  decoration: storybookCard(
                      fill: c == Currency.yarn
                          ? const Color(0xFFE5F5F2)
                          : const Color(0xFFFFF1C7),
                      accent: c == Currency.yarn ? Palette.teal : Palette.sun,
                      radius: 9),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      IconText(icon, style: const TextStyle(fontSize: 22)),
                      IconText(fmtNum(p.grants[c]),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800)),
                    ]),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final ads = ref.read(adServiceProvider);
    final gifts = ref.read(adGiftsProvider);
    final noAds = ref.read(noAdsProvider)();

    Widget gift(String placement, String icon, String title, Currency c) {
      final left = ads.remainingToday(placement);
      final amount = gifts.rewardFor(placement)[c];
      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: storybookCard(
            fill: c == Currency.yarn
                ? const Color(0xFFE5F5F2)
                : const Color(0xFFFFF1C7),
            accent: c == Currency.yarn ? Palette.teal : Palette.sun),
        child: Row(children: [
          IconText(icon, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                IconText(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                IconText('+$amount · ${s.adsLeft(left)}',
                    style:
                        const TextStyle(fontSize: 12, color: Palette.inkSoft)),
              ])),
          if (left > 0)
            GestureDetector(
              onTap: () => _claim(placement),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                decoration: storybookButton(
                    fill: Palette.lime, accent: Palette.teal, radius: 9),
                child: IconText(noAds ? s.claim : s.watch,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
    }

    return StorybookPaper(
      child: ListView(children: [
        _pageTitle(s.navShop),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
          child: IconText(s.lang == 'th' ? 'ของฟรีวันนี้' : 'Free today',
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: [
            gift('daily_gift', '🐟', s.dailyGift, Currency.goldfish),
            gift('yarn_bundle', '🧶', s.yarnBundle, Currency.yarn),
          ]),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          padding: const EdgeInsets.all(16),
          decoration: storybookCard(
              fill: const Color(0xFFFFE8C4), accent: Palette.coral),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            IconText(
                s.lang == 'th'
                    ? '🎁 เสบียงและนิทานไร้โฆษณา'
                    : '🎁 Supplies & ad-free story',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            IconText(s.lang == 'th'
                ? 'แพ็กเริ่ม \$0.99 ถึง \$99.99 · ราคาในหน้าซื้อจะแสดงตามประเทศ'
                : 'Packs from \$0.99 to \$99.99 · checkout shows the local price'),
            const SizedBox(height: 12),
            _packShelf(s, Currency.goldfish, '🐟'),
            const SizedBox(height: 6),
            _packShelf(s, Currency.yarn, '🧶'),
            const SizedBox(height: 12),
            // the parental gate comes first, always (T-025)
            Semantics(
              button: true,
              label: s.askParent,
              child: GestureDetector(
                onTap: () => openShop(context, ref),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: storybookButton(
                      fill: Palette.lime, accent: Palette.teal, radius: 9),
                  child: IconText('👨‍👩‍👧 ${s.askParent}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ),
          ]),
        ),
        // music and effects, each off at once and saved (T-024)
        const _SoundSwitches(),
        // language, shown in the language it switches to (T-004)
        Center(
          child: TextButton(
            onPressed: () => ref.read(langProvider.notifier).state =
                s.lang == 'th' ? 'en' : 'th',
            child: IconText(s.switchLanguage),
          ),
        ),
        // a grown-up can correct the age answer, behind the gate (T-040)
        Center(
          child: TextButton(
            onPressed: () async {
              final pass = await showParentalGate(context, ref);
              if (pass == null || !context.mounted) return;
              await Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (ctx) => AgeScreen(
                      pass: pass, onDone: () => Navigator.of(ctx).pop())));
            },
            child: IconText(s.changeAge),
          ),
        ),
      ]),
    );
  }
}

/// 🎵 / 🔊 switches (T-024): take effect at once, saved in settings.
class _SoundSwitches extends ConsumerStatefulWidget {
  const _SoundSwitches();

  @override
  ConsumerState<_SoundSwitches> createState() => _SoundSwitchesState();
}

class _SoundSwitchesState extends ConsumerState<_SoundSwitches> {
  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final audio = ref.read(audioServiceProvider);
    Widget row(String label, bool on, void Function(bool) set) => Row(
          children: [
            Expanded(
                child: IconText(label,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w800))),
            Switch(
              value: on,
              activeThumbColor: Palette.teal,
              onChanged: (v) => setState(() => set(v)),
            ),
          ],
        );
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 5, 6, 5),
      decoration: storybookCard(
          fill: const Color(0xFFE3F0EA), accent: Palette.teal, radius: 8),
      child: Column(children: [
        row(s.music, audio.bgmEnabled, audio.setBgmEnabled),
        row(s.sounds, audio.sfxEnabled, audio.setSfxEnabled),
      ]),
    );
  }
}
