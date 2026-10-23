# T-048: road events — เหตุการณ์สุ่มระหว่างทาง (บัฟ/ดีบัฟ) + โฆษณา
Module: idle_loop | Priority: P1 | Owner: Sonnet | Depends: T-034, T-008, T-039, T-043
> D-008 · spec: GDD v0.5.2 §9.2–9.3 · contract v2.2

## Goal
ระหว่างเดินระหว่างคลื่น สุ่มเหตุการณ์ทุก 3–5 คลื่น (seed) → ใส่ buff ให้แมวอัตโนมัติ นับอายุเป็นคลื่น · ดี 70 / ไม่ดี 30 · พร้อมกันสูงสุด 2 · ไม่เกิดออฟไลน์ · ไม่เกิดเหตุการณ์ใหม่ตอนสู้บอส แต่ผลที่ค้างอยู่มีผลกับบอสด้วย (บอส 1 ครั้ง = 1 คลื่นของอายุผล) · AUTO ท้าบอสรอดีบัฟหมดก่อน · ปุ่มโฆษณา `road_event`: ดี = ×2, ไม่ดี = ปัดเป่า

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
RoadEvents.active / Stream<RoadEventStarted|RoadEventEnded> / boostWithAd(eventId) / cleanseWithAd(eventId) — ทุกการดูโฆษณาผ่าน `AdService` (T-039) เท่านั้น

## Acceptance Criteria
- [ ] ตัวเลขทุกตัวจาก `road_events` + ตัวเหตุการณ์จาก design/data (T-043) — ไม่มี event hardcode
- [ ] deterministic ตาม seed · ไม่มีผลตอนออฟไลน์ · ผลค้างใช้กับบอส + ลดอายุ 1 หลังสู้บอส · AUTO ท้าบอสไม่เริ่มขณะมีดีบัฟ (กดเองได้)
- [ ] **compliance (D-008 ข้อ 4):** validator ปฏิเสธดีบัฟที่เกิน −10%/stat หรือ > 2 คลื่น · sim พิสูจน์ว่าแมวที่พลังพอดีหน้า (power = P(n)) ไม่แพ้คลื่นเพราะดีบัฟอย่างเดียว (1000 seed) · ดีบัฟหายเองเสมอ
- [ ] ปุ่มโฆษณาซ่อนเมื่อถึงเพดาน `road_event`/เพดานรวม 10 หรือมี Supporter Pack · ไม่มีนับถอยหลัง/ข้อความเร่ง/popup เต็มจอ (golden test)
- [ ] ผล ×2 ใช้ `ad_boost_mult` · ปัดเป่า = ลบดีบัฟทันที

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## ส่งงาน (2026-10-19)
**ไฟล์**
- `core/contracts/idle_loop.dart` — `IRoadEvents`, `ActiveRoadEvent`, `RoadEventStarted/Ended` (+ เหตุผล wornOff/cleansed)
- `src/idle/road_events.dart` — `RoadEventRules` (validator D-008), `RoadEvents` (hooks ของ idle loop, `apply`, `boostWithAd`, `cleanseWithAd`, `canOfferAd`), `applyRoadEffects`
- `src/idle/idle_loop.dart` — hook `onWalkBetweenWaves(page)` + `adjustReward` (รางวัลคลื่นออนไลน์เท่านั้น)
- `design/data/road_events.json` (ใหม่) — ดี 4 / ไม่ดี 3 ตาม T-043 amendment
- providers: `adServiceProvider` (T-039 จะ override), `roadEventRulesProvider`, `roadEventsProvider` · idle loop ใช้ hooks + `apply` กับสเปกแมวทุกการสู้

**Test** (`test/idle/road_events_test.dart` +14 → รวม 150 · analyze 0 ทั้ง 3 package)
- validator ปฏิเสธดีบัฟ > −10% / > 2 คลื่น / เป็นบวก / ให้รางวัล / instant
- เกิดทุก 3–5 คลื่น, พร้อมกัน ≤ 2, ดี ~70%, seed เดียวกันได้ลำดับเดียวกัน
- นับถอยหลังต่อคลื่น + ต่อการสู้บอส แล้วหมดฤทธิ์ · ถุงปลาทองจ่ายทันที ไม่กินช่อง
- ATK/ตีเร็ว/หลบ/DEF ตามข้อมูล · สายรุ้งไหมพรม ×2 · AUTO บอสรอดีบัฟหมด
- โฆษณา: ×2 นานขึ้นครั้งเดียว · ปัดเป่าทันที · ถึงเพดาน/ข้าม = ไม่มีอะไรเปลี่ยน
- **D-008:** แมวพลังเท่า P(n) กับคลื่นจริงหน้า 1–30, 1000 seed × ดีบัฟคู่ที่แรงที่สุดทุกคู่ → แพ้เพราะดีบัฟ 0 ครั้ง
- ใน loop จริง: บัฟไปถึงบอส, AUTO ไม่เริ่มบอสตอนมีดีบัฟ, กดท้าเองได้เสมอ

**ข้อสังเกต / หนี้**
- ผลบัฟใส่ตรงที่สเปกแมว (`applyRoadEffects`) จนกว่า T-008 buff engine — แล้วย้ายเป็น buff id (`buffs.json`)
- golden test ปุ่มโฆษณา (ไม่มีนับถอยหลัง/popup) = T-042 UI · ต้นแบบ v14 ใช้ชิปเล็กใต้กระเป๋าเงิน + ปุ่ม 📺
- เหตุการณ์ที่ค้างอยู่ไม่เซฟ (ปิดแอป = หาย) — ตั้งใจ (ออนไลน์เท่านั้น)

---
## ตรวจรับ (2026-10-23, Opus) → done
- ✓ ทุก AC: `road_events_test.dart` 14 tests (รวม sim 1000 seed ดีบัฟอย่างเดียวไม่ทำให้แพ้, validator ปฏิเสธดีบัฟเกิน, ปุ่มโฆษณาซ่อนเมื่อหมด/มี Supporter Pack) · golden หน้าเกม
