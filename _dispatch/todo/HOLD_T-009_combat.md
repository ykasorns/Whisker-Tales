# T-009: dodge & telegraph
Module: combat | Priority: P1 | Owner: Sonnet | Depends: T-008

## Goal
telegraph '!' นำหน้าโจมตีหนัก 0.8s, dodge window, หลบสำเร็จ = invincible 0.5s — skill ceiling ตาม GDD §4.1

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatEngine.onTelegraph stream / PlayerInput.dodge()

## Acceptance Criteria
- [ ] timing window test ± 1 frame
- [ ] ไม่กด dodge เลยก็ยังผ่านมอน tier 1 ได้ (เด็ก 5 ขวบ path)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.1 (D-004, 2026-10-18)
**ยกเลิก** — GDD v0.5 §1 idle ล้วน ไม่มีปุ่มหลบ · หลบเป็น stat (T-007) · "!" ก่อนมอนตีเป็นแค่ภาพ (T-042) · อย่า claim card นี้
