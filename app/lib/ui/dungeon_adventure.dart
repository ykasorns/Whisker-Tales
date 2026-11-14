import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_dungeon/wt_mode_dungeon.dart';

import '../l10n/strings.dart';
import 'frames.dart';
import 'game_icon.dart';
import 'palette.dart';

/// Aspect (width / height) of the painted background tiles.
const _bgAspect = {
  'L0_back': 736 / 400,
  'L1_far': 560 / 400,
  'L2_mid': 560 / 400,
  'L3_ground': 1103 / 400,
};

/// The Adventure menu's card for the Treat Dungeon (D-065).
class DungeonHubCard extends ConsumerWidget {
  const DungeonHubCard({super.key, required this.mode});

  final DungeonMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = AppLocalizations.of(context);
    final save = ref.read(modeSavesProvider).stateOf(mode) as DungeonSave;
    final unlocked = mode.manifest.enabled &&
        isModeUnlocked(
            mode.manifest.unlock, ref.read(modeUnlockContextProvider)());
    final day = ref.read(gameClockProvider).dateKey;
    final ads = ref.read(adServiceProvider);
    final left =
        mode.entriesLeft(save, day, ads.usedToday(mode.rules.adPlacement));
    return Semantics(
      button: unlocked,
      label: mode.manifest.nameTh,
      child: GestureDetector(
        key: const Key('dungeon-mode-card'),
        onTap: unlocked ? () => openDungeon(context, ref, mode) : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.66,
          child: Container(
            margin: const EdgeInsets.only(top: 14),
            padding: const EdgeInsets.all(16),
            decoration: storybookCard(
                fill: const Color(0xFFFFE3CC),
                accent: Palette.coral,
                radius: 11),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: storybookCard(
                      fill: const Color(0xFFFFF1D5),
                      accent: Palette.coral,
                      radius: 9),
                  child: Center(
                    child: unlocked
                        ? Image.asset('assets/game/dungeon/mode_dungeon.png',
                            width: 68, height: 68, fit: BoxFit.contain)
                        : const GameIcon('lock', size: 44),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconText(s.dungeonTitle,
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      IconText(unlocked ? s.dungeonSubtitle : s.dungeonLocked,
                          style: const TextStyle(
                              color: Palette.inkSoft, height: 1.25)),
                    ],
                  ),
                ),
              ]),
              if (unlocked) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                      child: _chip('👑', s.dungeonLevel('${save.unlocked}'))),
                  const SizedBox(width: 8),
                  Expanded(child: _chip('🎁', s.dungeonEntries('$left'))),
                ]),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  decoration: storybookButton(
                      fill: Palette.sun, accent: Palette.mochi, radius: 10),
                  child: IconText('🍪 ${s.dungeonStart}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                ),
              ],
            ]),
          ),
        ),
      ),
    );
  }

  Widget _chip(String icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: storybookCard(
            fill: Colors.white.withValues(alpha: .55),
            accent: Palette.coral,
            radius: 8),
        child: FitLine(
          child: IconText('$icon $text',
              maxLines: 1,
              style:
                  const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
        ),
      );
}

Future<void> openDungeon(
    BuildContext context, WidgetRef ref, DungeonMode mode) async {
  final game = ref.read(gameStateProvider.notifier);
  if (ref.read(gameStateProvider) == GameState.boot) game.goTo(GameState.hub);
  await Navigator.of(context).push(MaterialPageRoute<void>(
    builder: (_) => DungeonPage(mode: mode),
  ));
}

enum _Stage { ready, running, result }

/// Pick a boss level, drop in, watch 30 seconds of fighting, take the 🍪.
class DungeonPage extends ConsumerStatefulWidget {
  const DungeonPage({super.key, required this.mode});

  final DungeonMode mode;

  @override
  ConsumerState<DungeonPage> createState() => _DungeonPageState();
}

