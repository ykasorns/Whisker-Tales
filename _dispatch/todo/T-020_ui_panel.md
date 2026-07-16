# T-020: village hub
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-021

## Goal
หน้าหมู่บ้าน: เลือกแมว, ร้านปลดล็อก, ร้าน cosmetic, ปุ่มออกผจญภัยใหญ่

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
VillageScreen

## Acceptance Criteria
- [ ] flow ครบ: เปิดแอป → หมู่บ้าน → run → กลับ
- [ ] ปุ่มไปหน้า IAP ผ่าน parental gate เท่านั้น

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- เมนูโหมดในหมู่บ้าน build จาก ModeRegistry ตาม manifest.order — hub ห้ามรู้จักโหมดแบบ hardcode
- โหมด enabled:false/ยังไม่ unlock → การ์ดล็อก 🔒 ตาม spec §4
