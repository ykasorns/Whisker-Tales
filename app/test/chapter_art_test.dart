import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:whisker_tales/chapter_art.dart';
import 'package:wt_core/wt_core.dart';

/// D-031: every chapter draws its own monsters, boss, boss face and scenery,
/// and every file it names is in the app bundle.
void main() {
  late IdleRules rules;
  setUpAll(() async {
    final c = await ContentRepository(_Disk()).loadAll();
    rules = c.idle;
  });

  test('chapters pick their own art; the chapter boss is on page 10', () {
    expect(ChapterArt.of(rules, 1).layer, 'ch1');
    expect(ChapterArt.of(rules, 11).layer, 'ch2');
    expect(ChapterArt.of(rules, 30).layer, 'ch3');
    expect(ChapterArt.of(rules, 31).layer, 'ch1'); // book 2 reuses book 1
    expect(ChapterArt.bossOf(rules, 10), 'eraserking');
    expect(ChapterArt.bossOf(rules, 15), 'inkbat');
    expect(ChapterArt.bossOf(rules, 20), 'sharpcrab');
    expect(ChapterArt.bossOf(rules, 30), 'paperwolf');
  });

  test('every frame, face and layer exists', () {
    const frames = [
      'idle_f1', 'idle_f2', 'idle_f3', 'telegraph_f1', 'telegraph_f2', //
      'attack', 'defeated',
    ];
    for (final k in ChapterArt.kinds) {
      for (final f in frames) {
        expect(File('assets/game/mon/${k}_$f.png').existsSync(), isTrue,
            reason: '$k $f');
      }
    }
    for (final a in ChapterArt.all) {
      for (final l in ['L1_far', 'L2_mid']) {
        expect(File('assets/game/bg/bg_book1_${a.layer}_$l.png').existsSync(),
            isTrue);
      }
      for (final k in [a.boss, a.monsters.first]) {
        expect(File('assets/game/ui/ui_bossface_$k.png').existsSync(), isTrue,
            reason: k);
      }
    }
  });
}

class _Disk implements ContentSource {
  @override
  Future<String> read(String path) async =>
      File('assets/content/$path').readAsStringSync();
}
