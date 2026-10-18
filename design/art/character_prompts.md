# Whisker Tales — Character Sheet Prompts 🎨

**อัปเดต:** 2026-10-14 · **อ้างอิง:** ART_PROMPT_BIBLE (สไตล์/สี) · assetlist.md §A–C · GDD v0.4
**วิธีใช้:** 1 prompt = 1 ภาพ (sprite sheet) ต่อ 1 ตัวละคร → วางไฟล์ไว้ที่ `assets/raw/sheets/` ตามชื่อในหัวข้อ → Claude ตัดเป็นเฟรมแยก ลบพื้นหลัง ตั้งชื่อตาม Bible §7 ให้

> ชื่อ/หน้าตามอน เพื่อนสัตว์ และบอส ในไฟล์นี้เป็น**ข้อเสนอ** — ล็อกจริงใน T-043 · เปลี่ยนได้ แค่แก้คำบรรยายในบล็อก CHARACTER

---

## 0. กติกาให้ตัดภาพได้ (สำคัญที่สุด)

1. **พื้นหลังสีเดียวทึบ `#FF00FF` (magenta)** ทั้งภาพ — ไม่ใช่โปร่งใส ไม่ใช่ขาว (ขาวจะชนกับขอบขาวของสีไม้) · magenta ไม่อยู่ใน palette ของเกม ลบออกได้สะอาด
2. **ตารางช่องเท่ากันทุกช่อง** ตามจำนวนคอลัมน์ × แถวที่ระบุ · ตัวละครอยู่กลางช่อง เว้นขอบรอบตัว ≥ 10% ของช่อง · **ห้ามเกินขอบช่อง** (หาง หู เอฟเฟกต์ด้วย)
3. **ขนาดตัวเท่ากันทุกช่อง เท้าแตะเส้นพื้นระดับเดียวกัน** (baseline เดียวกัน) — ไม่งั้นเวลาเล่น animation ตัวจะเด้งขึ้นลง
4. **ห้ามมี** ตัวหนังสือ ตัวเลข เส้นตาราง กรอบ เงาบนพื้น หรือฉากหลัง
5. ความละเอียดสูงสุดที่เครื่องมือให้ได้ (แนะนำ ≥ 2048 px ด้านยาว) · ถ้าเครื่องมือเลือกสัดส่วนได้ ให้ตรงกับ grid (เช่น 4×3 → 4:3)
6. **แนบภาพ Style Anchor (ANCHOR v1) เป็น reference ทุกครั้ง** ตาม Bible — ถ้ายังไม่มี anchor ให้ทำ Sheet ของโมจิ (§1) ก่อน แล้วใช้เป็น anchor
7. ได้ภาพแล้วถ้าบางช่องเพี้ยน (หน้าตาเปลี่ยน, ขนาดไม่เท่า) **gen ใหม่ทั้งแผ่น** ดีกว่าแก้ทีละช่อง — ตัวละครในแผ่นเดียวกันจะหน้าตาตรงกันกว่า

### บล็อกที่ต่อท้ายทุก prompt — SHEET SUFFIX

```
STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, bright playful palette limited to warm orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, shadow plum #7A5E8C and cream #F6F0E1, strong readable silhouette, flat 2D side-scroller game sprite, no digital gradients, no airbrush, child-friendly, no blood, no sharp scary teeth.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the frames in an invisible grid of {COLS} columns by {ROWS} rows, every cell exactly the same size. One pose per cell, centered, with generous empty magenta padding around the character, nothing crossing into another cell. Same character, same proportions, same size and the same ground line in every cell. No text, no numbers, no labels, no grid lines, no borders, no floor, no cast shadows, no background scenery.
```

---

## 1. โมจิสองขา (v0.5 — ใช้อันนี้) — 3 แผ่น

> แบบสี่ขาเดิม (§1-old ด้านล่าง) เลิกใช้แล้ว (D-004) · prompt ด้านล่างประกอบเสร็จแล้ว ก๊อปทั้งกล่องได้เลย · **แนบ `sheet_mochi_poses.png` (แบบเดิม) เป็น reference เรื่องหน้าตา/สี/ลายเส้น** แต่ให้ยืนสองขา

