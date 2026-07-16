# T-014: ui panel shell + page-flip
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-002,T-004

## Goal
โครง layout 60/40 (GameWidget + panel), panel state routing 6 states ตาม GDD §10.2, transition พลิกหน้ากระดาษ

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
PanelController.show(PanelState) — ฟัง provider จาก core เท่านั้น

## Acceptance Criteria
- [ ] ทุก state สลับได้ golden test ครบ
- [ ] ปุ่มทั้งหมดอยู่ครึ่งล่างของโซน 40% (thumb zone)
- [ ] รองรับ reduced motion

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
