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
    expect(book.books.first.chapters.length, rules.chaptersPerBook);
    expect(book.bossOf(rules, rules.pagesPerChapter), book.chapters.first.boss);
    expect(book.bossOf(rules, 1), book.chapters.first.monsters.first);
    expect(book.kinds.toSet().length, book.kinds.length);
  });

  test('a missing chapter or an empty monster list names the problem', () {
    final short = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final first = (short['books'] as List).first as Map<String, dynamic>;
    first['chapters'] = (first['chapters'] as List).take(2).toList();
    expect(() => ChapterBook.fromJson(short, rules),
        throwsA(isA<FormatException>()));
    final empty = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    ((empty['books'] as List).first['chapters'] as List).first['monsters'] = [];
    expect(() => ChapterBook.fromJson(empty, rules),
        throwsA(isA<FormatException>()));
  });

  test('books switch every pagesPerBook pages and the last book loops', () {
    // Book 2 is a copy of book 1 with its own scenery and ids.
    final two = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    final b1 = (two['books'] as List).first as Map<String, dynamic>;
    final b2 = jsonDecode(jsonEncode(b1)) as Map<String, dynamic>
      ..['id'] = 'book2'
      ..['scenery'] = 'book2';
    for (final c in b2['chapters'] as List) {
      c['boss'] = 'b2_${c['boss']}';
      c['monsters'] = [for (final m in c['monsters'] as List) 'b2_$m'];
    }
    (two['books'] as List).add(b2);
    final book = ChapterBook.fromJson(two, rules);
    final per = rules.pagesPerBook;
    expect(book.bookOf(rules, per).id, 'book1');
    expect(book.bookOf(rules, per + 1).id, 'book2');
    expect(book.bookOf(rules, 2 * per).id, 'book2');
    expect(book.bookOf(rules, 2 * per + 1).id, 'book2'); // last book loops
    expect(book.of(rules, per + 1).scenery, 'book2');
    expect(book.of(rules, per).scenery, 'book1');
    expect(book.bossOf(rules, 2 * per), startsWith('b2_'));
    expect(book.chapters.length, 2 * rules.chaptersPerBook);
  });

  test('a book without scenery or with a wrong chapter count is rejected', () {
    final bad = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
    ((bad['books'] as List).first as Map<String, dynamic>).remove('scenery');
    expect(() => ChapterBook.fromJson(bad, rules),
        throwsA(isA<FormatException>()));
  });
}
