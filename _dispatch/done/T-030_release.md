# T-030: store readiness
Module: release | Priority: P1 | Owner: Opus+Sonnet | Depends: T-029

## Goal
icon/splash สไตล์แบบ B, privacy policy TH/EN (local+platform cloud save, no tracking), Data Safety form + Privacy Nutrition Label checklist, build script CI สำหรับ Mac Mini

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
scripts/build_release.sh (iOS+Android)

## Acceptance Criteria
- [ ] build release ได้จาก CLI ล้วนบน Mac Mini
- [ ] checklist compliance ครบตาม GDD §12.3
- [ ] rating questionnaire draft พร้อมยื่น 4+/Everyone

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
checklist compliance ตาม **GDD v0.4 §14** (แทน v0.3 §12.3): Privacy Policy TH/EN ใหม่ (ad SDK + age screen) · Play Data Safety (ระบุ ad SDK, ไม่เก็บ ad ID จาก <13) · Play Target audience & content + Families policy + ad SDK อยู่ในรายการ Families self-certified · App Store Privacy Nutrition Label + **ไม่ขอ ATT** · หน้าโชว์อัตรา gacha/ตะกร้า ครบ · ยืนยันว่าไม่มี IAP ใดให้ ไข่/ปลาทอง/ไหมพรม · ยืนยัน policy ปัจจุบันของทั้งสอง store ณ วัน submit

---
## Amendment D-017 (2026-10-19)
**Android / Google Play อย่างเดียว** — ตัดทุกอย่างที่เป็น iOS (Game Center, App Store Privacy Label, ATT, build iOS) · cloud = Play Games Services · IAP = Google Play Billing

---
## ส่งงาน + ตรวจรับ (2026-10-23, Opus) — D-035 → done (ฝั่งโค้ด)
- ✓ build release จาก CLI ล้วน: `scripts/build_release.sh` (test + analyze + appbundle + ตรวจ manifest) — รันจริงบนเครื่องนี้แล้ว → AAB arm64 30.8 MB (ทุก ABI ต้องรอ YK อนุญาตตัวคอมไพล์ใน macOS — RELEASE_CHECKLIST §3)
- ✓ compliance ตาม GDD v0.4 §14 ครบทุกข้อ (ดู D-035 ข้อ 7) · Data safety / Families / target audience ตอบไว้ใน `RELEASE_CHECKLIST.md`
- ✓ rating questionnaire draft (IARC → คาด Everyone / PEGI 3–7) ใน `RELEASE_CHECKLIST.md` §4
- ✓ ไอคอน/splash/กราฟิกร้าน · privacy policy TH/EN (ร่าง) · signing ผ่าน key.properties · targetSdk 36
- ค้างที่ต้องใช้บัญชี YK: keystore, AdMob app+unit, `supporter_pack`, PGS id, host privacy policy, ภาพหน้าจอจากมือถือ, กรอกฟอร์มใน Console → `RELEASE_CHECKLIST.md`
