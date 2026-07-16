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
