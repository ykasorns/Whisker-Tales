import 'dart:convert';
import 'dart:math';

import '../core/contracts/game_mode.dart';
import '../core/contracts/rewards.dart';

/// The shared checks every mode must pass (MODE_PLUGIN_SPEC §7). Plain
/// functions, so a mode's own test runs them with `expect(problems, isEmpty)`
/// and wt_core needs no test dependency at run time.
///
/// Returns one line per problem; empty = conforms.
List<String> checkModeConformance(
  GameMode mode, {
  required Map<String, dynamic> manifestJson,
  int maxDepth = 1000,
}) {
  final problems = <String>[];
  void check(String what, void Function() body) {
    try {
      body();
    } on Object catch (e) {
      problems.add('$what: $e');
    }
  }

  check('manifest', () {
    final parsed = ModeManifest.fromJson(manifestJson);
    if (parsed.id != mode.id) {
      problems.add('manifest id "${parsed.id}" != mode id "${mode.id}"');
    }
  });

  check('save roundtrip', () {
    final fresh = mode.decodeSave(const {});
    final json = mode.encodeSave(fresh);
    final again = mode.encodeSave(
        mode.decodeSave(jsonDecode(jsonEncode(json)) as Map<String, dynamic>));
    if (jsonEncode(json) != jsonEncode(again)) {
      problems.add('save changes after decode/encode');
    }
  });

  check('encounters', () {
    final state = mode.decodeSave(const {});
    final config = mode.createRunConfig(state);
    final a = mode.encounterSource(config);
    final b = mode.encounterSource(config);
    final ra = Random(config.seed), rb = Random(config.seed);
    for (var d = 0; d <= maxDepth; d++) {
      final ea = a.next(d, ra), eb = b.next(d, rb);
      if (ea?.type != eb?.type || ea?.contentId != eb?.contentId) {
        problems.add('same seed gave different encounters at depth $d');
        break;
      }
      a.preview(d, 3);
    }
  });

  check('reward vocabulary', () {
    final state = mode.decodeSave(const {});
    for (final outcome in RunOutcome.values) {
      final r = mode.resolveReward(
          RunResult(outcome: outcome, depthReached: 5), state);
      for (final c in r.reward.amounts.keys) {
        if (!Currency.values.contains(c)) problems.add('unknown currency $c');
      }
      for (final v in r.reward.amounts.values) {
        if (v < 0) problems.add('negative reward for $outcome');
      }
    }
  });

  return problems;
}
