# T-023: cloud sync
Module: save_cloud | Priority: P1 | Owner: Sonnet | Depends: T-022

## Goal
Game Center (iOS) / Play Games Services (Android) ผ่าน games_services, conflict rule: total_runs → goldfish → updated_at

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CloudSync.sync() -> SyncResult

## Acceptance Criteria
- [x] conflict ทุก case มี test
- [x] ไม่มี network = เล่น offline ได้ปกติ ไม่ block
- [x] ไม่แตะ personal data ใดๆ นอก platform service

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
conflict rule เปลี่ยนเป็น **`idle.cleared_page` → PowerScore → `updated_at`** (CONTRACT §4.6) แทน total_runs → goldfish · `clock.max_seen_utc` = max ของสองฝั่งเสมอ · `daily` ใช้ของฝั่งที่ `date_key` ใหม่กว่า (ถ้าเท่ากันใช้ `ads_total`/`fish_pulls` ที่มากกว่า — กันรีเซ็ต quota ด้วยการสลับเครื่อง) · test: 2 เครื่องนาฬิกาต่างกัน ไม่ได้รางวัลออฟไลน์ซ้ำ · Depends เพิ่ม T-033

---
## Amendment D-017 (2026-10-19)
**Android / Google Play อย่างเดียว** — ตัดทุกอย่างที่เป็น iOS (Game Center, App Store Privacy Label, ATT, build iOS) · cloud = Play Games Services · IAP = Google Play Billing

## ผล (2026-10-22, Opus) — D-025
- wt_core: `save/save_merge.dart` (`mergeSaves`: หน้า → พลัง → updated_at · clock max · daily วันใหม่กว่า/โควต้ามากกว่า · entitlements รวม), `save/cloud_store.dart` (`CloudStore` seam + `NoCloudStore` ค่าเริ่มต้น), `core/cloud_sync.dart` (`CloudSync.sync()` ตอน boot / `push()` ตอนออก, เส้นตายรวม, ไม่ทับคลาวด์ที่ไปไกลกว่า, rollback ถ้าเซฟคลาวด์ใช้ไม่ได้) · เซฟเพิ่ม `profile.power` · `GameSaver.capture(asSeen: false)` ดูเซฟโดยไม่ปิดหน้าต่างออฟไลน์
- app: `PlayCloudStore` (games_services 4.1.1, slot `whisker_tales_save`), boot sync ก่อนขึ้นจอ, push ตอน pause · Android: `pgsProjectId` → resValue + meta-data APP_ID + `PlayGamesSdk.initialize` เฉพาะตอนมี id

**Test** wt_core 273 (+14: conflict ทุกกรณี, ไม่มีคลาวด์/อ่านไม่ได้/ขยะ/ช้า = เกมไม่เปลี่ยน, เซฟคลาวด์ที่ไม่เข้าข้อมูล = rollback, 2 เครื่อง: ไกลกว่าชนะ, ออกจากแอปไม่ทับคลาวด์ที่ไปไกลกว่า, นาฬิกาต่างกันไม่ได้ออฟไลน์ซ้ำ, โควต้า/ของที่ซื้อตามไปอีกเครื่อง) · app 13 · analyze 0 · APK build ผ่าน

**ข้อสังเกต**
- ปิดไว้จนกว่าจะใส่ project id และตรวจนโยบาย Families เรื่อง Play Games Services (D-025 ข้อ 6)
- ทดสอบบนเครื่องจริงต้องมี PGS project + ผูก SHA-1 ของ signing key ใน Play Console

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ ทุก AC มี test (`cloud_sync_test.dart` 14 tests) · cloud ปิดอยู่จนกว่าจะตั้ง `pgsProjectId` → อยู่ใน RELEASE_CHECKLIST
