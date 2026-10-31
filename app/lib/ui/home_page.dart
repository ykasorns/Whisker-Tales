import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../game_view.dart';
import '../l10n/strings.dart';
import 'craft_sheet.dart';
import 'frames.dart';
import 'overlays.dart';
import 'game_icon.dart';
import 'palette.dart';
import 'yarn_basket.dart';

String fmtNum(int n) => n >= 1000000
    ? '${(n / 1000000).toStringAsFixed(1)}M'
    : n >= 10000
        ? '${(n / 1000).toStringAsFixed(1)}K'
        : '$n';

/// 🏠 Home (GDD v0.4 §11 + v0.5 §1): the fight on top (60%), the farm panel
/// below (40%) — gear slots, auto-knit and the yarn ball.
class HomePage extends ConsumerWidget {
  const HomePage({super.key, required this.avatarRules, required this.driver});
  final AvatarRules avatarRules;
  final GameDriver driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(children: [
      Expanded(
        flex: (AppLayout.gameViewportRatio * 100).round(),
        child: Stack(children: [
          Positioned.fill(
              child: GameView(avatarRules: avatarRules, driver: driver)),
          Positioned.fill(child: _Hud(driver: driver)),
          const Positioned.fill(child: FailCard()),
        ]),
      ),
      Expanded(
        flex: (AppLayout.uiPanelRatio * 100).round(),
        child: StorybookPaper(child: FarmPanel(driver: driver)),
      ),
    ]);
  }
}

class _Hud extends ConsumerWidget {
  const _Hud({required this.driver});
  final GameDriver driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: driver.ui$,
      builder: (context, _, __) {
        final loop = ref.read(idleLoopProvider);
        final rules = ref.read(idleRulesProvider);
        final wallet = ref.read(walletProvider);
        final cat = ref.read(catProgressProvider);
        final cls = ref.read(catClassProvider);
        // the cat as it fights: gear, pets, research and road events
        final power =
            ref.read(powerScoreProvider).of(ref.read(catSpecProvider)().stats);
        final st = loop.state;
        final plan = loop.plan;
        final frontier = st.farmPage == st.clearedPage + 1;
        final ready = loop.bossReady;
        final boss = loop.isBossFight;
        final speeds = rules.speedsFor(st.clearedPage);
        return Stack(children: [
          // top-left: profile, chapter banner and the boss button stacked
          // (kept above Mochi's health bar: see [_clusterRoom])
          Positioned.fill(
            child: LayoutBuilder(builder: (context, area) {
              final room = _clusterRoom(area.maxHeight);
              return Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 6),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: room),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: _TopLeftCluster(
                        key: const Key('hud-cluster'),
                        profileTitle: s.catTitle(s.className(cls.current)),
                        level: s.level(cat.level),
                        expFraction:
                            cat.expToNext == 0 ? 1 : cat.exp / cat.expToNext,
                        power: '${s.shortPower} ${fmtNum(power)}',
                        chapter: s.chapterPage(rules.chapterOf(st.farmPage),
                            rules.pageInChapter(st.farmPage)),
                        waves: plan.waves,
                        wavesDone: loop.waveIndex,
                        state: boss
                            ? s.fightingBoss
                            : ready && frontier
                                ? s.tapForBoss
                                : null,
                        semantics: ready
                            ? s.tapForBoss
                            : s.farm(math.min(loop.waveIndex, plan.waves),
                                plan.waves),
                        bossButton: GestureDetector(
                          onTap: ready && frontier && !boss
                              ? () => loop.challengeBoss()
                              : null,
                          child: _BossButton(
                            progress: boss
                                ? 1
                                : math.min(1, loop.waveIndex / plan.waves),
                            ready: ready && frontier,
                            face: ref
                                .read(chapterBookProvider)
                                .bossOf(rules, st.clearedPage + 1),
                          ),
                        ),
                        autoLabel: '${s.auto} ${loop.autoBoss ? s.on : s.off}',
                        autoOn: loop.autoBoss,
                        onAuto: () => loop.autoBoss = !loop.autoBoss,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          // wallet (top-right)
          Positioned(
            right: 6,
            top: 6,
            child: Column(
                key: const Key('hud-wallet'),
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _WalletTag(
                    label: s.curFish,
                    icon: '🐟',
                    value: fmtNum(wallet.balance(Currency.goldfish)),
                  ),
                  const SizedBox(height: 2),
                  _WalletTag(
                    label: s.curYarn,
                    icon: '🧶',
                    value: fmtNum(wallet.balance(Currency.yarn)),
                  ),
                  const SizedBox(height: 2),
                  _WalletTag(
                    label: s.curEggs,
                    icon: '🥚',
                    value: '${wallet.balance(Currency.eggs)}',
                  ),
                  const SizedBox(height: 4),
                  _SpeedControl(driver: driver, speeds: speeds),
                  const RoadChips(),
                ]),
          ),
          Positioned(
              left: 10, bottom: 10, child: SkillBar(speed: () => driver.speed)),
        ]);
      },
    );
  }

  /// Height the top-left cluster may use: from the top edge down to just
  /// above Mochi's status icons and health bar (the scene puts his bar at
  /// `kMochiBarFrac` of the scene height above the ground line).
  static double _clusterRoom(double sceneHeight) {
    final barTop =
        sceneHeight * (BattleGame.groundFrac - BattleGame.mochiBarFrac);
    return math.max(60, barTop - 34 - 6);
  }

  static const _bold =
      TextStyle(fontWeight: FontWeight.w800, color: Palette.ink, fontSize: 14);
}

