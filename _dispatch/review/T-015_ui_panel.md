# T-015: HUD
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014

## Goal
หัวใจ/ปลาทอง/แถบ XP ดาว/แถว relic icons บน viewport ตาม GDD §10.1 — มินิมอล ไม่บังเกม

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
HudOverlay widget ฟัง providers

## Acceptance Criteria
- [x] golden test ทุกสถานะ (เลือดเต็ม/ใกล้ตาย/relic 8 ชิ้น)
- [x] ไอคอนอ่านออกบนจอ 5.5 นิ้ว

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Delivery summary (2026-10-25)

- เพิ่ม HUD เหนือ viewport: HP, XP Talent, จำนวน Relic/Talent และสีเตือนเมื่อใกล้ตาย
- แสดงสถานะจริงจาก combat engine เหนือผู้ได้รับผลทั้งโมจิและมอนสเตอร์ รวม stun, poison, burn, frost และบัพผู้เล่น
- Golden ครอบเลือดเต็มและเลือดต่ำพร้อม Relic 8 ชิ้นที่ขนาดหน้าจอเป้าหมาย

### Verification

- Story UI goldens ผ่านทั้งหมด; app tests 54 รายการผ่าน
- `flutter analyze` ที่ `app`: 0 issue
