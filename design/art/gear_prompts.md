# Whisker Tales — Gear Prompts 🧶⚔️

**อัปเดต:** 2026-10-19 · **อ้างอิง:** GDD v0.5.1 §4 (D-005) · ART_PROMPT_BIBLE
**วิธีใช้:** prompt ประกอบเสร็จแล้ว ก๊อปทั้งกล่อง · แนบ `sheet_gear_set1.png` เป็น reference ทุกแผ่น · วางไฟล์ที่ `assets/raw/sheets/` หรือส่งในแชท → Claude ตัด → `assets/raw/frames/gear/`

| แผ่น | เกรด | เนื้อหา | สถานะ |
|---|---|---|---|
| `sheet_gear_set1.png` | ขาว–เขียว (แบบ 1) | ดาบ โล่ มีด ธนู ไม้เท้า หมวก ผ้าพันคอ กระเป๋า | ✅ ทำแล้ว |
| `sheet_gear_set2.png` | ฟ้า–ม่วง (แบบ 2) | 8 ชิ้นเดิม แบบหรูขึ้น | ✅ ทำแล้ว |
| `sheet_gear_set3.png` | ทอง–รุ้ง (แบบ 3) | 8 ชิ้นเดิม แบบตำนาน | ✅ ทำแล้ว |
| `sheet_gear_icons.png` | ทุกเกรด | ไอคอนช่องที่ไม่เห็นบนตัว: เสื้อ รองเท้า ถุงมือ กระดิ่ง × 3 แบบ | ✅ ทำแล้ว |

> เกรด → ภาพ: ขาว/เขียว = แบบ 1 · ฟ้า/ม่วง = แบบ 2 · ทอง/รุ้ง = แบบ 3 · อาวุธบนตัวขึ้นกับคลาส (นักรบ ดาบ+โล่ · โจร มีด 2 เล่ม · ธนู ธนู · เมจ ไม้เท้า)
> สีเกรดย่อยในช่วงเดียวกัน (เช่น ฟ้า vs ม่วง) เกมย้อมสีให้เอง ไม่ต้องวาดแยก

## 1. แบบ 2 — `sheet_gear_set2.png` (4 × 2 · สัดส่วน 2:1)
```
Create a game equipment sheet of 8 separate items for the small cartoon kitten adventurer, each item drawn alone, as the UPGRADED (rare) versions of the matching items in the reference sheet: same size, same orientation and same layout position as the reference, but sturdier and fancier. Match the reference art style exactly.

ITEMS, left to right, top to bottom:
Row 1:
(1) SWORD: a steel-bladed short sword with a teal leather-wrapped handle and a curled sun-yellow crossguard, standing straight UP, handle at the bottom;
(2) SHIELD: a round wooden shield with a teal and cream paw-print emblem and a riveted metal rim, seen from the front;
(3) DAGGER: one curved dagger with a silver blade, a plum grip and a small teal gem in the guard, standing straight UP, handle at the bottom;
(4) BOW: a recurved wooden bow with teal and plum wraps and a little feather charm, standing straight UP, grip in the middle;
Row 2:
(5) STAFF: a wooden staff wrapped in yarn, topped with a glowing teal crescent moon and a small star, standing straight UP, handle at the bottom;
(6) HAT: a teal explorer's cap with a cream yarn band and a small feather, seen from the side facing RIGHT, as if worn on a head;
(7) SCARF: a long teal and plum knitted scarf with tassels, wrapped as a loop with one end hanging, seen from the side facing RIGHT;
(8) BAG: a teal knitted adventurer's satchel-backpack with two pockets and a sun-yellow buckle, seen from the side facing RIGHT, as if worn on a back.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game item art, no digital gradients, no airbrush, child-friendly.

SHEET LAYOUT: a clean sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the items in an invisible grid of 4 columns by 2 rows, every cell the same size, one item per cell, centered, with wide empty magenta gaps so no two items touch. No text, no letters, no symbols, no grid lines, no borders, no shadows.
```
→ `gear_{sword|shield|dagger|bow|staff|hat|scarf|bag}_2.png`