/// Profile card, chapter banner and the boss button, one column on the
/// painted frames. Every text sits in its frame's measured paper area and
/// scales down rather than spilling out.
class _TopLeftCluster extends StatelessWidget {
  const _TopLeftCluster({
    super.key,
    required this.profileTitle,
    required this.level,
    required this.expFraction,
    required this.power,
    required this.chapter,
    required this.waves,
    required this.wavesDone,
    required this.state,
    required this.semantics,
    required this.bossButton,
    required this.autoLabel,
    required this.autoOn,
    required this.onAuto,
  });

  final String profileTitle, level, power, chapter, autoLabel, semantics;

  /// "Tap for boss" / "Fighting boss", or null while farming (wave dots).
  final String? state;
  final double expFraction;
  final int waves, wavesDone;
  final Widget bossButton;
  final bool autoOn;
  final VoidCallback onAuto;

  static const _ink =
      TextStyle(fontWeight: FontWeight.w900, color: Palette.ink);

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(
        key: const Key('hud-profile'),
        width: 220,
        height: 90,
        child: StretchFrame(
          frame: 'profile',
          builder: (context, g) {
            final medal = g.named('medallion');
            return Stack(children: [
              Positioned.fromRect(
                rect: medal,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: IconText(level, style: _ink.copyWith(fontSize: 16)),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: g.content,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: IconText(profileTitle,
                              maxLines: 1, style: _ink.copyWith(fontSize: 14)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                            value: expFraction,
                            color: Palette.teal,
                            backgroundColor: Palette.sheet,
                            minHeight: 5),
                      ),
                      const SizedBox(height: 2),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: IconText('🐾 $power',
                              maxLines: 1,
                              style: _ink.copyWith(
                                  fontSize: 13, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ]),
              ),
            ]);
          },
        ),
      ),
      const SizedBox(height: 2),
      Semantics(
        label: '$chapter, $semantics',
        child: SizedBox(
          width: 196,
          height: 66,
          child: StretchFrame(
            frame: 'chapter',
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IconText(chapter,
                      maxLines: 1, style: _ink.copyWith(fontSize: 12.5)),
                ),
              ),
              if (state != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: IconText(state!,
                        maxLines: 1,
                        style: _ink.copyWith(
                            fontSize: 10.5, color: Palette.coral)),
                  ),
                )
              else
                Row(mainAxisSize: MainAxisSize.min, children: [
                  for (var i = 0; i < waves; i++)
                    Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.all(1.5),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < wavesDone
                              ? Palette.lime
                              : Palette.ink.withValues(alpha: .2)),
                    ),
                ]),
            ]),
          ),
        ),
      ),
      const SizedBox(height: 2),
      Row(mainAxisSize: MainAxisSize.min, children: [
        Semantics(
            button: true,
            label: semantics,
            child: SizedBox(
                width: 60, height: 60, child: FittedBox(child: bossButton))),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onAuto,
          child: SizedBox(
            width: 96,
            height: 42,
            child: StretchFrame(
              frame: 'action',
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IconText(autoLabel,
                      maxLines: 1,
                      style: _ink.copyWith(
                          fontSize: 12,
                          color: autoOn ? Palette.coral : Palette.ink)),
                ),
              ),
            ),
          ),
        ),
      ]),
    ]);
  }
}

