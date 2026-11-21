# T-028: boss fight: หมาป่ากระดาษยักษ์
Module: combat | Priority: P1 | Owner: Sonnet | Depends: T-009,T-026

## Goal
boss 2 phase, telegraph ชัด, ความยาว 45–60 วิ, แพ้แบบน่ารัก (ตาเวียน+ควันสีไม้)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
ใช้ CombatEngine เดิม + boss pattern จาก monsters.json

## Acceptance Criteria
- [ ] ผู้เล่นไม่กด dodge เลย: ตายที่ phase 2 (ไม่ใช่ phase 1)
- [ ] ผู้เล่นหลบครบ: ผ่านแบบ HP เหลือ >50%

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.2 (D-070, 2026-11-21)
ไม่มีปุ่มหลบ (D-004) · Depends T-009 ตัดออก · Acceptance ใหม่แทนสองข้อเดิม:
- [x] เฟส 2 เริ่มที่เกณฑ์ HP จาก `monsters.json` และให้ buff โกรธครั้งเดียว
- [x] ท่าตีแรงมีภาพเตือน + "!" ก่อนร่ายตาม `telegraph_ms` และตรงกับเวลาของเอนจิน
- [x] ไฟต์ยาว 45 ถึง 60 วินาที
- [x] แมวไม่มี relic/talent แพ้ในเฟส 2 · แมวเก็บของครบชนะโดย HP > 50%
- [x] ตอนแพ้ใช้ภาพ defeated (มีตาเวียนและควันในภาพแล้ว)

## Delivery summary (2026-11-21, Claude)
- `monsters.json` v2: `boss_pattern` (เฟส 2, buff โกรธ, ท่าตีแรง `paper_storm`, telegraph) · `StoryContent` ตรวจและปฏิเสธข้อมูลผิด
- `StoryRunController`: เปลี่ยนเฟสตาม HP บอส, `bossTelegraph` อ่านจาก skill timer ของเอนจิน · แก้บั๊กผล relic/talent หายกับเอนจินจริง (คิว event)
- ฉาก: ท่าเตือน `telegraph_f1/f2` + "!" · บอสแพ้ค้างบนเวทีด้วยภาพ defeated
- เกณฑ์ตรวจกับคลาสอ้างอิงโร้กตาม D-070 ข้อ 6 ถึง 8 (คลาสอื่นส่ง T-029)

### Verification
- `app/test/story_boss_test.dart` (เอนจินจริง 12 seed): แพ้ในเฟส 2, ชนะ HP > 50% ไฟต์มัธยฐาน 46 วินาที, telegraph ครบทุกครั้ง, golden `boss_telegraph` / `boss_defeated`
- wt_core story_content_test เพิ่ม 5 เทสต์ boss_pattern
