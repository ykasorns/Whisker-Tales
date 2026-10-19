import '../core/random/seeded_rng.dart';
import '../core/contracts/idle_loop.dart';
import 'idle_rules.dart';

/// Mixes ints into one 32-bit seed (FNV-1a over 32-bit words).
int mixSeed(List<int> parts) {
  var h = 0x811C9DC5;
  for (final p in parts) {
    h = ((h ^ (p & 0xFFFFFFFF)) * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

int _between(SeededRng rng, (int, int) r) =>
    r.$1 + rng.nextUint32() % (r.$2 - r.$1 + 1);

/// Waves and monsters of [page] (GDD v0.5.2 §9.1). Depends only on the page
/// number, so every player and every visit sees the same plan.
PagePlan pagePlan(IdleRules rules, int page) {
  if (page < 1) throw ArgumentError.value(page, 'page', 'must be >= 1');
  final chapter = rules.chapterOf(page);
  final rng = SeededRng(mixSeed([0x9A6E, page]));
  final isLong = rules.longPages.contains(rules.pageInChapter(page));
  final waves = _between(rng, rules.wavesByChapter[chapter - 1]) +
      (isLong ? rules.longExtraWaves : 0);
  return PagePlan(
    page: page,
    chapter: chapter,
    isLong: isLong,
    monstersPerWave: List.unmodifiable([
      for (var i = 0; i < waves; i++)
        _between(rng, rules.monstersByChapter[chapter - 1]),
    ]),
  );
}
