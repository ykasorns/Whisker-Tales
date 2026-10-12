# T-007: combat engine base — deterministic sim + damage pipeline
Module: combat | Priority: P0 | Owner: Sonnet | Depends: T-002,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
engine สู้ที่ใช้ร่วมทุกโหมด: fixed-point + seeded RNG, stat หลัก/รอง + anti-stat, damage pipeline ตาม GDD v0.4 §4.2, auto-attack ตามความเร็วตี, หลายศัตรู/หลายฝ่าย (แมว + เพื่อนสัตว์ partner damage), PowerScore ตาม §15.2 (ค่าน้ำหนักจาก JSON)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
CombatEngine.start(CombatSetup) / tick(dtMs) / Stream<CombatEvent>
StatBlock (stat+anti-stat, cap จาก data) · PowerScore.of(StatBlock)

## Acceptance Criteria
- [ ] seed เดียวกัน + input เดียวกัน = ผลเหมือนกันทุก event (test 1000 รอบ)
- [ ] ไม่มี `double` ใน state ที่มีผลต่อแพ้ชนะ (fixed-point) · ไม่มี Random() ไม่มี seed
- [ ] สุ่ม hit ครั้งเดียวแบ่ง หลบ/ปกติ/คริ · base = max(ATK−DEF, ATK×floor%) · คริ ×max(1.5, แรงคริ−ลดแรงคริ) · proc = clamp(stat−anti, 0, cap) — ค่าทุกตัวมาจาก data
- [ ] partner (เพื่อนสัตว์) ใช้ช่อง damage แยกได้
- [ ] sim headless 1 คลื่น 5 มอน < 5 ms บนเครื่อง dev (ใช้คำนวณออฟไลน์ได้)
- [ ] มอนแพ้ emit `defeated` (ไม่มี gore)

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
