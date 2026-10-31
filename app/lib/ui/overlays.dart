import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../debug/telemetry.dart';
import '../l10n/strings.dart';
import 'home_page.dart';
import 'game_icon.dart';
import 'palette.dart';
import 'pets_tab.dart' show PetPicture;

/// "Welcome back" (GDD v0.4 §8): what Mochi farmed while away. One button,
/// no ×2 ad (D-003). Shown only when at least a minute is credited.
Future<void> showOfflineReward(BuildContext context, WidgetRef ref) async {
  final offline = ref.read(offlineRewardProvider);
  final r = offline.checkIn();
  if (kDebugTelemetry) {
    DebugTelemetryOverlay.lastOfflineMinutes = r.creditedMinutes;
  }
  if (r.creditedMinutes < 1 || !context.mounted) {
    offline.claim(); // nothing to show; still marks the window used
    return;
  }
  final s = AppLocalizations.of(context);
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      backgroundColor: Palette.storyPaper,
      shadowColor: Palette.inkSoft.withValues(alpha: 0.32),
      shape: const ContinuousRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(30))),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Image.asset('assets/game/cat/sleep.png', height: 110),
          IconText(s.welcomeBack,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          IconText(s.awayFarmed(r.creditedMinutes),
              textAlign: TextAlign.center),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final (icon, v) in [
              ('🐟 ${s.curFish}', r.reward[Currency.goldfish]),
              ('🧶 ${s.curYarn}', r.reward[Currency.yarn]),
              ('🥚 ${s.curEggs}', r.reward[Currency.eggs]),
              ('⭐ EXP', r.exp),
            ])
              if (v > 0)
                StoryTag(
                  color: const Color(0xFFFFEDCF),
                  child: IconText('$icon +${fmtNum(v)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w900)),
                ),
          ]),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () {
              offline.claim();
              Navigator.of(ctx).pop();
            },
            child: Container(
              height: 56,
              alignment: Alignment.center,
              decoration: storybookButton(
                  fill: Palette.lime, accent: Palette.teal, radius: 10),
              child: IconText(s.claim,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800)),
            ),
          ),
        ]),
      ),
    ),
  );
}

/// Road-event chips (D-008, D-013): icon + ▲/▼ + waves left, and a small 📺
/// button when an ad can boost (good) or cleanse (bad). No countdowns, no
/// pop-ups.
class RoadChips extends ConsumerWidget {
  const RoadChips({super.key});

  static String badge(RoadEventDef d) => [
        for (final f in d.effects)
          if (f.stat != null)
            '${const {
              'atk': '⚔️',
              'hp': '❤️',
              'def': '🛡️',
              'evade': '💨',
              'attack_speed': '⚡'
            }[f.stat]}${f.pct > 0 ? '▲' : '▼'}'
          else
            '🧶×${f.multPct ~/ 100}',
      ].join();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final road = ref.read(roadEventsProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      for (final a in road.active)
        Builder(builder: (_) {
          final d = road.defOf(a.uid);
          final good = a.kind == RoadEventKind.good;
          bool ad = false;
          try {
            ad = road.canOfferAd(a.uid);
          } catch (_) {}
          return Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: good
                    ? const [Color(0xFFF4F9E9), Color(0xFFD9EFC1)]
                    : const [Color(0xFFF5EEF7), Color(0xFFE2D2EA)],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: (good ? Palette.lime : Palette.plum)
                      .withValues(alpha: 0.25),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GameIcon.event(d.id, d.icon, size: 18),
              IconText(
                  '${AppLocalizations.of(context).lang == 'en' ? d.nameEn : d.nameTh} ${badge(d)} ·${a.wavesLeft}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
              if (ad) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => good
                      ? road.boostWithAd(a.uid)
                      : road.cleanseWithAd(a.uid),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration:
                        storybookCard(fill: Palette.parchment, radius: 6),
                    child: IconText(good ? '📺×2' : '📺✖',
                        style: const TextStyle(fontSize: 11)),
                  ),
                ),
              ],
            ]),
          );
        }),
    ]);
  }
}