### 1A. `sheet_mochi2_poses.png` — 4 × 3 · หันขวา · สัดส่วน 4:3
```
Create a sprite sheet of the same cartoon kitten adventurer in 12 poses, full body, side view facing RIGHT. Keep the face, fur colors, stripes and drawing style of the reference image, but the kitten now STANDS AND WALKS UPRIGHT ON TWO LEGS like a hero in an adventure cartoon.

CHARACTER: "Mochi", a chubby orange tabby kitten (#F6A83C fur with darker orange stripes), cream belly and muzzle, big friendly dark eyes with white highlights, small pink nose, about 2.2 heads tall, standing upright on two short sturdy hind legs, two arms with round paws, fluffy curved tail with a cream tip. Wears nothing except where a weapon is listed.

FRAMES, left to right, top to bottom:
Row 1: (1) idle, standing upright, arms relaxed, tail up; (2) walk, contact pose, front leg forward, arms swinging; (3) walk, passing pose, legs together, body slightly raised; (4) walk, contact pose, the other leg forward.
Row 2: (5) WARRIOR attack: holding a small round shield on the back arm, slashing a short wooden sword forward with the front arm; (6) ROGUE attack: quick forward stab with two small daggers, leaning in; (7) ARCHER attack: standing firm, drawing a small bow aimed to the right; (8) MAGE attack: raising a short wooden staff with a star tip, small sparkles.
Row 3: (9) dodge, quick hop backward, ears flattened; (10) hurt, flinching, eyes squeezed shut, cute not painful; (11) victory, jumping with both arms up, happy closed eyes; (12) sleeping curled up sitting, hugging a small teal cloth sack.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, bright playful palette limited to warm orange #F6A83C, coral #EE6352, teal #3FA7B8, lime #8CC152, sun yellow #F9D64E, shadow plum #7A5E8C and cream #F6F0E1, strong readable silhouette, flat 2D side-scroller game sprite, no digital gradients, no airbrush, child-friendly.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the frames in an invisible grid of 4 columns by 3 rows, every cell the same size. One pose per cell, centered, with wide empty magenta gaps so no two frames touch, nothing crossing into another cell. Same character, same proportions, same size and the same ground line in every cell. No text, no letters, no numbers, no symbols, no grid lines, no borders, no floor, no cast shadows, no background scenery.
```
→ `cat_mochi_{idle|walk_f1|walk_f2|walk_f3|atk_warrior|atk_rogue|atk_archer|atk_mage|dodge|hurt|victory|sleep}.png` — ใช้เป็นท่าอ้างอิงสำหรับทำ rig (และเป็นเฟรมสำรองถ้า rig ไม่ผ่าน)

### 1B. `sheet_mochi2_parts.png` — 9 × 3 · หันขวา · สัดส่วน 3:1 · **แนบภาพจาก 1A เป็น reference**
```
Create a character rig parts sheet: the same upright two-legged kitten as in the reference image, taken apart into separate body parts for 2D skeletal animation, side view facing RIGHT, NO weapons, NO clothes. Draw every part complete, including the areas normally hidden where parts overlap, and extend each part slightly past its joint (rounded ends) so it can rotate without gaps.

CHARACTER: "Mochi", a chubby orange tabby kitten (#F6A83C fur with darker orange stripes), cream belly and muzzle, big friendly dark eyes with white highlights, small pink nose, about 2.2 heads tall, upright on two legs, fluffy curved tail with a cream tip.

COLUMNS (same order in every row): (1) head with neutral face, no ears; (2) both ears as one piece; (3) torso with cream belly, no head, no limbs; (4) front arm, straight, open round paw; (5) back arm, straight, open round paw; (6) front leg with foot; (7) back leg with foot; (8) tail; (9) front paw closed into a fist with a round hole, as if gripping a stick.
ROWS: three copies of the exact same parts in the same positions and sizes, each redrawn by hand with slightly different line wobble. Parts stay identical in shape, size and color across rows; only the hand-drawn line wobble changes. Every part keeps the same scale it has on the assembled character.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, flat 2D game sprite, no digital gradients, no airbrush, child-friendly.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the parts in an invisible grid of 9 columns by 3 rows, every cell the same size, one part per cell, centered, with wide empty magenta gaps so no two parts touch. No text, no letters, no numbers, no symbols, no grid lines, no borders, no shadows.
```
→ `cat_mochi_{head|ears|torso|frontarm|backarm|frontleg|backleg|tail|fist}_f{1-3}.png`

