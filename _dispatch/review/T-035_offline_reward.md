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

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `src/offline/offline_reward.dart` — `OfflineRules.fromBalance` (8 ชม. + 10 นาที/เลเวลวิจัย สูงสุด 12 เลเวล, อัตราออฟไลน์ = `offline_rate_vs_online`), `OfflineReward` (`compute` ตาม contract + `checkIn()` จาก GameClock + `claim()`)
- `core/contracts/offline_reward.dart` — ผลลัพธ์เพิ่ม `waves` / `exp` (additive) · `RewardBundle.emptyConst`
- providers: `offlineRulesProvider`, `offlineRewardProvider` (ใช้ `incomeModelProvider` ตัวเดียวกับออนไลน์ · EXP เข้า `catProgressProvider` · ของเข้า `walletProvider`)

**Test** (`test/offline/` +10 → รวม 187 · analyze 0 ทั้ง 3 package)
- cap ตามเลเวลวิจัย · 1 ชม. = รายได้ 1 ชม. ด้วยสูตรเดียวกับออนไลน์ (IncomeModel) · เกิน cap ตัดที่ cap · เวลาติดลบ = 0
- ย้อนนาฬิกา (now < max_seen) = 0 · เลื่อนนาฬิกาไปข้างหน้า = ได้ไม่เกิน cap
- claim ครั้งเดียว · claim แล้ว last_seen = ตอนนี้ · merge cloud ทั้ง 2 ทิศ → รับซ้ำไม่ได้
- ข้อมูลพัง → error ระบุ field · providers: 8 ชม. → ปลาทองเข้ากระเป๋า + แมวเลเวลขึ้น

**ข้อสังเกต**
- ไม่มีปุ่ม ×2 (placement `offline_x2` ปิดตาม D-003) · ปุ่มความเร็วไม่มีผลกับออฟไลน์
- ออฟไลน์ไม่มีบอส/เหตุการณ์ระหว่างทาง (ตาม GDD) — ฟาร์มหน้าเดิมอย่างเดียว
- เลเวลวิจัย `offline_cap` ส่งเข้า `checkIn(offlineResearchLevel:)` — research (T-041) ต้องต่อ
