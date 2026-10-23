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

---
## ส่งงาน/ตรวจรับ (2026-10-23, D-042) — chunk 1 ของ Group B
AC เดิมเขียนก่อน idle pivot ("เกมเพลย์ story เหมือนก่อน refactor" ไม่มีอะไรให้เทียบ) จึงเขียนใหม่และจับคู่ test:
- [x] `ModeRegistry` (เรียงตาม `manifest.order`, id ซ้ำ = error) + `modeRegistryProvider` → `test/modes/mode_registry_test.dart`
- [x] ตัวตรวจ conformance เป็นฟังก์ชันใน `package:wt_core/wt_core_testing.dart` (`checkModeConformance`: manifest, save roundtrip, `next()` depth 0–1000 seed เดิมผลเดิม, รางวัลอยู่ใน vocabulary) → ทดสอบทั้งโหมดดีและโหมดเสีย
- [x] `wt_mode_story`: manifest (`enabled:false`, ปลดเมื่อชนะบอส `eraserking` = บอสบท 1), `StorySave`, source ชั่วคราว (9 สู้ + บอส) ผ่าน conformance → `wt_mode_story/test/story_mode_test.dart`
- [x] ลงทะเบียน 1 บรรทัดใน `app/lib/modes.dart`; ปิด `enabled` อยู่ → `enabledModes` ว่าง เมนูไม่แสดง → `app/test/modes_test.dart`
- [x] `modes.<id>` เข้า/ออก Save v3: เก็บ JSON ดิบจนกว่าโหมดจะขอ, โหมดที่ไม่ได้ลงทะเบียนไม่เสียความคืบหน้า, โหมดที่อ่านเซฟไม่ได้เริ่มใหม่เฉพาะโหมดนั้น; เซฟเดิมในเครื่อง YK ไม่ถูกแตะ (เพิ่มอย่างเดียว) → `game_save_test`
- [x] `wt_mode_story` ใช้ lint `implementation_imports: error` เดิม
- [x] unlock: `ModeUnlockContext` + `isModeUnlocked` (flag / fish_total = ปลาทองที่ถือ / boss_cleared = เคลียร์หน้าสุดท้ายของบทนั้นแล้ว) + `modeUnlockContextProvider`

**ช่องโหว่ของ contract ที่ต้องตัดสินก่อน chunk 2 (ห้ามแก้ interface โดยไม่ผ่าน advisor + D-entry):**
1. ทางแยก: `EncounterSource.next(depth, rng)` เป็นเส้นตรง รับ "ตัวเลือกผู้เล่น" ไม่ได้
2. `IRunManager.startRun(catId)` เก่า — โหมดนิทานต้องรับ snapshot แมวจากโหมดหลัก (StatBlock/PowerScore)
3. AC บอส T-028 อิงปุ่มหลบ (ถูกยกเลิก) → เขียนใหม่เป็นเงื่อนไขพลัง
4. รางวัลเต็ม 3 รอบ/วัน แล้ว 25% → ใช้ GameClock daily reset; `resolveReward` เป็นฟังก์ชันบริสุทธิ์ ต้องส่งจำนวนรอบวันนี้เข้ามา
5. ที่เก็บ content ของโหมด: เลือกที่เดียว (`design/data/story/*.json` + sync script เดิม)
6. balance: หนังสือเล่ม 1 = วัน 12.2 (ขอบล่าง 12) → ต้องเพิ่มรายได้โหมดนิทานใน `headless_player_test` ก่อนกำหนดตัวเลขรางวัล