class _WalletTag extends StatelessWidget {
  const _WalletTag({
    required this.label,
    required this.icon,
    required this.value,
  });

  final String label, icon, value;

  /// Natural width of the currency frame at this height is 143 dp: the plus
  /// button sits in the right cap, text only in the paper.
  static const _h = 31.0;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 146,
        height: _h,
        child: StretchFrame(
          frame: 'currency',
          builder: (context, g) => Stack(children: [
            Positioned.fromRect(
              rect: g.content,
              child: Align(
                alignment: Alignment.centerLeft,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: IconText(
                    '$icon $label  $value',
                    maxLines: 1,
                    style: _Hud._bold.copyWith(fontSize: 11.5),
                  ),
                ),
              ),
            ),
            // the art's round button is empty: the plus is live type
            Positioned.fromRect(
              rect: g.named('button'),
              child: const Center(
                child: Text('+',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        height: 1,
                        shadows: [
                          Shadow(color: Palette.ink, blurRadius: 2),
                        ])),
              ),
            ),
          ]),
        ),
      );
}

/// Kept with the wallet at the top-right so a full row of class and pet
/// cooldowns can use the bottom edge of the scene without being covered.
class _SpeedControl extends StatelessWidget {
  const _SpeedControl({required this.driver, required this.speeds});

  final GameDriver driver;
  final List<double> speeds;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const Key('game-speed-control'),
        onTap: speeds.length < 2
            ? null
            : () {
                final i = speeds.indexOf(driver.speed);
                driver.speed = speeds[(i + 1) % speeds.length];
              },
        child: Opacity(
          opacity: speeds.length < 2 ? 0.5 : 1,
          child: SizedBox(
            width: 90,
            height: 40,
            child: StretchFrame(
              frame: 'action',
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IconText(
                    '▶ x${driver.speed == driver.speed.roundToDouble() ? driver.speed.toInt() : driver.speed}',
                    maxLines: 1,
                    style: _Hud._bold.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}

class _BossButton extends StatelessWidget {
  const _BossButton(
      {required this.progress, required this.ready, required this.face});
  final double progress;
  final bool ready;
  final String face;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              color: Palette.coral,
              backgroundColor: Palette.sheet),
        ),
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.paper,
              boxShadow: [
                BoxShadow(
                  color: (ready ? Palette.coral : Palette.inkSoft)
                      .withValues(alpha: 0.28),
                  blurRadius: 7,
                  offset: const Offset(0, 2),
                ),
              ]),
          clipBehavior: Clip.antiAlias,
          child: ColorFiltered(
            colorFilter: ready
                ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                : const ColorFilter.matrix([
                    0.33,
                    0.33,
                    0.33,
                    0,
                    0,
                    0.33,
                    0.33,
                    0.33,
                    0,
                    0,
                    0.33,
                    0.33,
                    0.33,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
            child: Image.asset('assets/game/ui/ui_bossface_$face.png',
                fit: BoxFit.cover),
          ),
        ),
      ]),
    );
  }
}

/// The 40% farm panel: gear slots, auto-knit toggles, the yarn ball.
class FarmPanel extends ConsumerStatefulWidget {
  const FarmPanel({super.key, required this.driver});
  final GameDriver driver;

  static String slotArt(
      GearSlot slot, GearItem? item, String cls, WardrobeRules w) {
    final tier = item?.tier ?? 1;
    return switch (slot) {
      GearSlot.weapon => 'gear/${w.weaponArt[cls]}_$tier',
      GearSlot.hat ||
      GearSlot.scarf ||
      GearSlot.bag =>
        'gear/${slot.name}_$tier',
      _ => 'gear/icon_${slot.name}_$tier',
    };
  }

  @override
  ConsumerState<FarmPanel> createState() => _FarmPanelState();
}

class _FarmPanelState extends ConsumerState<FarmPanel> {
  StreamSubscription<(CraftResult, bool)>? _sub;
  int _wiggle = 0;
  ({String art, bool kept, int key})? _pop;

  GameDriver get driver => widget.driver;

