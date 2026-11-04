import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_mode_dungeon/wt_mode_dungeon.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

import '../l10n/strings.dart';
import 'frames.dart';
import 'dungeon_adventure.dart';
import 'game_icon.dart';
import 'palette.dart';
import 'story_scene.dart';

class AdventurePage extends ConsumerWidget {
  const AdventurePage({super.key, required this.refresh});

  final ValueNotifier<int> refresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ValueListenableBuilder(
        valueListenable: refresh,
        builder: (_, __, ___) {
          final s = AppLocalizations.of(context);
          final registry = ref.read(modeRegistryProvider);
          // The registry owns ordering and visibility. Disabled modes still
          // appear as locked previews so the menu never hardcodes a mode.
          final modes = registry.modes;
          return StorybookPaper(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                IconText(s.storyTitle,
                    style: const TextStyle(
                        fontSize: 25, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                IconText(s.storySubtitle,
                    style:
                        const TextStyle(color: Palette.inkSoft, height: 1.3)),
                const SizedBox(height: 18),
                for (final mode in modes)
                  if (mode is DungeonMode)
                    DungeonHubCard(mode: mode)
                  else
                    _modeCard(context, ref, mode),
                if (modes.isEmpty)
                  _paperMessage('📖', s.comingSoon, Palette.plum),
              ],
            ),
          );
        },
      );

