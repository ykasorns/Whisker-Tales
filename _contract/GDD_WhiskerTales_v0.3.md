# Game Design Document — "Whisker Tales" 🐱📖

**Version:** 0.3 (Approved Baseline)
**วันที่:** 5 กรกฎาคม 2026
**สถานะ:** ⛔ **Superseded by GDD v0.4 (2026-10-12, D-002)** — ใช้เป็น spec ของ**โหมดนิทานผจญภัย** (v0.4 §9) เท่านั้น · ข้อห้าม §12 ถูกแก้ใน v0.4 header
**Advisor:** Fable 5 | **Orchestrator:** Opus | **Coder:** Sonnet

> **Changelog v0.1 → v0.2**
> 1. เปลี่ยนชื่อเกม Whisker Quest → **Whisker Tales** (เข้ากับธีมหนังสือนิทานสีไม้)
> 2. Run length ปรับเป็น **3–5 นาที** (nodes ลดเหลือ 8–10/biome)
> 3. Node Map Preview ย้ายเป็น **floating layer โซนบนของจอ** (ม้วนกระดาษโปร่งแสง)
> 4. เพิ่ม **Talent System** (สายตี/สายหลบ/สายเวท) — สถาปัตยกรรมรองรับตั้งแต่ MVP
> 5. ยืนยันภาษา TH + EN ตั้งแต่ MVP
> 6. ยืนยัน rating 4+/Everyone ปกติ **ไม่สมัคร** Apple Kids Category
> 7. **Cloud save เป็นเป้าหมายตั้งแต่ MVP** (platform-native)
> 8. Concept ลายเส้นแมวโมจิ 3 แบบ → ดูไฟล์ `mochi_style_concepts.html` ประกอบ
>
> **Changelog v0.2 → v0.3**
> 9. ✅ ล็อกลายเส้น **แบบ B — การ์ตูนสีไม้** เป็น art style หลักของเกม
> 10. เพิ่มฟีเจอร์อนาคต **"Mochi Studio"** (ผู้เล่นวาด/ระบายสีสกินเองจากเทมเพลท) ลง roadmap

---

## 1. Vision Statement

เกม roguelite แนวตั้งบนมือถือ เล่นมือเดียว ตัวเอกเป็นแมวน้อยผจญภัยในโลกแฟนตาซีสไตล์ **ภาพวาดสีไม้บนกระดาษ** — เด็ก 5 ขวบเล่นจบ run ได้ด้วยตัวเอง ผู้ใหญ่เล่นฆ่าเวลาแล้วติดเพราะ build synergy + talent build

**One-liner:** "หนังสือนิทานสีไม้ที่เล่นได้ — ง่ายพอให้เด็กยิ้ม ลึกพอให้ผู้ใหญ่เล่นซ้ำ"

### Design Pillars
1. **One Thumb, One Run** — ทุก interaction ทำได้ด้วยนิ้วโป้งเดียวในโซนล่าง 40%
2. **Fail Forward** — ตายทุกครั้งได้อะไรกลับไปเสมอ ไม่มี run สูญเปล่า
3. **Two-Layer Depth** — เด็กเล่นชั้นผิว ผู้ใหญ่เล่นชั้นลึก (synergy + talent)
4. **Paper is Alive** — ทุกอย่างบนจอดูเหมือนวาดด้วยมือบนกระดาษจริง

---

## 2. Target Audience & Platform

| หัวข้อ | รายละเอียด |
|---|---|
| อายุ | ขั้นต่ำ 5 ขวบ ออกแบบให้เล่นสนุกทุกวัย |
| Rating | **App Store 4+ / Play Everyone (rating ปกติ ไม่สมัคร Kids Category)** — แต่ยังยึด Families Policy เป็น baseline ออกแบบ |
| Platform | iOS + Android |
| Orientation | Portrait เท่านั้น |
| Session length | **1 run = 3–5 นาที** — sweet spot ของการเล่นระหว่างรอ/พักสั้น |
| ภาษา | **ไทย + อังกฤษ ตั้งแต่ MVP** (เกมแทบไม่พึ่งตัวหนังสือ ต้นทุน localize ต่ำ) |
| Monetization | Free + IAP (cosmetic เท่านั้น) + Parental Gate |
| Save | **Local + Cloud save ตั้งแต่ MVP** (Game Center / Play Games Services) |
| Engine | Flutter + Flame |

