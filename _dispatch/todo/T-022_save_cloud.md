# T-022: save local + versioned schema
Module: save_cloud | Priority: P0 | Owner: Sonnet | Depends: T-002

## Goal
Hive local save ตาม schema contract §4.4 + migration framework (bump save_version ต้องมี migration+test)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
SaveService.load()/save()/migrate(from,to)

## Acceptance Criteria
- [ ] kill app กลางทาง = ไม่ corrupt (atomic write)
- [ ] migration v1→v2 ตัวอย่างมี test

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- save schema เริ่มที่ v2: namespace `modes.<id>` (spec §5) — core เก็บ/คืน blob ต่อโหมดโดยไม่ตีความ
- conformance: roundtrip encode/decode ของ ModeSaveState

---
## Amendment v2.0 (D-002, 2026-10-12)
ใช้ **Save v3** (CONTRACT §4.6) (conflict rule ใหม่ implement ใน T-023) · ยังไม่ต้อง migrate (ไม่มี user) แต่ต้องมี test decode v3 · T-022 แค่เก็บ field (`clock`, `daily`, `age`, `entitlements`) — logic merge อยู่ T-023, logic นาฬิกาอยู่ T-033 (ไม่ต้อง depend)