  Widget _modeCard(BuildContext context, WidgetRef ref, GameMode mode) {
    final s = AppLocalizations.of(context);
    final state = ref.read(modeSavesProvider).stateOf(mode);
    final unlocked = mode.manifest.enabled &&
        isModeUnlocked(
            mode.manifest.unlock, ref.read(modeUnlockContextProvider)());
    final story = state is StorySave ? state : StorySave();
    final fullLeft = mode is StoryMode
        ? math.max(
            0,
            mode.content.balance.fullRewardRuns -
                mode.completedRunsOn(
                    story, ref.read(gameClockProvider).dateKey))
        : 0;
    return Semantics(
      button: unlocked,
      label: mode.manifest.nameTh,
      child: GestureDetector(
        key: const Key('story-mode-card'),
        onTap: unlocked && mode is StoryMode
            ? () => _openStory(context, ref, mode, story)
            : null,
        child: Opacity(
          opacity: unlocked ? 1 : 0.66,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: storybookCard(
                fill: const Color(0xFFFFEBC0),
                accent: Palette.plum,
                radius: 11),
            child: Column(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: storybookCard(
                      fill: const Color(0xFFE9DBF1),
                      accent: Palette.plum,
                      radius: 9),
                  child: Center(
                    child: unlocked
                        ? const GameIcon('openbook', size: 54)
                        : const GameIcon('lock', size: 44),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconText(
                          s.lang == 'en'
                              ? mode.manifest.nameEn
                              : mode.manifest.nameTh,
                          style: const TextStyle(
                              fontSize: 21, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      IconText(
                          unlocked
                              ? s.storySubtitle
                              : mode.manifest.enabled
                                  ? s.storyUnlockHint
                                  : s.comingSoon,
                          style: const TextStyle(
                              color: Palette.inkSoft, height: 1.25)),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 14),
              Row(children: [
                Expanded(
                    child: _statChip('⭐', '${s.storyBest} ${story.bestDepth}')),
                const SizedBox(width: 8),
                Expanded(child: _statChip('🎁', '${s.storyDaily} $fullLeft')),
              ]),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 13),
                decoration: storybookButton(
                    fill: unlocked ? Palette.sun : Palette.sheet,
                    accent: unlocked ? Palette.mochi : Palette.inkSoft,
                    enabled: unlocked,
                    radius: 10),
                child: IconText(
                  unlocked ? '📖 ${s.storyStart}' : '🔒 ${s.storyLocked}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Future<void> _openStory(BuildContext context, WidgetRef ref, StoryMode mode,
      StorySave save) async {
    final game = ref.read(gameStateProvider.notifier);
    if (ref.read(gameStateProvider) == GameState.boot) game.goTo(GameState.hub);
    if (ref.read(gameStateProvider) == GameState.hub) game.goTo(GameState.run);
    final cat = ref.read(catSpecProvider)();
    final controller = StoryRunController(
      mode: mode,
      save: save,
      manager: ref.read(runManagerProvider),
      cat: cat,
      classId: ref.read(catClassProvider).current,
      powerScore: ref.read(powerScoreProvider),
      engineFactory: ref.read(combatEngineFactoryProvider),
      wallet: ref.read(walletProvider),
      buffBook: ref.read(buffBookProvider),
      dayKey: ref.read(gameClockProvider).dateKey,
      onSave: (updated) {
        ref.read(modeSavesProvider).update(mode, updated);
        ref.read(gameSaverProvider).save();
      },
    )..start();
    await Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (_) =>
          StoryRunPage(controller: controller, disposeController: true),
    ));
    if (ref.read(gameStateProvider) == GameState.run) game.goTo(GameState.hub);
  }
}

class StoryRunPage extends ConsumerStatefulWidget {
  const StoryRunPage({
    super.key,
    required this.controller,
    this.disposeController = false,
  });

  /// Allows deterministic UI previews and golden tests to render a run that
  /// has already reached a specific panel. Production creates its own run.
  final StoryRunController controller;
  final bool disposeController;

  @override
  ConsumerState<StoryRunPage> createState() => _StoryRunPageState();
}

class _StoryRunPageState extends ConsumerState<StoryRunPage>
    with SingleTickerProviderStateMixin {
  late final StoryRunController controller;
  late final bool _ownsController;
  late final Ticker _ticker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.disposeController;
    controller = widget.controller;
    controller.addListener(_changed);
    _ticker = createTicker((elapsed) {
      final dt = (elapsed - _last).inMilliseconds;
      _last = elapsed;
      if (dt > 0 && dt < 1000) controller.tick(dt);
    })
      ..start();
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.dispose();
    controller.removeListener(_changed);
    if (_ownsController) controller.dispose();
    super.dispose();
  }

  Future<void> _quit() async {
    final s = AppLocalizations.of(context);
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Palette.paper,
        title: IconText(s.storyQuit),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(s.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: IconText(s.storyQuit)),
        ],
      ),
    );
    if (leave == true && mounted) {
      controller.abandon();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _quit();
      },
      child: Scaffold(
        backgroundColor: Palette.storyPaper,
        body: SafeArea(
          child: Column(children: [
            Expanded(
              flex: 60,
              child: StoryScene(
                controller: controller,
                onQuit: _quit,
                nodeMap: controller.panel == StoryRunPanel.result
                    ? const SizedBox(height: 64)
                    : StoryNodeMapOverlay(
                        previews: controller.preview,
                        depth: controller.manager.current?.clearedNodes ?? 0,
                      ),
                statusIcons: (statuses) => _StatusIcons(statuses: statuses),
              ),
            ),
            Expanded(
              flex: 40,
              child: StorybookPaper(
                child: AnimatedSwitcher(
                  duration: disableMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => AnimatedBuilder(
                    animation: animation,
                    child: child,
                    builder: (_, child) => Transform(
                      alignment: Alignment.centerLeft,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY((1 - animation.value) * 0.28),
                      child: Opacity(opacity: animation.value, child: child),
                    ),
                  ),
                  child: _panel(context),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _panel(BuildContext context) => switch (controller.panel) {
        StoryRunPanel.map =>
          _MapPanel(key: const ValueKey('map'), controller: controller),
        StoryRunPanel.combat =>
          _CombatPanel(key: const ValueKey('combat'), controller: controller),
        StoryRunPanel.relicPick =>
          _RelicPickPanel(key: const ValueKey('relic'), controller: controller),
        StoryRunPanel.talentPick => _TalentPickPanel(
            key: const ValueKey('talent'), controller: controller),
        StoryRunPanel.event =>
          _EventPanel(key: const ValueKey('event'), controller: controller),
        StoryRunPanel.shop =>
          _ShopPanel(key: const ValueKey('shop'), controller: controller),
        StoryRunPanel.campfire => _CampfirePanel(
            key: const ValueKey('campfire'), controller: controller),
        StoryRunPanel.result => _ResultPanel(
            key: const ValueKey('result'),
            controller: controller,
            onReturn: () => Navigator.of(context).pop()),
      };
}

class StoryNodeMapOverlay extends StatefulWidget {
  const StoryNodeMapOverlay(
      {super.key, required this.previews, required this.depth});

  final List<EncounterPreview> previews;
  final int depth;

  @override
  State<StoryNodeMapOverlay> createState() => _StoryNodeMapOverlayState();
}

/// The next stops on a painted ribbon: where Mochi is, then what lies ahead.
class _StoryNodeMapOverlayState extends State<StoryNodeMapOverlay> {
  bool expanded = true;

  @override
  Widget build(BuildContext context) => GestureDetector(
        key: const Key('story-node-map'),
        onTap: () => setState(() => expanded = !expanded),
        child: AnimatedContainer(
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          width: double.infinity,
          height: 64,
          child: StretchFrame(
            frame: 'chapter',
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const GameIcon('paw', size: 18),
              if (expanded) ...[
                const SizedBox(width: 6),
                for (var i = 0; i < widget.previews.length; i++) ...[
                  if (i > 0)
                    Expanded(
                        child: Container(
                            height: 2,
                            color: Palette.ink.withValues(alpha: .3))),
                  GameIcon(_encounterIcon(widget.previews[i].type),
                      size: i == 0 ? 22 : 17),
                ],
              ] else
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: IconText('${widget.depth + 1}',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: Palette.ink)),
                ),
            ]),
          ),
        ),
      );
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final choices = controller.routeChoices;
    return _panelFrame(
      title: s.storyMap,
      icon: 'scroll',
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: 110, maxWidth: choices.length > 1 ? 400 : 230),
          child: Row(children: [
            for (var i = 0; i < choices.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _actionCard(
                  key: Key('route-${choices[i].routeId}'),
                  icon: _encounterIcon(choices[i].type),
                  label: choices.length > 1
                      ? (choices[i].routeId?.endsWith('safe') == true
                          ? s.storySafe
                          : s.storyRisky)
                      : _encounterName(s, choices[i].type),
                  color: choices.length > 1 &&
                          choices[i].routeId?.endsWith('risky') == true
                      ? Palette.coral
                      : Palette.teal,
                  onTap: () => controller.advance(routeId: choices[i].routeId),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }
}

class _CombatPanel extends StatelessWidget {
  const _CombatPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final cat = controller.combatView.where((u) => u.id == 'mochi').firstOrNull;
    final info = context
        .findAncestorStateOfType<_StoryRunPageState>()
        ?.ref
        .read(skillBookProvider)
        .info;
    return _panelFrame(
      title: s.storyCombat,
      icon: 'sword',
      child: Column(children: [
        Expanded(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (cat == null || cat.skills.isEmpty)
              const GameIcon('paw', size: 48)
            else
              for (final skill in cat.skills)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: Stack(alignment: Alignment.center, children: [
                      Positioned.fill(
                        child: CircularProgressIndicator(
                          value: skill.totalMs == 0
                              ? 1
                              : 1 - skill.remainingMs / skill.totalMs,
                          strokeWidth: 5,
                          color: Palette.teal,
                          backgroundColor: Palette.sheet,
                        ),
                      ),
                      GameIcon.skill(skill.id, info?[skill.id]?.icon ?? '✨',
                          size: 36),
                    ]),
                  ),
                ),
          ]),
        ),
        if (controller.relicIds.isNotEmpty)
          SizedBox(
            height: 26,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (final id in controller.relicIds.take(8))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: GameIcon(_relicIcon(id), size: 22),
                ),
            ]),
          ),
      ]),
    );
  }
}

