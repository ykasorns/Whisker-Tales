# UI kit v3, round 4: glyph icons (D-069)

Why: after rounds 1 to 3 every screen uses the painted kit, but a few UI symbols are still typed characters. They draw in the system font (not the storybook style), and some show as an empty box in the real-font goldens (for example `→` in the Owl Library line "Quick Paws → Lv.7"). This round paints them as icons so `IconText` can swap them like the other emoji (D-037).

| # | id | replaces | where it shows |
|---|---|---|---|
| 1 | `ui_arrow_next` | `→` | Library upgrade line, craft compare arrow, frames, buff text |
| 2 | `ui_stat_up` | `▲` | Craft compare and overlays: stat goes up |
| 3 | `ui_stat_down` | `▼` | Craft compare and overlays: stat goes down |
| 4 | `ui_key_backspace` | `⌫` | Grown-ups gate keypad (shop) |
| 5 | `ui_sparkle` | `✦` | Craft sheet highlight |

## Output

One sheet: `assets/raw/ui_v3/sheets/sheet_icons_9_glyphs.png`, exactly 1500 x 900 px, 5 columns x 3 rows, each cell 300 x 300 px. Cells 1 to 5 (top row) hold the icons in the order above. Cells 6 to 15 stay plain magenta.

## Prompt (send as one generation, attach `assets/raw/sheets/sheet_icons_2_ui.png` and `assets/raw/sheets/sheet_icons_8_stats_2.png` as style references)

STYLE: the same hand-painted colored-pencil storybook style as the reference images: bold dark ink outlines (#33291F), vibrant saturated colored pencil strokes clearly visible at a diagonal angle, a single flat shadow tone, bright playful palette limited to warm orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, shadow plum #7A5E8C and cream #F6F0E1, no digital gradients, no airbrush, child-friendly. Each icon is a CHUNKY, SIMPLE, instantly readable game icon with a thick outline and ONE clear silhouette that stays recognisable when shrunk to 20 pixels; avoid tiny details.

SHEET LAYOUT: a clean icon sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. An invisible grid of 5 columns by 3 rows, every cell exactly the same size. Only the five cells of the top row hold an icon, one per cell, centered, every icon the same visual size (about 60% of the cell), with wide empty magenta padding so nothing touches another cell. The middle and bottom rows are empty magenta. No text, no letters, no numbers, no labels, no grid lines, no borders, no floor, no cast shadows.

ICONS, top row left to right:
1. a short fat teal arrow pointing right, rounded tip and tail, like a painted wooden sign arrow
2. a lime green rounded triangle pointing up (stat goes up), soft rounded corners
3. a coral rounded triangle pointing down (stat goes down), same shape as icon 2 flipped
4. a cream keyboard key shaped like a pentagon pointing left, with a small coral cross on its face (delete key)
5. a sun yellow four-pointed sparkle star with slightly curved points

## Checks before delivery

- Size exactly 1500 x 900, RGB, background exactly #FF00FF outside the icons.
- Each icon stays inside its 300 x 300 cell with at least 45 px (15%) magenta padding.
- No stray fragments, no magenta fringe inside icons, rows 2 and 3 fully magenta.
- Append a short "Round 4 audit" to `assets/raw/ui_v3/DELIVERY.md`.

## Scope

Write only `assets/raw/ui_v3/sheets/sheet_icons_9_glyphs.png` and the DELIVERY.md append. Do not touch `app/`, `tools/`, `design/` (except reading), other art folders, git, or builds. Wiring (slicing, `icons.json`, tests) is Claude's job afterwards.
