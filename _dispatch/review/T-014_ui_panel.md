# T-014: ui panel shell + page-flip
Module: ui_panel | Priority: P0 | Owner: Sonnet | Depends: T-002,T-004

## Goal
โครง layout 60/40 (GameWidget + panel), panel state routing 6 states ตาม GDD §10.2, transition พลิกหน้ากระดาษ

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
PanelController.show(PanelState) — ฟัง provider จาก core เท่านั้น

## Acceptance Criteria
- [x] ทุก state สลับได้ golden test ครบ
- [x] ปุ่มทั้งหมดอยู่ครึ่งล่างของโซน 40% (thumb zone)
- [x] รองรับ reduced motion

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Delivery summary (2026-10-25)

- เพิ่ม Story Run shell สัดส่วน 60/40 และ routing ครบ 8 สถานะจริง: map, combat, relic, talent, event, shop, campfire และ result
- เปลี่ยนหน้าแผงด้วย page-flip แบบกระดาษ; ปิด animation ทั้ง page-flip และ node map เมื่อระบบเปิด reduced motion
- ปุ่มโต้ตอบทั้งหมดอยู่ในแผงล่าง 40%; viewport ด้านบนเป็นข้อมูลและปุ่มออกเท่านั้น
- Golden test ครบทุกสถานะและจอมือถือกว้างประมาณ 5.5 นิ้ว

### Verification

- `flutter test` ที่ `app`: ผ่าน 54 tests
- `flutter analyze` ที่ `app`: 0 issue
