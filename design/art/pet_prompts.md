# Whisker Tales — Pet Prompts 🐦🐭🐸🦔🐰🦄

**อัปเดต:** 2026-10-20 · **อ้างอิง:** GDD v0.4 §6 · `design/data/pets.json` (T-038)
**วิธีใช้:** แนบ `sheet_mochi2_poses.png` (หรือภาพโมจิท่ายืน) เป็น reference เรื่องสไตล์ · วาง `assets/raw/sheets/` หรือส่งในแชท → Claude ตัด → `assets/raw/frames/pets/`
**ตอนนี้ในเกมใช้ emoji แทนไปก่อน** — ได้ภาพแล้วเปลี่ยนได้โดยไม่ต้องแก้ระบบ

## `sheet_pets.png` (6 ตัว × 2 ท่า · ตาราง 4 × 3 · สัดส่วน 4:3)
```
Create a game sprite sheet of 6 small animal sidekicks for a cute cartoon kitten adventurer, each drawn twice: an IDLE pose (standing, happy) and an ATTACK pose (leaning forward, small action), all facing RIGHT, full body, same art style as the reference kitten. They are about half the kitten's height, round and friendly, made for young children.

PETS, in order (idle then attack for each, left to right, top to bottom):
(1) a tiny brown sparrow with a sun-yellow knitted scarf — attack: pecking forward with a small wind puff;
(2) a little grey mouse with big pink ears and a thimble helmet — attack: throwing a tiny yarn ball;
(3) a round green frog with a lily-pad hat — attack: tongue flick with a sparkle;
(4) a soft hedgehog with cream spikes like knitting needles tips, pastel teal scarf — attack: rolling into a spiky ball;
(5) a white rabbit holding a giant colored pencil like a lance — attack: poking with the pencil, a crayon streak behind it;
(6) a small unicorn with a rainbow mane and a glowing horn — attack: horn shooting a little rainbow star.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game sprite, no digital gradients, no airbrush, child-friendly, no weapons that look sharp or scary.

SHEET LAYOUT: a clean sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the 12 drawings in an invisible grid of 4 columns by 3 rows, every cell the same size, one drawing per cell, feet on the same baseline within a row, with wide empty magenta gaps so no two drawings touch. No text, no letters, no symbols, no grid lines, no borders, no shadows.
```
→ `pet_{sparrow|mouse|frog|hedgehog|rabbit|unicorn}_{idle|attack}.png`
