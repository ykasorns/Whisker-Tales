# T-039: ads — AdService + fake + placements + daily caps
Module: ads | Priority: P0 | Owner: Sonnet | Depends: T-033,T-040,T-022
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
module เดียวที่แตะโฆษณา: `AdService` interface + `FakeAdService` (ใช้ใน test/dev) · placement registry จาก idle_balance_v1.json `ads.placements` · บังคับ cap ต่อจุด + cap รวม/วัน ที่นี่ที่เดียว · โหมด child-directed/non-personalized ตาม age band · **ยังไม่ integrate SDK จริง** (Opus เลือก SDK Families-certified ทีหลัง + log DECISIONS)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AdService.canShow(placementId) / show(placementId) -> Future<AdOutcome{rewarded|skipped|failed|capped}> / remainingToday(placementId)

## Acceptance Criteria
- [ ] placement `enabled:false` → canShow=false เสมอ
- [ ] cap ต่อจุด + cap รวม ทำงานพร้อมกัน · รีเซ็ตเฉพาะ DayRollover
- [ ] age band under13 / unset → ส่ง flag non-personalized + child-directed ทุกครั้ง (assert ใน fake)
- [ ] entitlement `no_ads` ทำตาม `no_ads_behavior` ต่อ placement ใน JSON (`show | hide | grant`, ค่าเริ่มต้น `show`) → **ปัจจุบัน flag ไม่มีผลใด ๆ** จนกว่า YK ตอบ Q8 · `grant` ต้องถูก reject โดย validator สำหรับ placement ที่ให้ของสุ่ม/เร่งเวลา เว้นแต่ DECISIONS อนุญาต
- [ ] ไม่มี module อื่น import ad SDK (lint/test)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Amendment D-003 (2026-10-12)
- placement ที่เปิด: pet_hatch 3, research_speedup 5, yarn_bundle 2, daily_gift 1 · cap รวม 10 · `no_ads_behavior` = `hide` ทุกจุด (D-003) — `grant` ยังห้าม · test: no_ads=true → canShow=false ทุกจุด และไม่มีรางวัลออก