### 1C. `sheet_mochi2_faces.png` — 5 × 1 · หันขวา · **แนบภาพจาก 1A + 1B**
```
Create a sheet of 5 versions of the same kitten HEAD from the reference images, head only (no ears, no body), side view facing RIGHT. Identical head shape, size and position in every cell — it must match the head part in the reference parts sheet exactly; only the facial expression changes.

FRAMES left to right: (1) neutral, eyes open; (2) blinking, eyes closed as gentle curves; (3) hurt, eyes squeezed shut, small wobbly mouth; (4) happy, closed smiling eyes, open mouth; (5) determined, narrowed eyes, small confident smile.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, flat 2D game sprite, no digital gradients, no airbrush, child-friendly.

SHEET LAYOUT: a clean sprite sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the heads in an invisible grid of 5 columns by 1 row, every cell the same size, one head per cell, centered, with wide empty magenta gaps. No text, no letters, no symbols, no grid lines, no borders, no shadows.
```
→ `cat_mochi_face_{neutral|blink|hurt|happy|fierce}.png`

---

## 1-old. โมจิสี่ขา (v0.4 — เลิกใช้ เก็บไว้อ้างอิง)

โมจิเป็นตัวเดียวที่ต้องทำ **layered rig** (CONTRACT §5 — รองรับ cosmetic และ Mochi Studio) จึงต้องมี 3 แผ่น: ท่าเต็มตัว (ใช้เป็นเฟรม animation สำรอง + reference), ชิ้นส่วน rig, หน้าอารมณ์

**CHARACTER (ใช้ซ้ำทั้ง 3 แผ่น):**
```
CHARACTER: "Mochi", a chubby round orange tabby kitten (#F6A83C fur with darker orange stripes), cream belly and muzzle, big friendly dark eyes with white highlights, small pink nose, short stubby legs, fluffy curved tail with a cream tip, tiny cream paw pads. Soft round shapes, about 2.5 heads tall. Wears nothing (gear and cosmetics are added later as separate layers).
```

### 1A. `sheet_mochi_poses.png` — 4 คอลัมน์ × 3 แถว (12 ท่า) · หันขวาทุกช่อง

```
Create a sprite sheet of the same cartoon kitten character in 12 poses, full body, side view facing RIGHT.

{CHARACTER}

FRAMES, left to right, top to bottom:
Row 1: (1) idle standing, relaxed, tail up; (2) walk cycle contact pose, front paw forward; (3) walk cycle passing pose, legs together, body slightly raised; (4) walk cycle contact pose, opposite paw forward.
Row 2: (5) attack wind-up, crouched, paw raised back, determined face; (6) attack strike, paw swiped forward, three short curved motion lines; (7) casting magic, sitting up, glowing whiskers, small star sparkles; (8) dodge, quick hop backward, ears flattened.
Row 3: (9) hurt, flinching, eyes squeezed shut, cute not painful; (10) victory, jumping with both front paws up, happy closed eyes; (11) sleeping curled up hugging a small cloth sack, peaceful; (12) sitting front-facing, waving one paw (menu greeting).

{SHEET SUFFIX with COLS=4, ROWS=3}
```
→ ได้ 12 ไฟล์: `cat_mochi_{idle|walk_f1|walk_f2|walk_f3|attack_f1|attack_f2|cast|dodge|hurt|victory|sleep|wave}.png`

### 1B. `sheet_mochi_parts.png` — 6 คอลัมน์ × 3 แถว (ชิ้นส่วน rig × 3 เส้นสั่น)