class _RelicPickPanel extends StatelessWidget {
  const _RelicPickPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final content = controller.mode.content;
    final choices = [
      for (final id in controller.relicOptions) content.relics[id]!
    ];
    return _PickPanel<StoryRelic>(
      title: AppLocalizations.of(context).storyPickRelic,
      choices: choices,
      idOf: (r) => r.id,
      nameOf: (r) =>
          AppLocalizations.of(context).lang == 'en' ? r.nameEn : r.nameTh,
      descriptionOf: (r) => AppLocalizations.of(context).lang == 'en'
          ? r.descriptionEn
          : r.descriptionTh,
      iconOf: (r) => _relicIcon(r.id),
      colorOf: (_) => Palette.sun,
      synergyOf: (r) => _hasSynergy(content, controller.relicIds, r.id),
      onPick: controller.chooseRelic,
    );
  }
}

class _TalentPickPanel extends StatelessWidget {
  const _TalentPickPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final content = controller.mode.content;
    final ids = controller.talents.pickOptions();
    final choices = [for (final id in ids) content.talents[id]!];
    return _PickPanel<StoryTalent>(
      title: AppLocalizations.of(context).storyPickTalent,
      choices: choices,
      idOf: (t) => t.id,
      nameOf: (t) =>
          AppLocalizations.of(context).lang == 'en' ? t.nameEn : t.nameTh,
      descriptionOf: (t) => AppLocalizations.of(context).lang == 'en'
          ? t.descriptionEn
          : t.descriptionTh,
      iconOf: (t) => switch (t.tree) {
        'claw' => 'sword',
        'shadow' => 'evade',
        _ => 'sparkle'
      },
      colorOf: (t) => switch (t.tree) {
        'claw' => Palette.coral,
        'shadow' => Palette.plum,
        _ => Palette.teal
      },
      synergyOf: (t) =>
          t.crossSynergies.any((x) => controller.relicIds.contains(x.relicId)),
      onPick: controller.chooseTalent,
    );
  }
}

