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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: Palette.ink,
          content: IconText(
              f == BootFallback.olderSave ? s.saveOlder : s.saveNew,
              style: const TextStyle(fontWeight: FontWeight.w800)),
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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Palette.ink,
        content: IconText(
            s.researchDone(s.lang == 'en' ? node.nameEn : node.nameTh, e.level),
            style: const TextStyle(fontWeight: FontWeight.w800)),
      ));
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
      ('🐱', s.navCharacter),
      ('📖', s.navDungeon),
      ('🏠', s.navHome),
      ('🎁', s.navEvents),
      ('🛒', s.navShop),
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
                HomePage(avatarRules: widget.avatarRules, driver: _driver),
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
/// The selected page lifts like a cloth bookmark, leaving quiet tabs flat.
class _BottomDock extends StatelessWidget {
  const _BottomDock({
    required this.items,
    required this.selected,
    required this.onSelected,
  });

  final List<(String, String)> items;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => StorybookPaper(
        child: SizedBox(
          height: 78,
          child: LayoutBuilder(builder: (context, box) {
            final tabWidth = box.maxWidth / items.length;
            return Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/game/ui/ui_frame_nav_dock.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 170),
                curve: Curves.easeOut,
                left: tabWidth * selected + tabWidth * .16,
                top: -2,
                width: tabWidth * .68,
                height: 74,
                child: Image.asset(
                  'assets/game/ui/ui_frame_nav_selected.png',
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.medium,
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 2, 8, 12),
                  child: Row(children: [
                    for (var i = 0; i < items.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == selected,
                          label: items[i].$2,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelected(i),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == selected ? 1.18 : 1,
                                  duration: const Duration(milliseconds: 170),
                                  child: IconText(items[i].$1,
                                      style: const TextStyle(fontSize: 23)),
                                ),
                                const SizedBox(height: 1),
                                IconText(
                                  items[i].$2,
                                  maxLines: 1,
                                  overflow: TextOverflow.fade,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: i == selected
                                        ? FontWeight.w900
                                        : FontWeight.w700,
                                    color: i == selected
                                        ? Palette.ink
                                        : Palette.inkSoft,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ]);
          }),
        ),
      );
}
