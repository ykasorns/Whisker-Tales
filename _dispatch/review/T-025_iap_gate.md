# T-025: IAP + parental gate
Module: iap_gate | Priority: P1 | Owner: Sonnet | Depends: T-021,T-022

## Goal
parental gate (โจทย์สุ่มใหม่ทุกครั้ง เด็กเล็กผ่านไม่ได้) + in_app_purchase cosmetic 3 SKU + restore purchases — GDD §12

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
IapService.purchase(sku) / ParentalGate.challenge() -> bool

## Acceptance Criteria
- [x] เข้าหน้าซื้อโดยไม่ผ่าน gate = เป็นไปไม่ได้ (test ทุก entry point)
- [~] restore ทำงานทั้ง 2 platform
- [x] ไม่มี SKU ที่กระทบ gameplay

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
เพิ่ม SKU 'ถอดโฆษณา' เป็น **entitlement flag `no_ads` อย่างเดียว** — ห้ามผูกรางวัลแทนโฆษณาจนกว่า YK ตอบ GDD v0.4 §17 Q8 · parental gate ใช้ซ้ำสำหรับแก้ age band (T-040)

## Amendment D-003 (2026-10-12)
- SKU "ถอดโฆษณา" = **Supporter Pack** (D-003): ปลดธีม cosmetic + ช่อง preset อุปกรณ์ + ตั้ง entitlement `no_ads` → ซ่อนปุ่มโฆษณาทุกจุด **ไม่ให้รางวัลแทน** · ห้ามมีไข่/ปลาทอง/ไหมพรมใน SKU

---
## Amendment D-017 (2026-10-19)
**Android / Google Play อย่างเดียว** — ตัดทุกอย่างที่เป็น iOS (Game Center, App Store Privacy Label, ATT, build iOS) · cloud = Play Games Services · IAP = Google Play Billing

## ผล (2026-10-21, Opus) — D-023, D-024
- `src/iap/`: `ParentalGate` (โจทย์คูณเป็นตัวหนังสือ ไทย/อังกฤษ, `GatePass` 10 นาที), `IapCatalog` (iap.json, validator ไม่รับของ gameplay), `IapStore` seam + `UnavailableIapStore` (ค่าเริ่มต้น ไม่ขาย/ไม่แจก), `IapService` (purchase/restore ต้องมี pass · deliver ครั้งเดียว ไม่ต้องผ่าน gate · entitlements save) · `noAdsProvider` มาจากของที่ซื้อ
- app: `PlayIapStore` (in_app_purchase, ฟังตั้งแต่ boot, acknowledge ทุกชิ้น, pending/canceled/error), ร้าน: gate (แป้นตัวเลข) → sheet ราคาจาก Play + กู้คืน · ข้อความ Supporter ไม่สัญญาเกินจริง
- D-024 (YK): ชุดประจำคลาส — ตัดระบบแปะอุปกรณ์บนตัว, ตู้เสื้อผ้า → สมุดสะสม, ร้านขาย Supporter Pack อย่างเดียว

**Test** wt_core 259 · app 13 (gate ทุกทางเข้า: เปิดร้าน = gate ก่อน, ผิด = ข้อใหม่, ปิด gate = ไม่มีร้าน, ซื้อแล้วโฆษณาหาย, สแกนว่า ShopSheet/purchase อยู่หลัง openShop เท่านั้น) · analyze 0

**ข้อสังเกต**
- restore = Android อย่างเดียว (D-017) · ซื้อจริงทดสอบได้เมื่อสร้าง `supporter_pack` (non-consumable) ใน Play Console + อัปโหลดขึ้น testing track
- ไม่มีการตรวจใบเสร็จฝั่ง server (ไม่มี backend) — ยอมรับสำหรับ cosmetic/no_ads
