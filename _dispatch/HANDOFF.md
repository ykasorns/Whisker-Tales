# HANDOFF — Whisker Tales (updated 2026-10-23, after D-042)

Read this first if you are a new session or a different model picking up the work.
For background, also read `DECISIONS.md` (D-001 … D-042), `_contract/GAME_CONTRACT.md`, `_contract/GDD_WhiskerTales_v0.5.md` and `RELEASE_CHECKLIST.md`.

---

## 0. How to work with YK (owner)

- **YK writes in Thai** and drives one card at a time ("ต่อเลย", "ลุยโลด", "commit + push"). Reply in Thai and keep code and comments in English.
- **Model setup YK asked for (2026-10-23):**
  - The work runs on **Sonnet at medium effort**. YK picks this in the app's model menu, because a session cannot switch its own model.
  - **Opus is the advisor.** Call `advisor()` before anything that needs planning or tricky logic: a new card, a design decision, balance, a save format, compliance, or an unclear bug. Call it again before saying a card is done.
  - Routine edits, tests and commits do not need the advisor.
  - Reason: token cost.
- **Commits:**
  - Commit and push straight to `main`. No branches, no PRs.
  - **Never commit `.claude/`.**
  - End every commit message with `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Keep this line unless the system reminder gives a different attribution.
- **Hard rules for the game:**
  - Ads are rewarded only.
  - Yarn, eggs and goldfish are **never** sold for real money.
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
| `packages/wt_mode_story/` | Empty placeholder for group B (story challenge mode). |
| `app/` | Flutter app: `lib/main.dart` (boot), `lib/game_view.dart` (Flame scene + `GameDriver`), `lib/ui/*` (pages), `lib/ads/admob_network.dart`, `lib/audio/player_output.dart`, `lib/iap/`, `lib/cloud/`, `lib/l10n/*.arb`. |
| `design/data/*.json`, `design/balance/idle_balance_v1.json` | **Source of truth** for content and numbers. Never hard-code content (DoD). |
| `app/assets/content/` | Copy of `design/`, made by `bash tools/sync_content.sh`. A test fails if it is out of sync. |
| `assets/raw/` | Raw art: `sheets/`, sliced `frames/`, `backgrounds/`. |
| `app/assets/game/` | Shipped sprites, made by `python3 tools/sync_sprites.py`: 256 colours, backgrounds in WebP. |
| `app/assets/audio/` | Made by `python3 -I tools/audio/make_sounds.py`. |
| `tools/sprite_slicer/` | `slice_sheet.py` (magenta key, `--align feet/ground/center`) and `tile_background.py` (seamless parallax layer). |
| `tools/make_store_art.py` | Launcher icons, splash and Play graphics, all from Mochi's frames. |
| `scripts/build_release.sh` | Release build: AAB or `--apk`, plus `--arm64-only` and `--skip-tests`. |
| `_dispatch/{todo,done}/` | Task cards. `review/` is empty now. |

## 2. Status

**Group A (launch prep) is done on the code side**, and since then YK tested on a real phone (Samsung SM-S948B, Android 17) and everything below was built from his feedback. Latest APK arm64 ≈ 28.1 MB (send limit 31,457,280). Tests: wt_core 295, app 43, `flutter analyze` clean in both.

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
| D-039 | Pets: tap for stats, passive + active skill per pet (balance: book 1 = day 12.2, lower bound of the 14±2 target is 12) |
| D-040 | Home panel v2: gear shelf 2×4, two switches, animated yarn basket |
| D-041 | No welcome-back after a screenshot/ad (`AwayTracker`); characters smaller, monsters stay on screen |

Verification commands are in §6; the last full run before this note was green.

## 3. What only YK can do (all listed in `RELEASE_CHECKLIST.md`)

1. Confirm the package name `com.whiskertales.whisker_tales`. It is permanent after the first upload.
2. Create the upload keystore and `app/android/key.properties`.
3. Set up AdMob: create the app and a rewarded unit, then set `admobAppId` and `ADMOB_REWARDED_ID`. Mark the app child-directed and set max rating G.
4. Play Console:
   - Create the `supporter_pack` in-app product.
   - Set up license testers.
   - Optionally add the Play Games Services project ID (`pgsProjectId`).
5. Fill `{{DEVELOPER}}`, `{{CONTACT_EMAIL}}` and `{{DATE}}` in `docs/privacy/index.html`, then host it (GitHub Pages `/docs` works).
6. Take 2–8 phone screenshots. The goldens use a test font, so they can't be used.
7. Fill in the Play Console forms. Prepared answers are in checklist §4 and §5.
8. Optional: allow Flutter's quarantined AOT compilers on this Mac so a full multi-ABI AAB can build (checklist §3). This is a machine-security decision. **Do not remove the quarantine flag yourself.**

## 4. Known gaps / never verified

- **Do before Play:** remove the test crash screen (`WtApp.java`, `CrashActivity.java`, manifest `android:name=".WtApp"` + the `.CrashActivity` entry — see RELEASE_CHECKLIST §3) or replace it with a friendly message.
- **Purple art may be washed out:** the magenta key desaturated saturated purples (found on icons, fixed there with `--spill-start 110`). Gear set 2 (blue–purple) and other purple sprites were **not checked**; re-slice them with the higher value if they look grey.
- **Not yet tried on a phone** (YK tests from APKs): ads (test ads only), audio feel, the Supporter Pack purchase, 60 fps, cloud save, the newest D-039/D-040/D-041 changes (pet skill circles, yarn basket animation, smaller characters).
- If Android kills the app often after short backgrounding, memory use is high (Flame image cache); measure later. (`reason=3` in the crash screen was a normal background kill, now filtered.)
- EEA/UK: AdMob may need a UMP consent form even for non-personalized ads (not needed if the first release is Thailand only).
- T-041: Android system notification for "research done" while the app is closed → v1.1.
- Balance is a set of ASSUMPTIONs; re-run `flutter test tool/headless_player_test.dart` (in `packages/wt_core`) after any power change. Both targets must PASS.

## 5. Group B (story challenge mode) — IN PROGRESS (D-042)

**Chunk 1 (T-031) is done and in `_dispatch/done/`**: `ModeRegistry`, `ModeSaves`, `wt_core_testing.dart` conformance checks, `wt_mode_story` skeleton (dormant, `enabled:false`). YK ordered Group B built, but has **not** decided whether v1.0 includes it (recommendation: v1.1). Ask in one line.

**Next = chunk 2 (T-005 + T-006).** First settle the 6 contract gaps listed at the end of `_dispatch/done/T-031_mode_framework.md` (branching choice, cat snapshot into the mode, boss AC without dodge, 3 full runs/day then 25%, one content location, balance 12.2 days). Call `advisor()` before changing any interface, and log a D-entry. Commit per chunk only when YK asks.

Original plan (chunk 1 done):

GDD v0.5 §6/§8 keeps "ท้าทายนิทาน" (story challenge) in MVP, but YK has **not** yet decided whether v1.0 ships with it or with a locked "เร็ว ๆ นี้" ("coming soon") button.

The recommendation was to launch Group A first and do Group B for v1.1. Ask YK before starting, and log a D-### entry if it moves.

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