---

## 3. Core Gameplay Loop

### 3.1 Macro Loop (Meta)
```
หมู่บ้านแมว (Hub)
  → เลือกแมว + เครื่องประดับ
  → ออกผจญภัย (Run 3–5 นาที)
  → ชนะบอส หรือ ตาย
  → กลับหมู่บ้านพร้อมปลาทอง 🐟
  → ปลดล็อก: แมวใหม่ / relic เริ่มต้น / cosmetic / อัพเกรดหมู่บ้าน
  → ออก run ใหม่
```

### 3.2 Micro Loop — Side-view Encounter Runner
- แมวยืน**ฝั่งซ้าย** เดินไป**ทางขวา**อัตโนมัติ ฉากเลื่อน parallax กระดาษหลายชั้น
- เดินจนเจอ **Encounter Node** → หยุด → interact → เดินต่อ
- **1 biome = 8–10 nodes** จบด้วย Boss (คุม run ให้อยู่ใน 3–5 นาที)
- Pacing เป้าหมาย: combat ~20–30 วิ/ครั้ง, event/shop ~10–15 วิ, boss ~45–60 วิ

### 3.3 Encounter Types
| Type | สัดส่วน | รายละเอียด |
|---|---|---|
| ⚔️ Combat | ~50% | สู้มอน 1–3 ตัว ได้ปลาทอง + XP + บางครั้ง drop relic |
| 🎁 Treasure | ~10% | หีบสมบัติ / หีบปริศนา (เสี่ยงเจอ mimic น่ารัก) |
| ❓ Event | ~15% | เหตุการณ์เลือกตอบ 2 ทาง สื่อด้วยรูปภาพ ไม่พึ่งตัวหนังสือ |
| 🏕️ Campfire | ~10% | เลือก 1: ฟื้น HP 50% **หรือ** อัพเกรด item |
| 🛒 Shop | ~10% | ร้านนกฮูก ใช้ปลาทองใน run |
| 🔱 Fork | ~5% | ทางแยกเสี่ยงมาก-ได้มาก vs ปลอดภัย |

### 3.4 Node Map Preview — Floating Layer (ปรับใหม่)
- แสดงเป็น **ม้วนกระดาษโปร่งแสงลอยอยู่ขอบบนของ game viewport** (โซนบน 60%)
- เห็น node ถัดไป 2–3 จุดเป็นไอคอนบนเส้นทางวาดดินสอ node ปัจจุบันมีหมุดแมว 🐾
- โปร่งแสง ~85% ไม่บังฉาก / แตะเพื่อขยายดูทั้งเส้นทาง แตะอีกทีเพื่อย่อ (ปุ่มขยายอยู่ในระยะนิ้วโป้งไม่จำเป็น — เป็น optional interaction เพราะดูเฉยๆ ก็เล่นได้)
- ผลพลอยได้: โซนล่าง 40% ใน state เดินทาง โล่งขึ้น → ใช้พื้นที่กับปุ่มเร่ง + กระเป๋า + ปุ่ม talent ได้เต็มที่

---

## 4. Combat System — Semi-Turn-Based

### 4.1 โครงสร้าง
- แมวซ้าย มอนขวา (side-view ต่อเนื่องจากโหมดเดิน ไม่มี transition ตัดฉาก)
- **Auto-attack:** ตีเบาอัตโนมัติ — เด็กไม่กดอะไรก็ผ่านมอนต้นเกมได้
- **Skill buttons 2–3 ปุ่มใหญ่** ตาม cooldown
- **Dodge:** telegraph เครื่องหมาย **!** ดินสอแดง + เสียงเตือน → แตะหลบทัน = ไม่โดน (skill ceiling ธรรมชาติ)