class _PickPanel<T> extends StatefulWidget {
  const _PickPanel({
    required this.title,
    required this.choices,
    required this.idOf,
    required this.nameOf,
    required this.descriptionOf,
    required this.iconOf,
    required this.colorOf,
    required this.synergyOf,
    required this.onPick,
  });

  final String title;
  final List<T> choices;
  final String Function(T) idOf, nameOf, descriptionOf, iconOf;
  final Color Function(T) colorOf;
  final bool Function(T) synergyOf;
  final void Function(String) onPick;

  @override
  State<_PickPanel<T>> createState() => _PickPanelState<T>();
}

class _PickPanelState<T> extends State<_PickPanel<T>> {
  String? selected;

  @override
  Widget build(BuildContext context) => _panelFrame(
        title: widget.title,
        icon: 'sparkle',
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          for (var i = 0; i < widget.choices.length; i++) ...[
            if (i > 0) const SizedBox(width: 7),
            Expanded(child: _card(widget.choices[i])),
          ],
        ]),
      );

  Widget _card(T choice) {
    final id = widget.idOf(choice);
    final chosen = selected == id;
    final synergy = widget.synergyOf(choice);
    return Semantics(
      button: true,
      selected: chosen,
      label: widget.nameOf(choice),
      child: GestureDetector(
        key: Key('pick-$id'),
        onTap: () {
          if (chosen) {
            widget.onPick(id);
          } else {
            setState(() => selected = id);
          }
        },
        child: CustomPaint(
          foregroundPainter: synergy ? _DottedLinkPainter() : null,
          child: AnimatedScale(
            scale: chosen ? 1.04 : 1,
            duration: const Duration(milliseconds: 120),
            child: Container(
              padding: const EdgeInsets.fromLTRB(13, 15, 13, 13),
              decoration: paintedCardDecoration(
                  chosen ? 'card_pick_selected' : 'card_pick'),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GameIcon(widget.iconOf(choice), size: chosen ? 45 : 38),
                    const SizedBox(height: 4),
                    IconText(widget.nameOf(choice),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900)),
                    if (chosen) ...[
                      const SizedBox(height: 3),
                      IconText(widget.descriptionOf(choice),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 9, color: Palette.inkSoft)),
                      IconText(AppLocalizations.of(context).storyTapAgain,
                          style: const TextStyle(
                              fontSize: 9, fontWeight: FontWeight.w800)),
                    ],
                    if (synergy)
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: GameIcon('bolt', size: 15),
                      ),
                  ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventPanel extends StatelessWidget {
  const _EventPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final event = controller.event!;
    final en = s.lang == 'en';
    String name(StoryEventChoice c) => en ? c.labelEn : c.labelTh;
    final speaker = controller.mode.content.narrative.cast[event.speaker];
    return _panelFrame(
      title: en ? event.nameEn : event.nameTh,
      icon: 'question',
      child: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                if (speaker != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8, top: 2),
                    child: storyPortrait(event.speaker!, 62),
                  ),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (speaker != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: IconText(
                                en ? speaker.nameEn : speaker.nameTh,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900,
                                    color: Palette.teal)),
                          ),
                        StoryTypewriter(
                          key: ValueKey(event.id),
                          text: en ? event.storyEn : event.storyTh,
                          style: const TextStyle(
                              fontSize: 13.5,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                              color: Palette.ink),
                        ),
                      ]),
                ),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 92,
          child: Row(children: [
            for (var i = 0; i < event.choices.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _actionCard(
                  key: Key('event-${event.choices[i].id}'),
                  icon: _choiceIcon(event.choices[i].outcome),
                  label: name(event.choices[i]),
                  color: i == 0 ? Palette.coral : Palette.teal,
                  onTap: () => controller.chooseEvent(event.choices[i]),
                ),
              ),
            ],
          ]),
        ),
      ]),
    );
  }
}