```
Create a character rig parts sheet: the same kitten taken apart into separate body parts for 2D skeletal animation, side view facing RIGHT, every part drawn complete including the areas normally hidden where parts overlap (extend shapes slightly past the joints so they can rotate without gaps).

{CHARACTER}

COLUMNS (same order in every row): (1) head with face, no ears; (2) both ears as one piece; (3) body/torso with belly, no legs, no head; (4) front leg pair (near and far front legs, slightly apart); (5) back leg pair; (6) tail.
ROWS: three copies of the exact same parts in the same positions and sizes, each redrawn by hand with slightly different line jitter (boiling-line animation frames). Row 1 = version 1, Row 2 = version 2, Row 3 = version 3. Parts must stay identical in shape, size and color across rows; only the hand-drawn line wobble changes.

Each part keeps the same scale as it has on the assembled character.

{SHEET SUFFIX with COLS=6, ROWS=3}
```
→ ได้ 18 ไฟล์: `cat_mochi_{head|ears|body|frontleg|backleg|tail}_f{1-3}.png` — Claude จะวัดจุดหมุน (pivot) ของแต่ละชิ้นเทียบกับท่า idle ใน 1A ให้

### 1C. `sheet_mochi_faces.png` — 5 คอลัมน์ × 1 แถว (หน้าอารมณ์)

```
Create a sheet of 5 versions of the same kitten HEAD only (no ears, no body), side view facing RIGHT, identical head shape, size and position in every cell; only the facial expression changes.

{CHARACTER}

FRAMES left to right: (1) neutral, eyes open; (2) blinking, eyes closed as gentle curves; (3) hurt, eyes squeezed shut, small wobbly mouth; (4) happy, closed smiling eyes, open mouth; (5) determined, narrowed eyes, small confident smile (for attacking).

{SHEET SUFFIX with COLS=5, ROWS=1}
```
→ ได้ 5 ไฟล์: `cat_mochi_face_{neutral|blink|hurt|happy|fierce}.png`

---

## 2. นกฮูกบรรณารักษ์ (ห้องสมุด + ร้าน) — `sheet_owl.png` · 2 คอลัมน์ × 2 แถว · หันซ้าย (อยู่ฝั่งขวาของจอ)

```
Create a sprite sheet of a friendly NPC character in 4 frames, full body, side view facing LEFT.

CHARACTER: a plump, kind old owl librarian, soft teal (#3FA7B8) and cream feathers, round spectacles, a small plum (#7A5E8C) knitted scarf, holding a thick open storybook under one wing, sitting on a short stack of books. Gentle, wise and welcoming.

FRAMES: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) talking, beak open, one wing raised pointing up as if explaining.

{SHEET SUFFIX with COLS=2, ROWS=2}
```
→ `npc_owl_idle_f{1-3}.png`, `npc_owl_talk.png`

---

## 3. มอนสเตอร์ธรรมดา — 6 ตัว · แผ่นละ 4 คอลัมน์ × 2 แถว · หันซ้ายทุกช่อง

**FRAMES (ใช้กับมอนทุกตัว):**
```
FRAMES, left to right, top to bottom:
Row 1: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) move, a small hop forward toward the left.
Row 2: (5) attack telegraph, wind-up pose 1, leaning back, clearly about to attack, no symbols or marks above the head; (6) attack telegraph, wind-up pose 2, even more stretched back; (7) attack, lunging forward to the left; (8) defeated, sitting dazed with swirly dizzy eyes, a little puff of colored-pencil smoke, no injuries.
```

**PROMPT (เปลี่ยนแค่ CHARACTER):**
```
Create a sprite sheet of a cute cartoon forest monster in 8 frames, full body, side view facing LEFT. Mischievous but adorable, grumpy furrowed brows, coral and plum accents to show it is an enemy, never scary.

{CHARACTER}

{FRAMES}

{SHEET SUFFIX with COLS=4, ROWS=2}
```

