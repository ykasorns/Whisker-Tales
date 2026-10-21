import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'home_page.dart';
import 'palette.dart';
import 'pets_tab.dart';

Widget _pageTitle(String t) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(t,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
    );

Widget _soon(BuildContext context, String icon, String text) => Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(icon, style: const TextStyle(fontSize: 64)),
        const SizedBox(height: 8),
        Text(text,
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
    final s = S.of(context);
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
            _soon(context, '🦉', s.comingSoon),
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
    final s = S.of(context);
    final lang = s.lang;
    final cls = ref.read(catClassProvider);
    final cat = ref.read(catProgressProvider);
    final rules = ref.read(catRulesProvider);
    final skills = ref.read(skillBookProvider);
    final st = cls.combatSpec(extra: ref.read(catExtraStatsProvider)()).stats;
    String pct(Attribute a) => '${(st[a] / 100).toStringAsFixed(1)}%';
    final unlocked = cat.level >= rules.classUnlockLevel;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('Lv.${cat.level} · ${cls.current}',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
      LinearProgressIndicator(
          value: cat.expToNext == 0 ? 1 : cat.exp / cat.expToNext,
          color: Palette.teal,
          minHeight: 6),
      const SizedBox(height: 12),
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final (k, v) in [
          ('❤️ HP', '${st.hp}'),
          ('⚔️ ATK', '${st.atk}'),
          ('🛡️ DEF', '${st.def}'),
          ('💨', pct(Attribute.evade)),
          ('💥', pct(Attribute.crit)),
          ('✨', pct(Attribute.skillDmg)),
        ])
          Container(
            width: 104,
            padding: const EdgeInsets.all(8),
            decoration: inkBox(radius: 10, width: 2),
            child: Column(children: [
              Text(k, style: const TextStyle(fontSize: 12)),
              Text(v, style: const TextStyle(fontWeight: FontWeight.w800))
            ]),
          ),
      ]),
      _pageTitle(s.classPick),
      if (!unlocked) Text(s.classAt(rules.classUnlockLevel)),
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
                child: Text(c.id,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
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
              leading:
                  Text(i?.icon ?? '✨', style: const TextStyle(fontSize: 28)),
              title: Text(lang == 'en' ? (i?.en ?? sk.id) : (i?.th ?? sk.id),
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${(sk.cooldownMs / 1000).toStringAsFixed(1)} s'),
            ),
          );
        }),
    ]);
  }
}

class _WardrobeTab extends ConsumerStatefulWidget {
  const _WardrobeTab();

  @override
  ConsumerState<_WardrobeTab> createState() => _WardrobeTabState();
}

class _WardrobeTabState extends ConsumerState<_WardrobeTab> {
  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final wd = ref.read(wardrobeProvider);
    final cls = ref.read(catClassProvider).current;
    final wr = ref.read(wardrobeRulesProvider);
    return GridView.count(
      padding: const EdgeInsets.all(12),
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: [
        for (final e in wd.collection)
          GestureDetector(
            onTap: !e.unlocked
                ? null
                : () => setState(() => wd.choose(e.slot,
                    wd.styleOn(e.slot) == e.styleId ? null : e.styleId)),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: inkBox(
                  fill: wd.styleOn(e.slot) == e.styleId
                      ? Palette.sun
                      : Palette.paper,
                  radius: 12),
              child: Column(children: [
                Expanded(
                  child: ColorFiltered(
                    colorFilter: e.unlocked
                        ? const ColorFilter.mode(
                            Colors.transparent, BlendMode.dst)
                        : const ColorFilter.mode(Palette.ink, BlendMode.srcIn),
                    child: Image.asset(
                        'assets/game/${FarmPanel.slotArt(e.slot, GearItem(id: '', slot: e.slot, grade: (e.tier - 1) * 2, page: 1, stats: StatBlock(hp: 0, atk: 0, def: 0)), cls, wr)}.png'),
                  ),
                ),
                Text(e.unlocked ? e.styleId : s.lockedLook,
                    style: const TextStyle(fontSize: 11)),
              ]),
            ),
          ),
      ],
    );
  }
}

/// 🏰 Dungeon — v1.1 (D-018).
class DungeonPage extends StatelessWidget {
  const DungeonPage({super.key});

  @override
  Widget build(BuildContext context) =>
      _soon(context, '🏰🔒', S.of(context).dungeonSoon);
}

/// 🎁 Events: daily gift + yarn bundle, rewarded ads only (D-003).
class EventsPage extends ConsumerStatefulWidget {
  const EventsPage({super.key});

  @override
  ConsumerState<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends ConsumerState<EventsPage> {
  Future<void> _watch(String placement, Currency c, String minutesKey) async {
    final ads = ref.read(adServiceProvider);
    if (await ads.show(placement) != AdOutcome.rewarded) return;
    final rule = ref.read(adRulesProvider).placements[placement]!;
    final income = ref.read(incomeModelProvider);
    final page = ref.read(idleLoopProvider).state.farmPage;
    final waves =
        ((rule.params[minutesKey] ?? 0) * income.wavesPerMinute).floor();
    final amount = income.forWaves(page, waves)[c];
    ref.read(walletProvider).add(RewardBundle({c: amount < 1 ? 1 : amount}));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final ads = ref.read(adServiceProvider);
    Widget row(
        String icon, String title, String placement, VoidCallback onTap) {
      final left = ads.remainingToday(placement);
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: inkBox(),
        child: Row(children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                Text(s.adsLeft(left),
                    style: const TextStyle(color: Palette.inkSoft)),
              ])),
          if (left > 0)
            GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: inkBox(fill: Palette.sun, radius: 12),
                child: Text(s.watch,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
        ]),
      );
    }

    return ListView(children: [
      _pageTitle(s.navEvents),
      row(
          '🎁',
          s.dailyGift,
          'daily_gift',
          () => _watch(
              'daily_gift', Currency.goldfish, 'fish_minutes_of_income')),
      row('🧶', s.yarnBundle, 'yarn_bundle',
          () => _watch('yarn_bundle', Currency.yarn, 'yarn_minutes_of_income')),
    ]);
  }
}

/// 🛒 Shop: Supporter Pack + cosmetics, behind the parental gate (T-025).
class ShopPage extends StatelessWidget {
  const ShopPage({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    return ListView(children: [
      _pageTitle(s.navShop),
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: inkBox(fill: const Color(0xFFFFF3D6)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('💛 ${s.supporterPack}',
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(s.supporterDesc),
          const SizedBox(height: 12),
          Opacity(
            opacity:
                0.5, // purchases arrive with T-025 (parental gate + Play Billing)
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: inkBox(fill: Palette.lime, radius: 12),
              child: Text('👨‍👩‍👧 ${s.askParent}',
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    ]);
  }
}
