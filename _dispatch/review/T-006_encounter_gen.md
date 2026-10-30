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

---
## Amendment v2.0 (D-002, 2026-10-12)
ใช้กับโหมดนิทานผจญภัยเท่านั้น (spec = GDD v0.3 §3) · ไม่เกี่ยวกับ wave source ของ idle_loop

---
## ส่งงาน/ตรวจรับ (2026-10-24, D-046)
- [x] seed เดิมได้แผนที่เดิม 8–10 node และ node สุดท้ายเป็น `eraserking`
- [x] gen 1,000 maps แล้วสัดส่วน encounter ทุกชนิดอยู่ในช่วง ±10% ของ GDD
- [x] ทุกเส้นทางมี combat ต่อกันไม่เกิน 3 node ตรวจครบ safe/risky branches ใน 1,000 seeds
- [x] Fork เปิดตัวเลือก safe/risky ที่ depth เดียวกันและกลับมารวมเส้นทางหลังเลือก
- [x] การเลือก branch ต้องส่ง route id ชัดเจน; ไม่มีการสุ่มเลือกแทนผู้เล่น
- [x] conformance suite รองรับ source ที่มีหลายตัวเลือกและตรวจ determinism ของทุก route