class _ShopPanel extends StatelessWidget {
  const _ShopPanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final potions = controller.mode.content.balance.potions.take(3).toList();
    return _panelFrame(
      title:
          '${s.storyOwlShop} · 🐟 ${controller.wallet.balance(Currency.goldfish)}',
      icon: 'owl',
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(children: [
        Expanded(
          child: Row(children: [
            for (var i = 0; i < potions.length; i++) ...[
              if (i > 0) const SizedBox(width: 7),
              Expanded(child: _potion(context, potions[i])),
            ],
          ]),
        ),
        const SizedBox(height: 6),
        TextButton.icon(
            key: const Key('leave-story-shop'),
            onPressed: controller.leaveShop,
            icon: const GameIcon('paw', size: 18),
            label: IconText(s.storyLeaveShop)),
      ]),
    );
  }

  Widget _potion(BuildContext context, StoryPotion potion) {
    final s = AppLocalizations.of(context);
    final usable = controller.potionWouldHaveEffect(potion);
    final purchased = controller.purchasedPotionIds.contains(potion.id);
    return GestureDetector(
      key: Key('potion-${potion.id}'),
      onTap: !usable
          ? null
          : () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: Palette.paper,
                  title: IconText(s.storyConfirmBuy),
                  content: IconText('🐟 ${potion.price}'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(s.cancel)),
                    FilledButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: IconText(s.storyBuy)),
                  ],
                ),
              );
              if (yes == true &&
                  context.mounted &&
                  !controller.buyPotion(potion)) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: IconText(s.storyNotEnough)));
              }
            },
      child: Opacity(
        opacity: usable ? 1 : .48,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 13, 12, 12),
          decoration: paintedCardDecoration(
              usable && !purchased ? 'card_shop' : 'card_pick'),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            GameIcon(
                usable && !purchased ? _potionIcon(potion.buffId) : 'check',
                size: 32),
            IconText(s.lang == 'en' ? potion.nameEn : potion.nameTh,
                textAlign: TextAlign.center,
                maxLines: 2,
                style:
                    const TextStyle(fontSize: 10, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            IconText(
                s.lang == 'en' ? potion.descriptionEn : potion.descriptionTh,
                textAlign: TextAlign.center,
                maxLines: 3,
                style: const TextStyle(fontSize: 8, color: Palette.inkSoft)),
            IconText('🐟 ${potion.price}',
                style: const TextStyle(fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _CampfirePanel extends StatelessWidget {
  const _CampfirePanel({super.key, required this.controller});
  final StoryRunController controller;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    return _panelFrame(
      title: s.storyCampfire,
      icon: 'bed',
      child: Row(children: [
        Expanded(
          child: _actionCard(
            key: const Key('campfire-rest'),
            icon: 'heart',
            label:
                '${s.storyRest} +${controller.mode.content.balance.campfireHealPct}%',
            color: Palette.lime,
            onTap: controller.restAtCampfire,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: controller.relicIds.isEmpty
              ? _actionCard(
                  icon: 'hourglass',
                  label: s.storyNoRelic,
                  color: Palette.inkSoft,
                  onTap: controller.leaveCampfireWithoutUpgrade,
                )
              : _RelicUpgrade(controller: controller),
        ),
      ]),
    );
  }
}

class _RelicUpgrade extends StatefulWidget {
  const _RelicUpgrade({required this.controller});
  final StoryRunController controller;

  @override
  State<_RelicUpgrade> createState() => _RelicUpgradeState();
}

class _RelicUpgradeState extends State<_RelicUpgrade> {
  String? picked;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final id = picked ?? widget.controller.relicIds.first;
    final relic = widget.controller.mode.content.relics[id]!;
    return GestureDetector(
      key: const Key('campfire-upgrade'),
      onTap: () {
        if (picked == id) {
          widget.controller.upgradeAtCampfire(id);
        } else {
          setState(() => picked = id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: storybookButton(
            fill: const Color(0xFFFFE8C2), accent: Palette.coral, radius: 9),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          GameIcon(_relicIcon(id), size: 38),
          IconText(s.storyUpgrade,
              style: const TextStyle(fontWeight: FontWeight.w900)),
          IconText(s.lang == 'en' ? relic.nameEn : relic.nameTh,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 10)),
        ]),
      ),
    );
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel(
      {super.key, required this.controller, required this.onReturn});
  final StoryRunController controller;
  final VoidCallback onReturn;

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final done = controller.completion!;
    final title = switch (done.result.outcome) {
      RunOutcome.won => s.storyVictory,
      RunOutcome.died => s.storyDefeat,
      RunOutcome.abandoned => s.storyAbandoned,
    };
    final fish = done.reward.reward[Currency.goldfish];
    return _panelFrame(
      title: title,
      icon: done.result.outcome == RunOutcome.won ? 'victory' : 'sadcat',
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        IconText('${s.storyReward} 🐟 $fish',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        FilledButton.icon(
          key: const Key('story-return'),
          onPressed: onReturn,
          icon: const GameIcon('openbook', size: 22),
          label: IconText(s.storyReturn),
        ),
      ]),
    );
  }
}

class _StatusIcons extends StatelessWidget {
  const _StatusIcons({required this.statuses});
  final List<CombatStatusView> statuses;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        for (final status in statuses.take(4))
          Padding(
            padding: const EdgeInsets.all(2),
            child: Stack(clipBehavior: Clip.none, children: [
              GameIcon('status_${_statusIcon(status.id)}',
                  size: 22, fallback: '✨'),
              if (status.stacks > 1)
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Text('${status.stacks}',
                      style: const TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w900)),
                ),
            ]),
          ),
      ]);
}

