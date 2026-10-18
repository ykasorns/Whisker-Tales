"""Slice an AI-generated sprite sheet into transparent frames.

Sheets follow design/art/character_prompts.md §0: flat magenta background,
one pose per slot in a rows × cols layout. Generated sheets rarely keep an
exact grid, so frames are found by the empty background gaps between them:
rows first, then frames within each row. Small detached bits (sparkles,
motion lines) merge into the nearest frame.

All frames of one sheet are written on the same canvas size:
  --align ground   feet on a shared ground line; jumps keep their height
                   above the row's lowest feet (poses, monsters, pets)
  --align center   centred (rig parts, faces, icons)

Usage:
  python3 -I tools/sprite_slicer/slice_sheet.py SHEET.png --cols 4 --rows 3 \
      --names a,b,c,... --out assets/raw/frames/mochi [--align ground]
"""

import argparse
import os
import sys

import numpy as np
from PIL import Image

# Colour distance (0–441) from the background below which a pixel is background.
BG_CLEAR = 60
# Magenta tint (min(R,B) − G) where spill removal starts, and the ramp width.
SPILL_START = 40
SPILL_RAMP = 30
PAD = 12


def estimate_background(rgb: np.ndarray) -> np.ndarray:
    """Median colour of a 4 px border around the whole sheet."""
    border = np.concatenate([
        rgb[:4].reshape(-1, 3), rgb[-4:].reshape(-1, 3),
        rgb[:, :4].reshape(-1, 3), rgb[:, -4:].reshape(-1, 3),
    ])
    return np.median(border, axis=0)


def remove_background(rgb: np.ndarray, bg: np.ndarray) -> np.ndarray:
    """RGBA with the magenta background keyed out and magenta spill removed.

    1. Pixels within BG_CLEAR of the background colour become transparent.
    2. Every other pixel is checked for magenta mixed in: magenta has red and
       blue far above green, which no colour in the game palette does strongly
       (plum, pink noses and paw pads stay below SPILL_START). The mixed-in
       share becomes transparency and is un-mixed from the colour, so soft
       outline edges turn into clean, semi-transparent ink instead of a purple
       rim.
    """
    rgbf = rgb.astype(np.float32)
    dist = np.sqrt(((rgbf - bg) ** 2).sum(axis=2))

    bg_tint = min(bg[0], bg[2]) - bg[1]  # ≈ 247 for #FF00FF-ish backgrounds
    tint = np.minimum(rgbf[..., 0], rgbf[..., 2]) - rgbf[..., 1]
    ramp = np.clip((tint - SPILL_START) / SPILL_RAMP, 0.0, 1.0)
    share = np.clip(tint / bg_tint, 0.0, 1.0) * ramp  # fraction of background

    alpha = np.where(dist < BG_CLEAR, 0.0, 1.0 - share)
    a = alpha[..., None]
    fg = np.where(a > 0, (rgbf - (1 - a) * bg) / np.maximum(a, 1e-3), 0)
    fg = np.clip(fg, 0, 255)

    out = np.dstack([fg, alpha * 255]).astype(np.uint8)
    out[alpha <= 0.03] = 0
    return out


def runs(profile: np.ndarray) -> list[list[int]]:
    """[start, end) spans where profile > 0."""
    spans, start = [], None
    for i, v in enumerate(profile):
        if v and start is None:
            start = i
        elif not v and start is not None:
            spans.append([start, i])
            start = None
    if start is not None:
        spans.append([start, len(profile)])
    return spans


def merge_to(spans: list[list[int]], count: int) -> list[list[int]]:
    """Merge neighbouring spans across the smallest gaps until `count` remain."""
    spans = [s[:] for s in spans]
    while len(spans) > count:
        gaps = [spans[i + 1][0] - spans[i][1] for i in range(len(spans) - 1)]
        i = int(np.argmin(gaps))
        spans[i] = [spans[i][0], spans[i + 1][1]]
        del spans[i + 1]
    return spans


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("sheet")
    p.add_argument("--cols", type=int, required=True)
    p.add_argument("--rows", type=int, required=True)
    p.add_argument("--names", required=True, help="comma-separated, left→right, top→bottom")
    p.add_argument("--out", required=True)
    p.add_argument("--align", choices=["ground", "center"], default="center")
    args = p.parse_args()

    names = [n.strip() for n in args.names.split(",") if n.strip()]
    if len(names) != args.cols * args.rows:
        print(f"ERROR: {len(names)} names for a {args.cols}x{args.rows} layout", file=sys.stderr)
        return 2

    rgb = np.asarray(Image.open(args.sheet).convert("RGB"))
    bg = estimate_background(rgb)
    rgba = remove_background(rgb, bg)
    solid = rgba[..., 3] > 32
    print(f"sheet {args.sheet}: {rgb.shape[1]}x{rgb.shape[0]}, background {tuple(int(c) for c in bg)}")

    row_spans = runs(solid.sum(axis=1))
    if len(row_spans) < args.rows:
        print(f"ERROR: found {len(row_spans)} rows, expected {args.rows} — frames overlap vertically", file=sys.stderr)
        return 1
    row_spans = merge_to(row_spans, args.rows)

    frames = []  # (name, y0, y1, x0, x1, row_bottom)
    for r, (y0, y1) in enumerate(row_spans):
        band = solid[y0:y1]
        col_spans = runs(band.sum(axis=0))
        if len(col_spans) < args.cols:
            print(f"ERROR: row {r + 1} has {len(col_spans)} frames, expected {args.cols} — frames touch", file=sys.stderr)
            return 1
        col_spans = merge_to(col_spans, args.cols)
        row_frames = []
        for c, (x0, x1) in enumerate(col_spans):
            ys = np.nonzero(band[:, x0:x1].any(axis=1))[0]
            row_frames.append([names[r * args.cols + c], y0 + ys[0], y0 + ys[-1] + 1, x0, x1])
        row_bottom = max(f[2] for f in row_frames)
        frames += [f + [row_bottom] for f in row_frames]

    max_w = max(f[4] - f[3] for f in frames)
    if args.align == "ground":
        max_h = max(f[5] - f[1] for f in frames)  # tallest art incl. lift above ground
    else:
        max_h = max(f[2] - f[1] for f in frames)
    cw, ch = max_w + 2 * PAD, max_h + 2 * PAD
    os.makedirs(args.out, exist_ok=True)

    for name, y0, y1, x0, x1, row_bottom in frames:
        crop = rgba[y0:y1, x0:x1].copy()
        crop[~solid[y0:y1, x0:x1] & (crop[..., 3] < 8)] = 0
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        w, h = x1 - x0, y1 - y0
        left = (cw - w) // 2
        if args.align == "ground":
            top = ch - PAD - (row_bottom - y0)
        else:
            top = (ch - h) // 2
        canvas.alpha_composite(Image.fromarray(crop, "RGBA"), (left, top))
        canvas.save(os.path.join(args.out, f"{name}.png"))
        print(f"ok   {name}.png  art {w}x{h}")
    print(f"done: {len(frames)} frames on a {cw}x{ch} canvas ({args.align})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
