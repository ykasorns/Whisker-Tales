# HANDOFF — Whisker Tales (updated 2026-10-29, after D-058 + latest phone UI pass)

Read this first if you are a new session or a different model picking up the work.
For background, also read `DECISIONS.md` (D-001 … D-058), `_contract/GAME_CONTRACT.md`, `_contract/GDD_WhiskerTales_v0.5.md` and `RELEASE_CHECKLIST.md`.

---

## 0. How to work with YK (owner)

- **YK writes in Thai** and drives one card at a time ("ต่อเลย", "ลุยโลด", "commit + push"). Reply in Thai and keep code and comments in English.
- **Current model preference (updated by YK):** use **GPT-6 Sol, medium effort** for routine continuation and polish. The project is already mature, so the more expensive model is not needed by default.
- **Build cadence:** do **not** build an APK after every edit. Build only when YK explicitly asks, after a useful review batch is ready.
- **Visual-work rule:** whenever a task creates or redesigns visual UI, buttons, frames, backgrounds, icons or decorative art, use the relevant image/visual skill to create a real asset and integrate that asset into the game. A code-only approximation or mockup-only delivery is not considered finished (D-057).
- **Commits:**
  - Commit and push straight to `main`. No branches, no PRs.
  - **Never commit `.claude/`.**
  - End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Keep this line unless the system reminder gives a different attribution.
- **Hard rules for the game:**
  - Ads are rewarded only.
  - Eggs are **never** sold for real money. D-053 allows transparent yarn + goldfish supply packs behind the parental gate; yarn's current random-knit rates must stay visible by the purchase list.
  - Kids/Families compliance always applies.
  - Do **not** use Legend of Mushroom code, data or numbers.
  - Android / Google Play only (D-017).
