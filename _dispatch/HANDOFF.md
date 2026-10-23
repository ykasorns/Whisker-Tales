# HANDOFF — Whisker Tales (2026-10-23)

Read this first if you are a new session or a different model picking up the work.
For background, also read `DECISIONS.md` (D-001 … D-035), `_contract/GAME_CONTRACT.md`, `_contract/GDD_WhiskerTales_v0.5.md` and `RELEASE_CHECKLIST.md`.

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

## 2. Status: Group A (launch prep) is done on the code side

| Item | Commit | Decision |
|---|---|---|
| A5: 24 review cards signed off (AC → test evidence), T-009 deleted | 4605c3e | — |
| A4: T-043 content. `chapters.json` drives monsters, bosses and scenery per chapter. Owl library 5 → 23 nodes (new `bonus` effect = secondary stat per level). Balance re-tuned on the headless player: book 1 = **day 13.0** (target 14±2), no-ads +9.3%. | f4a693f, 2ffb57b | D-032 |
| A1: real ads with **Google AdMob** (Families self-certified). Rated G, child treatment under 13 or when age is unknown, never personalized. AD_ID and Privacy Sandbox permissions removed. Test IDs are the defaults. | 675c66e, f51cc9e | D-033 |
| A3: T-024 audio. Synthesised in-house; farm/boss music crossfade, 9 SFX, 🎵/🔊 switches on the shop page, saved in settings. | 3b38915 | D-034 |
| A2: T-030 store readiness. Icon (adaptive + themed), splash, signing via `key.properties`, release script, privacy policy TH/EN draft, `RELEASE_CHECKLIST.md`. | b2146ba, f51cc9e | D-035 |
| Chapter 2–3 art (monsters, bosses, faces, backgrounds) | 8ad896f | D-031 |

- Latest builds:
  - APK arm64: 27.2 MB (the 30 MB send-to-YK limit is 31,457,280 bytes)
  - AAB arm64: 30.8 MB
- Tests: wt_core 291 and app 21, all green. `flutter analyze` reports 0 issues in both packages.

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

- **Nothing has run on a real device or emulator.** This Mac has no emulator, and only about 12 GB of disk is free.
- Untested on device:
  - AdMob test ads
  - Audio levels and feel
  - The icon and splash on a launcher
  - 60 fps (T-027)
  - The purchase flow
  - Cloud save
- YK will test these from the APK (checklist §6).
- **EEA/UK:** AdMob may need a UMP consent form even for non-personalized ads. It is not needed if the game launches in Thailand only. Build it if YK opens the EEA (D-033).
- T-041: an Android system notification for "research done" while the app is closed is deferred to v1.1. In-game notice only for now.
- `MobileAdsInitProvider` (Google's) still loads at app launch. We delay measurement and only init and request on the first ad.
- Research `bonus` values are ASSUMPTION. Tune in playtest with `cd packages/wt_core && flutter test tool/headless_player_test.dart`, which writes `tools/balance_sim/headless_report.txt`. Both targets must PASS.

## 5. Next: Group B (story challenge mode), still in todo

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
