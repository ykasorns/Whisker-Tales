# T-016: floating node map scroll
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-006

## Goal
ม้วนกระดาษโปร่งแสง ~85% ลอยขอบบน viewport แสดง node ถัดไป 2–3 จุด + หมุดแมว, แตะขยาย/ย่อ — GDD §3.4

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
NodeMapOverlay(NodeMap, currentIndex)

## Acceptance Criteria
- [ ] โปร่งแสงไม่บัง gameplay (screenshot review)
- [ ] ขยาย/ย่อเป็น optional — ไม่แตะเลยก็เล่นจบ run ได้
- [ ] golden test ย่อ/ขยาย

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
