# T-011: synergy resolver
Module: item_synergy | Priority: P1 | Owner: Sonnet | Depends: T-010

## Goal
ตรวจคู่ synergy จาก relics.json แล้ว activate combo effect + emit event ให้ UI แสดงเส้นเชื่อม

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
SynergyResolver.activePairs / Stream<SynergyActivated>

## Acceptance Criteria
- [ ] 3 คู่ตัวอย่างใน GDD §6.2 ทำงานครบ
- [ ] ถอด relic (อนาคต) แล้ว combo ดับถูกต้อง

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
