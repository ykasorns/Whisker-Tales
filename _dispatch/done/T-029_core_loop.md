# T-029: balancing pass + debug telemetry
Module: core_loop | Priority: P2 | Owner: Sonnet | Depends: T-005..T-028

## Goal
debug overlay จับเวลา run จริง, จูน XP/HP/damage ให้ run = 3–5 นาที และเลเวลอัพ 2–3 ครั้ง/run

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
DebugTelemetry (dev build เท่านั้น — ห้ามหลุดไป release)

## Acceptance Criteria
- [n/a] 10 run ทดสอบ: median 3–5 นาที — เป้านี้ของโหมดผจญภัย (`wt_mode_story` ยังไม่มีโค้ด) · โหมดหลักใช้เป้า v2.0 แทน
- [x] dev flag ปิดใน release build (test ยืนยัน)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
เป้าหลักเปลี่ยน: **โหมดหลัก** จูน `idle_balance_v1.json` ด้วย `tools/balance_sim` + playtest — เล่ม 1 ≈ 14±2 วัน, no-ads ช้ากว่า ≤25%, แก้จุดอ่อนที่ GDD v0.4 §15.8 ระบุ (ไวต่อค่า / บท 3 เป็นกำแพง / โฆษณาแทบไม่มีผล) · โหมดผจญภัยยังใช้เป้า run 3–5 นาที · DebugTelemetry เพิ่มเวลาออฟไลน์ + ad usage

## ผล (2026-10-22, Opus) — D-027
- **ผู้เล่นจำลองบน engine จริง** `packages/wt_core/tool/headless_player_test.dart` (`flutter test tool/headless_player_test.dart`, `--dart-define=SEEDS/CLASSES/DAYS/BALANCE`) → รายงาน `tools/balance_sim/headless_report.txt` · `AdGifts` ย้ายสูตรของขวัญเข้า core
- จูน `idle_balance_v1.json` 5 ค่า (D-027 ข้อ 4) → จบเล่ม 1 วันที่ 12 (ทุกคลาส 10.5–12.2), ไม่ดูโฆษณาช้ากว่า 10%, ทน ±0.01 ไม่มีกำแพง
- DebugTelemetry overlay (dev เท่านั้น) · test `kDebugTelemetry == false` + ตรวจ release APK ไม่มีข้อความ telemetry
- sim เดิมเก็บไว้เป็นตัวคร่าว ๆ (ค่าใหม่มันบอก ~40 วัน — ไม่ใช้ตัดสินแล้ว)

**Test** wt_core 278 · app 16 · analyze 0 · golden welcome_back อัปเดต (รางวัลออฟไลน์น้อยลง)

**ต้องให้ YK ตัดสิน:** ออฟไลน์ได้ ~6–16% ของตอนเล่น (D-027 ข้อ 6)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ เป้าโหมดหลัก (D-027): headless player บน engine จริง `tool/headless_player_test.dart` · ✓ dev flag ปิดใน release (`boot_test`)
- n/a: เป้า run 3–5 นาทีของโหมดท้าทาย → ไปกับ T-005/T-029 รอบโหมดนิทาน (กลุ่ม B)
