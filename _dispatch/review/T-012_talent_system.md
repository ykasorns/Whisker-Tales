# T-012: talent XP/level + pick logic
Module: talent_system | Priority: P0 | Owner: Sonnet | Depends: T-003,T-007

## Goal
XP จาก combat/event, เลเวลอัพ 2–3 ครั้ง/run, สุ่ม talent 3 ใบถ่วงน้ำหนักตามสายที่เลือกก่อนหน้า — GDD §5

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
TalentSystem.gainXp(n) / Stream<LevelUp> / pickOptions() -> List<Talent>

## Acceptance Criteria
- [x] น้ำหนักการสุ่ม: เลือกสายเดิม 2 ครั้ง → ใบสายนั้นโผล่ ≥ 1 เสมอ (test 1000 rolls)
- [x] XP curve จูนได้จาก JSON

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
ขอบเขต = โหมดนิทานผจญภัยเท่านั้น (XP/level ใน run) · โหมดหลักไม่มี talent pick — สาย Claw/Shadow/Magic ย้ายไปเป็นสกิลแมว (T-008)

## Delivery summary (2026-10-25)

- เพิ่ม `TalentSystem` แบบ run-scoped: รับ XP, เก็บ XP คงเหลือ, ปล่อย `LevelUp` stream และรองรับหลายเลเวลจากการรับ XP ครั้งเดียว
- โหลด XP curve จาก `design/data/story/balance.json`; ไม่มีค่าคอนเทนต์ Talent hardcode ในระบบ
- สุ่มตัวเลือก 3 ใบด้วย seeded RNG และถ่วงน้ำหนักตามสายเดิม; เมื่อเลือกสายเดียวกัน 2 ใบ ใบ tier ถัดไปของสายนั้นจะติดตัวเลือกเสมอ
- offer เดิมคงที่จนกว่าจะเลือก และปฏิเสธการเลือกใบที่ไม่ได้เสนอ

### Verification

- `flutter test` ที่ `packages/wt_core`: ผ่านทั้งหมด 335 tests
- `flutter analyze` ที่ `packages/wt_core`: 0 issue
- test เฉพาะระบบ Talent ครอบ XP, stream, stable offer, invalid input และ 1,000 seeded rolls

### Notes

- ระบบนี้อยู่ใน Story Challenge เท่านั้นตาม Amendment v2.0 และยังไม่เปิดโหมด Story ใน manifest ระหว่างที่ T-014–T-020 ยังพักไว้
