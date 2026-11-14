# UI Kit v3 Delivery

Generated from `design/art/ui_kit_v3_prompt.md` on 2026-11-13.

## Summary

- Widgets: 42/42 PNG files, 412,289 bytes total (about 403 KB; below the 600 KB kit budget).
- Widget checks: exact size, transparent border, no magenta fringe, and all requested 3-slice/9-slice middle checks pass.
- Icon sheets: 2/2, exact 5 x 3 equal-cell layout at 1500 x 900 px. Each cell is 300 x 300 px and every icon has at least 45 px (15%) padding.
- Preview: 1080 x 1920 px, showing the new kit beside the existing style anchors.
- No Dart, JSON, app assets, or existing art folders were changed.

## Files

| File | Measured size | Check | Notes |
|---|---:|---|---|
| `widgets/ui_panel_card.png` | 256 x 256 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_panel_tile.png` | 128 x 128 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_panel_dialog.png` | 384 x 384 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_panel_sheet.png` | 512 x 256 | PASS | RGBA; asymmetric 9-slice row/column step 0.00 |
| `widgets/ui_sheet_grabber.png` | 128 x 32 | PASS | RGBA; fixed asset |
| `widgets/ui_panel_inset.png` | 256 x 128 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_tab_strip.png` | 768 x 128 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_tab_on.png` | 256 x 128 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_tab_off.png` | 256 x 128 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_green.png` | 480 x 160 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_yellow.png` | 480 x 160 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_purple.png` | 480 x 160 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_coral.png` | 480 x 160 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_disabled.png` | 480 x 160 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_btn_round_red.png` | 160 x 160 | PASS | RGBA; fixed asset |
| `widgets/ui_btn_round_cream.png` | 160 x 160 | PASS | RGBA; fixed asset |
| `widgets/ui_toggle_track_off.png` | 192 x 96 | PASS | RGBA; fixed asset |
| `widgets/ui_toggle_track_on.png` | 192 x 96 | PASS | RGBA; fixed asset |
| `widgets/ui_toggle_knob.png` | 80 x 80 | PASS | RGBA; fixed asset |
| `widgets/ui_bar_track.png` | 480 x 64 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_bar_fill_green.png` | 480 x 48 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_bar_fill_teal.png` | 480 x 48 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_bar_fill_coral.png` | 480 x 48 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_bar_fill_sun.png` | 480 x 48 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_slot_empty.png` | 160 x 160 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_slot_filled.png` | 160 x 160 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_slot_selected.png` | 160 x 160 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_slot_locked.png` | 160 x 160 | PASS | RGBA; 9-slice row/column step 0.00 |
| `widgets/ui_rim_g0.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_rim_g1.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_rim_g2.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_rim_g3.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_rim_g4.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_rim_g5.png` | 160 x 160 | PASS | RGBA; transparent centre verified |
| `widgets/ui_chip_pill.png` | 320 x 96 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_badge_dot.png` | 64 x 64 | PASS | RGBA; fixed asset |
| `widgets/ui_badge_count.png` | 96 x 96 | PASS | RGBA; fixed asset |
| `widgets/ui_ribbon_new.png` | 192 x 96 | PASS | RGBA; fixed asset |
| `widgets/ui_divider_stitch.png` | 512 x 24 | PASS | RGBA; transparent border verified |
| `widgets/ui_section_mark.png` | 256 x 48 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_toast_plate.png` | 480 x 120 | PASS | RGBA; 3-slice middle step 0.00 |
| `widgets/ui_spinner_yarn.png` | 192 x 192 | PASS | RGBA; fixed asset |
| `sheets/sheet_icons_7_stats_1.png` | 1500 x 900 | PASS | RGB; 5 x 3 equal cells; exact #FF00FF background; >=15% padding |
| `sheets/sheet_icons_8_stats_2.png` | 1500 x 900 | PASS | RGB; 5 x 3 equal cells; exact #FF00FF background; >=15% padding |
| `preview_kit.png` | 1080 x 1920 | PASS | Composite preview on cream paper |
| `reference_board.png` | 1200 x 900 | PASS | Internal six-anchor generation reference board |

