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

## Progress note 2 (2026-10-19)
- `flutter create --platforms=android,ios --org com.whiskertales` ใน `app/` → `app/android/`, `app/ios/` (applicationId / bundle id = `com.whiskertales.whisker_tales` — เปลี่ยนได้ก่อนขึ้นสโตร์) · ลบไฟล์ตัวอย่าง (widget_test, README)
- ✅ `flutter build apk --debug` ผ่าน (`app/build/app/outputs/flutter-apk/app-debug.apk`) · ✅ `flutter test` + `flutter analyze` ผ่านทั้ง wt_core / wt_mode_story / app
- ⚠️ เตือน: plugin `games_services` ใช้ Kotlin Gradle Plugin แบบเก่า — Flutter รุ่นหน้าจะ build ไม่ผ่าน → ต้องอัปเกรดหรือเปลี่ยนตอนทำ T-023
- ❌ iOS: เครื่องไม่มี Xcode เต็ม (มีแค่ Command Line Tools) + ไม่มี CocoaPods → build/รัน iOS ไม่ได้ — YK ต้องติดตั้ง Xcode จาก App Store แล้วรัน `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer` และ `sudo xcodebuild -runFirstLaunch` และติดตั้ง CocoaPods
- ไม่มี Android emulator (AVD) บนเครื่อง → ยังไม่ได้รันบนเครื่องจำลอง · ติดตั้ง APK ลงมือถือ Android จริงได้
- การ์ดยังอยู่ doing/ จนกว่า iOS build ผ่าน

## ส่งงาน (2026-10-19) — D-017: Android อย่างเดียว
- AC "build iOS" ตัดออกตาม D-017 (YK ลง Google Play อย่างเดียว) · ลบ `app/ios/`
- ✅ โครง monorepo ตาม contract §2 · ✅ `app/` อ้าง wt_core ผ่าน path dep + lint `implementation_imports: error` · ✅ `flutter build apk --debug` ผ่าน · ✅ `flutter test` + `flutter analyze` 0 issue ทั้ง wt_core / wt_mode_story / app
- หนี้: `games_services` ใช้ Kotlin Gradle Plugin แบบเก่า (เตือนตอน build) → แก้ใน T-023 · ยังไม่มี Android emulator บนเครื่อง YK (สร้างได้ใน Android Studio → Device Manager หรือใช้มือถือจริง)