## 2. แบบ 3 — `sheet_gear_set3.png` (4 × 2 · สัดส่วน 2:1)
```
Create a game equipment sheet of 8 separate items for the small cartoon kitten adventurer, each item drawn alone, as the LEGENDARY versions of the matching items in the reference sheet: same size, same orientation and same layout position as the reference, but magical and special, with golden details and a soft rainbow shimmer drawn as small colored pencil sparkle strokes (no glow effects, no gradients). Match the reference art style exactly.

ITEMS, left to right, top to bottom:
Row 1:
(1) SWORD: a golden short sword with a blade shaped like a giant colored pencil tip, a coral grip and a star pommel, standing straight UP, handle at the bottom;
(2) SHIELD: a round golden shield with a big cat-face emblem and rainbow-striped rim, seen from the front;
(3) DAGGER: one dagger shaped like a cat claw in gold and plum, with a heart gem, standing straight UP, handle at the bottom;
(4) BOW: a golden bow whose tips curl like cat tails, with rainbow wraps on the grip, standing straight UP, grip in the middle;
Row 2:
(5) STAFF: a golden staff topped with a big sun-yellow star holding a tiny rainbow, yarn ribbons trailing, standing straight UP, handle at the bottom;
(6) HAT: a coral wizard-adventurer hat with a golden band, a star pin and a curled tip, seen from the side facing RIGHT, as if worn on a head;
(7) SCARF: a rainbow-striped knitted scarf with golden tassels and a star brooch, wrapped as a loop with one end hanging, seen from the side facing RIGHT;
(8) BAG: a golden-trimmed coral backpack shaped like a little treasure chest with a cat-face lock, seen from the side facing RIGHT, as if worn on a back.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game item art, no digital gradients, no airbrush, no glow, child-friendly.

SHEET LAYOUT: a clean sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the items in an invisible grid of 4 columns by 2 rows, every cell the same size, one item per cell, centered, with wide empty magenta gaps so no two items touch. No text, no letters, no symbols, no grid lines, no borders, no shadows.
```
→ `gear_{…}_3.png`

## 3. ไอคอนช่องที่ไม่เห็นบนตัว — `sheet_gear_icons.png` (4 × 3 · สัดส่วน 4:3)
```
Create a game icon sheet of 12 separate equipment icons for a small cartoon kitten adventurer, matching the art style of the reference sheet exactly. Each icon is one item alone, centered, front three-quarter view, chunky simple shape, readable at 48 px.

COLUMNS (same order in every row): (1) SHIRT / tunic, (2) pair of SHOES / boots, (3) pair of GLOVES, (4) collar BELL.
ROWS = three quality tiers of the same four items:
Row 1 (common): a cream knitted sweater; plain brown cloth boots; cream knitted mittens; a small brass bell on a red ribbon.
Row 2 (rare): a teal padded adventurer's vest with pockets; teal leather boots with yellow laces; teal fingerless gloves with paw pads; a silver bell with a teal gem on a plum ribbon.
Row 3 (legendary): a golden-trimmed coral tunic with a star emblem; golden winged boots; rainbow-striped gloves with golden cuffs; a golden bell shaped like a cat face with a rainbow ribbon.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game icon, no digital gradients, no airbrush, child-friendly.

SHEET LAYOUT: a clean sheet on a perfectly flat solid magenta background (#FF00FF) filling the entire image. Arrange the icons in an invisible grid of 4 columns by 3 rows, every cell the same size, one icon per cell, centered, with wide empty magenta gaps so no two icons touch. No text, no letters, no symbols, no grid lines, no borders, no shadows.
```
→ `icon_{shirt|shoes|gloves|bell}_{1|2|3}.png`

## 4. ปุ่มก้อนไหมพรม — `ui_yarn_ball.png` (ภาพเดียว · สี่เหลี่ยมจัตุรัส 1:1)
```
Create a single game UI icon: a round, plump ball of coral-red yarn for a cute cat adventure game, slightly squishy and friendly, with clearly visible wound yarn strands crossing over the ball, a small loose yarn end curling out at the bottom right, and a tiny highlight on the top left. No knitting needles, no face, no text. Centered, filling about 80% of the image.

STYLE: bold dark ink outlines (#33291F), filled with vibrant saturated colored pencil strokes clearly visible at a diagonal angle, single flat shadow tone, saturday-morning-cartoon energy, flat 2D game icon, no digital gradients, no airbrush, child-friendly.

LAYOUT: one icon on a perfectly flat solid magenta background (#FF00FF) filling the entire image. No text, no letters, no symbols, no borders, no shadows on the background.
```
→ `ui_yarn_ball.png` (ใช้กับปุ่มถักหน้าหลัก + หัวหน้าเลือกช่อง · เกมทำอนิเมชันขยับ/เด้งเอง ไม่ต้องวาดหลายเฟรม)
