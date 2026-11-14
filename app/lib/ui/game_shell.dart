import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../debug/telemetry.dart';
import '../game_view.dart';
import '../l10n/strings.dart';
import 'home_page.dart';
import 'overlays.dart';
import 'pages.dart';
import 'away_tracker.dart';
import 'game_icon.dart';
import 'frames.dart';
import 'palette.dart';
import 'story_adventure.dart';

/// The app's frame (D-018): pages above, 5-button menu below. The game
/// keeps running whatever page is open — it is driven from here, not from
/// the (possibly hidden) game view.
class GameShell extends ConsumerStatefulWidget {
  const GameShell({super.key, required this.avatarRules, this.saveFallback});
  final AvatarRules avatarRules;

  /// The newest save did not load (bootGame): say so once.
  final BootFallback? saveFallback;

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell>
    with SingleTickerProviderStateMixin {
  static const home = 2;
  static const shop = 4;
  int _tab = home;
  late final GameDriver _driver = GameDriver(ref);
  late final Ticker _ticker;
  late final AppLifecycleListener _life;
  final _away = AwayTracker();
  StreamSubscription<ResearchCompleted>? _researchDone;
  final _sounds = <StreamSubscription<Object>>[];
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMicroseconds / 1e6;
      _last = elapsed;
      if (dt > 0 && dt < 1) _driver.tick(dt);
    })
      ..start();
    // welcome back: on open and on every return to the app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.saveFallback case final f?) {
        final s = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(kitToast(
          IconText(f == BootFallback.olderSave ? s.saveOlder : s.saveNew),
          duration: const Duration(seconds: 8),
        ));
      }
      showOfflineReward(context, ref);
    });
    _life = AppLifecycleListener(
      onInactive: () => _away.left(DateTime.now()),
      onHide: () => _away.left(DateTime.now()),
      onResume: () {
        ref.read(audioServiceProvider).resume();
        // only a real absence opens "welcome back": a screenshot, a dialog or
        // a rewarded ad blinks the app, and the time was spent playing
        // watching a rewarded ad is never "away", however long it runs
        final ads = ref.read(adServiceProvider);
        if (ads is AdService && ads.showingOrJustShown()) _away.reset();
        if (!_away.back(DateTime.now())) {
          ref.read(gameClockProvider).markSeen();
          return;
        }
        if (mounted) showOfflineReward(context, ref);
      },
      onPause: () {
        _away.left(DateTime.now());
        ref.read(audioServiceProvider).pause();
      },
    );
    _listenForSounds();
    // the only notice the library gives: "research done" (GDD §7), and the
    // player can switch it off
    final research = ref.read(researchProvider);
    _researchDone = research?.completed.listen((e) {
      if (!mounted || !research.notifyDone) return;
      final s = AppLocalizations.of(context);
      final node = research.rules.byId(e.nodeId)!;
      ScaffoldMessenger.of(context).showSnackBar(kitToast(IconText(
          s.researchDone(s.lang == 'en' ? node.nameEn : node.nameTh, e.level))));
    });
  }

  /// Game moments that make a sound (T-024). Effects the player triggers
  /// (knit, hatch) play where the tap happens.
  void _listenForSounds() {
    final audio = ref.read(audioServiceProvider);
    final loop = ref.read(idleLoopProvider);
    _sounds
      ..add(loop.combatEvents.listen((e) {
        switch (e) {
          case HitResolved(:final attackerId, :final outcome, :final damage)
              when damage > 0 &&
                  (attackerId == 'mochi' || attackerId.startsWith('pet_')):
            audio.playSfx(outcome == HitOutcome.crit ? 'crit' : 'hit');
          case UnitDefeated(:final unitId) when unitId != 'mochi':
            audio.playSfx('defeat');
          default:
        }
      }))
      ..add(loop.events.listen((e) {
        switch (e) {
          case BossResult(won: true):
            audio.playSfx('win');
          case WaveCleared():
            audio.playSfx('coin');
          default:
        }
      }))
      ..add(ref
          .read(catProgressProvider)
          .levelUps
          .listen((_) => audio.playSfx('level_up')));
  }

  @override
  void dispose() {
    for (final s in _sounds) {
      s.cancel();
    }
    _ticker.dispose();
    _life.dispose();
    _researchDone?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final items = [
      ('nav_character', s.navCharacter),
      ('nav_adventure', s.navDungeon),
      ('nav_home', s.navHome),
      ('nav_events', s.navEvents),
      ('nav_shop', s.navShop),
    ];
    return Scaffold(
      backgroundColor: Palette.paper,
      body: Stack(children: [
        SafeArea(
          child: Column(children: [
            Expanded(
              child: IndexedStack(index: _tab, children: [
                CharacterPage(refresh: _driver.ui$),
                AdventurePage(refresh: _driver.ui$),
                HomePage(
                  avatarRules: widget.avatarRules,
                  driver: _driver,
                  onOpenShop: () => setState(() => _tab = shop),
                ),
                const EventsPage(),
                const ShopPage(),
              ]),
            ),
            _BottomDock(
              items: items,
              selected: _tab,
              onSelected: (i) => setState(() => _tab = i),
            ),
          ]),
        ),
        // dev builds only (T-029); not in the release app
        if (kDebugTelemetry)
          Positioned(
            left: 4,
            top: 120,
            child: ValueListenableBuilder<int>(
                valueListenable: _driver.ui$,
                builder: (_, v, __) => DebugTelemetryOverlay(tick: v)),
          ),
      ]),
    );
  }
}

