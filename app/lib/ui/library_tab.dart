import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wt_core/wt_core.dart';

import '../l10n/strings.dart';
import 'home_page.dart';
import 'palette.dart';

/// `1:05:09` / `4:07` — timers read the same in both languages.
String fmtDur(Duration d) {
  String two(int n) => n.toString().padLeft(2, '0');
  final h = d.inHours, m = d.inMinutes % 60, s = d.inSeconds % 60;
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '$m:${two(s)}';
}

/// 🦉 Owl library (GDD v0.4 §7, T-041): running desks with a countdown and
/// the 📺 time cut, then every node with its cost, time and lock reason.
class LibraryTab extends ConsumerStatefulWidget {
  const LibraryTab({super.key, this.tick = 0});

  /// Changes a few times a second so countdowns move.
  final int tick;

  @override
  ConsumerState<LibraryTab> createState() => _LibraryTabState();
}

class _LibraryTabState extends ConsumerState<LibraryTab> {
  bool _busy = false;

  Future<void> _speedUp(Research r, String nodeId) async {
    if (_busy) return;
    setState(() => _busy = true);
    await r.speedUpWithAd(nodeId);
    if (mounted) setState(() => _busy = false);
  }

  String _name(AppLocalizations s, ResearchNode n) =>
      s.lang == 'en' ? n.nameEn : n.nameTh;

  String _effect(AppLocalizations s, Research r, ResearchNode n) {
    final lv = r.levelOf(n.id);
    switch (n.effect) {
      case ResearchEffect.stat:
        final per = r.rules.statBpPerLevel / 100;
        return s.statNode(s.statName(n.mainStat!), _pct(per), _pct(per * lv));
      case ResearchEffect.bonus:
        final per = n.bonusBpPerLevel / 100;
        return s.statNode(_name(s, n), _pct(per), _pct(per * lv));
      case ResearchEffect.offlineCap:
        final cap = ref.read(offlineRulesProvider).capFor(lv);
        return s.offlineNode(fmtDur(cap).replaceAll(RegExp(r':\d\d$'), ''));
      case ResearchEffect.queue:
        return s.queueNode;
    }
  }

  static String _pct(num v) => v == v.roundToDouble()
      ? '${v.round()}'
      : v.toStringAsFixed(2).replaceAll(RegExp(r'0$'), '');

  @override
  Widget build(BuildContext context) {
    final s = AppLocalizations.of(context);
    final r = ref.read(researchProvider);
    if (r == null) return const SizedBox();
    final ads = ref.read(adServiceProvider);
    final adsLeft = ads.remainingToday(researchSpeedupPlacement);
    return ListView(padding: const EdgeInsets.all(12), children: [
      Container(
        padding: const EdgeInsets.all(12),
        decoration: inkBox(fill: const Color(0xFFEFE6FF)),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Text('🦉', style: TextStyle(fontSize: 44)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(s.libraryTitle,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
            ),
          ]),
          for (var i = 0; i < r.queueSlots; i++)
            _desk(s, r, i < r.tasks.length ? r.tasks[i] : null, i,
                ad: ads.canShow(researchSpeedupPlacement), adsLeft: adsLeft),
          Row(children: [
            Expanded(
              child:
                  Text(s.notifyResearch, style: const TextStyle(fontSize: 13)),
            ),
            Switch(
              value: r.notifyDone,
              activeThumbColor: Palette.teal,
              onChanged: (v) => setState(() => r.notifyDone = v),
            ),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      for (final n in r.rules.nodes) _node(s, r, n),
    ]);
  }

  /// One desk: what it reads, the countdown, and its own 📺 button so the
  /// player picks which task the ad cuts (D-022).
  Widget _desk(AppLocalizations s, Research r, ResearchTask? t, int i,
      {required bool ad, required int adsLeft}) {
    if (t == null) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(s.deskFree(i + 1),
            style: const TextStyle(color: Palette.inkSoft)),
      );
    }
    final node = r.rules.byId(t.nodeId)!;
    final total = r.rules.timeFor(node, t.toLevel);
    final left = r.remaining(t);
    final done = total.inSeconds == 0
        ? 1.0
        : (1 - left.inSeconds / total.inSeconds).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text('${node.icon} ${_name(s, node)} → ${s.level(t.toLevel)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
          const Spacer(),
          Text('⏱ ${fmtDur(left)}',
              style: const TextStyle(fontWeight: FontWeight.w800)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: done, color: Palette.teal, minHeight: 8),
        if (ad)
          GestureDetector(
            onTap: _busy ? null : () => _speedUp(r, t.nodeId),
            child: Container(
              height: 44,
              margin: const EdgeInsets.only(top: 6),
              alignment: Alignment.center,
              decoration: inkBox(fill: Palette.sun, radius: 12),
              child: Text(s.adSpeedUp(r.rules.adCutMin, adsLeft),
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800)),
            ),
          ),
      ]),
    );
  }

  Widget _node(AppLocalizations s, Research r, ResearchNode n) {
    final lv = r.levelOf(n.id);
    final block = r.blockOf(n.id);
    final label = switch (block) {
      null ||
      ResearchBlock.fish =>
        '🐟 ${fmtNum(r.costOf(n))}\n⏱ ${fmtDur(r.timeOf(n))}',
      ResearchBlock.maxed => s.maxed,
      ResearchBlock.running => s.researching,
      ResearchBlock.queueFull => s.queueFull,
      ResearchBlock.locked => [
          for (final (id, need) in r.missing(n))
            '${_name(s, r.rules.byId(id)!)} Lv.$need',
        ].join('\n'),
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: inkBox(
          fill: block == ResearchBlock.locked
              ? const Color(0xFFEDE8DF)
              : Palette.paper,
          radius: 14),
      child: Row(children: [
        Text(block == ResearchBlock.locked ? '🔒' : n.icon,
            style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 10),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${_name(s, n)}  ${s.level(lv)}/${n.maxLevel}',
                style: const TextStyle(fontWeight: FontWeight.w800)),
            Text(_effect(s, r, n),
                style: const TextStyle(fontSize: 12, color: Palette.inkSoft)),
          ]),
        ),
        GestureDetector(
          onTap: block == null ? () => setState(() => r.start(n.id)) : null,
          child: Opacity(
            opacity: block == null ? 1 : 0.5,
            child: Container(
              width: 104,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              alignment: Alignment.center,
              decoration: inkBox(
                  fill: block == null ? Palette.lime : Palette.paper,
                  radius: 12),
              child: Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ]),
    );
  }
}
