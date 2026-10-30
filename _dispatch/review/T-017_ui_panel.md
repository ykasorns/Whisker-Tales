# T-017: combat panel
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-014,T-008,T-009

## Goal
ปุ่มสกิล Ø≥72pt + วง cooldown, ปุ่มหลบ, ช่องโพชั่น 2 — สื่อทุกอย่างด้วยไอคอน

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatPanel ฟัง CombatEngine streams

## Acceptance Criteria
- [x] กดได้ด้วยนิ้วโป้งเดียวทุกปุ่ม (hit area test)
- [x] telegraph '!' sync กับ dodge window

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.1 (D-004, 2026-10-18)
ไม่มีปุ่มสกิล/หลบ (idle ล้วน) → แสดงไอคอนสกิลพร้อม cooldown วงกลมแบบดูอย่างเดียว · ใช้ทั้งโหมดหลักและโหมดท้าทายนิทาน

## Delivery summary (2026-10-25)

- ทำตาม Amendment v2.1: ตัดปุ่มสกิล/หลบและ telegraph interaction ออกจาก Story panel เพราะต่อสู้อัตโนมัติเต็มรูปแบบ
- แสดงสกิลเป็นวง cooldown อ่านอย่างเดียวจาก `UnitView.skills`; ไม่มี GestureDetector ครอบวงสกิล
- combat, status และผล Talent/Relic ใช้ stream/state จาก combat engine จริง

### Verification

- Widget test ตรวจค่าคูลดาวน์และยืนยันว่าไอคอนสกิลกดไม่ได้
- Golden combat + app tests 54 รายการผ่าน
