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
