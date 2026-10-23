import 'idle_rules.dart';

/// One chapter's look: its monsters, chapter boss and scenery (D-032).
class ChapterInfo {
  const ChapterInfo({
    required this.id,
    required this.nameTh,
    required this.nameEn,
    required this.layer,
    required this.monsters,
    required this.boss,
  });

  final String id, nameTh, nameEn;

  /// Background layer id: `bg_book1_<layer>_L1_far` / `_L2_mid`.
  final String layer;

  /// Wave monsters, taken in turn.
  final List<String> monsters;

  /// The chapter boss on the chapter's last page.
  final String boss;
}

/// `design/data/chapters.json`: one entry per chapter of a book. Later
/// books reuse these until they get their own.
class ChapterBook {
  ChapterBook(this.chapters);

  final List<ChapterInfo> chapters;

  factory ChapterBook.fromJson(Map<String, dynamic> j, IdleRules idle) {
    final raw = j['chapters'];
    if (raw is! List || raw.length != idle.chaptersPerBook) {
      throw FormatException(
          'chapters: needs ${idle.chaptersPerBook} chapters (pages.chapters_per_book)');
    }
    String str(Map<String, dynamic> m, String k) {
      final v = m[k];
      if (v is! String || v.isEmpty) {
        throw FormatException('chapters.${m['id']}: "$k" must be a name');
      }
      return v;
    }

    return ChapterBook(List.unmodifiable([
      for (final m in raw.cast<Map<String, dynamic>>())
        ChapterInfo(
          id: str(m, 'id'),
          nameTh: str(m, 'name_th'),
          nameEn: str(m, 'name_en'),
          layer: str(m, 'layer'),
          boss: str(m, 'boss'),
          monsters: switch (m['monsters']) {
            final List l when l.isNotEmpty && l.every((e) => e is String) =>
              List.unmodifiable(l.cast<String>()),
            _ => throw FormatException(
                'chapters.${m['id']}: "monsters" must list monster ids'),
          },
        ),
    ]));
  }

  /// Every monster and boss id, for preloading sprites.
  Iterable<String> get kinds =>
      chapters.expand((c) => [...c.monsters, c.boss]).toSet();

  ChapterInfo of(IdleRules rules, int page) =>
      chapters[(rules.chapterOf(page) - 1) % chapters.length];

  /// The boss fought on [page]: the chapter boss on its last page, otherwise
  /// a big first monster of the chapter.
  String bossOf(IdleRules rules, int page) {
    final c = of(rules, page);
    return rules.isChapterBoss(page) ? c.boss : c.monsters.first;
  }
}
