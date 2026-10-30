import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_core/wt_core_testing.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

class _RepoSource implements ContentSource {
  @override
  Future<String> read(String path) => File('../../$path').readAsString();
}

void main() {
  final json = jsonDecode(File('assets/manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  late StoryMode mode;

  setUpAll(() async {
    final content = await ContentRepository(_RepoSource()).loadAll();
    mode = StoryMode(ModeManifest.fromJson(json), content.story);
  });

  test('passes the shared mode conformance checks', () {
    expect(checkModeConformance(mode, manifestJson: json), isEmpty);
  });

  test('ships enabled and opens after the chapter 1 boss', () {
    expect(mode.manifest.enabled, isTrue);
    expect(mode.manifest.unlock!.type, UnlockType.bossCleared);
    expect(mode.manifest.unlock!.value, 'eraserking');
  });

  test('save round trip keeps progress; junk becomes zero', () {
    final s = mode.decodeSave({
      'best_depth': 4,
      'runs': 2,
      'reward_day': '2026-10-24',
      'reward_runs_today': 3,
      'bosses_cleared': ['paperwolf', 7],
    }) as StorySave;
    expect(s.bestDepth, 4);
    expect(s.bossesCleared, ['paperwolf']);
    expect(mode.encodeSave(s), {
      'best_depth': 4,
      'runs': 2,
      'reward_day': '2026-10-24',
      'reward_runs_today': 3,
      'bosses_cleared': ['paperwolf'],
    });
    final bad = mode.decodeSave({'best_depth': -3, 'runs': 'x'}) as StorySave;
    expect([bad.bestDepth, bad.runs], [0, 0]);
  });

  test('creates a seeded 8–10 node route with branches and a final boss', () {
    final state = mode.decodeSave(const {});
    final config = mode.createRunConfig(state);
    final source = mode.encounterSource(config) as MapEncounterSource;
    expect(source.map.length, inInclusiveRange(8, 10));
    expect(source.map.stages.last.choices.single.type, EncounterType.boss);
    expect(source.map.stages.last.choices.single.contentId, 'paperwolf');
    for (final stage in source.map.stages) {
      for (final encounter in stage.choices) {
        if (encounter.type == EncounterType.combat) {
          expect(mode.content.monsters, contains(encounter.contentId));
        }
        if (encounter.type == EncounterType.event) {
          expect(mode.content.events, contains(encounter.contentId));
        }
      }
    }
  });

  test('first three daily runs pay full, later runs pay 25 percent', () {
    final state =
        StorySave(rewardDay: '2026-10-24', rewardRunsToday: 3, runs: 8);
    expect(mode.completedRunsOn(state, '2026-10-24'), 3);
    expect(mode.completedRunsOn(state, '2026-10-25'), 0);
    final full = mode.resolveReward(
        const RunResult(
            outcome: RunOutcome.won, depthReached: 9, completedRunsToday: 2),
        state);
    final repeat = mode.resolveReward(
        const RunResult(
            outcome: RunOutcome.won, depthReached: 9, completedRunsToday: 3),
        state);
    expect(full.reward[Currency.goldfish], 140);
    expect(repeat.reward[Currency.goldfish], 35);
  });

  test('run result updates best depth, daily count and cleared bosses', () {
    final updated = mode.updateAfterRun(
        const RunResult(
          outcome: RunOutcome.won,
          depthReached: 9,
          bossesCleared: ['paperwolf'],
          dayKey: '2026-10-24',
          completedRunsToday: 1,
        ),
        StorySave(bestDepth: 4, runs: 2)) as StorySave;
    expect(updated.bestDepth, 9);
    expect(updated.runs, 3);
    expect(updated.rewardDay, '2026-10-24');
    expect(updated.rewardRunsToday, 2);
    expect(updated.bossesCleared, ['paperwolf']);
  });

  test('registers with one line and is found by id', () {
    final r = ModeRegistry()..register(mode);
    expect(r.byId('story'), same(mode));
    expect(r.enabledModes, [mode]);
  });
}