class _DottedLinkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Palette.teal
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    for (double y = 2; y < 30; y += 7) {
      canvas.drawLine(Offset(size.width / 2, y),
          Offset(size.width / 2, math.min(y + 3, 30)), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Widget _panelFrame({
  Key? key,
  required String title,
  required String icon,
  required Widget child,
  EdgeInsets padding = const EdgeInsets.fromLTRB(12, 6, 12, 10),
}) =>
    Padding(
      key: key,
      padding: padding,
      child: Column(children: [
        SizedBox(
          height: 38,
          width: 250,
          child: StretchFrame(
            frame: 'chapter',
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              GameIcon(icon, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: IconText(title,
                      maxLines: 1,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Palette.ink)),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 6),
        Expanded(child: child),
      ]),
    );

Widget _actionCard({
  Key? key,
  required String icon,
  required String label,
  required Color color,
  required VoidCallback onTap,
}) =>
    Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 108, maxWidth: 240),
        child: Semantics(
          button: true,
          label: label,
          child: PressScale(
            onTap: onTap,
            child: StretchFrame(
              key: key,
              frame: 'action',
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  GameIcon(icon, size: 40),
                  const SizedBox(height: 3),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 130),
                    child: IconText(label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: color == Palette.coral
                                ? Color.lerp(Palette.ink, Palette.coral, .7)
                                : Palette.ink)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );

Widget _statChip(String icon, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: storybookCard(
          fill: const Color(0xFFFFEDC9), accent: Palette.mochi, radius: 7),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        GameIcon(icon, size: 18),
        const SizedBox(width: 4),
        Flexible(child: IconText(label, style: const TextStyle(fontSize: 11))),
      ]),
    );

Widget _paperMessage(String icon, String label, Color color) => Container(
      padding: const EdgeInsets.all(18),
      decoration: storybookCard(accent: color),
      child: Column(children: [GameIcon(icon, size: 52), IconText(label)]),
    );

String _encounterIcon(EncounterType type) => switch (type) {
      EncounterType.combat => 'sword',
      EncounterType.treasure => 'gift',
      EncounterType.event => 'question',
      EncounterType.campfire => 'bed',
      EncounterType.shop => 'owl',
      EncounterType.fork => 'scroll',
      EncounterType.boss => 'crown',
    };

String _encounterName(AppLocalizations s, EncounterType type) => switch (type) {
      EncounterType.combat => s.storyAheadCombat,
      EncounterType.treasure => s.storyAheadTreasure,
      EncounterType.event => s.storyAheadEvent,
      EncounterType.campfire => s.storyAheadCampfire,
      EncounterType.shop => s.storyAheadShop,
      EncounterType.fork => s.storyMap,
      EncounterType.boss => s.storyAheadBoss,
    };

String _relicIcon(String id) {
  if (id.contains('electric') || id.contains('lightning')) return 'bolt';
  if (id.contains('bell')) return 'bell';
  if (id.contains('fish')) return 'fish';
  if (id.contains('scarf') || id.contains('cape')) return 'coat';
  if (id.contains('claw')) return 'dagger';
  if (id.contains('milk')) return 'milk';
  if (id.contains('shield')) return 'shield';
  if (id.contains('thread')) return 'yarn';
  if (id.contains('star') || id.contains('button')) return 'star';
  if (id.contains('map') || id.contains('pencil')) return 'scroll';
  if (id.contains('ink')) return 'poison_blade';
  return 'sparkle';
}

bool _hasSynergy(StoryContent content, Set<String> owned, String candidate) {
  final relic = content.relics[candidate]!;
  if (relic.synergies.any((s) => owned.contains(s.withRelic))) return true;
  return owned.any((id) => content.relics[id]!.synergies
      .any((synergy) => synergy.withRelic == candidate));
}

String _choiceIcon(StoryEventOutcome outcome) {
  if (outcome.relicChoice) return 'gift';
  if (outcome.healPct > 0) return 'heart';
  if (outcome.buffId != null) return 'sparkle';
  if (outcome.xp > 0) return 'star';
  return 'fish';
}

String _potionIcon(String buffId) {
  if (buffId.contains('heal')) return 'heart';
  if (buffId.contains('shield') || buffId == 'iron_wall') return 'shield';
  return 'sword';
}

String _statusIcon(String id) {
  if (id.contains('poison')) return 'poison';
  if (id.contains('burn')) return 'burn';
  if (id.contains('frost')) return 'frost';
  if (id.contains('stun')) return 'stun';
  if (id.contains('shield') || id == 'iron_wall') return 'shield';
  if (id.contains('war_cry')) return 'war_cry';
  if (id.contains('eagle') || id.contains('crit')) return 'eagle';
  return 'shadow';
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
