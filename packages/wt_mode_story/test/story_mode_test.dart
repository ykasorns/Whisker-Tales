import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';
import 'package:wt_core/wt_core_testing.dart';
import 'package:wt_mode_story/wt_mode_story.dart';

void main() {
  final json = jsonDecode(File('assets/manifest.json').readAsStringSync())
      as Map<String, dynamic>;
  final mode = StoryMode(ModeManifest.fromJson(json));

  test('passes the shared mode conformance checks', () {
    expect(checkModeConformance(mode, manifestJson: json), isEmpty);
  });

  test('ships dormant and opens after the chapter 1 boss', () {
    expect(mode.manifest.enabled, isFalse);
    expect(mode.manifest.unlock!.type, UnlockType.bossCleared);
    expect(mode.manifest.unlock!.value, 'eraserking');
  });

  test('save round trip keeps progress; junk becomes zero', () {
    final s = mode.decodeSave({
      'best_depth': 4,
      'runs': 2,
      'bosses_cleared': ['eraserking', 7],
    }) as StorySave;
    expect(s.bestDepth, 4);
    expect(s.bossesCleared, ['eraserking']);
    expect(mode.encodeSave(s), {
      'best_depth': 4,
      'runs': 2,
      'bosses_cleared': ['eraserking'],
    });
    final bad = mode.decodeSave({'best_depth': -3, 'runs': 'x'}) as StorySave;
    expect([bad.bestDepth, bad.runs], [0, 0]);
  });

  test('registers with one line and is found by id', () {
    final r = ModeRegistry()..register(mode);
    expect(r.byId('story'), same(mode));
    expect(r.enabledModes, isEmpty); // dormant: the menu shows nothing
  });
}