- **Downloads need YK's explicit OK.** ChatGPT image downloads were approved for art work.
  - Art prompts are pasted into ChatGPT fully assembled.
  - Use the existing chat "สร้างสไปรต์ชีตลูกแมว" (https://chatgpt.com/c/6ad47ce5-6c50-83ec-a950-67f91ff441ef). Do not open new chats.
- **When a card is done:**
  - Update its card with "ส่งงาน/ตรวจรับ" (delivery / sign-off) notes.
  - Map each AC to a test.
  - `git mv` the card to `_dispatch/done/`.
  - Add a D-### entry to `DECISIONS.md` (Thai, same style as the existing entries).

## 1. Repo map

| Path | What |
|---|---|
| `packages/wt_core/` | All game logic (pure Dart + Riverpod providers). Barrel `lib/wt_core.dart`. The app may import **only** the barrel (lint: `implementation_imports: error`). |
| `packages/wt_mode_story/` | Implemented Story Challenge mode: mode registration, run controller, tests and manifest. It is enabled from Adventure. |
| `app/` | Flutter app: `lib/main.dart` (boot), `lib/game_view.dart` (Flame scene + `GameDriver`), `lib/ui/*` (pages), `lib/ads/admob_network.dart`, `lib/audio/player_output.dart`, `lib/iap/`, `lib/cloud/`, `lib/l10n/*.arb`. |
| `design/data/*.json`, `design/balance/idle_balance_v1.json` | **Source of truth** for content and numbers. Never hard-code content (DoD). |
| `app/assets/content/` | Copy of `design/`, made by `bash tools/sync_content.sh`. A test fails if it is out of sync. |
| `assets/raw/` | Raw art: `sheets/`, sliced `frames/`, `backgrounds/`. |
| `app/assets/game/` | Shipped sprites, made by `python3 tools/sync_sprites.py`: 256 colours, backgrounds in WebP. |
| `app/assets/audio/` | Made by `python3 -I tools/audio/make_sounds.py`. |
| `tools/sprite_slicer/` | `slice_sheet.py` (magenta key, `--align feet/ground/center`) and `tile_background.py` (seamless parallax layer). |
| `tools/make_store_art.py` | Launcher icons, splash and Play graphics, all from Mochi's frames. |
| `scripts/build_release.sh` | Release build: AAB or `--apk`, plus `--arm64-only` and `--skip-tests`. |
| `_dispatch/{todo,review,done}/` | Task cards. Story cards T-005/006, T-010–020 and T-026 are currently in `review/`; T-021, T-028, T-032 and HOLD_T-047 remain in `todo/`. |

## 2. Status

**Group A (launch prep) is done on the code side. Story Challenge is implemented and enabled.** YK has repeatedly tested arm64 APKs on a real phone (Samsung SM-S948B, Android 17), and the current work includes those phone-feedback passes.

**Latest APK (includes D-054–D-058 and the native-width top-right resource tag):**

- Path: `app/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- Built: **2026-10-27 17:57:53 ICT**
- Size: **29,387,668 bytes** (~29.4 MB)
- SHA-256: `2ba6610383c6907f59b8a1e1cd8c43c00024f4360c18ae0663937745cb0e8de8`
- Build form: arm64 split APK (`android-arm64`). Keep this form for phone review: the earlier ~61 MB universal APK failed to install, while the ~29 MB arm64 build is the known-good delivery format.

| Decision | What |
|---|---|
| D-031 | Chapter 2–3 monsters, bosses, scenery |
| D-032 | `chapters.json`; owl library 23 nodes (new `bonus` effect) |
| D-033 | Real ads: Google AdMob (Families-safe, test IDs by default) |
| D-034 | Audio (synthesised in-house), 🎵/🔊 switches |
| D-035 | Store readiness: icon/splash, signing, `scripts/build_release.sh`, privacy policy draft, `RELEASE_CHECKLIST.md` |
| D-036 | Launch crash fixed (R8 removed Room's constructor → `proguard-rules.pro`); on-screen crash report for TEST builds only |
| D-037 | All UI icons are painted art (70 icons), `IconText`/`GameIcon`, coverage tests |
| D-038 | Phone-test round 1: knit pop fades out, new alternating walk frames (5 classes), HP bars, skill cooldown circles + names, Fail card, archer arrow, class emblems, words next to icons, pets no longer hidden |
| D-039 | Pets: tap for stats, passive + active skill per pet (historical 12.2-day balance, superseded by D-043) |
| D-040 | Home panel v2: gear shelf 2×4, two switches, animated yarn basket |
| D-041 | No welcome-back after a screenshot/ad (`AwayTracker`); characters smaller, monsters stay on screen |
| D-043 | Faster idle progression: book 1 target 3±1 calendar days at 3×15 min/day, higher yarn/egg drops and offline rewards, lower enemy growth after page 30 |
| D-044 | Live combat status icons: stun/frost/poison/burn above monsters; shield/war cry/shadow/eagle buffs above Mochi; poison stack count |
| D-045 | Borderless UI: buttons, cards, menus and dialogs use colour gradients and soft tinted shadows instead of outline frames |
| D-046 | RunManager + seeded 8–10-node Story maps, explicit safe/risky branches, cat snapshot, fail-forward reward, and 3 full daily runs then 25% |
| D-047 | Story content: 15 relics, 9 talents, 5 monsters + paper-wolf boss, 8 two-choice events, 4 potions, validated balance/XP data |
| D-049 | Story Challenge enabled with complete run UI, map/cards/events/shop/campfire/results and integration coverage |
| D-050 | Early bosses 65% lighter through page 30, smoothly regain full power through page 120; book 1 target 2±1 days |
| D-051 | Speed control moved beside the top-right wallet; Story Run keeps Mochi visible and animates both combat actors |
| D-052 | Story HUD uses live combat HP/shield; shop healing updates immediately and unusable or sold potion slots cannot spend goldfish |
| D-053 | Unified Shop: fish/yarn reward ads 2× each daily; six repeatable supply packs ($0.99–$99.99 reference tiers); no-ads buyers claim both daily gifts without video; consumable transaction ids prevent duplicate grants |
| D-054 | Storybook UI v2: warm asymmetric paper surfaces, distinct action buttons, compact resource tags, one shared bottom dock and shared Cat tab rail; submenu polish continues on this system |
| D-055 | Cat submenus v2: hero/stat board, shared wardrobe rail, focused hatch station, rarity-tinted pets and effect-tinted research rows replace equal-weight card grids |
| D-056 | All remaining submenus v2: Adventure/Story panels, Shop/Events, age selection, knit sheet, offline/fail overlays and parental purchase flow now share the parchment hierarchy and action surfaces |
| D-057 | Asset-first UI rule: new visual designs must be generated as real game assets; Home HUD/actions and the shared dock now use the painted six-piece storybook kit instead of code-only rounded cards |
| D-058 | Phone layout correction: painted assets now have explicit live-content safe zones; profile, wallet, chapter, farm controls, basket label and shared dock no longer overlap or fall off-screen |

Verification commands are in §6. After D-058: app tests 57/57 and analyze are green. Core/story counts from D-049 remain wt_core 335/335 and story 9/9. D-050 headless verification reaches book 1 in 1.0–1.5 days and page 120 in 3.0–4.0 days across four classes with the scripted idle profile; boss losses fall from the 218–523 baseline to 0–33.

### 2a. Latest phone-feedback state

- The Home screen now uses real painted storybook assets for the profile, resource wallet, chapter/action labels and shared bottom navigation, rather than generic rounded Flutter cards.
- The first asset pass looked crowded on the real phone (`104209.jpg`). The live-content safe zones were corrected: profile text no longer collides with the level medallion, resource counts reserve space for the plus button, lower action text is constrained inside its stitched area, the basket label stays inside the lower panel, and bottom labels are lifted away from the screen edge.
- The top-right Goldfish/Yarn/Egg art was visibly stretched because a 600×260 atlas crop was being forced into a very wide box. It was replaced by a **native wide 960×209 asset** (4.59:1) displayed at about 4.68:1, so the parchment, leaves and plus button keep their intended proportions.
- The source of the six-piece painted kit is `assets/raw/ui/ui_storybook_kit.png`. The separately generated native-width resource tag is `assets/raw/ui/ui_currency_tag_wide.png`.
- `tools/sync_sprites.py` crops/optimizes these sources and writes `app/assets/game/ui/ui_frame_*.png`; it also removes low-alpha specks before cropping the wide currency tag. Do not hand-edit the shipped derivatives.
- After the latest layout and resource-tag correction: `flutter analyze` passed and app tests passed **57/57**, including updated Thai/English goldens.

### 2b. Product and gameplay changes already completed in this workstream

- Early progression was shortened for realistic idle play (not 24-hour active play): higher yarn/egg and offline rewards, lighter early scaling, and much weaker early bosses. Difficulty ramps later and additional stages/pages can reuse content while scaling upward.
- Auto-knit remains enabled when yarn reaches zero; it waits and automatically resumes when yarn arrives. The control uses the mouse/knitting-basket visual treatment.
- Warrior attack art was corrected so sword and shield are assigned to the intended hands and the shield follows the attacking arm/pose correctly.
- Combat status effects are functional and visible: stun, frost, poison, burn above monsters; shield, war cry, shadow and eagle buffs above the player; poison shows stacks.
- Skill and Library research names now have descriptions explaining their effects.
- Story/Adventure combat now shows Mochi, enemies and combat animation rather than only scenery/options. Its HUD uses live HP/shield, and purchases cannot spend fish without applying their stat/heal effect.
- The speed control was moved away from the overflowing skill wheel to the top-right wallet area.
- Shop owns rewarded fish/yarn gifts (2 claims per item per day) and the $0.99–$99.99 supply-pack structure. Purchases are parental-gated, consumable grants are transaction-idempotent, and Ad-free Story preserves daily gift claims without video.
- Defeat copy addresses the player as **You / คุณ**, not “Mochi”, because the profile name is intended to become player-editable.
- All main and submenu UI received the Storybook v2 hierarchy pass; D-057 supersedes any remaining code-only visual approximation whenever those screens are redesigned again.

## 3. What only YK can do (all listed in `RELEASE_CHECKLIST.md`)

1. Confirm the package name `com.whiskertales.whisker_tales`. It is permanent after the first upload.
2. Create the upload keystore and `app/android/key.properties`.
3. Set up AdMob: create the app and a rewarded unit, then set `admobAppId` and `ADMOB_REWARDED_ID`. Mark the app child-directed and set max rating G.
4. Play Console:
   - Create the seven in-app products listed in `RELEASE_CHECKLIST.md`: six consumable supply packs plus non-consumable `supporter_pack`.
   - Set up license testers.
   - Optionally add the Play Games Services project ID (`pgsProjectId`).
5. Fill `{{DEVELOPER}}`, `{{CONTACT_EMAIL}}` and `{{DATE}}` in `docs/privacy/index.html`, then host it (GitHub Pages `/docs` works).
6. Take 2–8 phone screenshots. The goldens use a test font, so they can't be used.
7. Fill in the Play Console forms. Prepared answers are in checklist §4 and §5.
8. Optional: allow Flutter's quarantined AOT compilers on this Mac so a full multi-ABI AAB can build (checklist §3). This is a machine-security decision. **Do not remove the quarantine flag yourself.**

## 4. Known gaps / never verified

- **Do before Play:** remove the test crash screen (`WtApp.java`, `CrashActivity.java`, manifest `android:name=".WtApp"` + the `.CrashActivity` entry — see RELEASE_CHECKLIST §3) or replace it with a friendly message.
- **Purple art may be washed out:** the magenta key desaturated saturated purples (found on icons, fixed there with `--spill-start 110`). Gear set 2 (blue–purple) and other purple sprites were **not checked**; re-slice them with the higher value if they look grey.
- **Still not fully verified end-to-end on a phone:** rewarded-ad completion, audio feel, real Supporter Pack / supply-pack billing, sustained 60 fps and cloud-save conflict/restore. The surrounding screens have been phone-reviewed, but these external/runtime flows still need explicit checks.
- If Android kills the app often after short backgrounding, memory use is high (Flame image cache); measure later. (`reason=3` in the crash screen was a normal background kill, now filtered.)
- EEA/UK: AdMob may need a UMP consent form even for non-personalized ads (not needed if the first release is Thailand only).
- T-041: Android system notification for "research done" while the app is closed → v1.1.
- Balance is a set of ASSUMPTIONs; re-run `flutter test tool/headless_player_test.dart` (in `packages/wt_core`) after any power change. Both targets must PASS. The test now fails when a target fails. To check continuation, use `--dart-define=TARGET_PAGES=120 --dart-define=SEEDS=1`; D-050 passed page 120 for all classes, but later books still reuse book 1 art and monsters while their power continues to scale.

## 5. Group B (Story Challenge mode) — IMPLEMENTED, ENABLED, AWAITING PRODUCT REVIEW

**The old “dormant / undecided for v1.0” note is obsolete.** YK decided on 2026-10-25 that Story Challenge ships enabled in the current build (D-049). The implementation is present and reviewable from Adventure.

**Chunk 2 (T-005 + T-006) is implemented and awaiting review.** D-046 settles the contract gaps: explicit route choices, a cat snapshot, mode-owned win conditions, daily reward count in StorySave, and `design/data/story/*.json` as the future content source. The paper-wolf boss power tuning remains with T-028; Story reward numbers are provisional until T-026.

**Chunk 3 (T-026) is implemented and awaiting review.** `StoryContent` validates the full roster from `design/data/story/`; reward and XP rules are data-driven; the map draws real monster/event ids and ends at `paperwolf`. Story panels currently show their mapped game icons; if any of these visuals are redesigned, follow D-057 and generate/integrate final painted assets rather than replacing them with generic code shapes.

**Chunk 4 (T-010 + T-011) is implemented and awaiting review.** `ItemSystem` resolves all relic and active-combo effects from Story data into `IBuffEngine`; chance rolls use the run's seeded RNG. `SynergyResolver` emits newly activated pairs and drops them immediately when either relic is removed. Synergy entries now carry their own trigger and target so instant effects happen at the correct combat event.

**Chunk 5 (T-012 + T-013) is implemented and awaiting review.** `TalentSystem` reads its XP curve and all nine talents from Story JSON, emits every crossed level, keeps seeded three-card offers stable until selection and guarantees the favored tree after two picks. Talent and electric-fur × Magic tier-3 effects share the ItemSystem effect resolver and route through `IBuffEngine`. Core verification: 335 tests passed and `flutter analyze` returned 0 issues.

**Chunk 6 / T-014–T-020 is implemented and awaiting review (D-049).** Story Challenge now ships `enabled:true`, unlocked after the idle chapter-1 boss. The Adventure menu comes from `ModeRegistry`; the 60/40 run screen covers map, automatic combat cooldowns, HUD/statuses, Relic/Talent two-tap cards, events, confirmed shop purchases, campfire and result/return. Golden tests cover every panel, map states, low HP with eight relics and the unlocked Adventure page. A 50-seed controller run reaches every panel and finishes; the app integration test covers app → Adventure → run → return. Story tests: 9, app tests: 54, analyze: 0 issues.

Original plan (chunk 1 done):

YK decided on 2026-10-25 that Story Challenge ships enabled in the current build (D-049).

Cards and their order (≈ 8 work chunks):

1. T-031 — mode framework / ModeRegistry
2. T-005 + T-006 — RunManager, encounter generator
3. T-026 — content: relic 15 / talent 9 / events / monsters
4. T-010 + T-011 — relics + synergy
5. T-012 + T-013 — talents
6. T-016 + T-018 + T-019 — map, card-pick, event/shop/campfire panels. T-014, T-015 and T-017 mostly overlap the existing T-042 shell; fold them in.
7. T-028 — giant paper wolf boss. The paper wolf sprites already exist.
8. T-020 — adventure entry on the home/menu. T-021 meta-progression is largely superseded; re-read it before starting.

Not for v1.0: T-032 (endless, P2) and HOLD_T-047 (dungeon, v1.1).

## 5b. Icons (D-037) — how to add or redo one

All UI icons are painted art, not emoji. To add an icon: draw it (sheet prompt style in `design/art/icon_prompts.md`; same ChatGPT chat; send the prompt by JS `document.execCommand('insertText')` into the composer — typing with newlines sends the message early) → save as `assets/raw/sheets/<sheet>.png` and list the ids in `design/art/icon_sheets.json` → `python3 -I tools/slice_icon_sheet.py <sheet>` → `python3 tools/sync_sprites.py` → map the emoji in `design/art/icons.json` (or add to `keep_as_text`) → `bash tools/sync_content.sh`. Draw with `IconText` / `GameIcon`, never `Text` with an emoji or `Icons.*` (tests fail). Purple art needs the slicer's `--spill-start 110`, already set in `slice_icon_sheet.py`.

## 5c. Downloading from ChatGPT safely, walk frames

- The image viewer shows an **intermediate** image while ChatGPT is still refining ("Worked for …", stop button visible). Wait until the stop button is gone, then open the final image and download.
- **Never** take `ls -t ~/Downloads | head -1`: on 2026-10-23 that moved YK's own file into the repo (put back unchanged, nothing sent). Take the file by the exact new name with a fresh mtime. `fix_walk.py` and `slice_icon_sheet.py` now refuse a sheet whose border is not magenta.
- Walk frames: `python3 -I tools/fix_walk.py <class> assets/raw/sheets/sheet_walk_<class>.png` replaces `assets/raw/frames/outfit/<class>/walk_f1..3.png`, then `python3 tools/sync_sprites.py`. The prompt that works describes pose 3 anatomically (far leg forward, near leg bent behind with the heel up); the vaguer "other leg forward" wording was ignored.
- Sending a prompt: insert the text with `execCommand('insertText')`, then press Return in the composer (the blue send button click can miss).

## 6. Commands

```bash
# verify everything (run before every commit that touches code)
cd packages/wt_core && flutter analyze && flutter test
cd app && flutter analyze && flutter test
# after editing design/*.json
bash tools/sync_content.sh
# after new raw art
python3 tools/sync_sprites.py
# goldens changed on purpose (look at test/failures/*.png first!)
cd app && flutter test --update-goldens test/panels_golden_test.dart
# phone build for YK (send with SendUserFile, must stay < 31,457,280 bytes)
cd app && flutter build apk --release --split-per-abi --target-platform android-arm64
# Play bundle (this Mac: arm64 only until YK allows the other compilers)
scripts/build_release.sh --arm64-only
```

## 7. Machine notes (8 GB Mac)

- `app/android/gradle.properties` is set to a 3 GB heap with one worker. Before this it was 8 GB, which caused out-of-memory and hangs.
- If the AOT build is killed with exit 137, close Chrome and build arm64 only.
- A build that hangs with 0 % CPU and `gen_snapshot` stuck in `_dyld_start` means macOS quarantine, not a bug. See §3 item 8.
- Python scripts that read downloaded or generated files run with `python3 -I`.

## 8. Current worktree and safest next steps

- The worktree is intentionally **very dirty**: it contains the whole Story implementation, balance changes, combat/status fixes, shop/IAP refactor, generated UI art, localization changes and updated goldens. These changes belong to the current project work. Do not reset, clean, checkout over, or delete unrelated files.
- `.claude/` is untracked and must never be committed.
- Old build artifacts may still exist in `app/build/app/outputs/flutter-apk/`, including a ~63.9 MB universal APK and other ABI splits. **Only deliver `app-arm64-v8a-release.apk`** for YK's current Samsung phone unless he explicitly requests another format.
- Current review queue: T-005, T-006, T-010–T-020 and T-026. Remaining todo: T-021 meta progression, T-028 paper-wolf boss, T-032 endless slice and HOLD_T-047 dungeon (v1.1).
- The next practical product-review pass should focus on the real phone at common narrow widths: Home top HUD proportions, lower basket/actions, bottom dock labels, Adventure live HP/stat purchases, rewarded-ad daily limits and purchase restoration.
- Before changing balance, rerun the headless progression test. Before changing generated art, edit the raw source/pipeline and resync. Before handing off a new APK, run app analyze/tests and build the arm64 split only.
