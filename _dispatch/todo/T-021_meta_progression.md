# T-021: meta progression
Module: meta_progression | Priority: P1 | Owner: Sonnet | Depends: T-003,T-005

## Goal
ปลาทองถาวร, ตารางปลดล็อก GDD §7, starting relic slot, village level

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
MetaProgression.unlock(id) / canAfford(id)

## Acceptance Criteria
- [ ] ปลดล็อกทั้งหมด data-driven จาก JSON
- [ ] ตายใน run ก็ได้ปลาทอง (Fail Forward test)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
currency ถาวร 4 สกุล (ปลาทอง/ไหมพรม/ไข่/ขนม) + ร้านนกฮูก + ปลดล็อกสกิล/ช่องตามบท · ตัด starting relic slot/village level ออกจากโหมดหลัก (ย้ายไปเป็น meta ของโหมดผจญภัย v1.1) · **ห้ามมี API ใดเพิ่มไหมพรม/ไข่/ปลาทองจาก IAP**
