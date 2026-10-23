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
      ('🏰', s.navDungeon),
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
                const DungeonPage(),
                HomePage(avatarRules: widget.avatarRules, driver: _driver),
                const EventsPage(),
                const ShopPage(),
              ]),
            ),
            Container(
              decoration: const BoxDecoration(
                color: Palette.sheet,
                border: Border(top: BorderSide(color: Palette.ink, width: 2.5)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == _tab,
                      label: items[i].$2,
                      child: InkWell(
                        onTap: () => setState(() => _tab = i),
                        child: SizedBox(
                          height: 66,
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  scale: i == _tab ? 1.25 : 1,
                                  duration: const Duration(milliseconds: 150),
                                  child: IconText(items[i].$1,
                                      style: TextStyle(
                                          fontSize: i == home ? 26 : 22)),
                                ),
                                IconText(items[i].$2,
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: i == _tab
                                            ? FontWeight.w800
                                            : FontWeight.w500,
                                        color: i == _tab
                                            ? Palette.ink
                                            : Palette.inkSoft)),
                              ]),
                        ),
                      ),
                    ),
                  ),
              ]),
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