  @override
  void initState() {
    super.initState();
    _sub = ref.read(autoCraftProvider).crafted.listen((e) {
      final (r, kept) = e;
      final cls = ref.read(catClassProvider).current;
      if (!mounted) return;
      setState(() {
        _wiggle++;
        _pop = (
          art: FarmPanel.slotArt(
              r.slot, r.item, cls, ref.read(wardrobeRulesProvider)),
          kept: kept,
          key: _wiggle,
        );
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: driver.ui$,
      builder: (context, _, __) {
        final basket = ref.read(gearBasketProvider);
        final auto = ref.read(autoCraftProvider);
        final yarn = ref.read(walletProvider).balance(Currency.yarn);
        final cls = ref.read(catClassProvider).current;
        final wr = ref.read(wardrobeRulesProvider);
        return LayoutBuilder(builder: (context, box) {
          // The book keeps the same width as the old shelf, but shrinks on
          // short phones so the basket and its controls remain reachable.
          final panelH = box.maxHeight.isFinite ? box.maxHeight : 300.0;
          final shelfH =
              math.min(panelH * 0.51, (box.maxWidth - 20) * 778 / 2022);
          // The painted book curls upward along its lower edge. Leave more
          // room below the second row so boots and gloves stay on the page.
          final slotSize = ((shelfH - 34) / 2).clamp(30.0, 55.0);
          Widget slotOf(GearSlot slot) => SizedBox(
                width: slotSize,
                height: slotSize,
                child: _Slot(
                  slot: slot,
                  open: basket.isOpen(slot),
                  item: basket.equipped(slot),
                  hasNew: basket.stashed(slot) != null,
                  art: FarmPanel.slotArt(slot, basket.equipped(slot), cls, wr),
                  unlockPage: basket.rules.slots[slot]!.unlockPage,
                  onTap: basket.stashed(slot) == null
                      ? null
                      : () => showCraftSheet(context, ref,
                          stashed: basket.stashed(slot)),
                ),
              );
          const slots = GearSlot.values;
          Widget shelfRow(List<GearSlot> row) => Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final slot in row) slotOf(slot)]);
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
            child: Column(children: [
              // The painted pages are behind the live, tappable gear slots.
              SizedBox(
                height: shelfH,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset('assets/game/ui/ui_storybook_shelf.webp',
                      fit: BoxFit.fill, filterQuality: FilterQuality.medium),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 7, 14, 21),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          shelfRow(slots.sublist(0, 4)),
                          const SizedBox(height: 6),
                          shelfRow(slots.sublist(4)),
                        ]),
                  ),
                ]),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Row(children: [
                  // the two auto-knit switches, one above the other
                  SizedBox(
                    width: box.maxWidth * 0.42,
                    // ≥ 48 dp tall on a normal phone; scaled down only when
                    // the panel is too short for both
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: SizedBox(
                        width: box.maxWidth * 0.42,
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _AutoKnitToggle(
                                  label: s.autoCraft,
                                  on: auto.running,
                                  hasYarn: yarn > 0,
                                  onTap: () => auto.running
                                      ? auto.stop()
                                      : auto.start()),
                              const SizedBox(height: 8),
                              _Toggle(
                                  label: auto.rule.mode == AutoCraftMode.equip
                                      ? s.betterEquip
                                      : s.betterStash,
                                  on: auto.rule.mode == AutoCraftMode.equip,
                                  onTap: () => auto.configure(AutoCraftRule(
                                      on: auto.running,
                                      mode:
                                          auto.rule.mode == AutoCraftMode.equip
                                              ? AutoCraftMode.stash
                                              : AutoCraftMode.equip))),
                            ]),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // the basket: the big button — it opens the knit sheet
                  // (odds first), and its balls move when auto-knit knits
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: s.knit,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: yarn < 1
                            ? null
                            : () => showCraftSheet(context, ref),
                        child: LayoutBuilder(builder: (context, area) {
                          const tagH = 30.0;
                          final basketH = math.max(
                              72.0,
                              math.min(area.maxHeight,
                                  area.maxWidth / BasketArt.aspect));
                          return Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                Center(
                                  child: YarnBasket(
                                      height: basketH,
                                      knit: _wiggle,
                                      quiet: true,
                                      empty: yarn < 1),
                                ),
                                // the tag hangs over the basket's front
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Center(
                                    child: ConstrainedBox(
                                      constraints: BoxConstraints(
                                          maxWidth: area.maxWidth * .96),
                                      child: SizedBox(
                                        height: tagH + 14,
                                        child: StretchFrame(
                                          frame: 'action',
                                          child: Center(
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: IconText(
                                                  yarn < 1
                                                      ? s.noYarn
                                                      : '${s.knit} · ${s.curYarn} 🧶 ${fmtNum(yarn)}',
                                                  style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: yarn < 1
                                                          ? Palette.inkSoft
                                                          : Palette.ink,
                                                      fontWeight:
                                                          FontWeight.w900)),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                if (_pop case final p?)
                                  Positioned(
                                    top: 0,
                                    child: KnitPop(
                                        key: ValueKey(p.key),
                                        art: p.art,
                                        kept: p.kept,
                                        onDone: () {
                                          if (mounted && _pop?.key == p.key) {
                                            setState(() => _pop = null);
                                          }
                                        }),
                                  ),
                              ]);
                        }),
                      ),
                    ),
                  ),
                ]),
              ),
            ]),
          );
        });
      },
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    required this.slot,
    required this.open,
    required this.item,
    required this.hasNew,
    required this.art,
    required this.unlockPage,
    this.onTap,
  });
  final GearSlot slot;
  final bool open, hasNew;
  final GearItem? item;
  final String art;
  final int unlockPage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return Container(
        alignment: Alignment.center,
        child: IconText(
            '🔒\n${AppLocalizations.of(context).unlockAt(unlockPage)}',
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 9, height: 1.1, color: Palette.inkSoft)),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Positioned.fill(
          child: Container(
            padding: const EdgeInsets.all(5),
            child: Opacity(
              opacity: item == null ? 0.65 : 1,
              child: Image.asset('assets/game/$art.png', fit: BoxFit.contain),
            ),
          ),
        ),
        if (hasNew)
          const Positioned(
              right: -6,
              top: -6,
              child: IconText('✨', style: TextStyle(fontSize: 14))),
      ]),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({required this.label, required this.on, required this.onTap});
  final String label;
  final bool on;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: StretchFrame(
            frame: 'action',
            child: Row(children: [
              SizedBox(
                width: 16,
                child: on
                    ? const GameIcon('check', size: 16)
                    : Center(
                        child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Palette.storyEdge))),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: IconText(label,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11.5,
                          color: on ? const Color(0xFF2F6B25) : Palette.ink,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// Auto-knit is a tiny mouse helper: while armed it waits beside an empty
/// basket, then scurries toward the basket whenever yarn is available.
class _AutoKnitToggle extends StatefulWidget {
  const _AutoKnitToggle({
    required this.label,
    required this.on,
    required this.hasYarn,
    required this.onTap,
  });

  final String label;
  final bool on, hasYarn;
  final VoidCallback onTap;

  @override
  State<_AutoKnitToggle> createState() => _AutoKnitToggleState();
}

class _AutoKnitToggleState extends State<_AutoKnitToggle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _run = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));

  bool get _working => widget.on && widget.hasYarn;

  @override
  void initState() {
    super.initState();
    if (_working) _run.repeat();
  }

  @override
  void didUpdateWidget(_AutoKnitToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_working && !_run.isAnimating) {
      _run.repeat();
    } else if (!_working && _run.isAnimating) {
      _run
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _run.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: 52,
          child: StretchFrame(
            frame: 'action',
            child: Row(children: [
              SizedBox(
                width: 30,
                height: 24,
                child: AnimatedBuilder(
                  animation: _run,
                  builder: (context, child) {
                    final reduce =
                        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
                    final t = reduce || !_working ? 0.0 : _run.value;
                    final dash = math.sin(t * math.pi);
                    return Transform.translate(
                      offset: Offset(8 * dash, -2 * math.sin(t * math.pi * 2)),
                      child: child,
                    );
                  },
                  child: Opacity(
                    opacity: widget.on ? 1 : 0.48,
                    child: Image.asset(
                      widget.hasYarn
                          ? 'assets/game/pet/mouse_attack.png'
                          : 'assets/game/pet/mouse_idle.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: IconText(widget.label,
                      maxLines: 1,
                      style: TextStyle(
                          fontSize: 11.5,
                          color:
                              widget.on ? const Color(0xFF2F6B25) : Palette.ink,
                          fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ),
      );
}

/// The knit button: a ball of yarn (D-010). Drawn until `ui_yarn_ball.png`
/// exists; it bobs gently, and wiggles when [wiggle] changes.
class YarnBall extends StatefulWidget {
  const YarnBall({super.key, this.size = 84, this.wiggle = 0});
  final double size;
  final int wiggle;

  @override
  State<YarnBall> createState() => _YarnBallState();
}

class _YarnBallState extends State<YarnBall> with TickerProviderStateMixin {
  late final _bob = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 2400))
    ..repeat();
  late final _wig = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 550));

  @override
  void didUpdateWidget(YarnBall old) {
    super.didUpdateWidget(old);
    if (widget.wiggle != old.wiggle) _wig.forward(from: 0);
  }

  @override
  void dispose() {
    _bob.dispose();
    _wig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedBuilder(
      animation: Listenable.merge([_bob, _wig]),
      builder: (context, child) {
        final t = reduce ? 0.0 : math.sin(_bob.value * 2 * math.pi);
        // wiggle: damped left-right shake with a squash (D-010)
        final w = reduce || !_wig.isAnimating ? 0.0 : _wig.value;
        final shake = math.sin(w * math.pi * 6) * (1 - w);
        return Transform.translate(
          offset: Offset(0, -3 * t.abs()),
          child: Transform.rotate(
            angle: -0.05 * t + 0.25 * shake,
            child: Transform.scale(
                scaleX: 1 + 0.08 * shake,
                scaleY: 1 - 0.08 * shake,
                child: child),
          ),
        );
      },
      child:
          CustomPaint(size: Size.square(widget.size), painter: _YarnPainter()),
    );
  }
}

/// An item popping out of the yarn ball: up and out with a ✨, then it
/// either settles (kept) or fades away into goldfish (recycled).
class KnitPop extends StatelessWidget {
  const KnitPop(
      {super.key,
      required this.art,
      required this.kept,
      this.size = 56,
      this.onDone});
  final String art;
  final bool kept;
  final double size;

  /// Called when the animation ends and nothing is left on screen.
  final VoidCallback? onDone;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      onEnd: onDone,
      builder: (context, v, _) {
        final up = Curves.easeOutBack.transform(math.min(1, v * 1.6));
        // a kept piece lingers a moment (it is in the slot now), then both
        // kinds fade out completely — nothing stays on screen
        final fade = kept
            ? 1 - math.max(0, (v - 0.7) / 0.3)
            : (1 - math.max(0, (v - 0.55) / 0.45));
        return Opacity(
          opacity: fade.clamp(0.0, 1.0).toDouble(),
          child: Transform.translate(
            offset: Offset(kept ? 0 : 30 * math.max(0, v - 0.55), -60 * up),
            child: Transform.scale(
              scale: 0.3 + 0.9 * up,
              child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                        width: size,
                        height: size,
                        child: Image.asset('assets/game/$art.png')),
                    if (v < 0.5)
                      const Positioned(
                          top: -14,
                          child: IconText('✨', style: TextStyle(fontSize: 18))),
                    if (!kept && v > 0.6)
                      const Positioned(
                          right: -18,
                          child:
                              IconText('🐟', style: TextStyle(fontSize: 18))),
                  ]),
            ),
          ),
        );
      },
    );
  }
}