## Exceptions

None. The delivered files match the requested names, dimensions, transparency/layout rules, and slice checks.

## Fix audit — 2026-11-13

The assets listed in `design/art/ui_kit_v3_fixes_prompt.md` were redrawn and checked with the end-cap profile test. `L` and `R` are the alpha-height shares at x=2 and x=width-3; `Mid` is the mean painted-height share in the stretchable middle; `Cap L/R` are the shares at the two cap joins.

| File | L | R | Mid | Cap L/R | Middle std | Result |
|---|---:|---:|---:|---:|---:|---|
| `widgets/ui_bar_fill_green.png` | 0.125 | 0.167 | 0.917 | 0.917 / 0.917 | 0.0000 | PASS |
| `widgets/ui_bar_fill_teal.png` | 0.146 | 0.167 | 0.917 | 0.917 / 0.917 | 0.0000 | PASS |
| `widgets/ui_bar_fill_coral.png` | 0.146 | 0.146 | 0.917 | 0.917 / 0.917 | 0.0000 | PASS |
| `widgets/ui_bar_fill_sun.png` | 0.146 | 0.125 | 0.917 | 0.917 / 0.917 | 0.0000 | PASS |
| `widgets/ui_bar_track.png` | 0.000 | 0.000 | 0.938 | 0.938 / 0.938 | 0.0000 | PASS |
| `widgets/ui_tab_strip.png` | 0.023 | 0.055 | 0.594 | 0.594 / 0.594 | 0.0000 | PASS |
| `widgets/ui_toast_plate.png` | 0.033 | 0.067 | 0.617 | 0.617 / 0.617 | 0.0000 | PASS |
| `widgets/ui_tab_on.png` | 0.070 | 0.070 | 0.641 | 0.641 / 0.641 | 0.0000 | PASS |
| `widgets/ui_tab_off.png` | 0.078 | 0.086 | 0.641 | 0.641 / 0.641 | 0.0000 | PASS |
| `widgets/ui_chip_pill.png` | 0.094 | 0.073 | 0.625 | 0.625 / 0.625 | 0.0000 | PASS |

Additional checks:

- `widgets/ui_btn_coral.png`: painted height 93/160 px (0.581); dark vertical column anomalies above 12 brightness points: 0; maximum measured delta: 0.00.
- `widgets/ui_panel_sheet.png`: inner-paper RGB standard deviation is `[0.0, 0.0, 0.0]`; no lighter inset rectangle remains.
- `sheets/sheet_icons_7_stats_1.png`: all six reviewed fragment regions contain 0 non-magenta pixels after cleanup; unrelated disconnected fragments below 600 px: 0. Intentional icon parts such as sparkles and speed marks are retained.
- `sheets/sheet_icons_8_stats_2.png`: the reviewed carrot-cell fragment region contains 0 non-magenta pixels after cleanup; unrelated disconnected fragments below 600 px: 0.
- `preview_fixes.png`: 3360 x 1995 px; every redrawn widget is composited on cream at its native width and at real 2x/3x middle-column stretch widths.

## Round 3 audit — 2026-11-14

| File | Measured result | Result |
|---|---|---|
| `widgets/ui_section_mark.png` | 256 x 48 canvas; painted bbox 200 x 32 px at `(28, 8)–(228, 40)`; transparent border; 0 magenta pixels | PASS |
| `widgets/ui_divider_stitch.png` | 512 x 24 canvas; painted x-range 5–506; painted height 6 px; minimum 115 painted pixels in every 40 px window; 32 px tile period with 5 px half-gap at each edge | PASS |
| `widgets/ui_panel_dialog.png` | 384 x 384 canvas; 0 pixels with alpha below 250 or 255 inside the silhouette eroded by 2 px; centre 208 x 208 contains one flat RGBA value; transparent outer border | PASS |
| `preview_round3.png` | 1400 x 900 | PASS — all three assets composited over cream `#F6F0E1` and dark blue `#2B3A55` |

All three files also pass the main size, transparent-border and magenta-fringe checks.