| แผ่น | บท | CHARACTER (ข้อเสนอ) |
|---|---|---|
| `sheet_mon_eraserslime.png` | 1 | `CHARACTER: "Eraser Slime", a squishy pink rubber-eraser blob shaped like a soft cube with rounded corners, eraser crumbs stuck on it, tiny stubby arms, grumpy little face.` |
| `sheet_mon_acorn.png` | 1 | `CHARACTER: "Grumpy Acorn", a round brown acorn with a knitted-looking cap, two tiny legs and arms, pouty face, holds a small twig like a sword.` |
| `sheet_mon_inkbat.png` | 2 | `CHARACTER: "Ink Bat", a small round bat made of folded dark-plum paper with ink-splat wings, big curious eyes, tiny fangs drawn as rounded nubs (not sharp), hovers off the ground.` |
| `sheet_mon_crayonsnail.png` | 2 | `CHARACTER: "Crayon Snail", a chubby snail whose shell is a spiral of melted coral and sun-yellow crayon wax, slow and sleepy-grumpy face.` |
| `sheet_mon_shavinghog.png` | 3 | `CHARACTER: "Shaving Hedgehog", a round hedgehog whose spines are curly pencil shavings with colored edges, little pointy nose, huffy expression.` |
| `sheet_mon_clipbeetle.png` | 3 | `CHARACTER: "Clip Beetle", a shiny teal beetle whose horn and legs are bent paper clips, determined little face.` |

→ ต่อตัว: `mon_{id}_idle_f{1-3}`, `mon_{id}_move`, `mon_{id}_telegraph_f{1-2}`, `mon_{id}_attack`, `mon_{id}_defeated`
→ บอสประจำหน้า (27 ตัว) ใช้มอนพวกนี้ขยาย ×1.3 + เอฟเฟกต์มงกุฎ ไม่ต้อง gen เพิ่ม

---

## 4. บอสประจำบท — 3 ตัว · หันซ้าย · ตัวใหญ่ราว 1.6 เท่าของมอนธรรมดา

### 4A–4B. บอสบท 1 และ 2 — 4 คอลัมน์ × 2 แถว

**FRAMES:**
```
FRAMES, left to right, top to bottom:
Row 1: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) hurt, flinching backward, eyes squeezed, cartoon-funny not painful.
Row 2: (5) attack telegraph wind-up 1; (6) attack telegraph wind-up 2, exaggerated big wind-up so children can see the attack coming; (7) big attack, lunging forward to the left with three short curved motion lines; (8) defeated, sitting down dazed with swirly eyes and a puff of colored-pencil smoke, a little embarrassed.
```

**PROMPT:**
```
Create a sprite sheet of a cute cartoon BOSS monster in 8 frames, full body, side view facing LEFT, larger and more impressive than a regular monster but still adorable and child-friendly, grumpy brows, coral and plum accents, never scary.

{CHARACTER}

{FRAMES}

{SHEET SUFFIX with COLS=4, ROWS=2}
```

| แผ่น | บท | CHARACTER (ข้อเสนอ) |
|---|---|---|
| `sheet_boss_eraserking.png` | 1 | `CHARACTER: "Eraser King", a giant squishy pink eraser blob wearing a lopsided paper crown and a tiny cape made from a torn notebook page, puffed-up chest, very proud.` |
| `sheet_boss_sharpcrab.png` | 2 | `CHARACTER: "Sharpener Crab", a big teal crab whose shell is a round pencil sharpener with a little metal blade drawn as a harmless silver stripe, claws shaped like pencil stubs, cranky face.` |

### 4C. บอสบท 3 "หมาป่ากระดาษยักษ์" — `sheet_boss_paperwolf.png` · 4 คอลัมน์ × 3 แถว

```
Create a sprite sheet of a cute cartoon BOSS monster in 12 frames, full body, side view facing LEFT, larger and more impressive than a regular monster but still adorable and child-friendly, never scary, no sharp teeth.

CHARACTER: "Giant Paper Wolf", a big fluffy wolf folded from cream drawing paper like origami, pencil-sketch fur texture, soft rounded snout, floppy paper ears, plum (#7A5E8C) shading, a coral scarf, grumpy furrowed brows.

FRAMES, left to right, top to bottom:
Row 1: (1–3) idle phase 1, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) hurt, flinching backward.
Row 2: (5) attack telegraph wind-up 1; (6) attack telegraph wind-up 2, huge exaggerated wind-up; (7) big pounce attack to the left with curved motion lines; (8) defeated, sitting down dazed with swirly eyes, paper ears unfolding, puff of colored-pencil smoke.
Row 3: (9–11) idle phase 2 (angry): the same wolf with paper edges crinkled, fur puffed up, coral scribble lines around it, redrawn three times with slight line jitter; (12) phase 2 attack telegraph wind-up, faster and angrier.

{SHEET SUFFIX with COLS=4, ROWS=3}
```
→ `boss_{id}_idle_f{1-3}`, `boss_{id}_hurt`, `boss_{id}_telegraph_f{1-2}`, `boss_{id}_attack`, `boss_{id}_defeated` (+ หมาป่า: `boss_paperwolf_idle2_f{1-3}`, `boss_paperwolf_telegraph2`)

