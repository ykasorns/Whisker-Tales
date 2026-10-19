# T-023: cloud sync
Module: save_cloud | Priority: P1 | Owner: Sonnet | Depends: T-022

## Goal
Game Center (iOS) / Play Games Services (Android) ผ่าน games_services, conflict rule: total_runs → goldfish → updated_at

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CloudSync.sync() -> SyncResult

## Acceptance Criteria
- [ ] conflict ทุก case มี test
- [ ] ไม่มี network = เล่น offline ได้ปกติ ไม่ block
- [ ] ไม่แตะ personal data ใดๆ นอก platform service

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
conflict rule เปลี่ยนเป็น **`idle.cleared_page` → PowerScore → `updated_at`** (CONTRACT §4.6) แทน total_runs → goldfish · `clock.max_seen_utc` = max ของสองฝั่งเสมอ · `daily` ใช้ของฝั่งที่ `date_key` ใหม่กว่า (ถ้าเท่ากันใช้ `ads_total`/`fish_pulls` ที่มากกว่า — กันรีเซ็ต quota ด้วยการสลับเครื่อง) · test: 2 เครื่องนาฬิกาต่างกัน ไม่ได้รางวัลออฟไลน์ซ้ำ · Depends เพิ่ม T-033

---
## Amendment D-017 (2026-10-19)
**Android / Google Play อย่างเดียว** — ตัดทุกอย่างที่เป็น iOS (Game Center, App Store Privacy Label, ATT, build iOS) · cloud = Play Games Services · IAP = Google Play Billing
