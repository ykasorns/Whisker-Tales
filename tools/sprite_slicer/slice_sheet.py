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
  --align feet     each frame's main body (largest blob) stands on the ground
                   line; loose bits like motion lines or crumbs don't lift it
                   (monsters — use ground for poses that jump)

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


def split_to(spans: list[list[int]], count: int, profile: np.ndarray, label: str) -> list[list[int]]:
    """Split the widest span at its thinnest column until `count` spans exist.

    Used when two frames touch. Warns with the number of art pixels the cut
    goes through, so a bad cut can be checked or the sheet regenerated.
    """
    spans = [s[:] for s in spans]
    while len(spans) < count:
        i = max(range(len(spans)), key=lambda k: spans[k][1] - spans[k][0])
        x0, x1 = spans[i]
        lo, hi = x0 + (x1 - x0) // 4, x1 - (x1 - x0) // 4
        cut = lo + int(np.argmin(profile[lo:hi]))
        print(f"WARN {label}: frames touch — split at {cut} through {int(profile[cut])} art px")
        spans[i:i + 1] = [[x0, cut], [cut, x1]]
    return spans


def label_components(mask: np.ndarray) -> tuple[np.ndarray, int]:
    """8-connected component labels (0 = background), run-length union-find."""
    h, w = mask.shape
    labels = np.zeros((h, w), dtype=np.int32)
    parent = [0]

    def find(a: int) -> int:
        while parent[a] != a:
            parent[a] = parent[parent[a]]
            a = parent[a]
        return a

    prev_runs: list[tuple[int, int, int]] = []
    for y in range(h):
        row = mask[y]
        cur_runs = []
        for x0, x1 in runs(row):
            lab = 0
            for px0, px1, plab in prev_runs:
                if px0 <= x1 and x0 <= px1:  # touches incl. diagonals
                    if lab == 0:
                        lab = find(plab)
                    else:
                        a, b = find(lab), find(plab)
                        if a != b:
                            parent[max(a, b)] = min(a, b)
                            lab = min(a, b)
            if lab == 0:
                parent.append(len(parent))
                lab = len(parent) - 1
            labels[y, x0:x1] = lab
            cur_runs.append((x0, x1, lab))
        prev_runs = cur_runs
    roots = np.array([find(i) for i in range(len(parent))], dtype=np.int32)
    return roots[labels], len(parent)


def dilate(mask: np.ndarray, radius: int) -> np.ndarray:
    out = mask.copy()
    h, w = mask.shape
    for dy in range(-radius, radius + 1):
        for dx in range(-radius, radius + 1):
            out[max(dy, 0):h + min(dy, 0), max(dx, 0):w + min(dx, 0)] |= \
                mask[max(-dy, 0):h - max(dy, 0), max(-dx, 0):w - max(dx, 0)]
    return out


def assign_owners(band: np.ndarray, spans: list[list[int]], touching: bool) -> np.ndarray:
    """Which frame (column index) owns each pixel of a row band.

    By default a pixel belongs to the column span it sits in. When frames
    touch, each separate blob of art moves whole to the frame holding most of
    it, so a cape tip or sparkle that pokes past the cut stays with its frame.
    Only art that is truly connected across the cut is split by column.
    """
    h, w = band.shape
    col_owner = np.zeros(w, dtype=np.int32)
    for i, (x0, x1) in enumerate(spans):
        col_owner[x0:x1] = i
    # Gaps between spans go to the nearer neighbour.
    starts = np.array([s[0] for s in spans])
    for x in range(w):
        if not any(x0 <= x < x1 for x0, x1 in spans):
            col_owner[x] = int(np.argmin(np.abs(starts - x)))
    owner = np.broadcast_to(col_owner, (h, w)).copy()
    if not touching:
        return owner

    labels, n = label_components(band)
    moved = np.zeros_like(band)
    for lab in np.unique(labels[band]):
        comp = labels == lab
        votes = np.bincount(owner[comp], minlength=len(spans))
        best = int(np.argmax(votes))
        if votes[best] >= 0.85 * comp.sum():
            owner[comp] = best
            moved |= comp
    # Soft rims (below the solid threshold) follow the blob next to them.
    for i in range(len(spans)):
        near = dilate(moved & (owner == i), 3) & ~band
        owner[near] = i
    return owner


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("sheet")
    p.add_argument("--cols", type=int, required=True)
    p.add_argument("--rows", type=int, required=True)
    p.add_argument("--names", required=True, help="comma-separated, left→right, top→bottom")
    p.add_argument("--out", required=True)
    p.add_argument("--align", choices=["ground", "center", "feet"], default="center")
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

    frames = []  # (name, mask over the whole sheet, y0, y1, x0, x1, row_bottom)
    for r, (y0, y1) in enumerate(row_spans):
        band = solid[y0:y1]
        profile = band.sum(axis=0)
        col_spans = runs(profile)
        touching = len(col_spans) < args.cols
        if touching:
            col_spans = split_to(col_spans, args.cols, profile, f"row {r + 1}")
        col_spans = merge_to(col_spans, args.cols)
        owner = assign_owners(band, col_spans, touching)
        row_frames = []
        for c in range(args.cols):
            mine = owner == c
            ys, xs = np.nonzero(mine & band)
            mask = np.zeros_like(solid)
            mask[y0:y1] = mine
            fr = [names[r * args.cols + c], mask, y0 + ys.min(), y0 + ys.max() + 1, xs.min(), xs.max() + 1]
            if args.align == "feet":
                sub = (mine & band)[:, xs.min():xs.max() + 1]
                labels, _ = label_components(sub)
                ids, counts = np.unique(labels[sub], return_counts=True)
                body = labels == ids[np.argmax(counts)]
                fr.append(y0 + np.nonzero(body.any(axis=1))[0].max() + 1)  # feet
            row_frames.append(fr)
        if args.align == "feet":
            frames += row_frames  # each frame carries its own feet line
        else:
            row_bottom = max(f[3] for f in row_frames)
            frames += [f + [row_bottom] for f in row_frames]

    max_w = max(f[5] - f[4] for f in frames)
    if args.align == "feet":
        above = max(f[6] - f[2] for f in frames)              # art above the feet line
        below = max(max(0, f[3] - f[6]) for f in frames)      # bits hanging below it
        max_h = above + below
    elif args.align == "ground":
        max_h = max(f[6] - f[2] for f in frames)  # tallest art incl. lift above ground
    else:
        max_h = max(f[3] - f[2] for f in frames)
    cw, ch = max_w + 2 * PAD, max_h + 2 * PAD
    os.makedirs(args.out, exist_ok=True)

    for name, mask, y0, y1, x0, x1, row_bottom in frames:
        crop = rgba[y0:y1, x0:x1].copy()
        crop[~mask[y0:y1, x0:x1]] = 0
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        w, h = x1 - x0, y1 - y0
        left = (cw - w) // 2
        if args.align == "feet":
            top = ch - PAD - below - (row_bottom - y0)  # row_bottom holds this frame's feet
        elif args.align == "ground":
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