### 4.2 Stats
❤️ HP | ⚔️ ATK | ⚡ Speed | 🍀 Luck — ไม่มีธาตุแพ้ทาง ไม่มี mana ความลึกอยู่ที่ relic synergy + talent

### 4.3 XP & Level ใน Run (ใหม่ — รองรับ Talent)
- ชนะ combat/event ได้ **XP (ดาวสีไม้ ⭐)**
- 1 run เลเวลอัพได้ **2–3 ครั้ง** (จูนให้พอดี run 3–5 นาที)
- เลเวลอัพ → panel ล่างพลิกหน้าเป็น **Talent Pick**

---

## 5. Talent System 🌟 (ใหม่ — ชั้น depth ที่ 3 สำหรับผู้ใหญ่)

### 5.1 หลักการ
- เลเวลอัพระหว่าง run → เลือก talent 1 จาก 3 ใบ (สุ่มจาก**สายที่ผู้เล่นสนใจ** ถ่วงน้ำหนักตามที่เลือกก่อนหน้า)
- แยกจาก relic ชัดเจน: **relic = ของที่เก็บได้ (สุ่มจากโลก) / talent = ทิศทางที่ผู้เล่นเลือก (สะท้อน playstyle)**
- เด็ก: เลือกการ์ดรูปที่ชอบ = ยังเล่นได้ / ผู้ใหญ่: ตั้งใจปั้นสาย + หา synergy ข้ามระบบ relic×talent

### 5.2 สาย Talent 3 สาย
| สาย | ไอคอนธีม | ตัวอย่าง talent (tier 1 → 3) |
|---|---|---|
| 🐾 **สายตี (Claw)** | อุ้งเท้า/รอยข่วน | ATK+15% → auto-attack มีโอกาสตี 2 ครั้ง → ทุกครั้งที่ crit รีเซ็ต cooldown สกิลตบ |
| 💨 **สายหลบ (Shadow)** | เงา/ควัน | หน้าต่างหลบกว้างขึ้น → หลบสำเร็จได้ speed buff 3 วิ → หลบสำเร็จ สวนกลับอัตโนมัติ |
| ✨ **สายเวท (Whisker Magic)** | หนวดเรืองแสง/ดาว | สกิลเวทดาเมจ+20% → cooldown สกิลทั้งหมด −15% → ร่ายสกิลแล้วทิ้งดาวระเบิดเล็ก |

### 5.3 Cross-System Synergy (จุดขายสำหรับผู้ใหญ่)
ตัวอย่าง: relic "ขนแมวไฟฟ้า ⚡" + talent สายเวท tier 3 = ดาวระเบิดปล่อย spark ลูกโซ่ — ตาราง synergy ข้ามระบบจะออกแบบใน balancing spec แยก

### 5.4 Scope การ implement
- **MVP:** สถาปัตยกรรมเต็มรูปแบบ (XP/level events, talent data schema JSON, UI Talent Pick) + talent สายละ **3 ใบ** (รวม 9)
- **v1.1:** ขยายเป็นสายละ 6–8 + cross-synergy เพิ่ม + meta-unlock talent ใหม่ด้วยปลาทอง
- Schema ออกแบบให้เพิ่ม talent ได้โดย**ไม่แตะโค้ด** (data-driven จากไฟล์ JSON) — Sonnet implement ครั้งเดียว เพิ่ม content ได้เรื่อยๆ

---

## 6. Item & Synergy System

### 6.1 ประเภท
- **Relic (ถาวรใน run):** แถวไอคอนเล็กขอบจอ — ที่มาของ synergy
- **Potion:** ถือได้ 2 ขวด
- **Cosmetic (meta):** ไม่มีผลเกมเพลย์ (จุดขาย IAP)

