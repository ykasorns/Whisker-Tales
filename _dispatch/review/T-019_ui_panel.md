# T-019: event/shop/campfire panels
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-006

## Goal
3 panels: event เลือก 2 ทางด้วยรูป, shop นกฮูก, campfire เลือก heal/upgrade — ไม่พึ่งตัวหนังสือ

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
EventPanel/ShopPanel/CampfirePanel

## Acceptance Criteria
- [x] เด็กที่อ่านหนังสือไม่ออกเข้าใจตัวเลือกจากภาพ (icon-first review)
- [x] ยืนยันก่อนใช้ปลาทองเสมอ

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Delivery summary (2026-10-25)

- Event แสดงตัวเลือกสองทางด้วยไอคอนผลลัพธ์, ร้านนกฮูกแสดง potion/ราคา และกองไฟเลือกพักหรืออัปเกรด Relic
- ร้านค้าถามยืนยันก่อนหักปลาทองทุกครั้ง; เงินไม่พอมีข้อความตอบกลับ
- ผล heal, damage, XP, buff, relic choice, potion และ campfire เชื่อมกับ StoryRunController จริง

### Verification

- Widget test ยืนยันว่าร้านไม่หักปลาทองก่อนกดยืนยัน
- Golden event/shop/campfire และ run simulation 50 seeds ผ่าน
