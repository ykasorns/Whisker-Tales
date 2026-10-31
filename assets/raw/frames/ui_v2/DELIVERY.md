# Whisker Tales UI Frames v2 — Delivery

Generated with the built-in ImageGen workflow on 2026-10-31. All production PNGs use real alpha and are stored only in this `ui_v2` delivery folder. The existing v1 art and application code were not changed.

## Frame measurements

Coordinates use `[x1, y1, x2, y2]` in final-file pixels. Content rectangles are conservative fully readable areas inside the hand-painted cream surfaces.

| File | Real size | cap_l | cap_r | Content rect | Extra rects |
|---|---:|---:|---:|---|---|
| `ui_frame_profile_v2.png` | 620×320 | 275 | 40 | `[346,117,551,227]` | medallion safe area `[83,80,272,244]` |
| `ui_frame_currency_v2.png` | 960×209 | 40 | 175 | `[50,66,730,151]` | empty button circle `[785,17,955,198]` |
| `ui_frame_chapter_v2.png` | 561×251 | 105 | 85 | `[113,57,452,206]` | — |
| `ui_frame_action_v2.png` | 590×254 | 92 | 90 | `[121,41,477,216]` | — |
| `ui_frame_nav_dock_v2.png` | 891×275 | 65 | 75 | `[55,89,841,175]` | slots listed below |
| `ui_frame_nav_selected_v2.png` | 309×348 | 0 | 0 | `[54,34,255,215]` | safe icon area before the swallow tail |
| `ui_badge_cooldown_v2.png` | 128×128 | 0 | 0 | `[28,26,100,101]` | empty number area |
| `ui_label_plate_v2.png` | 240×96 | 30 | 30 | `[34,16,207,81]` | — |

Dock slot paper rectangles, measured from the final painted file:

1. `[55,89,175,175]`
2. `[218,89,340,175]`
3. `[387,91,510,174]`
4. `[555,90,676,174]`
5. `[722,90,841,174]`

## Dock icons

| File | Real size | Alpha | Notes |
|---|---:|---|---|
| `ui_dock_icons_v2/nav_character.png` | 192×192 | yes | Orange cat head with teal hat |
| `ui_dock_icons_v2/nav_adventure.png` | 192×192 | yes | Open illustrated map book |
| `ui_dock_icons_v2/nav_home.png` | 192×192 | yes | Cozy house |
| `ui_dock_icons_v2/nav_events.png` | 192×192 | yes | Wrapped gift |
| `ui_dock_icons_v2/nav_shop.png` | 192×192 | yes | Woven basket with teal lining |

## Prompt set used

The source brief was `design/art/ui_frames_v2_prompt.md`. It was normalized into one built-in ImageGen prompt per requested asset:

- Frames: calm Whisker Tales storybook wood and cream paper, exact target aspect/cap proportions, transparent background, large clean live-content area, no text, leaves, vines, flowers, knobs, outside shadow or glow.
- Profile: empty left medallion and compact right name/XP strip.
- Currency: very wide paper strip and an empty circular right button with no plus sign.
- Chapter: compact flat ribbon ends and clean central paper.
- Action and label: rounded slim wooden rims with quiet cream faces.
- Dock: exactly five equal paper slots, thin dividers and no corner decoration.
- Selected tab: plain soft-teal cloth bookmark with a swallow-tail bottom.
- Cooldown: empty cream disc with a slim wooden ring, readable at 28 dp.
- Icons: one large bold subject per 192×192 transparent square, matching the storybook outline and palette, with no text or surrounding frame.

## Review notes / deviations

- Every requested production file has the exact specified pixel dimensions and real PNG alpha.
- The profile's painted cream medallion is intentionally larger than the nominal 106×86 live-number area; the measured safe medallion rect above is the area intended for overlay content.
- The dock art occupies approximately y=67–199 inside the 275 px canvas. Transparent space above and below keeps the five paper slots around y=84–181 and leaves room for the selected bookmark and labels.
- Hand-painted dock slot edges vary by 1–3 px. The conservative slot rectangles above are measured individually rather than estimated.
- The stretchable middles contain no discrete decoration, knot, nail or icon. They retain only extremely subtle painterly paper/wood variation to avoid a visibly synthetic flat strip.
- No existing v1 art, Dart code, frame JSON, decisions, handoff, tools or APK files were changed.
