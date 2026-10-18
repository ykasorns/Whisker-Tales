# T-045: wardrobe (styles, chosen look, collection)
Module: wardrobe | Priority: P1 | Owner: Sonnet | Depends: T-036,T-022
> D-004 · spec: GDD v0.5 · contract v2.1

## Goal
ตู้เสื้อผ้าตาม GDD v0.5 §4.2: ถักได้แบบใหม่ครั้งแรก → ปลดถาวร · เลือกหน้าตาต่อช่องแยกจากของที่ให้พลัง · สมุดสะสม (ยังไม่ได้ = เงาดำ) · แบบจาก IAP ใช้ระบบเดียวกัน · อาวุธแสดงแบบของคลาสปัจจุบัน

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
Wardrobe.unlocked / unlock(styleId) / choose(slotId, styleId|null) / lookFor(slotId, classId) -> styleId

## Acceptance Criteria
- [ ] รีไซเคิลของแล้วหน้าตายังปลดอยู่
- [ ] หน้าตาไม่มีผลต่อ stat (test)
- [ ] เปลี่ยนคลาสแล้วอาวุธเปลี่ยนเป็นแบบของคลาสนั้นอัตโนมัติ
- [ ] save/restore (Save v3 `wardrobe`)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
