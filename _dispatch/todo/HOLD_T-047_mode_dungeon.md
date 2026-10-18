# T-047: dungeon mode (v1.1)
Module: mode_dungeon | Priority: P2 | Owner: Sonnet | Depends: T-031,T-044,T-045
> D-004 · spec: GDD v0.5 · contract v2.1

## Goal
`wt_mode_dungeon` ตาม GDD v0.5 §7: ถ้ำคริสตัลสี (อัญมณี) · โรงปั่นด้าย (หินตีบวก + ไหมพรม) · ห้องสมุดลับ (หนังสือสกิล) · ความยากหลายชั้น · รางวัลเต็ม 3 รอบ/วัน/ดันเจี้ยน หลังจากนั้น 25% · ปลดช่องเสริมได้ — **HOLD จนถึง v1.1**

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
implements GameMode เท่านั้น

## Acceptance Criteria
- [ ] แก้ core = 0 ไฟล์ (นอกจาก vocabulary รางวัลที่ Opus อนุมัติ)
- [ ] ไม่มีระบบ energy/ตั๋วที่เติมตามเวลา

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
