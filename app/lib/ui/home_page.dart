import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../game_view.dart';
import '../l10n/strings.dart';
import 'craft_sheet.dart';
import 'overlays.dart';
import 'palette.dart';

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
        ]),
      ),
      Expanded(
        flex: (AppLayout.uiPanelRatio * 100).round(),
        child:
            ColoredBox(color: Palette.paper, child: FarmPanel(driver: driver)),
      ),
    ]);
  }
}

class _Hud extends ConsumerWidget {
  const _Hud({required this.driver});
  final GameDriver driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
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
          // profile card (top-left)
          Positioned(
            left: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.fromLTRB(6, 6, 12, 6),
              decoration: inkBox(radius: 16),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Palette.mochi,
                  child: Text('Lv${cat.level}',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Palette.ink)),
                ),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('โมจิ · ${cls.current}',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  SizedBox(
                    width: 90,
                    child: LinearProgressIndicator(
                        value: cat.expToNext == 0 ? 1 : cat.exp / cat.expToNext,
                        color: Palette.teal,
                        backgroundColor: Palette.sheet,
                        minHeight: 5),
                  ),
                  Text('🐾 ${fmtNum(power)}',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
              ]),
            ),
          ),
          // wallet (top-right)
          Positioned(
            right: 10,
            top: 10,
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('🐟 ${fmtNum(wallet.balance(Currency.goldfish))}',
                  style: _bold),
              Text('🧶 ${fmtNum(wallet.balance(Currency.yarn))}', style: _bold),
              Text('🥚 ${wallet.balance(Currency.eggs)}', style: _bold),
              const RoadChips(),
            ]),
          ),
          // page tag + boss button (top-centre)
          Align(
            alignment: const Alignment(0, -0.62),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: inkBox(radius: 10),
                child: Column(children: [
                  Text(
                      s.chapterPage(rules.chapterOf(st.farmPage),
                          rules.pageInChapter(st.farmPage)),
                      style: _bold),
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    for (var i = 0; i < plan.waves; i++)
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < loop.waveIndex
                                ? Palette.lime
                                : Palette.sheet,
                            border: Border.all(color: Palette.ink, width: 1.5)),
                      ),
                  ]),
                ]),
              ),
              const SizedBox(height: 6),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Semantics(
                  button: true,
                  label: ready
                      ? s.tapForBoss
                      : s.farm(
                          math.min(loop.waveIndex, plan.waves), plan.waves),
                  child: GestureDetector(
                    onTap: ready && frontier && !boss
                        ? () => loop.challengeBoss()
                        : null,
                    child: _BossButton(
                      progress:
                          boss ? 1 : math.min(1, loop.waveIndex / plan.waves),
                      ready: ready && frontier,
                      face: (st.clearedPage + 1) % 10 == 0
                          ? 'eraserking'
                          : 'eraserslime',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => loop.autoBoss = !loop.autoBoss,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: inkBox(
                        fill: loop.autoBoss ? Palette.coral : Palette.paper,
                        radius: 12),
                    child: Text('${s.auto}\n${loop.autoBoss ? s.on : s.off}',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color:
                                loop.autoBoss ? Palette.paper : Palette.ink)),
                  ),
                ),
              ]),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                decoration: inkBox(radius: 8, width: 2),
                child: Text(
                    boss
                        ? s.fightingBoss
                        : ready && frontier
                            ? s.tapForBoss
                            : s.farm(math.min(loop.waveIndex, plan.waves),
                                plan.waves),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const Positioned(left: 10, bottom: 10, child: SkillBar()),
          // speed button (bottom-right of the scene)
          Positioned(
            right: 10,
            bottom: 10,
            child: GestureDetector(
              onTap: speeds.length < 2
                  ? null
                  : () {
                      final i = speeds.indexOf(driver.speed);
                      driver.speed = speeds[(i + 1) % speeds.length];
                    },
              child: Opacity(
                opacity: speeds.length < 2 ? 0.5 : 1,
                child: Container(
                  width: 64,
                  height: 44,
                  alignment: Alignment.center,
                  decoration: inkBox(
                      fill: driver.speed > 1 ? Palette.sun : Palette.paper),
                  child: Text(
                      '▶ x${driver.speed == driver.speed.roundToDouble() ? driver.speed.toInt() : driver.speed}',
                      style: _bold),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  static const _bold =
      TextStyle(fontWeight: FontWeight.w800, color: Palette.ink, fontSize: 14);
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
              border: Border.all(color: Palette.ink, width: 2.5)),
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
    final s = S.of(context);
    return ValueListenableBuilder<int>(
      valueListenable: driver.ui$,
      builder: (context, _, __) {
        final basket = ref.read(gearBasketProvider);
        final auto = ref.read(autoCraftProvider);
        final yarn = ref.read(walletProvider).balance(Currency.yarn);
        final cls = ref.read(catClassProvider).current;
        final wr = ref.read(wardrobeRulesProvider);
        return Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
          child: Column(children: [
            Row(children: [
              for (final slot in GearSlot.values)
                Expanded(
                    child: Padding(
                  padding: const EdgeInsets.all(2.5),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: _Slot(
                      slot: slot,
                      open: basket.isOpen(slot),
                      item: basket.equipped(slot),
                      hasNew: basket.stashed(slot) != null,
                      art: FarmPanel.slotArt(
                          slot, basket.equipped(slot), cls, wr),
                      unlockPage: basket.rules.slots[slot]!.unlockPage,
                      onTap: basket.stashed(slot) == null
                          ? null
                          : () => showCraftSheet(context, ref,
                              stashed: basket.stashed(slot)),
                    ),
                  ),
                )),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                  child: _Toggle(
                      label: s.autoCraft,
                      on: auto.running,
                      onTap: () => auto.running ? auto.stop() : auto.start())),
              const SizedBox(width: 8),
              Expanded(
                  child: _Toggle(
                      label: auto.rule.mode == AutoCraftMode.equip
                          ? s.betterEquip
                          : s.betterStash,
                      on: auto.rule.mode == AutoCraftMode.equip,
                      onTap: () => auto.configure(AutoCraftRule(
                          on: auto.running,
                          mode: auto.rule.mode == AutoCraftMode.equip
                              ? AutoCraftMode.stash
                              : AutoCraftMode.equip)))),
            ]),
            Expanded(
              child: Semantics(
                button: true,
                label: s.knit,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: yarn < 1 ? null : () => showCraftSheet(context, ref),
                  child: Opacity(
                    opacity: yarn < 1 ? 0.5 : 1,
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                YarnBall(size: 84, wiggle: _wiggle),
                                if (_pop case final p?)
                                  KnitPop(
                                      key: ValueKey(p.key),
                                      art: p.art,
                                      kept: p.kept),
                              ]),
                          const SizedBox(width: 12),
                          Flexible(
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Text(s.knit,
                                    style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800)),
                                Text(yarn < 1 ? s.noYarn : s.yarnLeft(yarn),
                                    style: const TextStyle(
                                        color: Palette.inkSoft,
                                        fontWeight: FontWeight.w600)),
                              ])),
                        ]),
                  ),
                ),
              ),
            ),
          ]),
        );
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
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Palette.inkSoft, width: 2),
            color: Palette.sheet),
        alignment: Alignment.center,
        child: Text('🔒\n${S.of(context).unlockAt(unlockPage)}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 9, height: 1.1)),
      );
    }
    final color = item == null ? Palette.inkSoft : Palette.grades[item!.grade];
    return GestureDetector(
      onTap: onTap,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          decoration: BoxDecoration(
              color: Palette.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 2.5)),
          padding: const EdgeInsets.all(3),
          child: Opacity(
            opacity: item == null ? 0.35 : 1,
            child: Image.asset('assets/game/$art.png', fit: BoxFit.contain),
          ),
        ),
        if (hasNew)
          const Positioned(
              right: -6,
              top: -6,
              child: Text('✨', style: TextStyle(fontSize: 14))),
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
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration:
              inkBox(fill: on ? Palette.lime : Palette.paper, radius: 12),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(on ? Icons.circle : Icons.circle_outlined,
                size: 12, color: Palette.ink),
            const SizedBox(width: 6),
            Flexible(
                child: Text(label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700))),
          ]),
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
      {super.key, required this.art, required this.kept, this.size = 56});
  final String art;
  final bool kept;
  final double size;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      builder: (context, v, _) {
        final up = Curves.easeOutBack.transform(math.min(1, v * 1.6));
        final fade = kept ? 1.0 : (1 - math.max(0, (v - 0.55) / 0.45));
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
                          child: Text('✨', style: TextStyle(fontSize: 18))),
                    if (!kept && v > 0.6)
                      const Positioned(
                          right: -18,
                          child: Text('🐟', style: TextStyle(fontSize: 18))),
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
