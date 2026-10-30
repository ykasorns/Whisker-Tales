# T-016: floating node map scroll
Module: ui_panel | Priority: P1 | Owner: Sonnet | Depends: T-014,T-006

## Goal
ม้วนกระดาษโปร่งแสง ~85% ลอยขอบบน viewport แสดง node ถัดไป 2–3 จุด + หมุดแมว, แตะขยาย/ย่อ — GDD §3.4

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
NodeMapOverlay(NodeMap, currentIndex)

## Acceptance Criteria
- [x] โปร่งแสงไม่บัง gameplay (screenshot review)
- [x] ขยาย/ย่อเป็น optional — ไม่แตะเลยก็เล่นจบ run ได้
- [x] golden test ย่อ/ขยาย

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## Delivery summary (2026-10-25)

- เพิ่มม้วนแผนที่โปร่งแสงเหนือ viewport แสดงหมุดแมวและ preview 3 node ถัดไปจาก RunManager
- แตะเพื่อย่อ/ขยายได้โดยไม่เปลี่ยนสถานะ Run; controller test เล่นจบได้โดยไม่แตะแผนที่
- Golden ตรวจทั้ง expanded/collapsed และ reduced motion

### Verification

- Screenshot review ผ่าน: ฉากและตัวละครยังมองเห็นชัดใต้แผนที่
- Widget tests และ app tests ผ่านทั้งหมด
