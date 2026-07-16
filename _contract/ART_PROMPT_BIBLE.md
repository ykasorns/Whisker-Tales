# ART_PROMPT_BIBLE.md — Whisker Tales 🎨

**Version:** 1.0 | **Style ล็อกแล้ว:** แบบ B — "การ์ตูนสีไม้" (Bold Ink + Colored Pencil)
**อ้างอิง:** GDD_WhiskerTales_v0.3.md §9 | ใช้คู่กับ GAME_CONTRACT.md

> กฎข้อเดียวที่สำคัญที่สุด: **ทุก prompt ต้องลงท้ายด้วย MASTER STYLE SUFFIX และแนบ Style Anchor image เป็น reference เสมอ** — ไม่มีข้อยกเว้น

---

## 1. Style Definition (ล็อกแล้ว ห้ามดริฟท์)

- เส้นตัดขอบ: หมึก/ดินสอสีเข้ม `#33291F` **หนา มั่นใจ ปิดทุกรูปทรง** (เทียบสัดส่วน: เส้น ≈ 3–4% ของความสูงตัวละคร)
- ระบายภายใน: สีไม้ saturation สูง **เห็น stroke แนวเฉียงชัดเจน** ระบายเกือบเต็มแต่เว้นขอบขาวบางจุดให้รู้ว่าเป็นมือวาด
- เงา: สีทึบชั้นเดียว (โทนเข้มของสีหลัก) ไม่มี gradient ดิจิทัล
- Silhouette ต้องอ่านออกที่ขนาด 64px (ทดสอบย่อทุกตัวละคร)
- พื้นหลังทุก asset ที่เป็นฉาก: มี paper grain / asset ตัวละคร-ไอคอน: พื้นโปร่งใส

## 2. Locked Palette

| ชื่อ | Hex | ใช้กับ |
|---|---|---|
| Ink | `#33291F` | เส้นตัดขอบทุกชิ้น |
| Mochi Orange | `#F6A83C` | ตัวโมจิ, accent หลัก |
| Coral | `#EE6352` | ศัตรู/อันตราย, สายตี, ปุ่ม dodge telegraph |
| Teal | `#3FA7B8` | เวท/น้ำ, สายเวท, UI ปุ่มรอง |
| Lime | `#8CC152` | ธรรมชาติ, heal, ยืนยัน |
| Sun Yellow | `#F9D64E` | XP ดาว, ปลาทอง, ของมีค่า |
| Paper | `#F6F0E1` | พื้นกระดาษทุกฉาก/UI |
| Shadow Plum | `#7A5E8C` | สายหลบ, เงา, กลางคืน |

หลีกเลี่ยง: สี neon, gradient, สีนอก palette (ยกเว้น shade อ่อน/เข้มของสีข้างบน)

## 3. MASTER STYLE SUFFIX (ต่อท้ายทุก prompt)

```
, bold dark ink outlines (#33291F), filled with vibrant saturated colored
pencil strokes clearly visible at diagonal angle, single flat shadow tone,
saturday-morning-cartoon energy, bright playful palette, hand-drawn on
warm cream paper, strong readable silhouette, flat 2D side-scroller game
asset, no digital gradients, no airbrush, transparent background
```
*(สำหรับฉาก/พื้นหลัง เปลี่ยนท่อนท้ายเป็น `visible warm cream paper grain texture background`)*

## 4. Asset Specs & Prompt Templates

### 4.1 ตัวละคร (แมว) — layered rig
| Spec | ค่า |
|---|---|
| Canvas | 1024×1024 → export part layers |
| ท่าที่ต้องมี | idle side / walk (2 เฟรม) / attack / hurt / victory |
| Rig layers | head, ears, body, front-leg, back-leg, tail (แยกไฟล์ — ห้าม flatten ตาม GAME_CONTRACT §5) |

```
PROMPT: cartoon [ลักษณะแมว เช่น chubby orange tabby kitten] game character,
full body side view facing right, [ท่า: neutral idle standing pose],
big friendly eyes, simple round shapes [+ MASTER SUFFIX]
```

### 4.2 มอนสเตอร์
- Canvas 1024×1024 / ต้องมี: idle, attack-telegraph (ท่าเงื้อชัดเจน!), defeated (ตาเวียน 😵)
- กฎ: น่ารักเสมอ ไม่มีเขี้ยวเลือด — "ศัตรู" สื่อด้วยสีโทน Coral/Plum + คิ้วขมวด

```
PROMPT: cute cartoon [ชนิด เช่น grumpy paper wolf cub] fantasy monster,
full body side view facing left, mischievous but adorable, no scary
features, child-friendly [+ MASTER SUFFIX]
```

### 4.3 Relic / Talent / Potion Icons
- Canvas 512×512, วัตถุเดี่ยวกลางเฟรม, อ่านออกที่ 48px
- Talent ใส่กรอบสีตามสาย: ตี=Coral / หลบ=Plum / เวท=Teal