### 6.2 Synergy Matrix ตัวอย่าง (MVP มี relic 15 ชิ้น / synergy ≥ 6 คู่)
| Relic A | Relic B | Combo |
|---|---|---|
| ขนแมวไฟฟ้า ⚡ | กระดิ่งสะท้อน 🔔 | spark ลูกโซ่ใส่มอนข้างเคียง |
| ปลาย่างหอม 🐟 | ผ้าพันคออุ่น 🧣 | heal หลังสู้ ×2 |
| กรงเล็บเงา 🌙 | นมสายฟ้า 🥛 | crit แล้ว attack ถัดไปเร็วขึ้น |

### 6.3 การเลือก
การ์ด 3 ใบเด้งในโซนล่าง — relic ที่ combo กับของที่มี จะมี**เส้นประดินสอเชื่อม**ไปยังไอคอนบนจอ (สื่อ synergy โดยไม่ต้องอ่าน)

---

## 7. Meta-Progression (หมู่บ้านแมว)

| ปลดล็อก | ราคา | ผล |
|---|---|---|
| แมวใหม่ (MVP 2 ตัว) | สูง | สกิลชุดใหม่ + talent affinity ต่างกัน (เช่น แมวเงาเริ่มสายหลบ tier แรกฟรี) |
| Starting Relic Slot | กลาง | เริ่ม run พร้อม relic ที่เลือก |
| อัพเกรดหมู่บ้าน | ต่ำ–กลาง | ตกแต่ง + NPC daily bonus |
| Cosmetics | ปลาทอง / IAP | หมวด ผ้าพันคอ สีขน |

หลักการ: ปลดล็อก "ตัวเลือก" มากกว่า "ตัวเลข" — กัน power creep

---

## 8. Content Scope

### MVP (v1.0)
- Biome 1: **ป่าดินสอสี** — 8–10 nodes + Boss "หมาป่ากระดาษยักษ์"
- แมว 2 ตัว | มอน 5 ชนิด + boss 1
- Relic 15 (synergy ≥ 6 คู่) | Potion 4 | Event 8 แบบ
- **Talent 9 ใบ (3 สาย × 3)**
- หมู่บ้านพื้นฐาน + ร้าน cosmetic
- Cloud save ทำงานทั้ง 2 platform

### Post-launch
- v1.1: Biome 2 "ภูเขาสีเทียน" + แมวตัวที่ 3 + **Talent เต็มระบบ (สายละ 6–8)**
- v1.2: Daily Challenge (seed เดียวทั้งโลก) — retention ผู้ใหญ่
- v1.3: Biome 3 + pet ผู้ช่วย
- v1.4: **Mochi Studio 🖍️** — ผู้เล่นวาด/ระบายสีสกินแมวเองจากเทมเพลท
  - เทมเพลทเป็นโครงเส้นแมว (ท่ามาตรฐานตาม sprite rig) ผู้เล่นระบายสี/เติมลวดลายด้วยแปรงสีไม้/เทียนในแอป
  - ภาพวาดถูก map เข้า body-part regions ของ rig → สกินที่วาดขยับได้เหมือนสกินทางการ
  - **Local-only เด็ดขาด** — ไม่มีระบบแชร์ข้ามผู้เล่น (แชร์เมื่อไหร่ = UGC = ต้องมี moderation + กระทบ policy เกมเด็กทันที) แชร์ได้แค่ screenshot ออกนอกแอปผ่าน parental gate
  - Technical prep ตั้งแต่ MVP: ออกแบบ cat sprite เป็น **layered body-part rig** (ไม่ flatten เป็นภาพเดียว) เพื่อรองรับ skin swap ในอนาคตโดยไม่ rework

---

## 9. Art Direction — สีไม้บนกระดาษ 🎨

