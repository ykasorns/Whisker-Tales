# T-013: talent effect resolver + cross-synergy hooks
Module: talent_system | Priority: P1 | Owner: Sonnet | Depends: T-012,T-010

## Goal
resolver ผล talent จาก talents.json + hook จุดเชื่อม cross-synergy relic×talent (GDD §5.3)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
TalentSystem.resolve(trigger, ctx) — แชร์ vocabulary เดียวกับ ItemSystem

## Acceptance Criteria
- [x] talent 9 ใบ MVP ทำงานครบ
- [x] ตัวอย่าง cross-synergy ไฟฟ้า×เวท tier3 ทำงาน

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
effect ของ talent → buff id ผ่าน BuffEngine (T-008) · cross-synergy = on_event · Depends เพิ่ม T-008

## Delivery summary (2026-10-25)

- เพิ่ม resolver ของ Talent โดยใช้ effect vocabulary และ `StoryEffectResolver` ชุดเดียวกับ ItemSystem
- Talent ทั้ง 9 ใบอ่าน trigger, target, chance และ buff id จาก JSON แล้วส่งผลผ่าน `IBuffEngine`
- cross-synergy `electric_fur` × Magic tier 3 อ่านจาก JSON และทำงานเมื่อเกิด `on_skill`
- รองรับ owner/enemy target อย่างปลอดภัยและใช้ chance roll จาก seeded run context

### Verification

- `flutter test` ที่ `packages/wt_core`: ผ่านทั้งหมด 335 tests
- `flutter analyze` ที่ `packages/wt_core`: 0 issue
- test ตรวจ Talent MVP ครบ 9 ใบ และตรวจไฟฟ้า×เวท tier 3 ว่าใส่ buff ให้เป้าหมายถูกตัว

### Notes

- cross-synergy ถูกเก็บเป็น structured effect แทนข้อความ เพื่อให้ resolver ทำงานจากข้อมูลได้จริง
