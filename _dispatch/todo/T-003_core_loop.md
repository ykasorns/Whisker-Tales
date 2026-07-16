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
