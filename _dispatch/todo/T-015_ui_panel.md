# T-015: HUD
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014

## Goal
หัวใจ/ปลาทอง/แถบ XP ดาว/แถว relic icons บน viewport ตาม GDD §10.1 — มินิมอล ไม่บังเกม

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
HudOverlay widget ฟัง providers

## Acceptance Criteria
- [ ] golden test ทุกสถานะ (เลือดเต็ม/ใกล้ตาย/relic 8 ชิ้น)
- [ ] ไอคอนอ่านออกบนจอ 5.5 นิ้ว

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