class _DungeonPageState extends ConsumerState<DungeonPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker;
  Duration _last = Duration.zero;
  double _carryMs = 0;
  DungeonController? _run;
  late DungeonSave _save;
  _Stage _stage = _Stage.ready;
  int _level = 1;
  int _lastHit = 0;
  final _floats =
      <({int serial, bool onCat, int damage, HitOutcome o, int at})>[];

  DungeonMode get mode => widget.mode;
  DungeonRules get rules => mode.rules;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _save = ref.read(modeSavesProvider).stateOf(mode) as DungeonSave;
    _level = _save.unlocked;
    _ticker = createTicker(_onTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    // leaving mid-run pays what was dealt (the entry is already spent)
    _run?.finish();
    _run?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // going to the background ends the run: nobody re-rolls a bad one
    if (state == AppLifecycleState.paused && _stage == _Stage.running) {
      _finish();
    }
  }

  int get _adsWatched =>
      ref.read(adServiceProvider).usedToday(rules.adPlacement);

  int get _entriesLeft =>
      mode.entriesLeft(_save, ref.read(gameClockProvider).dateKey, _adsWatched);

  void _persist(DungeonSave s) {
    _save = s;
    ref.read(modeSavesProvider).update(mode, s);
    ref.read(gameSaverProvider).save();
  }

  void _start() {
    if (_stage == _Stage.running || _entriesLeft <= 0) return;
    final cat = ref.read(catSpecProvider)();
    final run = DungeonController(
      mode: mode,
      save: _save,
      cat: cat,
      partners:
          ref.read(petsProvider)?.partners(ref.read(catBaseSpecProvider)()) ??
              const [],
      idle: ref.read(idleRulesProvider),
      powerScore: ref.read(powerScoreProvider),
      engineFactory: ref.read(combatEngineFactoryProvider),
      wallet: ref.read(walletProvider),
      dayKey: ref.read(gameClockProvider).dateKey,
      adsWatchedToday: () => _adsWatched,
      onSave: _persist,
    );
    if (!run.start(_level)) {
      run.dispose();
      return;
    }
    _run?.dispose();
    _run = run;
    _floats.clear();
    _lastHit = 0;
    _carryMs = 0;
    _last = Duration.zero;
    setState(() => _stage = _Stage.running);
    _ticker.start();
  }

  void _onTick(Duration elapsed) {
    final run = _run;
    if (run == null || !run.running) return;
    // game time at 1x whatever the Home speed is: 30 s means 30 s
    final dt = math.min(0.25, (elapsed - _last).inMicroseconds / 1e6);
    _last = elapsed;
    _carryMs += dt * 1000;
    while (_carryMs >= 1 && run.running) {
      final step = math.min(100, _carryMs.floor());
      run.tick(step);
      _carryMs -= step;
    }
    for (final h in run.hits) {
      if (h.serial > _lastHit) {
        _lastHit = h.serial;
        _floats.add((
          serial: h.serial,
          onCat: h.onCat,
          damage: h.damage,
          o: h.outcome,
          at: run.elapsedMs,
        ));
      }
    }
    _floats.removeWhere((f) => run.elapsedMs - f.at > 700);
    if (!run.running) {
      _ticker.stop();
      _stage = _Stage.result;
    }
    setState(() {});
  }

  void _finish() {
    final run = _run;
    if (run == null) return;
    run.finish();
    _ticker.stop();
    setState(() => _stage = _Stage.result);
  }

  Future<void> _watchAd() async {
    final out = await ref.read(adServiceProvider).show(rules.adPlacement);
    if (!mounted) return;
    setState(() {});
    if (out != AdOutcome.rewarded) return;
  }

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Palette.paper,
      body: SafeArea(
        child: Column(children: [
          Expanded(flex: 60, child: _scene(s)),
          Expanded(
            flex: 40,
            child: StorybookPaper(child: _panel(s)),
          ),
        ]),
      ),
    );
  }

  // --- scene ---------------------------------------------------------------

  Widget _scene(AppLocalizations s) {
    final run = _run;
    final showFight = _stage != _Stage.ready && run != null;
    final boss = run?.boss;
    final fraction = boss == null || boss.maxHp == 0
        ? 0.0
        : (boss.alive ? (boss.maxHp - boss.hp) / boss.maxHp : 1.0);
    final t = run?.elapsedMs ?? 0;
    final phase = (t % 1200) / 1200;
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth, h = box.maxHeight;
      final gy = h * 0.84;
      Widget tile(String name, double th, double bottom) {
        final tw = th * (_bgAspect[name] ?? 1);
        return Stack(clipBehavior: Clip.hardEdge, children: [
          for (var x = 0.0; x < w; x += tw - 1)
            Positioned(
              left: x,
              top: bottom - th,
              width: tw,
              height: th,
              child: Image.asset('assets/game/bg/bg_dungeon_$name.webp',
                  fit: BoxFit.fill, filterQuality: FilterQuality.low),
            ),
        ]);
      }

      final bossFrame = phase >= .45 && phase < .66
          ? 'attack'
          : 'idle_f${(phase * 3).floor().clamp(0, 2) + 1}';
      final catFrame = !showFight
          ? 'idle'
          : phase < .22
              ? 'attack'
              : 'idle';
      final sprite = rules.spriteOf(_level);
      return Stack(clipBehavior: Clip.hardEdge, children: [
        tile('L0_back', h, h),
        tile('L1_far', h * .7, gy + h * .04),
        tile('L2_mid', h * .62, gy + h * .06),
        tile('L3_ground', (h - gy) / .3, h),
        Positioned(
          left: 24 + (showFight && phase < .22 ? 16 : 0),
          bottom: (h - gy) * .35,
          child: Image.asset(
            'assets/game/cat/outfit_${ref.read(catClassProvider).current}_$catFrame.png',
            width: 104,
            height: 130,
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => Image.asset(
                'assets/game/cat/$catFrame.png',
                width: 104,
                height: 130,
                fit: BoxFit.contain),
          ),
        ),
        Positioned(
          right: 18,
          bottom: (h - gy) * .35 + 4,
          child: Opacity(
            opacity: boss != null && !boss.alive ? .35 : 1,
            child: Image.asset(
              'assets/game/mon/${sprite}_${boss != null && !boss.alive ? 'defeated' : showFight ? bossFrame : 'idle_f1'}.png',
              key: const Key('dungeon-boss'),
              width: 170,
              height: 170,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
        ),
        for (final f in _floats)
          Positioned(
            key: ValueKey(f.serial),
            left: f.onCat ? 40 : w - 150,
            bottom: (h - gy) + 100 + ((t - f.at) / 700) * 40,
            child: Opacity(
              opacity: (1 - (t - f.at) / 700).clamp(0.0, 1.0),
              child: Text(
                f.o == HitOutcome.dodge ? '·' : '${f.damage}',
                style: TextStyle(
                    fontSize: f.o == HitOutcome.crit ? 22 : 16,
                    fontWeight: FontWeight.w900,
                    color: f.onCat
                        ? Palette.coral
                        : f.o == HitOutcome.crit
                            ? const Color(0xFFE8742B)
                            : Palette.ink,
                    shadows: const [
                      Shadow(color: Palette.paper, blurRadius: 3)
                    ]),
              ),
            ),
          ),
        Positioned(
          left: 8,
          right: 8,
          top: 6,
          child: Column(children: [
            Row(children: [
              _timerPlate(s, run),
              const SizedBox(width: 8),
              Expanded(child: _damageBar(s, fraction)),
              const SizedBox(width: 4),
              GestureDetector(
                key: const Key('dungeon-close'),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(child: GameIcon('cross', size: 24))),
              ),
            ]),
          ]),
        ),
      ]);
    });
  }

  Widget _timerPlate(AppLocalizations s, DungeonController? run) {
    final left = run == null
        ? rules.timeLimitMs
        : (_stage == _Stage.ready ? rules.timeLimitMs : run.remainingMs);
    final secs = (left / 1000).ceil();
    return SizedBox(
      width: 78,
      height: 40,
      child: StretchFrame(
        frame: 'action',
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: IconText('⏱ ${s.dungeonTime('$secs')}',
                key: const Key('dungeon-timer'),
                maxLines: 1,
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: secs <= 5 && _stage == _Stage.running
                        ? Palette.coral
                        : Palette.ink)),
          ),
        ),
      ),
    );
  }

  /// Damage dealt, filled 0–100% with a tick and the 🍪 prize at each tier.
  Widget _damageBar(AppLocalizations s, double fraction) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      return SizedBox(
        height: 56,
        child: Stack(clipBehavior: Clip.none, children: [
          Positioned(
            left: 0,
            right: 0,
            top: 36,
            height: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: Container(
                color: Palette.ink.withValues(alpha: .25),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(color: Palette.coral),
                ),
              ),
            ),
          ),
          for (var i = 0; i < rules.tiers.length; i++)
            Positioned(
              left: w * rules.tiers[i].damagePct / 100 -
                  (i == rules.tiers.length - 1 ? 26 : 13),
              top: 0,
              child: Opacity(
                opacity: fraction * 100 >= rules.tiers[i].damagePct ? 1 : .55,
                child: Column(children: [
                  Image.asset('assets/game/dungeon/prize_t${i + 1}.png',
                      width: 26, height: 26, fit: BoxFit.contain),
                  Text('${rules.cookiesFor(_level, i + 1)}',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: Palette.ink,
                          height: 1)),
                ]),
              ),
            ),
        ]),
      );
    });
  }

  // --- bottom panel --------------------------------------------------------

  Widget _panel(AppLocalizations s) => switch (_stage) {
        _Stage.ready => _readyPanel(s),
        _Stage.running => _runningPanel(s),
        _Stage.result => _resultPanel(s),
      };

  Widget _button(String label, VoidCallback? onTap,
      {Color fill = Palette.sun, Key? key}) {
    return PressScale(
      key: key,
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? .5 : 1,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: storybookButton(
              fill: fill,
              accent: Palette.mochi,
              enabled: onTap != null,
              radius: 10),
          child: IconText(label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }

  Widget _readyPanel(AppLocalizations s) {
    final left = _entriesLeft;
    final ads = ref.read(adServiceProvider);
    final canAd = ads.canShow(rules.adPlacement);
    final best = _save.bestTier[_level] ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(children: [
        Row(children: [
          _arrow('‹', _level > 1 ? () => setState(() => _level--) : null,
              const Key('dungeon-level-down')),
          Expanded(
            child: Column(children: [
              IconText(s.dungeonLevel('$_level'),
                  key: const Key('dungeon-level'),
                  style: const TextStyle(
                      fontSize: 19, fontWeight: FontWeight.w900)),
              IconText(
                  best == 0
                      ? s.dungeonUnlockHint('${rules.unlockTier}')
                      : '${s.dungeonBest}: ${s.dungeonTierName('$best')}',
                  style: const TextStyle(fontSize: 11, color: Palette.inkSoft)),
            ]),
          ),
          _arrow(
              '›',
              _level < _save.unlocked ? () => setState(() => _level++) : null,
              const Key('dungeon-level-up')),
        ]),
        const Spacer(),
        IconText(left > 0 ? s.dungeonEntries('$left') : s.dungeonNoRuns,
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 6),
        _button('🍪 ${s.dungeonStart}', left > 0 ? _start : null,
            key: const Key('dungeon-start')),
        if (canAd) ...[
          const SizedBox(height: 6),
          _button(s.dungeonWatch, _watchAd,
              fill: Palette.lime, key: const Key('dungeon-watch')),
        ],
      ]),
    );
  }

  Widget _arrow(String glyph, VoidCallback? onTap, Key key) => GestureDetector(
        key: key,
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? .3 : 1,
          child: SizedBox(
            width: 48,
            height: 44,
            child: Center(
              child: Text(glyph,
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Palette.ink,
                      height: 1)),
            ),
          ),
        ),
      );

  Widget _runningPanel(AppLocalizations s) {
    final run = _run!;
    final boss = run.boss;
    final pct = boss == null || boss.maxHp == 0
        ? 0
        : ((boss.alive ? boss.maxHp - boss.hp : boss.maxHp) * 100 ~/ boss.maxHp)
            .clamp(0, 100);
    final tier = rules.tierFor(
        boss == null ? 0 : (boss.alive ? boss.maxHp - boss.hp : boss.maxHp),
        boss?.maxHp ?? 0);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(children: [
        IconText(s.dungeonLevel('${run.level}'),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6),
        IconText(s.dungeonDamage('$pct'),
            key: const Key('dungeon-damage'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        IconText(
            tier == 0
                ? '🍪 0'
                : '${s.dungeonTierName('$tier')} · 🍪 ${rules.cookiesFor(run.level, tier)}',
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: Palette.inkSoft)),
        const Spacer(),
        _button(s.dungeonLeave, _finish,
            fill: Palette.sheet, key: const Key('dungeon-finish')),
      ]),
    );
  }

  Widget _resultPanel(AppLocalizations s) {
    final r = _run!.result;
    if (r == null) return const SizedBox.shrink();
    final left = _entriesLeft;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      child: Column(children: [
        IconText(r.bossDefeated ? s.dungeonDefeated : s.dungeonResult,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        IconText(
            '${s.dungeonDamage('${(r.fraction * 100).round()}')}'
            '${r.tier > 0 ? ' · ${s.dungeonTierName('${r.tier}')}' : ''}',
            style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        if (r.cookies > 0)
          IconText(s.dungeonGot('${r.cookies}'),
              key: const Key('dungeon-got'),
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Palette.teal))
        else
          IconText(s.dungeonNoTier,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Palette.inkSoft)),
        if (r.unlockedNext)
          IconText(s.dungeonOpened('${_save.unlocked}'),
              style: const TextStyle(
                  fontWeight: FontWeight.w900, color: Palette.coral)),
        const Spacer(),
        Row(children: [
          Expanded(
              child: _button(s.dungeonClose, () => Navigator.of(context).pop(),
                  fill: Palette.sheet, key: const Key('dungeon-back'))),
          const SizedBox(width: 8),
          Expanded(
              child: _button(
                  s.dungeonAgain,
                  left > 0
                      ? () {
                          if (r.unlockedNext) _level = _save.unlocked;
                          setState(() => _stage = _Stage.ready);
                        }
                      : null,
                  key: const Key('dungeon-again'))),
        ]),
      ]),
    );
  }
}
