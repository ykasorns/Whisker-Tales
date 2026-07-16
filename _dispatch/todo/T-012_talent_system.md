# T-012: talent XP/level + pick logic
Module: talent_system | Priority: P0 | Owner: Sonnet | Depends: T-003,T-007

## Goal
XP จาก combat/event, เลเวลอัพ 2–3 ครั้ง/run, สุ่ม talent 3 ใบถ่วงน้ำหนักตามสายที่เลือกก่อนหน้า — GDD §5

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
TalentSystem.gainXp(n) / Stream<LevelUp> / pickOptions() -> List<Talent>

## Acceptance Criteria
- [ ] น้ำหนักการสุ่ม: เลือกสายเดิม 2 ครั้ง → ใบสายนั้นโผล่ ≥ 1 เสมอ (test 1000 rolls)
- [ ] XP curve จูนได้จาก JSON

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
