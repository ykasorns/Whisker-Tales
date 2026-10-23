# Home panel v2 — proposal (YK item 11, 2026-10-23)

**Today (the 40% panel under the scene):** a row of 8 gear icons squeezed on one line, two toggle buttons (Auto-knit / "Better: wear now"), and a big red yarn ball with "Knit · yarn left" — the lower third is empty.

**YK's idea:** a **basket with several yarn balls** that move when you tap to knit; the rest "look at other games".

## Layout (portrait phone, panel ≈ 320 dp tall, width ≈ 411 dp)

```
┌─────────────────────────────────────────────┐
│  SHELF  (wooden plank look, code-drawn)       │
│  [weapon][hat][shirt][shoes]   2 rows × 4     │  ~ 120 dp, slots 56 dp
│  [scarf ][gloves][bell][bag]   locked = 🔒 + "Page N" │
├─────────────────────────────────────────────┤
│ [AUTO]      ┌────────────┐      [WEAR]      │
│ icon+word   │ 🧺 basket  │   icon+word      │  basket ≈ 190×140 dp
│ toggle      │ 5–6 balls  │   toggle         │  tap = knit (≥ 72 dp, thumb zone)
│             └────────────┘                  │
│        "Knit · 12 yarn left" tag on the basket│
└─────────────────────────────────────────────┘
```
Constraints kept: 60/40 split (`layout_test`), main button ≥ 72 dp in the thumb zone, no icon without a word, auto-knit/wear toggles stay, parental/ads rules untouched (no ad button here).

## Animation (Flutter, no extra engine)
- Idle: the balls bob gently (sine offsets, different phases); basket breathes ±1 %.
- Tap/knit: squash the basket, balls hop in a stagger, ONE ball arcs out above the basket, spins/unravels, then the existing `KnitPop` item appears; a short thread curl trails.
- Auto-knit: same but quieter (one hop) so it does not nag.
- Out of yarn: balls sit still and dim; the tag says "fight for yarn".
- Layering trick (no layered art needed): draw the basket image, draw the balls, then draw the **bottom 55 %** of the same basket image again on top, so the balls sit *inside* the opening.

## Art to generate in ChatGPT (same chat/style)
1. `basket` — one empty wicker basket, open top seen slightly from above, two small side handles, colored-pencil style, on magenta.
2. `yarn_1…6` — six single yarn balls with a loose thread, colors: coral, teal, sun-yellow, lime, plum, cream (3×2 sheet).
Shelf/slots stay code-drawn with the existing ink-box style (cheap, consistent, scales to any width).

## Open questions for the advisor
- 2 rows × 4 vs one row of 8 slots; where the "Better: wear now" toggle belongs.
- Is the basket-as-button big enough vs. the 72 dp rule when it shares the row with two toggles?
- Anything from other idle RPGs (e.g. bottom "upgrade shelf" patterns) worth copying?
