# T-001: repo scaffold + layout constants
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: -

## Goal
สร้างโปรเจกต์ Flutter + โครง folder ตาม GAME_CONTRACT §2, ล็อก dependency ใน pubspec ตาม §5, สร้าง lib/core/layout.dart กำหนด ratio 60/40 จาก safe area เป็น constant

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
class AppLayout { static const gameViewportRatio = 0.60; }

## Acceptance Criteria
- [ ] โปรเจกต์ build ผ่านทั้ง iOS/Android simulator
- [ ] folder ครบตาม contract
- [ ] flutter analyze = 0 issue

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
