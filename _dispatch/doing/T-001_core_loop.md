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

## Progress note (สถานะ: ยังอยู่ doing/ ไม่ผ่านเข้า review/)
**ทำแล้ว (hand-scaffold, เขียนไฟล์ตรง ไม่ได้รัน flutter tooling):**
- `packages/wt_core/` — pubspec.yaml (dependency ตาม §5), analysis_options.yaml, `lib/wt_core.dart` (barrel), `lib/src/core/layout.dart` (AppLayout interface ตามการ์ด), `lib/src/{encounter,combat,items,talents,meta,ui,save,audio}/` (โฟลเดอร์ว่างรอ task ถัดไป), `test/core/layout_test.dart`
- `packages/wt_mode_story/` — pubspec.yaml (path dep กลับไป wt_core), `lib/` ว่าง รอ T-031
- `app/` — pubspec.yaml (path dep ทั้งสอง package, l10n/localizations ปล่อยว่างให้ T-004), analysis_options.yaml, `lib/main.dart` (ต่อ AppLayout จริงในเลย์เอาต์ 60/40), `lib/modes.dart` (stub registerModes() รอ T-002/T-031), `lib/l10n/` โฟลเดอร์ว่างรอ T-004
- `melos.yaml` (root), `.gitignore` อัพเดตให้ตรง path ใหม่

**ยังไม่ผ่าน / verify ไม่ได้ (log ไว้ที่ BLOCKED.md):** เครื่องนี้ไม่มี Flutter SDK/Xcode/Android SDK
- ไม่ได้ generate `app/android/`, `app/ios/` (native project ต้องมาจาก `flutter create` เท่านั้น)
- ไม่ได้รัน `flutter pub get` — ไม่ยืนยัน dependency version resolve
- ไม่ได้รัน `flutter analyze` / `flutter test` — ไม่ยืนยัน 0 issue และ test เขียวจริง

**ข้อเสนอ:** ติดตั้ง toolchain แล้วรัน `flutter create --platforms=ios,android .` ใน `app/`, ตามด้วย `flutter pub get && flutter analyze && flutter test` ทั้ง workspace — ผ่านครบค่อยย้ายเข้า `review/`
