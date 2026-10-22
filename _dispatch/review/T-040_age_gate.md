# T-040: age screen (neutral)
Module: age_gate | Priority: P0 | Owner: Sonnet | Depends: T-033,T-022
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
หน้าถามอายุแบบเป็นกลางตอนเปิดครั้งแรก (ไม่ชี้นำคำตอบ ไม่มีค่า default ที่เป็นผู้ใหญ่) → age band `under13 | 13plus` เก็บใน save · ผู้ปกครองแก้ได้ผ่าน parental gate (T-025)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
AgeGate.band / needsPrompt / setBand(band) — screen widget อยู่ใน module นี้

## Acceptance Criteria
- [x] ข้ามหน้าจอไม่ได้ในครั้งแรก · band ที่ไม่รู้ = ถือเป็น under13
- [x] ใช้ตัวเลข/ภาพ เด็กเล็กเลือกได้โดยไม่ต้องอ่าน (TH/EN)
- [x] golden test

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล

## ผล (2026-10-22, Opus) — D-026
- wt_core `src/age/age_gate.dart`: `AgeGate` (band, needsPrompt, setBand ครั้งแรกเท่านั้น, changeBand ต้องมี parental pass, bandFor(age), treatAsChild, save `age.band`) · `ageGateProvider`, `ageBandProvider` มาจากคำตอบ · GameSaver เป็นเจ้าของ `age` (เลิก carry) · cloud merge เก็บคำตอบจากเครื่องที่ตอบแล้ว
- app `ui/age_screen.dart`: ตาราง 3…18+ เท่ากันทุกช่อง, จุดให้นับ, ยืนยัน ✓/✗, PopScope ข้ามไม่ได้ · แสดงก่อน GameShell ครั้งแรก · แก้อายุจากร้านค้าผ่านด่านผู้ปกครอง

**Test** wt_core 278 (+5: ถามจนกว่าจะตอบ, เปลี่ยนต้องมี pass, โฆษณา child-directed ตามคำตอบ, save/ค่าที่ไม่รู้จัก, cloud merge) · app 15 (+2 golden TH/EN: เกมไม่ขึ้นก่อนตอบ, back ข้ามไม่ได้, ✗ ยังถาม, ✓ เข้าเกม) · analyze 0
