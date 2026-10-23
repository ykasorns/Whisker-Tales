import 'package:wt_core/wt_core.dart';

/// Which monsters, boss and scenery each chapter of a book draws (D-031).
/// Later books reuse book 1's art until they get their own.
class ChapterArt {
  const ChapterArt(this.layer, this.monsters, this.boss);

  /// Background layer id: `bg/bg_book1_<layer>_L1_far.png` / `_L2_mid.png`.
  final String layer;
  final List<String> monsters;

  /// The chapter boss on the chapter's last page.
  final String boss;

  static const all = [
    ChapterArt('ch1', ['eraserslime', 'acorn'], 'eraserking'),
    ChapterArt('ch2', ['inkbat', 'crayonsnail'], 'sharpcrab'),
    ChapterArt('ch3', ['shavinghog', 'clipbeetle'], 'paperwolf'),
  ];

  static Iterable<String> get kinds =>
      all.expand((a) => [...a.monsters, a.boss]);

  static ChapterArt of(IdleRules rules, int page) =>
      all[(rules.chapterOf(page) - 1) % all.length];

  /// The boss fought on [page]: the chapter boss on its last page, otherwise
  /// a big first monster of the chapter.
  static String bossOf(IdleRules rules, int page) {
    final art = of(rules, page);
    return rules.isChapterBoss(page) ? art.boss : art.monsters.first;
  }
}
