# T-003: data loader + schema validation
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-002

## Goal
โหลด design/data/*.json (relics/talents/monsters/events) ตอน boot + validate ตาม schema §4 ของ contract, fail-fast พร้อม error message ระบุไฟล์/field

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
class ContentRepository { Future<void> loadAll(); List<Relic> relics; ... }

## Acceptance Criteria
- [ ] JSON ผิด schema → throw พร้อมชื่อ field
- [ ] test ครอบ: ไฟล์ดี/ไฟล์พัง/field หาย
- [ ] schema_version ไม่ตรง → error ชัดเจน

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
loader + validator ต้องรองรับไฟล์ v2: `buffs.json` (CONTRACT §4.7), `gear_slots.json` + affix pools, `pets.json`, `research.json`, `pages.json` และ `design/balance/idle_balance_v1.json` (ค่าที่ขึ้นต้น `ASSUMPTION_` ต้องโหลดได้ปกติ) · validate cross-ref: ทุก `effects[]`/skill อ้าง buff id ที่มีจริง · schema ละเอียดของไฟล์ใหม่ Opus กำหนดใน T-043 → T-003 ทำ framework + schema ที่มีแล้วก่อน แล้วเติม schema ตาม T-043
