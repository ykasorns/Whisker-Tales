# T-010: relic system + effect resolver
Module: item_synergy | Priority: P0 | Owner: Sonnet | Depends: T-003,T-007

## Goal
เก็บ relic ใน run, resolver แปลง trigger/action/params จาก relics.json เป็นผลจริงใน combat — data-driven 100%

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
ItemSystem.addRelic(id) / resolve(trigger, ctx)

## Acceptance Criteria
- [ ] เพิ่ม relic ใหม่ใน JSON โดยไม่แตะโค้ด = ทำงานทันที
- [ ] ทุก action ใน vocabulary §4.5 มี test

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

---
## Amendment v2.0 (D-002, 2026-10-12)
ขอบเขต = โหมดนิทานผจญภัยเท่านั้น · resolver ต้อง**แปลง `effects[]` เป็น buff id แล้วส่งให้ BuffEngine (T-008)** แทนการ implement ผลเอง — ห้ามมี effect logic ซ้ำกับ combat · Depends เพิ่ม T-008

---
## ส่งงาน/ตรวจรับ (2026-10-25, D-048)
- [x] `ItemSystem` เก็บ relic แยกต่อ Run, ปฏิเสธ id ที่ไม่มีใน content และเพิ่ม/ถอดได้โดยไม่แก้ข้อมูลถาวรของโหมดหลัก
- [x] resolver อ่าน trigger, buff, target และ chance จาก `StoryRelic` ที่ validate จาก JSON แล้วส่งผลเข้า `IBuffEngine.apply`; ไม่มีสูตร damage/heal/stat ซ้ำใน module items
- [x] chance ใช้ basis point จาก RNG ของ Run และ effect เป้าศัตรูจะข้ามอย่างปลอดภัยเมื่อ encounter ไม่มีศัตรู
- [x] เพิ่ม relic definition ใหม่ใน data model แล้วทำงานทันทีโดยไม่เพิ่มเงื่อนไขเฉพาะ id
- [x] test ครบ trigger vocabulary ทั้ง 7 แบบ, target, chance boundary, missing enemy, unknown id และการส่ง buff
- [x] wt_core tests 328, story tests 7, app tests 45; analyze ทั้งสามส่วนผ่าน
