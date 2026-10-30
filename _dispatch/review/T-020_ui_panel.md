# T-020: village hub
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-021

## Goal
หน้าหมู่บ้าน: เลือกแมว, ร้านปลดล็อก, ร้าน cosmetic, ปุ่มออกผจญภัยใหญ่

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
VillageScreen

## Acceptance Criteria
- [x] flow ครบ: เปิดแอป → หมู่บ้าน → run → กลับ
- [x] ปุ่มไปหน้า IAP ผ่าน parental gate เท่านั้น

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.1 (MODE_PLUGIN_SPEC)
- เมนูโหมดในหมู่บ้าน build จาก ModeRegistry ตาม manifest.order — hub ห้ามรู้จักโหมดแบบ hardcode
- โหมด enabled:false/ยังไม่ unlock → การ์ดล็อก 🔒 ตาม spec §4

---
## Amendment v2.0 (D-002, 2026-10-12)
หมู่บ้านเลิกเป็น hub หลัก → hub = หน้าฟาร์ม (T-042) · card นี้เหลือ: เมนู 'ผจญภัย' (การ์ดโหมดจาก ModeRegistry + การ์ดล็อก) + ร้านนกฮูก (สกิล/เพื่อน/cosmetic) · ตัด 'เลือกแมว' ออกจาก MVP ถ้า roster แมวยังเป็น 1 ตัว (Opus ยืนยัน)

## Delivery summary (2026-10-25)

- เปลี่ยนเมนูล่างเป็น Adventure และสร้างการ์ดจาก `ModeRegistry` ตาม order; โหมดปิดหรือยังไม่ปลดล็อกแสดงเป็นการ์ดล็อก
- Story Challenge เปิดใช้งานและปลดเมื่อผ่านบอสบท 1 (`eraserking`); แสดง best depth และจำนวนรางวัลเต็มที่เหลือวันนี้
- flow ผ่านครบ: เปิดแอป → Adventure → เริ่ม Run → ออก/จบ → กลับ Adventure พร้อมบันทึก ModeSave
- IAP เดิมยังเข้าทาง `openShop` ซึ่งเรียก parental gate ก่อนเปิด ShopSheet และมี test บังคับไว้แล้ว

### Verification

- Widget integration test ครบเส้นทาง app → Adventure → run → return
- Mode registration, unlock, parental-gate tests และ app tests 54 รายการผ่าน
