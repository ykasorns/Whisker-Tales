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
