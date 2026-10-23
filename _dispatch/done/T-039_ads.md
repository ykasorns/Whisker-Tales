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

---
## Amendment v2.3 (D-008, 2026-10-19)
placement ใหม่ `road_event` (3/วัน, อยู่ในเพดานรวม 10) — ใช้โดย T-048

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `src/ads/ad_network.dart` — `AdNetwork` (ช่องเสียบ SDK จริง), `AdRequest` (childDirected / nonPersonalized), `FakeAdNetwork` (dev/test, จดทุก request)
- `src/ads/ad_service.dart` — `AdRules.fromJson` (validator: `grant` ต้องมี `grant_allowed` จาก DECISIONS), `AdService` (canShow / show / remainingToday, เพดานต่อจุด + รวม, รีเซ็ตเมื่อ date_key ของ GameClock เดินหน้า, ทีละ 1 โฆษณา), `AdDailyState` (Save v3 `daily`: date_key / ads_used / ads_total)
- providers: `adRulesProvider`, `adNetworkProvider` (fake), `ageBandProvider` (T-040 override), `noAdsProvider` (T-025 override), `adServiceProvider` (แทนตัวที่ throw — road events ใช้ได้แล้ว)

**Test** (`test/ads/` +12 → รวม 162 · analyze 0 ทั้ง 3 package)
- placement จาก JSON · ปิด/ไม่รู้จัก = ไม่แสดง · เพดานต่อจุด + รวม 10 พร้อมกัน · นับเฉพาะดูจบ
- รีเซ็ตวันใหม่ตามเวลาท้องถิ่น · ย้อนนาฬิกาไม่รีเซ็ต · ทีละ 1 โฆษณา
- unset/under13 → child-directed + non-personalized · 13+ → ไม่ child-directed แต่ยัง non-personalized
- Supporter Pack → ซ่อนทุกจุด ไม่มีรางวัล · `grant` โดนปฏิเสธถ้าไม่มี DECISIONS
- save/load + วันเก่าถูกทิ้ง · สแกนโค้ดทั้ง wt_core / wt_mode_story / app: ไม่มีที่อื่นแตะ AdNetwork/ad SDK

**ข้อสังเกต**
- ยังไม่ต่อ SDK จริง (ตาม card) — Opus เลือก SDK ที่อยู่ใน Families self-certified list + log DECISIONS ก่อน
- 13+ ยัง non-personalized เพราะยังไม่มีหน้าขอความยินยอม (D-014)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ ทุก AC: `ad_service_test.dart` 12 tests (รวม test ห้ามโมดูลอื่นแตะ SDK)
- หนี้ "ยังไม่ต่อ SDK จริง" → ทำใน **D-033** (AdMob ผ่าน `AdNetwork` ใน app/)
