# T-040: age screen (neutral)
Module: age_gate | Priority: P0 | Owner: Sonnet | Depends: T-033,T-022
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
หน้าถามอายุแบบเป็นกลางตอนเปิดครั้งแรก (ไม่ชี้นำคำตอบ ไม่มีค่า default ที่เป็นผู้ใหญ่) → age band `under13 | 13plus` เก็บใน save · ผู้ปกครองแก้ได้ผ่าน parental gate (T-025)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AgeGate.band / needsPrompt / setBand(band) — screen widget อยู่ใน module นี้

## Acceptance Criteria
- [ ] ข้ามหน้าจอไม่ได้ในครั้งแรก · band ที่ไม่รู้ = ถือเป็น under13
- [ ] ใช้ตัวเลข/ภาพ เด็กเล็กเลือกได้โดยไม่ต้องอ่าน (TH/EN)
- [ ] golden test

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