```
PROMPT: single [วัตถุ เช่น glowing electric cat fur tuft] game item icon,
centered, chunky simple shape, thick outline [+ MASTER SUFFIX]
```

### 4.4 การ์ด (relic/talent pick)
- Canvas 768×1024, กรอบการ์ดกระดาษมุมม้วนเล็กน้อย, พื้นที่ล่าง 25% เว้นว่างให้ text layer ของเกม (ห้าม gen ตัวหนังสือ — ใส่จาก l10n)

### 4.5 ฉาก Parallax (ต่อ biome: 4 ชั้น)
| ชั้น | เนื้อหา | Canvas |
|---|---|---|
| L0 sky | ท้องฟ้า+เมฆสีไม้ | 2048×1024, tileable แนวนอน |
| L1 far | ภูเขา/ต้นไม้ไกล (โทนอ่อน) | 2048×1024, tileable |
| L2 mid | ต้นไม้/พุ่มหลัก | 2048×1024, tileable |
| L3 ground | พื้นเดิน | 2048×512, tileable |

```
PROMPT: fantasy pencil forest [ชั้น: distant treeline layer], horizontal
seamless tileable, colored pencil trees in lime and teal tones, drawn on
warm cream paper, soft grain, side-scroller parallax background layer
[+ MASTER SUFFIX ฉบับฉาก]
```

### 4.6 Effects
- ทุก effect = "เส้นขีดสีไม้" ไม่ใช่ particle — gen เป็น sprite sheet 3–4 เฟรม
- ไฟฟ้า = ขีดซิกแซก Yellow/Teal | โจมตี = เส้นโค้ง 3 เส้น Coral | heal = ดาว+ใบไม้ Lime

### 4.7 UI Elements (โซนล่าง "สมุดสเก็ตช์")
- ปุ่มสกิล: วงกลมสีไม้ระบาย + ไอคอนขาวเส้นหนา / กรอบ panel: ขอบกระดาษฉีก/สันสมุด
- ทุกปุ่ม gen 2 state: normal / pressed (เข้มขึ้น + ยุบ 4%)

## 5. Boiling Line Workflow (ทำภาพนิ่งให้มีชีวิต)

1. gen asset หลัก 1 ภาพ → ใช้เป็น reference
2. gen ซ้ำ 2 ครั้งด้วย prompt เดิม + reference เดิม + seed ต่างกัน โดยเพิ่ม `same character same pose, slightly different hand-drawn line jitter`
3. ได้ 3 เฟรมเส้นสั่นต่างกันเล็กน้อย → เล่นสลับ 8 fps = เอฟเฟกต์ "กระดาษหายใจ"
4. ใช้กับ: ตัวละคร idle, มอน idle, ไอคอนบนการ์ด — **ไม่ใช้กับ** UI ปุ่ม (จะกดยาก) และตัวหนังสือ

## 6. QA Checklist (ทุก asset ก่อนเข้า `assets/game/`)

- [ ] เส้นตัดขอบ = `#33291F` (±tolerance เล็กน้อย) หนาสม่ำเสมอ
- [ ] สีอยู่ใน palette §2
- [ ] พื้นโปร่งใสจริง (ตรวจขอบไม่มี halo ขาว)
- [ ] Silhouette test: ย่อ 64px ยังแยกได้ว่าเป็นอะไร
- [ ] ขนาด/มุม/ทิศหันตรง spec §4
- [ ] ไม่มีตัวหนังสือ gen ติดมา
- [ ] บันทึก prompt จริง + seed + วันที่ ลงทะเบียน §8

## 7. Naming Convention

```
{type}_{id}_{variant}_{frame}.png
เช่น cat_mochi_idle_f1.png / relic_electric_fur.png /
mon_paperwolf_telegraph_f2.png / bg_pencilforest_L2.png /
ui_btn_skill_claw_pressed.png
```

## 8. Prompt Register (append-only — ทุกครั้งที่ gen จริง)

| วันที่ | Asset | Prompt เต็ม | Seed/Model | ผ่าน QA |
|---|---|---|---|---|
| — | — | — | — | — |

---

## Task แรกของ pipeline: Style Anchor Sheet

gen ชุดเดียวจบ ใช้เป็น reference ตลอดโปรเจกต์:
1. โมจิ 5 ท่า (§4.1) จาก prompt template + suffix
2. มอน 1 ตัว (paper wolf cub) 3 ท่า
3. ฉากป่าดินสอสี 1 ภาพรวม (ยังไม่แยกชั้น)
4. การ์ด 1 ใบ + ปุ่มสกิล 1 ปุ่ม
→ YK review โทนรวม 1 รอบ → ล็อกเป็น **ANCHOR v1** → ทุก prompt หลังจากนี้แนบภาพจากชุดนี้เสมอ
