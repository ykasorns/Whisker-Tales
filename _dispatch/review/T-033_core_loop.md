# T-033: GameClock + daily reset + v2 contracts
Module: core_loop | Priority: P0 | Owner: Sonnet | Depends: T-002
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
แหล่งเวลาเดียวของเกม (ไม่มี backend) + กฎนาฬิกา CONTRACT §4.6 + daily reset ตาม date_key + ประกาศ provider/interface ของ module ใหม่ (idle_loop, offline_reward, gear_basket, pets, research, ads, age_gate) ใน core/contracts

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
GameClock.now() / effectiveNow (= max(now, max_seen)) / Stream<DayRollover> · contracts/*.dart

## Acceptance Criteria
- [ ] ย้อนนาฬิกา: effectiveNow ไม่ถอย, max_seen ไม่ลด
- [ ] date_key เปลี่ยนไปข้างหน้า → emit DayRollover ครั้งเดียว · ย้อนวัน → ไม่ emit
- [ ] merge จาก cloud: max_seen = max ของทั้งสองฝั่ง
- [ ] test ด้วย fake clock ครอบ: เดินหน้า, ย้อน, ข้ามหลายวัน, เปลี่ยน timezone

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Worker summary (2026-10-12)

**⚠️ เริ่มก่อน dependency:** T-002 ยังอยู่ todo (และ T-001 ยังอยู่ doing) — YK สั่งเริ่ม T-033 ตรง ๆ · GameClock ไม่ขึ้นกับ T-002 · ไฟล์ `core/providers.dart` และโฟลเดอร์ `core/contracts/` สร้างที่นี่ก่อน → **T-002 ต้องต่อเติมไฟล์เดิม ไม่สร้างทับ**

**ไฟล์ที่แตะ (ทั้งหมดใน `packages/wt_core/`)**
- `lib/src/core/clock/game_clock.dart` — `TimeSource` (+`SystemTimeSource`), `GameClock` (`now()`, `effectiveNow`, `tick()`, `markSeen()`, `mergeFrom()`, `snapshot()`, `dayRollovers`), `ClockState`, `DayRollover`
- `lib/src/core/contracts/` — `rewards.dart` (`Currency`, `RewardBundle`), `idle_loop.dart`, `offline_reward.dart`, `gear_basket.dart` (+ auto-craft), `pets.dart`, `research.dart`, `ads.dart`, `age_gate.dart` — interface ตาม Interface ของ card T-034–T-041 พร้อม doc อ้าง GDD v0.4 §
- `lib/src/core/providers.dart` — `timeSourceProvider`, `gameClockProvider`
- `lib/wt_core.dart` — export ทั้งหมดข้างบน
- test: `test/core/clock/game_clock_test.dart` (17), `test/core/contracts/rewards_test.dart` (4)

**Acceptance**
- [x] ย้อนนาฬิกา: effectiveNow ไม่ถอย, max_seen ไม่ลด (+ markSeen ไม่ถอย, restore จาก save ที่ max_seen ใหม่กว่า)
- [x] date_key เดินหน้า → DayRollover ครั้งเดียว (รวมข้ามหลายวัน) · ย้อนวัน → ไม่ emit และไม่เปิดวันเก่าซ้ำ
- [x] merge cloud: ทุก field เอาค่าที่ใหม่กว่า (max_seen, last_seen, date_key) · merge ไม่ emit rollover
- [x] fake clock ครอบ: เดินหน้า, ย้อน, ข้ามหลายวัน, เปลี่ยน timezone (บินไปตะวันออก/ตะวันตกข้ามเที่ยงคืน)
- `flutter analyze` 0 issue · `flutter test` 21/21 ผ่าน (Flutter 3.44.8 / Dart 3.12.2)

**ข้อสังเกต**
1. `AgeBand.over13` = ค่า `13plus` ใน Save v3 (Dart ตั้งชื่อขึ้นต้นด้วยตัวเลขไม่ได้) — T-022/T-040 ต้อง map ตอน encode
2. `effectiveNow` เป็น getter ที่อัพเดต max_seen ด้วย (ตั้งใจ — ทุกการอ่านเวลาถือว่า "เห็น" แล้ว) เขียนไว้ใน doc
3. `gameClockProvider` ยังไม่ restore จาก save — รอ T-022 (doc ระบุไว้)
4. merge ให้ date_key ใหม่กว่าชนะ → daily quota ของอีกเครื่องต้อง merge ใน T-023 ตาม amendment (เอา counter ที่มากกว่าถ้าวันเท่ากัน)
5. Flutter SDK มีในเครื่องแล้ว → blocker ของ T-001 (BLOCKED.md) น่าจะปลดได้ — แต่ยังต้องมี Xcode/Android SDK สำหรับ `flutter create` native project
