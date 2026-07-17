# BLOCKED.md

Sonnet append-only — ปัญหาที่ทำต่อไม่ได้โดยไม่เดา

---

[T-001] Flutter SDK / Xcode / Android SDK ไม่มีในเครื่องที่รันงานนี้ (เครื่องมีแค่ Command Line Tools, ไม่มี Xcode.app, ไม่มี Android SDK, ดิสก์เหลือ ~11GB) จึงรัน `flutter create`, `flutter pub get`, `flutter analyze`, `flutter test` ไม่ได้จริง — scaffold ไฟล์ Dart/pubspec/folder ด้วยมือไปแล้วครบตาม §2 แต่ 3 ข้อนี้ยังไม่ผ่านและ verify ไม่ได้:
- `app/android/` และ `app/ios/` — โฟลเดอร์ native project (Gradle/Xcode) ไม่ได้สร้าง เพราะเขียนมือให้ถูกต้องแทน `flutter create` ไม่ได้จริง (เสี่ยงสร้างโปรเจกต์ native ที่พังแบบเนียนๆ)
- ยังไม่ได้รัน `flutter pub get` — ไม่ยืนยันว่า version constraint ของ dependency (flame/riverpod/hive/games_services ฯลฯ) ใน pubspec.yaml resolve ได้จริง
- ยังไม่ได้รัน `flutter analyze` / `flutter test` — ไม่ยืนยันว่า 0 issue จริงและ layout_test.dart ผ่านจริง

ทางเลือกที่เสนอ: ติดตั้ง Flutter SDK (+ Xcode สำหรับ iOS, Android SDK/Studio สำหรับ Android) บนเครื่อง dev แล้วรัน `flutter create --platforms=ios,android .` ใน `app/` เพื่อ generate native project จริง จากนั้นรัน `flutter pub get && flutter analyze && flutter test` ทั้ง workspace เพื่อปิด 3 ข้อข้างต้น — card นี้คงอยู่ที่ `_dispatch/doing/` ไม่ย้ายเข้า `review/` จนกว่าจะ verify ได้
