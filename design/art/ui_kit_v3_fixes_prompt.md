# GPT task — UI kit v3: fixes after Claude's review (D-069)

Redraw **only the pieces listed here**, in the same folder, with the same file names and exact pixel sizes as in `design/art/ui_kit_v3_prompt.md`. Everything else in `assets/raw/ui_v3/` is accepted and wired into the game; do not touch it. Same STYLE block, references and delivery rules as the main brief (transparent PNG, no magenta, no text, no git, no APK). Reply to YK in Thai; notes in English.

Why these fail even though your self-check passed: the check only tested that the **middle** of each piece is uniform. It did not test that the **end caps are actually rounded ends**. Claude composited every file on cream paper and looked at it; the pieces below do not work as 3-slice pieces.

## A. Nine 3-slice pieces have no real end caps — redraw all nine
Measured on the files you delivered:

| File | Size | Cap | What is wrong |
|---|---|---|---|
| `ui_bar_fill_green/teal/coral/sun.png` | 480×48 | 24 | A flat striped rectangle with square ends: no rounded ends, the outline is just a line across the top and bottom. |
| `ui_bar_track.png` | 480×64 | 32 | The ends are drawn, but the top and bottom outline lines run straight **through** the caps and stick out past the rounded ends. |
| `ui_tab_strip.png` | 768×128 | 56 | Two horizontal lines only: no ends at all. |
| `ui_toast_plate.png` | 480×120 | 60 | Two horizontal lines only: no ends at all. |
| `ui_tab_on.png`, `ui_tab_off.png` | 256×128 | 40 | Rounded ends exist, but the top/bottom rim lines continue across the caps, so the silhouette is a rectangle with ears. |
| `ui_chip_pill.png` | 320×96 | 48 | Same problem as the tabs. |

What a correct 3-slice piece looks like (this is how the game uses it: left cap and right cap are drawn unstretched, only the strip between them is stretched sideways):
- The **whole rounded end lives inside the cap zone** (the first `cap` px on the left, the last `cap` px on the right): the outline curves around and closes; the corners of the image are transparent; nothing from the middle strip's rim lines enters the cap zone.
- At x = 0 the visible height is small (the tip of the round end) and it grows to the full height by x = `cap`. For a capsule whose height equals 2 × cap this is a half circle.
- From x = `cap` to x = width − `cap` the picture is **identical column by column** (top outline, flat fill, bottom outline), and it joins the caps without a visible step: the colour of the column at `cap − 1` must be the colour of the column at `cap`.
- The shape is a capsule (pill), as the main brief says. Fills keep their painted bevel: lighter top-left stroke, darker bottom lip.

Measured silhouette targets (alpha height of the painted part, as a share of the file height):
- `ui_bar_track`: full height 94 % in the middle, ≤ 40 % at x = 2 and at x = width − 3.
- `ui_bar_fill_*`: 92 % in the middle, ≤ 40 % at the extreme ends. The game draws a fill at any width ≥ 2 × cap, so each end must be a complete round cap.
- `ui_tab_strip`, `ui_toast_plate`, `ui_chip_pill`, `ui_tab_on`, `ui_tab_off`: the same rule with their own heights (tabs 64 %, chip 62 %, toast plate 62 %, strip 60 %).

## B. `ui_btn_coral.png` has two dark vertical lines inside the face
At about x = 80 and x = 400 (the cap boundaries) the file contains a dark vertical outline line across the face. Stretched, these become two stripes in the middle of every coral button. Redraw the face as one smooth piece with the same bevel as `ui_btn_yellow.png` (which is correct), no lines at the cap boundaries. Also make the art height consistent with the others: coral uses 77 % of the file height, the other four buttons use 58–69 %. Match `ui_btn_yellow` (58 %).

## C. `ui_panel_sheet.png` shows a lighter inner rectangle
Inside the paper there is a visible lighter rectangle with a hard edge (about 55 px in from the sides, 55 px below the top rim). Stretched, it looks like a second panel. The paper must be one flat cream from rim to rim.

## D. Stray fragments on the icon sheets
The slicer centres every icon on its bounding box, so a small stray mark inside the cell moves and shrinks the icon. Remove these fragments (they are leftovers of neighbouring icons or hatch strokes); keep every icon exactly as it is:
- `sheet_icons_7_stats_1.png` (cells are 300×300 px): a thin dark line at about x 733–750, y 356; bits at x 853–854, y 528–539 and x 852–854, y 751–757; small marks at x 141–155, y 549–554 and x 1348–1373, y 549–554; a speck at x 1153–1154, y 739–753.
- `sheet_icons_8_stats_2.png`: a half-round white fragment at about x 1142–1154, y 770–818 (right edge of the cell holding the carrot, beside the `pet_carrot` icon).
Also remove any other disconnected fragment smaller than 600 px that is not part of an icon (you will see them with a connected-components pass).

## Self-check to run, and report the numbers
Run the main brief's check **plus** these (they would have caught the errors above):

```python
from PIL import Image; import numpy as np
def height_profile(path):
    a = np.asarray(Image.open(path).convert("RGBA"))[:, :, 3] > 128
    h = a.shape[0]
    cols = a.sum(axis=0) / h            # share of the height covered at every column
    return cols
def check_caps(path, cap):
    c = height_profile(path); w = len(c)
    mid = c[cap + 2: w - cap - 2].mean()
    assert c[2] < 0.5 * mid, f"{path}: left end not rounded ({c[2]:.2f} vs {mid:.2f})"
    assert c[w - 3] < 0.5 * mid, f"{path}: right end not rounded"
    assert abs(c[cap - 1] - mid) < 0.08 and abs(c[w - cap] - mid) < 0.08, f"{path}: cap does not reach full height at x=cap"
    assert c[cap + 2: w - cap - 2].std() < 0.01, f"{path}: middle height varies"
```
Call `check_caps` with the caps from the table (bar fills 24, bar track 32, strip 56, toast plate 60, tabs 40, chip 48). For the coral button also report that no column inside the face (x between 100 and 380) has a dark vertical line (the mean brightness of any column must stay within 12 of the average of its neighbours ± 6 columns). For the sheets, report the number of disconnected components smaller than 600 px (must be 0).

Then composite every redrawn file over cream `#F6F0E1` **at three widths** (its own width, 2× and 3× wide, by repeating the middle column strip between the caps exactly as the game does) and put the result in `assets/raw/ui_v3/preview_fixes.png`. If a piece shows a step, a line or a square end at 2× or 3×, it is not done. Update `DELIVERY.md` with the measured numbers. Do not change any other file.