/// One shared illustrated dock instead of five unrelated rounded cards.
/// Icon and label sit inside the dock's five paper slots (measured in
/// `ui_frames.json`, D-059); the selected page lifts a cloth bookmark over its
/// slot, leaving quiet tabs flat.
class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  /// Dock height: the slots are about 38 dp tall, room for an icon and a
  /// one-line label.
  static const height = 100.0;

  final List<(String, String)> items;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => StorybookPaper(
        child: SizedBox(
          height: height,
          child: StretchFrame(
            frame: 'dock',
            builder: (context, g) {
              // without the frame data the five tabs still share the width
              final slots = g.spec.slots.length == items.length
                  ? [for (final r in g.spec.slots) g.rect(r)]
                  : [
                      for (var i = 0; i < items.length; i++)
                        Rect.fromLTWH(
                            g.content.left + g.content.width / items.length * i,
                            g.content.top,
                            g.content.width / items.length,
                            g.content.height)
                    ];
              final tab = FrameArt.spec('dock_selected');
              Widget bookmark(Rect slot) {
                // the ribbon keeps its own proportions, a little wider than
                // the slot's paper so the knobs hang over its top edge
                final w = slot.width * .62;
                final h = w * tab.h / tab.w;
                return AnimatedPositioned(
                  duration: const Duration(milliseconds: 170),
                  curve: Curves.easeOut,
                  left: slot.center.dx - w / 2,
                  top: slot.top - 18,
                  width: w,
                  height: h,
                  child: const StretchFrame(
                      frame: 'dock_selected', child: SizedBox()),
                );
              }

              return Stack(clipBehavior: Clip.none, children: [
                bookmark(slots[selected]),
                for (var i = 0; i < items.length; i++)
                  Positioned.fromRect(
                    rect: slots[i],
                    child: Semantics(
                      button: true,
                      selected: i == selected,
                      label: items[i].$2,
                      child: PressScale(
                        onTap: () => onSelected(i),
                        child: _DockTab(
                            icon: items[i].$1,
                            label: items[i].$2,
                            size: slots[i].size,
                            selected: i == selected),
                      ),
                    ),
                  ),
              ]);
            },
          ),
        ),
      );
}

/// One dock tab: the painted icon stands a little above the slot's paper (the
/// dock art leaves transparent room there) and the label sits on the paper.
class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.icon,
    required this.label,
    required this.size,
    required this.selected,
  });

  final String icon, label;
  final Size size;
  final bool selected;

  static const _labelH = 13.0;

  @override
  Widget build(BuildContext context) {
    final iconSize = (size.width - 4).clamp(0.0, size.height * 1.15);
    return Stack(clipBehavior: Clip.none, children: [
      Positioned(
        left: 0,
        right: 0,
        top: size.height - _labelH - iconSize + 2,
        height: iconSize,
        // the chosen tab's picture lifts a little
        child: AnimatedScale(
          scale: selected ? 1.12 : 1,
          alignment: Alignment.bottomCenter,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Image.asset('assets/game/ui/$icon.png',
              fit: BoxFit.contain, filterQuality: FilterQuality.medium),
        ),
      ),
      Positioned(
        left: 1,
        right: 1,
        bottom: 0,
        height: _labelH,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: IconText(
            label,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Palette.ink,
            ),
          ),
        ),
      ),
    ]);
  }
}
