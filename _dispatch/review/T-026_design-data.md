# T-026: content authoring: JSON ทั้งหมด
Module: design-data | Priority: P0 | Owner: Opus | Depends: T-003

## Goal
เขียน design/data/: relic 15 (synergy ≥6 คู่), talent 9, มอน 5+boss, event 8, XP curve — ตาม GDD §5–§6 + balance เบื้องต้น

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
ไฟล์ JSON ผ่าน validator T-003

## Acceptance Criteria
- [ ] validator ผ่านทุกไฟล์
- [ ] ทุก entry มี name_th + name_en
- [ ] synergy matrix ตรง GDD

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
content ของ**โหมดนิทานผจญภัย**เท่านั้น (relic/talent/event/มอน biome 1) · content ของโหมดหลักอยู่ใน T-043 · effects[] ต้องอ้าง buff id ที่มีใน buffs.json

---
## ส่งงาน/ตรวจรับ (2026-10-25, D-047)
- [x] `design/data/story/`: relic 15, talent 9 (3 สาย × 3 tier), มอน 5 + boss หมาป่ากระดาษ, event 8 แบบ × 2 ทางเลือก, potion 4 และ balance/XP
- [x] ทุก entry ที่ผู้เล่นเห็นมีชื่อและคำอธิบายไทย/อังกฤษ; validator ปฏิเสธข้อความว่าง
- [x] synergy 8 คู่ (ขั้นต่ำ 6) และมี 3 คู่ตาม GDD: ขนไฟฟ้า+กระดิ่ง, ปลาย่าง+ผ้าพันคอ, กรงเล็บเงา+นมสายฟ้า
- [x] effects/cross-synergy/monster/event/potion อ้าง buff id จริงใน `buffs.json`; id ซ้ำ, reference หาย, tier ขาด และจำนวน content ผิดทำให้ boot fail พร้อมชื่อส่วน
- [x] XP จาก route ปกติให้เลือก Talent 2–3 ครั้ง; reward 3 run แรกเต็มแล้ว 25% อ่านจาก JSON ไม่ hardcode
- [x] generator เลือก monster/event id จาก content จริงและจบด้วย `paperwolf`; `eraserking` ยังเป็นบอส idle ที่ปลดล็อกโหมด
- [x] sync script รองรับ `design/data/story/` และ content sync test ตรวจทุกไฟล์
- [x] wt_core analyze + tests 321, story tests 7 และ app analyze + tests 45 ผ่าน
