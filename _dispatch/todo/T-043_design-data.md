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

---
## Amendment v2.1 (D-004, 2026-10-18)
เพิ่ม content: 4 คลาส × 3 สกิล (12) · affix pool ต่อช่อง 3 ชั้น · style ช่องละ 3 + อาวุธ 3 × 4 คลาส · ตาราง EXP Lv1–40

---
## Amendment v2.3 (D-008, 2026-10-19)
เพิ่มข้อมูลเหตุการณ์ระหว่างทาง (GDD v0.5.2 §9.2): id, ชนิด good/bad, buff id ใน `buffs.json`, จำนวนคลื่น, icon, ชื่อ TH/EN — ตั้งต้น: ดี 4 (ปลาย่าง ATK+20%, ลมส่ง ตีเร็ว+15%, สายรุ้ง ไหมพรม×2, ถุงปลาทองรับทันที) · ไม่ดี 3 (ฝน ตีช้า−10%, ผึ้ง หลบ−10%, โคลน DEF−10%) — ดีบัฟต้องไม่เกิน `road_events.debuff_max_*`
