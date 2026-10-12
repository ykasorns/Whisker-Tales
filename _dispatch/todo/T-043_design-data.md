# T-043: content JSON v2 (idle)
Module: design-data | Priority: P0 | Owner: Opus | Depends: T-003,T-008
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
เขียน design/data สำหรับ v0.4: buffs.json (สกิล 9 + relic/talent เดิม map เป็น buff), gear_slots.json + affix pools, pets.json (6 ตัว), research.json (~25 node), pages.json (เล่ม 1: 3 บท × 10 หน้า + มอน/บอส) — ตัวเลข curve อ้าง idle_balance_v1.json ห้าม copy ตัวเลขซ้ำ

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
ไฟล์ JSON ผ่าน validator T-003 (schema v2)

## Acceptance Criteria
- [ ] sim `tools/balance_sim` ยังผ่าน 2 เป้าหลังเติม content
- [ ] ไม่มีชื่อ/ค่าใดมาจาก Legend of Mushroom

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