---

## 4D. ไอคอนหน้าบอส (ปุ่ม "ท้าบอส" กลางบนจอ) — แผ่นละบท · 3 คอลัมน์ × 1 แถว

ปุ่มเป็นวงกลม — เกมตัดเป็นวงกลมเอง ตอนรอฟาร์มจะทำเป็นสีเทา พร้อมท้าแล้วเป็นสีปกติ · **แนบ sheet ของมอนและบอสในบทนั้นเป็น reference**

บท 1 → `sheet_icon_boss_ch1.png` (แนบ `sheet_mon_eraserslime`, `sheet_mon_acorn`, `sheet_boss_eraserking`)
```
Create 3 round game UI portrait icons of the boss characters from the reference images, one per cell, for a "challenge the boss" button. Match the reference art style exactly (same line weight, colored pencil texture and palette).

ICONS left to right:
(1) the pink Eraser Slime from the reference, wearing a small sun-yellow crown, grumpy determined face;
(2) the Grumpy Acorn from the reference, wearing a small sun-yellow crown on its plum cap, grumpy determined face, holding the twig up;
(3) the Eraser King from the reference, its lopsided paper crown, proud and grumpy face.

Each icon: head-and-shoulders close-up, three-quarter view looking slightly to the LEFT toward the viewer, face large and centered, everything important inside the central 80% of the cell so it survives a circular crop, bold readable at 64 px.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game icon, no digital gradients, no airbrush, child-friendly, never scary.

SHEET LAYOUT: a clean icon sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the icons in an invisible grid of 3 columns by 1 row, every cell the same square size, one icon per cell, centered, with wide empty magenta gaps so no two icons touch. No circles, no frames, no borders, no text, no letters, no symbols, no background scenery.
```
→ `ui_bossface_eraserslime.png`, `ui_bossface_acorn.png`, `ui_bossface_eraserking.png` · บท 2–3 ทำหลังมี sheet มอนของบทนั้นแล้ว (โครงเดียวกัน เปลี่ยนชื่อตัวละคร)

---

## 5. เพื่อนสัตว์ — 6 ตัว · แผ่นละ 4 คอลัมน์ × 2 แถว · หันขวา (ยืนข้างโมจิ)

**FRAMES:**
```
FRAMES, left to right, top to bottom:
Row 1: (1–3) idle, the same pose redrawn three times with slightly different hand-drawn line jitter (boiling-line frames), identical shape and position; (4) move, a small hop or flap forward to the right (following the cat).
Row 2: (5) attack wind-up; (6) attack, a small cute attack to the right with a tiny effect matching the animal; (7) happy cheer, both arms or wings up; (8) PORTRAIT ICON: head and shoulders only, facing the viewer, centered, big friendly smile (used as the menu icon).
```

**PROMPT:**
```
Create a sprite sheet of a cute cartoon animal companion in 8 frames, side view facing RIGHT for frames 1–7. Friendly, loyal, sidekick of a small orange kitten, small enough to stand beside it (about two-thirds of the kitten's height).

{CHARACTER}

{FRAMES}

{SHEET SUFFIX with COLS=4, ROWS=2}
```

