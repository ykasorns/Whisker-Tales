# GPT task — Story Run art pack (characters + cards) for Whisker Tales

Generate **image assets** only. Read the whole file first. Do not edit Dart code, JSON or docs; Claude will wire the art in. Reply to YK in Thai; file names and notes inside files in English.

## Why
The Story Run (Adventure tab) now has a story: a little thread-spool sprite **Bobbin** rides on Mochi's scarf and meets a small recurring cast along the way (see `design/data/story/events.json`, keys `cast`, `narrative`, `events[*].story_en`). The text works, but the screen has no faces for the speakers and the pick/shop cards are flat. Rule D-057: new designs must be real generated artwork.

## Style
Same as the current game: pencil-and-crayon storybook look, warm palette, soft dark-brown outline (match `app/assets/game/mon/*` and `app/assets/game/cat/*`). Kid-safe, friendly, no text or letters inside the images, transparent background (real alpha, PNG-32), no drop shadow or glow outside the art. Original characters only — nothing from other games.

## 1. Speaker portraits (6) — 256×256, head-and-shoulders, facing slightly right
Save to `assets/raw/frames/story_v1/portraits/`:
| File | Who |
|---|---|
| `portrait_bobbin.png` | Bobbin: a tiny spool of teal thread with two big eyes, a little thread tail curling like a tail, cheerful and a bit cheeky |
| `portrait_hoot.png` | Professor Hoot: a round owl in tiny round glasses and a scholar's cap, sleepy-wise |
| `portrait_pip.png` | Pip: a small grey mouse holding an upside-down wooden sign, worried but sweet |
| `portrait_crumb.png` | Mrs. Crumb: a plump hedgehog baker with a flour-dusted apron and a chef's hat |
| `portrait_inkie.png` | Inkie: a friendly dancing puddle of dark-blue ink with a smiling face and a little arrow shape on top |
| `portrait_chesty.png` | Chesty: a small wooden treasure chest with a mischievous grin, a tiny tongue, and tiny teeth along the lid |

## 2. Card frames (3) — painted paper cards for relic / talent / shop picks
Calm style like the v2 UI frames in `assets/raw/frames/ui_v2/` (slim honey-wood rim, flat clean cream paper face, no leaves/vines). Portrait orientation, **200×280**, real alpha, tight crop. For each give the paper-face rectangle `[x1,y1,x2,y2]` measured on the final file.
- `card_pick.png` (cream face), `card_pick_selected.png` (same shape, warmer gold rim to show "tapped once"), `card_shop.png` (same shape with a small empty tag notch at the bottom for a price).
Save to `assets/raw/frames/story_v1/cards/`.

## 3. Combat hit sparks (4) — 128×128 transparent
`fx_hit_white.png` (a quick white crayon starburst), `fx_hit_crit.png` (bigger gold starburst with a few star shards), `fx_hit_hurt.png` (small coral-red puff for when Mochi is hit), `fx_dust.png` (a soft puff of dust for footsteps). Save to `assets/raw/frames/story_v1/fx/`.

## Delivery
Put everything under `/Users/kolupy/whisker_tales/assets/raw/frames/story_v1/` (create it). Do not write anywhere else, do not commit, do not build an APK. Also save `preview_sheet.png` (all pieces on mid-grey, labels outside the artwork) and `DELIVERY.md` with each file's real pixel size and the measured rectangles. Check with `ls -R` that all 17 PNGs exist.
