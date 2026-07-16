# T-006: encounter generator (seed-based)
Module: encounter_gen | Priority: P0 | Owner: Sonnet | Depends: T-003,T-005

## Goal
สร้าง node map 8–10 nodes จาก seed, การกระจาย encounter ตามสัดส่วน GDD §3.3, node สุดท้าย = boss, รองรับ Fork (ทางแยก)

## Interface (ห้ามเปลี่ยนโดยไม่ผ่าน Opus)
EncounterGenerator.generate(seed) -> NodeMap

## Acceptance Criteria
- [ ] seed เดิม = map เดิมเป๊ะ (รองรับ Daily Challenge อนาคต)
- [ ] สัดส่วน encounter อยู่ในช่วง ±10% ของ GDD เมื่อ gen 1000 maps (statistical test)
- [ ] combat ติดกันไม่เกิน 3 nodes

## DoD
ตาม GAME_CONTRACT §6 ทุกข้อ + ย้าย card นี้ไป _dispatch/review/ พร้อมสรุปผล
