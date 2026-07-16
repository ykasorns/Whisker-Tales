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
