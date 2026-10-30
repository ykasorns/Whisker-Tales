# T-005: RunManager
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-002,T-003

## Goal
implement RunManager: เริ่ม run, เดินหน้า node, จบ run (ชนะ/ตาย), สรุปรางวัลปลาทอง — pacing รองรับ run 3–5 นาที (GDD §3.2)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
RunManager.startRun(catId) / advanceToNextNode() / endRun(RunResult)

## Acceptance Criteria
- [ ] วงจร run เต็มรูปแบบผ่าน unit test
- [ ] ตายกลางทาง = ได้ปลาทองตามสูตร Fail Forward

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- RunManager รับ `EncounterSource` + `WinCondition` จาก GameMode — ห้าม hardcode โครง node list ในตัวเอง (spec §3)
- acceptance เพิ่ม: mock EncounterSource แบบ finite และ infinite ต้องใช้ RunManager ตัวเดียวกันได้

---
## Amendment v2.0 (D-002, 2026-10-12)
RunManager ใช้เฉพาะ **โหมดเสริมแบบ run** (story/endless) — โหมดหลัก idle อยู่ใน `idle_loop` (T-034) ไม่ผ่าน RunManager · pacing 3–5 นาทียังใช้กับโหมดนิทานผจญภัย · ศัตรูในโหมดเสริม scale ตาม PowerScore จาก core

---
## ส่งงาน/ตรวจรับ (2026-10-24, D-046)
- [x] วงจรเต็มเริ่ม run → เดิน → encounter → resolve → จบชนะ/ตาย/ออก ผ่าน `test/core/run_manager_test.dart`
- [x] snapshot คลาส, stats และ Power ของโมจิตอนเริ่ม run; การอัปเกรดด้านนอกไม่เปลี่ยน run ที่กำลังเล่น
- [x] ตายกลางทางยังคำนวณรางวัลจากจำนวน node ที่ผ่าน (Fail Forward)
- [x] GameMode เป็นเจ้าของ `EncounterSource`, `WinCondition`, สูตรรางวัล และ save progress; RunManager ไม่ hardcode เงื่อนไขชนะ
- [x] source แบบ finite และ infinite ใช้ RunManager ตัวเดียวกัน โดยมี test ทั้งสองแบบ
- [x] โควตารางวัลรายวันส่งผ่าน config/result แบบ deterministic และบันทึกโดยโหมด
- [x] `flutter analyze` และ wt_core tests 316 รายการผ่าน; story tests 7 รายการและ app tests 45 รายการผ่าน
