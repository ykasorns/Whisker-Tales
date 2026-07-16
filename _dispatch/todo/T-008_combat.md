# T-008: skills + cooldown
Module: combat | Priority: P0 | Owner: Sonnet | Depends: T-007

## Goal
ระบบสกิล 2–3 ช่อง ต่อแมว, cooldown, effect ผ่าน resolver กลาง (vocabulary contract §4.5)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatEngine.useSkill(slotIndex)

## Acceptance Criteria
- [ ] กดตอน cooldown = ไม่มีผล ไม่ crash
- [ ] สกิลโมจิ 3 ตัว (ตบ/ขู่ฟ่อ/ม้วนตัว) ทำงานตาม GDD §4.3

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
