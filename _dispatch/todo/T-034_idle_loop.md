# T-034: idle loop — page progression, wave source, boss gate
Module: idle_loop | Priority: P0 | Owner: Sonnet | Depends: T-007,T-033,T-003
> D-002 · spec: GDD v0.4 · contract v2.0

## Goal
โหมดหลัก (core — ไม่ใช่ GameMode): เล่ม→บท→หน้า, คลื่นไม่รู้จบของหน้าที่ฟาร์ม, เลือกหน้าฟาร์ม (farm_min_power_ratio), ท้าบอสหน้า/บอสบท, รายได้ต่อคลื่น (ปลาทอง/ไหมพรม/ไข่) — curve ทั้งหมดจาก idle_balance_v1.json

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
IdleLoop.state / challengeBoss() / Stream<WaveCleared|BossResult> / IncomeModel.perWave(page)

## Acceptance Criteria
- [ ] P(n), boss mult, รายได้ต่อคลื่น ตรงกับสูตรใน JSON (test เทียบตาราง)
- [ ] แพ้บอส = ไม่เสียอะไร กลับไปฟาร์ม
- [ ] IncomeModel ใช้ร่วมกับ offline_reward (ฟังก์ชันเดียวกัน ไม่ copy)
- [ ] deterministic ตาม seed

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
