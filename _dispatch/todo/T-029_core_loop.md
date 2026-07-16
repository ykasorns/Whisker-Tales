# T-029: balancing pass + debug telemetry
Module: core_loop | Priority: P2 | Owner: Sonnet | Depends: T-005..T-028

## Goal
debug overlay จับเวลา run จริง, จูน XP/HP/damage ให้ run = 3–5 นาที และเลเวลอัพ 2–3 ครั้ง/run

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
DebugTelemetry (dev build เท่านั้น — ห้ามหลุดไป release)

## Acceptance Criteria
- [ ] 10 run ทดสอบ: median 3–5 นาที
- [ ] dev flag ปิดใน release build (test ยืนยัน)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
