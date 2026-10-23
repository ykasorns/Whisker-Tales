import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../debug/telemetry.dart';
import '../l10n/strings.dart';
import 'home_page.dart';
import 'game_icon.dart';
import 'palette.dart';

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
      backgroundColor: Palette.paper,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Palette.ink, width: 3)),
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
          Wrap(spacing: 14, children: [
            for (final (icon, v) in [
              ('🐟', r.reward[Currency.goldfish]),
              ('🧶', r.reward[Currency.yarn]),
              ('🥚', r.reward[Currency.eggs]),
              ('⭐ EXP', r.exp),
            ])
              if (v > 0)
                IconText('$icon +${fmtNum(v)}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
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
              decoration: inkBox(fill: Palette.lime),
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
              color: good ? Palette.paper : const Color(0xFFF1E8F4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: good ? const Color(0xFF4E8A1F) : Palette.plum,
                  width: 2),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              GameIcon.event(d.id, d.icon, size: 18),
              IconText('${badge(d)} ·${a.wavesLeft}',
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
                    decoration: inkBox(radius: 6, width: 1.5),
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

/// Class skills (T-008): icons that light up when cast — they cast by
/// themselves (D-004), so these are not buttons.
class SkillBar extends ConsumerStatefulWidget {
  const SkillBar({super.key});

  @override
  ConsumerState<SkillBar> createState() => _SkillBarState();
}

class _SkillBarState extends ConsumerState<SkillBar> {
  StreamSubscription<CombatEvent>? _sub;
  final _flash = <String, int>{};

  @override
  void initState() {
    super.initState();
    _sub = ref.read(idleLoopProvider).combatEvents.listen((e) {
      if (e is SkillCast && e.unitId == 'mochi' && mounted) {
        setState(() => _flash[e.skillId] = (_flash[e.skillId] ?? 0) + 1);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.read(catClassProvider).combatSpec().skills;
    final info = ref.read(skillBookProvider).info;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      for (final sk in skills)
        TweenAnimationBuilder<double>(
          key: ValueKey('${sk.id}${_flash[sk.id] ?? 0}'),
          tween: Tween(begin: 1, end: 0),
          duration: const Duration(milliseconds: 600),
          builder: (context, glow, _) => Container(
            width: 40,
            height: 40,
            margin: const EdgeInsets.only(right: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Palette.paper,
              border: Border.all(color: Palette.ink, width: 2.5),
              boxShadow: [
                BoxShadow(
                    color: Palette.sun
                        .withValues(alpha: (_flash[sk.id] == null ? 0 : glow)),
                    blurRadius: 12,
                    spreadRadius: 4)
              ],
            ),
            child: GameIcon.skill(sk.id, info[sk.id]?.icon ?? '✨', size: 28),
          ),
        ),
    ]);
  }
}