### 9.1 กฎเหล็ก
1. พื้นหลังทุกฉาก = texture กระดาษวาดเขียน เห็นเกรนจางๆ
2. ทุก element มีเส้นตัดขอบ + ระบายสีไม้เห็น stroke ไม่เต็มขอบ
3. Effect = เส้นขีดสีไม้ ไม่ใช่ particle ดิจิทัล
4. **Boiling line animation** — สลับเฟรมเส้นวาด 2–3 เวอร์ชัน ให้ภาพ "หายใจ"
5. มอนแพ้ = ตาเวียน 😵 + ควันสีไม้ ไม่มีเลือด

### 9.2 ลายเส้นแมวโมจิ — 3 ทางเลือก (ดู `mochi_style_concepts.html`)
| แบบ | ชื่อ | ลายเส้น | โทน |
|---|---|---|---|
| A | **นิทานก่อนนอน** | สีไม้คลาสสิก เส้นดินสอนุ่ม แรเงาละมุน | อบอุ่น พาสเทล ผู้ปกครองรัก |
| B ✅ | **การ์ตูนสีไม้ (เลือกแล้ว)** | เส้นหมึกหนาชัด + ระบายสีไม้สด | สดใส มีพลัง อ่านง่ายบนจอเล็ก |
| C | **เด็กวาดเอง** | เส้นเทียน/crayon โยกเยก ระบายเลยขอบ | ซน ขี้เล่น จริงใจ |

*(หลังเลือกแล้ว → gen Style Anchor Sheet เต็มรูปแบบจากแบบที่เลือก)*

### 9.3 AI Art Pipeline
1. Task แรก: **Style Anchor Sheet** — โมจิ (หน้าตรง/ข้าง/เดิน/โจมตี), palette 8–10 สี, ฉาก 1, การ์ด 1
2. ทุก prompt อ้าง anchor + image reference เสมอ
3. QA checklist ทุก asset: พื้นโปร่งใส / ขนาด-มุมตรง spec / โทนใน palette
4. เก็บ prompt จริงทุกชิ้นลง **Art Prompt Bible**

---

## 10. UI/UX — Layout 60/40 One-Handed

### 10.1 โซนบน 60% — Game Viewport
- Side-view แมวฝั่งซ้าย ~25% ความกว้างจอ พื้นเดินระดับขอบล่างของโซน
- HUD: ❤️ ซ้ายบน / 🐟 ขวาบน / แถบ XP ⭐ บางๆ ใต้หัวใจ / แถว relic icon เล็ก
- **Node Map ลอย:** ม้วนกระดาษโปร่งแสงขอบบนสุด (ดูข้อ 3.4)

### 10.2 โซนล่าง 40% — "สมุดสเก็ตช์" (transition พลิกหน้ากระดาษ)
| State | เนื้อหา |
|---|---|
| เดินทาง | ปุ่มเร่งความเร็ว + กระเป๋า + ดู talent ที่เลือกแล้ว |
| ต่อสู้ | ปุ่มสกิล 2–3 (Ø ≥ 72pt) + ปุ่มหลบ + ช่องโพชั่น |
| เลือกการ์ด relic | การ์ด 3 ใบเต็มโซน |
| **Talent Pick** | การ์ด talent 3 ใบ พื้นหลังโทนสีตามสาย (แดงตี/ม่วงหลบ/ฟ้าเวท) |
| Event | ภาพสถานการณ์ + ปุ่มเลือกรูปภาพ 2 ปุ่ม |
| Shop/Campfire | รายการของ + ปุ่มยืนยันใหญ่ |

### 10.3 กฎ Accessibility (เด็ก 5 ขวบ)
- ปุ่มสำคัญในรัศมีนิ้วโป้ง / ไม่มีตัวหนังสือเป็นเงื่อนไขการเล่น / ยืนยันก่อนซื้อ-ทิ้งเสมอ / ไม่มี timer นอกฉากสู้

---

