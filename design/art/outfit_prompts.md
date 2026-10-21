# Whisker Tales — ชุดประจำคลาส (D-024) 🎨

**อัปเดต:** 2026-10-21 · **อ้างอิง:** character_prompts.md §0 (กติกาตัดภาพ + SHEET SUFFIX) · `design/art/mochi_sprites.json`
**วิธีใช้:** 1 prompt = 1 แผ่น ต่อ 1 คลาส · **แนบ `sheet_mochi2_poses.png` เป็น reference ทุกครั้ง** (หน้าตา/สี/ลายเส้นโมจิต้องเหมือนเดิม) · วางไฟล์ที่ `assets/raw/sheets/` แล้วให้ Claude ตัด:

```
python3 -I tools/sprite_slicer/slice_sheet.py assets/raw/sheets/sheet_outfit_<class>.png --cols 3 --rows 3 \
  --names idle,walk_f1,walk_f2,walk_f3,attack,dodge,hurt,victory,sleep \
  --out assets/raw/frames/outfit/<class> --align ground
python3 tools/sync_sprites.py
```
คลาสที่ยังไม่มีภาพ เกมใช้ภาพโมจิพื้นฐานไปก่อน · คลาสขั้นที่ 2 (content v1.1) ใช้ prompt เดียวกัน เปลี่ยนแค่บล็อก OUTFIT

## Prompt (เปลี่ยนแค่บรรทัด OUTFIT ตามคลาสด้านล่าง)

```
Create a sprite sheet of the same cartoon kitten adventurer from the reference image in 9 poses, full body, side view facing RIGHT, standing and walking upright on two legs. Keep the face, fur colors, stripes, proportions and drawing style exactly the same as the reference — only the outfit is new, and the kitten wears it in every pose (the outfit and its hand item are part of the character, drawn naturally, not pasted on).

CHARACTER: "Mochi", a chubby orange tabby kitten (#F6A83C fur with darker orange stripes), cream belly and muzzle, big friendly dark eyes with white highlights, small pink nose, about 2.2 heads tall, two short sturdy legs, round paws, fluffy curved tail with a cream tip.

OUTFIT: {OUTFIT}

FRAMES, left to right, top to bottom:
(1) idle — standing relaxed, gentle smile;
(2) walk 1 — left leg forward, arms swinging;
(3) walk 2 — legs passing, body slightly higher;
(4) walk 3 — right leg forward, arms swinging the other way;
(5) attack — a big confident action with the class item (swing, shot or spell burst), small speed lines;
(6) dodge — hopping back lightly, surprised but cheerful;
(7) hurt — flinching with eyes squeezed shut, a tiny star above the head, not scary;
(8) victory — paw raised high, happy closed-eye grin;
(9) sleep — curled up sitting, eyes closed, a small "z" bubble shape (no letters).

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, bright playful palette limited to warm orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, shadow plum #7A5E8C and cream #F6F0E1, strong readable silhouette, flat 2D side-scroller game sprite, no digital gradients, no airbrush, child-friendly, no blood, nothing sharp or scary.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the frames in an invisible grid of 3 columns by 3 rows, every cell exactly the same size. One pose per cell, centered, with generous empty magenta padding around the character, nothing crossing into another cell. Same character, same proportions, same size and the same ground line in every cell. No text, no numbers, no labels, no grid lines, no borders, no floor, no cast shadows, no background scenery.
```
สัดส่วนภาพ 1:1

## OUTFIT ต่อคลาส

| ไฟล์ | OUTFIT |
|---|---|
| `sheet_outfit_novice.png` | a beginner adventurer: a lime-green bandana tied around the neck, a small brown leather satchel across the body, and a short rounded wooden practice sword with a cloth-wrapped grip |
| `sheet_outfit_warrior.png` | a brave little knight: a rounded tin helmet with a sun-yellow plume, a coral tunic with a cream belt, a small round teal shield on the left arm and a short rounded wooden-and-tin sword |
| `sheet_outfit_rogue.png` | a nimble scout: a teal hooded scarf with the hood down, soft plum boots, a cream sash, and two small rounded wooden daggers with blunt tips, one in each paw |
| `sheet_outfit_archer.png` | a forest ranger: a lime-green feathered cap with a sun-yellow feather, a brown leaf-patterned vest, a quiver of soft-tipped arrows on the back and a curved wooden bow |
| `sheet_outfit_mage.png` | a little star wizard: a tall floppy plum wizard hat with sun-yellow stars, a short teal cape, and a wooden staff topped with a glowing yellow star |
