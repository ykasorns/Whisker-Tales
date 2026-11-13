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
    expect(book.of(rules, 31).layer, 'ch4');
    expect(book.of(rules, 41).layer, 'ch5');
    expect(book.of(rules, 51).layer, 'ch6');
    // Pages past the last authored book loop its three chapters.
    expect(book.of(rules, 61).layer, 'ch4');
    expect(book.bossOf(rules, 10), 'eraserking');
    expect(book.bossOf(rules, 15), 'inkbat');
    expect(book.bossOf(rules, 20), 'sharpcrab');
    expect(book.bossOf(rules, 30), 'paperwolf');
    expect(book.bossOf(rules, 40), 'quiltbear');
    expect(book.bossOf(rules, 50), 'thimbleturtle');
    expect(book.bossOf(rules, 60), 'yarnyeti');
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
    for (final b in book.books) {
      for (final l in ['L0_sky', 'L3_ground']) {
        expect(
            File('assets/game/bg/bg_${b.scenery}_$l.webp').existsSync(), isTrue,
            reason: '${b.id} $l');
      }
    }
    for (final c in book.chapters) {
      for (final l in ['L1_far', 'L2_mid']) {
        expect(
            File('assets/game/bg/bg_${c.scenery}_${c.layer}_$l.webp')
                .existsSync(),
            isTrue,
            reason: '${c.id} $l');
      }
      for (final k in [...c.monsters, c.boss]) {
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
