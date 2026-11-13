import 'dart:math' as math;

import 'idle_rules.dart';

/// One chapter's look: its monsters, chapter boss and scenery (D-032).
class ChapterInfo {
  const ChapterInfo({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.layer,
    required this.scenery,
    required this.monsters,
    required this.boss,
  });

  final String id, nameTh, nameEn;

  /// Background layer id: `bg_<scenery>_<layer>_L1_far` / `_L2_mid`.
  final String layer;

  /// The book's scenery prefix: `bg_<scenery>_L0_sky` / `_L3_ground` are
  /// shared by every chapter of the book.
  final String scenery;

  /// Wave monsters, taken in turn.
  final List<String> monsters;

  /// The chapter boss on the chapter's last page.
  final String boss;
}

/// One book: its scenery prefix and one [ChapterInfo] per chapter.
class BookInfo {
  const BookInfo(
      {required this.id, required this.scenery, required this.chapters});
  final String id, scenery;
  final List<ChapterInfo> chapters;
}

/// `design/data/chapters.json`: the books in play order, each with one entry
/// per chapter. Past the last book the last book loops (D-067).
class ChapterBook {
  ChapterBook(this.books) : assert(books.isNotEmpty);

  final List<BookInfo> books;

  factory ChapterBook.fromJson(Map<String, dynamic> j, IdleRules idle) {
    final rawBooks = j['books'];
    if (rawBooks is! List || rawBooks.isEmpty) {
      throw const FormatException(
          'chapters: "books" must list at least one book');
    }
    String str(Map<String, dynamic> m, String k, String where) {
      final v = m[k];
      if (v is! String || v.isEmpty) {
        throw FormatException('chapters.$where: "$k" must be a name');
      }
      return v;
    }

    return ChapterBook(List.unmodifiable([
      for (final b in rawBooks.cast<Map<String, dynamic>>())
        () {
          final id = str(b, 'id', 'book');
          final scenery = str(b, 'scenery', id);
          final raw = b['chapters'];
          if (raw is! List || raw.length != idle.chaptersPerBook) {
            throw FormatException(
                'chapters.$id: needs ${idle.chaptersPerBook} chapters (pages.chapters_per_book)');
          }
          return BookInfo(
            id: id,
            scenery: scenery,
            chapters: List.unmodifiable([
              for (final m in raw.cast<Map<String, dynamic>>())
                ChapterInfo(
                  id: str(m, 'id', id),
                  nameTh: str(m, 'name_th', id),
                  nameEn: str(m, 'name_en', id),
                  layer: str(m, 'layer', id),
                  scenery: scenery,
                  boss: str(m, 'boss', id),
                  monsters: switch (m['monsters']) {
                    final List l
                        when l.isNotEmpty && l.every((e) => e is String) =>
                      List.unmodifiable(l.cast<String>()),
                    _ => throw FormatException(
                        'chapters.${m['id']}: "monsters" must list monster ids'),
                  },
                ),
            ]),
          );
        }(),
    ]));
  }

  /// Every chapter of every book, in play order.
  List<ChapterInfo> get chapters => [for (final b in books) ...b.chapters];

  /// Every monster and boss id, for preloading sprites.
  Iterable<String> get kinds =>
      chapters.expand((c) => [...c.monsters, c.boss]).toSet();

  /// The book that [page] belongs to; the last book loops.
  BookInfo bookOf(IdleRules rules, int page) =>
      books[math.min(rules.bookOf(page), books.length) - 1];

  ChapterInfo of(IdleRules rules, int page) =>
      bookOf(rules, page).chapters[rules.chapterOf(page) - 1];

  /// The boss fought on [page]: the chapter boss on its last page, otherwise
  /// a big first monster of the chapter.
  String bossOf(IdleRules rules, int page) {
    final c = of(rules, page);
    return rules.isChapterBoss(page) ? c.boss : c.monsters.first;
  }
}
