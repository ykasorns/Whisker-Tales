# T-019: event/shop/campfire panels
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-006

## Goal
3 panels: event เลือก 2 ทางด้วยรูป, shop นกฮูก, campfire เลือก heal/upgrade — ไม่พึ่งตัวหนังสือ

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
EventPanel/ShopPanel/CampfirePanel

## Acceptance Criteria
- [ ] เด็กที่อ่านหนังสือไม่ออกเข้าใจตัวเลือกจากภาพ (icon-first review)
- [ ] ยืนยันก่อนใช้ปลาทองเสมอ

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
