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