class _YarnPainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final r = s.width * 0.38, o = Offset(s.width * 0.48, s.height * 0.5);
    c.drawPath(
        Path()
          ..moveTo(o.dx + r * 0.8, o.dy + r * 0.5)
          ..quadraticBezierTo(
              o.dx + r * 1.2, o.dy + r * 0.7, o.dx + r * 1.05, o.dy + r * 1.05),
        Paint()
          ..color = Palette.coral
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round);
    c.drawCircle(o, r, Paint()..color = Palette.coral);
    final line = Paint()
      ..color = const Color(0xFFB8423A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final (a, b, cc) in [
      (-0.7, -0.2, 0.5),
      (-0.9, 0.15, 0.6),
      (-0.6, 0.5, 0.45)
    ]) {
      c.drawPath(
          Path()
            ..moveTo(o.dx - r * 0.9, o.dy + r * b)
            ..quadraticBezierTo(o.dx, o.dy + r * (b + a * cc), o.dx + r * 0.9,
                o.dy + r * (b + 0.1)),
          line);
    }
    c.drawCircle(
        o,
        r,
        Paint()
          ..color = Palette.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5);
    c.drawCircle(o.translate(-r * 0.32, -r * 0.4), r * 0.16,
        Paint()..color = const Color(0xCCFFD9C9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