| แผ่น | ความหายาก | CHARACTER (ข้อเสนอ) |
|---|---|---|
| `sheet_pet_sparrow.png` | ธรรมดา | `CHARACTER: "Pip", a tiny round sparrow with sun-yellow (#F9D64E) chest and brown wings, attacks by pecking.` |
| `sheet_pet_mouse.png` | ธรรมดา | `CHARACTER: "Crumb", a small grey field mouse with big round ears and a lime-green leaf satchel, attacks by throwing a little seed.` |
| `sheet_pet_frog.png` | ธรรมดา | `CHARACTER: "Lily", a chubby lime-green (#8CC152) frog with a tiny flower on its head, attacks with a sticky tongue flick.` |
| `sheet_pet_fox.png` | หายาก | `CHARACTER: "Ember", a fox kit with coral-orange fur and a fluffy cream-tipped tail, carries a small lantern, attacks with a tail swipe that leaves warm sparkles.` |
| `sheet_pet_bunny.png` | หายาก | `CHARACTER: "Doodle", a white bunny whose ear tips look dipped in teal paint, holds a paintbrush, attacks by flicking a splash of teal paint.` |
| `sheet_pet_crayondragon.png` | ตำนาน | `CHARACTER: "Scribble", a baby dragon made of colorful crayon strokes (orange, teal, plum, sun yellow), stubby wings, round belly, attacks by puffing a small rainbow scribble cloud.` |

→ ต่อตัว: `pet_{id}_idle_f{1-3}`, `pet_{id}_move`, `pet_{id}_attack_f{1-2}`, `pet_{id}_cheer`, `pet_{id}_icon`

---

## 6. สรุปจำนวน

| กลุ่ม | แผ่น | เฟรมที่ได้ |
|---|---|---|
| โมจิ | 3 | 35 (ท่า 12 + ชิ้นส่วน 18 + หน้า 5) |
| นกฮูก | 1 | 4 |
| มอนธรรมดา | 6 | 48 |
| บอส | 3 | 28 |
| เพื่อนสัตว์ | 6 | 48 |
| **รวม** | **19 แผ่น** | **163 เฟรม** |

## 7. ลำดับที่แนะนำ

1. `sheet_mochi_poses` → YK ดูโทน → ถ้าโอเคใช้เป็น **ANCHOR v1** (แนบทุก prompt หลังจากนี้)
2. `sheet_mochi_parts`, `sheet_mochi_faces`
3. มอนบท 1 (`eraserslime`, `acorn`) + `eraserking` → พอสำหรับเริ่มเล่น idle loop บท 1 (P0)
4. นกฮูก, เพื่อนสัตว์, มอนบท 2–3, บอสที่เหลือ (P1)

## 8. ส่งให้ Claude ตัด

วางไฟล์ไว้ที่ `assets/raw/sheets/` ตามชื่อแผ่นในไฟล์นี้ (หรือส่งภาพให้ Claude ในแชท) — เฟรมที่ตัดแล้วอยู่ที่ `assets/raw/frames/<ตัวละคร>/`

เครื่องมือ: `tools/sprite_slicer/slice_sheet.py` — หาเฟรมจากช่องว่างพื้นหลังจริง (ไม่ต้องเป็นตารางเป๊ะ) แต่**เฟรมห้ามแตะกันเอง**
```
python3 -I tools/sprite_slicer/slice_sheet.py assets/raw/sheets/sheet_mochi_poses.png \
  --cols 4 --rows 3 --align ground --out assets/raw/frames/mochi --names cat_mochi_idle,...
```
`--align ground` = ท่าตัวละคร (เท้าอยู่ระดับเดียวกัน) · `--align center` = ชิ้นส่วน rig, หน้า, ไอคอน

Claude จะ:
1. ตัดตาม grid → ลบพื้น magenta เป็นโปร่งใส (เก็บขอบเส้นให้เนียน)
2. จัดทุกเฟรมของตัวเดียวกันให้ขนาด canvas เท่ากันและเท้าอยู่ระดับเดียวกัน
3. ตั้งชื่อตาม Bible §7 → `assets/raw/` แล้วรัน QA checklist (Bible §6) ที่ตรวจด้วยโค้ดได้: พื้นโปร่งใสจริง, ไม่มี halo magenta, ขนาดตรงกัน
4. รายงานช่องที่เพี้ยน (ตัวไม่ตรงกัน/เกินขอบ) ให้ gen ใหม่
