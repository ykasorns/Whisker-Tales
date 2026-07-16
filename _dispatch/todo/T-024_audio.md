# T-024: audio service
Module: audio | Priority: P2 | Owner: Sonnet | Depends: T-002

## Goal
BGM/SFX service, ducking, ปิด/เปิดแยกใน settings — asset จาก assets/game/audio

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AudioService.playBgm(id)/sfx(id)

## Acceptance Criteria
- [ ] สลับ scene แล้ว BGM crossfade ไม่กระตุก
- [ ] mute ทำงานทันทีทุกที่

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
