# T-017: combat panel
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-014,T-008,T-009

## Goal
ปุ่มสกิล Ø≥72pt + วง cooldown, ปุ่มหลบ, ช่องโพชั่น 2 — สื่อทุกอย่างด้วยไอคอน

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatPanel ฟัง CombatEngine streams

## Acceptance Criteria
- [ ] กดได้ด้วยนิ้วโป้งเดียวทุกปุ่ม (hit area test)
- [ ] telegraph '!' sync กับ dodge window

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
