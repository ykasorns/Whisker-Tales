# T-001: repo scaffold + layout constants
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: -

## Goal
สร้าง melos-style monorepo ตาม GAME_CONTRACT §2 (v1.2, D-001): `packages/wt_core/` (workspace package, path dependency จาก `app/`) + `packages/wt_mode_story/` + `app/` — ล็อก dependency ใน pubspec ตาม §5, สร้าง `packages/wt_core/lib/src/core/layout.dart` กำหนด ratio 60/40 จาก safe area เป็น constant แล้ว export ผ่าน barrel `packages/wt_core/lib/wt_core.dart`

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
class AppLayout { static const gameViewportRatio = 0.60; } — อยู่ใน `packages/wt_core/lib/src/core/layout.dart`, re-export จาก `package:wt_core/wt_core.dart`

## Acceptance Criteria
- [ ] โปรเจกต์ build ผ่านทั้ง iOS/Android simulator (จาก `app/`)
- [ ] folder ครบตาม contract §2 (packages/wt_core, packages/wt_mode_story, app/)
- [ ] `app/` อ้างอิง `wt_core` ผ่าน path dependency ใน pubspec เท่านั้น — import ใน `app/` ต้องผ่าน `package:wt_core/wt_core.dart` (บังคับด้วย lint)
- [ ] `flutter test` รันผ่านทั้งจาก `packages/wt_core` และ `app`
- [ ] flutter analyze = 0 issue ทั้งสอง package

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment v1.2 (D-001)
- โครง repo เปลี่ยนจาก single-app `lib/` เป็น monorepo ตาม GAME_CONTRACT §2 ที่แก้แล้ว — ดู DECISIONS.md D-001
