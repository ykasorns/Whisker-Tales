# T-035: offline reward
Module: offline_reward | Priority: P0 | Owner: Sonnet | Depends: T-034,T-033,T-022
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
คำนวณรางวัลออฟไลน์ = IncomeModel × เวลา (cap 8 ชม. + research node +10 นาที/เลเวล) ตอนเปิดแอป/กลับจาก background

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
OfflineReward.compute(lastSeen, effectiveNow, cap) -> RewardBundle / claim()

## Acceptance Criteria
- [ ] ย้อนนาฬิกา → 0 · เวลาติดลบ → 0
- [ ] เกิน cap → ตัดที่ cap
- [ ] save จาก 2 เครื่องที่นาฬิกาต่างกัน merge แล้ว claim ซ้ำไม่ได้ (ใช้ last_seen หลัง merge)
- [ ] ไม่มีปุ่ม ×2 ใน MVP (รอ Q7)
- [ ] test ครอบ: ปกติ, เกิน cap, ย้อนนาฬิกา, เลื่อนนาฬิกาไปข้างหน้า (ได้ไม่เกิน cap), merge cloud

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
