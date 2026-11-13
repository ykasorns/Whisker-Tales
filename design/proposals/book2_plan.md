# Book 2 plan — "Craft Room" (pages 31–60), proposed D-067

Assumption: "new map" = the next book of the main farm. Book 1 (pages 1–30) has its own scenery, monsters and bosses; pages 31+ currently replay Book 1 (`chapters.json`: "later books reuse this set until they have their own"). If YK meant a different kind of map, stop here and re-scope.

## Content
- 3 chapters × 10 pages (`pages_per_chapter` 10, `chapters_per_book` 3): `patch_meadow`, `ribbon_river`, `yarn_peaks`; 2 monsters + 1 boss each. Names, characters and all art specs: `design/art/book2_art_prompt.md` (20 images).
- Enemy power after page 30 already follows `page_power_growth_after_book1` (1.09/page since D-067; was 1.065, which cleared pages 31–60 in ~1.3 days). Re-run the balance sim after wiring to confirm the day-by-day target still holds for pages 31–60.

## Work for Claude (no art needed)
_Status 2026-11-13: steps 1, 2 and the tests in 5 are DONE (D-067, books[] model, last book loops, scenery from data). Book 2 itself is added to chapters.json when the art arrives._

1. **Data model.** `design/data/chapters.json` becomes `books: [{ id, sky, ground, chapters: [...] }]`. `ChapterBook` in `wt_core` picks the book by `(page-1) ~/ (pages_per_chapter*chapters_per_book)`; from the last book onwards it loops the last book (not book 1). Keep a test that rejects a book with the wrong chapter count. This avoids hard-coding `bg_book1_` anywhere.
2. **Scenery lookup.** `app/lib/game_view.dart` (lines ~200 and ~458) uses `bg/bg_book1_*`; take sky/ground/layer names from the book/chapter data instead and preload per book.
3. **Sprite sync.** `tools/sync_sprites.py`: add the 9 new ids to `MONSTERS`, convert the 8 `bg_book2_*` layers to webp like Book 1, copy the three `ui_bossface_*` sets; keep the APK under 30 MB (Book 1 art is ~3 MB; budget ≤ 3 MB for Book 2, so cap sprite width at 440 px and quantise as for Book 1).
4. **Boss-challenge icon** and chapter banner: read the icon by id from the chapter data (today it is chosen per chapter 1–3).
5. **Tests.** Chapter lookup per page (30/31/60/61), scenery asset existence for every layer named in the data (so a missing file fails a test, not the phone), golden of the farm scene on page 31.
6. **Docs.** D-067 in `DECISIONS.md`, HANDOFF row, `RELEASE_CHECKLIST.md` (Book 2 art is the last item before "Book 2 playable").

## Order
1. YK sends `design/art/book2_art_prompt.md` to GPT (chapter 4 first).
2. Claude does steps 1–2 and 5 now (data model + tests; Book 1 plays exactly as before), then 3–4 and the goldens when the art arrives.
3. Real-phone check of pages 31–60 pacing.

## Open questions for YK
- Is Book 2 the right "new map", or did you want a new Adventure mode / a map picker?
- Keep the craft-room theme (sewing and knitting), or another theme?
- Should the Adventure story (`wt_mode_story`) get a Book 2 chapter later, or is this farm-only?

## Update 2026-11-13: scenery redo
The first art pack made the far, mid and ground layers fully opaque (the first brief said "opaque"; Book 1's are transparent above the art), so the mid layers hide the far layer. Redo brief: `design/art/book2_layers_v2_prompt.md` (7 layers with true alpha, optional sky). Claude re-checks pages 31/41/51 in the game when the files arrive.
