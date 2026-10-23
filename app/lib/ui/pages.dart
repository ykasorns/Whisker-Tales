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
    return DefaultTabController(
      length: 4,
      child: Column(children: [
        TabBar(
          labelColor: Palette.ink,
          indicatorColor: Palette.coral,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800),
          tabs: [
            Tab(text: s.tabCat),
            Tab(text: s.tabWardrobe),
            Tab(text: s.tabPets),
            Tab(text: s.tabLibrary)
          ],
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
    );
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
      Row(children: [
        IconText('${s.level(cat.level)} · ${s.className(cls.current)}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(width: 8),
        GameIcon.classEmblem(cls.current, size: 34),
      ]),
      LinearProgressIndicator(
          value: cat.expToNext == 0 ? 1 : cat.exp / cat.expToNext,
          color: Palette.teal,
          minHeight: 6),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (k, v) in [
          ('❤️ ${s.shortHp}', '${st.hp}'),
          ('⚔️ ${s.shortAtk}', '${st.atk}'),
          ('🛡️ ${s.shortDef}', '${st.def}'),
          ('💨 ${s.shortEvade}', pct(Attribute.evade)),
          ('💥 ${s.shortCrit}', pct(Attribute.crit)),
          ('✨ ${s.shortSkill}', pct(Attribute.skillDmg)),
        ])
          Container(
            width: 104,
            padding: const EdgeInsets.all(8),
            decoration: inkBox(radius: 10, width: 2),
            child: Column(children: [
              IconText(k, style: const TextStyle(fontSize: 12)),
              IconText(v, style: const TextStyle(fontWeight: FontWeight.w800))
            ]),
          ),
      ]),
      _pageTitle(s.classPick),
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
                decoration: inkBox(
                    fill: c.id == cls.current ? Palette.sun : Palette.paper,
                    radius: 12),
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
      _pageTitle(s.skills),
      for (final sk in skills.byClass[cls.current] ?? const <SkillSpec>[])
        Builder(builder: (_) {
          final i = skills.info[sk.id];
          final open = cls.combatSpec().skills.any((x) => x.id == sk.id);
          return Opacity(
            opacity: open ? 1 : 0.4,
            child: ListTile(
              leading: GameIcon.skill(sk.id, i?.icon ?? '✨', size: 36),
              title: IconText(
                  lang == 'en' ? (i?.en ?? sk.id) : (i?.th ?? sk.id),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: IconText(
                  s.cooldownSeconds((sk.cooldownMs / 1000).toStringAsFixed(1))),
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
      IconText(s.classOutfits,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      SizedBox(
        height: 104,
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final c in classes)
            Container(
              width: 80,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(4),
              decoration: inkBox(
                  fill: c.id == cls ? Palette.sun : Palette.paper, radius: 12),
              child: Column(children: [
                Expanded(
                    child: Image.asset('assets/game/cat/bare_${c.id}.png',
                        fit: BoxFit.contain)),
                IconText(s.className(c.id),
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      IconText(s.looksFound(found, wd.collection.length),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
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
              padding: const EdgeInsets.all(6),
              decoration: inkBox(
                  border: e.unlocked ? Palette.ink : Palette.inkSoft,
                  radius: 12),
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

/// 🎁 Events: daily gift + yarn bundle, rewarded ads only (D-003).
class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  Future<void> _watch(String placement) async {
    await ref.read(adGiftsProvider).watch(placement);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final ads = ref.read(adServiceProvider);
    Widget row(
        String icon, String title, String placement, VoidCallback onTap) {
      final left = ads.remainingToday(placement);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: inkBox(),
        child: Row(children: [
          IconText(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                IconText(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                IconText(s.adsLeft(left),
                    style: const TextStyle(color: Palette.inkSoft)),
              ])),
          if (left > 0)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: inkBox(fill: Palette.sun, radius: 12),
                child: IconText(s.watch,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
    }

    return ListView(children: [
      _pageTitle(s.navEvents),
      row('🎁', s.dailyGift, 'daily_gift', () => _watch('daily_gift')),
      row('🧶', s.yarnBundle, 'yarn_bundle', () => _watch('yarn_bundle')),
    ]);
  }
}

/// 🛒 Shop: Supporter Pack + cosmetics, behind the parental gate (T-025).
class ShopPage extends ConsumerWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return ListView(children: [
      _pageTitle(s.navShop),
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: inkBox(fill: const Color(0xFFFFF3D6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          IconText('💛 ${s.supporterPack}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          IconText(s.supporterDesc),
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
                decoration: inkBox(fill: Palette.lime, radius: 12),
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
    ]);
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
      child: Column(children: [
        row(s.music, audio.bgmEnabled, audio.setBgmEnabled),
        row(s.sounds, audio.sfxEnabled, audio.setSfxEnabled),
      ]),
    );
  }
}
