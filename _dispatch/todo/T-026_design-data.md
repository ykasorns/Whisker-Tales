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