/// Class skills (T-008): circles that light up when cast — they cast by
/// themselves (D-004), so these are not buttons. A dark sweep with the
/// seconds left shows when each skill is ready again (YK 2026-10-23); no
/// sweep between fights. [speed] is the game speed, so the count is in real
/// seconds.
/// Seconds left on a painted round badge hung on the circle's bottom-right.
Widget _cooldownBadge(int secs, double d, double out) => Positioned(
      right: -out,
      bottom: -out,
      width: d,
      height: d,
      child: Stack(alignment: Alignment.center, children: [
        Positioned.fill(
            child: Image.asset('assets/game/ui/ui_badge_cooldown.png',
                fit: BoxFit.contain)),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('$secs',
              style: TextStyle(
                  color: Palette.ink,
                  fontSize: d * 0.5,
                  height: 1,
                  fontWeight: FontWeight.w900)),
        ),
      ]),
    );

class SkillBar extends ConsumerStatefulWidget {
  const SkillBar({super.key, required this.speed});

  final double Function() speed;

  @override
  ConsumerState<SkillBar> createState() => _SkillBarState();
}

class _SkillBarState extends ConsumerState<SkillBar> {
  StreamSubscription<CombatEvent>? _sub;
  Timer? _tick;
  final _flash = <String, int>{};

  @override
  void initState() {
    super.initState();
    _sub = ref.read(idleLoopProvider).combatEvents.listen((e) {
      if (e is SkillCast && mounted) {
        final key = e.unitId == 'mochi' ? e.skillId : e.unitId;
        setState(() => _flash[key] = (_flash[key] ?? 0) + 1);
      }
    });
    // the sweep moves smoothly while a fight runs; idle otherwise
    _tick = Timer.periodic(const Duration(milliseconds: 80), (_) {
      if (mounted && ref.read(idleLoopProvider).fightView.isNotEmpty) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.read(catClassProvider).combatSpec().skills;
    final info = ref.read(skillBookProvider).info;
    final view = ref.read(idleLoopProvider).fightView;
    final mochi = view.where((u) => u.id == 'mochi');
    SkillView? timer(String id) {
      for (final u in mochi) {
        for (final k in u.skills) {
          if (k.id == id) return k;
        }
      }
      return null;
    }

    // pets on the field: one smaller circle per skill, after Mochi's
    final pets = ref.read(petsProvider);
    final petRows = <({PetDef def, SkillView? timer})>[
      for (final u in view)
        if (u.isPartner && u.id.startsWith('pet_'))
          if (pets?.rules.byId(u.id.substring(4)) case final def?)
            if (def.skill != null)
              (
                def: def,
                timer: u.skills.isEmpty ? null : u.skills.first,
              ),
    ];

    Widget circle(double size, Widget face, SkillView? t, int flash) {
      final frac = t == null || t.totalMs == 0
          ? 0.0
          : (t.remainingMs / t.totalMs).clamp(0.0, 1.0);
      final secs = t == null || t.remainingMs == 0
          ? 0
          : (t.remainingMs / widget.speed() / 1000).ceil();
      return TweenAnimationBuilder<double>(
        key: ValueKey('c${face.hashCode}$flash'),
        tween: Tween(begin: 1, end: 0),
        duration: const Duration(milliseconds: 600),
        builder: (context, glow, _) => Container(
          width: size,
          height: size,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const RadialGradient(
                colors: [Colors.white, Palette.paper, Palette.storyPaper]),
            boxShadow: [
              BoxShadow(
                  color: Palette.sun.withValues(alpha: flash == 0 ? 0 : glow),
                  blurRadius: 12,
                  spreadRadius: 4)
            ],
          ),
          // the count sits on a painted badge at the corner, outside the
          // circle, so the skill's picture stays readable while it recharges
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned.fill(
              child: ClipOval(
                child: Stack(alignment: Alignment.center, children: [
                  face,
                  if (frac > 0)
                    Positioned.fill(
                        child: CustomPaint(painter: _CooldownPainter(frac))),
                ]),
              ),
            ),
            if (secs > 0) _cooldownBadge(secs, size * 0.46, size * 0.04),
          ]),
        ),
      );
    }

    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final sk in skills)
        Builder(builder: (_) {
          final t = timer(sk.id);
          final frac = t == null || t.totalMs == 0
              ? 0.0
              : (t.remainingMs / t.totalMs).clamp(0.0, 1.0);
          final secs = t == null || t.remainingMs == 0
              ? 0
              : (t.remainingMs / widget.speed() / 1000).ceil();
          return TweenAnimationBuilder<double>(
            key: ValueKey('${sk.id}${_flash[sk.id] ?? 0}'),
            tween: Tween(begin: 1, end: 0),
            duration: const Duration(milliseconds: 600),
            builder: (context, glow, _) => Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                    colors: [Colors.white, Palette.paper, Palette.storyPaper]),
                boxShadow: [
                  BoxShadow(
                      color: Palette.sun.withValues(
                          alpha: (_flash[sk.id] == null ? 0 : glow)),
                      blurRadius: 12,
                      spreadRadius: 4)
                ],
              ),
              child: Stack(clipBehavior: Clip.none, children: [
                Positioned.fill(
                  child: ClipOval(
                    child: Stack(alignment: Alignment.center, children: [
                      GameIcon.skill(sk.id, info[sk.id]?.icon ?? '✨', size: 32),
                      if (frac > 0)
                        Positioned.fill(
                            child:
                                CustomPaint(painter: _CooldownPainter(frac))),
                    ]),
                  ),
                ),
                if (secs > 0) _cooldownBadge(secs, 22, 2),
              ]),
            ),
          );
        }),
      for (final r in petRows)
        circle(38, PetPicture(id: r.def.id, icon: r.def.icon, size: 26),
            r.timer, _flash['pet_${r.def.id}'] ?? 0),
    ]);
  }
}