## 11. Audio Direction
- BGM acoustic อบอุ่น (ukulele, glockenspiel, เปียโน) โทนหนังสือนิทาน
- SFX foley กระดาษ/ดินสอ + เสียงแมวหลากอารมณ์
- เกณฑ์: "ผู้ปกครองฟังวนได้ไม่รำคาญ"

---

## 12. Monetization & Compliance ⚖️

### 12.1 Free + IAP (Cosmetic-only)
| รายการ | ราคา (ร่าง) |
|---|---|
| ชุดแต่งตัวธีม | $1.99–2.99 |
| แมว cosmetic variant | $2.99 |
| Supporter Pack | $4.99 |

**ห้าม:** loot box, pay-to-win, ads ทุกชนิด, energy system, dark pattern

### 12.2 Parental Gate
Gate ก่อนเข้า IAP/ลิงก์ออกนอกแอป (โจทย์ที่เด็กเล็กทำไม่ได้ สุ่มใหม่ทุกครั้ง) + native store purchase flow

### 12.3 Data & Privacy (แนว COPPA/GDPR-K/PDPA)
- Save: local + **cloud ผ่าน Game Center / Play Games Services** (platform จัดการ identity/consent เอง — เราไม่แตะ personal data โดยตรง ไม่ต้องมี backend เอง)
- ไม่มี 3rd-party analytics ที่เก็บ identifier / ไม่มี social-chat-UGC
- Privacy Policy TH+EN + Data Safety form (Play) + Privacy Nutrition Label (App Store)
- Rating: ยื่น questionnaire ปกติ เป้าหมาย 4+/Everyone — **ไม่สมัคร Kids Category** แต่คง Families-friendly design เป็น baseline (ลดความเสี่ยง policy + ขยายไป Kids ทีหลังได้ถ้าต้องการ)

---

## 13. Technical Overview (รายละเอียดใน GAME_CONTRACT.md)

- **Engine:** Flutter 3.x + Flame — `GameWidget` โซนบน 60% / Flutter UI โซนล่าง 40%
- **State:** Riverpod แชร์ระหว่าง game world ↔ UI panel
- **Save:** local (Hive/Isar) + **cloud sync ผ่าน Game Center (iOS) / Play Games Services (Android)** — ออกแบบ save schema เป็น versioned JSON ก้อนเดียว sync ทั้งก้อน + conflict rule "ความคืบหน้ามากกว่าชนะ"
- **IAP:** `in_app_purchase` official plugin
- **Data-driven content:** relic / talent / event / มอน ทั้งหมดเป็น JSON — เพิ่ม content ไม่ต้องแตะโค้ด
- **Procedural gen:** seed-based node map (รองรับ Daily Challenge)
- **โมดูลแตก task:** `core_loop` / `encounter_gen` / `combat` / `item_synergy` / `talent_system` / `meta_progression` / `ui_panel` / `save_cloud` / `audio` / `iap_gate`
- **Test:** unit test logic ทุกโมดูล + golden test UI panel — รันบน Mac Mini ผ่าน dispatch

---

## 14. คำตอบ Open Questions (ปิดครบจาก v0.1)

| # | คำถาม | คำตอบ |
|---|---|---|
| 1 | ชื่อเกม | ✅ **Whisker Tales** |
| 2 | ภาษา | ✅ TH + EN ตั้งแต่ MVP |
| 3 | Apple Kids Category | ✅ Rating ปกติ 4+ ไม่สมัคร |
| 4 | Cloud save | ✅ เป้าหมายตั้งแต่ MVP (platform-native) |
| 5 | หน้าตาโมจิ | ✅ **แบบ B — การ์ตูนสีไม้** (เส้นหมึกหนา + สีไม้สด) |

---

*เอกสารถัดไปหลัง approve: GAME_CONTRACT.md → AI Art Prompt Bible (จากแบบที่เลือก) → Task Breakdown สำหรับ Opus*
