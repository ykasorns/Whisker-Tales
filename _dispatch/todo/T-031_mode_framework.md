# T-031: mode framework + story เป็น plugin แรก
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-002,T-005,T-020,T-022

## Goal
implement ModeRegistry + ModeConformanceTest suite ใน wt_core แล้ว refactor เนื้อหา Story (biome ป่าดินสอสี + boss) ออกเป็น package `wt_mode_story` ที่ implement GameMode เต็มรูปแบบ ตาม MODE_PLUGIN_SPEC §2–§5

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
GameMode / EncounterSource / ModeRegistry.register() ตาม MODE_PLUGIN_SPEC §3

## Acceptance Criteria
- [ ] wt_mode_story ผ่าน ModeConformanceTest ครบทุกข้อ (spec §7)
- [ ] app/lib/modes.dart ลงทะเบียน story 1 บรรทัด — ถอดบรรทัดออกแล้วเกม build ได้ hub ว่าง
- [ ] เกมเพลย์ story เหมือนก่อน refactor ทุกประการ (regression test เดิมผ่านหมด)
- [ ] save เขียนลง modes.story namespace ถูกต้อง

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