/// The dark pie over a skill that is still cooling down: [frac] of the
/// circle is covered, clockwise from the top, shrinking to nothing.
class _CooldownPainter extends CustomPainter {
  _CooldownPainter(this.frac);
  final double frac;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawArc(Offset.zero & size, -math.pi / 2, 2 * math.pi * frac, true,
        Paint()..color = const Color(0xB0000000));
  }

  @override
  bool shouldRepaint(_CooldownPainter old) => old.frac != frac;
}

/// "Fail" card over the scene when Mochi loses a boss, or rests after a lost
/// wave streak (YK 2026-10-23). A small card, not a pop-up: it never pauses
/// the game, goes away by itself after about 3 s or on a tap, offers no ad
/// and no retry button (losing costs nothing — GDD §14, D-008), and never
/// stacks.
class FailCard extends ConsumerStatefulWidget {
  /// How long the card stays when nobody taps it.
  static const showFor = Duration(seconds: 3);

  const FailCard({super.key, this.events});

  /// Loop events; the idle loop's own unless a test passes one.
  final Stream<IdleEvent>? events;

  @override
  ConsumerState<FailCard> createState() => _FailCardState();
}

class _FailCardState extends ConsumerState<FailCard> {
  StreamSubscription<IdleEvent>? _sub;
  Timer? _hide;
  bool _boss = false, _shown = false;
  int _tip = 0;
  bool _inLossStreak = false;

  @override
  void initState() {
    super.initState();
    _sub = (widget.events ?? ref.read(idleLoopProvider).events).listen((e) {
      switch (e) {
        case BossResult(won: false):
          _show(boss: true);
        case WaveFailed():
          // one card per streak of lost waves, not one per retry
          if (!_inLossStreak) _show(boss: false);
          _inLossStreak = true;
        case WaveCleared() || BossResult(won: true):
          _inLossStreak = false;
      }
    });
  }

  void _show({required bool boss}) {
    if (!mounted) return;
    _hide?.cancel();
    setState(() {
      _boss = boss;
      _shown = true;
      _tip = (_tip + 1) % 4;
    });
    _hide = Timer(FailCard.showFor, _dismiss);
  }

  void _dismiss() {
    if (mounted) setState(() => _shown = false);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hide?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final tip = [s.tipKnit, s.tipLevel, s.tipLibrary, s.tipPets][_tip];
    return IgnorePointer(
      ignoring: !_shown,
      child: Align(
        alignment: const Alignment(0, 0.15),
        child: AnimatedScale(
          scale: _shown ? 1 : 0.8,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedOpacity(
            opacity: _shown ? 1 : 0,
            duration: const Duration(milliseconds: 250),
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                key: const ValueKey('fail-card'),
                width: 280,
                padding: const EdgeInsets.all(14),
                decoration: storybookCard(
                    fill: const Color(0xFFFFE2CE),
                    accent: Palette.coral,
                    radius: 11),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const GameIcon('sadcat', size: 56),
                    const SizedBox(width: 10),
                    IconText(s.failTitle,
                        style: const TextStyle(
                            fontSize: 30, fontWeight: FontWeight.w900)),
                  ]),
                  const SizedBox(height: 6),
                  IconText(_boss ? s.failBoss : s.failWave,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  IconText(tip,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: Palette.inkSoft)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
