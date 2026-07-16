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
