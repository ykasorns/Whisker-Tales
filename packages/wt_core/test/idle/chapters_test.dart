import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:wt_core/wt_core.dart';

Map<String, dynamic> _j(String p) =>
    jsonDecode(File(p).readAsStringSync()) as Map<String, dynamic>;

/// D-032: monsters, bosses and scenery per chapter come from chapters.json.
void main() {
  final rules =
      IdleRules.fromBalance(_j('../../design/balance/idle_balance_v1.json'));
  final data = _j('../../design/data/chapters.json');

  test('one chapter per chapter of a book; boss on the last page', () {
    final book = ChapterBook.fromJson(data, rules);
    expect(book.chapters.length, rules.chaptersPerBook);
    expect(book.bossOf(rules, rules.pagesPerChapter), book.chapters.first.boss);
    expect(book.bossOf(rules, 1), book.chapters.first.monsters.first);
    expect(book.kinds.toSet().length, book.kinds.length);
  });

  test('a missing chapter or an empty monster list names the problem', () {
    final short = {
      'chapters': (data['chapters'] as List).take(2).toList(),
    };
    expect(() => ChapterBook.fromJson(short, rules),
        throwsA(isA<FormatException>()));
    final empty = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    (empty['chapters'] as List).first['monsters'] = [];
    expect(() => ChapterBook.fromJson(empty, rules),
        throwsA(isA<FormatException>()));
  });
}
