# T-013: talent effect resolver + cross-synergy hooks
Module: talent_system | Priority: P1 | Owner: Sonnet | Depends: T-012,T-010

## Goal
resolver ผล talent จาก talents.json + hook จุดเชื่อม cross-synergy relic×talent (GDD §5.3)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
TalentSystem.resolve(trigger, ctx) — แชร์ vocabulary เดียวกับ ItemSystem

## Acceptance Criteria
- [ ] talent 9 ใบ MVP ทำงานครบ
- [ ] ตัวอย่าง cross-synergy ไฟฟ้า×เวท tier3 ทำงาน

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
effect ของ talent → buff id ผ่าน BuffEngine (T-008) · cross-synergy = on_event · Depends เพิ่ม T-008
