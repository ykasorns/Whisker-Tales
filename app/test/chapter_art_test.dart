import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

/// D-031/D-032: every chapter draws its own monsters, boss, boss face and
/// scenery from `chapters.json`, and every file it names is in the bundle.
void main() {
  late IdleRules rules;
  late ChapterBook book;
  setUpAll(() async {
    final c = await ContentRepository(_Disk()).loadAll();
    rules = c.idle;
    book = c.chapters;
  });

  test('chapters pick their own art; the chapter boss is on page 10', () {
    expect(book.of(rules, 1).layer, 'ch1');
    expect(book.of(rules, 11).layer, 'ch2');
    expect(book.of(rules, 30).layer, 'ch3');
    expect(book.of(rules, 31).layer, 'ch1'); // book 2 reuses book 1
    expect(book.bossOf(rules, 10), 'eraserking');
    expect(book.bossOf(rules, 15), 'inkbat');
    expect(book.bossOf(rules, 20), 'sharpcrab');
    expect(book.bossOf(rules, 30), 'paperwolf');
  });

  test('every frame, face and layer exists', () {
    const frames = [
      'idle_f1', 'idle_f2', 'idle_f3', 'telegraph_f1', 'telegraph_f2', //
      'attack', 'defeated',
    ];
    for (final k in book.kinds) {
      for (final f in frames) {
        expect(File('assets/game/mon/${k}_$f.png').existsSync(), isTrue,
            reason: '$k $f');
      }
    }
    for (final c in book.chapters) {
      for (final l in ['L1_far', 'L2_mid']) {
        expect(File('assets/game/bg/bg_book1_${c.layer}_$l.png').existsSync(),
            isTrue);
      }
      for (final k in [c.boss, c.monsters.first]) {
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
