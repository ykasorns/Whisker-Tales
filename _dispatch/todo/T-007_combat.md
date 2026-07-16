# T-007: combat engine base
Module: combat | Priority: P0 | Owner: Sonnet | Depends: T-002,T-003

## Goal
auto-attack ตามค่า Speed, ระบบ HP/ATK/Luck, crit, ผลแพ้ชนะ, XP drop — GDD §4

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatEngine.start(List<Monster>) / tick(dt) / Stream<CombatEvent>

## Acceptance Criteria
- [ ] จำลองสู้จบใน unit test โดยไม่มี UI
- [ ] มอนแพ้ emit event defeated (ไม่มี logic เลือด/gore)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
